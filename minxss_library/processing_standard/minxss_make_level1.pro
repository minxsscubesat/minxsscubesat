;+
; NAME:
;   minxss_make_level1.pro
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
;   minxss_make_level1, fm=fm
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
;   version [string]: Software/data product version to store in filename and internal anonymous structure. Default is '2.0'.
;   cal_version [string]: Calibration version to store in internal anonymous structure. Default is '2.0.0'.
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
;   Need the functions (minxss_x123_correct_deadtime.pro, minxss_X123_mean_count_rate_uncertainty.pro, minxss_XP_mean_count_rate_uncertainty.pro, minxss_XP_signal_from_X123_signal.pro, minxss_x123_invert_count_to_photon_estimate.pro,  minxss_X123_be_photoelectron_si_escape_count_correction.pro)
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
;+
PRO minxss_make_level1, fm=fm, low_count=low_count, directory_flight_model=directory_flight_model, directory_input_file=directory_input_file,  directory_output_file=directory_output_file, directory_calibration_file=directory_calibration_file, output_filename=output_filename, directory_minxss_data=directory_minxss_data, version=version, cal_version=cal_version, $
                        DO_NOT_OVERWRITE_FM=DO_NOT_OVERWRITE_FM, VERBOSE=VERBOSE, DEBUG=DEBUG
  
  ; Defaults
  if keyword_set(debug) then verbose=1

  if not keyword_set(fm) then fm=1    ; Default Flight Model (FM)
  if (fm lt 1) then fm=1
  if (fm gt 2) then fm=2
  fm_str = strtrim(fm,2)
  if keyword_set(verbose) then begin
    print, "minxss_make_level1 is processing data for FM " + fm_str
    print, '   START at ', JPMsystime()
  endif
  IF version EQ !NULL THEN version = '2.0'
  IF cal_version EQ !NULL THEN cal_version = '2.0.0'
  
  ; Constants
  seconds_per_day = 60.0*60.0*24.0

  if fm eq 1 then LOW_LIMIT_DEFAULT = 7.0 $
  else LOW_LIMIT_DEFAULT = 7.0  ; for FM-2 ???
  if not keyword_set(low_limit) then low_limit = LOW_LIMIT_DEFAULT
  if keyword_set(verbose) then print, '     low_limit = ', low_limit
  ;
  ;   1. Read the MinXSS Level 0D mission-length file
  ;
  if keyword_set(directory_minxss_data) then begin
    ddir = directory_minxss_data
  endif else begin
    ddir = getenv('minxss_data')
  endelse
  if strlen(ddir) lt 1 then begin
    print, '*** ERROR finding MinXSS data, you need to define $minxss_data environment variable. But will continue.... Chris Moore edit.'
 ;     return
  endif
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
  infile = 'minxss' + fm_str + '_l0d_mission_length.sav'
  if keyword_set(verbose) then print, '     Reading L0D data'
  restore, indir+infile    ; variable is MINXSSLEVEL0D


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;for testing purposes just run the ~ 1,000 entries
  ;  minxsslevel0d_old = minxsslevel0d
  ; minxsslevel0d = minxsslevel0d[4E3:4.1E3]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ; STOP, 'DEBUG the Level 0D data ...'

  ;
  ; 2. Select (filter) the data for good (valid) data
  ;   not in eclipse by at least one minute, radio flag is less than 1,
  ;   low energy counts are below the low_limit, and ADCS mode is Fine-Ref(1)
  ;
  sp_sec = (minxsslevel0d.time.jd - yd2jd(2016001.D0))*24.D0*3600.  ; seconds since Jan 1, 2016
  ;sp = count rate
  sp = float(minxsslevel0d.x123_spectrum)
  ;raw total counts in the integration time
  sp_counts = sp
  num_sci = n_elements(minxsslevel0d)
  ; convert to counts per sec (cps) with smallest time
  ; Note that Version 1 used x123_live_time instead of x123_accum_time
;  for ii=0,num_sci-1 do sp[*,ii] = sp[*,ii] / (minxsslevel0d[ii].x123_accum_time/1000.)

; Adjust x123_accum_time to be 263 millisec shorter if x123_radio_flag EQ 1
; The x123_accum_time is adjusted in-line in minxsslevel0d because it is used several times in this procedure
  wradio1 = where(minxsslevel0d.x123_radio_flag eq 1, num_radio1)
  if (num_radio1 gt 0) then minxsslevel0d[wradio1].x123_accum_time -= minxsslevel0d[wradio1].x123_radio_flag * 263L
  for ii=0,num_sci-1 do sp[*,ii] = sp[*,ii] / (minxsslevel0d[ii].x123_accum_time/1000.)

  fast_count = minxsslevel0d.x123_fast_count / (minxsslevel0d.x123_accum_time/1000.)
  fast_limit = 3.E4  ; New version 2 value.  Version 1 values was 1.E5 for FM-1
  if fm eq 2 then fast_limit = 3.E4   ; ??? assume same as FM-1
  slow_count = minxsslevel0d.x123_slow_count / (minxsslevel0d.x123_accum_time/1000.)
  new_low_limit = slow_count * 0.006 > low_limit   ; Version 2 improved low_limit for lowcnts check
  if fm eq 2 then new_low_limit = slow_count * 0.006 > low_limit  ; ??? FM-2 may need different function

  sps_sum = total(minxsslevel0d.sps_data_sci[0:3],1) / float(minxsslevel0d.sps_xp_integration_time)
  sps_sum_sun_min = 280000.   ; June 2016 it is 310K; this  allows for 1-AU changes and 5% degradation

  ; exclude spectra with radio on (flag > 1), not in sun, and high low counts
  lowcnts = total( sp[20:24,*], 1 )
  peakcnts = total( sp[36:40,*], 1 )
  PEAK_SLOPE_DEFAULT = 3.0
  lowlimit = 20.0    ; M5 Flare is lt 20
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

for k = 0, n_times_nominal - 1 do begin
  minxss_x123_irradiance_wrapper, sp[*,k], sp[*,k], initial_x123_irradiance_temp, result=initial_x123_irradiance_structure, directory_calibration_file=cal_dir, fm=fm
  initial_x123_irradiance[*,k] = initial_x123_irradiance_structure.irradiance
