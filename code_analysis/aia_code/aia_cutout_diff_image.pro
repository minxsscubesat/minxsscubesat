;
;	AIA Analysis Code
;	-----------------
;
;	Purpose:  	Plot AIA Cutout images as difference images
;				using the result from aia_cutout_read.pro that reads FITS file from SSW Cutout Service
;
;	Input:  	imdata		Result from aia_cutout_read()
;				diff_step	Number of images to skip for doing difference image
;							Default is 3.  Value of zero (0) means use first image in sequence.
;
;	Options:	/log		Use log scaling of images  (default)
;				/linear		Use linear scaling of images
;				/both		Displays Both types of images (Difference and Original image)
;				/time_series 	Add time series plot above images (sets /both)
;				/jpeg		Make JPEG images for each frame (non-interactive mode)
;				/loud		Print information about the files being read
;				/slit		Pick a slit on the image and make a h/t plot
;				/ht_size	How large to make the h/t plot
;				/movie		Runs as a movie instead of stopping to look at each frame
;				/loop		Loops the movie continuously until cutoff by ctrl-c
;				/save_movie	Outputs an MPEG movie
;
;	Output:		None
;
;	Calls:		None
;
;	Plot:		Plots difference image with option to include original image and time series plot
;
;	History:	7/25/10  	T. Woods, original code
;			8/11/10		P. Chamberlin, added the /slit and /ht_size keywords
;			8/23/10		P. Chamberlin, added the /movie, /save_movie and /loop options
;

pro aia_cutout_diff_image, imdata, diff_step, log=log, linear=linear, both=both, loop=loop, movie=movie, $
			save_movie=save_movie, ht_size=ht_size, slit=slit, time_series=time_series, jpeg=jpeg, loud=loud

;
;  check inputs
;
if (n_params() lt 1) then begin
  print, 'USAGE:  aia_cutout_diff_image, image_data, diff_step [, /log, /linear, /both, /time_series, /jpeg, /loud]'
  print, '       Note that image_data = aia_cutout_read( files )  needs to be called first.'
  return
endif

imsize = size( imdata[0].image )
if (imsize[0] ne 2) then begin
  print, 'ERROR: aia_cutout_diff_image requires input data with images'
  return
endif

if keyword_set(save_movie) then begin
	movie=1
	loop=0
	slit=0 ; Don't do multiple windows when saving movie
	jpeg=1 ; Need jpeg files to make movie
endif

if (n_params() lt 2) then diff_step = 3L	; default diff_step value of 3 images apart
diff_step = long(diff_step)
if (diff_step lt 1) then diff_step = 0L		; difference to first image in sequence

do_log = 1  ; default scaling of images is log
if keyword_set(linear) then do_log = 0
if keyword_set(log) then do_log = 1

do_both = 0
if keyword_set(both) then do_both = 1 ;or keyword_set(slit) 

do_time = 0
if keyword_set(time_series) then do_time = 1
if (do_time ne 0) then do_both = 1

do_jpeg = 0
if keyword_set(jpeg) then do_jpeg = 1

if not keyword_set(ht_size) then ht_size = 1

if keyword_set(loud) then begin
  imtype = 'LOG'
  if (do_log eq 0) then imtype = 'Linear'
  print, 'Processing AIA cutout images with ', imtype, ' scaling and difference step of ', strtrim(diff_step,2)
endif

;
;  make plots
;
if (do_jpeg ne 0) then print, 'Making ', strtrim(n_elements(imdata),2), ' JPEG images...' $
else print, 'Use SPACE for next, B for previous, < or > for paging, J for JPEG image, or Q to quit ...'

xim = imsize[1]
yim = imsize[2]
wxsize = xim
wysize = yim
if (do_both ne 0) then wxsize = xim * 2
if (do_time ne 0) then wysize = yim + 300

window, 0, xsize=wxsize, ysize=wysize
device, set_font='Helvetica', /TT_FONT
device, decomposed=0	; configure X window so color tables work properly
!p.background = '00FFFFFF'X	; white background
!p.color = 0			; black lines

