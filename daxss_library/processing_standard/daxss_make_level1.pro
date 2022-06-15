;+
; NAME:
;   daxss_make_level1.pro
;
; PURPOSE:
;   Read a data product and make x minute averages and store the data in a structure
;
;   This will process L0D raw counts from X123 into irradiance units and in x-minute averages.
;   It also calculates the XP background subtracted data
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   daxss_make_level1, fm=fm
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:                    Flight Model number 1 or 2 (default is 1)
;   low_limit [float]:               Option to change limit on selecting low energy counts for good X123 spectra. Default for low_limit is 7.0
;   directory_flight_model [string]: ??? ; FIXME: Fill in
;   directory_input_file [string]:   ??? ; FIXME: Fill in
;   directory_output_file [string]:  ??? ; FIXME: Fill in
;   directory_calibration_file [string]: ??? ; FIXME: Fill in
;   output_filename [string]:            ??? ; FIXME: Fill in
;   directory_minxss_data [string]:      ??? ; FIXME: Fill in
;   version [string]: Software/data product version to store in filename and internal anonymous structure. Default is '1.0'.
;   cal_version [string]: Calibration version to store in internal anonymous structure. Default is '1.0.0'.
;
; KEYWORD PARAMETERS:
;   DO_NOT_OVERWRITE_FM: Set this to prevent the overwriting of the flight model number in the data product with the fm optional input
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
;   Uses Chris Moore's irradiance conversion code for X123
;   Need the functions (minxss_x123_correct_deadtime.pro, minxss_X123_mean_count_rate_uncertainty.pro,minxss_x123_invert_count_to_photon_estimate.pro,  minxss_X123_be_photoelectron_si_escape_count_correction.pro)
;
; PROCEDURE:
;   1. Read the MinXSS Level 0D mission-length file
;   2. Select (filter) the data for good (valid) data
;   not in eclipse by at least one minute, radio flag is greater than 1,
;   low energy counts are below the low_limit
;   3. Choose the timeframe of the data to be considered
;   4. First order correction for deadtime
;   5. Average the data over x-minute intervals, make irradiance values calculate XP background subtracted data and compare to X123 estimates
;   6. Make meta-data for Level 1
;   7. Save the Level 1 results (mission-length file)
;
; HISTORY:
;	3/21/2022   T. Woods, Copy of minxss_make_level1.pro for DAXSS processing
;	5/28/2022	T. Woods, Updated to exclude Eclipse data, low Accum. Time, and to zero-out 0-0.3 keV range
;	6/2/2022	T. Woods, Removed the unused X123_RADIO_FLAG in the Level 1 structure, broke up data & meta variables
;	6/3/2022	T. Woods, Added calculation of Solar Zenith Angle and Tangent Ray Height
;	6/13/2022	T. Woods, Updated MetaData units for Precision and Accuracy;
;							and added background subtraction using linear fit to 12-20 keV signal
;+
PRO daxss_make_level1, fm=fm, low_count=low_count, directory_flight_model=directory_flight_model, directory_input_file=directory_input_file,  directory_output_file=directory_output_file, directory_calibration_file=directory_calibration_file, output_filename=output_filename, directory_minxss_data=directory_minxss_data, version=version, cal_version=cal_version, $
                        DO_NOT_OVERWRITE_FM=DO_NOT_OVERWRITE_FM, VERBOSE=VERBOSE, DEBUG=DEBUG

  ; Defaults
  if keyword_set(debug) then verbose=1

  ; Default Flight Model (FM) for DAXSS is FM3 (was FM4, changed 5/24/2022, TW)
  if not keyword_set(fm) then fm=3
  ;  only allow FM-3
  if (fm lt 3) then fm=3
  if (fm gt 3) then fm=3

  fm_str = strtrim(fm,2)
  if keyword_set(verbose) then begin
    message,/INFO, "daxss_make_level1 is processing data for FM " + fm_str $
    	+':  START at '+JPMsystime()
  endif
  IF version EQ !NULL THEN version = '1.1.0'   ; updated 6/14/2022 T.Woods
  IF cal_version EQ !NULL THEN cal_version = '1.0.0'

  ; Constants
  seconds_per_day = 60.0*60.0*24.0D0

  if fm eq 3 then LOW_LIMIT_DEFAULT = 15.0 $
  else LOW_LIMIT_DEFAULT = 15.0  ; for FM-X ???
  if not keyword_set(low_limit) then low_limit = LOW_LIMIT_DEFAULT
  ; if keyword_set(verbose) then print, '     low_limit = ', low_limit
  ;
  ;   1. Read the DAXSS Level 0D mission-length file
  ;
  if keyword_set(directory_minxss_data) then begin
    ddir = directory_minxss_data
  endif else begin
    ddir = getenv('minxss_data')
  endelse