endfor
  
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

  ; select data without radio beacons, SPS on sun, ADCS in Fine-Ref point mode, and counts acceptable (not noise)
  wsci = where((minxsslevel0d.x123_radio_flag le 1) and (sps_sum gt sps_sum_sun_min) $
               and (minxsslevel0d.adcs_mode eq 1) and ((lowcnts-new_low_limit) le 0) $
               and ((peakcnts*0.5-lowcnts) ge 0) and (peakcnts ge 0.4) $
               and (fast_count lt fast_limit) and (slow_count gt slow_count_min) $
               and (minxsslevel0d.eclipse lt 1.0) and (minxsslevel0d.SPACECRAFT_MODE gt science_mode_flag_threshold) $
               and (fe_cnts lt FE_CNTS_MAX) $
               and (ratio_initial_x123_irradiance_structure_spectrum_photon_flux_index_range_band_2 le limit_value_photon_flux) $
               and minxsslevel0d.x123_read_errors le 5 and minxsslevel0d.x123_write_errors le 5 $
               and minxsslevel0d.x123_spectrum[200] LE 40, $
               num_sp)

  wsci_comparison = where((minxsslevel0d.x123_radio_flag lt 1) and (sps_sum gt sps_sum_sun_min) $
                          and (minxsslevel0d.adcs_mode eq 1) and ((lowcnts-new_low_limit) lt 0) $
                          and ((peakcnts-lowcnts) ge PEAK_SLOPE_DEFAULT) and (peakcnts gt 0) $
                          and (fast_count lt fast_limit) and (slow_count gt slow_count_min) $
                          and (minxsslevel0d.spacecraft_in_saa lt 1.0) and (minxsslevel0d.eclipse lt 1.0) $
                          and (minxsslevel0d.SPACECRAFT_MODE gt science_mode_flag_threshold) and (fe_cnts lt FE_CNTS_MAX), $
                          num_sp_comparison)

  wsci_xp = where((minxsslevel0d.x123_radio_flag lt 1) and (sps_sum gt sps_sum_sun_min) $
                  and (minxsslevel0d.adcs_mode eq 1) and ((lowcnts-new_low_limit) lt 0) $
                  and ((peakcnts-lowcnts) ge PEAK_SLOPE_DEFAULT) and (peakcnts gt 0) $
                  and (fast_count lt fast_limit) and (slow_count gt slow_count_min) $
                  and (minxsslevel0d.spacecraft_in_saa lt 1.0) and (minxsslevel0d.eclipse lt 1.0) $
                  and (minxsslevel0d.SPACECRAFT_MODE gt science_mode_flag_threshold) and (fe_cnts lt FE_CNTS_MAX) $
                  and (((minxsslevel0d.XPS_DATA_SCI/minxsslevel0d.sps_xp_integration_time) - (minxsslevel0d.SPS_DARK_DATA_SCI/minxsslevel0d.sps_xp_integration_time)) gt 0), $
                  num_sp_xp )

  wdark = where((minxsslevel0d.x123_radio_flag lt 1) and (sps_sum lt (sps_sum_sun_min/10.)) $
                and ((lowcnts-new_low_limit) lt 0) and (fast_count lt fast_limit) $
                and (slow_count lt slow_count_max) and (minxsslevel0d.SPACECRAFT_MODE gt science_mode_flag_threshold) $
                and (minxsslevel0d.spacecraft_in_saa lt 1.0) and (minxsslevel0d.eclipse gt 0.0), $
                num_dark)

  if keyword_set(verbose) then print, 'Number of good L0D science packets = ',strtrim(num_sp,2), $
    ' out of ', strtrim(n_elements(minxsslevel0d),2)
  if (num_sp le 1) then begin
    print, '*** ERROR finding any X123 solar data'
    if keyword_set(verbose) then stop, 'DEBUG ...'
    return
  endif

  ;
  ; make SPS pointing information using SCI SPS data (versus lower quality HK SPS data)
  ;
  sps_temp = minxsslevel0d.x123_board_temperature  ; reliable temperature that doesn't depend on I2C monitor
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
  endif else begin
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
  endelse
  SPS_SUM_LIMIT = 5000.  ; fC lower limit
  data1 = ( (minxsslevel0d.sps_data_sci[0]/minxsslevel0d.sps_xp_integration_time - sps_dark1) * sps_gain1 ) > 0.
  data2 = ( (minxsslevel0d.sps_data_sci[1]/minxsslevel0d.sps_xp_integration_time - sps_dark2) * sps_gain2 ) > 0.
  data3 = ( (minxsslevel0d.sps_data_sci[2]/minxsslevel0d.sps_xp_integration_time - sps_dark3) * sps_gain3 ) > 0.
  data4 = ( (minxsslevel0d.sps_data_sci[3]/minxsslevel0d.sps_xp_integration_time - sps_dark4) * sps_gain4 ) > 0.
  sps_sum_best = (data1 + data2 + data3 + data4) > 1.
  sps_x = ((data1 + data2) - (data3 + data4)) * sps_x_factor / sps_sum_best
  sps_y = ((data1 + data4) - (data2 + data3)) * sps_y_factor / sps_sum_best
  wbad = where(sps_sum_best lt SPS_SUM_LIMIT, numbad)
  if (numbad gt 0) then begin
    sps_x[wbad] = !VALUES.F_NAN
    sps_y[wbad] = !VALUES.F_NAN
  endif

  ;
  ; truncate L0D down to good science data (wsci)
  ;
  if keyword_set(verbose) then begin
    print, '   Processing ', strtrim(num_sp,2), ' good spectra out of ', strtrim(num_sci,2)
    if keyword_set(debug) then stop, 'DEBUG at start of irradiance conversion processing ...'
  endif

  ;  add path for the calibration file
  if keyword_set(directory_calibration_file) then begin
    cal_dir = directory_calibration_file
  endif else begin
    cal_dir = getenv('minxss_data')+ path_sep() + 'calibration' + path_sep()
  endelse

  if fm eq 1 then begin
    ; FM-1 values
    minxss_calibration_file = 'minxss_fm1_response_structure.sav'
    minxss_calibration_file_path = cal_dir + minxss_calibration_file
    restore, minxss_calibration_file_path
    nominal_x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
    energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
  endif else begin
    minxss_calibration_file = 'minxss_fm2_response_structure.sav'
    minxss_calibration_file_path = cal_dir + minxss_calibration_file
    restore, minxss_calibration_file_path
    ; FM-2 values  To-Do  (defined by Chris Moore but not uploaded to dropbox yet!)
    nominal_x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
    energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
  endelse

  ;  save energy bins for the return
  energy_bins_kev = nominal_x123_energy_bins_kev + energy_bins_offset

  ; Define the data structures that will be filled in later
  ;minxss-1 x123 science structure
  level1_x123 = { time: minxsslevel0d[0].time, $
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
    x123_radio_flag: 0L, $
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
    sps_x_hk: 0.0, $
    sps_y_hk: 0.0, $
    longitude: 0.0, $
    latitude: 0.0, $
    altitude: 0.0, $
    sun_right_ascension: 0.0, $
    sun_declination: 0.0, $
    earth_sun_distance: 0.0, $
    correct_au: 0.0}

  ;minxss-1 x123 dark data structure
  level1_x123_dark = { time: minxsslevel0d[0].time, $
    flight_model: 0, $
    energy: fltarr(1024), $
    spectrum_cps: fltarr(1024), $
    spectrum_cps_accuracy: fltarr(1024), $
    spectrum_cps_precision: fltarr(1024), $
    spectrum_cps_stddev: fltarr(1024), $
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
    sps_x_hk: 0.0, $
    sps_y_hk: 0.0, $
    longitude: 0.0, $
    latitude: 0.0, $
    altitude: 0.0, $
    sun_right_ascension: 0.0, $
    sun_declination: 0.0, $
    earth_sun_distance: 0.0, $
    correct_au: 0.0}

  ;minxss-1 xp data structure
  level1_xp = { time: minxsslevel0d[0].time, $
    flight_model: 0, $
    signal_fc: 0.0, $
    signal_fc_accuracy: 0.0, $
    signal_fc_precision: 0.0, $
    signal_fc_stddev: 0.0, $
    integration_time: 0.0, $
    ; x123_estimated_xp_fc: 0.0, $ ; JPM 2020-01-21: Removing this variable until we receive a fix for it from Chris (value is a constant 2654.2224). 
    ; x123_estimated_xp_fc_uncertainty: 0.0, $
    ; fractional_difference_x123_estimated_xp_fc: 0.0, $
    number_xp_samples: 0L}


  ;minxss-1 xp dark data structure, same as the normal structure
  level1_xp_dark = level1_xp


