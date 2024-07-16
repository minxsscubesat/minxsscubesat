;
;	daxss_plot_flare.pro
;
;	Plot DAXSS Flare time series and spectrum
;	Version 2 = plot procedure used instead of plot function
;
; INPUTS
;	date		Fractional day in YD or YMD format
;	/range_hours	Option to specify time range before / after flare (default is +/- 12 hours)
;					That is, plot is peak-range_hours to peak+range_hours
;	/all		Option to plot DAXSS time series for all dates during IS1 mission
;	/do_stats	Option to calculate number of packets per flare period
;	/pdf		Option to make PDF graphics files after making plot
;	/verbose	Option to print messages
;	/script_make	Option to make a downlink script
;						User will be asked for Hour-Minute start time.
;						Actual start time is -5 minutes before this time becasue the
;						flare downlink script code is written with assumption time is flare peak time
;	/multi_script	Option to make multiple downlink scripts over a time range (every 20 minutes)
;	/eclipse_remove	Option to NOT plot the orbit eclipse shaded boxes
;	/old_template	Option to use old Playback Script Template (new one assumes Flash operations)
;
;	Code Version 1:  3/23/2022	T. Woods
;	Code Version 2:  9/30/2022	T. Woods, plot procedure used instead of plot function
;	Code Version 3:  6/30/2023	T. Woods, changed to use new Downlink Script for FLASH operations
;	Code Version 3.1: 9/6/2023  T. Woods, added option to make multiple scripts over a time range
;	Code Version 3.2: 10/31/2023  T. Woods, added the SBAND option
;								Example Call for SBAND> daxss_plot_flare, date, /SBAND, /verbose
;
;
pro daxss_plot_flare, date, range_hours=range_hours, SBAND=SBAND, $
							do_stats=do_stats, all=all, pdf=pdf, $
							script_make=script_make, multi_script=multi_script, $
							eclipse_remove=eclipse_remove, $
							old_template=old_template, reload_common=reload_common, $
							version=version, verbose=verbose, debug=debug

if (n_params() lt 1) AND (not keyword_set(all)) then begin
	print, 'USAGE for checking for DAXSS data: daxss_plot_flare, date'
	print, 'USAGE for plotting all DAXSS data: daxss_plot_flare, /all, /pdf'
	print, 'USAGE for making single DAXSS playback script: daxss_plot_flare, date, /script_make'
	print, 'USAGE for making many DAXSS playback scripts: daxss_plot_flare, date, /multi_script'
	date = 0.0D0
	read, 'Enter Date for flare (in YD or YMD format, fractional day): ', date
endif

if not keyword_set(version) then version = '2.0.0'
version_long = long(version)

;  New option 10/31/2023 to downlink 7 hours of data by SBAND option
useSBAND = (keyword_set(SBAND) ? 1 : 0)

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
if (range_hours ne RANGE_HOURS_DEFAULT) then hour_str = strtrim(long(range_hours),2)

if keyword_set(debug) then verbose=1

if keyword_set(all) then begin
	pdf = 1
	reload_common = 1
endif
pdf_dir = getenv('minxss_data')+path_sep()+'flares'+path_sep()+'daxss'+path_sep()

common daxss_plot_flare2_common, daxss_level1_data, hk, hk_jd, sci, sci_jd, picosim2,  $
						goes, goes_year, goes_jd

if (goes_year eq !NULL) then goes_year = 0L

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level1' + path_sep()
dfile1 = 'daxss_l1_mission_length_v'+version+'.sav'
if (daxss_level1_data eq !NULL) OR keyword_set(reload_common) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
	restore, ddir+dfile1   ; daxss_level1 variable is structure
endif

;
;	Read DAXSS Level 0C
;
ddir0c = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level0c' + path_sep()
dfile0c = 'daxss_l0c_all_mission_length_v'+version+'.sav'
if (hk eq !NULL) OR keyword_set(reload_common) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L0C data from '+ddir0c+dfile0c
	restore, ddir0c+dfile0c   ; hk and sci variables are packet structures
	hk_jd = hk.time_jd  ; gps2jd(hk.time)
	sci_jd = sci.time_jd ; gps2jd(sci.time)
	; make picosim2 time series too
	picosim2 = reform(sci.picosim_data[2]) / (sci.picosim_integ_time/1000.)