;  if strlen(ddir) lt 1 then begin
;    print, '*** ERROR finding DAXSS data, you need to define $minxss_data environment variable. But will continue.... Chris Moore edit.'
 ;     return
;  endif
;add keyword call for directory
  if keyword_set(directory_flight_model) then begin
    fmdir = directory_flight_model
  endif else begin
    fmdir = ddir + path_sep() + 'fm' + fm_str + path_sep()
  endelse
  if keyword_set(directory_input_file) then begin
    indir = directory_input_file
  endif else begin
    indir = fmdir + 'level0d' +  path_sep()
  endelse
  infile = 'daxss_l0d_mission_length_v' + version + '.sav'
  if keyword_set(verbose) then begin
  	message, /INFO, 'Reading L0D data from '+indir+infile
  endif
  restore, indir+infile    ; variable is DAXSS_LEVEL0D


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;for testing purposes just run the ~ 1,000 entries
  ;  DAXSS_LEVEL0D_old = DAXSS_LEVEL0D
  ; DAXSS_LEVEL0D = DAXSS_LEVEL0D[4E3:4.1E3]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ; STOP, 'DEBUG the Level 0D data ...'

  ;
  ; 2. Select (filter) the data for good (valid) data
  ;   not in eclipse by at least one minute,
  ;   low energy counts are below the low_limit, and ADCS mode is Fine-Ref(1)
  ;
  sp_sec = (DAXSS_LEVEL0D.time_jd - yd2jd(2016001.D0))*24.D0*3600.  ; seconds since Jan 1, 2016
  ;sp = count rate
  sp = float(DAXSS_LEVEL0D.x123_spectrum)
  ;raw total counts in the integration time
  num_sci = n_elements(DAXSS_LEVEL0D)
  ; convert to counts per sec (cps) with smallest time
  ; Note that Version 1 used x123_live_time instead of x123_accum_time
;  for ii=0,num_sci-1 do sp[*,ii] = sp[*,ii] / (DAXSS_LEVEL0D[ii].x123_accum_time/1000.)

; RADIO_FLAG is not valid for DAXSS
; Adjust x123_accum_time to be 263 millisec shorter if x123_radio_flag EQ 1
; The x123_accum_time is adjusted in-line in DAXSS_LEVEL0D because it is used several times in this procedure
;  wradio1 = where(DAXSS_LEVEL0D.x123_radio_flag eq 1, num_radio1)
;  if (num_radio1 gt 0) then DAXSS_LEVEL0D[wradio1].x123_accum_time -= DAXSS_LEVEL0D[wradio1].x123_radio_flag * 263L
  accum_time = DAXSS_LEVEL0D.x123_accum_time/1000.
  real_time  =  DAXSS_LEVEL0D.x123_real_time/1000.
  accum_time_factor = 0.6  ; new check 5/28/2022 to exclude data when accum_time < this_factor * real_time

  ;		Convert spectrum from counts to counts per sec (cps)
  ;
  ;		correct the spectrum counts for background using 12-20 keV signal (T. Woods, 6/13/2022)
  ;			fit line as there is there is a small trend with energy
  ;			save the background results
  whi = indgen(420) + 602
  bins = findgen(1024)
  sp_counts = sp
  background_struct1 = { background_mean: 0.0, background_median: 0.0, fit_coeff: fltarr(2) }
  background = replicate( background_struct1, num_sci )
  for ii=0,num_sci-1 do begin
    ; background subtraction
    coeff = poly_fit( bins[whi], sp_counts[whi,ii], 1)
    background_spectrum = (coeff[0] + bins*coeff[1]) > 0.0
    background[ii].fit_coeff = reform(coeff)
    background[ii].background_mean = mean(sp_counts[whi,ii])
    background[ii].background_median = median(sp_counts[whi,ii])
    sp_counts[*,ii] = (reform(sp_counts[*,ii]) - background_spectrum) > 0.
  	;  convert to CPS
  	sp[*,ii] = reform(sp_counts[*,ii]) / accum_time[ii]
  	if keyword_set(debug) AND (ii eq 0) then stop, 'DEBUG sp_counts and sp arrays ...'
  endfor

  fast_count = DAXSS_LEVEL0D.x123_fast_count / accum_time
  fast_limit = 1E6  ; New Limit for  FM-3
  fast_limit = 2E5  ; New Limit for FM-3 (T. Woods, 5/28/2022)
  slow_count = DAXSS_LEVEL0D.x123_slow_count / accum_time

