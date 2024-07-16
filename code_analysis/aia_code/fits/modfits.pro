pro MODFITS, filename, data, header, EXTEN_NO = exten_no, ERRMSG = errmsg
           
;+
; NAME:
;      MODFITS
; PURPOSE:
;      Modify a FITS file by updating the header and/or data array.  
; EXPLANATION:
;      The updated header or array cannot change the size of the FITS file.
;
; CALLING SEQUENCE:
;      MODFITS, Filename_or_fcb, Data, [ Header, EXTEN_NO =, ERRMSG=]
;
; INPUTS:
;      FILENAME/FCB = Scalar string containing either the name of the FITS file  
;                  to be modified, or the IO file control block returned after 
;                  opening the file with FITS_OPEN,/UPDATE.   The explicit
;                  use of FITS_OPEN can save time if many extensions in a 
;                  single file will be updated.
;
;      DATA - data array to be inserted into the FITS file.   Set DATA = 0
;               to leave the data portion of the FITS file unmodified
;
;      HEADER - FITS header (string array) to be updated in the FITS file.
;
; OPTIONAL INPUT KEYWORDS:
;      EXTEN_NO - scalar integer specifying the FITS extension to modified.  For
;               example, specify EXTEN = 1 or /EXTEN to modify the first 
;               FITS extension. 
; OPTIONAL OUTPUT KEYWORD:
;       ERRMSG - If this keyword is supplied, then any error mesasges will be
;               returned to the user in this parameter rather than depending on
;               on the MESSAGE routine in IDL.   If no errors are encountered
;               then a null string is returned.               
;
;
; EXAMPLES:
;     (1) Modify the value of the DATE keyword in the primary header of a 
;             file TEST.FITS.
;
;              IDL> h = headfits('test.fits')      ;Read primary header
;              IDL> sxaddpar,h,'DATE','2001-03-23' ;Modify value of DATE 
;              IDL> modfits,'test.fits',0,h        ;Update header only
;
;       (2) Replace the values of the primary image array in 'test.fits' with 
;               their absolute values
;
;               IDL> im = readfits('test.fits')    ;Read image array
;               IDL> im = abs(im)                  ;Take absolute values
;               IDL> modfits,'test.fits',im        ;Update image array
;
;       (3) Modify the value of the EXTNAME keyword in the first extension
;       
;               IDL> h = headfits('test.fits',/ext)  ;Read first extension hdr
;               IDL> sxaddpar,h,'EXTNAME','newtable' ;Update EXTNAME value
;               IDL> modfits,'test.fits',0,h,/ext    ;Update extension hdr
;
;       (4) Change 'OBSDATE' keyword to 'OBS-DATE' in every extension in a 
;           FITS file.    Explicitly open with FITS_OPEN to save compute time.
;
;               fits_open,'test.fits',io,/update    ;Faster to explicity open
;               for i = 1,nextend do begin          ;Loop over extensions
;                   fits_read,io,0,h,/header_only,exten_no=i,/No_PDU ;Get header     
;                   date= sxpar(h,'OBSDATE')         ;Save keyword value
;                   sxaddpar,h,'OBS-DATE',date,after='OBSDATE' 
;                   sxdelpar,h,'OBSDATE'             ;Delete bad keyword
;                   modfits,io,0,h,exten_no=i        ;Update header
;               endfor
;
;           Note the use of the /No_PDU keyword in the FITS_READ call -- one 
;           does *not* want to append the primary header, if the STScI 
;           inheritance convention is adopted.
;
; NOTES:
;       MODFITS performs numerous checks to make sure that the DATA and
;       HEADER are the same size as the data or header currently stored in the 
;       FITS files.    (More precisely, MODFITS makes sure that the FITS file
;       would not be altered by a multiple of 2880 bytes.    Thus, for example,
;       it is possible to add new header lines so long as the total line count 
;       does not exceed the next multiple of 36.)    MODFITS is best
;       used for modifying FITS keyword values or array or table elements.
;       When the size of the data or header have been modified, then a new
;       FITS file should be written with WRITEFITS.
; RESTRICTIONS:
;       (1) Cannot be used to modifiy the data in FITS files with random 
;           groups or variable length binary tables.   (The headers in such
;           files *can* be modified.)
;
; PROCEDURES USED:
;       Functions:   IS_IEEE_BIG(), N_BYTES(), SXPAR()
;       Procedures:  CHECK_FITS, FITS_OPEN, FITS_READ, HOST_TO_IEEE
;
; MODIFICATION HISTORY:
;       Written,    Wayne Landsman          December, 1994
;       Converted to IDL V5.0   W. Landsman   September 1997
;       Fixed possible problem when using WRITEU after READU   October 1997
;       New and old sizes need only be the same within multiple of 2880 bytes
;       Added call to IS_IEEE_BIG()     W. Landsman   May 1999
;       Added ERRMSG output keyword     W. Landsman   May 2000
;       Update tests for incompatible sizes   W. Landsman   December 2000
;       Major rewrite to use FITS_OPEN procedures W. Landsman November 2001
;       Add /No_PDU call to FITS_READ call  W. Landsman  June 2002
;       Update CHECKSUM keywords if already present in header, add padding 
;       if new data  size is smaller than old  W.Landsman December 2002
;-
  On_error,2                    ;Return to user