;
;  make time series data
;
if (do_time ne 0) or keyword_set(slit) then begin
  tshour = imdata.sod/3600.
  tsdata = ((imdata.signal / min(imdata.signal > 1)) - 1.) * 100.
  tsxr = [ long(min(tshour)), long(max(tshour+0.9)) ]
  tsyr = [ 0, max(tsdata)*1.1 ]
  tsxm = [ 7, 2 ]
  tsym = [ yim / (!d.y_ch_size * !p.charsize) + 3.5, 0.5 ]
endif

;
;  Chose slit and compile H/T image if keyword 'slit' is set
;

if keyword_set(slit) then begin
 for k=long(diff_step),n_elements(imdata)-1 do begin
  if (k eq 0) then k = 1L
  ; make time string HH:MM:SS
  shour = strtrim(long(imdata[k].time / 10000L),2)
  if (strlen(shour) lt 2) then shour = '0' + shour
  smin = strtrim(long(long(imdata[k].time / 100L) mod 100L),2)
  if (strlen(smin) lt 2) then smin = '0' + smin
  ssec = strtrim(long(imdata[k].time mod 100L),2)
  if (strlen(ssec) lt 2) then ssec = '0' + ssec
  strtime = shour + ':' + smin + ':' + ssec

  ;  make images (scale as LOG or Linear)
  image2 = imdata[k].image > 1
  if (diff_step gt 0) then image1 = imdata[k-diff_step].image > 1 $
  else image1 = imdata[0].image > 1
  if (do_log ne 0) then begin
    image2 = alog(image2)
    image1 = alog(image1)
  endif
  diff_image = image2 - image1


  ;  Pick slit and compile h/t image if keyword 'slit' is set
    if k eq long(diff_step) then begin
	if (do_time ne 0) then erase   ;  clear screen for next plot
	
	;  plot difference image (always required)
	loadct, 0, /silent	; grey scale for difference image
	tvscl, diff_image, 0, 0
	xx = long(!d.x_ch_size)
	yy = yim - long(!d.y_ch_size * 2)
	if (do_time ne 0) then yy = yim + long(!d.y_ch_size)
	xyouts, xx, yy, 'Time = '+strtime, /device
	
	;  plot original image (if required)
	if (do_both ne 0) then begin
	  loadct, 3, /silent  ; Red Temperature for original image
	  tvscl, image2, xim, 0
	endif

   	ans = ' '
	read, 'Pick start of slit (bottom) with cursor (hit Return key)', ans
	cursor, x1, y1, /device, /nowait
	if x1 gt xim then x1=x1-xim
	read, 'Pick end of slit (top) with cursor (hit Return key)', ans
	cursor, x2, y2, /device, /nowait
	if x2 gt xim then x2=x2-xim
	m=(y1-y2)/(x1-x2*1.)
	b=y1-m*x1
	; Decide which axis, x or y, is longer 
	if abs(x2-x1) ge abs(y2-y1) then begin ; x is longer or they are equal length
		if x2 gt x1 then x_pixs=indgen(x2-x1)+x1 else x_pixs=reverse(indgen(x1-x2)+x2)
		y_pixs=fix(m*x_pixs+b) 
		ht_img_diff=fltarr(n_elements(imdata),n_elements(x_pixs))
		ht_img_orig=fltarr(n_elements(imdata),n_elements(x_pixs))
	endif else begin ; y is the longer axis
		if y2 gt y1 then y_pixs=indgen(y2-y1)+y1 else y_pixs=reverse(indgen(y1-y2)+y2)
		x_pixs=fix((y_pixs-b)/m) 
		ht_img_diff=fltarr(n_elements(imdata),n_elements(y_pixs))
		ht_img_orig=fltarr(n_elements(imdata),n_elements(y_pixs))
	endelse
      endif

    if keyword_set(both) then begin
	oplot, [x1/(2.*xim)+0.5,x2/(2.*xim)+0.5], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on original image
	oplot, [x1/(2.*xim),x2/(2.*xim)], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on difference image
    endif else begin
	oplot, [x1/(1.*xim),x2/(1.*xim)], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on difference image
    endelse
    ht_img_diff[k,*]=diff_image[x_pixs, y_pixs]
    ht_img_orig[k,*]=image2[x_pixs, y_pixs]
    ht_img_x=rebin(tshour,n_elements(ht_img_orig[*,0]))
  
 endfor

 ; Find max and min of h/t image to scale all other images for consistent intensity scaling
 max_int_diff=max(ht_img_diff)
 min_int_diff=min(ht_img_diff)
 max_int_orig=max(ht_img_orig)
 min_int_orig=min(ht_img_orig>0.0)
 
