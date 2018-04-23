;
;	minxss_goes_2temperature_fit.pro
;
;	This procedure will compare plasma temperature dervied from MinXSS L1 spectra and GOES XRS-A/XRS-B ratio
;	This is similar to minxss_goes_temperature_fit except it does 2-Temperature Fit using
;		minxss_fit_2temperature.pro
;
;	INPUT
;		date		Date in format of Year and Day of Year (YYYYDOY) or it can be in YYYYMMDD format too
;		date_end	Optional date for end of time series (if not provided, then just one day)
;		/fm			Option to specify which MinXSS Flight Model (default is 1)
;		/reload		Option to reload L1, GOES XRS, and Orbit Number file
;		/hour_range	Option to define Hour range for a single day plot
;		/eps		Option to make EPS graphics files after doing interactive plotting
;		/list_fit	Option to list 2T fit results over the hour_range
;		/debug		Option to debug at the end
;
;	OUTPUT
;		result		Array of time, MinXSS_integrated_XRS-B, GOES_XRS-B, MinXSS_Temperature,
;							GOES_Temperature, and MinXSS_Abundance_Factor
;
;	FILES
;		MinXSS L1		$minxss_data/fm1/level1/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Flare Plots		$minxss_data/trends/goes  directory
;		GOES Temperature  $minxss_data/merged/xrs_temp_current.dat
;		X123 Temperature  $minxss_data/merged/x123_ch_ss_sp_2016c.sav
;
;		NOTE that system environment must be set for $minxss_data
;
;	CODE
;		This procedure plus plot routines in
;		$minxss_dir/code/production/convenience_functions_generic/
;
;	HISTORY
;		9/3/2016  Tom Woods   Original Code based on minxss_goes_ts used for Level 1 GOES comparisons
;		9/10/2016 Tom Woods	  Updated to use GOES bands from X123 for temperature estimate
;								NOTE that Version 2 does not work well because X123 XRS-A is very low counts
;		9/12/2016 Tom Woods	  Changed to use minxss_fit_temperature.pro to get Temperature & Abundance
;		9/18/2016 Tom Woods	  Changed to use minxss_fit_2temperature.pro to get Temperature & Abundance
;		9/26/2016 Tom Woods	  Added plot of XRS-B intensity versus Temperature
;
pro minxss_goes_2temperature_fit, date, date_end, result=result, fm=fm, reload=reload, $
						hour_range=hour_range, eps=eps, debug=debug, list_fit=list_fit

common minxss_data1_2temperature_fit, doy1, data1, x123_xrsa, x123_xrsb, goes_doy, goes_xrsa, goes_xrsb, $
					base_year, xrsratio_temp, xrs_logT, x123_logT, x123_logT_2, x123_abundance, $
					x123_fit_chi, x123_fe_xxv, x123_fits

;
;	check input parameters
;
if n_params() lt 1 then begin
	print, ' '
	print, 'USAGE:  minxss_goes_2temperature_fit, date, date_end, result=result, fm=fm, /reload, /eps, /debug'
	print, ' '
	date = 2016001L
	read, '>>>>> Enter Date as YYYYDOY or YYYYMMDD format ? ', date
endif
if (date gt 2030000L) then begin
	; input format is assumed to be YYYYMMDD
	year = long(date / 10000.)
	mmdd = long(date - year*10000L)
	mm = long(mmdd / 100.)
	dd = long(mmdd - mm*100L)
	doy = long( julday(mm, dd, year) - julday(1,1,year,0,0,0) + 1. )
endif else begin
	; input format is assumed to be YYYYDOY
	year = long(date / 1000.)
	doy = long(date - year*1000L)
endelse
if (year lt 2016) then year = 2016L
if (year gt 2030) then year = 2030L
year_str = strtrim(long(year),2)
if (doy lt 1) then doy=1L
if (doy gt 366) then doy=366L
doy_str = strtrim(long(doy),2)
yyyydoy_str = year_str + '/' + doy_str

; default year2, doy2 values for a single DOY
year2 = year
doy2 = doy + 1
doy2_str = strtrim(long(doy2),2)
doDays = 0
numDays = 1

