;
;	daxss_plot_power.pro
;
;	Plot DAXSS Power (eclipse) time series
;
; INPUTS
;	date		Fractional day in YD or YMD format
;	/range_hours	Option to specify time range before / after flare (default is +/- 12 hours)
;					That is, plot is peak-range_hours to peak+range_hours
;	/fast		Option to include X123_FAST_COUNT in time series
;	/gp			Option to include X123_GP_COUNT in time series
;	/all		Option to plot DAXSS time series for all dates during IS1 mission
;	/do_stats	Option to calculate number of packets per flare period
;	/pdf		Option to make PDF graphics files after making plot
;	/verbose	Option to print messages
;
;	T. Woods, 7/24/2022
;
pro daxss_plot_power, date, range_hours=range_hours, fast=fast, gp=gp, $
							do_stats=do_stats, all=all, pdf=pdf, $
							version=version, verbose=verbose, debug=debug

if (n_params() lt 1) AND (not keyword_set(all)) then begin
	date = 0.0D0
	read, 'Enter Date for DAXSS Power Plot (in YD or YMD format, fractional day): ', date
endif

if not keyword_set(version) then version = '2.0.0'
version_long = long(version)

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

if keyword_set(PDF) then pdf_dir = getenv('minxss_data')+path_sep()+'fm3'+path_sep()+ $
								'trends'+path_sep()+'power'+path_sep()

common daxss_plot_power_common, hk, hk_yd, hk_jd, sci, sci_yd, sci_jd

