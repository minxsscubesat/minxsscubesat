;+
; NAME:
;   daxss_apply_arf.pro
;
; PURPOSE:
;   Apply the Effective Area (cm^2) to the corrected count spectrum to have irradiance units
;	of photons/sec/cm^2/keV
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   daxss_apply_arf, energy_input, spectrum_input, $
;				fm=fm, accuracy=accuracy, valid_flags=valid_flags, $
;				verbose=verbose, debug=debug
;
; INPUTS:
;   Energy_Input		Energy of the bins (float array 1024)
;	Spectrum_Input		Spectrum of corrected counts per sec (cps) (float array 1024)
;
; OPTIONAL INPUTS:
;   FM					Flight Model number (defaults to 3 for DAXSS)
;
; KEYWORD PARAMETERS:
;   VERBOSE:             Set this to print processing messages
;   DEBUG:               Set this to trigger breakpoints for debugging
;
; OUTPUTS:
;   Returns the irradiance spectrum with ARF applied
;
; OPTIONAL OUTPUTS:
;   ACCURACY			Relative accuracy for ARF calibration (does not include precision)
;	VALID_FLAGS			Array of flags (0=bad, 1=good) if irradiance values are valid (float array 1024)
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Used for daxss_make_level1new.pro
;
; PROCEDURE:
;   1. Check inputs and read ARF file if needed
;	2. Zero out bins not useful for DAXSS spectra (< 0.3 keV and > 13 keV)
;   3. Convert corrected count spectrum into irradiance units
;   4. Configure the other two outputs: accuracy and valid_flags
;   5. Return irradiance spectrum
;
; HISTORY:
;	6/27/2022	T. Woods, daxss_apply_arf.pro developed for daxss_make_level1new.pro
;
;+
function daxss_apply_arf, energy_input, spectrum_input, fm=fm, $
						accuracy=accuracy, valid_flags=valid_flags, verbose=verbose, debug=debug

	if (n_params() lt 2) then stop, 'daxss_apply_arf: ERROR for not having any parameters!!!'

	;
	;   1. Check inputs and read ARF file if needed
	;
	; Defaults
	if keyword_set(debug) then verbose=1

	; Default Flight Model (FM) for DAXSS is FM3 (was FM4, changed 5/24/2022, TW)
	if not keyword_set(fm) then fm=3
	;  limit check for FM for DAXSS
	if (fm lt 3) then fm=3
	if (fm gt 3) then fm=3
	fm_str = strtrim(fm,2)

	;  If not created yet, make the arf_rebin for the Energy_Input array
	;  This is done once as it is static matrix for data processing.
	COMMON daxss_response_common, rmf, rmf_energy, rmf_matrix, arf, arf_energy, arf_rebin
	ddir = getenv('minxss_data')
	cal_dir = ddir + path_sep() + 'calibration' + path_sep()
	cal_file_arf = 'minxss_fm'+fm_str+'_ARF.fits'  ; arf.specresp
	if (n_elements(arf) lt 1) then arf=eve_read_whole_fits(cal_dir+cal_file_arf)
	if (n_elements(arf_rebin) le 1) then begin
		; interpolate ARF for the energy_input bins
		arf_energy = energy_input
		arf_specresp_energy = reform((arf.specresp.energ_lo + arf.specresp.energ_hi)/2.)
		arf_rebin = interpol( reform(arf.specresp.specresp), arf_specresp_energy, energy_input) > 0
		if keyword_set(DEBUG) then stop, 'STOPPED: CHECK OUT ARF and ARF_REBIN'
	endif

	;
	;	2. Zero out bins not useful for DAXSS spectra (< 0.3 keV and > 13 keV)
	;
	spectrum_output = fltarr(n_elements(spectrum_input))
	valid_flags = fltarr(n_elements(spectrum_input))
	accuracy = fltarr(n_elements(spectrum_input)) + 1.0

	wzero = where( energy_input lt 0.3 OR energy_input gt 13. OR arf_rebin eq 0.0, num_zero )
	if (num_zero gt 0) then begin
		spectrum_output[wzero] = 0.0
		valid_flags[wzero] = 0
		accuracy[wzero] = 1.0
	endif

	;
	;   3. Convert corrected count spectrum into irradiance units (photons/sec/cm^2/keV)
	;   4. Configure the other two outputs: accuracy and valid_flags
	;
	wgood = where( energy_input ge 0.3 AND energy_input le 13. AND arf_rebin gt 0.0, num_good )
	if (num_good gt 0) then begin
		energy_bin = abs(energy_input[2] - energy_input[1])
		spectrum_output[wgood] = spectrum_input[wgood] / arf_rebin[wgood] / energy_bin
		valid_flags[wgood] = 1
		accuracy[wgood] = 0.1		; 10% pre-flight calibration accuracy (really should have pre-flight precision too)
	endif

	if keyword_set(DEBUG) then stop, 'daxss_apply_arf: STOPPED at end to debug ...'

;   5. Return irradiance spectrum
return, spectrum_output
end