;set the xp dark to the x123 dark times
num_xp_dark = num_dark

  ;replicate the structure to the actual number of MinXSS-1 spectra that is valid in the time interval
  minxsslevel1_x123 = replicate(level1_x123, num_sp)
  minxsslevel1_x123_dark = replicate(level1_x123_dark, num_dark)
  minxsslevel1_xp = replicate(level1_xp, num_sp_xp)
  minxsslevel1_xp_dark = replicate(level1_xp_dark, num_xp_dark)


  ;calculate parameters and fill in the structures
  num_L1 = 0L
  num_L1_dark = 0L
  num_L1_xp = 0L
  num_L1_xp_dark = 0L
  num_10percent = long(num_sp/10.)


  ; loop over only the time indices that are known to have minxss data within the x-minute for the current index
  for k = 0, num_sp - 1 do begin  
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;   4. Deadtime correction
    if keyword_set(verbose) then verbose_deadtime=verbose
    x123_counts_deadtime_corrected = minxss_x123_correct_deadtime(float(minxsslevel0d[wsci[k]].x123_spectrum), minxsslevel0d[wsci[k]].x123_accum_time, x123_energy_bin_centers_kev=energy_bins_kev, minxss_instrument_structure_data_file=minxss_calibration_file_path, flight_model_number=1, verbose=verbose_deadtime, $ low_energy_limit=low_energy_limit,  $
      deadtime_correction_scale_factor=x123_deadtime_correction_scale_factor_array)
    ;deadtime corrected slow counts
    x123_slow_count_deadtime_corrected = (total(x123_counts_deadtime_corrected, 1, /double, /nan))/(minxsslevel0d[wsci[k]].x123_accum_time/1000.)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 5.  Calculate the uncertainties
    ;incorporate the SURF relative uncertainty of 10%, to be added in quadrature with the other uncertainties
    ;pre-flight cal uncertainty (SURF) is ~10%
    pre_flight_cal_uncertainty = 0.1

    ;accuracy, calculation from Tom Woods
    x123_cps_mean_count_rate_uncertainty_accuracy = minxss_X123_mean_count_rate_uncertainty(x123_counts_deadtime_corrected, x123_energy_bin_centers_kev=energy_bins_kev, integration_time_array=minxsslevel0d[wsci[k]].x123_accum_time, fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $ uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
      x123_mean_count_rate = x123_cps_mean_count_rate, $
      relative_uncertainty_x123_mean_count_rate = x123_cps_mean_count_rate_relative_uncertainty_accuracy, $
      uncertainty_x123_measured_count_array=x123_measured_count_array_uncertainty, $
      x123_count_rate = x123_cps_count_rate, $
      uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_accuracy, $
      uncertainty_stddev_x123_mean_count_rate=x123_cps_count_rate_stddev, $
      ratio_uncertainty_stddev_x123_mean_count_rate = x123_cps_mean_count_rate_ratio_uncertainty_stddev, $
      X123_Summed_Counts=X123_total_counts, $
      X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_accuracy, $
      X123_Summed_Integration_time_seconds=X123_total_integration_time)

    x123_cps_mean_count_rate_uncertainty_precision = minxss_X123_mean_count_rate_uncertainty(x123_counts_deadtime_corrected, x123_energy_bin_centers_kev=energy_bins_kev, integration_time_array=minxsslevel0d[wsci[k]].x123_accum_time, $ fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $ uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
      x123_mean_count_rate = x123_cps_mean_count_rate, $
      x123_count_rate = x123_cps_count_rate, $
      uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_precision, $
      X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_precision)
      
    

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;  6.  Calculate the MinXSS X123 irradiance
    minxss_x123_irradiance_wrapper, x123_cps_count_rate, x123_cps_count_rate_uncertainty_accuracy, x123_irradiance_mean, result=x123_irradiance_structure, directory_calibration_file=cal_dir, fm=fm

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 7. Put data into structures
    ; fill the variables in the level1_x123 structure
    ;
    correct_1AU = (minxsslevel0d[wsci[k]].earth_sun_distance)^2.
    minxsslevel1_x123[num_L1].time = minxsslevel0d[wsci[k]].time
    minxsslevel1_x123[num_L1].flight_model = minxsslevel0d[wsci[k]].flight_model
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
    minxsslevel1_x123[num_L1].x123_radio_flag = minxsslevel0d[wsci[k]].x123_radio_flag
    minxsslevel1_x123[num_L1].integration_time = X123_total_integration_time
    minxsslevel1_x123[num_L1].number_spectra = 1
    minxsslevel1_x123[num_L1].x123_fast_count = fast_count[wsci[k]]
    minxsslevel1_x123[num_L1].x123_slow_count = x123_slow_count_deadtime_corrected
    minxsslevel1_x123[num_L1].sps_on = minxsslevel0d[wsci[k]].switch_sps
    minxsslevel1_x123[num_L1].sps_sum = sps_sum[wsci[k]]
    minxsslevel1_x123[num_L1].sps_x = sps_x[wsci[k]]
    minxsslevel1_x123[num_L1].sps_y = sps_y[wsci[k]]
    minxsslevel1_x123[num_L1].sps_x_hk = (minxsslevel0d[wsci[k]].sps_x_hk/10000.)*sps_x_factor ; degrees
    minxsslevel1_x123[num_L1].sps_y_hk = (minxsslevel0d[wsci[k]].sps_y_hk/10000.)*sps_y_factor ; degrees
    minxsslevel1_x123[num_L1].longitude = minxsslevel0d[wsci[k]].longitude
    minxsslevel1_x123[num_L1].latitude = minxsslevel0d[wsci[k]].latitude
    minxsslevel1_x123[num_L1].altitude = minxsslevel0d[wsci[k]].altitude
    minxsslevel1_x123[num_L1].sun_right_ascension = minxsslevel0d[wsci[k]].sun_right_ascension
    minxsslevel1_x123[num_L1].sun_declination = minxsslevel0d[wsci[k]].sun_declination
    minxsslevel1_x123[num_L1].earth_sun_distance = minxsslevel0d[wsci[k]].earth_sun_distance
    minxsslevel1_x123[num_L1].correct_au = correct_1AU


    ; increment k and num_L1
    if keyword_set(debug) and (k eq 0) then stop, 'DEBUG at first L1 entry...'
    num_L1 += 1
  endfor ; k loop to num_sp
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end x123 science ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    for k = 0, num_sp_xp - 1 do begin
    ;  find data within x-minute of current index
    ; 7. Include background (from the dark diode) subtracted XP data
      ;incorporate the SURF relative uncertainty of 10%, to be added in quadrature with the other uncertainties
      pre_flight_cal_uncertainty = 0.1

      XP_data_Uncertainty_mean_DN_rate_accuracy = minxss_XP_mean_count_rate_uncertainty(minxsslevel0d[wsci_xp[k]].XPS_DATA_SCI, integration_time_array=minxsslevel0d[wsci_xp[k]].sps_xp_integration_time, XP_Dark_measured_count_array=minxsslevel0d[wsci_xp[k]].SPS_DARK_DATA_SCI, dark_integration_time_array=minxsslevel0d[wsci_xp[k]].sps_xp_integration_time, fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
        XP_mean_count_rate=XP_data_mean_DN_rate, $
        relative_uncertainty_XP_mean_count_rate=xp_data_relative_Uncertainty_mean_DN_rate, $
        uncertainty_XP_measured_count_array=xp_data_uncertainty_measured_DN_array, $
        XP_count_rate=xp_data_DN_rate, $
        uncertainty_XP_measured_count_rate_array=xp_data_uncertainty_DN_rate_accuracy, $
        background_subtracted_mean_count_rate = xp_data_background_subtracted_mean_DN_rate, $
        uncertainty_background_subtracted_mean_count_rate = xp_data_uncertainty_background_subtracted_mean_DN_rate_accuracy, $
        background_subtracted_count_rate = xp_data_background_subtracted_DN_rate, $
        uncertainty_background_subtracted_count_rate = xp_data_uncertainty_background_subtracted_DN_rate_accuracy, $
        mean_background_subtracted_count_rate = xp_data_mean_background_subtracted_DN_rate, $
        uncertainty_mean_background_subtracted_count_rate = xp_data_uncertainty_mean_background_subtracted_DN_rate_accuracy, $
        Out_XP_mean_Dark_count_rate=xp_data_mean_dark_DN_rate, $
        Out_relative_uncertainty_XP_mean_dark_count_rate = xp_data_relative_Uncertainty_mean_dark_DN_rate, $
        out_uncertainty_XP_measured_dark_count_array = xp_data_uncertainty_measured_dark_DN_array_accuracy, $
        out_dark_count_rate = xp_data_dark_DN_rate, $
        out_uncertainty_XP_measured_dark_count_rate_array=xp_data_uncertainty_dark_DN_rate_accuracy)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;Precision

      XP_data_Uncertainty_mean_DN_rate_precision = minxss_XP_mean_count_rate_uncertainty(minxsslevel0d[wsci_xp[k]].XPS_DATA_SCI, integration_time_array=minxsslevel0d[wsci_xp[k]].sps_xp_integration_time, XP_Dark_measured_count_array=minxsslevel0d[wsci_xp[k]].SPS_DARK_DATA_SCI, dark_integration_time_array=minxsslevel0d[wsci_xp[k]].sps_xp_integration_time, $ fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
        uncertainty_XP_measured_count_rate_array=xp_data_uncertainty_DN_rate_precision, $
        uncertainty_background_subtracted_mean_count_rate = xp_data_uncertainty_background_subtracted_mean_DN_rate_precision, $
        uncertainty_background_subtracted_count_rate = xp_data_uncertainty_background_subtracted_DN_rate_precision, $
        uncertainty_mean_background_subtracted_count_rate = xp_data_uncertainty_mean_background_subtracted_DN_rate_precision, $
        out_uncertainty_XP_measured_dark_count_array = xp_data_uncertainty_measured_dark_DN_array_precision, $
        out_uncertainty_XP_measured_dark_count_rate_array=xp_data_uncertainty_dark_DN_rate_precision)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;Calculate the fA data
      xp_data_mean_background_subtracted_fC_rate = minxss_detector_response.XP_FC_PER_DN*xp_data_mean_background_subtracted_DN_rate
      xp_data_uncertainty_mean_background_subtracted_fC_rate_accuracy = minxss_detector_response.XP_FC_PER_DN*xp_data_uncertainty_mean_background_subtracted_DN_rate_accuracy
      xp_data_uncertainty_mean_background_subtracted_fC_rate_precision = minxss_detector_response.XP_FC_PER_DN*xp_data_uncertainty_mean_background_subtracted_DN_rate_precision
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      XP_fc_precision = xp_data_uncertainty_mean_background_subtracted_fC_rate_precision
      XP_fc_accuracy = xp_data_uncertainty_mean_background_subtracted_fC_rate_accuracy
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;7. Compare the predicted XP signal from the X123 measurements
      ;Compare x123 to the XP measurements
      ;use a nominal 0.0 energy bin offset
      energy_bins_offset_zero = 0.0
      if keyword_set(verbose) then verbose_xp_signal_from_x123_signal = verbose

      xp_data_x123_mean_photon_flux_photopeak_XP_Signal = minxss_XP_signal_from_X123_signal(energy_bins_kev, energy_bins_offset_zero, x123_cps_mean_count_rate, counts_uncertainty=x123_cps_mean_count_rate_uncertainty_accuracy, minxss_instrument_structure_data_file=minxss_calibration_file_path, /use_detector_area, verbose=verbose_xp_signal_from_x123_signal, $ 
        output_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=xp_data_mean_DN_signal_estimate_be_photoelectron_only, $
        output_uncertainty_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=xp_data_uncertainty_xp_mean_DN_signal_estimate_be_photoelectron_only, $
        output_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=xp_data_mean_fC_signal_estimate_be_photoelectron_only, $
        output_uncertainty_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=xp_data_uncertainty_mean_xp_fC_signal_estimate_be_photoelectron_only)

      Fractional_Difference_xp_data_mean_DN_signal_estimate_be_photoelectron_only = (xp_data_mean_background_subtracted_DN_rate - xp_data_mean_DN_signal_estimate_be_photoelectron_only)/xp_data_mean_background_subtracted_DN_rate
      Fractional_Difference_xp_data_mean_fC_signal_estimate_be_photoelectron_only = (xp_data_mean_background_subtracted_fC_rate - xp_data_mean_fC_signal_estimate_be_photoelectron_only)/xp_data_mean_background_subtracted_fC_rate
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ; 8. Put data into structures
      ; fill the variables in the level1_xp structure
      minxsslevel1_xp[num_L1_xp].time = minxsslevel0d[wsci_xp[k]].time
      minxsslevel1_xp[num_L1_xp].flight_model = minxsslevel0d[wsci_xp[k]].flight_model
      minxsslevel1_xp[num_L1_xp].signal_fc = xp_data_mean_background_subtracted_fC_rate
      minxsslevel1_xp[num_L1_xp].signal_fc_accuracy = XP_fc_accuracy
      minxsslevel1_xp[num_L1_xp].signal_fc_precision = XP_fc_precision
      minxsslevel1_xp[num_L1_xp].signal_fc_stddev = !VALUES.F_NAN
      minxsslevel1_xp[num_L1_xp].integration_time = minxsslevel0d[wsci_xp[k]].sps_xp_integration_time
      ;minxsslevel1_xp[num_L1_xp].x123_estimated_xp_fc = xp_data_mean_fC_signal_estimate_be_photoelectron_only ; JPM 2020-01-21: Removing this variable until we receive a fix for it from Chris (value is a constant 2654.2224). 
      ;minxsslevel1_xp[num_L1_xp].x123_estimated_xp_fc_uncertainty = xp_data_uncertainty_mean_xp_fC_signal_estimate_be_photoelectron_only
      ;minxsslevel1_xp[num_L1_xp].fractional_difference_x123_estimated_xp_fc = Fractional_Difference_xp_data_mean_fC_signal_estimate_be_photoelectron_only
      minxsslevel1_xp[num_L1_xp].number_xp_samples = minxsslevel0d[wsci_xp[k]].sps_xp_integration_time ; Time and number here are equivalent because each sample is 1 second

      ; increment k and num_L1
      if keyword_set(debug) and (k eq 0) then stop, 'DEBUG at first L1 entry...'
      num_L1_xp += 1