endif else begin ; Need to find max and min scaling

 for k=long(diff_step),n_elements(imdata)-1 do begin
  if (k eq 0) then k = 1L
  ; make time string HH:MM:SS
  shour = strtrim(long(imdata[k].time / 10000L),2)
  if (strlen(shour) lt 2) then shour = '0' + shour
  smin = strtrim(long(long(imdata[k].time / 100L) mod 100L),2)
  if (strlen(smin) lt 2) then smin = '0' + smin
  ssec = strtrim(long(imdata[k].time mod 100L),2)
  if (strlen(ssec) lt 2) then ssec = '0' + ssec
  strtime = shour + ':' + smin + ':' + ssec

  ;  make images (scale as LOG or Linear)
  image2 = imdata[k].image > 1
  if (diff_step gt 0) then image1 = imdata[k-diff_step].image > 1 $
  else image1 = imdata[0].image > 1
  if (do_log ne 0) then begin
    image2 = alog(image2)
    image1 = alog(image1)
  endif
  diff_image = image2 - image1

  ; Find max and min of h/t image to scale all other images for consistent intensity scaling
  if k eq long(diff_step) then begin
  	max_int_diff=max(diff_image)
  	min_int_diff=min(diff_image)
	if keyword_set(both) then begin
	  	max_int_orig=max(image2)
		min_int_orig=min(image2>0.0)
	endif
  endif else begin
  	max_int_diff_temp=max(diff_image)
	if max_int_diff_temp gt max_int_diff then max_int_diff=max_int_diff_temp
  	min_int_diff_temp=min(diff_image)
	if min_int_diff_temp lt min_int_diff then min_int_diff=min_int_diff_temp
	if keyword_set(both) then begin
	  	max_int_orig_temp=max(image2)
		if max_int_orig_temp gt max_int_orig then max_int_orig=max_int_orig_temp
		min_int_orig_temp=min(image2>0.0)
 		if min_int_orig_temp lt min_int_orig then min_int_orig=min_int_orig_temp
	endif
  endelse
 endfor
endelse

loop_movie: ; Keyword set to loop through movie if /movie and /loop are set
if keyword_set(save_movie) then begin
	mv_flnm='./movies/'+strtrim(imdata[0].date,2)+'_'+strtrim(fix(imdata[0].sod/3600),2)+'.mpg'
	if keyword_set(both) then begin
		mpegID=mpeg_open([xim*2, yim], quality=100)
	endif else begin
		mpegID=mpeg_open([xim, yim], quality=100)
	endelse
endif

