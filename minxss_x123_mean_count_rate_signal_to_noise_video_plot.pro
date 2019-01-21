

;+
; NAME:
;   minxss_x123_mean_count_rate_signal_to_noise_video_plot
;
;
; AUTHOR:
;   Chris Moore, Harvard-Smithsonian Center for Astrophysics, 60 Garden Street, Cambridge, MA, USA
;   christopher.s.moore@cfa.harvard.edu
;
; PURPOSE: Calculate the signal-to-noise ratio as a function of the number of data sets. Determines the uncertainty from the measured count spectrum (counts/s) per integration time (accumulation time) per energy bin. Options to normalize by the detector area (/use_detector_area) and the bin width (use_bin_width) -> (counts/s/keV/cm^2)
;
;
; CALLING SEQUENCE: result = minxss_x123_mean_count_rate_signal_to_noise_video_plot(time_jd_array, x123_measured_count_array, x123_energy_bin_centers_kev=x123_energy_bin_centers_kev, fm=fm, xtickinterval_time_series=xtickinterval_time_series, integration_time_seconds_array=integration_time_seconds_array, uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, make_plot=make_plot, plot_title=plot_title, min_signal_noise_ratio=min_signal_noise_ratio, min_energy_bin_kev=min_energy_bin_kev, make_video=make_video, file_directory_video=file_directory_video, filename_video=filename_video, video_fps=video_fps, video_file_type=video_file_type, verbose=verbose)

;
; DESCRIPTION: Makes plots and videos of the signal-to-noise ratio of the X123 spectrum as a function of data sets. Takes the x123 measured count spectrum array as a function of time and calculates the mean count rate, uncertainties on that mean count rate, the count rate vs. time and uncertainties on that count rate vs. time.
;              Noise Contributions include, Poisson noise (photon arrival probability), uncertainty in the X123 accumulation timer, uncertainty of the Sun's position accross the X123 FOV, per integration time - *can be modified to incorporate in orbit FOV map in the future.*
;              Has the option to return the count rate normalized (divided) by the detector area (/use_detector_area keyword) and/or energy bin width (/use_bin_width keyword).

; INPUTS: x123 measured count spectrum (counts/s) vs. integration period, x123 energy bins (keV), video and plot file names, file directories.
;           Array is assumed to be in the order of counts_array[time,energy]

;
; INPUT KEYWORD PARAMETERS: /use_detector_area, divides the resultant count spectrum by the X123 geometric aperture area,
;                           /use_bin_width, divides the resultant count spectrum by the X123 energy bin width, nominally 0.03 keV, but if x123_energy_bin_centers_kev is supplied then the value is taken from there.
;

; RETURNS: signal-to-noise ratio. Uncertainty on the mean count rate spectrum (counts/s),
;           if keyword /use_detector_area set then (counts/s/cm^2)
;           if keyword /use_bin_width set then (counts/s/keV)
;           if keywords /use_detector_area and /use_bin_width are set then (counts/s/keV/cm^2)

