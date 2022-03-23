;
;	minxss_make_level4.pro
;
;	This procedure will model fit the MinXSS X123 spectra using the minxss_goes_2temperature_fit.pro
;	This compares plasma temperature dervied from MinXSS L1 spectra and GOES XRS-A/XRS-B ratio
;
;	This Level 4 Version is similar to minxss_goes_temperature_fit except it does 2-Temperature Fit using
;		minxss_fit_2temperature.pro
;
;	INPUT
;		/fm			Option to specify which MinXSS Flight Model (default is 1)
;		/daily		Option to specify daily average (L3) instead of minute average (L1)
;		/average	Option to specify which average of L1 to use (1, 2, 5, 15, 60, 1440 min)
;		/debug		Option to debug at the end
;		/verbose	Option to print processing messages
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
;		5/12/2017 Tom Woods   Updated for Version 3 of minxss_fit_2temperature.pro
;		5/16/2017 Tom Woods	  Major update so result output is array structure and
;								full mission is not fit every time unless /full_mission option is given
;		6/15/2017 Tom Woods   Updated from minxss_goes_2temperature_fit.pro to be minxss_make_level4.pro
;		9/10/2017 Tom Woods   Updated to use Chris Moore's Level 1 1-minute average file
;		9/28/2017 Tom Woods	  Updated to use Chris Moore's Level 1 with parameter for which average
;
pro minxss_make_level4, result=result, fm=fm, daily=daily, average=average, debug=debug, verbose=verbose
;
;	check input parameters
;
result=-1
if keyword_set(fm) then fm=long(fm) else fm=1L
if (fm lt 1) then fm=1L
if (fm gt 2) then fm=2L
fm_str = strtrim(fm,2)

if keyword_set(verbose) then verbose=1 else verbose=0
if keyword_set(debug) then verbose=1

;
; do Full Mission so set doDays = 1
;
doDays = 1
if fm eq 1 then begin
  date = 20160609L  ; first Science Day in MinXSS-1 mission
  date_end = 20170506L  ; last day of MinXSS-1 mission
endif else begin
  date = 20181207L  ; first Science Day in MinXSS-2 mission
  date_end = 20190105L  ; last day of MinXSS-2 mission
endelse

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
date_jd = yd2jd(year*1000. + doy)
doy_str = strtrim(long(doy),2)
yyyydoy_str = year_str + '/' + doy_str

if (date_end gt 2030000L) then begin
	; input format is assumed to be YYYYMMDD
	year2 = long(date_end / 10000.)
	mmdd = long(date_end - year2*10000L)
	mm = long(mmdd / 100.)
	dd = long(mmdd - mm*100L)
	doy2 = long( julday(mm, dd, year2) - julday(1,1,year2,0,0,0) + 1. )
endif else begin
	; input format is assumed to be YYYYDOY
	year2 = long(date_end / 1000.)
	doy2 = long(date_end - year2*1000L)
endelse
if (year2 lt 2016) then year2 = 2016L
if (year2 gt 2030) then year2 = 2030L
year2_str = strtrim(long(year2),2)
if (doy2 lt 1) then doy2=1L
if (doy2 gt 366) then doy2=366L
if (doy2 le doy) and (year2 eq year) then doy2 = doy + 2
date2_jd = yd2jd(year2*1000. + doy2)
numDays = long(date2_jd - date_jd)
doy2_str = strtrim(long(doy2),2)
yyyydoy2_str = year2_str + '/' + doy2_str
if (doDays ne 0) then yyyydoy_str += ' to ' + yyyydoy2_str

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
;	read the MinXSS L1 merged file and GOES XRS data
;
dir_fm = getenv('minxss_data')+slash+'fm'+fm_str+slash
dir_out = dir_fm + 'level4' + slash
if keyword_set(daily) then begin
	dir_in = dir_fm + 'level3' + slash
	file_in = 'minxss'+fm_str+'_l3_mission_length.sav'
	file_out = 'minxss'+fm_str+'_L4daily_2temp_fits.sav'
	; updated 1/5/2022 to use final version 3.1
	file_in = 'minxss'+fm_str+'_l3_1day_average_mission_length_v3.1.0dev.sav'
	file_out = 'minxss'+fm_str+'_L4_1day_2temp_fits_v3.1.0dev.sav'