endif
hk_x123_on = (hk.daxss_cdh_enables AND '0002'X)

if (version_long ge 2) then begin
	; Version 2 new variables
	slow_cps = daxss_level1_data.x123_slow_cps
endif else begin
	; Version 1
	slow_cps = daxss_level1_data.x123_slow_count
endelse

;
;	configure the plot dates
;
if keyword_set(all) then begin
	jd1 = yd2jd(2022059.0D0)
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
pdf_loop = 0
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
	if (long(hour) eq 0) then jd_mid += 0.5D0		; force LONG(date) to be middle of day
	jd1 = jd_mid - range_hours/24.D0
	jd2 = jd_mid + range_hours/24.D0

	date_str = strtrim(long(date[ii]),2)
	; if keyword_set(debug) then stop, 'DEBUG date[ii] and jd1, jd2 ...'

	if (jd_mid lt yd2jd(2022045.D0)) or (jd_mid gt systime(/julian)) then begin
		message,/INFO, 'ERROR with Date being outside the InspireSat-1 mission range !'
		continue	; continue the big FOR loop
	endif

	;
	;	Look for DAXSS data within the JD time range
	;
	wdax =  where((daxss_level1_data.time_jd gt jd1) AND (daxss_level1_data.time_jd lt jd2), num_dax )
	if (num_dax lt 2) then begin
		message,/INFO, 'ERROR finding any DAXSS data for the date '+strtrim(long(date[ii]),2)
		; continue	; continue the big FOR loop
	endif

	; print time range of DAXSS data in this plot window
	if keyword_set(verbose) then begin
		message, /INFO, 'DAXSS date range is: '
		print, '     ' + strtrim(jpmjd2iso(min(daxss_level1_data[wdax].time_jd)),2)+ ' to '+ $
			strtrim(jpmjd2iso(max(daxss_level1_data[wdax].time_jd)),2)
	endif

	;
	;	Read GOES data
	;
	gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
	gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
	if (year ne goes_year) OR keyword_set(reload_common) then begin
		if keyword_set(verbose) then message,/INFO, 'Reading GOES data from '+gdir+gfile
		restore, gdir+gfile   ; goes structure array
		goes_jd = gps2jd(goes.time)
		goes_year = year
	endif

	wgoes =  where((goes_jd gt jd1) AND (goes_jd lt jd2), num_goes )
	if (num_goes ge 2) then begin
		gyd = jd2yd(goes_jd[wgoes])
		temp = max( goes[wgoes].long, wg_max)
		gpeak = (gyd[wg_max] - long(gyd[wg_max])) * 24.
		gpeak_hour = long(gpeak)
		gpeak_min = (gpeak - gpeak_hour)*60.
		print, '***** GOES  Peak is at ', gpeak_hour, gpeak_min, format="(A,I2,':',F5.2)"
	endif

	if (num_dax ge 2) then begin
		;  Print DAXSS peak time too
		dyd = jd2yd(daxss_level1_data[wdax].time_jd)
		temp = max( slow_cps[wdax], wd_max)
		dpeak = (dyd[wd_max] - long(dyd[wd_max])) * 24.
		dpeak_hour = long(dpeak)
		dpeak_min = (dpeak - dpeak_hour)*60.
		print, '***** DAXSS Peak is at ', dpeak_hour, dpeak_min, format="(A,I2,':',F5.2)"
	endif

	;
	;	make Time Series plot with DAXSS slow counts and GOES XRS irradiance
	;
	pdf_loop = 0

