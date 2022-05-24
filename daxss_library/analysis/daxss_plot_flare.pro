;
;	daxss_plot_flare.pro
;
;	Plot DAXSS Flare time series and spectrum
;
; INPUTS
;	date		Fractional day in YD or YMD format
;	/minxss1	Option to over-plot MinXSS-1 flare spectrum too
;					If minxss1 is specific time, then use that time, else match GOES XRS-B level
;	/range_hours	Option to specify time range before / after flare (default is +/- 12 hours)
;					That is, plot is peak-range_hours to peak+range_hours
;	/all		Option to plot DAXSS time series for all dates during IS1 mission
;	/do_stats	Option to calculate number of packets per flare period
;	/pdf		Option to make PDF graphics files after making plot
;	/verbose	Option to print messages
;
;	T. Woods, 3/23/2022
;
pro daxss_plot_flare, date, minxss1=minxss1, range_hours=range_hours, $
							do_stats=do_stats, all=all, pdf=pdf, $
							verbose=verbose, debug=debug

if (n_params() lt 1) AND (not keyword_set(all)) then begin
	date = 0.0D0
	read, 'Enter Date for flare (in YD or YMD format, fractional day): ', date
endif

RANGE_HOURS_DEFAULT = 12.0
if not keyword_set(range_hours) then range_hours = RANGE_HOURS_DEFAULT
if (n_elements(range_hours) ge 2) then begin
	temp_hours = range_hours
	range_hours = (temp_hours[1] - temp_hours[0])/2.
	mid_hour = (temp_hours[1] + temp_hours[0])/2.
	num_dates = n_elements(date)
	date = double(date)
	for ii=0L,num_dates-1 do date[ii] = long(date[ii]) + mid_hour/24.D0
endif

if keyword_set(debug) then verbose=1

if keyword_set(PDF) then pdf_dir = getenv('minxss_data')+path_sep()+'flares'+path_sep()+'daxss'+path_sep()

common daxss_plot_flare_common, daxss_level1, daxss_fe_abundance, minxsslevel1, goes, goes_year, goes_jd
if (goes_year eq !NULL) then goes_year = 0L