endfor


;X123 dark data 
 for k = 0, num_dark - 1 do begin
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;dark data
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 5.  Calculate the uncertainties
    ;incorporate the SURF relative uncertainty of 10%, to be added in quadrature with the other uncertainties
    ;pre-flight cal uncertainty (SURF) is ~10%
    pre_flight_cal_uncertainty = 0.1
    x123_cps_mean_count_rate_uncertainty_accuracy = minxss_X123_mean_count_rate_uncertainty(float(minxsslevel0d[wdark[k]].x123_spectrum), x123_energy_bin_centers_kev=energy_bins_kev, integration_time_array=minxsslevel0d[wdark[k]].x123_accum_time, fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $ uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
      x123_mean_count_rate = x123_cps_mean_count_rate, $
      relative_uncertainty_x123_mean_count_rate = x123_cps_mean_count_rate_relative_uncertainty_accuracy, $
      uncertainty_x123_measured_count_array=x123_measured_count_array_uncertainty, $
      x123_count_rate = x123_cps_count_rate, $
      uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_accuracy, $
      uncertainty_stddev_x123_mean_count_rate=x123_cps_count_rate_stddev, $
      ratio_uncertainty_stddev_x123_mean_count_rate = x123_cps_mean_count_rate_ratio_uncertainty_stddev, $
      X123_Summed_Counts=X123_total_counts, $
      X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_accuracy, $
      X123_Summed_Integration_time_seconds=X123_total_integration_time)

    x123_cps_mean_count_rate_uncertainty_precision = minxss_X123_mean_count_rate_uncertainty(float(minxsslevel0d[wdark[k]].x123_spectrum), x123_energy_bin_centers_kev=energy_bins_kev, integration_time_array=minxsslevel0d[wdark[k]].x123_accum_time, $ fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $ uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
      x123_mean_count_rate = x123_cps_mean_count_rate, $
      x123_count_rate = x123_cps_count_rate, $
      uncertainty_x123_measured_count_rate_array=x123_cps_count_rate_uncertainty_precision, $
      X123_uncertainty_Summed_Counts = X123_total_counts_uncertainty_precision)

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 6. Put data into structures
    ; fill the variables in the level1_x123 structure
    ;
    correct_1AU = (minxsslevel0d[wdark[k]].earth_sun_distance)^2.
    minxsslevel1_x123_dark[num_L1_dark].time = minxsslevel0d[wdark[k]].time
    minxsslevel1_x123_dark[num_L1_dark].flight_model = minxsslevel0d[wdark[k]].flight_model
    minxsslevel1_x123_dark[num_L1_dark].energy = energy_bins_kev
    minxsslevel1_x123_dark[num_L1_dark].spectrum_cps = x123_cps_mean_count_rate
    minxsslevel1_x123_dark[num_L1_dark].spectrum_cps_accuracy = x123_cps_mean_count_rate_uncertainty_accuracy
    minxsslevel1_x123_dark[num_L1_dark].spectrum_cps_precision = x123_cps_mean_count_rate_uncertainty_precision
    minxsslevel1_x123_dark[num_L1_dark].spectrum_cps_stddev = !VALUES.F_NAN
    minxsslevel1_x123_dark[num_L1_dark].spectrum_total_counts = X123_total_counts
    minxsslevel1_x123_dark[num_L1_dark].spectrum_total_counts_accuracy = X123_total_counts_uncertainty_accuracy
    minxsslevel1_x123_dark[num_L1_dark].spectrum_total_counts_precision = X123_total_counts_uncertainty_precision
    minxsslevel1_x123_dark[num_L1_dark].integration_time = X123_total_integration_time
    minxsslevel1_x123_dark[num_L1_dark].number_spectra = 1
    minxsslevel1_x123_dark[num_L1_dark].x123_fast_count = fast_count[wdark[k]]
    minxsslevel1_x123_dark[num_L1_dark].x123_slow_count = slow_count[wdark[k]]
    minxsslevel1_x123_dark[num_L1_dark].sps_on = minxsslevel0d[wdark[k]].switch_sps
    minxsslevel1_x123_dark[num_L1_dark].sps_sum = sps_sum[wdark[k]]
    minxsslevel1_x123_dark[num_L1_dark].sps_x = sps_x[wdark[k]]
    minxsslevel1_x123_dark[num_L1_dark].sps_y = sps_y[wdark[k]]
    minxsslevel1_x123_dark[num_L1_dark].sps_x_hk = (minxsslevel0d[wdark[k]].sps_x_hk/10000.)*sps_x_factor ; degrees
    minxsslevel1_x123_dark[num_L1_dark].sps_y_hk = (minxsslevel0d[wdark[k]].sps_y_hk/10000.)*sps_y_factor ; degrees
    minxsslevel1_x123_dark[num_L1_dark].longitude = minxsslevel0d[wdark[k]].longitude
    minxsslevel1_x123_dark[num_L1_dark].latitude = minxsslevel0d[wdark[k]].latitude
    minxsslevel1_x123_dark[num_L1_dark].altitude = minxsslevel0d[wdark[k]].altitude
    minxsslevel1_x123_dark[num_L1_dark].sun_right_ascension = minxsslevel0d[wdark[k]].sun_right_ascension
    minxsslevel1_x123_dark[num_L1_dark].sun_declination = minxsslevel0d[wdark[k]].sun_declination
    minxsslevel1_x123_dark[num_L1_dark].earth_sun_distance = minxsslevel0d[wdark[k]].earth_sun_distance
    minxsslevel1_x123_dark[num_L1_dark].correct_au = correct_1AU


    ; increment k and num_L1
    if keyword_set(debug) and (k eq 0) then stop, 'DEBUG at first L1 entry...'
    num_L1_dark += 1