if n_params() ge 2 then begin
  doDays = 1
  numDays = long(yd2jd(date_end) - yd2jd(date))
  if (date_end gt 2030000L) then begin
	; input format is assumed to be YYYYMMDD
	year2 = long(date_end / 10000.)
	mmdd = long(date_end - year*10000L)
	mm = long(mmdd / 100.)
	dd = long(mmdd - mm*100L)
	doy2 = long( julday(mm, dd, year) - julday(1,1,year2,0,0,0) + 1. )
  endif else begin
	; input format is assumed to be YYYYDOY
	year2 = long(date_end / 1000.)
	doy2 = long(date_end - year*1000L)
  endelse
  if (year2 lt 2016) then year2 = 2016L
  if (year2 gt 2030) then year2 = 2030L
  year2_str = strtrim(long(year2),2)
  if (doy2 lt 1) then doy2=1L
  if (doy2 gt 366) then doy2=366L
  if (doy2 le doy) and (year2 eq year) then doy2 = doy + 2
  doy2_str = strtrim(long(doy2),2)
  yyyydoy2_str = year2_str + '/' + doy2_str
  yyyydoy_str += ' to ' + yyyydoy2_str
endif

if keyword_set(debug) then print, '***** Processing data for ',yyyydoy_str

;  option for Flight Model, default is 1
if not keyword_set(fm) then fm=1
fm=long(fm)
if (fm lt 1) then fm=1
if (fm gt 2) then fm=2
fm_str = strtrim(long(fm),2)

;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

