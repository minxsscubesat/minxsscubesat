

;+
; NAME:
;   X123_invert_count_to_photon_estimate
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
; PURPOSE: Invert the x123 measured count spectrum (counts/s/kev) to estimate the incident photon flux (photons/s/keV), if keyword set, /use_detector_area, the photon flux is in units of (photons/s/keV/cm^2)
;
;
; CALLING SEQUENCE: result = X123_invert_count_to_photon_estimate(x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, $
;  uncertainty_X123_photon_estimate_ARRAY=output_model_uncertainty_X123_photon_estimate, $
;  X123_photon_estimate_be_si_photopeak_only_ARRAY=output_model_x123_inverted_counts_to_photons_be_si_photopeak_only, $
;  uncertainty_X123_photon_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only, $
;  X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=output_model_x123_inverted_counts_to_photons_be_photoelectron_only, $
;  uncertainty_X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=output_model_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, $
;  X123_corrected_count_be_photoelectron_si_escape_ARRAY=X123_corrected_count_be_photoelectron_si_escape, $
;  X123_count_contribution_Be_Si_photopeak_ARRAY=X123_count_contribution_Be_Si_photopeak, $
;  X123_count_contribution_Be_photoelectron_ARRAY=X123_count_contribution_Be_photoelectron, $
;  X123_count_contribution_Si_escape_all_ARRAY=X123_count_contribution_Si_escape_all, $
;  X123_corrected_count_contribution_Si_escape_all_ARRAY=X123_corrected_count_contribution_Si_escape_all, $
;  X123_count_contribution_Si_k_escape_ARRAY=X123_count_contribution_Si_k_escape, $
;  X123_corrected_count_contribution_Si_k_escape_ARRAY=X123_corrected_count_contribution_Si_k_escape, $
;  X123_count_contribution_Si_l_2s_escape_ARRAY=X123_count_contribution_Si_l_2s_escape, $
;  X123_corrected_count_contribution_Si_l_2s_escape_ARRAY=X123_corrected_count_contribution_Si_l_2s_escape, $
;  X123_count_contribution_Si_l_2p_escape_ARRAY=X123_count_contribution_Si_l_2p_escape, $
;  X123_corrected_count_contribution_Si_l_2p_escape_ARRAY=X123_corrected_count_contribution_Si_l_2p_escape, $
;  X123_inverted_count_to_photon_estimate_valid_flag_ARRAY=X123_invert_count_to_photon_estimate_valid_flag, $
;  X123_inverted_valid_flag_fractional_difference_level=X123_inverted_valid_flag_fractional_difference_maximum_threshold)
;
; DESCRIPTION: Takes the x123 measured count spectrum and inverts to obtain the input photon flux (photons/s/keV/cm^2)
;

; INPUTS: x123 measured count spectrum (counts/s/kev), x123 energy bins (keV)

;
; INPUT KEYWORD PARAMETERS: /use_detector_area, multiplies the input photon flux by the XP geometric aperture area,
;                           can output uncertainties and contributions form different processes that contribute to the minxss spectrum
;