;  sps_sum = total(DAXSS_LEVEL0D.sps_data_sci[0:3],1) / float(DAXSS_LEVEL0D.sps_xp_integration_time)
;  sps_sum_sun_min = 280000.   ; June 2016 it is 310K; this  allows for 1-AU changes and 5% degradation

  ; exclude spectra if not in sun, and high low counts
  lowcnts = total( sp[20:24,*], 1 )
  peakcnts = total( sp[36:40,*], 1 )
  PEAK_SLOPE_DEFAULT = 3.0
  lowlimit = 20.0    ; M5 Flare is lt 20
  lowlimit = 1000.	; New lower limit for slow counts (T. Woods, 5/28/2022)
  slow_count_min = lowlimit
  slow_count_max = fast_limit

  ;X123_swicth on flag, 1 = on and 0 is off
  x123_switch_flag = 0.0

  ;Science mode check, science_mode_flag = 4.0
  science_mode_flag_threshold = 3.0

  ;  get Counts for the Fe XXV emission line
  fe_cnts = total( sp[210:250,*], 1 )
  FE_CNTS_MAX = 200.

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; Add a new check using the initial estimated MinXSS X123 irradiance
  ; Pass in the level 0D counts in the integration spectrum. We will be taking a ratio of counts in particular energy bins so the units will not matter
  ; put in the actual spectrum for the uncert
  ; add path for the calibration file
  if keyword_set(directory_calibration_file) then begin
    cal_dir = directory_calibration_file
  endif else begin
    cal_dir = getenv('minxss_data')+ path_sep() + 'calibration' + path_sep()
  endelse

n_spectra = n_elements(sp[*,0])
n_times_nominal = n_elements(sp[0,*])
initial_x123_irradiance = dblarr(n_spectra, n_times_nominal)

if keyword_set(verbose) then message, /INFO, 'Level 1 starting irradiance conversion.'
if keyword_set(debug) then n_times_nominal = 100L  ; limit for DEBUG session

for k = 0, n_times_nominal - 1 do begin
  minxss_x123_irradiance_wrapper, sp[*,k], sp[*,k], initial_x123_irradiance_temp, result=initial_x123_irradiance_structure, directory_calibration_file=cal_dir, fm=fm
  initial_x123_irradiance[*,k] = initial_x123_irradiance_structure.irradiance
  if keyword_set(debug) AND (k eq 0) then stop, 'DEBUG sp and initial_x123_irradiance_structure ...'
endfor

