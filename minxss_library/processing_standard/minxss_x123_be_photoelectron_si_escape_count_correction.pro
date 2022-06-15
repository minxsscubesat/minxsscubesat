

;+
; NAME:
;   minxss_X123_be_photoelectron_si_escape_count_correction
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
; PURPOSE: Correct the measured x123 count spectrum for be_photoelectron, Si k, l (2s and 2p) escape processes.
;
;
; CALLING SEQUENCE: result = minxss_X123_be_photoelectron_si_escape_count_correction(x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, $
;X123_count_contribution_Be_Si_photopeak_ARRAY=output_model_X123_count_contribution_Be_Si_photopeak, $
;X123_count_contribution_Be_photoelectron_ARRAY=output_model_X123_count_contribution_Be_photoelectron, $
;X123_count_contribution_Si_escape_all_ARRAY=output_model_X123_count_contribution_Si_escape_all, $
;X123_corrected_count_contribution_Si_escape_all_ARRAY=output_model_X123_corrected_count_contribution_Si_escape_all, $
;X123_count_contribution_Si_k_escape_ARRAY=output_model_X123_count_contribution_Si_k_escape, $
;X123_corrected_count_contribution_Si_k_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_k_escape, $
;X123_count_contribution_Si_l_2s_escape_ARRAY=output_model_X123_count_contribution_Si_l_2s_escape, $
;X123_corrected_count_contribution_Si_l_2s_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_l_2s_escape, $
;X123_count_contribution_Si_l_2p_escape_ARRAY=output_model_X123_count_contribution_Si_l_2p_escape, $
;X123_corrected_count_contribution_Si_l_2p_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_l_2p_escape)
;
;
; DESCRIPTION: Adjust the measured counts to correct for the processes mentioned above
;

; INPUTS: x123 measured count spectrum (counts/s/kev), x123 energy bins (keV)

;
; INPUT KEYWORD PARAMETERS: None
;

; RETURNS: corrected x123 count spectrum
;
;
;;;X123_energy_bins_kev:                                                         [INPUT] input X123 energy bins (ARRAY)
;converted_energy_bins_offset_bins:                                              [INPUT] Offset in keV energy bins (FLOAT)
;x123_measured_counts:                                                           [INPUT] x123 measured count spectrum (ARRAY)
;counts_uncertainty:                                                             [OPTIONAL INPUT] uncertainty in the x123 count spectrum (ARRAY)
;minxss_instrument_structure_data_file:                                          [INPUT] Full path and file name of the minxss_instrument_structure_data_file (ARRAY)
;X123_count_contribution_Be_Si_photopeak_ARRAY:                                  [OUTPUT/RETURNED KEYWORD] measured count contribution from be_si_photopeak (ARRAY)
;X123_count_contribution_Be_photoelectron_ARRAY:                                 [OUTPUT/RETURNED KEYWORD] measured count contribution from be_photoelectrons (ARRAY)
;X123_count_contribution_Si_escape_all_ARRAY:                                    [OUTPUT/RETURNED KEYWORD] measured count contribution from all si escape processes (ARRAY)
;X123_corrected_count_contribution_Si_escape_all_ARRAY:                          [OUTPUT/RETURNED KEYWORD] corrected count contribution from be_si_escape all processes (ARRAY)
;X123_count_contribution_Si_k_escape_ARRAY:                                      [OUTPUT/RETURNED KEYWORD] measured count contribution from si k escape process (ARRAY)
;X123_corrected_count_contribution_Si_k_escape_ARRAY:                            [OUTPUT/RETURNED KEYWORD] corrected count contribution from silicon k escape process (ARRAY)
;X123_count_contribution_Si_l_2s_escape_ARRAY:                                   [OUTPUT/RETURNED KEYWORD] measured count contribution from si l 2s escape process (ARRAY)
;X123_corrected_count_contribution_Si_l_2s_escape_ARRAY:                         [OUTPUT/RETURNED KEYWORD] corrected count contribution from si l 2s escape process (ARRAY)
;X123_count_contribution_Si_l_2p_escape_ARRAY:                                   [OUTPUT/RETURNED KEYWORD] measured count contribution from si l 2p escape process (ARRAY)
;X123_corrected_count_contribution_Si_l_2p_escape_ARRAY:                         [OUTPUT/RETURNED KEYWORD] corrected count contribution from si l 2p escape process (ARRAY)