endfor
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end x123 dark ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; start xp dark ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Xp dark data
  for k = 0, num_xp_dark - 1 do begin
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 5.  Calculate the uncertainties
    ; Include background (from the dark diode) subtracted XP data
    ;incorporate the SURF relative uncertainty of 10%, to be added in quadrature with the other uncertainties
    pre_flight_cal_uncertainty = 0.1
    XP_data_Uncertainty_mean_DN_rate_accuracy = minxss_XP_mean_count_rate_uncertainty(minxsslevel0d[wdark[k]].XPS_DATA_SCI, integration_time_array=minxsslevel0d[wdark[k]].sps_xp_integration_time, XP_Dark_measured_count_array=minxsslevel0d[wdark[k]].SPS_DARK_DATA_SCI, dark_integration_time_array=minxsslevel0d[wdark[k]].sps_xp_integration_time, fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
      XP_mean_count_rate=XP_data_mean_DN_rate, $
      relative_uncertainty_XP_mean_count_rate=xp_data_relative_Uncertainty_mean_DN_rate, $
      uncertainty_XP_measured_count_array=xp_data_uncertainty_measured_DN_array, $
      XP_count_rate=xp_data_DN_rate, $
      uncertainty_XP_measured_count_rate_array=xp_data_uncertainty_DN_rate_accuracy, $
      background_subtracted_mean_count_rate = xp_data_background_subtracted_mean_DN_rate, $
      uncertainty_background_subtracted_mean_count_rate = xp_data_uncertainty_background_subtracted_mean_DN_rate_accuracy, $
      background_subtracted_count_rate = xp_data_background_subtracted_DN_rate, $
      uncertainty_background_subtracted_count_rate = xp_data_uncertainty_background_subtracted_DN_rate_accuracy, $
      mean_background_subtracted_count_rate = xp_data_mean_background_subtracted_DN_rate, $
      uncertainty_mean_background_subtracted_count_rate = xp_data_uncertainty_mean_background_subtracted_DN_rate_accuracy, $
      Out_XP_mean_Dark_count_rate=xp_data_mean_dark_DN_rate, $
      Out_relative_uncertainty_XP_mean_dark_count_rate = xp_data_relative_Uncertainty_mean_dark_DN_rate, $
      out_uncertainty_XP_measured_dark_count_array = xp_data_uncertainty_measured_dark_DN_array_accuracy, $
      out_dark_count_rate = xp_data_dark_DN_rate, $
      out_uncertainty_XP_measured_dark_count_rate_array=xp_data_uncertainty_dark_DN_rate_accuracy)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Precision

    XP_data_Uncertainty_mean_DN_rate_precision = minxss_XP_mean_count_rate_uncertainty(minxsslevel0d[wdark[k]].XPS_DATA_SCI, integration_time_array=minxsslevel0d[wdark[k]].sps_xp_integration_time, XP_Dark_measured_count_array=minxsslevel0d[wdark[k]].SPS_DARK_DATA_SCI, dark_integration_time_array=minxsslevel0d[wdark[k]].sps_xp_integration_time, $ fractional_systematic_uncertainty=pre_flight_cal_uncertainty, $
      uncertainty_XP_measured_count_rate_array=xp_data_uncertainty_DN_rate_precision, $
      uncertainty_background_subtracted_mean_count_rate = xp_data_uncertainty_background_subtracted_mean_DN_rate_precision, $
      uncertainty_background_subtracted_count_rate = xp_data_uncertainty_background_subtracted_DN_rate_precision, $
      uncertainty_mean_background_subtracted_count_rate = xp_data_uncertainty_mean_background_subtracted_DN_rate_precision, $
      out_uncertainty_XP_measured_dark_count_array = xp_data_uncertainty_measured_dark_DN_array_precision, $
      out_uncertainty_XP_measured_dark_count_rate_array=xp_data_uncertainty_dark_DN_rate_precision)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Calculate the fA data
    xp_data_mean_background_subtracted_fC_rate = minxss_detector_response.XP_FC_PER_DN*xp_data_mean_background_subtracted_DN_rate
    xp_data_uncertainty_mean_background_subtracted_fC_rate_accuracy = minxss_detector_response.XP_FC_PER_DN*xp_data_uncertainty_mean_background_subtracted_DN_rate_accuracy
    xp_data_uncertainty_mean_background_subtracted_fC_rate_precision = minxss_detector_response.XP_FC_PER_DN*xp_data_uncertainty_mean_background_subtracted_DN_rate_precision
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    XP_fc_precision = xp_data_uncertainty_mean_background_subtracted_fC_rate_precision
    XP_fc_accuracy = xp_data_uncertainty_mean_background_subtracted_fC_rate_accuracy
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Compare x123 to the XP measurements
    ;use a nominal 0.0 energy bin offset
    energy_bins_offset_zero = 0.0
    if keyword_set(verbose) then verbose_xp_signal_from_x123_signal = verbose

    xp_data_x123_mean_photon_flux_photopeak_XP_Signal = minxss_XP_signal_from_X123_signal(energy_bins_kev, energy_bins_offset_zero, x123_cps_mean_count_rate, counts_uncertainty=x123_cps_mean_count_rate_uncertainty_accuracy, minxss_instrument_structure_data_file=minxss_calibration_file_path, /use_detector_area, verbose=verbose_xp_signal_from_x123_signal, $ ; input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, $
      ;  output_uncertainty_XP_DN_signal_estimate_ARRAY=output_model_uncertainty_XP_DN_signal_estimate, $
      ;  output_XP_fC_signal_estimate_ARRAY=output_model_XP_fC_signal_estimate, $
      ;  output_uncertainty_XP_fC_signal_estimate_ARRAY=output_model_uncertainty_XP_fC_signal_estimate, $
      ;  output_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_DN_signal_estimate_be_si_photopeak_only, $
      ;  output_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only, $
      ;  output_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_fC_signal_estimate_be_si_photopeak_only, $
      ;  output_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only, $
      output_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=xp_data_mean_DN_signal_estimate_be_photoelectron_only, $
      output_uncertainty_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=xp_data_uncertainty_xp_mean_DN_signal_estimate_be_photoelectron_only, $
      output_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=xp_data_mean_fC_signal_estimate_be_photoelectron_only, $
      output_uncertainty_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=xp_data_uncertainty_mean_xp_fC_signal_estimate_be_photoelectron_only)

    Fractional_Difference_xp_data_mean_DN_signal_estimate_be_photoelectron_only = (xp_data_mean_background_subtracted_DN_rate - xp_data_mean_DN_signal_estimate_be_photoelectron_only)/xp_data_mean_background_subtracted_DN_rate
    Fractional_Difference_xp_data_mean_fC_signal_estimate_be_photoelectron_only = (xp_data_mean_background_subtracted_fC_rate - xp_data_mean_fC_signal_estimate_be_photoelectron_only)/xp_data_mean_background_subtracted_fC_rate
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; 8. Put data into structures
    ; fill the variables in the level1_xp structure
    minxsslevel1_xp_dark[num_L1_xp_dark].time = minxsslevel0d[wdark[k]].time
    minxsslevel1_xp_dark[num_L1_xp_dark].flight_model = minxsslevel0d[wdark[k]].flight_model
    minxsslevel1_xp_dark[num_L1_xp_dark].signal_fc = xp_data_mean_background_subtracted_fC_rate
    minxsslevel1_xp_dark[num_L1_xp_dark].signal_fc_accuracy = XP_fc_accuracy
    minxsslevel1_xp_dark[num_L1_xp_dark].signal_fc_precision = XP_fc_precision
    minxsslevel1_xp_dark[num_L1_xp_dark].signal_fc_stddev = !VALUES.F_NAN
    minxsslevel1_xp_dark[num_L1_xp_dark].integration_time = minxsslevel0d[wdark[k]].sps_xp_integration_time
    ; minxsslevel1_xp_dark[num_L1_xp_dark].x123_estimated_xp_fc = xp_data_mean_fC_signal_estimate_be_photoelectron_only ; JPM 2020-01-21: Removing this variable until we receive a fix for it from Chris (value is a constant 2654.2224). 
    ; minxsslevel1_xp_dark[num_L1_xp_dark].x123_estimated_xp_fc_uncertainty = xp_data_uncertainty_mean_xp_fC_signal_estimate_be_photoelectron_only
    ; minxsslevel1_xp_dark[num_L1_xp_dark].fractional_difference_x123_estimated_xp_fc = Fractional_Difference_xp_data_mean_fC_signal_estimate_be_photoelectron_only
    minxsslevel1_xp_dark[num_L1_xp_dark].number_xp_samples = minxsslevel0d[wdark[k]].sps_xp_integration_time ; time and number are equivalent here because each sample is 1 second


    ; increment k and num_L1
    if keyword_set(debug) and (k eq 0) then stop, 'DEBUG at first L1 entry...'
    num_L1_xp_dark += 1