pdf_loopback:
	if keyword_set(pdf) then begin
		if pdf_loop eq 0 then begin
			; make the PS (and PDF) files first and then plot to screen
			pdf_file = 'daxss_flare_ts_'+date_str
			if (range_hours ne RANGE_HOURS_DEFAULT) then pdf_file += '_' + hour_str
			pdf_file += '.ps'
			pdf_file_fullname = pdf_dir + pdf_file
			ps_on, filename=pdf_file_fullname    ; , /landscape
		endif
	endif

	setplot
	cc=rainbow(7)
	dots

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
	if not keyword_set(eclipse_remove) then p1_title += ' (red=in-sun flag,blue=PicoSIM-2)' $
	else p1_title += ' (blue=PicoSIM-2)'
	xmargin = [5.2,5.2]
	ymargin = [3.6,2]

	plot, daxss_level1_data.time_jd, slow_cps, /nodata, xmargin=xmargin, ymargin=ymargin, $
		xrange=xrange, xstyle=1, /ylog, yrange=yrange1, ystyle=1+8, title=p1_title, $
		psym=4, xtitle='Time', ytitle='DAXSS Signal (cps)', XTICKFORMAT='LABEL_DATE', XTICKUNITS='Time'
	oplot,  xrange, yrange1[1]*0.99*[1,1]

	;
	;	plot grey boxes for orbit eclipse periods
	;
	; **** OLD WAY ****
	; overplot Eclipse times using HK data
	; p1eclipse = plot( hk_jd, hk.eclipse_state*8E3 + 2E3, color='red', sym='Square', /overplot )
	; p1eclipse = plot( hk_jd, hk.daxss_curr*4E4 + 2E3, color='red', sym='Square', /overplot )
	; p1eclipse = plot( hk_jd, hk.daxss_sps_sum*0.05 + 2E3, color='red', sym='Square', /overplot )
	;stop, 'Debug HK packet ...'
	;
	; **** NEW WAY ****
	;
	if not keyword_set(eclipse_remove) then begin
		; get orbit eclipse periods from TLE orbit code (IS-1 Satellite ID = 51657)
		orbit_jd = jd1 + findgen(1440L)*(jd2-jd1)/1439.0
		spacecraft_location, orbit_jd, orbit_location, orbit_sunlight, id_satellite=51657L
		oplot, orbit_jd, orbit_sunlight*7E5 + 2E3, color=cc[0]
		oplot, xrange, 2E3*[1,1], color=cc[0], linestyle=2
		; stop, 'DEBUG orbit location ...'
	endif

	; now plot the DAXSS data
	oplot, daxss_level1_data.time_jd, slow_cps, psym=-4

	goes_factor = 1E-10
	oplot, goes_jd, (goes.long/goes_factor), color=cc[3], psym=10
	axis, yaxis=1, ytitle='GOES XRS-B (W/m!U2!N)', $
		/ylog, yrange=yrange2, color=cc[3]   ;  coord_transform=[0.,goes_factor]

	; over-plot PicoSIM[2] time series as indication of good pointing
	oplot, sci_jd, picosim2/1E3, psym=8, color=cc[4]

	; over-plot HK_X123_ON flag
	oplot, hk_jd, hk_x123_on * yrange1[1]*0.8/2., psym=6

	;
	;	save PDF file (if requested)
	;
	if keyword_set(pdf) then begin
		if pdf_loop eq 0 then begin
			ps_off
			if keyword_set(verbose) then message, /INFO, 'Making PDF file: '+pdf_file_fullname
			pstopdf, pdf_file_fullname, /wait, /deleteps
		endif
		pdf_loop += 1
		;  loop-back for plot to screen
		if (pdf_loop eq 1) then goto, pdf_loopback
	endif

	;
	;		Average 5 DAXSS spectra together near the peak
	;
	if (num_dax lt 2) OR keyword_set(script_make) or keyword_set(multi_script) $
		then goto, downlink_script_option

	wd_max1 = wd_max-2L > 0
	wd_max2 = wd_max+2L < (n_elements(wdax)-1L)
	wd_max_num = wd_max2 - wd_max1 + 1.0
	dax_sp = total(daxss_level1_data[wdax[wd_max1:wd_max2]].irradiance, 2) / wd_max_num
	dax_e =  daxss_level1_data[wdax[wd_max]].energy

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
	daxss_peak_jd = daxss_level1_data[wdax[wd_max]].time_jd
	goes_daxss = interpol( goes.long, goes_jd, daxss_peak_jd ) > 1E-8
	if (goes_daxss lt 9.95E-8) then goes_name = 'A' + string(goes_daxss/1E-8,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-7) then goes_name = 'B' + string(goes_daxss/1E-7,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-6) then goes_name = 'C' + string(goes_daxss/1E-6,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-5) then goes_name = 'M' + string(goes_daxss/1E-5,format='(F3.1)') $
	else if (goes_daxss lt 9.95E-4) then goes_name = 'X' + string(goes_daxss/1E-4,format='(F3.1)') $
	else goes_name = 'X' + string(goes_daxss/1E-4,format='(F4.1)')
	goes_xrsb_array[ii] = goes_daxss

	print, '***** GOES Level of ', goes_name, ' versus DAXSS 1-8Ang Level of ', daxss_name