;
;
; Details:
;
;
;time_jd_array:                                                                 [INPUT] time array in Julian Date (will add anytim in future versions for any input format (ARRAY)
;x123_measured_count_array:                                                     [INPUT] x123 measured count spectrum vs. integration time periods (ARRAY)
;x123_energy_bin_centers_kev:                                                   [OPTIONAL INPUT] input X123 energy bins (ARRAY)
;fm:                                                                            [OPTIONAL INPUT] flight model number for MinXSS
;integration_time_seconds_array                                                 [OPTIONAL INPUT] integration time array in milliseconds (ms) (ARRAY), if not supplied, the nominal X123 10,000 milliseconds is used
;xtickinterval_time_series:                                                     [OPTIONAL INPUT] tick interval for the display times on the abscissa of the time series plot
;uncertainty_integration_time                                                   [OPTIONAL INPUT] array of uncertainty times in the X123 accumulation counter (ARRAY), if not supplied, currently taken to be nominally 1 ms
;uncertainty_fov                                                                [OPTIONAL INPUT] values of foV uncertainties as a function of integration time periods *can be modified to adjust the counts by an on orbit fov map* (ARRAY), if not supplied, curently taken to be +/- 3% from NIST fov map
;use_bin_width                                                                  [BOOLEAN KEYWORD] set this keyword to use the energy bin width (keV) in the calculation
;use_detector_area                                                              [BOOLEAN KEYWORD] set this keyword to use the detector area in the calculation
;make_plot                                                                      [BOOLEAN KEYWORD] set this keyword to output a plot using the IDL plot FUNCTION
;plot_title                                                                     [OPTIONAL INPUT]  plot title (string)
;min_signal_noise_ratio                                                         [OPTIONAL INPUT] minimun signal-to-noise to plot, default is 1.0
;min_energy_bin_kev                                                             [OPTIONAL INPUT] minimun energy bin in keV to plot, default is 0.5
;make_video                                                                     [BOOLEAN KEYWORD] set this keyword to create a video of the signal-to-noise and the spectrum vs. time
;file_directory_video                                                           [OPTIONAL INPUT] set the directory to save the video, the default is home, '= getenv(HOME)'
;filename_video                                                                 [OPTIONAL INPUT] set the video fileneme
;video_fps                                                                      [OPTIONAL INPUT] set the video frames-per-second, default is 5
;video_file_type                                                                [OPTIONAL INPUT] set the video file type (options are .mp4, .avi, .webm, .flv, .mjpeg, .swf. Default is .mp4. Details are at https://www.harrisgeospatial.com/docs/CreatingVideo.html
;verbose                                                                        [BOOLEAN KEYWORD] set this keyword to print details to the IDL Console


; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, January 18, 2019, Christopher S. Moore
;   Harvard-Smithsonain Center for Astrophysics
;
;
;-
;-
function minxss_x123_mean_count_rate_signal_to_noise_video_plot, time_jd_array, x123_measured_count_array, x123_energy_bin_centers_kev=x123_energy_bin_centers_kev, fm=fm, xtickinterval_time_series=xtickinterval_time_series, integration_time_seconds_array=integration_time_seconds_array, uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, make_plot=make_plot, plot_title=plot_title, min_signal_noise_ratio=min_signal_noise_ratio, min_energy_bin_kev=min_energy_bin_kev, make_video=make_video, file_directory_video=file_directory_video, filename_video=filename_video, video_fps=video_fps, video_file_type=video_file_type, verbose=verbose
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Convert_keV_Nanometers = 1.24
  Convert_Meters_Nanameters = 1.0E9
  Convert_Angstroms_Nanameters = 1.0E-1
  CONVERT_um_to_cm = 1.0E-4
  CONVERT_A_to_um = CONVERT_um_to_cm
  CONVERT_ms_to_s = 1.0e-3
  e_h_Pair_keV = 0.00365
  Convert_keV_ev = 1.0e3
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Minxss x123 area in cm^2
  x123_diameter_um = 178.0
  x123_diameter_cm = CONVERT_um_to_cm*x123_diameter_um
  x123_area_cm = !PI*((0.5*x123_diameter_cm)^(2.0))
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Minxss flight model
  IF KEYWORD_SET(fm) THEN begin
    fm_string = string(fm)
  ENDIF else begin
    ;default is fm = 1
    fm_string = '1'
  Endelse
  
  ;  Find the total number of integrations
  ;Assume that the second indicie of the array be the time component and the first section is the energy bins
  N_Integrations = n_elements(x123_measured_count_array[0,*])

  ;Find the number of spectra
  N_energy_bins = n_elements(x123_measured_count_array[*,0])

  ;calculate the total counts per second
  dimension_spectrum_sum = 1
  spectrum_summed_count_rate_array = total(x123_measured_count_array, dimension_spectrum_sum, /double, /nan)/integration_time_seconds_array

  ;Energy_bin_width
  IF KEYWORD_SET(x123_energy_bin_centers_kev) THEN begin
    minxss_gain = ABS(x123_energy_bin_centers_kev[0] - x123_energy_bin_centers_kev[1])
  ENDIF else begin
    ;nominally 0.03
    minxss_gain = 0.03
  Endelse

  ;Energy_bin_offset
  IF KEYWORD_SET(x123_energy_bin_centers_kev) THEN begin
    minxss_offset = x123_energy_bin_centers_kev[0]
  ENDIF else begin
    ;nominally 0.0
    minxss_offset = 0.0
  Endelse

  ;make _the goes date label
  GOES15_FLUX_Data_mission_LABEL_DATE = LABEL_DATE(DATE_FORMAT=['%H:%I','%M-%D','%Y'])
  IF KEYWORD_SET(XTICKINTERVAL_time_series) THEN begin
    XTICKINTERVAL_time_series_use = XTICKINTERVAL_time_series
  ENDIF else begin
    ;default is XTICKINTERVAL_time_series = 1
    XTICKINTERVAL_time_series_use = 1
  Endelse
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Calculate the signal-to-noise for all the data sets enterd to set the plot limits.
  minxss_all_uncertainty_X123_mean_count_rate = minxss_x123_uncertainty_mean_count_rate(x123_measured_count_array, x123_energy_bin_centers_kev=x123_energy_bin_centers_kev, integration_time_array=(integration_time_seconds_array/CONVERT_ms_to_s), uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
    x123_mean_count_rate = minxss_all_mean_count_rate, $
    uncertainty_x123_measured_count_array=minxss_all_uncertainty_x123_measured_count_array, $
    x123_count_rate = minxss_all_count_rate, $
    uncertainty_x123_measured_count_rate_array=minxss_all_uncertainty_x123_measured_count_rate_array, $
    uncertainty_stddev_x123_mean_count_rate=minxss_all_uncertainty_stddev_mean_count_rate, $
    ratio_uncertainty_stddev_x123_mean_count_rate = minxss_all_ratio_uncertainty_stddev_mean_count_rate, $
    X123_Summed_Counts=minxss_all_Summed_Counts, $
    X123_uncertainty_Summed_Counts = minxss_all_uncertainty_Summed_Counts, $
    X123_Summed_Integration_time_seconds=minxss_all_Summed_Integration_time_seconds)

  signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array = minxss_all_mean_count_rate/minxss_all_uncertainty_X123_mean_count_rate
  ;pad any negative or unknown values with 0's
  index_negative_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array = where(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array LT 0.0, n_index_negative_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array)
  if n_index_negative_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array gt 0 then signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array[index_negative_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array] = 0.0
  ;get rid of NANs
  index_NAN_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array = where(finite(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array, /nan) gt 0)
  if n_elements(index_NAN_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array) gt 0 then signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array[index_NAN_signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;plot limits
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Y_MAX_minxss2_x123_signal_noise_ratio = max(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array)
  if keyword_set(min_signal_noise_ratio) then begin
    Y_MIN_minxss2_x123_signal_noise_ratio = min_signal_noise_ratio
  endif else begin
    Y_MIN_minxss2_x123_signal_noise_ratio = 1.0E0
  endelse
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  min_spectrum_summed_count_rate_array = min(spectrum_summed_count_rate_array)
  ratio_N_Integrations_min_spectrum_summed_count_rate_array = sqrt(N_Integrations)/min_spectrum_summed_count_rate_array
  buffer_ratio_N_Integrations_min_spectrum_summed_count_rate_array = 0.5
;  x123_SPECTRUM_ENERGY_KeV_MAX = x123_energy_bin_centers_kev[max(where(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array ge Y_MIN_minxss2_x123_signal_noise_ratio))]
  x123_SPECTRUM_ENERGY_KeV_MAX = x123_energy_bin_centers_kev[max(where(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array ge ratio_N_Integrations_min_spectrum_summed_count_rate_array + buffer_ratio_N_Integrations_min_spectrum_summed_count_rate_array))]

  if keyword_set(min_signal_noise_ratio) then begin
    x123_SPECTRUM_ENERGY_KeV_MIN = min_energy_bin_kev
  endif else begin
    x123_SPECTRUM_ENERGY_KeV_MIN = 0.5
  endelse
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  plot_buffer_X123_RAW_COUNT_RATE_FM2 = 1.0
  Y_MAX_X123_RAW_COUNT_RATE_FM2 = max(minxss_all_mean_count_rate) + plot_buffer_X123_RAW_COUNT_RATE_FM2
  Y_MIN_X123_RAW_COUNT_RATE_FM2 = min(minxss_all_mean_count_rate[where(signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array ge Y_MIN_minxss2_x123_signal_noise_ratio)])
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Time_Chossen_Max = max(time_jd_array)
  Time_Chossen_Min = min(time_jd_array)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  slow_counts_plot_buffer = 1.0
  Y_MAX_Slow_Counts = max(spectrum_summed_count_rate_array) + slow_counts_plot_buffer
  Y_Min_Slow_Counts = min(spectrum_summed_count_rate_array) - slow_counts_plot_buffer
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Calculate the signal-to-noise forr the first data set for sc0ing to the integrations for 0 the data sets.
  minxss_0_uncertainty_X123_mean_count_rate = minxss_x123_uncertainty_mean_count_rate(x123_measured_count_array[*,0], x123_energy_bin_centers_kev=x123_energy_bin_centers_kev, integration_time_array=(integration_time_seconds_array[0]/CONVERT_ms_to_s), uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
    x123_mean_count_rate = minxss_0_mean_count_rate, $
    uncertainty_x123_measured_count_array=minxss_0_uncertainty_x123_measured_count_array, $
    x123_count_rate = minxss_0_count_rate, $
    uncertainty_x123_measured_count_rate_array=minxss_0_uncertainty_x123_measured_count_rate_array, $
    uncertainty_stddev_x123_mean_count_rate=minxss_0_uncertainty_stddev_mean_count_rate, $
    ratio_uncertainty_stddev_x123_mean_count_rate = minxss_0_ratio_uncertainty_stddev_mean_count_rate, $
    X123_Summed_Counts=minxss_0_Summed_Counts, $
    X123_uncertainty_Summed_Counts = minxss_0_uncertainty_Summed_Counts, $
    X123_Summed_Integration_time_seconds=minxss_0_Summed_Integration_time_seconds)

  signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array = minxss_0_mean_count_rate/minxss_0_uncertainty_X123_mean_count_rate
  ;pad any negative or unknown values with 0's
  index_negative_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array = where(signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array LT 0.0, n_index_negative_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array)
  if n_index_negative_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array gt 0 then signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array[index_negative_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array] = 0.0
  ;get rid of NANs
  index_NAN_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array = where(finite(signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array, /nan) gt 0)
  if n_elements(index_NAN_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array) gt 0 then signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array[index_NAN_signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  x1_position_time_series = 0.05
  x2_position_time_series = 0.45
  y1_position_time_series = 0.20
  y2_position_time_series = 0.88
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   x1_position_spectrum = 0.55
   x1_position_spectrum = 0.55
   x2_position_spectrum = 0.95
   y1_position_spectrum_top = 0.30
   y2_position_spectrum_top = y2_position_time_series
   y1_position_spectrum_bottom = 0.08
   y2_position_spectrum_bottom = y1_position_spectrum_top
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if keyword_set(make_plot) then begin
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;set the text for field 1
    TEXT_delta_x_position = 0.10
    TEXT_delta_y_position = 0.04

    ;field_1
    TEXT_X_Position_timeseries_plot_field_1 = 0.87
    TEXT_Y_Position_timeseries_plot_field_1 = 0.82
    TEXT_color_timeseries_plot_field_1 = 'Black'
    TEXT_name_timeseries_plot_field_1 = 'N$_{spectra}$ = '+strtrim(N_Integrations, 2)

    ;field_2
    TEXT_X_Position_timeseries_plot_field_2 = TEXT_X_Position_timeseries_plot_field_1
    TEXT_Y_Position_timeseries_plot_field_2 = TEXT_Y_Position_timeseries_plot_field_1 - TEXT_delta_y_position
    ;TEXT_color_timeseries_plot_field_2 = 'green yellow'
    TEXT_color_timeseries_plot_field_2 = 'Black'
    TEXT_name_timeseries_plot_field_2 = 't$_{integration}$ = '+strtrim(long(minxss_all_Summed_Integration_time_seconds), 2)+' s'

    ;field_3
    TEXT_X_Position_timeseries_plot_field_3 = TEXT_X_Position_timeseries_plot_field_1
    TEXT_Y_Position_timeseries_plot_field_3 = 0.26
    TEXT_color_timeseries_plot_field_3 = 'Black'
    TEXT_name_timeseries_plot_field_3 = '[CPS/$\sigma_{CPS}]_{N_{SPECTRA}}$'

    ;field_4
    TEXT_X_Position_timeseries_plot_field_4 = TEXT_X_Position_timeseries_plot_field_3
    TEXT_Y_Position_timeseries_plot_field_4 = TEXT_Y_Position_timeseries_plot_field_3 - TEXT_delta_y_position
    TEXT_color_timeseries_plot_field_4 = 'Red'
    TEXT_name_timeseries_plot_field_4 = '[CPS/$\sigma_{CPS}]_{1}\times(N_{SPECTRA})^{0.5}$'

    ;set the window x size
    x_size_window = 1600
    ;set the window y size
    y_size_window = 0.5*x_size_window
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    WINDOW_PLOT_TIME_SERIES = WINDOW(DIMENSIONS = [x_size_window, y_size_window], BACKGROUND_COLOR = 'White')
    WINDOW_PLOT_TIME_SERIES_TITLE = TEXT(0.5, 0.95, ALIGNMENT = 0.5, FONT_SIZE = 18, FONT_STYLE = 'bold', plot_title)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;BACKGROUND=color_index
    PLOT_Time_Series_MinXSS = PLOt(time_jd_array, spectrum_summed_count_rate_array, /NODATA, NAME = 'GOES 15 Flux Plot', MARGIN=[0.18,0.18,0.18,0.18], Title = 'Count Rate', POSITION = [x1_position_time_series, y1_position_time_series, x2_position_time_series, y2_position_time_series], AXIS_STYLE=1, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, YTITLE = 'Count Rate (count s$^{-1}$)', XTITLE = 'Date', $
      XRANGE = [Time_Chossen_Min, Time_Chossen_Max], YRANGE = [Y_Min_Slow_Counts, Y_MAX_Slow_Counts], XTICKUNITS = ['Time', 'Time', 'Year'], XTICKFORMAT=['LABEL_DATE', 'LABEL_DATE', 'LABEL_DATE'], XTICKINTERVAL = XTICKINTERVAL_time_series_use, $
      FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /CURRENT)

    ;chris_moore_credit
    ;TEXT_chris_moore_credit = TEXT(TEXT_X_Position_chris_moore_credit, TEXT_y_Position_chris_moore_credit, ALIGNMENT = 0.5, TEXT_name_chris_moore_credit, COLOR = TEXT_color_chris_moore_credit, FONT_SIZE = 11, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

    PLOT_Time_Series_MinXSS_Y_AXIS_RIGHT = AXIS('Y', LOCATION='right', SHOWTEXT = 0, TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', COLOR = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Y_AXIS_LEFT = AXIS('Y', LOCATION='left', SHOWTEXT = 0, TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold',  color = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 0,  color = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 0, color = 'black', TARGET = PLOT_Time_Series_MinXSS)

    ;goes_
    ;PLOT_normalized_time_series_Coronal_DATA = PLOT(GOES_Coronal.GOES15_Flux_Data_TIMEJD, GOES15_Flux_Data_FLUX_1_TO_8_ANG_normalized_signal, NAME = 'GOES 0.1 - 0.8 nm', COLOR='cyan', LINESTYLE='-', sym_color='cyan', SYMBOL = 'Triangle', THICK=1, SYM_SIZE = 0.25, sym_filled = 0, SYM_THICK = 1, /OVERPLOT)
    ;minxss-2 slow counts
    PLOT_MINXSS_X123_Time_Slow_Counts_Filtered_sci = PLOT(time_jd_array, spectrum_summed_count_rate_array, NAME = 'Count rate', COLOR='black', LINESTYLE='none', sym_color='black', SYMBOL = 'Circle', sym_filled = 0, THICK=1, SYM_SIZE = 1.0, SYM_THICK = 2, /OVERPLOT)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;PLOT_Minxss2_mean_count_rate = PLOT(ssaxi_inverted_photon_counting_integrated_spectrum_v0_sparse_dem_combined_Al_7um_0002cm2_Be_110um_004cm2_Be_1000um_8cm2.energy_bins_kev, PLOT_Minxss2_mean_count_rate_Array, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', Title = 'SSAXI Spectrum '+ ssaxi_date_string + ' ' + ssaxi_time_string + ' UT', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_top, x2_position_spectrum, y2_position_spectrum_top], AXIS_STYLE=2, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, YTITLE = 'Photon Flux (Photons s$^{-1}$ cm$^{-2}$ keV$^{-1}$)', $
    PLOT_Minxss2_mean_count_rate = PLOT(x123_energy_bin_centers_kev, minxss_all_mean_count_rate, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_top, x2_position_spectrum, y2_position_spectrum_top], AXIS_STYLE=4, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, $
      XRANGE = [x123_SPECTRUM_ENERGY_KeV_MIN, x123_SPECTRUM_ENERGY_KeV_MAX], YRANGE = [Y_MIN_X123_RAW_COUNT_RATE_FM2, Y_MAX_X123_RAW_COUNT_RATE_FM2], /ylog, FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /CURRENT)

    PLOT_MinXSS2_count_rate_spectrum_error_DATA = ERRORPLOT((x123_energy_bin_centers_kev + (0.5*MinXSS_GAIN)), minxss_all_mean_count_rate, minxss_all_uncertainty_X123_mean_count_rate, NAME = 'Uncertainty Mean Spectra', COLOR='black', LINESTYLE='none', SYMBOL = 'none', THICK=4, SYM_SIZE = 1.5, SYM_THICK = 3, HISTOGRAM = 0, TRANSPARENCY = 0.0, /OVERPLOT)
    PLOT_MinXSS2_count_rate_spectrum_DATA = PLOT(x123_energy_bin_centers_kev, minxss_all_mean_count_rate, NAME = 'Mean Spectra', COLOR='black', LINESTYLE='-', SYMBOL = 'none', THICK=4, SYM_SIZE = 1.5, SYM_THICK = 3, HISTOGRAM = 1, TRANSPARENCY = 0.0, /OVERPLOT)

    ;place text
    ;field_1
    TEXT_timeseries_plot_field_1 = TEXT(TEXT_X_Position_timeseries_plot_field_1, TEXT_y_Position_timeseries_plot_field_1, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_1, COLOR = TEXT_color_timeseries_plot_field_1, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)
    ;field_2
    TEXT_timeseries_plot_field_2 = TEXT(TEXT_X_Position_timeseries_plot_field_2, TEXT_y_Position_timeseries_plot_field_2, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_2, COLOR = TEXT_color_timeseries_plot_field_2, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

    PLOT_Minxss2_mean_count_rate_DATA_Left_Y_AXIS = AXIS('Y', LOCATION='left', SHOWTEXT = 1, TITLE = 'Count Rate (Counts s$^{-1}$)', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_mean_count_rate)
    PLOT_Minxss2_mean_count_rate_DATA_Right_Y_AXIS = AXIS('Y', LOCATION='right', SHOWTEXT = 0, color = 'black', TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_mean_count_rate)
    PLOT_Minxss2_mean_count_rate_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 1, Title = 'Bin #', COORD_TRANSFORM=[(-1.0*MinXSS_OFFSET)/(MinXSS_GAIN), (1.0/MinXSS_GAIN)], TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', color = 'black', TARGET = PLOT_Minxss2_mean_count_rate)
    ;PLOT_ssaxi1_ssaxi_estimate_level1_60_MINUTE_mission_slow_counts_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 0, color = 'black', TARGET = PLOT_Minxss2_mean_count_rate)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    PLOT_Minxss2_signal_noise_ratio = PLOT(x123_energy_bin_centers_kev, signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_bottom, x2_position_spectrum, y2_position_spectrum_bottom], AXIS_STYLE=4, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, $
      XRANGE = [x123_SPECTRUM_ENERGY_KeV_MIN, x123_SPECTRUM_ENERGY_KeV_MAX], YRANGE = [Y_Min_minxss2_x123_signal_noise_ratio , Y_MAX_minxss2_x123_signal_noise_ratio], FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /ylog, /CURRENT)

    PLOT_Minxss2_signal_noise_ratio_root_n_scaled_DATA = PLOT((x123_energy_bin_centers_kev + MinXSS_GAIN), (sqrt(double(N_Integrations))*signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array), NAME = 'Mean Signal-to-Noise Scaled Root N', COLOR='red', LINESTYLE='-', SYMBOL = 'none', THICK=3, SYM_FILLED = 0, SYM_FILL_color = 'black', SYM_SIZE = 1.5, SYM_THICK = 2, HISTOGRAM = 0, TRANSPARENCY = 0.0, /OVERPLOT)
    PLOT_Minxss2_signal_noise_ratio_DATA = PLOT((x123_energy_bin_centers_kev + (0.5*MinXSS_GAIN)), signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array, NAME = 'Mean Signal-to-Noise', COLOR='black', LINESTYLE='-', SYMBOL = 'none', THICK=4, SYM_FILLED = 0, SYM_FILL_color = 'black', SYM_SIZE = 1.5, SYM_THICK = 2, HISTOGRAM = 1, TRANSPARENCY = 0.0, /OVERPLOT)

    ;field_3
    TEXT_timeseries_plot_field_3 = TEXT(TEXT_X_Position_timeseries_plot_field_3, TEXT_y_Position_timeseries_plot_field_3, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_3, COLOR = TEXT_color_timeseries_plot_field_3, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)
    ;field_4
    TEXT_timeseries_plot_field_4 = TEXT(TEXT_X_Position_timeseries_plot_field_4, TEXT_y_Position_timeseries_plot_field_4, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_4, COLOR = TEXT_color_timeseries_plot_field_4, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

    PLOT_Minxss2_signal_noise_ratio_DATA_Left_Y_AXIS = AXIS('Y', LOCATION='left', SHOWTEXT = 1, TITLE = 'Signal-to-Noise', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
    PLOT_Minxss2_signal_noise_ratio_DATA_Right_Y_AXIS = AXIS('Y', LOCATION='right', SHOWTEXT = 0, color = 'black', TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
    PLOT_Minxss2_signal_noise_ratio_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 0,  color = 'black', TARGET = PLOT_Minxss2_signal_noise_ratio)
    PLOT_Minxss2_signal_noise_ratio_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 1, TITLE = 'Energy (keV)', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if keyword_set(make_video) then begin
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;set the directory to place the video
    if keyword_set(file_directory_video) then begin
      file_directory_video_use = file_directory_video
    endif else begin
      file_directory_video_use = getenv('HOME')
    endelse

    ;set the file name of the video
    if keyword_set(filename_video) then begin
      filename_video_use = filename_video
    endif else begin
    filename_video_use = 'signal_to_noise_video' 
    endelse
  
    ;video frames per second
    if keyword_set(video_fps) then begin
      video_fps_use = video_fps
    endif else begin
      video_fps_use = 5
    endelse

  ;set the video file type
  if keyword_set(video_file_type) then begin
    video_file_type_use = video_file_type
  endif else begin
    video_file_type_use = '.mp4'
    ;  video_file_type_use = '.avi'
    ;  video_file_type_use = '.webm'
  endelse

    nframes = N_Integrations
    ;set the window x size
    x_size_window = 1600
    ;set the window y size
    y_size_window = 0.5*x_size_window
    ;set the frames per second
    output_video_filename = file_directory_video_use+filename_video_use+'_'+strtrim(video_fps_use,2)+'fps'+video_file_type_use
    if keyword_set(verbose) then print, 'filename = ', output_video_filename

    v = idlffvideowrite(output_video_filename)
    vs = v.addvideostream(x_size_window, y_size_window, video_fps_use)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;make a vertical line to indicate the observation
    n_vertical_line_Minxss_time_loop = 10.0
    max_vertical_line_Minxss_time_loop = 1.0e12
    min_vertical_line_Minxss_time_loop = 1.0E-2
    delta_vertical_line_Minxss_time_loop = (max_vertical_line_Minxss_time_loop - min_vertical_line_Minxss_time_loop)/n_vertical_line_Minxss_time_loop
    Y_vertical_line_Minxss_time_loop_array = (delta_vertical_line_Minxss_time_loop*dindgen(n_vertical_line_Minxss_time_loop)) + min_vertical_line_Minxss_time_loop
    Y_vertical_line_Minxss_time_loop_array = (10.0)^(-1.0*alog10(Y_vertical_line_Minxss_time_loop_array))
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    WINDOW_PLOT_TIME_SERIES = WINDOW(DIMENSIONS = [x_size_window, y_size_window], BACKGROUND_COLOR = 'White', /buffer)
    ;start the loop
    for u = 0, N_Integrations - 1 do begin
;    for u = 0, 10 - 1 do begin ; use for debugging

      ;Print the loop number
      if keyword_set(verbose) then print, 'loop number = ', u, ' / ', strtrim((N_Integrations-1), 2)

      ;Erase the windoe after each loop
      WINDOW_PLOT_TIME_SERIES.erase
      WINDOW_PLOT_TIME_SERIES_TITLE = TEXT(0.5, 0.93, ALIGNMENT = 0.5, COLOR = 'black', FONT_SIZE = 18, FONT_STYLE = 'bold', plot_title)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      index_Minxss_time_loop = u
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      X_vertical_line_Minxss_time_loop_array = dblarr(n_vertical_line_Minxss_time_loop)
      X_vertical_line_Minxss_time_loop_array[*] = time_jd_array[index_Minxss_time_loop]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;BACKGROUND=color_index
    PLOT_Time_Series_MinXSS = PLOt(time_jd_array, spectrum_summed_count_rate_array, /NODATA, NAME = 'GOES 15 Flux Plot', MARGIN=[0.18,0.18,0.18,0.18], Title = 'Count Rate', POSITION = [x1_position_time_series, y1_position_time_series, x2_position_time_series, y2_position_time_series], AXIS_STYLE=1, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, YTITLE = 'Count Rate (count s$^{-1}$)', XTITLE = 'Date', $
      XRANGE = [Time_Chossen_Min, Time_Chossen_Max], YRANGE = [Y_Min_Slow_Counts, Y_MAX_Slow_Counts], XTICKUNITS = ['Time', 'Time', 'Year'], XTICKFORMAT=['LABEL_DATE', 'LABEL_DATE', 'LABEL_DATE'], XTICKINTERVAL = XTICKINTERVAL_time_series_use, $
      FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /CURRENT)

    ;chris_moore_credit
    ;TEXT_chris_moore_credit = TEXT(TEXT_X_Position_chris_moore_credit, TEXT_y_Position_chris_moore_credit, ALIGNMENT = 0.5, TEXT_name_chris_moore_credit, COLOR = TEXT_color_chris_moore_credit, FONT_SIZE = 11, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

    PLOT_Time_Series_MinXSS_Y_AXIS_RIGHT = AXIS('Y', LOCATION='right', SHOWTEXT = 0, TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', COLOR = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Y_AXIS_LEFT = AXIS('Y', LOCATION='left', SHOWTEXT = 0, TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold',  color = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 0,  color = 'black', TARGET = PLOT_Time_Series_MinXSS)
    PLOT_Time_Series_MinXSS_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 0, color = 'black', TARGET = PLOT_Time_Series_MinXSS)

    PLOT_vertical_line_Minxss_time_loop_array = PLOT(X_vertical_line_Minxss_time_loop_array, Y_vertical_line_Minxss_time_loop_array, NAME = 'Vertical Line', COLOR='Black', LINESTYLE='-', sym_color='Black', SYMBOL = 'none', THICK=3, SYM_SIZE = 1, sym_filled = 0, SYM_THICK = 0.5, /OVERPLOT)

    ;goes_
    ;PLOT_normalized_time_series_Coronal_DATA = PLOT(GOES_Coronal.GOES15_Flux_Data_TIMEJD, GOES15_Flux_Data_FLUX_1_TO_8_ANG_normalized_signal, NAME = 'GOES 0.1 - 0.8 nm', COLOR='cyan', LINESTYLE='-', sym_color='cyan', SYMBOL = 'Triangle', THICK=1, SYM_SIZE = 0.25, sym_filled = 0, SYM_THICK = 1, /OVERPLOT)
    ;minxss slow counts
    PLOT_MINXSS_X123_Time_Slow_Counts_Filtered_sci = PLOT(time_jd_array, spectrum_summed_count_rate_array, NAME = 'Count rate', COLOR='black', LINESTYLE='none', sym_color='black', SYMBOL = 'Circle', sym_filled = 0, THICK=1, SYM_SIZE = 1.0, SYM_THICK = 2, /OVERPLOT)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;Calculate the signal-to-noise forr the first data set for sc0ing to the integrations for 0 the data sets.
      minxss_loop_uncertainty_X123_mean_count_rate = minxss_x123_uncertainty_mean_count_rate(x123_measured_count_array[*,0:index_Minxss_time_loop], x123_energy_bin_centers_kev=x123_energy_bin_centers_kev, integration_time_array=(integration_time_seconds_array[0:index_Minxss_time_loop]/CONVERT_ms_to_s), uncertainty_integration_time=uncertatinty_integration_time, uncertainty_fov=uncertainty_fov, use_bin_width=use_bin_width, use_detector_area=use_detector_area, $
      x123_mean_count_rate = minxss_loop_mean_count_rate, $
      uncertainty_x123_measured_count_array=minxss_loop_uncertainty_x123_measured_count_array, $
      x123_count_rate = minxss_loop_count_rate, $
      uncertainty_x123_measured_count_rate_array=minxss_loop_uncertainty_x123_measured_count_rate_array, $
      uncertainty_stddev_x123_mean_count_rate=minxss_loop_uncertainty_stddev_mean_count_rate, $
      ratio_uncertainty_stddev_x123_mean_count_rate = minxss_loop_ratio_uncertainty_stddev_mean_count_rate, $
      X123_Summed_Counts=minxss_loop_Summed_Counts, $
      X123_uncertainty_Summed_Counts = minxss_loop_uncertainty_Summed_Counts, $
      X123_Summed_Integration_time_seconds=minxss_loop_Summed_Integration_time_seconds)

      signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array = minxss_loop_mean_count_rate/minxss_loop_uncertainty_X123_mean_count_rate
      ;pad any negative or unknown values with 0's
      index_negative_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array = where(signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array LT 0.0, n_index_negative_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array)
      if n_index_negative_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array gt 0 then signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array[index_negative_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array] = 0.0
      ;get rid of NANs
      index_NAN_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array = where(finite(signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array, /nan) gt 0)
      if n_elements(index_NAN_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array) gt 0 then signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array[index_NAN_signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array] = 0.0
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;set the text for field 1
      TEXT_delta_x_position = 0.10
      TEXT_delta_y_position = 0.04

      ;field_1
      TEXT_X_Position_timeseries_plot_field_1 = 0.87
      TEXT_Y_Position_timeseries_plot_field_1 = 0.82
      TEXT_color_timeseries_plot_field_1 = 'Black'
      TEXT_name_timeseries_plot_field_1 = 'N$_{spectra}$ = '+strtrim(index_Minxss_time_loop+1, 2)

      ;field_2
      TEXT_X_Position_timeseries_plot_field_2 = TEXT_X_Position_timeseries_plot_field_1
      TEXT_Y_Position_timeseries_plot_field_2 = TEXT_Y_Position_timeseries_plot_field_1 - TEXT_delta_y_position
      ;TEXT_color_timeseries_plot_field_2 = 'green yellow'
      TEXT_color_timeseries_plot_field_2 = 'Black'
      TEXT_name_timeseries_plot_field_2 = 't$_{integration}$ = '+strtrim(long(minxss_loop_Summed_Integration_time_seconds+1.0), 2)+' s'

      ;field_3
      TEXT_X_Position_timeseries_plot_field_3 = TEXT_X_Position_timeseries_plot_field_1
      TEXT_Y_Position_timeseries_plot_field_3 = 0.26
      TEXT_color_timeseries_plot_field_3 = 'Black'
      TEXT_name_timeseries_plot_field_3 = '[CPS/$\sigma_{CPS}]_{N_{SPECTRA}}$'

      ;field_4
      TEXT_X_Position_timeseries_plot_field_4 = TEXT_X_Position_timeseries_plot_field_3
      TEXT_Y_Position_timeseries_plot_field_4 = TEXT_Y_Position_timeseries_plot_field_3 - TEXT_delta_y_position
      TEXT_color_timeseries_plot_field_4 = 'Red'
      TEXT_name_timeseries_plot_field_4 = '[CPS/$\sigma_{CPS}]_{1}\times(N_{SPECTRA})^{0.5}$'
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;PLOT_Minxss2_mean_count_rate = PLOT(ssaxi_inverted_photon_counting_integrated_spectrum_v0_sparse_dem_combined_Al_7um_0002cm2_Be_110um_004cm2_Be_1000um_8cm2.energy_bins_kev, PLOT_Minxss2_mean_count_rate_Array, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', Title = 'SSAXI Spectrum '+ ssaxi_date_string + ' ' + ssaxi_time_string + ' UT', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_top, x2_position_spectrum, y2_position_spectrum_top], AXIS_STYLE=2, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, YTITLE = 'Photon Flux (Photons s$^{-1}$ cm$^{-2}$ keV$^{-1}$)', $
      PLOT_Minxss2_mean_count_rate = PLOT(x123_energy_bin_centers_kev, minxss_all_mean_count_rate, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_top, x2_position_spectrum, y2_position_spectrum_top], AXIS_STYLE=4, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, $
        XRANGE = [x123_SPECTRUM_ENERGY_KeV_MIN, x123_SPECTRUM_ENERGY_KeV_MAX], YRANGE = [Y_MIN_X123_RAW_COUNT_RATE_FM2, Y_MAX_X123_RAW_COUNT_RATE_FM2], /ylog, FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /CURRENT)

      PLOT_MinXSS2_count_rate_spectrum_error_DATA = ERRORPLOT((x123_energy_bin_centers_kev + (0.5*MinXSS_GAIN)), minxss_loop_mean_count_rate, minxss_loop_uncertainty_X123_mean_count_rate, NAME = 'Uncertainty Mean Spectra', COLOR='black', LINESTYLE='none', SYMBOL = 'none', THICK=4, SYM_SIZE = 1.5, SYM_THICK = 3, HISTOGRAM = 0, TRANSPARENCY = 0.0, /OVERPLOT)
      PLOT_MinXSS2_count_rate_spectrum_DATA = PLOT(x123_energy_bin_centers_kev, minxss_loop_mean_count_rate, NAME = 'Mean Spectra', COLOR='black', LINESTYLE='-', SYMBOL = 'none', THICK=4, SYM_SIZE = 1.5, SYM_THICK = 3, HISTOGRAM = 1, TRANSPARENCY = 0.0, /OVERPLOT)

      ;place text
      ;field_1
      TEXT_timeseries_plot_field_1 = TEXT(TEXT_X_Position_timeseries_plot_field_1, TEXT_y_Position_timeseries_plot_field_1, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_1, COLOR = TEXT_color_timeseries_plot_field_1, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)
      ;field_2
      TEXT_timeseries_plot_field_2 = TEXT(TEXT_X_Position_timeseries_plot_field_2, TEXT_y_Position_timeseries_plot_field_2, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_2, COLOR = TEXT_color_timeseries_plot_field_2, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

      PLOT_Minxss2_mean_count_rate_DATA_Left_Y_AXIS = AXIS('Y', LOCATION='left', SHOWTEXT = 1, TITLE = 'Count Rate (Counts s$^{-1}$)', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_mean_count_rate)
      PLOT_Minxss2_mean_count_rate_DATA_Right_Y_AXIS = AXIS('Y', LOCATION='right', SHOWTEXT = 0, color = 'black', TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_mean_count_rate)
      PLOT_Minxss2_mean_count_rate_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 1, Title = 'Bin #', COORD_TRANSFORM=[(-1.0*MinXSS_OFFSET)/(MinXSS_GAIN), (1.0/MinXSS_GAIN)], TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', color = 'black', TARGET = PLOT_Minxss2_mean_count_rate)
      ;PLOT_ssaxi1_ssaxi_estimate_level1_60_MINUTE_mission_slow_counts_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 0, color = 'black', TARGET = PLOT_Minxss2_mean_count_rate)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      PLOT_Minxss2_signal_noise_ratio = PLOT(x123_energy_bin_centers_kev, signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array, /NODATA, NAME = 'CHOSSEN_DATA Spactra - Photon Flux', MARGIN=[0.18,0.18,0.18,0.18], POSITION = [x1_position_spectrum, y1_position_spectrum_bottom, x2_position_spectrum, y2_position_spectrum_bottom], AXIS_STYLE=4, SYMBOL='Square', SYM_COLOR='black', COLOR='black', LINESTYLE='None', THICK=2, SYM_SIZE = 1.5, SYM_THICK = 2, $
        XRANGE = [x123_SPECTRUM_ENERGY_KeV_MIN, x123_SPECTRUM_ENERGY_KeV_MAX], YRANGE = [Y_Min_minxss2_x123_signal_noise_ratio , Y_MAX_minxss2_x123_signal_noise_ratio], FONT_SIZE = 14, FONT_STYLE = 'bold', FONT_COLOR = 'black', /ylog, /CURRENT)

      PLOT_Minxss2_signal_noise_ratio_root_n_scaled_DATA = PLOT((x123_energy_bin_centers_kev + MinXSS_GAIN), (sqrt(double(index_Minxss_time_loop+1))*signal_noise_ratio_minxss_0_uncertainty_mean_count_rate_array), NAME = 'Mean Signal-to-Noise Scaled Root N', COLOR='red', LINESTYLE='-', SYMBOL = 'none', THICK=3, SYM_FILLED = 0, SYM_FILL_color = 'black', SYM_SIZE = 1.5, SYM_THICK = 2, HISTOGRAM = 0, TRANSPARENCY = 0.0, /OVERPLOT)
      PLOT_Minxss2_signal_noise_ratio_DATA = PLOT((x123_energy_bin_centers_kev + (0.5*MinXSS_GAIN)), signal_noise_ratio_minxss_loop_uncertainty_mean_count_rate_array, NAME = 'Mean Signal-to-Noise', COLOR='black', LINESTYLE='-', SYMBOL = 'none', THICK=4, SYM_FILLED = 0, SYM_FILL_color = 'black', SYM_SIZE = 1.5, SYM_THICK = 2, HISTOGRAM = 1, TRANSPARENCY = 0.0, /OVERPLOT)

      ;field_3
      TEXT_timeseries_plot_field_3 = TEXT(TEXT_X_Position_timeseries_plot_field_3, TEXT_y_Position_timeseries_plot_field_3, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_3, COLOR = TEXT_color_timeseries_plot_field_3, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)
      ;field_4
      TEXT_timeseries_plot_field_4 = TEXT(TEXT_X_Position_timeseries_plot_field_4, TEXT_y_Position_timeseries_plot_field_4, ALIGNMENT = 0.5, TEXT_name_timeseries_plot_field_4, COLOR = TEXT_color_timeseries_plot_field_4, FONT_SIZE = 16, FONT_STYLE = 'Bold', /NORMAL, Target = WINDOW_PLOT_TIME_SERIES)

      PLOT_Minxss2_signal_noise_ratio_DATA_Left_Y_AXIS = AXIS('Y', LOCATION='left', SHOWTEXT = 1, TITLE = 'Signal-to-Noise', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
      PLOT_Minxss2_signal_noise_ratio_DATA_Right_Y_AXIS = AXIS('Y', LOCATION='right', SHOWTEXT = 0, color = 'black', TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
      PLOT_Minxss2_signal_noise_ratio_Top_X_AXIS = AXIS('X', LOCATION='top', SHOWTEXT = 0,  color = 'black', TARGET = PLOT_Minxss2_signal_noise_ratio)
      PLOT_Minxss2_signal_noise_ratio_Bottom_X_AXIS = AXIS('X', LOCATION='bottom', SHOWTEXT = 1, TITLE = 'Energy (keV)', color = 'black', TICKFONT_SIZE = 14, TICKFONT_STYLE = 'Bold', TARGET = PLOT_Minxss2_signal_noise_ratio)
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;    wait, video_wait_time_display_seconds
      !null = v.put(vs, WINDOW_PLOT_TIME_SERIES.copywindow()) & $
      endfor

    obj_destroy, v
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;return the signal to noise
  return, signal_noise_ratio_minxss_all_uncertainty_mean_count_rate_array


end