; RETURNS: estimate of the input photon flux (photons/s/keV/cm^2)
;
;
; Details:
; 
;
;
;;X123_energy_bins_kev:                                                          [INPUT] input X123 energy bins (ARRAY)
;converted_energy_bins_offset_bins:                                              [INPUT] Offset in keV energy bins (FLOAT)
;x123_measured_counts:                                                           [INPUT] x123 measured count spectrum (ARRAY)
;counts_uncertainty                                                              [OPTIONAL INPUT] uncertainty in the x123 count spectrum (ARRAY)
;minxss_instrument_structure_data_file:                                          [INPUT] Full path and file name of the minxss_instrument_structure_data_file (ARRAY)
;use_detector_area                                                               [BOOLEAN KEYWORD] set this keyword to use the detector area in the calculation
;uncertainty_X123_photon_estimate_ARRAY:                                         [OUTPUT/RETURNED KEYWORD]  returns the uncertainty in the photon flux estimate
;X123_photon_estimate_be_si_photopeak_only_ARRAY:                                [OUTPUT/RETURNED KEYWORD] estimate of input photon flux derived form the be_si_photopeak contribution (ARRAY)
;uncertainty_X123_photon_estimate_be_si_photopeak_only_ARRAY:                    [OUTPUT/RETURNED KEYWORD] uncertainty in the estimate of input photon flux derived form the be_si_photopeak contribution (ARRAY)
;X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY:                    [OUTPUT/RETURNED KEYWORD] estimate of input photon flux derived form the be_photoelectron contribution (ARRAY)
;uncertainty_X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY:        [OUTPUT/RETURNED KEYWORD] uncertainty in the estimate of input photon flux derived form the be_photoelectron contribution (ARRAY)
;X123_corrected_count_be_photoelectron_si_escape_ARRAY:                          [OUTPUT/RETURNED KEYWORD] corrected count contribution from be_photoelectrons (ARRAY)
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
;X123_inverted_count_to_photon_estimate_valid_flag_ARRAY:                        [OUTPUT/RETURNED KEYWORD] flag indicating the agreement between the returned, be_si_photopeak_only and be_photoelectron_only photon flux estimation (ARRAY), 
;                                                                                   flag = 1 if all three processes agree to within 10% (this is the default value,
;                                                                                   which can be changed by setting the X123_inverted_valid_flag_fractional_difference_level keyword to another FRACTIONAL value,
;                                                                                   flag = 0 if the above is NOT true (or if there are no measured x123 counts at that energy
;X123_inverted_valid_flag_fractional_difference_level:                           [OUTPUT/RETURNED KEYWORD] sets a diferent FRACTIONAL agreement value between the three inverted photon estimates, between the returned, be_si_photopeak_only and be_photoelectron_only photon flux estimation
  
;
; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, May, 2016, Christopher S. Moore
;   Laboratory for Atmospheric and Space Physics
;
;
;-
;-

;Invert the counts to get an estimate of the input photon flux

function X123_invert_count_to_photon_estimate, x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, $
  uncertainty_X123_photon_estimate_ARRAY=output_model_uncertainty_X123_photon_estimate, $
  X123_photon_estimate_be_si_photopeak_only_ARRAY=output_model_x123_inverted_counts_to_photons_be_si_photopeak_only, $
  uncertainty_X123_photon_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only, $
  X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=output_model_x123_inverted_counts_to_photons_be_photoelectron_only, $
  uncertainty_X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=output_model_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, $
  X123_corrected_count_be_photoelectron_si_escape_ARRAY=X123_corrected_count_be_photoelectron_si_escape, $
  X123_count_contribution_Be_Si_photopeak_ARRAY=X123_count_contribution_Be_Si_photopeak, $
  X123_count_contribution_Be_photoelectron_ARRAY=X123_count_contribution_Be_photoelectron, $
  X123_count_contribution_Si_escape_all_ARRAY=X123_count_contribution_Si_escape_all, $
  X123_corrected_count_contribution_Si_escape_all_ARRAY=X123_corrected_count_contribution_Si_escape_all, $
  X123_count_contribution_Si_k_escape_ARRAY=X123_count_contribution_Si_k_escape, $
  X123_corrected_count_contribution_Si_k_escape_ARRAY=X123_corrected_count_contribution_Si_k_escape, $
  X123_count_contribution_Si_l_2s_escape_ARRAY=X123_count_contribution_Si_l_2s_escape, $
  X123_corrected_count_contribution_Si_l_2s_escape_ARRAY=X123_corrected_count_contribution_Si_l_2s_escape, $
  X123_count_contribution_Si_l_2p_escape_ARRAY=X123_count_contribution_Si_l_2p_escape, $
  X123_corrected_count_contribution_Si_l_2p_escape_ARRAY=X123_corrected_count_contribution_Si_l_2p_escape, $
  X123_inverted_count_to_photon_estimate_valid_flag_ARRAY=X123_invert_count_to_photon_estimate_valid_flag, $
  X123_inverted_valid_flag_fractional_difference_level=X123_inverted_valid_flag_fractional_difference_maximum_threshold

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
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Estimate the corrected count rate
x123_corrected_count_be_photoelectron_si_escape = X123_be_photoelectron_si_escape_count_correction(x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, $
  X123_count_contribution_Be_Si_photopeak_ARRAY=X123_count_contribution_Be_Si_photopeak, $
  X123_count_contribution_Be_photoelectron_ARRAY=X123_count_contribution_Be_photoelectron, $
  X123_count_contribution_Si_escape_all_ARRAY=X123_count_contribution_Si_escape_all, $
  X123_corrected_count_contribution_Si_escape_all_ARRAY=X123_corrected_count_contribution_Si_escape_all, $
  X123_count_contribution_Si_k_escape_ARRAY=X123_count_contribution_Si_k_escape, $
  X123_corrected_count_contribution_Si_k_escape_ARRAY=X123_corrected_count_contribution_Si_k_escape, $
  X123_count_contribution_Si_l_2s_escape_ARRAY=X123_count_contribution_Si_l_2s_escape, $
  X123_corrected_count_contribution_Si_l_2s_escape_ARRAY=X123_corrected_count_contribution_Si_l_2s_escape, $
  X123_count_contribution_Si_l_2p_escape_ARRAY=X123_count_contribution_Si_l_2p_escape, $
  X123_corrected_count_contribution_Si_l_2p_escape_ARRAY=X123_corrected_count_contribution_Si_l_2p_escape);
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  ;use the positive indicies
  x123_corrected_count_be_photoelectron_si_escape_positive = x123_corrected_count_be_photoelectron_si_escape[index_positive_energies]
  X123_count_contribution_Be_Si_photopeak_positive = X123_count_contribution_Be_Si_photopeak[index_positive_energies]
  X123_count_contribution_Be_photoelectron_positive = X123_count_contribution_Be_photoelectron[index_positive_energies]

  If KEYWORD_SET(uncertainty_x123_measured_counts) THEN  $
    uncertainty_x123_measured_counts_positive = uncertainty_x123_measured_counts[index_positive_energies]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Restore, the minxss_detector_response_data
  RESTORE, minxss_instrument_structure_data_file
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

  ;invert to find the photon flux
 
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_photoelectron_only
  x123_inverted_counts_to_photons_be_photoelectron_only = X123_count_contribution_Be_photoelectron_positive/final_shifted_convolve_X123_be_photoelectron_detection_ARRAY

  ;correct for negatives
  INDEX_x123_inverted_counts_to_photons_be_photoelectron_only = WHERE(x123_inverted_counts_to_photons_be_photoelectron_only LT 0.0)
  x123_inverted_counts_to_photons_be_photoelectron_only[INDEX_x123_inverted_counts_to_photons_be_photoelectron_only] = 0.0
  ;Correct for NAN's
  INDEX_FINITE_x123_inverted_counts_to_photons_be_photoelectron_only = WHERE(FINITE(x123_inverted_counts_to_photons_be_photoelectron_only, /NAN) EQ 1.0)
  x123_inverted_counts_to_photons_be_photoelectron_only[INDEX_x123_inverted_counts_to_photons_be_photoelectron_only] = 0.0
  ;output the data back on the input grid
  output_model_x123_inverted_counts_to_photons_be_photoelectron_only = DBLARR(n_x123_energy_bins_kev)
  output_model_x123_inverted_counts_to_photons_be_photoelectron_only[index_positive_energies] = x123_inverted_counts_to_photons_be_photoelectron_only
  ;Divide by he minxss x123 area
  if keyword_set(use_detector_area) then output_model_x123_inverted_counts_to_photons_be_photoelectron_only /= minxss_detector_response.x123_aperture_geometric_area
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;calculate uncertainties ofn the inverted photon flux
  if keyword_set(uncertainty_x123_measured_counts) then begin
    uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only = SQRT(((uncertainty_x123_measured_counts_positive*X123_count_contribution_Be_photoelectron_positive)/(x123_measured_counts_positive*final_shifted_convolve_X123_be_photoelectron_detection_ARRAY))^(2.0))
    ;correct for negatives
    INDEX_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only = WHERE(uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only LT 0.0)
    uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only[INDEX_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only] = 0.0
    ;Correct for NAN's
    INDEX_FINITE_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only = WHERE(FINITE(uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, /NAN) EQ 1.0)
    uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only[INDEX_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only] = 0.0
    ;output the data back on the input grid
    output_model_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only = DBLARR(n_x123_energy_bins_kev)
    output_model_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only[index_positive_energies] = uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only

    if keyword_set(use_detector_area) then output_model_uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only /= minxss_detector_response.x123_aperture_geometric_area
  endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;be_si_photopeak_only
  x123_inverted_counts_to_photons_be_si_photopeak_only = x123_measured_counts_positive/final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY

  ;correct for negatives 
  INDEX_x123_inverted_counts_to_photons_be_si_photopeak_only = WHERE(x123_inverted_counts_to_photons_be_si_photopeak_only LT 0.0)
  x123_inverted_counts_to_photons_be_si_photopeak_only[INDEX_x123_inverted_counts_to_photons_be_si_photopeak_only] = 0.0
  ;Correct for NAN's
  INDEX_FINITE_x123_inverted_counts_to_photons_be_si_photopeak_only = WHERE(FINITE(x123_inverted_counts_to_photons_be_si_photopeak_only, /NAN) EQ 1.0)
  x123_inverted_counts_to_photons_be_si_photopeak_only[INDEX_x123_inverted_counts_to_photons_be_si_photopeak_only] = 0.0
  ;output the data back on the input grid
  output_model_x123_inverted_counts_to_photons_be_si_photopeak_only = DBLARR(n_x123_energy_bins_kev)
  output_model_x123_inverted_counts_to_photons_be_si_photopeak_only[index_positive_energies] = x123_inverted_counts_to_photons_be_si_photopeak_only
  ;Divide by he minxss x123 area
  if keyword_set(use_detector_area) then output_model_x123_inverted_counts_to_photons_be_si_photopeak_only /= minxss_detector_response.x123_aperture_geometric_area
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;calculate uncertainties ofn the inverted photon flux
  if keyword_set(uncertainty_x123_measured_counts) then begin
    uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only = SQRT(((uncertainty_x123_measured_counts_positive*x123_measured_counts_positive)/(x123_measured_counts_positive*final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY))^(2.0))
    ;correct for negatives
    INDEX_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only = WHERE(uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only LT 0.0)
    uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only[INDEX_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only] = 0.0
    ;Correct for NAN's
    INDEX_FINITE_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only = WHERE(FINITE(uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only, /NAN) EQ 1.0)
    uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only[INDEX_FINITE_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only] = 0.0
    ;output the data back on the input grid
    output_model_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only = DBLARR(n_x123_energy_bins_kev)
    output_model_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only[index_positive_energies] = uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only

    if keyword_set(use_detector_area) then output_model_uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only /= minxss_detector_response.x123_aperture_geometric_area
  endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;corrected_counts
  x123_corrected_inverted_counts_to_photons = x123_corrected_count_be_photoelectron_si_escape_positive/final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY

  ;correct for negatives
  INDEX_x123_corrected_inverted_counts_to_photons = WHERE(x123_corrected_inverted_counts_to_photons LT 0.0)
  x123_corrected_inverted_counts_to_photons[INDEX_x123_corrected_inverted_counts_to_photons] = 0.0
  ;Correct for NAN's
  INDEX_FINITE_x123_corrected_inverted_counts_to_photons = WHERE(FINITE(x123_corrected_inverted_counts_to_photons, /NAN) EQ 1.0)
  x123_corrected_inverted_counts_to_photons[INDEX_FINITE_x123_corrected_inverted_counts_to_photons] = 0.0
  ;output the data back on the input grid
  output_model_x123_corrected_inverted_counts_to_photons = DBLARR(n_x123_energy_bins_kev)
  output_model_x123_corrected_inverted_counts_to_photons[index_positive_energies] = x123_corrected_inverted_counts_to_photons
  ;Divide by he minxss x123 area
  if keyword_set(use_detector_area) then output_model_x123_corrected_inverted_counts_to_photons /= minxss_detector_response.x123_aperture_geometric_area
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;calculate uncertainties ofn the inverted photon flux
if keyword_set(uncertainty_x123_measured_counts) then begin
  uncertainty_x123_corrected_inverted_counts_to_photons = SQRT(((uncertainty_x123_measured_counts_positive*x123_corrected_count_be_photoelectron_si_escape_positive)/(x123_measured_counts_positive*final_shifted_convolve_X123_be_si_photopeak_detection_ARRAY))^(2.0))
  ;correct for negatives
  INDEX_uncertainty_x123_corrected_inverted_counts_to_photons = WHERE(uncertainty_x123_corrected_inverted_counts_to_photons LT 0.0)
  uncertainty_x123_corrected_inverted_counts_to_photons[INDEX_uncertainty_x123_corrected_inverted_counts_to_photons] = 0.0
  ;Correct for NAN's
  INDEX_FINITE_uncertainty_x123_corrected_inverted_counts_to_photons = WHERE(FINITE(uncertainty_x123_corrected_inverted_counts_to_photons, /NAN) EQ 1.0)
  uncertainty_x123_corrected_inverted_counts_to_photons[INDEX_FINITE_uncertainty_x123_corrected_inverted_counts_to_photons] = 0.0
  ;output the data back on the input grid
  output_model_uncertainty_X123_photon_estimate = DBLARR(n_x123_energy_bins_kev)
  output_model_uncertainty_X123_photon_estimate[index_positive_energies] = uncertainty_x123_corrected_inverted_counts_to_photons

  if keyword_set(use_detector_area) then output_model_uncertainty_X123_photon_estimate /= minxss_detector_response.x123_aperture_geometric_area
endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Set a flag equal to 1 if the inverted photon estimate, agrees to within 10% and of each other. 
fractional_difference_maximum_threshold = 0.10

if keyword_set(X123_inverted_valid_flag_fractional_difference_maximum_threshold) then fractional_difference_maximum_threshold = X123_inverted_valid_flag_fractional_difference_maximum_threshold


;Exclude 0's in the inverted photon flux
;be_si_photopeak
INDEX_ZERO_output_model_x123_inverted_counts_to_photons_be_si_photopeak_only = WHERE(output_model_x123_inverted_counts_to_photons_be_si_photopeak_only LE 0.0)
;Corrected
INDEX_ZERO_output_model_x123_inverted_counts_to_photons_corrected = WHERE(output_model_x123_corrected_inverted_counts_to_photons LE 0.0)
;be_photoelectron_only
INDEX_ZERO_output_model_x123_inverted_counts_to_photons_be_photoelectron_only = WHERE(output_model_x123_inverted_counts_to_photons_be_photoelectron_only LE 0.0)

;Fractional difference between the corrected and Si photopeak inverted photon flux
fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons = abs(output_model_x123_inverted_counts_to_photons_be_si_photopeak_only - output_model_x123_corrected_inverted_counts_to_photons)/output_model_x123_inverted_counts_to_photons_be_si_photopeak_only
;Get rid of NAN, and infinity, and set them equal to 1.0 -> 100% 
NAN_INDEX_fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons, /NAN) EQ 1.0)
fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons[NAN_INDEX_fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons] = 1.0
INFINITY_INDEX_fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons, /INFINITY) EQ 1.0)
fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons[INFINITY_INDEX_fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons] = 1.0