endfor
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end xp dark ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Truncate down to the elements used
minxsslevel1_x123 = minxsslevel1_x123[0:num_L1-1]
minxsslevel1_xp = minxsslevel1_xp[0:num_L1_xp-1]
minxsslevel1_x123_dark = minxsslevel1_x123_dark[0:num_L1_dark-1]
minxsslevel1_xp_dark = minxsslevel1_xp_dark[0:num_L1_xp_dark-1]

if keyword_set(output_filename) then begin
  outfile = output_filename + '.sav'
endif else begin
  outfile = 'minxss' + fm_str + '_l1_mission_length_v' + version + '.sav'
endelse

; X123 information structure
minxsslevel1_x123_meta = { $
  Title: 'MinXSS Level 1 Data Product', $
  Source: 'MinXSS SOC at LASP / CU', $
  Mission: 'MinXSS-'+fm_str, $
  Data_product_type: 'MinXSS Level 1', $
  VERSION: version, $
  Calibration_version: cal_version, $
  Description: 'Calibrated MinXSS X123 science data corrected to 1-AU', $
  History: [ '2016-07-30: Tom Woods: Updated with meta-data, latest Level 0D, and 1-AU correction', $
  '2016-07-25: Tom Woods: Original Level 1 code for first version of Level 0D', '2017-06-23: Chris Moore: added first-order deadtime correction, x minute averaging, XP data', $
  '2019-11-12: James Paul Mason: Bug fixes and variable renaming.'], $
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
  FLIGHT_MODEL: 'MinXSS Flight Model integer (1 or 2)', $
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
  X123_FAST_COUNT: 'X123 Fast Counter value', $
  X123_SLOW_COUNT: 'X123 Slow Counter value: spectral integration of counts over 1024 bins', $
  SPS_ON: 'SPS power flag (1=ON, 0=OFF)', $
  SPS_SUM: 'SPS signal in units of fC, normally about 2E6 fC when in sunlight', $
  SPS_X: 'SPS X-axis offset from the sun center (NaN if SPS is not in the sun)', $
  SPS_Y: 'SPS Y-axis offset from the sun center (NaN if SPS is not in the sun)', $
  SPS_X_HK: 'SPS X-axis offset from the sun center (NaN if SPS is not in the sun)', $
  SPS_Y_HK: 'SPS Y-axis offset from the sun center (NaN if SPS is not in the sun)', $
  LONGITUDE: 'Earth Longitude for this measurement in units of degrees', $
  LATITUDE : 'Earth Latitude for this measurement in units of degrees', $
  ALTITUDE : 'Earth Altitude for this measurement in units of km from Earth center', $
  SUN_RIGHT_ASCENSION: 'Sun Right Ascension from orbit location', $
  SUN_DECLINATION: 'Sun Declination from orbit location', $
  EARTH_SUN_DISTANCE: 'Earth-Sun Distance in units of AU (irradiance is corrected to 1AU)', $
  CORRECT_AU: 'Earth-Sun Distance correction factor' $
}