endif else begin
	dir_in = dir_fm + 'level1' + slash
	file_in = 'minxss'+fm_str+'_l1_mission_length.sav'
	file_out = 'minxss'+fm_str+'_L4_2temp_fits.sav'
	; updated 9/10/2017 to use Chris Moore's version of 1-min averages
	file_in = 'minxss'+fm_str+'_l1_1_minute_mission_length.sav'
	file_out = 'minxss'+fm_str+'_L4_1_minute_2temp_fits.sav'
	; updated 1/5/2022 to use final version 3.1
	file_in = 'minxss'+fm_str+'_l1_mission_length_v3.1.0dev.sav'
	file_out = 'minxss'+fm_str+'_L4_2temp_fits_ver3.1.0dev.sav'
	if keyword_set(average) then begin
		avg_good = [1,60]
		wavg=where( avg_good eq long(average), num_avg )
		if (num_avg ge 1) then begin
			avg_num = avg_good[wavg[0]]
			avg_num_str = strtrim(avg_num,2)
			if (avg_num ge 60) then avg_num_name = strtrim(long(avg_num/60.),2)+'hour' $
			else avg_num_name = avg_num_str+'minute'
			dir_in = dir_fm + 'level2' + slash
			if keyword_set(verbose) then print, '***** Processing ', avg_num_str, ' minute average...'
			file_in = 'minxss'+fm_str+'_l1_'+avg_num_str+'_minute_mission_length.sav'
			file_out = 'minxss'+fm_str+'_L4_'+avg_num_str+'_minute_2temp_fits.sav'
			; updated 1/5/2022 to use final version 3.1
			file_in = 'minxss'+fm_str+'_l2_'+avg_num_name+'_average_mission_length_v3.1.0dev.sav'
			file_out = 'minxss'+fm_str+'_L4_'+avg_num_name+'_2temp_fits_ver3.1.0dev.sav'
		endif
	endif
endelse

if verbose ne 0 then begin
	print, '*****  Reading MinXSS and GOES data ...'
	print, 'Input File = ', dir_in+file_in
endif
restore, dir_in + file_in   ; restores minxsslevelX and minxsslevelX_meta

if keyword_set(daily) then begin
	; Level 3
	x123_jd = minxsslevel3.x123.time.jd
	energy = minxsslevel3.x123.energy
	energy1 = reform(energy[*,0])
	irradiance = minxsslevel3.x123.irradiance
endif else if keyword_set(average) then begin
	; Level 2
	x123_jd = minxsslevel2.x123.time.jd
	energy = minxsslevel2.x123.energy
	energy1 = reform(energy[*,0])
	irradiance = minxsslevel2.x123.irradiance
endif else begin
	; Level 1
	x123_jd = minxsslevel1.x123.time.jd
	energy = minxsslevel1.x123.energy
	energy1 = reform(energy[*,0])
	irradiance = minxsslevel1.x123.irradiance
endelse

  ;
  ;	load GOES XRS data from $minxss_data/ancillary/goes/ IDL save set (file per year)
  ;
  fm_years = [2016, 2017]
  if (fm eq 2) then fm_years = [2018,2019]
  num_fm_years = n_elements(fm_years)
  goes_num = num_fm_years * 366L * (24L*60L)   ; one-minute cadence
  goes_len = 0L
  goes1 = { jd: 0.0D0, yd: 0.0D0, xrsb: 0.0, xrsa: 0.0, logTemp: 0.0 }
  goes_data = replicate( goes1, goes_num )
  for k=0,num_fm_years-1 do begin
    xrs_file = 'goes_1mdata_widx_'+strtrim(fm_years[k],2)+'.sav'
    xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
    restore, xrs_dir + xrs_file   ; goes data structure
    num_new = n_elements(goes)
    goes_jd = gps2jd(goes.time)
    goes_data[goes_len:goes_len+num_new-1].jd = goes_jd
    goes_data[goes_len:goes_len+num_new-1].yd = jd2yd(goes_jd)
    goes_data[goes_len:goes_len+num_new-1].xrsb = goes.long
    goes_data[goes_len:goes_len+num_new-1].xrsa = goes.short
    goes_len += num_new
    goes=0L
    goes_jd = 0.
  endfor
  goes_data = goes_data[0:goes_len-1]  ; truncate to what is actually used

  ; apply "calibration" to GOES XRS (just done once)
  acal = 1. / 0.85	; XRS-A / 0.85 for "true" irradiance level
  goes_data.xrsa *= acal
  bcal = 1. / 0.70   ; XRS-B / 0.70  for "true" irradiance level
  goes_data.xrsb *= bcal
  ;
  ;	load temperature model for GOES ratio of XRS-A / XRS-B
  ;
  gtdir = getenv('minxss_data') + slash + 'merged' + slash
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
  ratio_xrs = goes_data.xrsa / (goes_data.xrsb > 1E-10)
  goes_data.logTemp = interpol( reform(xrsratio_temp[0,*]), reform(xrsratio_temp[3,*]), ratio_xrs )
  wlow = where( ratio_xrs lt min(xrsratio_temp[3,*], ilow), numlow )
  if (numlow gt 0) then goes_data[wlow].logTemp = xrsratio_temp[0,ilow]
  whigh = where( ratio_xrs gt max(xrsratio_temp[3,*], ihigh), numhigh )
  if (numhigh gt 0) then goes_data[whigh].logTemp = xrsratio_temp[0,ihigh]


