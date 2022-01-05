;
;	megsa_line_center.pro
;
;	Get center-of-mass line center for MEGS-A spectra
;
;	INPUTS:
;		image		2048 x 1024 image of MEGS-A data (e.g. from rocket flight)
;		/line		Option to specify a line wavelength (default is He II 30.4 nm)
;		/noplot		Option to NOT do plots
;		/eps		Option to make EPS files for the plots
;		/title		Option to have title for image and base name of EPS file
;
;	OUTPUTS:
;		position	X & Y position along with predicted offset from ideal center in arc-minutes
;
;	HISTORY:
;		12/30/21	T. Woods, original code
;
pro megsa_line_center, image, line=line, position=position, noplot=noplot, $
					title=title, eps=eps, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE: megsa_line_center, image, line=line, position=position, /debug'
	return
endif

;
;	rough guess of wavelength scale for MEGS-A spectra
;
; a_wave = findgen(2048)*(-0.01745) + 37.7656		; 2021 quick wave cal
coeff_wave = [37.7930, -0.01748]
a_wave = findgen(2048)*coeff_wave[1] + coeff_wave[0]		; 2010 quick wave cal
A1_TO_A2_WAVE_DIFF = 3.3

if not keyword_set(line) then line = 30.4   ; default is He II 30.4 nm line
line_str = strtrim( long(line), 2 )+'nm'
ans=' '

if not keyword_set(title) then title='rEVE'

; define ideal Y_REF at 17.1 nm
y_ref_ideal = 297.0
y_ref_wave = 17.1
y_ref_slope = (325.94-321.35)/(30.4-17.1)	; for 2010 rocket MEGS-A

if (line lt 21) then begin
	; Do line center for MEGS-A1 (top half)
	; 		collapse image in X and Y and find Center of Mass for each axis
	;		also remove background level
	xx = findgen(2048)
	xdata = total(image[*,512:1023],2)
	xdata -= min(xdata)
	yy = findgen(512)
	ydata = total(image[*,512:1023],1)
	ydata -= min(ydata)

	;  find line peak (wmax) and make special ydata profile (ydata1)
	temp = min(abs(a_wave-line),wline)
	temp = max(xdata[wline-5:wline+5],wm)
	wmax = wline-5+wm
	ydata1 = total(image[wmax-5:wmax+5,512:1023],1)
	ydata1 -= min(ydata1)

	x_center = total( xx[wmax-5:wmax+5] * xdata[wmax-5:wmax+5] ) / total( xdata[wmax-5:wmax+5] )
	y_center = total( yy * ydata1 ) / total( ydata1 )

	;	calculate offsets in arc-min
	ARCMIN_PER_PIXEL = 10.0 / 65.
	x_ref = (line - coeff_wave[0])/coeff_wave[1] + A1_TO_A2_WAVE_DIFF
	y_ref1 = y_ref_ideal + y_ref_slope * (line-y_ref_wave)
	y_ref = 512.-y_ref1   ; opposite distance from edge for A1 than for A2
	dx = (x_center - x_ref)
	dx_arcmin = dx * ARCMIN_PER_PIXEL
	dy = (y_center - y_ref)
	dy_arcmin = dy * ARCMIN_PER_PIXEL

	;	print results
	print, 'MEGS-A1 Center for line (nm) at ', line
	print, 'X center (pixel) = ', x_center, ' ; dx = ', dx, ' and dx_arcmin = ', dx_arcmin
	print, 'Y center (pixel) = ', y_center, ' ; dy = ', dy, ' and dy_arcmin = ', dy_arcmin
	print, ' '

	position1 = { channel: 'MEGS-A1', x_center: x_center, y_center: y_center, dx_arcmin: dx_arcmin, dy_arcmin: dy_arcmin }

	if not keyword_set(noplot) then begin
		if keyword_set(eps) then begin
	  		efile = title+'_MEGS-A1_'+line_str+'_X.eps'
	  		print, 'Writing Plot to ', efile
	  		eps2_p, efile
	  	endif
		setplot & cc=rainbow(7)
		nplot=15
		plot, xx[wmax-nplot:wmax+nplot], xdata[wmax-nplot:wmax+nplot], xs=1, $
			title=title+' MEGS-A1 '+string(line,format='(F5.1)')+'nm', xtitle='X Scan'
		oplot, x_center*[1,1], !y.crange, line=2, color=cc[0]
		oplot, x_ref*[1,1], !y.crange, color=cc[3]
		if keyword_set(eps) then send2 else read, 'Next Plot ', ans
		if keyword_set(eps) then begin
	  		efile = title+'_MEGS-A1_'+line_str+'_Y.eps'
	  		print, 'Writing Plot to ', efile
	  		eps2_p, efile
	  	endif
		setplot & cc=rainbow(7)
		plot, yy, ydata1, xs=1, $
			title=title+' MEGS-A1 '+string(line,format='(F5.1)')+'nm', xtitle='Y Scan'
		oplot, y_center*[1,1], !y.crange, line=2, color=cc[0]
		oplot, y_ref*[1,1], !y.crange, color=cc[3]
		if keyword_set(eps) then send2 else read, 'Next Plot ', ans
	endif
