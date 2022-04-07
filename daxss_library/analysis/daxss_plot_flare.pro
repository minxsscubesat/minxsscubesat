;
;	daxss_plot_flare.pro
;
;	Plot DAXSS Flare time series and spectrum
;
; INPUTS
;	date		Fractional day in YD or YMD format
;	/minxss1	Option to over-plot MinXSS-1 flare spectrum too
;					If minxss1 is specific time, then use that time, else match GOES XRS-B level
;	/range_hours	Option to specify time range before / after flare (default is 0.5-hour)
;					That is, plot is peak-range_hours to peak+range_hours
;	/verbose	Option to print messages
;
;	T. Woods, 3/23/2022
;
pro daxss_plot_flare, date, minxss1=minxss1, range_hours=range_hours, verbose=verbose, debug=debug

if n_params() lt 1 then begin
	date = 0.0D0
	read, 'Enter Date for flare (in YD or YMD format, fractional day): ', date
endif

if not keyword_set(range_hours) then range_hours = 0.5

common daxss_plot_flare_common, daxss_level1, minxsslevel1

;
;	figure out the Date in JD and hours
;
if (date gt 2030001L) then begin
	; YYYYMMDD format assumed
	year = long(date) / 10000L
	month = (long(date) - year*10000L)/100L
	day = (long(date) - year*10000L - month*100L)
	hour = (date - long(date))*24.
	jd_mid = ymd2jd(year,month,day+hour/24.)
endif else begin
	; YYYYDOY format assumed
	year = long(date) / 100L
	doy = (long(date) - year*1000L)
	hour = (date - long(date))*24.
	jd_mid = yd2jd(date)
endelse
jd1 = jd_mid - range_hours/24.
jd2 = jd_mid + range_hours/24.

if (jd_mid lt yd2jd(2022045.D0)) or (jd_mid gt systime(/julian)) then begin
	message,/INFO, 'ERROR with Date being outside the InspireSat-1 mission range !'
	return