;
;  do FOR loop for the plots with JPEG images for each or Ask User for keyboard input for next plot
;
for k=long(diff_step),n_elements(imdata)-1 do begin
  if (k eq 0) then k = 1L
  ; make time string HH:MM:SS
  shour = strtrim(long(imdata[k].time / 10000L),2)
  yfrac=long(imdata[k].time / 10000L)*1.0
  if (strlen(shour) lt 2) then shour = '0' + shour
  smin = strtrim(long(long(imdata[k].time / 100L) mod 100L),2)
  if (strlen(smin) lt 2) then smin = '0' + smin
  ssec = strtrim(long(imdata[k].time mod 100L),2)
  if (strlen(ssec) lt 2) then ssec = '0' + ssec
  strtime = shour + ':' + smin + ':' + ssec
  
  ;  make images (scale as LOG or Linear)
  image2 = imdata[k].image > 1
  if (diff_step gt 0) then image1 = imdata[k-diff_step].image > 1 $
  else image1 = imdata[0].image > 1
  if (do_log ne 0) then begin
    image2 = alog(image2)
    image1 = alog(image1)
  endif
  diff_image = (image2 - image1) 
  if keyword_set(slit) then diff_image[x_pixs,y_pixs]=min_int_diff  ; Make slit show
  ;diff_image = diff_image < 10.

  if (do_time ne 0) then erase   ;  clear screen for next plot

  ;  plot difference image (always required)
  loadct, 0, /silent	; grey scale for difference image
  ;   Scale the intensity to consistent intensity
  diff_image_tv=(!d.table_size-1)*(diff_image-min_int_diff)/(max_int_diff-min_int_diff)
  tv, diff_image_tv, 0, 0
  ;tvscl, diff_image, 0, 0
  xx = long(!d.x_ch_size)
  yy = yim - long(!d.y_ch_size * 2)
  if (do_time ne 0) then yy = yim + long(!d.y_ch_size)
  xyouts, xx, yy, 'Time = '+strtime, /device

  ;  plot original image (if required)
  if (do_both ne 0) then begin
    loadct, 3, /silent  ; Red Temperature for original image
    ;   Scale the intensity to consistent intensity
    image2_tv=(!d.table_size-1)*(image2-min_int_orig)/(max_int_orig-min_int_orig)
    if keyword_set(slit) then image2_tv[x_pixs,y_pixs]=min_int_orig
    tv, image2_tv, xim, 0
  endif
  
  ;  plot time series  (if required)
  if (do_time ne 0) then begin
    plot, tshour, tsdata, /noerase, xrange=tsxr, xs=1, yrange=tsyr, ys=1, $
        xmargin=tsxm, ymargin=tsym, xtitle='Time (hour)', ytitle='Variability (%)'
    oplot, (imdata[k].sod/3600.)*[1,1], !y.crange, line=2
    if (diff_step gt 0) then oplot, (imdata[k-diff_step].sod/3600.)*[1,1], !y.crange, line=1
  endif
  
  ;if keyword_set(save_movie) then begin
  ;	im3 = tvrd(true=1)
  ; 	mpeg_put, mpegID, image=im3, frame=k-long(diff_step)
  ;endif

  if (do_jpeg ne 0) then begin
    im3 = tvrd(true=1)
    jpg_file = 'AIA_diff_'
    if (do_both ne 0) then jpg_file = jpg_file + 'both_'
    if (do_time ne 0) then jpg_file = jpg_file + 'ts_'
    jpg_file = jpg_file+strtime+'.jpg'
    write_jpeg, jpg_file, im3, true=1, quality=100.
    if keyword_set(save_movie) then begin
	read_jpeg, jpg_file, jim3
  	mpeg_put, mpegID, image=jim3, frame=k-long(diff_step)
     endif

  endif 

  ;  Plot slit and h/t image if keyword 'slit' is set
  if keyword_set(slit) then begin
    ;if keyword_set(both) then begin
	;oplot, [x1/(2.*xim)+0.5,x2/(2.*xim)+0.5], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on original image
	;oplot, [x1/(2.*xim),x2/(2.*xim)], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on difference image
    ;endif else begin
	;oplot, [x1/(1.*xim),x2/(1.*xim)], [y1/(1.*yim),y2/(1.*yim)] ; oplot slit on difference image
    ;endelse

    if ht_size gt 1 then begin
	ht_img_diff_plt=rebin(ht_img_diff,ht_size*n_elements(imdata),ht_size*n_elements(x_pixs))
	ht_img_diff_plt[k*ht_size:(k+1)*ht_size-1,*]=min(ht_img_diff_plt)
	ht_img_orig_plt=rebin(ht_img_orig,ht_size*n_elements(imdata),ht_size*n_elements(x_pixs))
	ht_img_orig_plt[k*ht_size:(k+1)*ht_size-1,*]=min(ht_img_orig_plt)
    endif else begin    
    	ht_img_diff_plt=ht_img_diff
    	ht_img_diff_plt[k,*]=min(ht_img_diff)
    	ht_img_orig_plt=ht_img_orig
    	ht_img_orig_plt[k,*]=min(ht_img_orig)
    endelse

    ; Adjust the intensity for consistent color table plotting
    ht_img_diff_tv=(!d.table_size-1)*(ht_img_diff_plt-min_int_diff)/(max_int_diff-min_int_diff)
    ht_img_orig_tv=(!d.table_size-1)*(ht_img_orig_plt-min_int_orig)/(max_int_orig-min_int_orig)

    loadct, 0, /silent	; grey scale for difference image
    if k eq long(diff_step) then begin
	window, 1, xsize=ht_size*n_elements(imdata)-(diff_step-1)*ht_size, ysize=fix(ht_size*n_elements(x_pixs)*1.1)
	device, set_font='Helvetica', /TT_FONT
	device, decomposed=0	; configure X window so color tables work properly
	!p.background = '00FFFFFF'X	; white background
	!p.color = 0			; black lines
	if do_both ne 0 then begin
		window, 2, xsize=ht_size*n_elements(imdata)-(diff_step-1)*ht_size, ysize=fix(ht_size*n_elements(x_pixs)*1.1)
		device, set_font='Helvetica', /TT_FONT
		device, decomposed=0	; configure X window so color tables work properly
		!p.background = '00FFFFFF'X	; white background
		!p.color = 0			; black lines
	endif
    endif
    wset, 1
    tv, ht_img_diff_tv[diff_step*ht_size:n_elements(ht_img_diff_tv[*,0])-1,*], 0 , fix(ht_size*n_elements(x_pixs)*0.1)
    plot, ht_img_x, findgen(n_elements(ht_img_x)), /nodata, /noerase, position=[0,0.1,1,1], xtitle='Hours'
    ;tvscl, ht_img_diff_plt, xim-ht_size*n_elements(imdata), yim-ht_size*n_elements(x_pixs)
    if do_both ne 0 then begin
	    wset, 2
	    loadct, 3, /silent  ; Red Temperature for original image
	    tv, ht_img_orig_tv[diff_step*ht_size:n_elements(ht_img_orig_tv[*,0])-1,*], 0, fix(ht_size*n_elements(x_pixs)*0.1)
	    plot, ht_img_x, findgen(n_elements(ht_img_x)), /nodata, /noerase, position=[0,0.1,1,1], xtitle='Hours'
    endif
    wset, 0

    ;stop
  endif

  if keyword_set(movie) then goto, skip_opts

  ; end of plotting
  if (do_jpeg ne 0) then begin
    imht = tvrd(true=1)
    jpg_file1 = 'AIA_ht_image_'
    if (do_both ne 0) then jpg_file = jpg_file1 + 'both_'
    jpg_file1 = jpg_file1+strtime+'.jpg'
    write_jpeg, jpg_file1, imht, true=1, quality=100.
  endif else begin
    ; get user input (SPACE, B or Q is expected)
    usrkey = get_kbrd(1)
    usrkey = strupcase(usrkey)
    if (usrkey eq 'B') then begin
      k = k - 2
      if (k lt (diff_step-1)) then k = long(diff_step) - 1L
    endif else if (usrkey eq '>') or (usrkey eq '.') then begin
      k = k + 10
      if (k gt (n_elements(imdata)-1)) then k = long(n_elements(imdata)-1)
    endif else if (usrkey eq '<') or (usrkey eq ',') then begin
      k = k - 10
      if (k lt (diff_step-1)) then k = long(diff_step) - 1L
    endif else if (usrkey eq 'J') then begin
      k = k - 1  ; no movement, just make JPEG image
      if (k lt (diff_step-1)) then k = long(diff_step) - 1L
      im3 = tvrd(true=1)
      jpg_file = 'AIA_diff_'
      if (do_both ne 0) then jpg_file = jpg_file + 'both_'
      if (do_time ne 0) then jpg_file = jpg_file + 'ts_'
      jpg_file = jpg_file+strtime+'.jpg'
      print, 'Writing JPEG image to ', jpg_file
      write_jpeg, jpg_file, im3, true=1, quality=100.   
    endif else if (usrkey eq 'Q') or (byte(usrkey) eq 27) then begin
      ; Q or ESC key will cause escape from plotting
      goto, doquit
    endif
	
  skip_opts:	

  endelse
endfor

if keyword_set(save_movie) then begin
	mpeg_save, mpegID, filename=mv_flnm
	mpeg_close, mpegID
endif

if keyword_set(movie) and not keyword_set(save_movie) then begin
	if keyword_set(loop) then goto, loop_movie else begin
		again_movie=''
		read, again_movie, prompt='Repeat Movie (y/n)?'
		if again_movie eq 'y' then goto, loop_movie
	endelse
endif

doquit:
  print, 'End of aia_cutout_diff_image.'
  
return
end
