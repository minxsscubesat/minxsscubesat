;
;	minxss_browse.pro
;
;	Browse MinXSS data by day by ploting X123 Total Counts time series
;
;	Inputs:
;		minxsslevel1	MinXSS Level-1 data structure (merged for the mission)
;		date			Date for plot (YYYYMMDD or YYYYDOY format)
;		/interactive	Option to interactively do Next or Previous day browsing
;		/xp				Option to also over plot X-ray Photometer (XP) data
;		/debug			Option to debug code at end of procedure
;
;	Outputs:
;		plot onto default window
;
;	History:
;		12/21/2021	Tom Woods, original file
;
pro minxss_browse, minxsslevel1, date, xp=xp, interactive=interactive, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE: minxss_browse, minxsslevel1, date, /xp, /interactive'
	return
endif

jd1 = long(min(minxsslevel1.x123.time.jd))+0.5
jd2 = long(max(minxsslevel1.x123.time.jd))+0.5

if n_params() lt 2 then begin
	date = jd2yd(jd1)	; start with first date
endif

; get the starting JD value
if (date gt 2100001) then begin
	; YYYYMMDD format
	d = long(date)
	yy=long( d / 10000L )
	mm=long( (d - yy*10000L) / 100L )
	dd=long( d - yy*10000L - mm*100L )
	theJD = ymd2jd(yy,mm,dd)
endif else begin
	; YYYYDOY format
	d = long(date)
	yy=long( d / 1000L )
	doy=long( d - yy*1000L )
	theJD = yd2jd(double(d))
endelse

;  make arrays that will be plotted
temp = minxsslevel1.x123.spectrum_cps
x123_cps = total(temp,1)
xp_signal_fA = minxsslevel1.xp.signal_fc / minxsslevel1.xp.integration_time

; set pre-plot variables
if keyword_set(interactive) then begin
  mtitle='N=Next; P=Previous; F=First; L=Last; Q,E=Exit'
endif else begin
  mtitle=' '
endelse
ans = ' '
dir = 1		; dir = direction for searching for day; it is either 1 or -1
xmargin1=[6,1] & ymargin1=[3.5,1.8]
xmargin2=[6,1] & ymargin2=[3.5,0]

;  loop back point for new plots
loopback:
if (theJD lt jd1) then theJD = jd1
if (theJD gt jd2) then theJD = jd2

doLoopBack = 0

;
;	check for valid data for the plot
;
wgd = where( (minxsslevel1.x123.time.jd ge (theJD-0.55)) and (minxsslevel1.x123.time.jd le (theJD+0.55)), numgd )
if (numgd lt 2) then begin
	theJD += (1.0 * dir)
	if (theJD gt jd2) then begin
		print, 'END of Mission reached without finding more data.'
		goto, debug_end
	endif
	; try finding data for the next day
	goto, loopback
endif

;
;	do plot of X123 total counts as time series for one day
;		if XP over-plot being done, then don't plot the X123 spectra
;
theHours = (minxsslevel1.x123[wgd].time.jd - theJD) * 24.D0 + 12.0
theYYYYDOY = long( jd2yd(theJD) )
theCounts = minxsslevel1.x123[wgd].spectrum_total_counts

if not keyword_set(xp) then !p.multi=[0,1,2]

setplot & cc=rainbow(7) & cs=2.0

plot, theHours, x123_cps[wgd], /nodata, $
		xrange=[-1,25], xs=1, xtitle='Hour of '+strtrim(theYYYYDOY,2), $
		yrange=[1,1E5], ys=1, /ylog, ytitle='X123 Signal (cps)', $
		xmargin=xmargin1, ymargin=ymargin1, title=mtitle

oplot, theHours, x123_cps[wgd], psym=-4

if keyword_set(xp) then begin
	oplot, theHours, xp_signal_fA[wgd], color=cc[0], psym=-5
	xyouts, 0, 3E4, 'X123', charsize=cs
	xyouts, 0, 1E4, 'XP', charsize=cs, color=cc[0]
endif else begin
	numcol = (numgd gt 255? 255: numgd)
	ccc=rainbow(numcol)
	for ii=0,numgd-1 do begin
		oplot,theHours[ii]*[1,1], x123_cps[wgd[ii]]*[1,1], psym=4, color=ccc[ii mod numcol]
	endfor
	;
	; spectral plot now
	;
	x123_energy = minxsslevel1.x123[wgd[0]].energy
	plot, x123_energy, minxsslevel1.x123[wgd[0]].irradiance, /nodata, $
		xrange=[0.5,8], xs=1, xtitle='Energy (keV)', $
		yrange=[1E4,1E9], ys=1, /ylog, ytitle='X123 Irradiance (ph/s/cm!U2!N/keV)', $
		xmargin=xmargin2, ymargin=ymargin2, title=' '
	for ii=0,numgd-1 do begin
		oplot, x123_energy, minxsslevel1.x123[wgd[ii]].irradiance, psym=10, color=ccc[ii mod numcol]
	endfor
	!p.multi=0
endelse

if keyword_set(interactive) then begin
	theChar = get_kbrd()  ; wait for keyboard character
	theChar = strupcase(theChar)
	switch theChar of
		'N': begin & theJD += 1.0 & dir=1 & break & end
		'P': begin & theJD -= 1.0 & dir=-1 & break & end
		'F': begin & theJD = jd1 & dir=1 & break & end
		'L': begin & theJD = jd2 & dir=-1 & break & end
		else: begin & break & end
	endswitch
	if (theChar eq 'E') or (theChar eq 'Q') then doLoopBack=0 else doLoopBack = 1
endif

if (doLoopBack ne 0) then goto, loopback

debug_end:
if keyword_set(debug) then stop, 'STOP: debug at end for minxss_browse...'
end
