;
; minxss_x123_irradiance_wrapper_cm.pro
;
; This is wrapper code for Chris Moore's conversion of X123 raw spectrum to irradiance
;
; INPUTS
;   raw_count_sp  Expected to be X123 counts per second with 1024 bins
;
; OUTPUTS
;   irradiance_sp Irradiance in units of photons/cm^2/sec/keV
;   energy_bins   Bins in units of keV for the 1024 spectral elements
;
; HISTORY
; 2016-06-23  T. Woods  Original Code
; 2017-06-20  Chris Moore added the MinXSS calibration file energy bins, energy gain and offset (the true offset should be fit for every observation)
;
pro minxss_x123_irradiance_wrapper, raw_count_sp, uncertainty_raw_count_sp, irradiance_sp, result=result, fm=fm, directory_calibration_file=directory_calibration_file, debug=debug

  if n_params() lt 2 then begin
    print, 'USAGE:  x123_irradiance_wrapper, raw_count_sp, uncertainty_raw_count_sp, irradiance_sp, fm=fm, full_result=full_result'
    return
  endif

  if not keyword_set(fm) then fm=1
  if (fm lt 1) then fm=1
  if (fm gt 3) then fm=3


;
; Update energy bins and offset with information in calibration data
; T. Woods  2016-Oct-11
; Chris Moore 6017-06-20 - updated to use the latest energy offset

;  add path for the calibration file
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
  x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
  energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
endif else if fm eq 2 then begin
  minxss_calibration_file = 'minxss_fm2_response_structure.sav'
  minxss_calibration_file_path = cal_dir + minxss_calibration_file
  restore, minxss_calibration_file_path
  ; FM-2 values  -  T. Woods 12/2021  based on Moore's calibration paper
  x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
  energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
endif else if fm eq 3 then begin
  minxss_calibration_file = 'minxss_fm3_response_structure.sav'
  minxss_calibration_file_path = cal_dir + minxss_calibration_file
  restore, minxss_calibration_file_path
  ; FM-3 values - T. Woods 3/2022   based on Schwab+Sewell DAXSS calibration paper
  x123_energy_bins_kev = findgen(1024) * minxss_detector_response.x123_energy_gain_kev_per_bin
  energy_bins_offset = minxss_detector_response.x123_energy_offset_kev_orbit
endif else begin
	message,/INFO, 'ERROR with FM number not being 1, 2, or 4.'
	stop, 'DEBUG ...'
endelse

   ;  save energy bins for the return
  ebins = x123_energy_bins_kev + energy_bins_offset

;use a nominal 0.0 energy bin offset
energy_bins_offset_zero = 0.0

  ;
  ; Call Chris Moore's irradiance converter - returns 3 irradiance options
  ;   1)  Be filter calibration
  ;   2)  Be filter calibration + Si correction
  ;   3)  Be filter calibration + Photoelectrons
  ;
  irradiance_1 = minxss_x123_invert_count_to_photon_estimate( ebins, $
    energy_bins_offset_zero, raw_count_sp, counts_uncertainty=uncertainty_raw_count_sp,  /use_detector_area, $
    minxss_instrument_structure_data_file=minxss_calibration_file_path, $
    X123_photon_estimate_be_si_photopeak_only_ARRAY= irradiance_2, $
    X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY= irradiance_3, $
    uncertainty_X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=uncertainty_irradiance_3, $
    X123_inverted_count_to_photon_estimate_valid_flag_ARRAY= valid_flag )
  ;   doesn't work yet
  ;   X123_inverted_valid_flag_fractional_difference_level= valid_difference )

  ;  best spectrum to use is irradiance_3
  ;   irradiance_1 is Be filter calibration corrected for Si and photoelectrons (low)
  ;   irradiance_2 is Be filter calibration (high)
  ;   irradiance_3 is Be filter calibration corrected for photoelectrons (middle of range)
  irradiance_sp = transpose([ [ebins], [irradiance_3] ])

  result = { energy_bins: ebins, counts: raw_count_sp, irradiance_low: irradiance_1, $
    irradiance_high: irradiance_2, irradiance: irradiance_3, irradiance_uncertainty: uncertainty_irradiance_3, $
    valid_flag: valid_flag }


  if keyword_set(debug) then stop, 'DEBUG at end of x123_irradiance_wrapper...'
  return
end