;
;	read the MinXSS L0C merged file, GOES XRS data, and MinXSS Orbit Number data
;	one can /reload by command or it will reload if the year changes from previous call
;
dir_fm = getenv('minxss_data')+slash+'fm'+fm_str+slash
dir_merged = getenv('minxss_data')+slash+'merged'+slash
if n_elements(doy1) lt 2 then base_year = 0L
if (year ne base_year) or keyword_set(reload) then begin
  print, 'Reading and processing MinXSS Level 1 and GOES data...'
  ; file1 = 'minxss1_l1_mission_length.sav'
  file1 = 'minxss'+fm_str+'_l1_mission_length.sav'
  restore, dir_fm + 'level1' + slash + file1   ; restores minxsslevel1 and minxsslevel1_meta
  ;
  ;	make doy1 and data1
  ;
  base_year = year
  data1 = minxsslevel1
  minxsslevel1 = 0L    ; clear memory of this variable
  doy1 = data1.time.jd - julday(1,1,base_year,0,0,0) + 1.
  x123_jd = data1.time.jd
  x123_yd = jd2yd(data1.time.jd)

  ;
  ;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
  ;
  xrs_file = 'goes_1mdata_widx_'+strtrim(base_year,2)+'.sav'
  xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_jd = gps2jd(goes.time)
  goes_yd = jd2yd(goes_jd)
  goes_doy = goes_jd - julday(1,1,base_year,0,0,0) + 1.  ; convert GPS to DOY fraction
  goes_xrsb = goes.long
  goes_xrsa = goes.short
  goes=0L

  ;
  ;		calculate GOES XRS-B equivalent band using X123 spectra
  ;		NOAA recommends XRS-B / 0.70 and  XRS-A / 0.85 for "true" irradiance level
  ;
  gcs = 1.5
  hc = 6.626D-34 * 2.998D8
  EFang = 12.398
  aband = EFang / [ 0.5, 4 ]	; convert Angstrom to keV for XRS bands
  awidth = aband[0] - aband[1]
  acenter = (aband[0]+aband[1])/2.
  actr_weighted = 4.13   ; 1/E^5 irradiance weighting means low energy more important
  bband = EFang / [ 1, 8 ]
  bwidth = bband[0] - bband[1]
  bcenter = (bband[0]+bband[1])/2.
  bctr_weighted = 2.06  ; 1/E^5 irradiance weighting means low energy more important

  esp = data1[0].energy
  x123_band = esp[20] - esp[19]  ; ~ 0.03 keV/bin
  wgxa = where( (esp ge aband[1]) and (esp lt aband[0]) )
  aphoton2energy = (hc*esp[wgxa]) * 1.D4 / (1.D-10*EFang)
  wgxb = where( (esp ge bband[1]) and (esp lt bband[0]) )
  bphoton2energy = (hc*esp[wgxb]) * 1.D4 / (1.D-10*EFang)

  num_x123 = n_elements(data1)
  x123_xrsa = fltarr(num_x123)
  x123_xrsb = fltarr(num_x123)

  ; apply "calibration" to GOES XRS (just done once)
  acal = 1. / 0.85	; XRS-A / 0.85 for "true" irradiance level
  goes_xrsa *= acal
  bcal = 1. / 0.70   ; XRS-B / 0.70  for "true" irradiance level
  goes_xrsb *= bcal

  for k=0L, num_x123-1 do begin
  	;
  	;  get X123 integrated irradiance in units of W/m^2 for direct comparison to GOES
  	;
	x123_xrsa[k] = total(data1[k].irradiance[wgxa]*x123_band*aphoton2energy)
	x123_xrsb[k] = total(data1[k].irradiance[wgxb]*x123_band*bphoton2energy)
  endfor

  ;
  ;	load temperature model for GOES ratio of XRS-A / XRS-B
  ;
  gtdir = dir_merged
  dtfile = 'xrs_temp_current.dat'
  xrsratio = read_dat(gtdir + dtfile)
  xrsratio[0,*] = alog10(xrsratio[0,*] * 1E6)		; convert T_MK to alog10(T_K)
  ;  place A/B ratio into Current_C column
  xrsratio[3,*] = 0.0
  wgd1 = where((xrsratio[2,*] gt 0) and (xrsratio[1,*] gt 0))
  xrsratio[3,wgd1] = xrsratio[1,wgd1] / xrsratio[2,wgd1]
  xrs_temp_valid = [5.3, 7.9]
  wgd = where( (xrsratio[0,*] ge xrs_temp_valid[0]) and (xrsratio[0,*] le xrs_temp_valid[1]) $
  		and (xrsratio[2,*] gt 0) and (xrsratio[1,*] gt 0) )
  ;  truncate to valid ratio range
  xrsratio_temp = xrsratio[*,wgd]

  ;
  ;	calculate GOES XRS temperature for all of the GOES data points
  ;
  print, 'Calculating GOES XRS temperatures...'
  ratio_xrs = goes_xrsa / (goes_xrsb > 1E-10)
  xrs_logT = interpol( xrsratio_temp[0,*], xrsratio_temp[3,*], ratio_xrs )
  wlow = where( ratio_xrs lt min(xrsratio_temp[3,*], ilow), numlow )
  if (numlow gt 0) then xrs_logT[wlow] = xrsratio_temp[0,ilow]
  whigh = where( ratio_xrs gt max(xrsratio_temp[3,*], ihigh), numhigh )
  if (numhigh gt 0) then xrs_logT[whigh] = xrsratio_temp[0,ihigh]

  ;
  ;		fit X123 temperature to CHIANTI isothermal models
  ;
  print, 'Calculating X123 temperatures...'
  num_x123 = n_elements(data1)
  x123_logT = fltarr( num_x123 )
  x123_logT_2 = fltarr( num_x123 )
  x123_abundance = fltarr( num_x123 )
  x123_fit_chi = fltarr( num_x123, 2 )
  x123_fe_xxv = fltarr( num_x123 )
  for k=0L,num_x123-1 do begin
  		e_data = data1[k].energy
  		f_data = data1[k].irradiance
  		minxss_fit_2temperature, e_data, f_data, fit_flux, parameters=param1, chi=chi, /noplot
  		if (k eq 0) then x123_fits = replicate( param1, num_x123 )
  		x123_fits[k] = param1
  		x123_logT[k] = param1.logT
  		x123_logT_2[k] = param1.logT_2
  		x123_abundance[k] = param1.abundance
  		x123_fit_chi[k,*] = chi
  		x123_fe_xxv[k] = param1.fe_xxv_flux
  endfor

  ans = ' '
  read, 'Do you want to save the model fit results ? ', ans
  if (strupcase(strmid(ans,0,1)) eq 'Y') then begin
    sfile = 'minxss'+strtrim(fm,2)+'_L1_2temp_fits.sav'
    print, 'Saving model fit results in ', dir_merged+sfile
    units = [ 'JD = Julian Date', 'YD = YYYYDOY', 'GOES irradiance=W/m^2', 'GOES XRS flux is corrected', $
    		'logT = K', 'Abundance Factor is relative to photosphere', 'Fe_XXV = ph/s/cm^2/keV' ]
    x123_spectra = data1.irradiance
    x123_energy = data1[0].energy
    save, units, goes_jd, goes_yd, goes_xrsa, goes_xrsb, xrsratio_temp, xrs_logT, $
			x123_jd, x123_yd, x123_logT, x123_logT_2, x123_abundance, $
			x123_fit_chi, x123_xrsa, x123_xrsb, x123_energy, x123_spectra, x123_fe_xxv, file=dir_merged+sfile
  endif

  read, 'Do you want to save the X123 bands for XRS-A & -B ? ', ans
  if (strupcase(strmid(ans,0,1)) eq 'Y') then begin
    sfile2 = 'minxss'+strtrim(fm,2)+'_L1_xrs_bands.sav'
    print, "Saving X123's XRS bands in ", dir_merged+sfile2
    units = [ 'JD = Julian Date', 'YD = YYYYDOY', 'irradiance=W/m^2' ]
    save, units, x123_jd, x123_yd, x123_xrsa, x123_xrsb, goes_jd, goes_yd, goes_xrsa, goes_xrsb, $
    		file=dir_merged+sfile2
  endif