;
; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, April, 2016, Christopher S. Moore
;   Laboratory for Atmospheric and Space Physics
;
;
;-
;-

;Returns the Be photoelectron and si k and l (2s and 2p) fluoresence escape process count rate, that can be used to infer the 'cleaned' detected count rate

function minxss_X123_be_photoelectron_si_escape_count_correction, x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, $
  X123_count_contribution_Be_Si_photopeak_ARRAY=output_model_X123_count_contribution_Be_Si_photopeak, $
  X123_count_contribution_Be_photoelectron_ARRAY=output_model_X123_count_contribution_Be_photoelectron, $
  X123_count_contribution_Si_escape_all_ARRAY=output_model_X123_count_contribution_Si_escape_all, $
  X123_corrected_count_contribution_Si_escape_all_ARRAY=output_model_X123_corrected_count_contribution_Si_escape_all, $
  X123_count_contribution_Si_k_escape_ARRAY=output_model_X123_count_contribution_Si_k_escape, $
  X123_corrected_count_contribution_Si_k_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_k_escape, $
  X123_count_contribution_Si_l_2s_escape_ARRAY=output_model_X123_count_contribution_Si_l_2s_escape, $
  X123_corrected_count_contribution_Si_l_2s_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_l_2s_escape, $
  X123_count_contribution_Si_l_2p_escape_ARRAY=output_model_X123_count_contribution_Si_l_2p_escape, $
  X123_corrected_count_contribution_Si_l_2p_escape_ARRAY=output_model_X123_corrected_count_contribution_Si_l_2p_escape

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  Convert_keV_Nanometers = 1.24
  Convert_Meters_Nanameters = 1.0E9
  Convert_Angstroms_Nanameters = 1.0E-1
  CONVERT_um_to_cm = 1.0E-4
  CONVERT_A_to_um = CONVERT_um_to_cm
  CONVERT_Barn_to_MBARN = 1.0E-6
  CONVERT_ms_to_s = 1.0e-3
  e_h_Pair_keV = 0.00365
  Convert_keV_ev = 1.0e3
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;  Apply an offset
  x123_energy_bins_kev_offset = x123_energy_bins_kev + converted_energy_bins_offset_bins

  ;Find the total number of input bins
  n_x123_energy_bins_kev = n_elements(x123_energy_bins_kev_offset)


  ;Find the values of positve energy bins, (x123 offset can be negative)
  index_positive_energies = where(x123_energy_bins_kev_offset gt 0.0)
  n_positive_x123_energy_bins_kev = n_elements(index_positive_energies)
  ;find the good energies and put them into an array
  positive_x123_energy_bins_kev = x123_energy_bins_kev_offset[index_positive_energies]
  converted_energy_bins = positive_x123_energy_bins_kev


  ;use only the positive indicies
  x123_measured_counts_positive = x123_measured_counts[index_positive_energies]

  If KEYWORD_SET(uncertainty_x123_measured_counts) THEN  $
    uncertainty_x123_measured_counts_positive = uncertainty_x123_measured_counts[index_positive_energies]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Restore, the minxss_detector_response_data
  ;  TW-2022:  This is very slow to Restore Cal-File 1000s of time; make COMMON BLOCK
  COMMON  minxss_detector_response_common, minxss_detector_response
  if (n_elements(minxss_detector_response) lt 1) then RESTORE, minxss_instrument_structure_data_file
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Calculate the Si_escape process probability functions to the energy bins
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_si_photopeak_detection
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_si_photopeak_detection
  ;Interpolate to the probability the the bin space
  interpol_be_si_photopeak_detection_pdf = INTERPOL(minxss_detector_response.x123_be_fit_spectral_efficiency, minxss_detector_response.photon_energy, converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_interpol_be_si_photopeak_detection_pdf = WHERE(interpol_be_si_photopeak_detection_pdf LT 0.0)
  interpol_be_si_photopeak_detection_pdf[INDEX_interpol_be_si_photopeak_detection_pdf] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_photoelectron_detection
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_photoelectron_detection
  ;Interpolate to the probability the the bin space
  interpol_be_photoelectron_detection_pdf = INTERPOL(minxss_detector_response.x123_photoelectron_spectral_detection_efficiency, minxss_detector_response.photon_energy, converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_interpol_be_photoelectron_detection_pdf = WHERE(interpol_be_photoelectron_detection_pdf LT 0.0)
  interpol_be_photoelectron_detection_pdf[INDEX_interpol_be_photoelectron_detection_pdf] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si_k_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si_k_secape
  ;Interpolate to the probability the the bin space
  interpol_si_k_escape_pdf = INTERPOL(minxss_detector_response.x123_si_k_escape_probability, minxss_detector_response.photon_energy, converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_interpol_si_k_escape_pdf = WHERE(interpol_si_k_escape_pdf LT 0.0)
  interpol_si_k_escape_pdf[INDEX_interpol_si_k_escape_pdf] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;si_l_2s_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;si_l_2s_secape
  ;Interpolate to the probability the the bin space
  interpol_si_l_2s_escape_pdf = INTERPOL(minxss_detector_response.x123_si_l_2s_escape_probability, minxss_detector_response.photon_energy, converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_interpol_si_l_2s_escape_pdf = WHERE(interpol_si_l_2s_escape_pdf LT 0.0)
  interpol_si_l_2s_escape_pdf[INDEX_interpol_si_l_2s_escape_pdf] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;si_l_2p_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;si_l_2p_secape
  ;Interpolate to the probability the the bin space
  interpol_si_l_2p_escape_pdf = INTERPOL(minxss_detector_response.x123_si_l_2p_escape_probability, minxss_detector_response.photon_energy, converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_interpol_si_l_2p_escape_pdf = WHERE(interpol_si_l_2p_escape_pdf LT 0.0)
  interpol_si_l_2p_escape_pdf[INDEX_interpol_si_l_2p_escape_pdf] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;convolve the probability distribution of the photopeak be-si detection and the be photoelectrons
  ;convolve the signal
  ;be_si_photopeak_detection
  convolve_X123_Be_si_photopeak_detection_ARRAY = gaussfold(minxss_detector_response.photon_energy, minxss_detector_response.x123_be_fit_spectral_efficiency, minxss_detector_response.x123_nominal_spectral_resolution)
  ;    convolve_X123_Be_si_photopeak_detection_ARRAY = gauss_variable_fwhm_convolve(minxss_detector_response.photon_energy, minxss_detector_response.x123_be_fit_spectral_efficiency, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
  ;be_photoelectron
  convolve_X123_be_photoelectron_detection_ARRAY = gaussfold(minxss_detector_response.photon_energy, minxss_detector_response.x123_photoelectron_spectral_detection_efficiency, minxss_detector_response.x123_nominal_spectral_resolution)
  ;    convolve_X123_be_photoelectron_detection_ARRAY = gauss_variable_fwhm_convolve(minxss_detector_response.photon_energy, minxss_detector_response.x123_photoelectron_spectral_detection_efficiency, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)


  ;integrate the counts to the bins
  ;Bin the electrons/counts into energy space
  ;INTERPOLATE to an offset grid, a grid that is offset by 0.5*the bin width
  ;Offest the X123 Fe 55 calibrated energy bins by half a bin width to sum counts
  x123_bin_spacing_energy_kev = abs(positive_x123_energy_bins_kev[0] - positive_x123_energy_bins_kev[1])
  SHIFTED_converted_energy_bins = converted_energy_bins - (0.5*x123_bin_spacing_energy_kev)

  ;interpolate tot the shifteed energy bins
  ;be_si_photopeak_detection
  shifted_convolve_X123_be_si_photopeak_detection_ARRAY = interpol(convolve_X123_be_si_photopeak_detection_ARRAY, minxss_detector_response.photon_energy, SHIFTED_converted_energy_bins, /NAN)
  ;be_photoelectron
  shifted_convolve_X123_be_photoelectron_detection_ARRAY = interpol(convolve_X123_be_photoelectron_detection_ARRAY, minxss_detector_response.photon_energy, SHIFTED_converted_energy_bins, /NAN)

  ;get rid of negatives
  ;be_si_photopeak_detection
  INDEX_shifted_convolve_X123_be_si_photopeak_detection_ARRAY = WHERE(shifted_convolve_X123_be_si_photopeak_detection_ARRAY LT 0.0)
  shifted_convolve_X123_be_si_photopeak_detection_ARRAY[INDEX_shifted_convolve_X123_be_si_photopeak_detection_ARRAY] = 0.0
  ;be_photoelectron
  INDEX_shifted_convolve_X123_be_photoelectron_detection_ARRAY = WHERE(shifted_convolve_X123_be_photoelectron_detection_ARRAY LT 0.0)
  shifted_convolve_X123_be_photoelectron_detection_ARRAY[INDEX_shifted_convolve_X123_be_photoelectron_detection_ARRAY] = 0.0


  ;bin the counts
  ;be_si_photopeak_detection
  final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)
  ;be_photoelectron
  final_shifted_convolve_X123_be_photoelectron_detection_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)

  ;Sum the counts over the shirfted energy bins
  FOR t = 0, n_positive_x123_energy_bins_kev  - 2 DO BEGIN ;Sum over 1 less indix becaus of the staggered bin
    ;be_si_photopeak_detection
    final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_be_si_photopeak_detection_ARRAY[t:t+1], /DOUBLE)
    ;be_photoelectron
    final_shifted_convolve_X123_be_photoelectron_detection_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_be_photoelectron_detection_ARRAY[t:t+1], /DOUBLE)
  ENDFOR
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Start by finding the contribution of each escape process, also accounting for the be photoelectron component

  ;Start the reconstruction
  estimated_count_contribution_si_k_escape = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_si_l_2s_escape = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_si_l_2p_escape = DBLARR(n_positive_x123_energy_bins_kev)

  subtracted_counts_si_k_escape = DBLARR(n_positive_x123_energy_bins_kev)
  corrected_counts_si_k_escape = DBLARR(n_positive_x123_energy_bins_kev)
  subtracted_counts_si_l_2s_escape = DBLARR(n_positive_x123_energy_bins_kev)
  corrected_counts_si_l_2s_escape = DBLARR(n_positive_x123_energy_bins_kev)
  subtracted_counts_si_l_2p_escape = DBLARR(n_positive_x123_energy_bins_kev)
  corrected_counts_si_l_2p_escape = DBLARR(n_positive_x123_energy_bins_kev)

  shifted_x123_energy_bins_kev_si_k_escape = positive_x123_energy_bins_kev - minxss_detector_response.x123_si_k_photon_escape_energy_keV
  shifted_x123_energy_bins_kev_si_l_2s_escape = positive_x123_energy_bins_kev - minxss_detector_response.x123_si_l_2s_photon_escape_energy_keV
  shifted_x123_energy_bins_kev_si_l_2p_escape = positive_x123_energy_bins_kev - minxss_detector_response.x123_si_l_2p_photon_escape_energy_keV


  total_estimated_measured_count_pdf = DBLARR(n_positive_x123_energy_bins_kev)
  normalized_convolved_be_si_photopeak_detection_pdf = DBLARR(n_positive_x123_energy_bins_kev)
  normalized_convolved_be_photoelectron_detection_pdf = DBLARR(n_positive_x123_energy_bins_kev)
  normalized_absoulute_interpol_si_k_escape_pdf = DBLARR(n_positive_x123_energy_bins_kev)
  normalized_absoulute_interpol_si_l_2s_escape_pdf = DBLARR(n_positive_x123_energy_bins_kev)
  normalized_absoulute_interpol_si_l_2p_escape_pdf = DBLARR(n_positive_x123_energy_bins_kev)

  estimated_count_contribution_convolved_be_si_photopeak_detection = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_convolved_be_photoelectron_detection = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_si_k_escape = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_si_l_2s_escape = DBLARR(n_positive_x123_energy_bins_kev)
  estimated_count_contribution_si_l_2p_escape  = DBLARR(n_positive_x123_energy_bins_kev)


  corected_count_contribution = DBLARR(n_positive_x123_energy_bins_kev)

  ;Start with the original counts
  temp_modified_x123_measured_counts_positive_array = x123_measured_counts_positive



  ;Must reconstruct the counts in reverse index space
  FOR k = n_positive_x123_energy_bins_kev - 2, 0, -1 DO BEGIN
    ;      total_estimated_measured_count_pdf[k] = final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY[k] - ((interpol_si_k_escape_pdf[k] + interpol_si_l_2s_escape_pdf[k] + interpol_si_l_2p_escape_pdf[k])*interpol_be_si_photopeak_detection_pdf[k]) + final_shifted_convolve_X123_be_photoelectron_detection_ARRAY[k]
    ;      normalized_convolved_be_si_photopeak_detection_pdf[k] = final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY[k]/total_estimated_measured_count_pdf[k]
    ;      normalized_convolved_be_photoelectron_detection_pdf[k] = final_shifted_convolve_X123_be_photoelectron_detection_ARRAY[k]/total_estimated_measured_count_pdf[k]

    total_estimated_measured_count_pdf[k] = interpol_be_si_photopeak_detection_pdf[k] - ((interpol_si_k_escape_pdf[k] + interpol_si_l_2s_escape_pdf[k] + interpol_si_l_2p_escape_pdf[k])*interpol_be_si_photopeak_detection_pdf[k]) + interpol_be_photoelectron_detection_pdf[k]
    normalized_convolved_be_si_photopeak_detection_pdf[k] = interpol_be_si_photopeak_detection_pdf[k]/total_estimated_measured_count_pdf[k]
    normalized_convolved_be_photoelectron_detection_pdf[k] = interpol_be_photoelectron_detection_pdf[k]/total_estimated_measured_count_pdf[k]

    normalized_absoulute_interpol_si_k_escape_pdf[k] = (interpol_si_k_escape_pdf[k]*interpol_be_si_photopeak_detection_pdf[k])/total_estimated_measured_count_pdf[k]
    normalized_absoulute_interpol_si_l_2s_escape_pdf[k] = (interpol_si_l_2s_escape_pdf[k]*interpol_be_si_photopeak_detection_pdf[k])/total_estimated_measured_count_pdf[k]
    normalized_absoulute_interpol_si_l_2p_escape_pdf[k] = (interpol_si_l_2p_escape_pdf[k]*interpol_be_si_photopeak_detection_pdf[k])/total_estimated_measured_count_pdf[k]

    estimated_count_contribution_convolved_be_si_photopeak_detection[k] = normalized_convolved_be_si_photopeak_detection_pdf[k]*temp_modified_x123_measured_counts_positive_array[k]
    estimated_count_contribution_convolved_be_photoelectron_detection[k] = normalized_convolved_be_photoelectron_detection_pdf[k]*temp_modified_x123_measured_counts_positive_array[k]
    estimated_count_contribution_si_k_escape[k] = normalized_absoulute_interpol_si_k_escape_pdf[k]*temp_modified_x123_measured_counts_positive_array[k]
    estimated_count_contribution_si_l_2s_escape[k] = normalized_absoulute_interpol_si_l_2s_escape_pdf[k]*temp_modified_x123_measured_counts_positive_array[k]
    estimated_count_contribution_si_l_2p_escape[k] = normalized_absoulute_interpol_si_l_2p_escape_pdf[k]*temp_modified_x123_measured_counts_positive_array[k]


    ;si_k_escape
    INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_k_escape = MAX(WHERE(positive_x123_energy_bins_kev LE shifted_x123_energy_bins_kev_si_k_escape[k]))
    IF positive_x123_energy_bins_kev[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_k_escape] GT 0.0 THEN $
      temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_k_escape] = temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_k_escape] - estimated_count_contribution_si_k_escape[k]
    ;si_l_2s_escape
    INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2s_escape = MAX(WHERE(positive_x123_energy_bins_kev LE shifted_x123_energy_bins_kev_si_l_2s_escape[k]))
    IF positive_x123_energy_bins_kev[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2s_escape] GT 0.0 THEN $
      temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2s_escape] = temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2s_escape] - estimated_count_contribution_si_l_2s_escape[k]
    ;si_l_2p_escape
    INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2p_escape = MAX(WHERE(positive_x123_energy_bins_kev LE shifted_x123_energy_bins_kev_si_l_2p_escape[k]))
    IF positive_x123_energy_bins_kev[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2p_escape] GT 0.0 THEN $
      temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2p_escape] = temp_modified_x123_measured_counts_positive_array[INDEX_temp_modified_x123_measured_counts_positive_array_count_contribution_si_l_2p_escape] - estimated_count_contribution_si_l_2p_escape[k]

    corected_count_contribution[k] = temp_modified_x123_measured_counts_positive_array[k] - estimated_count_contribution_convolved_be_photoelectron_detection[k] + (estimated_count_contribution_si_k_escape[k] + estimated_count_contribution_si_l_2s_escape[k] + estimated_count_contribution_si_l_2p_escape[k])

    ;    ENDIF
  ENDFOR

  ;Correct for negative counts
  ;get rid of negatives
  INDEX_corected_count_contribution = WHERE(corected_count_contribution LT 0.0)
  corected_count_contribution[INDEX_corected_count_contribution] = 0.0
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;interpolate to the original grid
  ;Correct for negative counts
  ;get rid of negatives
  ;be_si_photopeak
  INDEX_estimated_count_contribution_convolved_be_si_photopeak_detection = WHERE(estimated_count_contribution_convolved_be_si_photopeak_detection LT 0.0)
  estimated_count_contribution_convolved_be_si_photopeak_detection[INDEX_estimated_count_contribution_convolved_be_si_photopeak_detection] = 0.0
  ;be_photoelectron
  INDEX_estimated_count_contribution_convolved_be_photoelectron_detection = WHERE(estimated_count_contribution_convolved_be_photoelectron_detection LT 0.0)
  estimated_count_contribution_convolved_be_photoelectron_detection[INDEX_estimated_count_contribution_convolved_be_photoelectron_detection] = 0.0

  ;si_k_escape
  INDEX_estimated_count_contribution_si_k_escape = WHERE(estimated_count_contribution_si_k_escape LT 0.0)
  estimated_count_contribution_si_k_escape[INDEX_estimated_count_contribution_si_k_escape] = 0.0
  ;si_l_2s_escape
  INDEX_estimated_count_contribution_si_l_2s_escape = WHERE(estimated_count_contribution_si_l_2s_escape LT 0.0)
  estimated_count_contribution_si_l_2s_escape[INDEX_estimated_count_contribution_si_l_2s_escape] = 0.0
  ;si_l_2p_escape
  INDEX_estimated_count_contribution_si_l_2p_escape = WHERE(estimated_count_contribution_si_l_2p_escape LT 0.0)
  estimated_count_contribution_si_l_2p_escape[INDEX_estimated_count_contribution_si_l_2p_escape] = 0.0



  ;si_k_escape
  interpol_estimated_count_contribution_si_k_escape = interpol(estimated_count_contribution_si_k_escape, shifted_x123_energy_bins_kev_si_k_escape, positive_x123_energy_bins_kev, /NAN)
  ;si_l_2s_escape
  interpol_estimated_count_contribution_si_l_2s_escape = interpol(estimated_count_contribution_si_l_2s_escape, shifted_x123_energy_bins_kev_si_l_2s_escape, positive_x123_energy_bins_kev, /NAN)
  ;si_l_2p_escape
  interpol_estimated_count_contribution_si_l_2p_escape = interpol(estimated_count_contribution_si_l_2p_escape, shifted_x123_energy_bins_kev_si_l_2p_escape, positive_x123_energy_bins_kev, /NAN)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;insert the computed response to an array of the same size as the original but with 0's for the negative energies
  ;Be_Si_photopeak
  output_model_X123_count_contribution_Be_Si_photopeak = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_count_contribution_Be_Si_photopeak[index_positive_energies] = estimated_count_contribution_convolved_be_si_photopeak_detection

  ;Be_photoelectron
  output_model_X123_count_contribution_Be_photoelectron = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_count_contribution_Be_photoelectron[index_positive_energies] = estimated_count_contribution_convolved_Be_photoelectron_detection

  ;Si_k_escape
  output_model_X123_count_contribution_Si_k_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_count_contribution_Si_k_escape[index_positive_energies] = interpol_estimated_count_contribution_si_k_escape

  ;Si_l_2s_escape
  output_model_X123_count_contribution_Si_l_2s_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_count_contribution_Si_l_2s_escape[index_positive_energies] = interpol_estimated_count_contribution_si_l_2s_escape

  ;Si_l_2p_escape
  output_model_X123_count_contribution_Si_l_2p_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_count_contribution_Si_l_2p_escape[index_positive_energies] = interpol_estimated_count_contribution_si_l_2p_escape


  ;the count_contribution from all the Si edges
  output_model_X123_count_contribution_Si_escape_all = output_model_X123_count_contribution_Si_k_escape + output_model_X123_count_contribution_Si_l_2s_escape +output_model_X123_count_contribution_Si_l_2p_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si_k_escape
  output_model_X123_corrected_count_contribution_Si_k_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_corrected_count_contribution_Si_k_escape[index_positive_energies] = estimated_count_contribution_si_k_escape

  ;Si_l_2s_escape
  output_model_X123_corrected_count_contribution_Si_l_2s_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_corrected_count_contribution_Si_l_2s_escape[index_positive_energies] = estimated_count_contribution_si_l_2s_escape

  ;Si_l_2p_escape
  output_model_X123_corrected_count_contribution_Si_l_2p_escape = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_corrected_count_contribution_Si_l_2p_escape[index_positive_energies] = estimated_count_contribution_si_l_2p_escape

  ;Calculate the corrected count contribution from all Si K and L escape
  output_model_X123_corrected_count_contribution_Si_escape_all = output_model_X123_corrected_count_contribution_Si_k_escape + output_model_X123_corrected_count_contribution_Si_l_2s_escape + output_model_X123_corrected_count_contribution_Si_l_2p_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Final be photoelectron and si k, l (2s and 2p) corrected count rate
  output_model_x123_corected_count_contribution = DBLARR(n_x123_energy_bins_kev)
  output_model_x123_corected_count_contribution[index_positive_energies] = corected_count_contribution


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;return the model output signal
  return, output_model_x123_corected_count_contribution


end