; Check for filename input

   if N_params() LT 1 then begin                
      print,'Syntax - MODFITS, Filename, Data, [ Header, EXTEN_NO=, ERRMSG= ]'
      return
   endif

   if not keyword_set( EXTEN_NO ) then exten_no = 0
   if N_params() LT 2 then Header = 0
   nheader = N_elements(Header)
   ndata = N_elements(data)
   dtype = size(data,/TNAME)
   printerr =  not arg_present(ERRMSG) 

   if (nheader GT 1) and (ndata GT 1) then begin
        check_fits, data, header, /FITS, ERRMSG = MESSAGE
        if message NE '' then goto, BAD_EXIT
   endif

; Open file and read header information
         
   if exten_no EQ 0 then begin 
         if nheader GT 0 then $
             if strmid( header[0], 0, 8)  NE 'SIMPLE  ' then begin 
                 message = $
                'Input header does not contain required SIMPLE keyword'
                 goto, BAD_EXIT
             endif
   endif else begin
         if nheader GT 0 then $
             if strmid( header[0], 0, 8)  NE 'XTENSION' then begin 
              message = $
             'ERROR - Input header does not contain required XTENSION keyword'
              goto, BAD_EXIT
              endif
   endelse

   fcbsupplied = size(filename,/TNAME) EQ 'STRUCT'
   if not fcbsupplied then begin 
       fits_open, filename, io,/update,/No_Abort,message=message
       if message NE '' then GOTO, BAD_EXIT
    endif else begin 
       if filename.open_for_write EQ 0 then begin
             message = 'FITS file is set for READONLY, cannot be updated'
             goto, BAD_EXIT
       endif
       io = filename
   endelse

   unit = io.unit
 
   fits_read,io,0,oldheader,/header_only, exten=exten_no, /No_PDU, $
                             message = message,/no_abort
   if message NE '' then goto, BAD_EXIT
   dochecksum = sxpar(oldheader,'CHECKSUM', Count = N_checksum)
   checksum = N_checksum GT 0  
 
   if nheader GT 1 then begin
      noldheader = N_elements(oldheader)
 
        if dtype EQ 'UINT' then $
              sxaddpar,header,'BZERO',32768,'Data is unsigned integer'
        if dtype EQ 'ULONG' then $
              sxaddpar,header,'BZERO',2147483648,'Data is unsigned long'
        point_lun, unit, io.start_header[exten_no]      ;Position header start
        if checksum then begin 
               if Ndata GT 1 then fits_add_checksum, header, data else $
                fits_add_checksum, header 
        endif
        nheader = N_elements(header) 
        if ( (nheader-1)/36) NE ( (Noldheader-1)/36) then begin     ;Updated Dec. 2000
        message = 'FITS header not compatible with existing file '
        message,'Input FITS header contains '+ strtrim(nheader,2) +' lines',/inf
        message,'Current disk FITS header contains ' + strtrim(Noldheader,2) + $
                ' lines',/inf
        goto,BAD_EXIT
        endif

        writeu, unit, byte(header)                      ;Write new header

   endif 

   if ndata GT 1 then begin
        Naxis = sxpar(oldheader, 'NAXIS')
        bitpix = sxpar( oldheader, 'BITPIX')

        if Naxis GT 0 then begin
            Nax = sxpar( oldheader, 'NAXIS*' )   ;Read NAXES
            nbytes = nax[0]*abs(bitpix/8)
           if naxis GT 1 then for i = 2, naxis do nbytes = nbytes*nax[i-1]
        endif else nbytes = 0

        newbytes = N_BYTES(data)    ;total number of bytes in supplied data
 
        if ((newbytes-1)/2880) NE ( (nbytes-1)/2880) then begin   ;Updated Dec. 2000
        message = 'FITS data not compatible with existing file '
        message,'Input FITS data contains '+ strtrim(newbytes,2) + ' bytes',/inf
        message,'Current disk FITS data contains ' + strtrim(nbytes,2) + $
                ' bytes',/inf
        goto, BAD_EXIT
        endif
        if nheader EQ 0 then begin
                check_fits,data,oldheader,/FITS,ERRMSG = message
                if message NE '' then goto, BAD_EXIT
        endif
        vms = !VERSION.OS EQ "vms"
        Little_endian = not IS_IEEE_BIG()

        junk = fstat(unit)   ;Need this before changing from READU to WRITEU
        point_lun, unit, io.start_data[exten_no] 
        if dtype EQ 'UINT' then newdata = fix(data - 32768)
        if dtype EQ 'ULONG' then newdata = long(data - 2147483648)
        if (VMS or Little_endian) then begin
             newdata = data
             host_to_ieee, newdata
        endif
        if N_elements(newdata) GT 0 then writeu, unit, newdata  else $
                                         writeu, unit ,data
        remain = newbytes mod 2880
	if remain GT 0 then begin
             exten = sxpar( oldheader, 'XTENSION')
	     if exten EQ 'TABLE   ' then padnum = 32b else padnum = 0b
	     writeu, unit, replicate( padnum, 2880 - remain)
	endif
    endif       

   if not fcbsupplied then fits_close,io
   return 

BAD_EXIT:
    if N_elements(io) GT 0 then if not fcbsupplied then fits_close,io
    if printerr then message,'ERROR - ' + message,/CON else errmsg = message
    if fcbsupplied then fname = filename.filename else fname = filename
    message,'FITS file ' + fname + ' not modified',/INF
    return
   end 
