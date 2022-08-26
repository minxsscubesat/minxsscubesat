;+
; NAME:
;   daxss_subtract_background.pro
;
; PURPOSE:
;   Subtract DAXSS background using 13-20 keV linear trend with energy
;
;   This is for daxss_make_leve11new.pro
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   spectrum_corrected = daxss_subtract_background( energy_input, spectrum_input )
;
; INPUTS:
;   Spectrum_Input		Input spectrum
;
; OPTIONAL INPUTS:
;	None
;
; KEYWORD PARAMETERS:
;   /VERBOSE			Print processing messages
;
; OUTPUTS:
;   Returns spectrum corrected for background signal
;
; OPTIONAL OUTPUTS:
;   fit_background	Data structure of the background fit values
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   None
;
; PROCEDURE:
;   1. Fit linear trend for signal between 13 and 20 keV (above bin 652)
;   2. Subtract trend and return the corrected spectrum
;
; HISTORY:
;	6/27/2022	T. Woods, daxss_subtract_background.pro created for daxss_make_level1new.pro
;
;+
function daxss_subtract_background, spectrum_input, fit_background=fit_background, verbose=verbose

	if (n_params() lt 1) then $
		stop, 'daxss_subtract_background: ERROR for not having any parameters!!!'
	if (n_elements(spectrum_input) ne 1024) then $
		stop, 'daxss_subtract_background: ERROR for spectrum_input not being 1024 elements!!!'

	whi = indgen(371) + 652
	bins = findgen(1024)
	fit_background = { background_mean: 0.0, background_median: 0.0, fit_coeff: fltarr(2) }

	; background fit for 12-20 keV (above bin 602)
	coeff = poly_fit( bins[whi], spectrum_input[whi], 1)
	background_trend = (coeff[0] + bins*coeff[1]) > 0.0
	fit_background.fit_coeff = reform(coeff)
	fit_background.background_mean = mean(spectrum_input[whi])
	fit_background.background_median = median(spectrum_input[whi])

	; subtract the background (assumed to be energetic particles)
	spectrum_output = (spectrum_input - background_trend) > 0.

return, spectrum_output
end