; XP information structure
minxsslevel1_xp_meta = { $
  Title: 'MinXSS Level 1 Data Product corrected', $
  Source: 'MinXSS SOC at LASP / CU', $
  Mission: 'MinXSS-'+fm_str, $
  Data_product_type: 'MinXSS Level 1', $
  VERSION: version, $
  Calibration_version: cal_version, $
  Description: 'Calibrated MinXSS X123 science data corrected to 1-AU', $
  History: [ '2016/07/30: Tom Woods: Updated with meta-data, latest Level 0D, and 1-AU correction', $
  '2016/07/25: Tom Woods: Original Level 1 code for first version of Level 0D', '2017/06/23: Chris Moore: added first-order deadtime correction, XP data'], $
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
  FLIGHT_MODEL: 'MinXSS Flight Model integer (1 or 2)', $
  SIGNAL_FC: 'XP background subtracted (dark diode) signal in units of femtocoulombs per second (fc/s -> fA), float array[1024]', $
  signal_fc_accuracy: 'XP signal uncertainty including the 10% SURF accuracy (cps), float array[1024]', $
  signal_fc_precision: 'XP signal uncertainty soley incluting the instrument measurement precision (cps), float array[1024]', $
  signal_fc_stddev: 'XP signal standard deviation of the float array[1024]', $
  INTEGRATION_TIME: 'X123 Integration Time accumulated over the', $
  ;XP_FC_X123_ESTIMATED: 'XP signal estimated from the measured X123 spectra in units of femtocoulombs per second (fc/s -> fA), double array', $
  ;XP_FC_X123_ESTIMATED_UNCERTAINTY: 'XP signal uncertainty of the estimated XP signal from the measured X123 spectra, double array', $
  ;FRACTIONAL_DIFFERENCE_XP_FC_X123_ESTIMATED: 'Fractional difference between the actual measured XP signal and the estimated XP signal from the measured X123 spectra, double array', $
  NUMBER_XP_SAMPLES: 'XP number of samples' $
}