if keyword_set(verbose) then message, /INFO, 'Level 1 finished irradiance conversion at ' + JPMsystime()

  ; find where the ratio of counts is less than a critical ratio (minimal slope)
  dimension = 1
  e_low_band_1 = 1.3
  e_high_band_1 = 1.4
  index_range_band_1 = where((initial_x123_irradiance_structure[0].energy_bins ge e_low_band_1) and (initial_x123_irradiance_structure[0].energy_bins le e_high_band_1))
  initial_x123_irradiance_structure_SPECTRUM_Photon_Flux_index_range_band_1 = total(initial_x123_irradiance[index_range_band_1,*], dimension, /double, /nan)
  e_low_band_2 = 1.0
  e_high_band_2 = 1.1
  index_range_band_2 = where((initial_x123_irradiance_structure[0].energy_bins ge e_low_band_2) and (initial_x123_irradiance_structure[0].energy_bins le e_high_band_2))
  initial_x123_irradiance_structure_SPECTRUM_Photon_Flux_index_range_band_2 = total(initial_x123_irradiance[index_range_band_2,*], dimension, /double, /nan)

  ratio_initial_x123_irradiance_structure_SPECTRUM_Photon_Flux_index_range_band_2 = initial_x123_irradiance_structure_SPECTRUM_Photon_Flux_index_range_band_2/initial_x123_irradiance_structure_SPECTRUM_Photon_Flux_index_range_band_1
  limit_value_Photon_Flux = 5.0E1

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  *****  SIMPLIFIED where for DAXSS on IS-1 **************
  wsci = where((fast_count lt fast_limit) $
  			   and (slow_count gt slow_count_min) $
  			   and (accum_time ge (accum_time_factor * real_time)) $
               and (DAXSS_LEVEL0D.eclipse lt 1.0) $
               and DAXSS_LEVEL0D.x123_read_errors le 5 $
               and DAXSS_LEVEL0D.x123_write_errors le 5, $
               num_sp)

  if keyword_set(verbose) then BEGIN
  	message, /INFO, 'Number of good L1 science packets = '+strtrim(num_sp,2) $
    		+' out of '+strtrim(n_elements(DAXSS_LEVEL0D),2)
  endif
  if (num_sp le 1) then begin
    message,/INFO, '*** ERROR finding any X123 solar data'
    if keyword_set(verbose) then stop, 'DEBUG ...'
    return
  endif

  ;
  ; make SPS pointing information using SCI SPS data (versus lower quality HK SPS data)
  ;
  sps_temp = DAXSS_LEVEL0D.sps_board_temp  ; reliable temperature that doesn't depend on I2C monitor
  if (fm eq 1) then begin
    ; FM-1 SPS SURF calibration result
    sps_x_factor = 3.224    ; 1/2 FOV degrees
    sps_y_factor = 3.230
    sps_gain1 = 7.11      ; fC/DN
    sps_gain2 = 6.38
    sps_gain3 = 6.51
    sps_gain4 = 5.54
    sps_dark1 = -1.623 + 0.40462*sps_temp   ; FM-1 in-flight calibration
    sps_dark2 = -1.199 + 0.42585*sps_temp   ; FM-1 in-flight calibration
    sps_dark3 = -1.602 + 0.41635*sps_temp   ; FM-1 in-flight calibration
    sps_dark4 = -1.760 + 0.44285*sps_temp   ; FM-1 in-flight calibration
    sps_type = 1.0	; N-on-P
  endif else if (fm eq 2) then begin
    sps_x_factor = 3.202    ; 1/2 FOV degrees
    sps_y_factor = 3.238
    sps_gain1 = 6.53      ; fC/DN
    sps_gain2 = 6.44
    sps_gain3 = 6.72
    sps_gain4 = 6.80
    sps_dark1 = 40. + 0.*sps_temp ; default value until have flight data
    sps_dark2 = 40. + 0.*sps_temp
    sps_dark3 = 40. + 0.*sps_temp
    sps_dark4 = 40. + 0.*sps_temp
    sps_type = 1.0	; N-on-P
  endif else begin
     ; *********   ASSUMES FM-3 *************
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
  endelse
  SPS_SUM_LIMIT = 5000.  ; fC lower limit
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

  ;
  ; truncate L0D down to good science data (wsci)
  ;
  if keyword_set(debug) then begin
    print, '***** Processing ', strtrim(num_sp,2), ' good spectra out of ', strtrim(num_sci,2)
    stop, 'DEBUG at start of irradiance conversion processing ...'
  endif

  ;  add path for the calibration file
  if keyword_set(directory_calibration_file) then begin
    cal_dir = directory_calibration_file
  endif else begin
    cal_dir = getenv('minxss_data')+ path_sep() + 'calibration' + path_sep()
  endelse

  if fm eq 3 then begin
    ; FM-1 values
    minxss_calibration_file = 'minxss_fm3_response_structure.sav'
    minxss_calibration_file_path = cal_dir + minxss_calibration_file
    restore, minxss_calibration_file_path
    nominal_x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
    energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
  endif else begin
    message, /INFO, 'ERROR with Flight Model not being FM3'
    STOP, 'DEBUG  daxss_make_level1.pro ...'
  endelse

  ;  save energy bins for the return
  energy_bins_kev = nominal_x123_energy_bins_kev + energy_bins_offset

  ; Define the data structures that will be filled in later
  ;minxss-1 x123 science structure
  level1_x123 = { time_gps: DAXSS_LEVEL0D[0].time, $
    time_jd: 0.0D0, $
    time_yd: 0.0D0, $
    time_iso: '', $
    flight_model: 0, $
    irradiance: fltarr(1024), $
    irradiance_uncertainty: fltarr(1024), $
    energy: fltarr(1024), $
    spectrum_cps: fltarr(1024), $
    spectrum_cps_accuracy: fltarr(1024), $
    spectrum_cps_precision: fltarr(1024), $
    spectrum_cps_stddev: fltarr(1024), $
    deadtime_correction_factor: 0.0, $
    valid_flag: fltarr(1024), $
    spectrum_total_counts: fltarr(1024), $
    spectrum_total_counts_accuracy: fltarr(1024), $
    spectrum_total_counts_precision: fltarr(1024),$
    integration_time: 0.0, $
    number_spectra: 0L, $
    x123_fast_count: 0.0, $
    x123_slow_count: 0.0, $
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
  minxsslevel1_x123 = replicate(level1_x123, num_sp)

  ;calculate parameters and fill in the structures
  num_L1 = 0L
  num_10percent = long(num_sp/10.)


  ; loop over only the time indices that are known to have minxss data within the x-minute for the current index
  for k = 0, num_sp - 1 do begin
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;   4. Deadtime correction
    if keyword_set(verbose) then verbose_deadtime=verbose
    ; raw_spectrum_counts = float(DAXSS_LEVEL0D[wsci[k]].x123_spectrum)
    raw_spectrum_counts = reform(sp_counts[*,wsci[k]])  ; corrected for background signal
    x123_counts_deadtime_corrected = minxss_x123_correct_deadtime(raw_spectrum_counts, DAXSS_LEVEL0D[wsci[k]].x123_accum_time, x123_energy_bin_centers_kev=energy_bins_kev, minxss_instrument_structure_data_file=minxss_calibration_file_path, flight_model_number=1, verbose=verbose_deadtime, $ low_energy_limit=low_energy_limit,  $
      deadtime_correction_scale_factor=x123_deadtime_correction_scale_factor_array)
    ;deadtime corrected slow counts
    x123_slow_count_deadtime_corrected = (total(x123_counts_deadtime_corrected, 1, /double, /nan))/(DAXSS_LEVEL0D[wsci[k]].x123_accum_time/1000.)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 5.  Calculate the uncertainties
    ;incorporate the SURF relative uncertainty of 10%, to be added in quadrature with the other uncertainties
    ;pre-flight cal uncertainty (SURF) is ~10%
    pre_flight_cal_uncertainty = 0.1

    ;accuracy, calculation from Tom Woods
    x123_cps_mean_count_rate_uncertainty_accuracy = minxss_X123_mean_count_rate_uncertainty(x123_counts_deadtime_corrected, $
    x123_energy_bin_centers_kev=energy_bins_kev, $
    integration_time_array=DAXSS_LEVEL0D[wsci[k]].x123_accum_time, $
    fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
    uncertainty_integration_time=uncertatinty_integration_time, $
    uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, $
    use_detector_area=use_detector_area, $
      x123_mean_count_rate = x123_cps_mean_count_rate, $
      relative_uncertainty_x123_mean_count_rate = x123_cps_mean_count_rate_relative_uncertainty_accuracy, $
      uncertainty_x123_measured_count_array=x123_measured_count_array_uncertainty, $
      x123_count_rate = x123_cps_count_rate, $
	  uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_accuracy, $
      uncertainty_stddev_x123_mean_count_rate=x123_cps_count_rate_stddev, $
      ratio_uncertainty_stddev_x123_mean_count_rate = x123_cps_mean_count_rate_ratio_uncertainty_stddev, $
      X123_Summed_Counts=X123_total_counts, $
      X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_accuracy, $
      X123_Summed_Integration_time_seconds=X123_total_integration_time )

    x123_cps_mean_count_rate_uncertainty_precision = $
		minxss_X123_mean_count_rate_uncertainty(x123_counts_deadtime_corrected, $
		x123_energy_bin_centers_kev=energy_bins_kev, $
		integration_time_array=DAXSS_LEVEL0D[wsci[k]].x123_accum_time, $
		fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
		uncertainty_integration_time=uncertatinty_integration_time, $
		uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, $
		use_detector_area=use_detector_area, $
		x123_mean_count_rate = x123_cps_mean_count_rate, $
		x123_count_rate = x123_cps_count_rate, $
		uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_precision, $
		X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_precision )

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;  6.  Calculate the MinXSS X123 irradiance
    minxss_x123_irradiance_wrapper, x123_cps_count_rate, x123_cps_count_rate_uncertainty_accuracy, x123_irradiance_mean, result=x123_irradiance_structure, directory_calibration_file=cal_dir, fm=fm

    ;  The VALID_FLAG may need to be fixed for DAXSS irradiance for 0.5 - 1 keV.
    wgd = where(energy_bins_kev ge 0.5 and energy_bins_kev lt 1.0)
	;   x123_irradiance_structure.valid_flag[wgd] = 1
	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 7. Put data into structures
    ; fill the variables in the level1_x123 structure
    ;
    correct_1AU = (DAXSS_LEVEL0D[wsci[k]].earth_sun_distance)^2.
    minxsslevel1_x123[num_L1].time_gps = DAXSS_LEVEL0D[wsci[k]].time
    minxsslevel1_x123[num_L1].time_jd = DAXSS_LEVEL0D[wsci[k]].time_jd
    minxsslevel1_x123[num_L1].time_yd = DAXSS_LEVEL0D[wsci[k]].time_yd
    minxsslevel1_x123[num_L1].time_iso = DAXSS_LEVEL0D[wsci[k]].time_iso
    minxsslevel1_x123[num_L1].flight_model = DAXSS_LEVEL0D[wsci[k]].flight_model
    minxsslevel1_x123[num_L1].irradiance = x123_irradiance_structure.irradiance*correct_1AU
    minxsslevel1_x123[num_L1].irradiance_uncertainty = x123_irradiance_structure.IRRADIANCE_UNCERTAINTY*correct_1AU
    minxsslevel1_x123[num_L1].energy = energy_bins_kev
    minxsslevel1_x123[num_L1].spectrum_cps = x123_cps_mean_count_rate
    minxsslevel1_x123[num_L1].spectrum_cps_accuracy = x123_cps_mean_count_rate_uncertainty_accuracy
    minxsslevel1_x123[num_L1].spectrum_cps_precision = x123_cps_mean_count_rate_uncertainty_precision
    minxsslevel1_x123[num_L1].spectrum_cps_stddev = !VALUES.F_NAN
    minxsslevel1_x123[num_L1].deadtime_correction_factor = x123_deadtime_correction_scale_factor_array
    minxsslevel1_x123[num_L1].spectrum_total_counts = X123_total_counts
    minxsslevel1_x123[num_L1].spectrum_total_counts_accuracy = X123_total_counts_uncertainty_accuracy
    minxsslevel1_x123[num_L1].spectrum_total_counts_precision = X123_total_counts_uncertainty_precision
    minxsslevel1_x123[num_L1].valid_flag = x123_irradiance_structure.valid_flag
    minxsslevel1_x123[num_L1].integration_time = X123_total_integration_time
    minxsslevel1_x123[num_L1].number_spectra = 1
    minxsslevel1_x123[num_L1].x123_fast_count = fast_count[wsci[k]]
    minxsslevel1_x123[num_L1].x123_slow_count = x123_slow_count_deadtime_corrected
    minxsslevel1_x123[num_L1].sps_on = DAXSS_LEVEL0D[wsci[k]].enable_sps
    minxsslevel1_x123[num_L1].sps_sum = sps_sum[wsci[k]]
    minxsslevel1_x123[num_L1].sps_x = sps_x[wsci[k]]
    minxsslevel1_x123[num_L1].sps_y = sps_y[wsci[k]]
;    minxsslevel1_x123[num_L1].sps_x_hk = (DAXSS_LEVEL0D[wsci[k]].sps_x_hk/10000.)*sps_x_factor ; degrees
;    minxsslevel1_x123[num_L1].sps_y_hk = (DAXSS_LEVEL0D[wsci[k]].sps_y_hk/10000.)*sps_y_factor ; degrees
    minxsslevel1_x123[num_L1].longitude = DAXSS_LEVEL0D[wsci[k]].longitude
    minxsslevel1_x123[num_L1].latitude = DAXSS_LEVEL0D[wsci[k]].latitude
    minxsslevel1_x123[num_L1].altitude = DAXSS_LEVEL0D[wsci[k]].altitude
    minxsslevel1_x123[num_L1].sun_right_ascension = DAXSS_LEVEL0D[wsci[k]].sun_right_ascension
    minxsslevel1_x123[num_L1].sun_declination = DAXSS_LEVEL0D[wsci[k]].sun_declination
    minxsslevel1_x123[num_L1].earth_sun_distance = DAXSS_LEVEL0D[wsci[k]].earth_sun_distance
    minxsslevel1_x123[num_L1].correct_au = correct_1AU
	; New 6/13/2022 Update with addition of background subtraction - track results
	minxsslevel1_x123[num_L1].background_mean = background[wsci[k]].background_mean
	minxsslevel1_x123[num_L1].background_median = background[wsci[k]].background_median
	minxsslevel1_x123[num_L1].background_fit_yzero = background[wsci[k]].fit_coeff[0]
	minxsslevel1_x123[num_L1].background_fit_slope = background[wsci[k]].fit_coeff[1]

	if keyword_set(debug) AND (k eq 0) then stop, 'DEBUG energy_bins_kev and minxsslevel1_x123[0] ...'

    ; New 5/28/2022 Update to zero-out below 0.3 keV
    DAXSS_ENERGY_LIMIT = 0.3
    wzero = where( energy_bins_kev lt DAXSS_ENERGY_LIMIT, num_zero)
    if (num_zero gt 1) then begin
    	minxsslevel1_x123[num_L1].irradiance[wzero] = 0.0
    	minxsslevel1_x123[num_L1].irradiance_uncertainty[wzero] = 0.0
    endif

    ; increment k and num_L1
    if keyword_set(debug) and (k eq 0) then stop, 'DEBUG at first L1 entry...'
    num_L1 += 1
  endfor ; k loop to num_sp
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end x123 science ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Truncate down to the elements used
minxsslevel1_x123 = minxsslevel1_x123[0:num_L1-1]

;
;	calculate Solar Zenith Angle and Tangent Ray Height
;
solar_zenith_altitude, minxsslevel1_x123.time_yd, minxsslevel1_x123.longitude, $
				minxsslevel1_x123.latitude, minxsslevel1_x123.altitude, sza, trh
minxsslevel1_x123.solar_zenith_angle = sza
minxsslevel1_x123.tangent_ray_height = trh

if keyword_set(output_filename) then begin
  outfile = output_filename + '.sav'
endif else begin
  outfile = 'daxss_l1_mission_length_v' + version + '.sav'
endelse

; X123 information structure
minxsslevel1_x123_meta = { $
  Title: 'DAXSS Level 1 Data Product', $
  Source: 'MinXSS-DAXSS SOC at LASP / CU', $
  Mission: 'InspireSat-1 DAXSS (MinXSS-'+fm_str+')', $
  Data_product_type: 'DAXSS Level 1', $
  VERSION: version, $
  Calibration_version: cal_version, $
  Description: 'Calibrated DAXSS X123 science data corrected to 1-AU', $
  History: [ '2022-03-21: Tom Woods: first version based on MinXSS Level 1 algorithms', $
  '2016-2019: MinXSS Processing Development Team'], $
  Filename: outfile, $
  Date_generated: JPMsystime(), $
  TIME_struct: 'Time structure for different date/time formats', $
  TIME_struct_ISO: 'Time in ISO text format', $
  TIME_struct_HUMAN: 'Time in Human-readable text format', $
  TIME_struct_YYYYMMDD: 'Time in Year-Month-Day long integer format', $
  TIME_struct_YYYYDOY: 'Time in Year Day-Of-Year (DOY) long integer format', $
  TIME_struct_HHMMSS: 'Time in Hour-Minute-Second text format', $
  TIME_struct_SOD: 'Time in Seconds of Day (SOD) long integer format', $
  TIME_struct_FOD: 'Time in Fraction of Day (FOD) double format', $
  TIME_struct_JD: 'Time in Julian Date double format', $
  TIME_struct_spacecraftgpsformat: 'Time recorded by spacecraft in GPS Seconds double format', $
  INTERVAL_START_TIME_JD: 'Start Time of the Interval in which the data is averaged in Julian Date double format', $
  INTERVAL_END_TIME_JD: 'End Time of the Interval in which the data is averaged in Julian Date double format', $
  INTERVAL_START_TIME_HUMAN: 'Start Time of the Interval in which the data is averaged in Human format - Calendar Date', $
  INTERVAL_END_TIME_HUMAN: 'End Time of the Interval in which the data is averaged in Human format - Calendar Date', $
  FLIGHT_MODEL: 'MinXSS Flight Model integer (1, 2, or 4)', $
  IRRADIANCE: 'X123 Irradiance in units of photons/sec/cm^2/keV, float array[1024]', $
  IRRADIANCE_UNCERTAINTY: 'X123 Irradiance uncertainty, float array[1024]', $
  ENERGY: 'X123 Energy bins in units of keV, float array[1024]', $
  SPECTRUM_CPS: 'X123 Deadtime corrected spectrum in units of counts per second (cps), float array[1024]', $
  SPECTRUM_CPS_ACCURACY: 'X123 Deadtime corrected spectrum uncertainty including the 10% SURF accuracy (cps), float array[1024]', $
  SPECTRUM_CPS_PRECISION: 'X123 Deadtime corrected spectrum uncertainty soley incluting the instrument measurement precision (cps), float array[1024]', $
  SPECTRUM_CPS_STDDEV: 'X123 If averaging multiple spectra, this is their standard deviation, float array[1024]; else single NaN', $
  DEADTIME_CORRECTION_FACTOR: 'X123 first order deadtime correction factor, double', $
  VALID_FLAG: 'X123 Valid Flag for Irradiance conversion (1=TRUE, 0=FALSE), float array[1024]', $
  SPECTRUM_TOTAL_COUNTS: 'X123 Deadtime corrected spectrum in units of counts per second (cps), float array[1024]', $
  SPECTRUM_TOTAL_COUNTS_ACCURACY: 'X123 Deadtime corrected spectrum uncertainty including the 10% SURF accuracy (total spectral counts over the entire time frame), float array[1024]', $
  SPECTRUM_TOTAL_COUNTS_PRECISION: 'X123 Deadtime corrected spectrum uncertainty soley incluting the instrument measurement precision (total spectral counts over the entire time frame), float array[1024]', $
  INTEGRATION_TIME: 'X123 Integration Time', $
  NUMBER_SPECTRA: 'X123 Number of Spectra in the time interval', $
  X123_FAST_COUNT: 'X123 Fast Counter value (cps)', $
  X123_SLOW_COUNT: 'X123 Slow Counter value (cps)', $
  SPS_ON: 'SPS power flag (1=ON, 0=OFF)', $
  SPS_SUM: 'SPS signal, saturates at 111K DN', $
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
  CORRECT_AU: 'Earth-Sun Distance correction factor' $
}

; Overwrite flight model number by default.
; Why? Level 0d interpolates the hk.flight_model to the sci packet. If hk and sci are too far apart in time, it fills with NaN. Level 1 replaces this NaN with 0.
; We know what level it is though, so just overwrite it unless user does not want this.
IF NOT keyword_set(DO_NOT_OVERWRITE_FM) THEN BEGIN
  minxsslevel1_x123.flight_model = fm
ENDIF

if keyword_set(debug) then BEGIN
	stop, 'DEBUG: at end - will not save limited data set in DEBUG mode ...'
	return
endif

; 9. Save the Level 1 results (mission-length file) data into an IDL .sav file, need to make .netcdf files also
;
; Create the file name extension that changes with the minute average chossen as a variable
;  outdir = fmdir + 'level1' + x_minute_average_string +'minute' + path_sep()

if keyword_set(directory_output_file) then begin
  outdir = directory_output_file
endif else begin
  outdir = fmdir + 'level1' + path_sep()
endelse

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
