;+
; NAME:
;	read_xrs_gse
;
; PURPOSE:
;	read ETU XRS data from ASIC GSE
;
; CATEGORY:
;	SURF / lab procedure for quick look purpose
;
; CALLING SEQUENCE:  
;	data_array = read_xrs_gse( filename )
;
; INPUTS:
;	filename		Filename (can include directory path too)
;					If not given, then ask user to select file
;
; OUTPUTS:  
;	data_array	 Array of 28 x NN  (where NN = number of lines of data)
;					Column 4,5,6 (IDL index 3,4,5) = Hours, Minutes, Seconds
;					Column 8, 10, 12, 14, 16, 18 = Counts from ASIC channel 1-6
;					Column 25, 26 = Temperture-1 and Temperature-2
;					Column 7, 9, 11, 13, 15, 17 = Offsets (IDAC) for ASIC channel 1-6
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.  Open file
;	3.  Read and process one line of text from data file
;	4.  Close file and exit
;
; MODIFICATION HISTORY:
;	9/20/10		Tom Woods	Original file creation
;
;+

function read_xrs_gse, filename, debug=debug

;
;	1.  Check input parameters
;		If none given, then ask user to select file
;
gotFile = 0
if (n_params() lt 1) then begin
  filename = ' '
endif

fsize = size(filename)
if (total(fsize) eq 0) then begin
  filename=' '
endif

if (strlen(filename) gt 2) then gotFile=1 

if (gotFile eq 0) then begin
  fdir = getenv('XRS_CAL_DATA')
  if (strlen(fdir) gt 1) then begin
    filename = dialog_pickfile( filter='*asic*', path=fdir )  
  endif else begin
    filename = dialog_pickfile( filter='*asic*' )  
  endelse
endif

;
;	2.  Open file
;
openr, lun, filename, /get_lun

;
;	3.  Read and process one line of text from data file
;		Define packet types and then do while loop until EOF
;
instring = ' '
scnt = 0L
badcnt = 0L
if not eof(lun) then readf,lun,instring  ; read header
while not eof(lun) do begin
  readf,lun,instring
  ; parse string into tokens and store as array of numbers
  strclean=strtrim(strcompress(instring),2) ;remove unnecessary white space
  tempdata = float( strsplit(strclean,' ',/extract) )
  if (n_elements(tempdata) ne 28) then begin
    badcnt += 1L
  endif else begin
    if (scnt eq 0) then data = tempdata else data = [ [data], [tempdata] ]
    scnt += 1L
  endelse
endwhile

;
;	4.  Close file and exit
;
close, lun
free_lun, lun

if keyword_set(debug) then print_stats = 1 else print_stats = 0
if (print_stats ne 0) then begin
  print, 'read_xrs_gse: ', strtrim(scnt,2), ' data records read'
  if (badcnt gt 0) then print, '    and ', strtrim(badcnt,2), ' bad (skipped) data lines'
endif

return, data
end