; Overwrite flight model number by default. 
; Why? Level 0d interpolates the hk.flight_model to the sci packet. If hk and sci are too far apart in time, it fills with NaN. Level 1 replaces this NaN with 0. 
; We know what level it is though, so just overwrite it unless user does not want this. 
IF NOT keyword_set(DO_NOT_OVERWRITE_FM) THEN BEGIN
  minxsslevel1_x123.flight_model = fm
  minxsslevel1_x123_dark.flight_model = fm
  minxsslevel1_xp.flight_model = fm
  minxsslevel1_xp_dark.flight_model = fm  
ENDIF

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
minxsslevel1 = {x123:minxsslevel1_x123, $ ; FIXME: time structure needs to be elevated to this same level, i.e., minxsslevel1.time instead of redundantly minxsslevel1.x123.time minxsslevel1.x123_dark.time, etc
                x123_meta:minxsslevel1_x123_meta, $
                x123_dark:minxsslevel1_x123_dark, $
                xp:minxsslevel1_xp, $
                xp_meta:minxsslevel1_xp_meta, $
                xp_dark:minxsslevel1_xp_dark}
                
;save the data as a .sav and .ncdf files
save, /compress, minxsslevel1, file=outdir+outfile
minxss_make_netcdf, '1', fm = fm, verbose = verbose

if keyword_set(verbose) then print, 'END of minxss_make_level1 at ', JPMsystime()

if keyword_set(debug) then stop, 'DEBUG at end of minxss_make_level1.pro ...'


END