;
;	process model fits
;
doProcess = 1
if (doProcess ne 0) then begin
  ; do full Mission processing
  x123_num = n_elements(x123_jd)
  index = indgen(x123_num)
  if verbose ne 0 then print, '***** Processing data for Full Mission: '+strtrim(x123_num,2)+' X123 spectra.'

  ; if keyword_set(debug) then stop, 'DEBUG: enter .c to continue for processing data. '
  ; energy_min = 0.15
  energy_min = 0.5
  energy_max = 12.0
  wenergy = where( (energy1 ge energy_min) and (energy1 lt energy_max), energy_num )
  x123_fit1 = { jd: 0.0D0, yd: 0.0D0, x123_xrsa: 0.0, x123_xrsb: 0.0, $
  			goes_xrsa: 0.0, goes_xrsb: 0.0, goes_temp: 0.0, $
  			fe_xxv_flux: 0.0, ca_xix_flux: 0.0, $
  			logT: 0.0, abundance: 0.0, abundance_ca_xix: 0.0, abundance_fe_xxv: 0.0, fit_chi: 0.0, $
  			uncertainty_abund: 0.0, uncertainty_abund_ca: 0.0, uncertainty_abund_fe: 0.0, $
  			logT_2: 0.0, abundance_2: 0.0, fit_chi_2: 0.0, $
  			cor_density: 0.0D0, photo_density: 0.0D0, cor_density_2: 0.0D0, photo_density_2: 0.0D0, $
  			energy: fltarr(energy_num), x123_irradiance: fltarr(energy_num), $
  			model_1: fltarr(energy_num),  model_2: fltarr(energy_num), model_baseline: fltarr(energy_num) }

  minxsslevel4 = replicate( x123_fit1, x123_num )
  minxsslevel4.jd = x123_jd[index]
  minxsslevel4.yd = jd2yd(x123_jd[index])
  x123_jd = 0.
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
  ; get X123 energy values and band steps
  esp = energy1
  x123_band = esp[20] - esp[19]  ; ~ 0.03 keV/bin
  wgxa = where( (esp ge aband[1]) and (esp lt aband[0]) )
  aphoton2energy = (hc*esp[wgxa]) * 1.D4 / (1.D-10*EFang)
  wgxb = where( (esp ge bband[1]) and (esp lt bband[0]) )
  bphoton2energy = (hc*esp[wgxb]) * 1.D4 / (1.D-10*EFang)

  for k=0L, x123_num-1 do begin
  	;
  	;  get X123 integrated irradiance in units of W/m^2 for direct comparison to GOES
  	;
	minxsslevel4[k].x123_xrsa = total(irradiance[wgxa,index[k]]*x123_band*aphoton2energy)
	minxsslevel4[k].x123_xrsb = total(irradiance[wgxb,index[k]]*x123_band*bphoton2energy)
  endfor

  ; store GOES results in L4 data structure
  sptime = minxsslevel4.jd
  num_sp = n_elements(sptime)
  goes_xrsa_cmp = interpol( goes_data.xrsa, goes_data.jd, sptime )
  goes_xrsb_cmp = interpol( goes_data.xrsb, goes_data.jd, sptime )
  goes_temp_cmp = interpol( goes_data.logTemp, goes_data.jd, sptime )
  minxsslevel4.goes_xrsa = goes_xrsa_cmp
  minxsslevel4.goes_xrsb = goes_xrsb_cmp
  minxsslevel4.goes_temp = goes_temp_cmp

  ;
  ;		fit X123 temperature to CHIANTI isothermal models
  ;
  if verbose ne 0 then print, 'Calculating X123 temperatures for ',strtrim(x123_num,2), ' spectra...'
  ; minxss_fit_2temperature parameters = { logT: 0.0, cor_density: 0.0D0, photo_density: 0.0D0, $
  ;			abundance: 0.0, abundance_fe_xxv: 0.0, fe_xxv_flux: 0.0, abundance_ca_xix: 0.0, ca_xix_flux: 0.0, $
  ;			logT_2: 0.0, cor_density_2: 0.0D0, photo_density_2: 0.0D0, abundance_2: 0.0 }
  ;
  for k=0L,x123_num-1 do begin
  		e_data = reform(energy[*,index[k]])
  		f_data = reform(irradiance[*,index[k] ])
  		theDebug = 0
  		if keyword_set(debug) and (minxsslevel4[k].x123_xrsb gt 4E-6) then theDebug = 1
  		minxss_fit_2temperature, e_data, f_data, fit_flux, parameters=param1, chi=chi, /noplot, debug=theDebug
  		minxsslevel4[k].logT = param1.logT
  		minxsslevel4[k].logT_2 = param1.logT_2
  		minxsslevel4[k].abundance = param1.abundance
  		minxsslevel4[k].abundance_2 = param1.abundance_2
  		minxsslevel4[k].fe_xxv_flux = param1.fe_xxv_flux
  		minxsslevel4[k].abundance_fe_xxv = param1.abundance_fe_xxv
  		minxsslevel4[k].ca_xix_flux = param1.ca_xix_flux
  		minxsslevel4[k].abundance_ca_xix = param1.abundance_ca_xix
  		minxsslevel4[k].cor_density = param1.cor_density
  		minxsslevel4[k].photo_density = param1.photo_density
  		minxsslevel4[k].cor_density_2 = param1.cor_density_2
  		minxsslevel4[k].photo_density_2 = param1.photo_density_2
  		minxsslevel4[k].fit_chi = chi[0]
  		minxsslevel4[k].fit_chi_2 = chi[1]
  		minxsslevel4[k].uncertainty_abund = param1.uncertainty_abund
  		minxsslevel4[k].uncertainty_abund_ca = param1.uncertainty_abund_ca
  		minxsslevel4[k].uncertainty_abund_fe = param1.uncertainty_abund_fe
  		minxsslevel4[k].energy = e_data[wenergy]
  		minxsslevel4[k].x123_irradiance = f_data[wenergy]
  		if (fit_flux[0] ne -1L) then begin
  		  minxsslevel4[k].model_1 = interpol( reform(fit_flux[2,*]), reform(fit_flux[0,*]), e_data[wenergy] )
  		  minxsslevel4[k].model_2 = interpol( reform(fit_flux[3,*]), reform(fit_flux[0,*]), e_data[wenergy] )
  		  minxsslevel4[k].model_baseline = interpol( reform(fit_flux[4,*]), reform(fit_flux[0,*]), e_data[wenergy] )
  		endif
  		if (theDebug ne 0) then stop, 'DEBUG fit for larger flares...'
  endfor

  ;
  ;  save the fits data as Level 4
  ;
	print, 'Saving model fit results in ', dir_out+file_out
	if verbose ne 0 then print, 'Number of X123 spectral fits = ',strtrim(x123_num,2)

	goes_units = [ 'JD = Julian Date', 'YD = YYYYDOY', 'XRSA & XRSB = W/m^2', $
			'logTemp = log(K)', 'GOES XRS flux is corrected to standard NOAA calibration' ]
	minxsslevel4_units = [ 'JD = Julian Date', 'YD = YYYYDOY', 'X123_XRSA = W/m^2', 'X123_XRSB = W/m^2', $
			'logT & logT_2 = log(K)', 'ABUNDANCE values are relative to photosphere', $
			'Fe_XXV & Ca_XIX_FLUX = ph/s/cm^2/keV', 'FIT_CHI & FIT_CHI_2 are model fit chi-squared values', $
			'DENSITY parameters are Emission Measure (cm^5)', 'ENERGY = keV', $
			'X123_IRRADIANCE & MODEL values have units of ph/s/cm^2/keV', $
			'Uncertainty of Temperature is 0.1 log(K)', 'Uncertainty of Abundance is relative uncertainty' ]

	save, goes_data, minxsslevel4, goes_units, minxsslevel4_units, file=dir_out+file_out