;Fractional difference between the Be photoelectron and Si photopeak inverted photon flux
fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons = abs(output_model_x123_inverted_counts_to_photons_be_si_photopeak_only - output_model_x123_inverted_counts_to_photons_be_photoelectron_only)/output_model_x123_inverted_counts_to_photons_be_si_photopeak_only
;Get rid of NAN, and infinity, and set them equal to 1.0 -> 100%
NAN_INDEX_fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons, /NAN) EQ 1.0)
fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons[NAN_INDEX_fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons] = 1.0
INFINITY_INDEX_fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons, /INFINITY) EQ 1.0)
fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons[INFINITY_INDEX_fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons] = 1.0

;Fractional difference between the corrected and Be photoelectron inverted photon flux
fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons = abs(output_model_x123_corrected_inverted_counts_to_photons - output_model_x123_inverted_counts_to_photons_be_si_photopeak_only)/output_model_x123_corrected_inverted_counts_to_photons
;Get rid of NAN, and infinity, and set them equal to 1.0 -> 100%
NAN_INDEX_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons, /NAN) EQ 1.0)
fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons[NAN_INDEX_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons] = 1.0
INFINITY_INDEX_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons = WHERE(FINITE(fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons, /INFINITY) EQ 1.0)
fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons[INFINITY_INDEX_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons] = 1.0

