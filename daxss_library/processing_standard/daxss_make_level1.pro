;+
; NAME:
;   daxss_make_level1.pro
;
; PURPOSE:
;   Read the Level 0D data product, convert to irradiance, and make Level 1 data product
;
;   This will process L0D raw counts from X123 into irradiance units.
;   It is new algorithms using the RMF and ARF response files (as used for XSPEC)
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   daxss_make_level1, fm=fm, version=version, cal_version=cal_version, verbose=verbose
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:                    Flight Model number 1 or 2 (default is 1)
;   version [string]: Software/data product version to store in filename and internal anonymous structure. Default is '2.0.0'.
;   cal_version [string]: Calibration version to store in internal anonymous structure. Default is '2.0.0'.
;
; KEYWORD PARAMETERS:
;   VERBOSE:             Set this to print processing messages
;   DEBUG:               Set this to trigger breakpoints for debugging
;
; OUTPUTS:
;   Saves .sav and .ncdf files to disk containing the level 1 data product
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;   Uses new irradiance conversion code for DAXSS (Woods version instead of Moore version)
;
; PROCEDURE:
;   1. Read the MinXSS Level 0D mission-length file
;   2. Read the RMF and ARF response files
;   3. Signal correction for RMF, deadtime, and background
;   4. Fold in ARF response to make irradiance, and calculate accuracy / precision
;   5. Select (filter) the data for good (valid) data
;   	e.g., not in eclipse by at least one minute, valid deadtime correction, etc.
;   6. Make meta-data for Level 1
;   7. Save the Level 1 results (mission-length file)
;
; HISTORY:
;	6/27/2022	T. Woods, daxss_make_level1.pro adopted for daxss_make_level1new.pro
;	5/7/2024	T. Woods, updated with new daxss_dead_time_slow_only.pro call to fix dead-time correction
;	1/28/2024	T. Woods, It is more accurate to use the updated daxss_dead_time.pro
;
;+
PRO daxss_make_level1, fm=fm, version=version, cal_version=cal_version, $
                    	 VERBOSE=VERBOSE, DEBUG=DEBUG

  ; Defaults
  if keyword_set(debug) then verbose=1

  ; Default Flight Model (FM) for DAXSS is FM3 (was FM4, changed 5/24/2022, TW)
  if not keyword_set(fm) then fm=3
  ;  limit check for FM for DAXSS
  if (fm lt 3) then fm=3
  if (fm gt 3) then fm=3
  fm_str = strtrim(fm,2)

  if keyword_set(verbose) then begin
    message,/INFO, "daxss_make_level1 is processing data for FM " + fm_str $
    	+':  START at '+JPMsystime()
  endif
  ;; IF version EQ !NULL THEN version = '2.0.0'   ; updated 6/27/2022 T.Woods
  IF version EQ !NULL THEN version = '2.1.0'   ; updated 5/7/2024 T.Woods
  IF cal_version EQ !NULL THEN cal_version = '2.0.0'

  ; Constants
  seconds_per_day = 60.0*60.0*24.0D0

  ENERGY_KEV_PER_BIN = 0.0199706   ; pre-flight calibration for DAXSS
  ENERGY_KEV_OFFSET = -0.00939901  ; in-orbit calibration for flare features at 0.81-1.85 keV
  energy_array = findgen(1024)*ENERGY_KEV_PER_BIN + ENERGY_KEV_OFFSET

  ;
  ;   1. Read the DAXSS Level 0D mission-length file
  ;
  ddir = getenv('minxss_data')
  fmdir = ddir + path_sep() + 'fm' + fm_str + path_sep()
  indir = fmdir + 'level0d' +  path_sep()
  infile = 'daxss_l0d_mission_length_v' + version + '.sav'
  if keyword_set(verbose) then begin
  	message, /INFO, 'Reading L0D data from '+indir+infile
  endif
  restore, indir+infile    ; variable is DAXSS_LEVEL0D

  ;sp = count rate
  sp = float(DAXSS_LEVEL0D.x123_spectrum)
  ;raw total counts in the integration time
  num_sci = n_elements(DAXSS_LEVEL0D)

  ; convert to counts per sec (cps) with smallest time
