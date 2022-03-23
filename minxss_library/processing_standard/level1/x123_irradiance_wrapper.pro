;
;	x123_irradiance_wrapper.pro
;
;	This is wrapper code for Chris Moore's conversion of X123 raw spectrum to irradiance
;
;	INPUTS
;		raw_count_sp	Expected to be X123 counts per second with 1024 bins
;
;	OUTPUTS
;		irradiance_sp	Irradiance in units of photons/cm^2/sec/keV
;		energy_bins		Bins in units of keV for the 1024 spectral elements
;
;	HISTORY
;	2016-06-23	T. Woods  Original Code
;
pro x123_irradiance_wrapper, raw_count_sp, irradiance_sp, result=result, fm=fm, debug=debug

if n_params() lt 2 then begin
	print, 'USAGE:  x123_irradiance_wrapper, raw_count_sp, irradiance_sp, fm=fm, full_result=full_result'
	return
endif

if not keyword_set(fm) then fm=1
if (fm lt 1) then fm=1
if (fm gt 4) then fm=4

if fm eq 1 then begin
	; FM-1 values
	x123_energy_bins_kev = findgen(1024) * 0.02930
	energy_bins_offset = -0.13
	minxss_calibration_file = 'minxss_fm1_response_structure.sav'
endif else begin
	; FM-2 values  To-Do  (NOT DEFINED YET !!!!)
	x123_energy_bins_kev = findgen(1024) * 0.02930
	energy_bins_offset = -0.13
	minxss_calibration_file = 'minxss_fm2_response_structure.sav'
endelse

;  add path for the calibration file
cal_dir = getenv('minxss_data')+'/calibration/'
minxss_calibration_file = cal_dir + minxss_calibration_file
;  save energy bins for the return
ebins = x123_energy_bins_kev + energy_bins_offset

;
;	Call Chris Moore's irradiance converter - returns 3 irradiance options
;		1)  Be filter calibration
;		2)  Be filter calibration + Si correction
;		3)  Be filter calibration + Photoelectrons
;
irradiance_1 = X123_invert_count_to_photon_estimate( x123_energy_bins_kev, $
				energy_bins_offset, raw_count_sp, /use_detector_area, $
				minxss_instrument_structure_data_file=minxss_calibration_file, $
				X123_photon_estimate_be_si_photopeak_only_ARRAY= irradiance_2, $
				X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY= irradiance_3, $
				X123_inverted_count_to_photon_estimate_valid_flag_ARRAY= valid_flag )
				;   doesn't work yet
				;  	X123_inverted_valid_flag_fractional_difference_level= valid_difference )

;  best spectrum to use is irradiance_3
;		irradiance_1 is Be filter calibration corrected for Si and photoelectrons (low)
;		irradiance_2 is Be filter calibration (high)
;		irradiance_3 is Be filter calibration corrected for photoelectrons (middle of range)
irradiance_sp = transpose([ [ebins], [irradiance_3] ])

result = { energy_bins: ebins, counts: raw_count_sp, irradiance_low: irradiance_1, $
		irradiance_high: irradiance_2, irradiance: irradiance_3, $
		valid_flag: valid_flag }

if keyword_set(debug) then stop, 'DEBUG at end of x123_irradiance_wrapper...'
return
end