;
;  make Fe abundance factor scaling to include in the flare plots with abundance expected between 1 to 4
;
DAXSS_FE_LINE_PEAK = 0.81
DAXSS_FE_CONTINUUM = 1.20
DAXSS_FE_WIDTH = 1L
DAXSS_FE_ABUNDANCE_SCALE_FACTOR = 0.080    ; based on non-flare first light spectrum so Fe abundance is ~ 4.0
DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR = 1E5

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level1' + path_sep()
dfile1 = 'minxss4_l1_mission_length_v1.0.0.sav'
if (daxss_level1 eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
	restore, ddir+dfile1   ; daxss_level1 variable is structure
	; estimate daxss_fe_abundance using Fe line peak at 0.81 keV to continuum level at 1.2 keV
	num_L1 = n_elements(daxss_level1.data)
	daxss_fe_abundance = fltarr(num_L1)
	temp1 = min(abs(daxss_level1.data[0].energy - DAXSS_FE_LINE_PEAK),wfe)
	temp2 = min(abs(daxss_level1.data[0].energy - DAXSS_FE_CONTINUUM),wcont)
	for ii=0L,num_L1-1 do begin
		fe_peak = total(daxss_level1.data[ii].irradiance[wfe-DAXSS_FE_WIDTH:wfe+DAXSS_FE_WIDTH])
		fe_cont = total(daxss_level1.data[ii].irradiance[wcont-DAXSS_FE_WIDTH:wcont+DAXSS_FE_WIDTH])
		daxss_fe_abundance[ii] = (fe_peak / fe_cont) * DAXSS_FE_ABUNDANCE_SCALE_FACTOR
	endfor
endif

;
;	Read MinXSS-1 Level 1 data
;
if keyword_set(minxss1) then begin
	mdir = getenv('minxss_data') + path_sep() + 'fm1' + path_sep() + 'level1' + path_sep()
	mfile1 = 'minxss1_l1_mission_length_v3.1.0.sav'
	if (minxsslevel1 eq !NULL) then begin
		if keyword_set(verbose) then message,/INFO, 'Reading MinXSS-1 L1 data from '+mdir+mfile1
		restore, mdir+mfile1   ; minxsslevel1 variable is structure
	endif
endif

;
;	configure the plot dates
;
if keyword_set(all) then begin
	jd1 = yd2jd(2022059.D0)
	jd2 = systime(/julian)
	num_date = long(jd2-jd1+1L)
	jd_all = findgen(num_date) + jd1
	date = long(jd2yd(jd_all)) + 0.5D0
endif else begin
	num_date = n_elements(date)
endelse

;
;	Do big FOR Loop for a plot per day
;
ans=' '
daxss_xrsb_array = fltarr(num_date)
goes_xrsb_array = fltarr(num_date)

for ii=0L,num_date-1 do begin
	;
	;	figure out the Date in JD and hours
	;
	if (date[ii] gt 2030001L) then begin
		; YYYYMMDD format assumed
		year = long(date[ii]) / 10000L
		month = (long(date[ii]) - year*10000L)/100L
		day = (long(date[ii]) - year*10000L - month*100L)
		hour = (date[ii] - long(date[ii]))*24.
		jd_mid = ymd2jd(year,month,day+hour/24.)
	endif else begin
		; YYYYDOY format assumed
		year = long(date[ii]) / 1000L
		doy = (long(date[ii]) - year*1000L)
		hour = (date[ii] - long(date[ii]))*24.
		jd_mid = yd2jd(date[ii])
	endelse
	if (hour eq 0) then jd_mid += 0.5D0		; force LONG(date) to be middle of day
	jd1 = jd_mid - range_hours/24.
	jd2 = jd_mid + range_hours/24.

	if (jd_mid lt yd2jd(2022045.D0)) or (jd_mid gt systime(/julian)) then begin
		message,/INFO, 'ERROR with Date being outside the InspireSat-1 mission range !'
		continue	; continue the big FOR loop
	endif

	;
	;	Look for DAXSS data within the JD time range
	;
	wdax =  where((daxss_level1.data.time_jd ge jd1) AND (daxss_level1.data.time_jd le jd2), num_dax )
	if (num_dax lt 2) then begin
		message,/INFO, 'ERROR finding any DAXSS data for the date '+strtrim(long(date[ii]),2)
		continue	; continue the big FOR loop
	endif

	;
	;	Read GOES data
	;
	gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
	gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
	if (year ne goes_year) then begin
		if keyword_set(verbose) then message,/INFO, 'Reading GOES data from '+gdir+gfile
		restore, gdir+gfile   ; goes structure array
		goes_jd = gps2jd(goes.time)
		goes_year = year
	endif

	wgoes =  where((goes_jd ge jd1) AND (goes_jd le jd2), num_goes )
	if (num_goes ge 2) then begin
		gyd = jd2yd(goes_jd[wgoes])
		temp = max( goes[wgoes].long, wg_max)
		gpeak = (gyd[wg_max] - long(gyd[wg_max])) * 24.
		gpeak_hour = long(gpeak)
		gpeak_min = (gpeak - gpeak_hour)*60.
		print, '***** GOES  Peak is at ', gpeak_hour, gpeak_min, format="(A,I2,':',F5.2)"
	endif

	;  Print DAXSS peak time too
	dyd = jd2yd(daxss_level1.data[wdax].time_jd)
	temp = max( daxss_level1.data[wdax].x123_slow_count, wd_max)
	dpeak = (dyd[wd_max] - long(dyd[wd_max])) * 24.
	dpeak_hour = long(dpeak)
	dpeak_min = (dpeak - dpeak_hour)*60.
	print, '***** DAXSS Peak is at ', dpeak_hour, dpeak_min, format="(A,I2,':',F5.2)"

	;
	;	make Time Series plot with DAXSS slow counts and GOES XRS irradiance
	;
	;setplot
	;cc=rainbow(7)

	xrange = [jd1, jd2]
	yrange1 = [1E3, 1E6]
	yrange2 = [1E-7,1E-4]
	date_str = strtrim(long(date[ii]),2)
	jd_middle = (jd1+jd2)/2.
	yd_middle = jd2yd(jd_middle)
	hour_middle = (yd_middle - long(yd_middle))*24.
	hour_str = strtrim(long(hour_middle),2)
	p1_title = 'DAXSS Flare '+date_str
	p1_labels = label_date(DATE_FORMAT="%H:%I")

	p1 = plot( daxss_level1.data.time_jd, daxss_level1.data.x123_slow_count, $
		xrange=xrange, xstyle=1, /ylog, yrange=yrange1, ystyle=1, title=p1_title, $
		axis_style = 1, sym='Diamond', $
		xtitle='Time', ytitle='DAXSS Signal (cps)', XTICKFORMAT='LABEL_DATE', XTICKUNITS='Time' )
	p1a = plot( xrange, yrange1[1]*0.99*[1,1], /overplot )

	p1c = plot( daxss_level1.data.time_jd, daxss_fe_abundance*DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR, $
				color='red', sym='Square', line='none', /overplot )
	p1d = plot( xrange, DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR*[1 ,1], line='dash', color='red', /overplot )
	p1e = plot( xrange, DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR*[4 ,4], line='dash', color='red', /overplot )
	xx = xrange[0] + (xrange[1]-xrange[0])*0.01
	t1d = text( xx, DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR*1.05, 'P', /data, color='red'  )
	t1e = text( xx, DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR*4.05, 'C', /data, color='red'  )

	goes_factor = 1E-10
	p1b = plot( goes_jd, goes.long/goes_factor, color='green', /histogram, /overplot )
	yaxis = axis( 'Y', location='right', title='GOES XRS-B (W/m!U2!N)', $
		/log, axis_range=yrange2, coord_transform=[0.,goes_factor], color='green' )

	;
	;	save PDF file (if requested)
	;
	if keyword_set(PDF) then begin
		pdf_file = 'daxss_flare_ts_'+date_str
		if (range_hours ne RANGE_HOURS_DEFAULT) then pdf_file += '_' + hour_str
		pdf_file += '.pdf'
		if keyword_set(verbose) then print, '>>> Saving PDF file: ', pdf_dir+pdf_file
		p1.Save, pdf_dir + pdf_file, RESOLUTION=150, /CLOSE
	endif

	;
	;	make Spectral plot with DAXSS and MinXSS-1 spectra
	;		Average 5 spectra together near the peak
	;
	;setplot
	;cc=rainbow(7)

	wd_max1 = wd_max-2L > 0
	wd_max2 = wd_max+2L < (n_elements(wdax)-1L)
	wd_max_num = wd_max2 - wd_max1 + 1.0
	dax_sp = total(daxss_level1.data[wdax[wd_max1:wd_max2]].irradiance, 2) / wd_max_num
	dax_e =  daxss_level1.data[wdax[wd_max]].energy

	;  get DAXSS 1-8Angstrom Irradiance
	EAfactor = 12.4
	dax_delta_e = abs(dax_e[11] - dax_e[10])
	xrsb_e2 = EAfactor / 1.
	xrsb_e1 = EAfactor / 8.
	wd_xrsb = where( (dax_e ge xrsb_e1) AND (dax_e le xrsb_e2) )
	daxss_xrsb = total( dax_sp[wd_xrsb] * dax_e[wd_xrsb] * 1.602D-19 * 1D3 * 1D4 * dax_delta_e ) ; convert to W/m^2
	print, '@@@ '+date_str+' DAXSS 1-8Ang Irradiance (W/m^2) is ', daxss_xrsb
	if (daxss_xrsb lt 9.95E-8) then daxss_name = 'A' + string(daxss_xrsb/1E-8,format='(F3.1)') $
	else if (daxss_xrsb lt 9.95E-7) then daxss_name = 'B' + string(daxss_xrsb/1E-7,format='(F3.1)') $
	else if (daxss_xrsb lt 9.95E-6) then daxss_name = 'C' + string(daxss_xrsb/1E-6,format='(F3.1)') $
	else if (daxss_xrsb lt 9.95E-5) then daxss_name = 'M' + string(daxss_xrsb/1E-5,format='(F3.1)') $
	else if (daxss_xrsb lt 9.95E-4) then daxss_name = 'X' + string(daxss_xrsb/1E-4,format='(F3.1)') $
	else daxss_name = 'X' + string(daxss_xrsb/1E-4,format='(F4.1)')
	daxss_xrsb_array[ii] = daxss_xrsb

	; identify GOES XRS-B level for the DAXSS peak time
	daxss_peak_jd = daxss_level1.data[wdax[wd_max]].time_jd
	goes_daxss = interpol( goes.long, goes_jd, daxss_peak_jd ) > 1E-8
	if (goes_daxss lt 9.95E-8) then goes_name = 'A' + string(goes_daxss/1E-8,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-7) then goes_name = 'B' + string(goes_daxss/1E-7,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-6) then goes_name = 'C' + string(goes_daxss/1E-6,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-5) then goes_name = 'M' + string(goes_daxss/1E-5,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-4) then goes_name = 'X' + string(goes_daxss/1E-4,format='(F3.1)') $
	else goes_name = 'X' + string(goes_daxss/1E-4,format='(F4.1)')
	goes_xrsb_array[ii] = goes_daxss

	print, '***** GOES Level of ', goes_name, ' versus DAXSS 1-8Ang Level of ', daxss_name

	if keyword_set(minxss1) then begin
	  read, 'Next Plot ? ', ans

	  if (minxss1 gt 2022045L) then begin
		;
		;  Use date given in MinXSS-1 input variable to find closest MinXSS-1 spectrum
		;
		mDate = minxss1
		if (mDate gt 2030001L) then begin
			; YYYYMMDD format assumed
			myear = long(mDate) / 10000L
			mmonth = (long(mDate) - myear*10000L)/100L
			mday = (long(mDate) - myear*10000L - mmonth*100L)
			mhour = (mDate - long(mDate))*24.
			minxss_jd = ymd2jd(myear,mmonth,mday+mhour/24.)
		endif else begin
			; YYYYDOY format assumed
			myear = long(mDate) / 100L
			mdoy = (long(mDate) - myear*1000L)
			mhour = (mDate - long(mDate))*24.
			minxss_jd = yd2jd(mDate)
		endelse
		; find peak signal within 10 minutes of given time
		delta_jd = 10./60./24.
		wgd = where( (minxsslevel1.x123.time.jd ge (minxss_jd-delta_jd)) AND $
					(minxsslevel1.x123.time.jd le (minxss_jd+delta_jd)), num_gd )
		if (num_gd gt 3) then begin
			temp = max( minxsslevel1.x123[wgd].x123_slow_count, wm_max )
			wm_match = wgd[wm_max]
			minxss_sp = minxsslevel1.x123[wm_match].irradiance
			minxss_e = minxsslevel1.x123[wm_match].energy
			print, '*** MinXSS-1 Time for Peak Match is ', minxsslevel1.x123[wm_match].time.human
		endif else begin
			temp = min(abs(minxsslevel1.x123.time.jd - minxss_jd), wm_match )
			minxss_sp = total( minxsslevel1.x123[wm_match-1:wm_match+1].irradiance,2) / 3.0
			minxss_e = minxsslevel1.x123[wm_match].energy
			print, '*** MinXSS-1 Time for Time Match is ', minxsslevel1.x123[wm_match].time.human
		endelse
	  endif else begin
		;
		; find MinXSS-1 spectrum at same level of GOES XRS
		;	First read GOES data for 2016
		;
		gfile2 = 'goes_1mdata_widx_2016.sav'
		restore, gdir+gfile2   ; goes structure array
		goes2_jd = gps2jd(goes.time)
		w2016 = where( minxsslevel1.x123.time.yyyydoy lt 2017000L )
		minxss_jd = minxsslevel1.x123[w2016].time.jd
		goes2_minxss = interpol( goes.long, goes2_jd, minxss_jd )
		temp = min(abs(goes2_minxss - goes_daxss), wm_match )
		minxss_sp = total( minxsslevel1.x123[w2016[wm_match-1:wm_match+1]].irradiance,2) / 3.0
		minxss_e = minxsslevel1.x123[w2016[wm_match]].energy
		print, '*** MinXSS-1 Time for GOES-XRS-B Match is ', minxsslevel1.x123[w2016[wm_match]].time.human
	  endelse

	  ;  Integrate MinXSS spectrum for XRS-B 1-8 Ang Irradiance
	  minxss_delta_e = minxss_e[11] - minxss_e[10]
	  wm_xrsb = where( (minxss_e ge xrsb_e1) AND (minxss_e le xrsb_e2) )
	  ; convert to W/m^2
	  minxss_xrsb = total( minxss_sp[wd_xrsb] * minxss_e[wd_xrsb] * 1.602D-19 * 1D3 * 1D4 * minxss_delta_e )
	  print, '*** MinXSS 1-8Ang Irradiance (W/m^2) is ', minxss_xrsb

	  ;
	  ;	do X-ray spectral PLOT
	  ;
		x2range = [0.,8.]
		y2range = [1E3,1E9]
		p2_title = 'DAXSS '+goes_name+' Flare on '+date_str
		p2 = plot( dax_e, dax_sp, $
			xrange=x2range, xstyle=1, /ylog, yrange=y2range, ystyle=1, title=p2_title, $
			axis_style = 2, /histogram, xtitle='Energy (keV)', ytitle='Irradiance (ph/s/cm!U2!N/keV)' )
		p2b = plot( minxss_e, minxss_sp, /histogram, color='red', /overplot )

		if keyword_set(PDF) then begin
			pdf_file = 'daxss_flare_spectrum_'+date_str
			if (range_hours ne RANGE_HOURS_DEFAULT) then pdf_file += '_' + hour_str
			pdf_file += '.pdf'
			if keyword_set(verbose) then print, '>>> Saving PDF file: ', pdf_dir+pdf_file
			p2.Save, pdf_dir + pdf_file, RESOLUTION=150, /CLOSE
		endif

	endif	; endif is for IF keyword_set(minxss1)

 	; if (num_date gt 1) then read, 'Next Date ? ', ans

endfor   ; END of big loop

if keyword_set(all) then begin
	;
	;	do Plot of GOES-XRS-B to DAXSS calculated XRS-B irradiance
	;
	x3range = [1E-7,1E-4]
	y3range = x3range
	p3_title = 'XRS-B Irradiance Comparison'
	p3 = plot( goes_xrsb_array, daxss_xrsb_array, sym='Diamond', line='none', $
		/xlog, xrange=x3range, xstyle=1, /ylog, yrange=y3range, ystyle=1, title=p3_title, $
		axis_style = 2, xtitle='GOES XRS-B (W/m!U2!N)', ytitle='DAXSS 0.1-0.8nm (W/m!U2!N)' )
	p3b = plot( x3range, y3range, line='dash', color='green', /overplot )

	if keyword_set(PDF) then begin
		pdf_file = 'daxss_goes_compare.pdf'
		if keyword_set(verbose) then print, '>>> Saving PDF file: ', pdf_dir+pdf_file
		p3.Save, pdf_dir + pdf_file, RESOLUTION=150, /CLOSE
	endif

	;
	;	do Plot of Ratio of DAXSS to GOES-XRS-B
	;
	x4range = [1E-7,1E-4]
	y4range = [0,3]
	p4_title = 'XRS-B Irradiance Comparison'
	ratio_daxss_goes = daxss_xrsb_array / (goes_xrsb_array>1E-7)
	print, '>>>  Median of Ratio DAXSS/GOES = ', median(ratio_daxss_goes)
	p4 = plot( goes_xrsb_array, ratio_daxss_goes, sym='Diamond', line='none', $
		/xlog, xrange=x4range, xstyle=1, yrange=y4range, ystyle=1, title=p4_title, $
		axis_style = 2, xtitle='GOES XRS-B (W/m!U2!N)', ytitle='Ratio DAXSS / GOES-XRS-B' )
	p4b = plot( x4range, [1,1], line='dash', color='green', /overplot )
	if keyword_set(PDF) then begin
		pdf_file = 'daxss_goes_compare_ratio.pdf'
		if keyword_set(verbose) then print, '>>> Saving PDF file: ', pdf_dir+pdf_file
		p4.Save, pdf_dir + pdf_file, RESOLUTION=150, /CLOSE
	endif
endif

;
;	/do_stats	Option to calculate number of packets per flare period
;
if keyword_set(do_stats) then begin
	num_stats = 0L
	num_data = n_elements(daxss_level1.data)
	data_num_per_flare = lonarr(num_data)
	data_flare_jd = dblarr(num_data)
	num1 = 1L
	TIME_SEC_STEP = 301.
	for ii=1L,num_data-1 do begin
		if ((daxss_level1.data[ii].time_gps - daxss_level1.data[ii-1].time_gps) lt TIME_SEC_STEP) then begin
			num1 += 1L
		endif else begin
			data_num_per_flare[num_stats] = num1
			data_flare_jd[num_stats] = daxss_level1.data[ii-num1].time_jd
			num_stats += 1L
			num1 = 1L
		endelse
	endfor
	; save info for last flare
	data_num_per_flare[num_stats] = num1
	data_flare_jd[num_stats] = daxss_level1.data[ii-1].time_jd
	num_stats += 1L
	; clean up
	data_num_per_flare = data_num_per_flare[0:num_stats-1]
	data_flare_jd = data_flare_jd[0:num_stats-1]
	;  print results
	print, ' '
	print, '*****  STATS for Flare Data *****'
	print, '  No.    YYYYDOY- Hour  Number Spectra for Flare '
	data_flare_yd = jd2yd(data_flare_jd)
	data_flare_hour = (data_flare_yd - long(data_flare_yd))*24.
	for ii=0L,num_stats-1 do print, ii, long(data_flare_yd[ii]), data_flare_hour[ii], $
								data_num_per_flare[ii], format="(I6,I10,'-',F5.2,'h',I6)"
	print, ' '
ENDIF

if keyword_set(debug) then stop, "DEBUG at end of daxss_plot_flare.pro ..."
return
end