downlink_script_option:
	if (num_date eq 1) AND (keyword_set(script_make) OR keyword_set(multi_script) $
			OR keyword_set(SBAND)) then begin
		;
		;	make a downlink script from user's input
		;
		folder_flare_script = getenv('minxss_data') + '/flares/daxss/scripts/'
		if keyword_set(multi_script) then begin
			msg_info = 'USER will select Time Range for multiple downlinks (in 20-min increments).'
			msg1 = 'USER: Select START TIME for Multiple DAXSS SCI downlinks.'
			msg2 = 'USER: Select END TIME for Multiple DAXSS SCI downlinks.'
		endif else begin
			msg_info = 'USER will select Time for downlink (Time-5min, Time+'
			msg_info += (keyword_set(SBAND)? '7hours).': '15min).' )
			msg1 = 'USER: Select TIME for single DAXSS SCI downlink.'
			msg2 = ''
		endelse
USER_SCRIPT_INPUT:
		;  User selects time on plot
		print, '*****'
		print, msg_info
		print, msg1
		myhour = 12. & myminute=0. & ans=' '
		read, '>>>  Enter the hour, minute value : ', myhour, myminute
		x_yd = long(jd2yd(jd_mid))
		x_jd = yd2jd( double(x_yd) + myhour/24. + myminute/24./60. )

		if keyword_set(multi_script) then begin
			print, ' '
			print, msg2
			myhour2 = 12. & myminute2=0.
			read, '>>>  Enter the END hour, minute value : ', myhour2, myminute2
			x2_jd = yd2jd( double(x_yd) + myhour2/24. + myminute2/24./60. )
			if (x2_jd lt x_jd) then begin
				print, 'ERROR having END time before START time, Try Again...'
				goto, USER_SCRIPT_INPUT
			endif
		endif

		my_time_iso = jpmjd2iso(x_jd)
		goes_daxss = interpol( goes.long, goes_jd, x_jd ) > 1E-8
		if (goes_daxss lt 9.95E-8) then flare_class = 'A' + string(goes_daxss/1E-8,format='(F3.1)') $
		else if (goes_daxss lt 9.95E-7) then flare_class = 'B' + string(goes_daxss/1E-7,format='(F3.1)') $
		else if (goes_daxss lt 9.95E-6) then flare_class = 'C' + string(goes_daxss/1E-6,format='(F3.1)') $
		else if (goes_daxss lt 9.95E-5) then flare_class = 'M' + string(goes_daxss/1E-5,format='(F3.1)') $
		else if (goes_daxss lt 9.95E-4) then flare_class = 'X' + string(goes_daxss/1E-4,format='(F3.1)') $
		else flare_class = 'X' + string(goes_daxss/1E-4,format='(F4.1)')
		if keyword_set(multi_script) then begin
			my_time2_iso = jpmjd2iso(x2_jd)
			time_iso = [my_time_iso, my_time2_iso]
			print, 'Downlink Scripts are from '+my_time_iso+'  to  '+my_time2_iso
			oplot, x_jd*[1,1], yrange1, linestyle=2, color=cc[4]
			oplot, x2_jd*[1,1], yrange1, linestyle=2, color=cc[4]
		endif else begin
			if keyword_set(SBAND) then deltaJD = 7./24.D0 else deltaJD = 15./24./60.D0
			time_iso = [jpmjd2iso(x_jd-5./24./60.), jpmjd2iso(x_jd+deltaJD) ]
			print, 'Downlink Script is for '+flare_class+' flare level at '+my_time_iso
			oplot, x_jd*[1,1], yrange1, color=cc[4]
			oplot, (x_jd-5./24./60.D0)*[1,1], yrange1, linestyle=2, color=cc[4]
			oplot, (x_jd+deltaJD)*[1,1], yrange1, linestyle=2, color=cc[4]
		endelse

		read, 'Is time OK for downlinking data ? (Y/N) ', ans
		ans = strmid(strupcase(ans),0,1)
		if (ans eq 'Y') then begin
			if keyword_set(SBAND) then begin
				daxss_downlink_script, time_iso=time_iso, saveloc=folder_flare_script, $
					class=flare_class, /verbose, /SBAND
			endif else if keyword_set(old_template) then begin
				daxss_downlink_script, time_iso=time_iso, saveloc=folder_flare_script, $
					class=flare_class, /verbose
			endif else begin
				; ***** New addition 6/30/2023 to use Flash downlink template file
				daxss_downlink_flash_script, time_iso=time_iso, saveloc=folder_flare_script, $
					class=flare_class, /verbose
			endelse
		endif
	endif

	; pause for each plot if plotting all of them
	if keyword_set(all) then wait,0.25