endif

;
;	set some parameters / flags for the data
;
max_doy = long(max(doy1))

plotdir = getenv('minxss_data')+slash+'trends'+slash+'goes'+slash
ans = ' '

doEPS = 0   ; set to zero for first pass through for interactive plots
loopCnt = 0L

;
;	configure time in hours or in days
;
if (doDays ne 0) then begin
	; time1 is in units of DOY for multiple days (assumes same year)
	time1 = doy1
	goes_time = goes_doy
	xtitle='Time (' + year_str + ' DOY)'
	xrange=[doy,doy2]
endif else begin
	; time1 is in units of hours for a single DOY
	time1 = (doy1 - doy)*24.
	goes_time = (goes_doy - doy)*24.
	xtitle='Time (Hour of ' + yyyydoy_str + ')'
	xrange = [0,24]
	if keyword_set(hour_range) then begin
	  if n_elements(hour_range) gt 1 then xrange=hour_range[0:1] else begin
	    hour1 = 0. & hour2 = 24.
	    read, 'Enter Hour Range : ', hour1, hour2
	    xrange = [hour1, hour2]
	  endelse
	endif
endelse

;
;	prepare science data for day around chosen DOY in case selects outside 24-hour period
;
sps_sum_1au = data1.sps_sum*(data1.earth_sun_distance^2.)
SPS_SUM_MIN = 1.98E6
wsci = where( (doy1 ge doy) and (doy1 lt doy2) and (sps_sum_1au gt SPS_SUM_MIN), num_sp )

if (num_sp le 1) then begin
	print, 'ERROR finding any L1 science data for DOY = ' + doy_str
	if keyword_set(debug) then stop, 'DEBUG ...'
endif

;  limit data for returning "result"
sptime = time1[wsci]
slow_count1 = data1[wsci].x123_slow_count
goes_xrsb_cmp = interpol( goes_xrsb, goes_time, sptime )
goes_xrsa_cmp = interpol( goes_xrsa, goes_time, sptime )

; make X123 version of XRS-B by integrating over GOES XRS-B band width
x123_xrsb_cmp = x123_xrsb[wsci]
ratio_xrsb = x123_xrsb_cmp / goes_xrsb_cmp
x123_xrsa_cmp = x123_xrsa[wsci]
ratio_xrsa = x123_xrsa_cmp / goes_xrsa_cmp

;
;	calculate X123 te perature and GOES temperature for just the direct comparison to X123
;
x123_temp = x123_logT[wsci]
x123_abund = x123_abundance[wsci]
x123_temp2 = x123_logT_2[wsci]
x123_fe_xxv_flux = x123_fe_xxv[wsci]
goes_temp_cmp = interpol( xrs_logT, goes_time, sptime )

; save "result"
result = dblarr(8,num_sp)
result[0,*] = sptime
result[1,*] = x123_xrsb_cmp
result[2,*] = goes_xrsb_cmp
result[3,*] = x123_temp
result[4,*] = goes_temp_cmp
result[5,*] = x123_abund
result[6,*] = x123_temp2
result[7,*] = x123_fe_xxv_flux