;INDEX_GOOD_X123_invert_count_to_photon_estimate_valid_flag = WHERE(TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons EQ TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons)
;X123_invert_count_to_photon_estimate_valid_flag = DBLARR(n_x123_energy_bins_kev)
;X123_invert_count_to_photon_estimate_valid_flag[TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons[INDEX_GOOD_X123_invert_count_to_photon_estimate_valid_flag]] = 1.0


;corrrected and photopeak
TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons = WHERE(fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons LE fractional_difference_maximum_threshold AND fractional_difference_be_photoelectron_to_si_photopeak_only_inverted_counts_to_photons LE fractional_difference_maximum_threshold)
ARRAY_TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons = DBLARR(n_x123_energy_bins_kev)
ARRAY_TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons[TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons] = 2.0
;corrected and Be photoelectrons
TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons = WHERE(fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons LE fractional_difference_maximum_threshold AND fractional_difference_corrected_to_si_photopeak_only_inverted_counts_to_photons LE fractional_difference_maximum_threshold)
ARRAY_TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons = DBLARR(n_x123_energy_bins_kev)
ARRAY_TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons[TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons] = 2.0

INDEX_GOOD_X123_invert_count_to_photon_estimate_valid_flag = WHERE(ARRAY_TEMP_INDEX_GOOD_fractional_difference_be_photoelectron_to_corrected_inverted_counts_to_photons EQ 2.0 AND ARRAY_TEMP_INDEX_GOOD_fractional_difference_si_photopeak_to_corrected_inverted_counts_to_photons EQ 2.0)
X123_invert_count_to_photon_estimate_valid_flag = DBLARR(n_x123_energy_bins_kev)
X123_invert_count_to_photon_estimate_valid_flag[INDEX_GOOD_X123_invert_count_to_photon_estimate_valid_flag] = 1.0


;remove indicies where the data is 0 or negative
X123_invert_count_to_photon_estimate_valid_flag[INDEX_ZERO_output_model_x123_inverted_counts_to_photons_be_si_photopeak_only] = 0.0
X123_invert_count_to_photon_estimate_valid_flag[INDEX_ZERO_output_model_x123_inverted_counts_to_photons_corrected] = 0.0
X123_invert_count_to_photon_estimate_valid_flag[INDEX_ZERO_output_model_x123_inverted_counts_to_photons_be_photoelectron_only] = 0.0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;return the model output signal
  return, output_model_x123_corrected_inverted_counts_to_photons


end