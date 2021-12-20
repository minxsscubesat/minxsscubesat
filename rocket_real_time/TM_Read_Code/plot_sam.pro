;
;	plot_sam.pro
;
;	Plot SAM image using raw MEGS-A images
;
;	INPUT
;		filename   SAV set from output file from read_tm2
;		image	   number of image to view (can be range)
;		/scale	   option to display images as tvscl instead of tv
;		tzero      time for zero time (launch time)
;
;	OUTPUT
;		sam			SAM image
;
;	Tom Woods
;	9/12/2021
;
;
pro plot_sam, filename, image, data=data, scale=scale, rocket=rocket, sam=sam, debug=debug

common rocket_common, rocket_number, launch_time, rocket_data_dir
if not keyword_set(rocket) then rocket=36.353
rocket_set_number, rocket
tzero = launch_time

if (n_params() lt 1) then BEGIN
	print, 'USAGE: plot_sam, filename, image_number, data=data, /scale, rocket=rocket, /debug'
	; if keyword_set(debug) then stop, 'DEBUG early exit ...'
	return
endif

mnumx = 2048L
mnumy = 1024L
atotal = mnumx * mnumy


;
;	READ for *.SAV files
;
  restore, filename	; expect to have "data" in this save set
  dcnt = n_elements(data)
  if (dcnt eq 0) then begin
    if rocket eq 36.353 then begin
    	data=adata
    endif else begin
    	data=amegs
    endelse
    dcnt = n_elements(data)
  endif
  if (dcnt eq 0) then begin
    stop, 'ERROR in finding data for ', filename
  endif
; END of READ

if keyword_set(debug) then begin
	print, 'DEBUG: Rocket # ', rocket
	stop, 'STOP for DEBUG of data[] ...'
endif

if (rocket eq 36.258) then begin
    ; tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 30.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.275) then begin
    ; tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.286) then begin
    ; tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.290) then begin
    ; tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.300) then begin
    ; tzero = 19*3600L+15*60L+0.000D0  ; launch time in UT
    tapogee = 200.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.318) then begin
    ; tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 250.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.336) then begin
    ; tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 250.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif else if (rocket eq 36.353) then begin
    ; tzero = 17*3600L+25*60L+0.000D0  ; launch time in UT
    tapogee = 278.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    if (n_params() lt 2) then begin
    	wgd = where( (data.time ge (tapogee-dtlight)) and (data.time le (tapogee+dtlight)) )
    	image = [wgd[0],wgd[-1]]
    	print, 'Setting IMAGE range for ', image
	endif
endif

;
;	no need to set T-zero (launch) time as that is already in the raw data file
;
;tz = data[0].time
;if keyword_set(tzero) or (rocket ne 0) then tz = tzero

;
;	make the SAM Image
;
; stop, 'DEBUG: decide on SAM area...'
width = 300L
x1 = 1610 - width/2
;  BETTER VALUE based on 36.353
x1  = 1574  - width/2
x2 = x1 + width - 1
y1 = 277 - width/2
; BETTER VALUE based on 36.353
y1 = 250 - width/2
y2 = y1 + width - 1
sam1 = fltarr(width,width)
sam_raw = sam1
sam_sp = sam1

kstart = long(image[0])
if (kstart lt 0) then kstart = 0L
if (kstart ge dcnt) then kstart = dcnt-1L
kend = kstart
if n_elements(image) ge 2 then begin
	kend = long(image[1])
	if (kend lt 0) then kend = 0L
	if (kend ge dcnt) then kend = dcnt-1L
endif

cnt = 0L
for k=kstart,kend do begin
	if (k eq kstart) then begin
	  dark = min( data[k].image[x1:x2,y1:y2] )
	endif
	;  remove energetic particles by using Median of three  images
	for  i=x1,x2 do begin
		for j=y1,y2 do begin
			sam1[i-x1,j-y1] =  median( reform(data[k-1:k+1].image[i,j]) )
		endfor
	endfor
	sam_sp += (sam1 - dark)
	sam_raw  += (data[k].image[x1:x2,y1:y2] -  dark)
	cnt++
endfor
;  normalize for single 10-sec image
sam_raw = sam_raw / cnt
sam_sp = sam_sp / cnt

;
;	display the data
;
if (!d.name eq 'X') then window,0,xsize=width*2+2,ysize=width*2+2
setplot
cc=rainbow(255,/image)

; loadct,4

erase
sam  = rebin( sam_sp, width*2, width*2  )
if keyword_set(scale) then tvscl, sam, 1, 1 else tv, sam, 1, 1

if keyword_set(debug) then stop, 'STOP: DEBUG at end of plot_sam()...'

return
end