LOOP_START:

flare_name = [ 'A', 'B', 'C', 'M', 'X' ]
ytitle='X123 XRS-B Band'
mtitle='MinXSS-'+fm_str

;
;   ****************************************************************
;	Plot results
;   ****************************************************************
;
  ; same plot as done by minxss_goes_ts.pro (so have reference of irradiance levels)
  plot1 = 'minxss'+fm_str+'_goes_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
  endif
  setplot
  cc = rainbow(7)

  yrange4 = [1E-8,1E-3]
  ytitle4 = 'Irradiance (W/m!U2!N)'
  cs_goes = 2.0

  plot, result[0,*], result[1,*], psym=10, /nodata, xr=xrange, xs=1, /ylog, $
	yr=yrange4, ys=1, xtitle=xtitle, ytitle=ytitle4, title=mtitle
  oplot, result[0,*], result[1,*], psym=4, color=cc[3]
  oplot, goes_time, goes_xrsb, color=cc[0]

  dx = (!x.crange[1] - !x.crange[0])/10.
  xx = !x.crange[0] - dx
  my=2.
  for jj=0L,n_elements(flare_name)-1 do begin
    xyouts, xx, my * 10.^float(!y.crange[0] + jj), flare_name[jj], color=cc[0], charsize=cs_goes
  endfor
  x1 = !x.crange[0] + 2*dx
  y1 = 7E-5 & my1 = 3.
  xyouts, x1, y1, 'GOES XRS-B', charsize=cs_goes, color=cc[0]
  xyouts, x1, y1*my1, 'X123 XRS-B Band', charsize=cs_goes, color=cc[3]

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;	plot 1 a is like plot 1 but for XRS-A instead
  ;
  plot1a = 'minxss'+fm_str+'_goes-a_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1a
	eps2_p,plotdir+plot1a
  endif
  setplot
  cc = rainbow(7)

  yrange4a = [1E-9,1E-4]

  plot, result[0,*], x123_xrsa_cmp, psym=10, /nodata, xr=xrange, xs=1, /ylog, $
	yr=yrange4a, ys=1, xtitle=xtitle, ytitle=ytitle4, title=mtitle
  oplot, result[0,*], x123_xrsa_cmp, psym=4, color=cc[3]
  oplot, goes_time, goes_xrsa, color=cc[0]

  dx = (!x.crange[1] - !x.crange[0])/10.
  x1 = !x.crange[0] + 2*dx
  y1 = 7E-6 & my1 = 3.
  xyouts, x1, y1, 'GOES XRS-A', charsize=cs_goes, color=cc[0]
  xyouts, x1, y1*my1, 'X123 XRS-A Band', charsize=cs_goes, color=cc[3]

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;   plot 2  is  Temperature plot
  ;
  plot2 = 'minxss'+fm_str+'_goes_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'_temperature.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot2
	eps2_p,plotdir+plot2
  endif
  setplot
  cc = rainbow(7)

  yrange2 = [5.5,8.0]
  ytitle2 = 'log10(Temperature) [K]'
  cs_goes = 2.0

  plot, result[0,*], result[4,*], /nodata, xr=xrange, xs=1, $
	yr=yrange2, ys=1, xtitle=xtitle, ytitle=ytitle2, title=mtitle

  oplot, result[0,*], result[3,*], psym=4, color=cc[3]
  oplot, result[0,*], result[6,*], psym=4, color=cc[5]
  oplot, goes_time, xrs_logT, color=cc[0]

  dx = (!x.crange[1] - !x.crange[0])/10.
  x1 = !x.crange[0] + 2.5*dx
  y1 = 5.6 & dy1 = 0.25
  xyouts, x1, y1, 'GOES Temp', charsize=cs_goes, color=cc[0],align=1.0
  xyouts, x1, y1+dy1, 'X123 Temp-1', charsize=cs_goes, color=cc[3], align=1.0
  xyouts, x1, y1+dy1, '  Temp-2', charsize=cs_goes, color=cc[5], align=0.0

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;   plot 3  is  Abundance plot
  ;
  plot3 = 'minxss'+fm_str+'_goes_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'_abundance.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot3
	eps2_p,plotdir+plot3
  endif
  setplot
  cc = rainbow(7)

  yrange3 = [0,4.0]
  ytitle3 = 'Abundance Factor'
  cs_goes = 2.0

  plot, result[0,*], result[5,*], /nodata, xr=xrange, xs=1, $
	yr=yrange3, ys=1, xtitle=xtitle, ytitle=ytitle3, title=mtitle

  xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
  oplot, !x.crange, [1,1], line=1
  xyouts, xx, 1.1, 'Photospheric'
  oplot, !x.crange, [2.138,2.138], line=2
  xyouts, xx, 2.238, 'Coronal'

  ; scale log(goes) from 0 to 1.0
  goes_scaled = (alog10(goes_xrsb) + 8.0)*0.2
  oplot, goes_time, goes_scaled, color=cc[0]
  xyouts, xx, 0.8, 'GOES Scaled', charsize=cs_goes/1.2, color=cc[0]

  oplot, result[0,*], ((result[5,*] > yrange3[0]) < yrange3[1]), psym=4, color=cc[3]

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;   plot of  GOES XRS-B versus Temperature
  ;	  only plot if number of days is greater than 10
  ;			Add power law fit of Temperature versus GOES XRS-B magnitude
  ;