endfor   ; END of big loop

if keyword_set(all) then begin
	;
	;	do Plot of GOES-XRS-B to DAXSS calculated XRS-B irradiance
	;
	if keyword_set(pdf) then begin
		pdf_file = 'daxss_goes_compare.ps'
		; if keyword_set(verbose) then print, '>>> Saving GOES PS plot: ', pdf_dir+pdf_file
		pdf_file_fullname = pdf_dir + pdf_file
		ps_on, filename=pdf_file_fullname    ; , /landscape
	endif else begin
		read, 'Next Plot for GOES Validation ? ', ans
	endelse
	x3range = [1E-7,1E-4]
	y3range = x3range
	p3_title = 'XRS-B Irradiance Comparison'
	setplot & cc=rainbow(7)
	plot, goes_xrsb_array, daxss_xrsb_array, sym=4, $
		/xlog, xrange=x3range, xstyle=1, /ylog, yrange=y3range, ystyle=1, title=p3_title, $
		xtitle='GOES XRS-B (W/m!U2!N)', ytitle='DAXSS 0.1-0.8nm (W/m!U2!N)'
	oplot, x3range, y3range, line=2, color=cc[3]

	if keyword_set(pdf) then begin
		ps_off
		if keyword_set(verbose) then message, /INFO, '>>> Making GOES Comparison PDF plot: '+pdf_file_fullname
		pstopdf, pdf_file_fullname, /wait, /deleteps
	endif

	;
	;	do Plot of Ratio of DAXSS to GOES-XRS-B
	;
	if keyword_set(pdf) then begin
		pdf_file = 'daxss_goes_compare_ratio.ps'
		; if keyword_set(verbose) then print, '>>> Saving GOES PS plot: ', pdf_dir+pdf_file
		pdf_file_fullname = pdf_dir + pdf_file
		ps_on, filename=pdf_file_fullname    ; , /landscape
	endif else begin
		read, 'Next Plot for GOES Validation ? ', ans
	endelse

	x4range = [1E-7,1E-4]
	y4range = [0,3]
	p4_title = 'XRS-B Irradiance Comparison'
	ratio_daxss_goes = daxss_xrsb_array / (goes_xrsb_array>1E-7)
	print, '>>>  Median of Ratio DAXSS/GOES = ', median(ratio_daxss_goes)
	setplot & cc=rainbow(7)
	plot, goes_xrsb_array, ratio_daxss_goes, psym=4, $
		/xlog, xrange=x4range, xstyle=1, yrange=y4range, ystyle=1, title=p4_title, $
		xtitle='GOES XRS-B (W/m!U2!N)', ytitle='Ratio DAXSS / GOES-XRS-B'
	oplot, x4range, [1,1], line=2, color=cc[3]
	if keyword_set(pdf) then begin
		ps_off
		if keyword_set(verbose) then message, /INFO, '>>> Making GOES Ratio PDF plot: '+pdf_file_fullname
		pstopdf, pdf_file_fullname, /wait, /deleteps
	endif
endif

;
;	/do_stats	Option to calculate number of packets per flare period
;
if keyword_set(do_stats) then begin
	num_stats = 0L
	num_data = n_elements(daxss_level1_data)
	data_num_per_flare = lonarr(num_data)
	data_flare_jd = dblarr(num_data)
	num1 = 1L
	TIME_SEC_STEP = 301.
	for ii=1L,num_data-1 do begin
		if ((daxss_level1_data[ii].time_gps - daxss_level1_data[ii-1].time_gps) lt TIME_SEC_STEP) then begin
			num1 += 1L
		endif else begin
			data_num_per_flare[num_stats] = num1
			data_flare_jd[num_stats] = daxss_level1_data[ii-num1].time_jd
			num_stats += 1L
			num1 = 1L
		endelse
	endfor
	; save info for last flare
	data_num_per_flare[num_stats] = num1
	data_flare_jd[num_stats] = daxss_level1_data[ii-1].time_jd
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