endif

;  prepare data for returning "result"
; make X123 version of XRS-B by integrating over GOES XRS-B band width
x123_xrsb_cmp = minxsslevel4.x123_xrsb
ratio_xrsb = x123_xrsb_cmp / goes_xrsb_cmp
x123_xrsa_cmp = minxsslevel4.x123_xrsa
ratio_xrsa = x123_xrsa_cmp / goes_xrsa_cmp

;
;	calculate X123 temperature and GOES temperature for just the direct comparison to X123
;
x123_temp = minxsslevel4.logT
x123_abund = minxsslevel4.abundance
x123_temp2 = minxsslevel4.logT_2
x123_fe_xxv_flux = minxsslevel4.fe_xxv_flux
x123_abund_fe_xxv = minxsslevel4.abundance_fe_xxv
x123_ca_xix_flux = minxsslevel4.ca_xix_flux
x123_abund_ca_xix = minxsslevel4.abundance_ca_xix

; save "result"
result = dblarr(11,num_sp)
result[0,*] = sptime
result[1,*] = x123_xrsb_cmp
result[2,*] = goes_xrsb_cmp
result[3,*] = x123_temp
result[4,*] = goes_temp_cmp
result[5,*] = x123_abund
result[6,*] = x123_temp2
result[7,*] = x123_fe_xxv_flux
result[8,*] = x123_abund_fe_xxv
result[9,*] = x123_ca_xix_flux
result[10,*] = x123_abund_ca_xix

if keyword_set(debug) then stop, 'DEBUG at end of minxss_make_level4 ...'

end