endif

if (line gt 17) then begin
	;   Do line center for MEGS-A2 (bottom half)
	; 		collapse image in X and Y and find Center of Mass for each axis
	;		also remove background level
	xx = findgen(2048)
	xdata = total(image[*,0:511],2)
	xdata -= min(xdata)
	yy = findgen(512)
	ydata = total(image[*,0:511],1)
	ydata -= min(ydata)

	;  find line peak (wmax) and make special ydata profile (ydata1)
	temp = min(abs(a_wave-line),wline)
	temp = max(xdata[wline-5:wline+5],wm)
	wmax = wline-5+wm
	ydata1 = total(image[wmax-5:wmax+5,0:511],1)
	ydata1 -= min(ydata1)

	x_center = total( xx[wmax-5:wmax+5] * xdata[wmax-5:wmax+5] ) / total( xdata[wmax-5:wmax+5] )
	y_center = total( yy * ydata1 ) / total( ydata1 )

	;	calculate offsets in arc-min
	ARCMIN_PER_PIXEL = 10.0 / 65.
	x_ref = (line - coeff_wave[0])/coeff_wave[1]
	y_ref = y_ref_ideal + y_ref_slope * (line-y_ref_wave)
	dx = (x_center - x_ref)
	dx_arcmin = dx * ARCMIN_PER_PIXEL
	dy = (y_center - y_ref)
	dy_arcmin = dy * ARCMIN_PER_PIXEL

	;	print results
	print, 'MEGS-A2 Center for line (nm) at ', line
	print, 'X center (pixel) = ', x_center, ' ; dx = ', dx, ' and dx_arcmin = ', dx_arcmin
	print, 'Y center (pixel) = ', y_center, ' ; dy = ', dy, ' and dy_arcmin = ', dy_arcmin
	print, ' '

	position2 = { channel: 'MEGS-A2', x_center: x_center, y_center: y_center, dx_arcmin: dx_arcmin, dy_arcmin: dy_arcmin }

	if not keyword_set(noplot) then begin
	  	if keyword_set(eps) then begin
	  		efile = title+'_MEGS-A2_'+line_str+'_X.eps'
	  		print, 'Writing Plot to ', efile
	  		eps2_p, efile
	  	endif
		setplot & cc=rainbow(7)
		nplot=15
		plot, xx[wmax-nplot:wmax+nplot], xdata[wmax-nplot:wmax+nplot], xs=1, $
			title=title+' MEGS-A2 '+string(line,format='(F5.1)')+'nm', xtitle='X Scan'
		oplot, x_center*[1,1], !y.crange, line=2, color=cc[0]
		oplot, x_ref*[1,1], !y.crange, color=cc[3]
		if keyword_set(eps) then send2 else read, 'Next Plot ', ans
		if keyword_set(eps) then begin
	  		efile = title+'_MEGS-A2_'+line_str+'_Y.eps'
	  		print, 'Writing Plot to ', efile
	  		eps2_p, efile
	  	endif
		setplot & cc=rainbow(7)
		plot, yy, ydata1, xs=1, $
			title=title+' MEGS-A2 '+string(line,format='(F5.1)')+'nm', xtitle='Y Scan'
		oplot, y_center*[1,1], !y.crange, line=2, color=cc[0]
		oplot, y_ref*[1,1], !y.crange, color=cc[3]
		if keyword_set(eps) then send2 else read, 'Next Plot ', ans
	endif
endif

if (line gt 17) and (line lt 21) then begin
	position = replicate( position1, 2 )
	position[1] = position2
endif else if (line lt 17) then begin
	position = position1
endif else begin
	position = position2
endelse

if keyword_set(debug) then stop, 'DEBUG at end of megsa_line_center.pro ...'
end
