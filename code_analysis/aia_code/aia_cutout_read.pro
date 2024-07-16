;
;	AIA Analysis Code
;	-----------------
;
;	Purpose:  	Read AIA FITS file from SSW Cutout Service
;				and to calculate signal (total counts in region / exposure_time)
;
;	Input:  	OLD:   file		FITS file (ssw_cutout_YYYYMMDD_HHHMMSS_AIA_wave_.fts)
;							Can use wildcards (*) to read multiple files.
;			NEW (pcc 8/11/10):	wv	the wv, in Angstroms, of the AIA images to read, e.g. '335' or '094'
;
;	Options:	/path		Specify directory path to search for files
;				/loud		Print information about the files being read
;				/noimage	Option to just get image region signal (no images saved)
;				/region		Option to specify region for "signal" calculation
;								3 elements = Circle: (X, Y) center and Radius
;								4 elements = Rectangle: (X,Y) corner and (X,Y) other corner
;								All region values are given in pixels.
;								If not given, then use full cutout image for signal.
;				/rebin_fact	Rebins the images up or down to make images smaller or larger to fit screen
;				/date		change the date from the default, format: 'mmm_dd_yyyy' (e.g. 'may_05_2010')	
;
;	Output:		image_data	Image from the file (index=0 in FITS file)
;							Provided as data structure to include additional information
;							such as date, time, exposure time, etc.
;				header		String array of header information
;
;	Calls:		mrdfits		IDL procedure to read FITS files
;
;	Plot:		None
;
;	History:	7/8/10  	T. Woods, original code
;			8/11/10		P. Chamberlin, added /wv, /rebin_fact, and /date keywords
;