;
;	Read DAXSS Level 0C (HK and SCI packetds)
;
ddir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level0c' + path_sep()
dfile0c = 'daxss_l0c_all_mission_length_v'+version+'.sav'
if (hk eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L0C data from '+ddir+dfile0c
	restore, ddir+dfile0c   ; HK and SCI variables are structures
	hk_jd = gps2jd(hk.time) & hk_yd = jd2yd(hk_jd)
	sci_jd = gps2jd(sci.time) & sci_yd = jd2yd(sci_jd)
endif

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
slow_cps = sci.x123_slow_count / (sci.x123_accum_time/1000. > 1.)
fast_cps = sci.x123_fast_count / (sci.x123_accum_time/1000. > 1.)
gp_cps = sci.x123_gp_count / (sci.x123_accum_time/1000. > 1.)

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
	jd1 = jd_mid - range_hours/24.
	jd2 = jd_mid + range_hours/24.
	if keyword_set(debug) then stop, 'DEBUG date and jd1, jd2 ...'

	if (jd_mid lt yd2jd(2022045.D0)) or (jd_mid gt systime(/julian)) then begin
		message,/INFO, 'ERROR with Date being outside the InspireSat-1 mission range !'
		continue	; continue the big FOR loop
	endif

	;
	;	Look for DAXSS data within the JD time range
	;
	wdax =  where((sci_jd ge jd1) AND (sci_jd le jd2), num_dax )
	whk = where((hk_jd ge jd1) AND (hk_jd le jd2), num_hk )
	if (num_dax lt 2) then begin
		message,/INFO, 'ERROR finding any DAXSS data for the date '+strtrim(long(date[ii]),2)
		continue	; continue the big FOR loop
	endif

	;
	;	make Time Series plot with DAXSS (SCI)
	;		Eclipse_State (0-1)
	;		ENABLE_X123 (0-1)  SHIFTED to (0.1-1.1)
	;		EPS_5V_CUR  (0-900 mA)  SCALED by DIV 1000.
	;		SCI_SPS_SUM  (0-123,800) SCALED to (0-1.24) by DIV 100,000
	;		X123_ACCUM_TIME (0-15800 msec)  SCALED to (0-1.58) by DIV 10000.
	;		X123_SLOW_COUNT (0-124,000 cps) SCALED to (0-1.24) by DIV 100,000.
	;		X123_FAST_COUNT (0-2,700,00 cps) SCALED to (0-27.) by DIV 100,000.
	;
	;setplot
	;cc=rainbow(7)

	; dynamically adjust Plot X-range
	if (range_hours eq RANGE_HOURS_DEFAULT) then begin
		jd1 = min(sci_jd[wdax]) - 1.4E-3 ; 4-min border added to data range
		jd2 = max(sci_jd[wdax]) + 1.4E-3
	endif
	xrange = [jd1, jd2]
	yrange = [0.,1.5]
	date_str = strtrim(long(date[ii]),2)
	jd_middle = (jd1+jd2)/2.
	yd_middle = jd2yd(jd_middle)
	hour_middle = (yd_middle - long(yd_middle))*24.
	hour_str = strtrim(long(hour_middle),2)
	p1_title = 'DAXSS Power '+date_str
	p1_labels = label_date(DATE_FORMAT="%H:%I")

	p1a = plot( sci_jd, sci.eclipse_state, $
		xrange=xrange, xstyle=1, yrange=yrange, ystyle=1, title=p1_title, $
		axis_style = 2, sym='diamond', $
		xtitle='Time', ytitle='Power Indicators', XTICKFORMAT='LABEL_DATE', XTICKUNITS='Time' )
	; p1a = plot( xrange, yrange1[1]*0.99*[1,1], /overplot )
	xx = xrange[0] + (xrange[1]-xrange[0])*0.02
	t1a = text( xx, 1.03, 'Eclipse', /data  )

  	p1b = plot( sci_jd, sci.enable_x123+0.1, color='green', sym='diamond', /overplot )
	t1b = text( xx, 1.13, 'Enable', /data, color='green' )

  	p1c = plot( sci_jd, sci.eps_5v_cur/1000., color='red', sym='diamond', /overplot )
	t1c = text( xx, 0.93, '5V_Cur', /data, color='red' )

  	p1d = plot( sci_jd, sci.sci_sps_sum/100000., color='blue', sym='square', /overplot )
	t1d = text( xx, 1.33, 'SPS_Sum', /data, color='blue' )

  	p1e = plot( sci_jd, (sci.x123_accum_time/10000. < 1.48), color='gold', sym='triangle', /overplot )
	t1e = text( xx, 1.40, 'Accum_Time', /data, color='gold' )

  	p1f = plot( sci_jd, slow_cps/100000., color='purple', sym='triangle', /overplot )
	t1f = text( xx, 0.73, 'Slow_cps', /data, color='purple' )

	if keyword_set(fast) then begin
  		p1g = plot( sci_jd, fast_cps/100000., color='magenta', sym='triangle', /overplot )
		t1g = text( xx, 0.83, 'Fast_cps', /data, color='magenta' )
	endif

	if keyword_set(gp) then begin
  		p1g = plot( sci_jd, gp_cps/100000., color='peru', sym='triangle', /overplot )
		t1g = text( xx, 0.63, 'GP_cps', /data, color='peru' )
	endif

	;
	;	save PDF file (if requested)
	;
	if keyword_set(PDF) then begin
		pdf_file = 'daxss_power_ts_'+date_str
		if (range_hours ne RANGE_HOURS_DEFAULT) then pdf_file += '_' + hour_str
		pdf_file += '.pdf'
		if keyword_set(verbose) then print, '>>> Saving PDF file: ', pdf_dir+pdf_file
		p1a.Save, pdf_dir + pdf_file, RESOLUTION=150, /CLOSE
	endif

 	; if (num_date gt 1) then read, 'Next Date ? ', ans

endfor   ; END of big loop

;
;	/do_stats	Option to calculate number of eclipse periods per day
;
if keyword_set(do_stats) then begin
	num_stats = 0L
	num_data = n_elements(sci)

	;  NOT IMPLEMENTED YET    +++++ TO DO

	print, ' '
ENDIF

if keyword_set(debug) then stop, "DEBUG at end of daxss_plot_power.pro ..."
return
end
