;
;	daxss_flare_goes_plot.pro
;
;	Plot DAXSS Level 1 irradiance intgrated for the GOES 1-8 Angstrom band along with GOES XRS data
;
;	INPUT
;		date		YYYYMMDD or YYYYDOY format (not required if /ALL is provided)
;		/all		Option to do a plot per day
;		/verbose	Option to print messages
;		/debug		Option to debug data
;
;	4/1/2022  Tom Woods,  Original code
;
pro daxss_flare_goes_plot, date, all=all, verbose=verbose, debug=debug

;
;	read DAXSS Level 1 data once and store in common block
;
common daxss_flare_common, daxss_level1, daxss_e, daxss_jd, daxss_yd, daxss_xrsb
if daxss_level1 eq !NULL then begin
	ddir = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level1' + path_sep()
	dfile = 'minxss4_l1_mission_length_v1.0.0.sav'
	if keyword_set(verbose) then message, /INFO, 'Reading Level 1 from '+ddir+dfile
	restore, ddir + dfile
	;  make daxss_jd and daxss_yd arrays
	daxss_jd = daxss_level1.data.time_jd
	daxss_yd = daxss_level1.data.time_yd
	;	make daxss_e array for energy
	daxss_e = daxss_level1.data[0].energy
	if keyword_set(verbose) then message, /INFO, 'Calculating DAXSS Irradiance for XRS-B Band...'
	;  integrate DAXSS spectra for GOES XRS-B range of 1-8 Angstroms
	e1 = 12.398 / 8.0  & e2 = 12.398 / 1.0
	wb = where(daxss_e ge e1 and daxss_e le e2)
	eband = daxss_e[11] - daxss_e[10]  ; delta-energy in keV units
	; convert ph/sec/cm^2/keV to  W/m^2/keV and then integrate over energy (keV)
	num_sp = n_elements(daxss_level1.data)
	daxss_xrsb = fltarr(num_sp)
	q_electron = 1.602D-19 * 1E3  ; convert from keV instead of eV
	for ii=0,num_sp-1 do begin
		sp_watts = daxss_level1.data[ii].irradiance * (daxss_e*q_electron) * 1D4
		daxss_xrsb[ii] = total(sp_watts[wb]) * eband
	endfor
endif

if keyword_set(all) then begin
	jd_date_range = [ min(daxss_jd), max(daxss_jd) ]
	num_dates = (long(jd_date_range[1]) - long(jd_date_range[0]) + 1)
	theDates = findgen(num_dates) + long(jd_date_range[0]) + 0.5D0	; JD days start at 0.5
endif else begin
	num_dates = n_elements(date)
	theDates = dblarr(num_dates)
	for ii=0,num_dates-1 do begin
		if (date[ii] gt 2030001.D0) then begin
			; assume date format is yyyymmdd
			str_date = strtrim(long(date[ii]),2)
			year = long(strmid(str_date,0,4))
			month = long(strmid(str_date,4,2))
			day = long(strmid(str_date,6,2))
			theDates[ii] = ymd2jd(year,month,day)
		endif else begin
			; assume date format is yyyydoy
			theDates[ii] = long(yd2jd(date[ii])) + 0.5D0
		endelse
	endfor
endelse

if keyword_set(verbose) then message,/INFO, 'Plotting '+strtrim(num_dates,2)+' days of flare data.'
ans = ' '
goes_last_year = 0L
goes_range = [1E-7, 1E-3]
goes_levels = [ 'B', 'C', 'M', 'X']
num_levels = n_elements(goes_levels)

for ii=0,num_dates-1 do begin
	theYD = long(jd2yd(theDates[ii]))
	year = long(theYD/1000.)
	if (year ne goes_last_year) then begin
		; Read GOES XRS 1-min data
		gdir = getenv('minxss_data')+path_sep()+'ancillary'+path_sep()+'goes'+path_sep()
		gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
		if keyword_set(verbose) then message,/INFO, 'Reading GOES file '+gdir+gfile
		restore, gdir+gfile
		goes_yd = jd2yd(gps2jd(goes.time))
		goes_xrsb = goes.long
		goes_last_year = year
	endif
	; get optimal X-range for this day and plot in X-units of hours
	wgd = where( (daxss_yd ge theYD) AND (daxss_yd lt (theYD+0.99999D0)), num_gd )
	if (num_gd gt 1) then begin
		theHours = (daxss_yd[wgd] - theYD) * 24.
		xrange=[long(min(theHours))-0.5, long(max(theHours))+1.5]
		; do plot
		setplot & cc=rainbow(7) & cs=2.0
		plot, theHours, daxss_xrsb[wgd], psym=-4, xrange=xrange, xs=1, $
			/ylog, yrange=goes_range, ys=1, $
			title='DAXSS (black), GOES (green)', $
			xtitle='Hours of '+strtrim(theYD,2), ytitle='XRS-B 1-8 Ang (W/m!U2!N)'
		oplot, (goes_yd-theYD)*24., goes_xrsb, psym=10, color=cc[3]
		dx = (xrange[1]-xrange[0])/50.
		for k=0,num_levels-1 do begin
		  xyouts, xrange[1]+dx, goes_range[0]*(10.^k)*1.5, goes_levels[k], $
		  		charsize=cs, color=cc[3], /noclip
		endfor
		read, 'Next Plot ? ', ans
	endif
endfor

if keyword_set(DEBUG) then stop, 'DEBUG at end of daxss_flare_goes_plot ...'
return
end