if (doDays ne 0) and (numDays gt 10) then begin
  ;
  ;  power law fit of Temperature versus GOES XRS-B magnitude
  ;		fit only above B2 level and with good X123 temperatures
  ;
  wgd = where( result[3,*] gt 5.7 and result[3,*] lt 7.7 )  ; sort out bad fits
  wgdall = wgd
  wfit = where( (result[2,*] gt 2E-7) and (result[3,*] gt 5.7) and (result[3,*] lt 7.7), numfit )
  if (numfit gt 10) then begin
    xgd = alog10(result[2,wgd])
    ygd = result[3,wgd]
    xfit = alog10(result[2,wfit])
    yfit = result[3,wfit]
    gtcoeff = poly_fit( xfit, yfit, 1, yfit=yfit1 )
    	; exclude 3-sigma bad points
	diff = abs(yfit-yfit1)
	wgood = where( diff lt 3.*stddev(diff), num_good )
	if (num_good gt 10) then begin
	  gtcoeff = poly_fit( xfit[wgood], yfit[wgood], 1, yfit=yfit2 )
	endif
    xfitlog = findgen(400)*0.01 - 8.  ; B2-M1 level
    xfitplot = 10.^xfitlog
    yfitplot = gtcoeff[0] + gtcoeff[1]*xfitlog
    ; exclude X123 temperature data in plot
    xall = alog10(result[2,*])
    yallfit = gtcoeff[0] + gtcoeff[1]*xall
    diffall = abs(result[3,*]-yallfit)
    wgdall = where( (result[3,*] gt 5.7) and (result[3,*] lt 7.7) and (diffall lt 3.*stddev(diff)) )
    print, ' '
    print, 'FIT RESULTS for   T = A * G^N where '
    print, '    A = ', 10.^gtcoeff[0], ' and N = ', gtcoeff[1]
    ;  replace below B2 with constant value
    tlow = median( ygd[where(xgd lt -6.699)] )
    wlow = where( yfitplot lt tlow )
    yfitplot[wlow] = tlow
    print, '    Low  Temperature = ', tlow, (10.^tlow)/1E6, ' MK'
    ; replace above M1 with constant value
    thigh = median( yfit[where(xfit gt -5)] )
    whigh = where( yfitplot gt thigh )
    yfitplot2 = yfitplot
    yfitplot2[whigh] = thigh
    print, '    High Temperature = ', thigh, (10.^thigh)/1E6, ' MK'
    print, ' '
  endif
  plot4 = 'minxss'+fm_str+'_goes_vs_temp_'+year_str+'-'+doy_str+'_'+doy2_str+'.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot4
	eps2_p,plotdir+plot4
  endif
  setplot
  cc = rainbow(7)

  xrange4 = [1E-8,1E-4]
  xtitle4 = 'GOES XRS-B (W/m!U2!N)'
  cs_goes = 2.5
  dot

  plot, result[2,*], result[3,*], /nodata, psym=8, xr=xrange4, xs=1, /xlog, $
	yr=yrange2, ys=1, xtitle=xtitle4, ytitle=ytitle2, title=mtitle

  oplot, result[2,wgdall], result[3,wgdall], psym=4   ; X123 hot temperature
  oplot, result[2,*], result[4,*], psym=8, color=cc[0]  ; GOES XRS temperature
  wfull = where( (goes_time ge doy) and (goes_time le doy2) )
  ; oplot, goes_xrsb[wfull], xrs_logT[wfull], psym=8, color=cc[0]

  oplot, 10.^!x.crange, alog10(2.E6)*[1,1], line=2, color=cc[0]  ; GOES 2MK reference

  if (numfit gt 10) then begin
    wlow = where( xfitplot lt 1E-5 )
    whi = where( xfitplot ge 1E-5 )
    oplot, xfitplot[wlow], yfitplot[wlow], thick=3, color=cc[3]
    oplot, xfitplot[whi], yfitplot[whi], thick=3, line=2, color=cc[3]
    oplot, xfitplot[whi], yfitplot2[whi], thick=3, line=2, color=cc[3]
    x3a = 3E-8 & x3b = 1.5E-6 & x3c = 3E-5
    y3 = 5.60
    xyouts, x3a, y3, '1.78 MK', align=0.5, color=cc[3], charsize=cs_goes
    xyouts, x3b, y3, 'T(K)=2.4x10!U9!N * XRS!U0.46!N ', align=0.5, color=cc[3], charsize=cs_goes
    xyouts, x3c, y3, '12.6 MK', align=0.5, color=cc[3], charsize=cs_goes
    ; add legend for the other lines too
    xyouts, x3c, alog10(2.5E6), '2 MK Ref', color=cc[0], align=0.5, charsize=cs_goes
    x4 = 2E-8 & mx = 1.2 & y4 = 7.7 & dy = 0.3 & dytxt = dy/5.
    oplot, x4*[1.,mx,mx^2,mx^3], y4*[1,1,1,1], psym=4
    xyouts, x4*mx^4, y4-dytxt, 'X123', charsize=cs_goes
    oplot, x4*[1.,mx,mx^2,mx^3], (y4-dy)*[1,1,1,1], psym=8, color=cc[0]
    xyouts, x4*mx^4, y4-dy-dytxt, 'GOES', color=cc[0], charsize=cs_goes
 endif

  dy = (!y.crange[1] - !y.crange[0])/10.
  yy = !y.crange[0] - dy
  mx=2.
  for jj=0L,n_elements(flare_name)-2 do begin
    xyouts, mx * 10.^float(!x.crange[0] + jj), yy, flare_name[jj], color=cc[0], charsize=cs_goes
  endfor

  if doEPS ne 0 then send2 else read, 'Next ? ', ans