; RADIO_FLAG is not valid for DAXSS
; Adjust x123_accum_time to be 263 millisec shorter if x123_radio_flag EQ 1
; The x123_accum_time is adjusted in-line in DAXSS_LEVEL0D because it is used several times in this procedure
;  wradio1 = where(DAXSS_LEVEL0D.x123_radio_flag eq 1, num_radio1)
;  if (num_radio1 gt 0) then DAXSS_LEVEL0D[wradio1].x123_accum_time -= DAXSS_LEVEL0D[wradio1].x123_radio_flag * 263L
  accum_time = (DAXSS_LEVEL0D.x123_accum_time/1000.) > 0.001  ; force accum_time to not be zero
  live_time = (DAXSS_LEVEL0D.x123_live_time/1000.) > 0.001
  avg_time = (accum_time + live_time)/2.   ; note that avg_time is same as using accum_time and f_time correction
  real_time  =  DAXSS_LEVEL0D.x123_real_time/1000.
  ACCUM_TIME_FACTOR = 0.6  ; new check 5/28/2022 to exclude data when accum_time < this_factor * real_time
  REAL_TIME_LIMIT = 2.9		; something is wrong if the integration time ever goes below 3 sec

  fast_count_rate = DAXSS_LEVEL0D.x123_fast_count / accum_time
  slow_count_rate = DAXSS_LEVEL0D.x123_slow_count / accum_time

  FAST_LIMIT = 5.0E5  ; New Limit for FM-3 (T. Woods, 6/27/2022)
  ; 3/10/2025: T. Woods, Change SLOW_LIMIT from 1.2E5 to 1.4E5 to be consistent with new Dead-Time-Correction
  ;            This change is consistent with DEAD_TIME_CORRECTION_LIMIT of 2.0 and M1 flare limit
  SLOW_LIMIT = 1.4E5  ; New Limit (was 1.2E5) for changes to dead-time-correction (T. Woods, 5/7/2024)
					; Seen FAST up to 2.7E6 for large flare but then SLOW goes to zero counts

  TANGENT_RAY_HEIGHT_MIN = 300.0	; define how low is allowed for solar slant path

  ;
  ;   2. Read the DRM and ARF response files
  ;			Store in COMMON block as these are static files for DAXSS
  ;			RMF = redistribution (rows add up to 1.0)
  ;			ARF = effective area in units of cm^2
  ;
  COMMON daxss_response_common, rmf, rmf_energy, rmf_matrix, arf, arf_energy, arf_rebin
  cal_dir = ddir + path_sep() + 'calibration' + path_sep()
  cal_file_rmf = 'minxss_fm'+fm_str+'_RMF.fits'  ; rmf.maxtrix, rmf.ebounds
  cal_file_arf = 'minxss_fm'+fm_str+'_ARF.fits'  ; arf.specresp
  if (n_elements(rmf) lt 1) then rmf=eve_read_whole_fits(cal_dir+cal_file_rmf)
  if (n_elements(arf) lt 1) then arf=eve_read_whole_fits(cal_dir+cal_file_arf)

  if keyword_set(debug) then stop, 'STOPPED:  DEBUG rmf and arf variables ...'

  ;
  ; Define the Level-1 data structures that will be filled in later
  ;
  level1_x123 = { time_gps: DAXSS_LEVEL0D[0].time, $
    time_jd: 0.0D0, $
    time_yd: 0.0D0, $
    time_iso: '', $
    flight_model: fm, $
    irradiance: fltarr(1024), $
    irradiance_uncertainty: fltarr(1024), $
    energy: fltarr(1024), $
    spectrum_cps: fltarr(1024), $
    spectrum_cps_accuracy: fltarr(1024), $
    spectrum_cps_precision: fltarr(1024), $
    spectrum_cps_stddev: fltarr(1024), $
    valid_flag: fltarr(1024), $
    deadtime_correction_factor: 0.0, $
    deadtime_uncertainty: 0.0, $
    integration_time: 0.0, $
    number_spectra: 1L, $
    x123_fast_cps: 0.0, $
    x123_slow_cps: 0.0, $
    x123_slow_corrected: 0.0, $
    sps_on: 0, $
    sps_sum: 0.0, $
    sps_x: 0.0, $
    sps_y: 0.0, $
    longitude: 0.0, $
    latitude: 0.0, $
    altitude: 0.0, $
    sun_right_ascension: 0.0, $
    sun_declination: 0.0, $
    solar_zenith_angle: 0.0, $
    tangent_ray_height: 0.0, $
    earth_sun_distance: 0.0, $
    correct_au: 0.0, $
    background_mean: 0.0, $
    background_median: 0.0, $
    background_fit_yzero: 0.0, $
    background_fit_slope: 0.0 $
    }

  ;replicate the structure to the actual number of MinXSS-1 spectra that is valid in the time interval
  minxsslevel1_x123 = replicate(level1_x123, num_sci)

  ;
  ; 	Fill in many of the Level 1 variables
  ;
  minxsslevel1_x123.time_gps = DAXSS_LEVEL0D.time
  minxsslevel1_x123.time_jd = DAXSS_LEVEL0D.time_jd
  minxsslevel1_x123.time_yd = DAXSS_LEVEL0D.time_yd
  minxsslevel1_x123.time_iso = DAXSS_LEVEL0D.time_iso

  minxsslevel1_x123.integration_time = accum_time
  minxsslevel1_x123.x123_fast_cps = fast_count_rate
  minxsslevel1_x123.x123_slow_cps = slow_count_rate

  minxsslevel1_x123.longitude = DAXSS_LEVEL0D.longitude
  minxsslevel1_x123.latitude = DAXSS_LEVEL0D.latitude
  minxsslevel1_x123.altitude = DAXSS_LEVEL0D.altitude
  minxsslevel1_x123.sun_right_ascension = DAXSS_LEVEL0D.sun_right_ascension
  minxsslevel1_x123.sun_declination = DAXSS_LEVEL0D.sun_declination
  minxsslevel1_x123.earth_sun_distance = DAXSS_LEVEL0D.earth_sun_distance
  minxsslevel1_x123.correct_au = (DAXSS_LEVEL0D.earth_sun_distance)^2.

  solar_zenith_altitude, minxsslevel1_x123.time_yd, minxsslevel1_x123.longitude, $
				minxsslevel1_x123.latitude, minxsslevel1_x123.altitude, sza, trh
  minxsslevel1_x123.solar_zenith_angle = sza
  minxsslevel1_x123.tangent_ray_height = trh

  ;
  ;	Do SPS angle calculatons for FM 3
  ;
  ; *********   SPS Parameters unique for FM-3 *************
    sps_temp = DAXSS_LEVEL0D.sps_board_temp
    sps_x_factor = 4.45    ; 1/2 FOV degrees
    sps_y_factor = 4.45
    sps_gain1 = 1.0      ; fC/DN ???? not applicable for FM-4
    sps_gain2 = 1.0
    sps_gain3 = 1.0
    sps_gain4 = 1.0
    sps_dark1 = 28000. + 0.*sps_temp ; default value until have flight data
    sps_dark2 = 28000. + 0.*sps_temp
    sps_dark3 = 28000. + 0.*sps_temp
    sps_dark4 = 28000. + 0.*sps_temp
    sps_type = -1.0	; P-on-N
    SPS_SUM_LIMIT = 5000.  ; fC lower limit
  ;  SPS calculations (more generic)
  data1 = ( (DAXSS_LEVEL0D.sps_data[0] - sps_dark1) * sps_gain1 * sps_type ) > 0.
  data2 = ( (DAXSS_LEVEL0D.sps_data[1] - sps_dark2) * sps_gain2 * sps_type ) > 0.
  data3 = ( (DAXSS_LEVEL0D.sps_data[2] - sps_dark3) * sps_gain3 * sps_type ) > 0.
  data4 = ( (DAXSS_LEVEL0D.sps_data[3] - sps_dark4) * sps_gain4 * sps_type ) > 0.
  sps_sum_best = (data1 + data2 + data3 + data4) > 1.
  sps_x = ((data1 + data2) - (data3 + data4)) * sps_x_factor / sps_sum_best
  sps_y = ((data1 + data4) - (data2 + data3)) * sps_y_factor / sps_sum_best
  wbad = where(sps_sum_best lt SPS_SUM_LIMIT, numbad)
  if (numbad gt 0) then begin
    sps_x[wbad] = !VALUES.F_NAN
    sps_y[wbad] = !VALUES.F_NAN
  endif
  sps_sum = sps_sum_best
  minxsslevel1_x123.sps_on = DAXSS_LEVEL0D.enable_sps
  minxsslevel1_x123.sps_sum = sps_sum
  minxsslevel1_x123.sps_x = sps_x
  minxsslevel1_x123.sps_y = sps_y

  ;
  ;   3. Signal correction for RMF (redistribution), deadtime, and background
  ;		spectrum_cps = spectrum / accum_time
  ;		spectrum_corrected = daxss_apply_rmf(spectrum_cps) * daxss_dead_time( fast_count_rate, slow_count_rate )
  ;		spectrum_corrected2 = daxss_subtract_background(spectrum_corrected)
  ;
  ;   4. Fold in ARF response to make irradiance, and calculate accuracy / precision
  ;
  if keyword_set(verbose) then message, /INFO, 'Processing signal for '+strtrim(num_sci,2)+' spectra.'
  sp_counts = sp

  ;
  ;	Dead-Time is calculated using FAST and SLOW counts (cps) for the whole mission first
  ;
  ;; OLD CODE ;; dead_time_factor = daxss_dead_time( fast_count_rate, slow_count_rate, flag_valid=deadtime_flag, $
  ;; OLD CODE ;; 							uncertainty=deadtime_uncertainty )
  ;
  ; New Dead-Time Correction with Slow Counts Only and removal of divide by 2 (T. Woods, 5/7/2024)
  ;; dead_time_factor = daxss_dead_time_slow_only( slow_count_rate, flag_valid=deadtime_flag, $
  ;;							uncertainty=deadtime_uncertainty )

  ;  1/28/2025:  It is more accurate to use the original daxss_dead_time.pro (but updated)
  ;			This version then agrees with  slow or Spectrum divided by avg_time (accum & live average)
  ; dead_time_factor = daxss_dead_time( fast_count_rate, slow_count_rate, flag_valid=deadtime_flag, $
  ; 							uncertainty=deadtime_uncertainty )

  ; 2/22/2025:  T. Woods, new daxss_dead_time_avg_time.pro to use avg_time and
  ;						to use also slow dead time correction, the "time" inputs are millisec
  dead_time_factor = daxss_dead_time_avg_time( slow_count_rate, accum_time*1000., live_time*1000., $
  				flag_valid=deadtime_flag, uncertainty=deadtime_uncertainty )

  ;  1/30/2025:  The ratio of (avg_time / accum_time) might be more accurate for fixing differences on 2022/088
  dead_time_factor_time_based = accum_time / (avg_time > 0.1)
  DEAD_TIME_MAXIMUM = 3.0
  wbad = where( (avg_time lt 0.1) OR (dead_time_factor_time_based gt DEAD_TIME_MAXIMUM), num_bad )
  if (num_bad gt 2) then dead_time_factor_time_based[wbad] = DEAD_TIME_MAXIMUM

  ;  1/30/25: T. Woods - use dead_time_factor_time_based (as better option versus dead_time_factor)
  ; dead_time_factor_best = dead_time_factor_time_based

  ;  2/22/2025:  T. Woods - changed to usig new daxss_dead_time_avg_time.pro
  dead_time_factor_best = dead_time_factor
  minxsslevel1_x123.deadtime_correction_factor = dead_time_factor_best
  minxsslevel1_x123.deadtime_uncertainty = deadtime_uncertainty

  ;
  ;	Now do all of the signal corrections: Redistribution (RMF), Dead-Time, Background
  ;
  num10 = num_sci/10L

  for ii=0,num_sci-1 do begin
  	if keyword_set(VERBOSE) and ((ii mod num10) eq 0) and (ii ne 0) then $
  			print, '... at ',long(ii*100./num_sci), '% processed.'

    ;		spectrum_cps = spectrum / accum_time
  	spectrum_cps = reform(sp_counts[*,ii]) / accum_time[ii]

  	;		spectrum_corrected = daxss_apply_rmf(spectrum_cps) * $
  	;				daxss_dead_time( fast_count_rate, slow_count_rate )
  	spectrum_corrected = daxss_apply_rmf(energy_array, spectrum_cps) * dead_time_factor_best[ii]

  	;		spectrum_corrected2 = daxss_subtract_background(spectrum_corrected)
  	spectrum_corrected2 = daxss_subtract_background(spectrum_corrected, fit_background=fit_background1)
  	if (ii eq 0) then background = replicate( fit_background1, num_sci )
  	background[ii] = fit_background1

	; calculate the measurement precision

	;  save the correct spectrum back into the original sp[] array
  	sp[*,ii] = spectrum_corrected2

	; Fold in ARF response to make irradiance
	irradiance = daxss_apply_arf( energy_array, spectrum_corrected2, $
						accuracy=irradiance_accuracy, valid_flags=valid_flags)
	; Correct Irradiance to 1-AU
	irradiance = irradiance * minxsslevel1_x123[ii].correct_au

	;
	; Calculate uncertainty:
	;		uncertainty = irradiance * sqrt( irradiance_accuray^2
	;					+ (spectrum_cps_precision/spectrum_cps)^2
	;					+ deadtime_uncertainty^2 )
	;
	spectrum_cps_precision = sqrt( spectrum_cps * accum_time[ii] ) / accum_time[ii]
	relative_uncertainty = sqrt( irradiance_accuracy^2 $
						+ (spectrum_cps_precision/spectrum_corrected2)^2 $
						+ (deadtime_uncertainty[ii])^2 )
	irradiance_uncertainty = irradiance * relative_uncertainty
	spectrum_cps_accuracy = spectrum_corrected2 * relative_uncertainty

  	;  fill in some of the L1 data structure
  	minxsslevel1_x123[ii].energy = energy_array
	minxsslevel1_x123[ii].spectrum_cps = spectrum_corrected2  ; save the corrected spectrum (cps)
	minxsslevel1_x123[ii].spectrum_cps_precision = spectrum_cps_precision
	minxsslevel1_x123[ii].spectrum_cps_accuracy = spectrum_cps_accuracy
	minxsslevel1_x123[ii].irradiance = irradiance
	minxsslevel1_x123[ii].irradiance_uncertainty = irradiance_uncertainty
	minxsslevel1_x123[ii].valid_flag = valid_flags
	minxsslevel1_x123[ii].x123_slow_corrected = total(spectrum_corrected2)

  	if keyword_set(debug) and ((ii mod 100) eq 0) then $
  		stop, 'STOPPED: DEBUG spectrum_cps, spectrum_corrected, spectrum_corrected2 ...'
  endfor

  ;  fill in more of the Level 1 data structure
  minxsslevel1_x123.background_mean = background.background_mean
  minxsslevel1_x123.background_median = background.background_median
  minxsslevel1_x123.background_fit_yzero = reform(background.fit_coeff[0])
  minxsslevel1_x123.background_fit_slope = reform(background.fit_coeff[1])