endif

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level1' + path_sep()
dfile1 = 'minxss4_l1_mission_length_v1.0.0.sav'
if (daxss_level1 eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
	restore, ddir+dfile1   ; daxss_level1 variable is structure
endif

;
;	Look for DAXSS data within the JD time range
;
wdax =  where((daxss_level1.data.time_jd ge jd1) AND (daxss_level1.data.time_jd le jd2), num_dax )
if (num_dax lt 2) then begin
	message,/INFO, 'ERROR finding any DAXSS data during this flare.'
	return
endif

;
;	Read GOES data
;
gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
if keyword_set(verbose) then message,/INFO, 'Reading GOES data from '+gdir+gfile
restore, gdir+gfile   ; goes structure array
goes_jd = gps2jd(goes.time)

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
;	make Time Series plot with DAXSS slow counts and GOES XRS irradiance
;
;setplot
;cc=rainbow(7)

xrange = [jd1, jd2]
yrange1 = [1E3, 1E6]
yrange2 = [1E-7,1E-4]
p1_title = 'DAXSS Flare '+strtrim(long(date),2)
p1_labels = label_date(DATE_FORMAT="%H:%I")

p1 = plot( daxss_level1.data.time_jd, daxss_level1.data.x123_slow_count, $
	xrange=xrange, xstyle=1, /ylog, yrange=yrange1, ystyle=1, title=p1_title, $
	axis_style = 1, sym='Diamond', $
	xtitle='Time', ytitle='DAXSS Signal (cps)', XTICKFORMAT='LABEL_DATE', XTICKUNITS='Time' )
p1a = plot( xrange, yrange1[1]*0.99*[1,1], /overplot )

goes_factor = 1E-10
p1b = plot( goes_jd, goes.long/goes_factor, color='green', /histogram, /overplot )
yaxis = axis( 'Y', location='right', title='GOES XRS-B (W/m!U2!N)', $
	/log, axis_range=yrange2, coord_transform=[0.,goes_factor], color='green' )

ans = ' '
read, 'Next Plot ? ', ans

;
;	make Spectral plot with DAXSS and MinXSS-1 spectra
;		Average 5 spectra together near the peak
;
;setplot
;cc=rainbow(7)

dax_sp = total(daxss_level1.data[wdax[wd_max-2:wd_max+2]].irradiance, 2) / 5.
dax_e =  daxss_level1.data[wdax[wd_max]].energy

;  get DAXSS 1-8Angstrom Irradiance
EAfactor = 12.4
dax_delta_e = abs(dax_e[11] - dax_e[10])
xrsb_e2 = EAfactor / 1.
xrsb_e1 = EAfactor / 8.
wd_xrsb = where( (dax_e ge xrsb_e1) AND (dax_e le xrsb_e2) )
daxss_xrsb = total( dax_sp[wd_xrsb] * dax_e[wd_xrsb] * 1.602D-19 * 1D3 * 1D4 * dax_delta_e ) ; convert to W/m^2
print, '*** DAXSS 1-8Ang Irradiance (W/m^2) is ', daxss_xrsb
if (daxss_xrsb lt 9.95E-8) then daxss_name = 'A' + string(daxss_xrsb/1E-8,format='(F3.1)') $
else if (daxss_xrsb lt 9.95E-7) then daxss_name = 'B' + string(daxss_xrsb/1E-7,format='(F3.1)') $
else if (daxss_xrsb lt 9.95E-6) then daxss_name = 'C' + string(daxss_xrsb/1E-6,format='(F3.1)') $
else if (daxss_xrsb lt 9.95E-5) then daxss_name = 'M' + string(daxss_xrsb/1E-5,format='(F3.1)') $
else if (daxss_xrsb lt 9.95E-4) then daxss_name = 'X' + string(daxss_xrsb/1E-4,format='(F3.1)') $
else daxss_name = 'X' + string(daxss_xrsb/1E-4,format='(F4.1)')

; identify GOES XRS-B level for the DAXSS peak time
daxss_peak_jd = daxss_level1.data[wdax[wd_max]].time_jd
goes_daxss = interpol( goes.long, goes_jd, daxss_peak_jd ) > 1E-8
if (goes_daxss lt 9.95E-8) then goes_name = 'A' + string(goes_daxss/1E-8,format='(F3.1)') $
else if (goes_daxss lt 9.95E-7) then goes_name = 'B' + string(goes_daxss/1E-7,format='(F3.1)') $
else if (goes_daxss lt 9.95E-6) then goes_name = 'C' + string(goes_daxss/1E-6,format='(F3.1)') $
else if (goes_daxss lt 9.95E-5) then goes_name = 'M' + string(goes_daxss/1E-5,format='(F3.1)') $
else if (goes_daxss lt 9.95E-4) then goes_name = 'X' + string(goes_daxss/1E-4,format='(F3.1)') $
else goes_name = 'X' + string(goes_daxss/1E-4,format='(F4.1)')

print, '***** GOES Level of ', goes_name, ' versus DAXSS 1-8Ang Level of ', daxss_name

if keyword_set(minxss1) then begin
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
  minxss_xrsb = total( minxss_sp[wd_xrsb] * minxss_e[wd_xrsb] * 1.602D-19 * 1D3 * 1D4 * minxss_delta_e ) ; convert to W/m^2
  print, '*** MinXSS 1-8Ang Irradiance (W/m^2) is ', minxss_xrsb
endif

x2range = [0.,8.]
y2range = [1E3,1E9]
p2_title = 'DAXSS '+goes_name+' Flare on '+strtrim(long(date),2)

p2 = plot( dax_e, dax_sp, $
	xrange=x2range, xstyle=1, /ylog, yrange=y2range, ystyle=1, title=p2_title, $
	axis_style = 2, /histogram, xtitle='Energy (keV)', ytitle='Irradiance (ph/s/cm!U2!N/keV)' )

if keyword_set(minxss1) then begin
	p2b = plot( minxss_e, minxss_sp, /histogram, color='red', /overplot )
endif

if keyword_set(debug) then stop, "DEBUG at end of daxss_plot_flare.pro ..."
return
end