endif  ;  end for if (doDays ne 0) for Plot #4

;  END OF LOOP
LOOP_END:
loopcnt += 1
if (loopcnt eq 1) and keyword_set(eps) then begin
	; make EPS files now
	print, ' '
	print, 'MAKING EPS FILES ...'
   doEPS = 1
   goto, LOOP_START
endif

if keyword_set(list_fit) and keyword_set(hour_range) then begin
  fit_hour = (doy1 - doy)*24.
  wsci2 = where( (fit_hour ge xrange[0]) and (fit_hour lt xrange[1]) and $
  				(sps_sum_1au gt SPS_SUM_MIN), num_sp2 )
  print, ' '
  print, 'X123 Fit Results for date = ', yyyydoy_str
  print, '  Hour  Temp1    EM1    Abund1     Temp2     EM2    Abund2'
  format='(F6.3,F6.2,E10.2,F8.3,F10.2,E10.2,F8.3)'
  for i=0L,num_sp2-1 do begin
    ii = wsci2[i]
	print, fit_hour[ii], x123_fits[ii].logt, x123_fits[ii].cor_density, x123_fits[ii].abundance, $
			x123_fits[ii].logt_2, x123_fits[ii].cor_density_2, x123_fits[ii].abundance_2, format=format
  endfor
  print, ' '
endif

if keyword_set(debug) then stop, 'DEBUG at end of minxss_goes_2temperature_fit ...'

end