;   5. Select (filter) the data for good (valid) data
;   	e.g., not in eclipse by at least one minute, valid deadtime correction, etc.

  wsci = where( (deadtime_flag ne 0) $
  			   and (fast_count_rate lt FAST_LIMIT) $
  			   and (accum_time ge (ACCUM_TIME_FACTOR * real_time)) $
  			   and (real_time gt REAL_TIME_LIMIT) $
               and (minxsslevel1_x123.tangent_ray_height gt TANGENT_RAY_HEIGHT_MIN) $
               and (DAXSS_LEVEL0D.x123_det_temp gt 230.) and (DAXSS_LEVEL0D.x123_det_temp lt 241.) $
               and DAXSS_LEVEL0D.x123_read_errors le 3 $
               and DAXSS_LEVEL0D.x123_write_errors le 3, $
               num_sp)
			; and (DAXSS_LEVEL0D.eclipse lt 1.0) $

  if keyword_set(verbose) then BEGIN
  	message, /INFO, 'Number of good L1 science packets = '+strtrim(num_sp,2) $
  				+ ' out of '+strtrim(num_sci,2) + ' ('+strtrim(long(num_sp*100./num_sci),2)+'%)'
  	print, '******* Level 1 Data Loss Summary ********'
  	w=where(deadtime_flag eq 0, numw)
  	print, numw*100./num_sci, '% loss for INVALID DeadTime'
  	w=where(fast_count_rate ge FAST_LIMIT, numw)
  	print, numw*100./num_sci, '% loss for HIGH Fast Count Rate'
  	w=where(accum_time lt (ACCUM_TIME_FACTOR * real_time), numw)
  	print, numw*100./num_sci, '% loss for LOW Accum_Time'
  	w=where(real_time le REAL_TIME_LIMIT, numw)
  	print, numw*100./num_sci, '% loss for HIGH Fast Count Rate'
   	w=where((DAXSS_LEVEL0D.x123_det_temp le 230.) OR (DAXSS_LEVEL0D.x123_det_temp ge 241.), numw)
  	print, numw*100./num_sci, '% loss for X123 TEMPERATURE OUT-OF-LIMIT'
  	w=where(minxsslevel1_x123.tangent_ray_height le TANGENT_RAY_HEIGHT_MIN, numw)
  	print, numw*100./num_sci, '% loss for ECLIPSE times'
 	w=where(DAXSS_LEVEL0D.x123_read_errors gt 3 OR DAXSS_LEVEL0D.x123_write_errors gt 3, numw)
  	print, numw*100./num_sci, '% loss for X123 BAD COMMUNICATION'
  	print, '  '
  endif

  if (num_sp le 1) then begin
    message,/INFO, '*** ERROR finding any good X123 solar data'
    if keyword_set(verbose) then stop, 'DEBUG ...'
    return
  endif

  if keyword_set(verbose) then begin
		message,/INFO, 'Level 1 Processing completed at '+JPMsystime()
  endif

  ;
  ; truncate L0D down to good science data (wsci)
  ;
  minxsslevel1_x123 = minxsslevel1_x123[wsci]

  ;
  ;	Define Output File names so can store into MetaData structure
  ;
  if keyword_set(directory_output_file) then begin
	  outdir = directory_output_file
  endif else begin
	  outdir = fmdir + 'level1' + path_sep()
  endelse

  if keyword_set(output_filename) then begin
	  outfile = output_filename + '.sav'
  endif else begin
	  outfile = 'daxss_l1_mission_length_v' + version + '.sav'
  endelse


  ;
  ; 6.  Make X123 MetaData information structure
  ;
  minxsslevel1_x123_meta = { $
	  Title: 'DAXSS Level 1 Data Product', $
	  Source: 'MinXSS-DAXSS SOC at LASP / CU', $
	  Mission: 'InspireSat-1 DAXSS (MinXSS-'+fm_str+')', $
	  Data_product_type: 'DAXSS Level 1', $
	  VERSION: version, $
	  Calibration_version: cal_version, $
	  Description: 'Calibrated DAXSS X123 science data corrected to 1-AU', $
	  History: [ '2022-03-21: Tom Woods: first version based on MinXSS Level 1 algorithms', $
	  '2016-2020: MinXSS Processing Team', '2021-2023: DAXSS Processing Team'], $
	  Filename: outfile, $
	  Date_generated: JPMsystime(), $
	  TIME_GPS: 'Time in GPS seconds', $
	  TIME_JD: 'Time in Julian Date', $
	  TIME_YD: 'Time in Year Day-Of-Year (DOY)', $
	  TIME_ISO: 'Time in ISO text format', $
	  FLIGHT_MODEL: 'MinXSS Flight Model, DAXSS = 3', $
	  IRRADIANCE: 'X123 Irradiance in units of photons/sec/cm^2/keV, float array[1024]', $
	  IRRADIANCE_UNCERTAINTY: 'X123 Irradiance Uncertainty in units of irradiance, float array[1024]', $
	  ENERGY: 'X123 Energy bins in units of keV, float array[1024]', $
	  SPECTRUM_CPS: 'X123 spectrum counts in units of counts per second (cps), float array[1024]', $
	  SPECTRUM_CPS_ACCURACY: 'X123 total uncertainty in cps units, float array[1024]', $
	  SPECTRUM_CPS_PRECISION: 'X123 measurement precision in cps units, float array[1024]', $
	  SPECTRUM_CPS_STDDEV: '0.0 for Level 1; counts standard deviation for averages in Levels 2 and 3, float array[1024]', $
	  VALID_FLAG: 'X123 Valid Flag for Irradiance conversion (1=TRUE, 0=FALSE), float array[1024]', $
	  DEADTIME_CORRECTION_FACTOR: 'X123 deadtime correction factor', $
	  DEADTIME_UNCERTAINTY: 'Relative uncertainty for the deadtime correction factor', $
	  INTEGRATION_TIME: 'X123 Integration (Aquistion) Time in units of seconds', $
	  NUMBER_SPECTRA: '1.0 for Level 1; Number of Spectra in the average for Levels 2 and 3', $
	  X123_FAST_CPS: 'X123 Fast Counter value in cps units', $
	  X123_SLOW_CPS: 'X123 Slow Counter value in cps units', $
	  X123_SLOW_CORRECTED: 'X123 Slow Counter with RMF and deadtime corrections in cps units', $
	  SPS_ON: 'SPS power flag (1=ON, 0=OFF)', $
	  SPS_SUM: 'SPS total signal, saturates at 120K DN', $
	  SPS_X: 'SPS X-axis offset from the sun center (NaN if SPS is not in the sun)', $
	  SPS_Y: 'SPS Y-axis offset from the sun center (NaN if SPS is not in the sun)', $
	  LONGITUDE: 'Earth Longitude for this measurement in units of degrees', $
	  LATITUDE : 'Earth Latitude for this measurement in units of degrees', $
	  ALTITUDE : 'Earth Altitude for this measurement in units of km from Earth center', $
	  SUN_RIGHT_ASCENSION: 'Sun Right Ascension from orbit location', $
	  SUN_DECLINATION: 'Sun Declination from orbit location', $
	  SOLAR_ZENITH_ANGLE: 'Solar Zenith Angle from orbit location', $
	  TANGENT_RAY_HEIGHT: 'Tangent Ray Height in km in Earth atmosphere', $
	  EARTH_SUN_DISTANCE: 'Earth-Sun Distance in units of AU (irradiance is corrected to 1AU)', $
	  CORRECT_AU: 'Earth-Sun Distance correction factor',  $
	  BACKGROUND_MEAN: 'Background signal (cps) mean for 13-20 keV range',  $
	  BACKGROUND_MEDIAN: 'Background signal (cps) median for 13-20 keV range',  $
	  BACKGROUND_FIT_YZERO: 'Background signal (cps) linear fit y-zero result (cps)',  $
	  BACKGROUND_FIT_SLOPE: 'Background signal (cps) linear fit Slope result (cps/bin)'  $
	}

	; Overwrite flight model number by default.
	; Why? Level 0d interpolates the hk.flight_model to the sci packet. If hk and sci are too far apart in time, it fills with NaN. Level 1 replaces this NaN with 0.
	; We know what level it is though, so just overwrite it unless user does not want this.
	IF NOT keyword_set(DO_NOT_OVERWRITE_FM) THEN BEGIN
	  minxsslevel1_x123.flight_model = fm
	ENDIF

	if keyword_set(debug) then BEGIN
		stop, 'DEBUG: at end - WARNING - this will not save limited data set in DEBUG mode ...'
		return
	endif

	; 7. Save the Level 1 results (mission-length file) data into an IDL .sav file, need to make .netcdf files also
	;
	; Create the file name extension that changes with the minute average chossen as a variable
	;  outdir = fmdir + 'level1' + x_minute_average_string +'minute' + path_sep()

	if keyword_set(verbose) then message, /INFO, ': Saving Level 1 save set in ' +  outdir+outfile

	; Combine all the individual structures into one big structure (structures in structures in sructures in structures! :)
	; daxss_level1 = { data: minxsslevel1_x123, meta: minxsslevel1_x123_meta }
	; Updated 6/2/2022 (TW) to break up data and meta into separate variables
	daxss_level1_data = minxsslevel1_x123
	daxss_level1_meta = minxsslevel1_x123_meta

	;save the data as a .sav and .ncdf files
	save, /compress, daxss_level1_data, daxss_level1_meta, file=outdir+outfile

	daxss_make_netcdf, '1', version=version, verbose=verbose

	if keyword_set(verbose) then begin
		message,/INFO, 'END of daxss_make_level1 at '+JPMsystime()
	endif

	if keyword_set(debug) then stop, 'DEBUG at end of daxss_make_level1.pro ...'

RETURN
END
