;+
; NAME:
;   daxss_apply_rmf.pro
;
; PURPOSE:
;   Apply the Redistribution Matrix File (RMF) to redistribute photons to correct bins
;
;   This decreases counts in a bin from higher-energy photon redistribution effects (e.g. Si K escape).
;	This also increases counts in a bin from lower-energy photon events that were redistributed.
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   daxss_apply_rmf, energy_input, spectrum_input, verbose=verbose, debug=debug
;
; INPUTS:
;   Energy_Input		Energy of the bins (float array 1024)
;	Spectrum_Input		Spectrum of corrected counts per sec (cps) (float array 1024)
;
; OPTIONAL INPUTS:
;   fm [integer]		Flight Model number - default is 3 for DAXSS
;
; KEYWORD PARAMETERS:
;   VERBOSE:             Set this to print processing messages
;   DEBUG:               Set this to trigger breakpoints for debugging
;
; OUTPUTS:
;   Returns the spectrum with RMF applied
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Used for daxss_make_level1new.pro
;
; PROCEDURE:
;   1. Check inputs and read RMF file if needed
;	2. Zero out bins not useful for DAXSS spectra (< 0.3 keV)
;   3. Reduce counts from higher-energy photons
;   4. Increase counts from lower-energy photons
;   5. Return updated spectrum
;
; HISTORY:
;	6/27/2022	T. Woods, daxss_apply_rmf.pro developed for daxss_make_level1new.pro
;
;+
function daxss_apply_rmf, energy_input, spectrum_input, fm=fm, verbose=verbose, debug=debug

	if (n_params() lt 2) then stop, 'daxss_apply_rmf: ERROR for not having any parameters!!!'

	;
	;   1. Check inputs and read RMF file if needed
	;
	; Defaults
	if keyword_set(debug) then verbose=1

	; Default Flight Model (FM) for DAXSS is FM3 (was FM4, changed 5/24/2022, TW)
	if not keyword_set(fm) then fm=3
	;  limit check for FM for DAXSS
	if (fm lt 3) then fm=3
	if (fm gt 3) then fm=3
	fm_str = strtrim(fm,2)

	;  If not created yet, make the square RMF_MATRIX
	;  This is done once as it is static matrix for data processing.
	COMMON daxss_response_common, rmf, rmf_energy, rmf_matrix, arf, arf_energy, arf_rebin
	ddir = getenv('minxss_data')
	cal_dir = ddir + path_sep() + 'calibration' + path_sep()
	cal_file_rmf = 'minxss_fm'+fm_str+'_RMF.fits'  ; rmf.maxtrix, rmf.ebounds
	if (n_elements(rmf) lt 1) then rmf=eve_read_whole_fits(cal_dir+cal_file_rmf)
	if (n_elements(rmf_matrix) le 1) then begin
		; rebin for square matrix
		num_energy = n_elements(rmf.ebounds)
		e_low = rmf.ebounds.e_min
		e_hi  = rmf.ebounds.e_max
		rmf_energy = (e_low + e_hi)/2.
		; rmf_matrix[ii,*] is vertical information for reducing counts in a bin (from higher-energy photon)
		; rmf_matrix[*,ii] is horizontal information for increasing counts in a bin (multiplication)
		rmf_matrix = fltarr( num_energy, num_energy )
		for ii=0,num_energy-1 do begin
			ww = where(rmf.matrix.energ_lo ge e_low[ii] and rmf.matrix.energ_hi le e_hi[ii], num_ww)
			temp2 = rmf.matrix[ww].matrix  ; 2-D array
			if (num_ww gt 1) then temp1 = total(temp2,2) else temp1 = reform(temp2)		; 1-D array
			rmf_matrix[*,ii] = temp1 / total(temp1)  ; renormalize back to one
		endfor
		wbad = where( finite(rmf_matrix) eq 0, numbad )
		if (numbad gt 0) then rmf_matrix[wbad] = 0
		if keyword_set(DEBUG) then stop, 'STOPPED: CHECK OUT RMF and RMF_Matrix'
	endif

	;
	;	2. Zero out bins not useful for DAXSS spectra (< 0.3 keV)
	;
	spectrum_output = spectrum_input
	wzero = where( energy_input lt 0.3 )
	spectrum_output[wzero] = 0.0

	;
	;   3. Reduce counts from higher-energy photons
	;   4. Increase counts from lower-energy photons
	;
	NUMBER_ELECTRONS_NOISE = 6.45  ; this is only VALID for FM=3
	energy_resolution = 2.35*3.68E-3*sqrt(0.12*energy_input/3.68E-3 + NUMBER_ELECTRONS_NOISE^2.)
	energy_step = abs(energy_input[2] - energy_input[1])

	i1 = wzero[-1] + 1L
	i2 = (where( energy_input gt (max(rmf_energy)-2.*max(energy_resolution))))[0] - 1L
	imax = (where( energy_input gt max(rmf_energy)))[0] - 1L
	ioffset = long((rmf_energy[0] - energy_input[0])/energy_step)
	kkmax = imax - ioffset
	kk1 = i1 - ioffset

	counts_reduced = fltarr(n_elements(spectrum_input))
	counts_add = fltarr(n_elements(spectrum_input))

	for ii=i2,i1,-1L do begin
		iextra = long(2.*energy_resolution[ii]/energy_step)
		kk = ii - ioffset  ; translate to different index for RMF_MATRIX (ii is for energy_input scale)
		temp1 = reform(rmf_matrix[kk,kk+iextra:kkmax])
		; wbad = where( finite(temp1) eq 0, numbad )
		; if (numbad gt 0) then temp1[wbad] = 0
		counts_reduced[ii] = total( temp1 * spectrum_input[ii+iextra:imax] )
		if ((kk-iextra) ge kk1) then begin
			temp2 = reform(rmf_matrix[kk1:kk-iextra,kk])
			; wbad = where( finite(temp2) eq 0, numbad )
			; if (numbad gt 0) then temp2[wbad] = 0
			counts_add[ii] = total( temp2 ) * spectrum_input[ii]
		endif
		spectrum_output[ii] = (spectrum_input[ii] - counts_reduced[ii] + counts_add[ii]) > 0.
	endfor

	if keyword_set(debug) then stop, 'STOPPED:  CHECK out spectrum_output, counts_reduced, counts_add ...'

;   5. Return updated spectrum
return, spectrum_output
end