function aia_cutout_read, wv, path=path, noimage=noimage, region=region, loud=loud, header=header, $
		rebin_fact=rebin_fact, date=date

  ;
  ;  check inputs
  ;
  if n_params() lt 1 then begin
     print, 'USAGE:  image_data = aia_cutout_read( wv [, path=path, /noimage, region=region, /loud, header=header] '
     return, -1
  endif

  file='*_'+strtrim(wv,2)+'*.fts'
  ; if not keyword_set(path) then path='/Users/pcchambe/SDO/AIA/Data/'
  ; if not keyword_set(date) then date='may_07_2010'
  ; path=path+date+'/'
  
  if keyword_set(path) then begin
    fdir = path 
    if (strpos(fdir,'/',/reverse_search) lt (strlen(fdir)-1)) then fdir = fdir + '/'
  endif else fdir = ''
  
  selectType = -1	; 0 = Circle, 1= Rectangle, -1 = Full Image
  if keyword_set(region) then begin
    if (n_elements(region) lt 3) or (n_elements(region) gt 4) then begin
      print, 'AIA_CUTOUT_READ: Error in REGION definition, using full image.'
    endif else if (n_elements(region) eq 3) then begin
      selectType = 0
      selectX = long(region[0])
      selectY = long(region[1])
      selectR = long(region[2])
      if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Circle region: Center=(', $
          strtrim(selectX,2),',',strtrim(selectY,2),') Radius=',strtrim(selectR,2)
    endif else begin
      selectType = 1
      selectX = long(min([region[0],region[2]]))
      selectY = long(min([region[1],region[3]]))
      selectX2 = long(max([region[0],region[2]]))
      selectY2 = long(max([region[1],region[3]]))
      if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Rectangle region: Corner-1=(', $
          strtrim(selectX,2),',',strtrim(selectY,2),') Corner-2=(',strtrim(selectX2,2),',',strtrim(selectY2,2),')'
    endelse
  endif
  
  ;
  ;	Prepare to read files
  ;
  doMultipleFiles = 0
  if (strpos(file,'*') ge 0) then doMultipleFiles = 1
  fullfile = fdir + file
  
  if (doMultipleFiles eq 0) then begin
    ;
    ;   Read Single File
    ;
    if keyword_set(loud) then begin
      image = mrdfits( fullfile, 0, header, status=status )
      if (status ne 0) then print, 'AIA_CUTOUT_READ: Error=',strtrim(status),' from reading ', file
    endif else begin
      image = mrdfits( fullfile, 0, header, status=status, /silent )
    endelse
    
    if keyword_set(noimage) then begin
      image_data = { image: -1, date: 0L, time: 0L, sod: 0.0, exptime: 0.0, signal: 0.0 }
    endif else begin
      image_data = { image: image, date: 0L, time: 0L, sod: 0.0, exptime: 0.0, signal: 0.0 }    
    endelse
      
    ; extract Date and Time
    match=where(strmatch( header, 'T_OBS*', /fold_case ) ne 0, numgd)
    if (numgd gt 0) then begin
      tempstr = strsplit( header[match[0]], ' =', /extract )
      image_data.date = long(strmid(tempstr[1],1,4))*10000L + $
             long(strmid(tempstr[1],6,2))*100L + long(strmid(tempstr[1],9,2))
      hour = long(strmid(tempstr[1],12,2))
      min = long(strmid(tempstr[1],15,2))
      sec = float(strmid(tempstr[1],18,5))
      image_data.time = hour*10000L + min*100L + long(sec+0.5)
      image_data.sod = hour*3600L + min*60L + sec
    endif
   
   ; extract exposure time
    match=where(strmatch( header, 'EXPTIME*', /fold_case ) ne 0, numgd)
    if (numgd gt 0) then begin
      tempstr = strsplit( header[match[0]], ' =', /extract )
      image_data.exptime = float(tempstr[1])
    endif
    
    ; calcluate signal = total counts in region / exposure_time
    if (image_data.exptime gt 0) then begin
      if (selectType eq 0) then begin
        ; circle for signal
        ; first do radius calculation for every pixel
        imsize = size(image)
        if (imsize[0] ne 2) then begin
          if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Error with file image not being 2-D image.'
          image_data.signal = total(image)/image_data.exptime  ; let signal be full image value
        endif else begin
          imx = lindgen( imsize[1], imsize[2] ) mod imsize[1]
          imy = lindgen( imsize[1], imsize[2] ) / imsize[1]
          radius = sqrt( (imx - selectX)^2. + (imy - selectY)^2. )
          wselect = where( radius le selectR, numselect )
          if (numselect gt 1) then image_data.signal = total(image[wselect]) / image_data.exptime
        endelse
      endif else if (selectType eq 1) then begin
        ; rectangle for signal
        imsize = size(image)
        if (imsize[0] ne 2) then begin
          if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Error with file image not being 2-D image.'
          image_data.signal = total(image)/image_data.exptime  ; let signal be full image value
        endif else begin
          sx1 = selectX
          if (sx1 lt 0) then sx1 = 0L
          sx2 = selectX2
          if (sx2 ge imsize[1]) then sx2 = imsize[1] - 1L
          sy1 = selectY
          if (sy1 lt 0) then sy1 = 0L
          sy2 = selectY2
          if (sy2 ge imsize[2]) then sy2 = imsize[2] - 1L
          image_data.signal = total( image[sx1:sx2,sy1:sy2] ) / image_data.exptime
        endelse
      endif else begin
        ; full image for signal
        image_data.signal = total(image)/image_data.exptime
      endelse
    endif
    
  endif else begin
    ;
    ;   Read Multiple Files
    ;
    if keyword_set(loud) then print, 'Searching for files: ', fullfile
    filelist = file_search( fullfile, count=filecount, /FULLY_QUALIFY_PATH )
    if keyword_set(loud) then print, 'AIA_CUTOUT_READ: reading ', strtrim(filecount,2), ' files...'
    
    for k=0,filecount-1 do begin
     if keyword_set(loud) then begin
      image = mrdfits( filelist[k], 0, header1, status=status )
      if (status ne 0) then print, 'AIA_CUTOUT_READ: Error=',strtrim(status),' from reading ', filelist[k]
     endif else begin
      image = mrdfits( filelist[k], 0, header1, status=status, /silent )
		;
		; Rebin images to fit on screen if 'rebin_fact' keyword is set
		;
		if keyword_set(rebin_fact) then begin
			imsize_orig = size(image)
			image=fix(image,type=4) ; convert to float as rebin does average
			image=rebin(image[0:imsize_orig[1]/rebin_fact*rebin_fact-1,0:imsize_orig[2]/rebin_fact*rebin_fact-1],$
				imsize_orig[1]/rebin_fact, imsize_orig[2]/rebin_fact)
			image=image*rebin_fact*rebin_fact ; Keep absolute counts as 'rebin' finds average
		endif

     endelse
     
     if (k eq 0) then begin
       if keyword_set(noimage) then begin
         imagedata1 = { image: -1, date: 0L, time: 0L, sod: 0.0, exptime: 0.0, signal: 0.0 }
       endif else begin
         imagedata1 = { image: image, date: 0L, time: 0L, sod: 0.0, exptime: 0.0, signal: 0.0 }    
       endelse
       image_data = replicate( imagedata1, filecount )
       imsize1 = size(image)
       imsize = imsize1
       header = header1
     endif else if not keyword_set(noimage) then begin
       imsize = size(image)
       ; check if same size image
       if (total(imsize1) eq total(imsize)) then image_data[k].image = image $
       else if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Error for image size for file ', filelist[k]
     endif
       
     ; extract Date and Time
     match=where(strmatch( header1, 'T_OBS*', /fold_case ) ne 0, numgd)
     if (numgd gt 0) then begin
      tempstr = strsplit( header1[match[0]], ' =', /extract )
      image_data[k].date = long(strmid(tempstr[1],1,4))*10000L + $
             long(strmid(tempstr[1],6,2))*100L + long(strmid(tempstr[1],9,2))
      hour = long(strmid(tempstr[1],12,2))
      min = long(strmid(tempstr[1],15,2))
      sec = float(strmid(tempstr[1],18,5))
      image_data[k].time = hour*10000L + min*100L + long(sec+0.5)
      image_data[k].sod = hour*3600L + min*60L + sec
     endif
   
    ; extract exposure time
     match=where(strmatch( header1, 'EXPTIME*', /fold_case ) ne 0, numgd)
     if (numgd gt 0) then begin
      tempstr = strsplit( header1[match[0]], ' =', /extract )
      image_data[k].exptime = float(tempstr[1])
     endif
    
    ; calculate Signal = Image region total counts / exposure_time
    if (image_data[k].exptime gt 0) then begin
       if (selectType eq 0) then begin
        ; circle for signal
        ; first do radius calculation for every pixel
        if (imsize[0] ne 2) then begin
          if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Error with file image not being 2-D image.'
          image_data[k].signal = total(image)/image_data[k].exptime  ; let signal be full image value
        endif else begin
          imx = lindgen( imsize[1], imsize[2] ) mod imsize[1]
          imy = lindgen( imsize[1], imsize[2] ) / imsize[1]
          radius = sqrt( (imx - selectX)^2. + (imy - selectY)^2. )
          wselect = where( radius le selectR, numselect )
          if (numselect gt 1) then image_data[k].signal = total(image[wselect]) / image_data[k].exptime
        endelse
      endif else if (selectType eq 1) then begin
        ; rectangle for signal
        imsize = size(image)
        if (imsize[0] ne 2) then begin
          if keyword_set(loud) then print, 'AIA_CUTOUT_READ: Error with file image not being 2-D image.'
          image_data[k].signal = total(image)/image_data[k].exptime  ; let signal be full image value
        endif else begin
          sx1 = selectX
          if (sx1 lt 0) then sx1 = 0L
          sx2 = selectX2
          if (sx2 ge imsize[1]) then sx2 = imsize[1] - 1L
          sy1 = selectY
          if (sy1 lt 0) then sy1 = 0L
          sy2 = selectY2
          if (sy2 ge imsize[2]) then sy2 = imsize[2] - 1L
          image_data[k].signal = total( image[sx1:sx2,sy1:sy2] ) / image_data[k].exptime
        endelse
      endif else begin
        ; full image for signal
        image_data[k].signal = total(image)/image_data[k].exptime
      endelse  
    endif

    endfor
  endelse
  
return, image_data
end
