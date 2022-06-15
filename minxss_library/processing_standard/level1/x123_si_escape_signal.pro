

;+
; NAME:
;   x123_Si_escape_signal
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
;; PURPOSE: Estimate the si k, l (2s and 2p) escape process contributions to the x123 measured count spectrum
;
;
; CALLING SEQUENCE: result = x123_si_escape_signal, x123_energy_bins_kev(converted_energy_bins_offset_bins, detected_si_photon_flux_energy_array_keV, detected_si_photon_flux_array, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, $
;         OUTPUT_X123_detected_counts_Si_k_escape_ARRAY=output_model_X123_detected_counts_Si_k_escape_signal, OUTPUT_X123_created_counts_Si_k_escape_ARRAY=output_model_X123_created_counts_Si_k_escape_signal, $
;         OUTPUT_X123_detected_counts_Si_l_2s_escape_ARRAY=output_model_X123_detected_counts_Si_l_2s_escape_signal, OUTPUT_X123_created_counts_Si_l_2s_escape_ARRAY=output_model_X123_created_counts_Si_l_2s_escape_signal, $
;         OUTPUT_X123_detected_counts_Si_l_2p_escape_ARRAY=output_model_X123_detected_counts_Si_l_2p_escape_signal, OUTPUT_X123_created_counts_Si_l_2p_escape_ARRAY=output_model_X123_created_counts_Si_l_2p_escape_signal, $
;         OUTPUT_X123_created_counts_Si_escape_all_ARRAY=output_model_x123_si_escape_all_created)
;
; DESCRIPTION: Same as in the Purpose section
;

; INPUTS: x123 photon energy bins array (keV), x123 energy bins offset (keV), photon flux array (photons/s/keV), photon energy array (keV)

;
; INPUT KEYWORD PARAMETERS: None
;

; RETURNS: detected count spectrum contribution from all the si fluorescence escape processes mentioned above from the Si DETECTED incident photon flux (photons/s/keV), option to return the DETECTED photoelectron efficiency (counts/photon)
;;
;
;
;; Details:!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;
;
;
;;X123_energy_bins_kev:                                                          [INPUT] input X123 energy bins (ARRAY)
;converted_energy_bins_offset_bins:                                              [INPUT] Offset in keV energy bins (FLOAT)
;detected_si_photon_flux_energy_array_keV:                                       [INPUT] photon energy array of the silicon detected (si_photopeak) input photon flux (ARRAY)
;detected_si_photon_flux_array:                                                  [INPUT] silicon detected (si_photopeak) input photon flux energy array (ARRAY)
;minxss_instrument_structure_data_file:                                          [INPUT] Full path and file name of the minxss_instrument_structure_data_file (ARRAY)
;OUTPUT_X123_Photoelectron_efficiency_ARRAY:                                     [OUTPUT/RETURNED KEYWORD] DETECTED be_photoelectron efficiency
;OUTPUT_X123_detected_counts_Si_k_escape_ARRAY:                                  [OUTPUT/RETURNED KEYWORD] DETECTED counts from the si k escape process
;OUTPUT_X123_created_counts_Si_k_escape_ARRAY:                                   [OUTPUT/RETURNED KEYWORD] created counts from the si k escape process
;OUTPUT_X123_detected_counts_Si_l_2s_escape_ARRAY:                               [OUTPUT/RETURNED KEYWORD] DETECTED counts from the si l 2s escape process
;OUTPUT_X123_created_counts_Si_l_2s_escape_ARRAY:                                [OUTPUT/RETURNED KEYWORD] created counts from the si l 2s escape process
;OUTPUT_X123_detected_counts_Si_l_2p_escape_ARRAY:                               [OUTPUT/RETURNED KEYWORD] DETECTED counts from the si l 2p escape process
;OUTPUT_X123_created_counts_Si_l_2p_escape_ARRAY:                                [OUTPUT/RETURNED KEYWORD] created counts from the si l 2p escape process
;OUTPUT_X123_created_counts_Si_escape_all_ARRAY:                                 [OUTPUT/RETURNED KEYWORD] created counts from the all the si escape processes mentioned above

;
;;
; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, April, 2016, Christopher S. Moore
;   Laboratory for Atmospheric and Space Physics
;
;
;-
;-



function x123_si_escape_signal, x123_energy_bins_kev, converted_energy_bins_offset_bins, detected_si_photon_flux_energy_array_keV, detected_si_photon_flux_array, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, $
         OUTPUT_X123_detected_counts_Si_k_escape_ARRAY=output_model_X123_detected_counts_Si_k_escape_signal, OUTPUT_X123_created_counts_Si_k_escape_ARRAY=output_model_X123_created_counts_Si_k_escape_signal, $
         OUTPUT_X123_detected_counts_Si_l_2s_escape_ARRAY=output_model_X123_detected_counts_Si_l_2s_escape_signal, OUTPUT_X123_created_counts_Si_l_2s_escape_ARRAY=output_model_X123_created_counts_Si_l_2s_escape_signal, $
         OUTPUT_X123_detected_counts_Si_l_2p_escape_ARRAY=output_model_X123_detected_counts_Si_l_2p_escape_signal, OUTPUT_X123_created_counts_Si_l_2p_escape_ARRAY=output_model_X123_created_counts_Si_l_2p_escape_signal, $
         OUTPUT_X123_created_counts_Si_escape_all_ARRAY=output_model_x123_si_escape_all_created


  ; common minxss_123_multienergy_share1, ELEMENTS_ARRAY
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

  ;find the x123 gain
  gain_x123_energy_bins_kev = abs(converted_energy_bins[0] - converted_energy_bins[1])
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Restore, the minxss_detector_response_data
  ;  TW-2022:  This is very slow to Restore Cal-File 1000s of time; make COMMON BLOCK
  COMMON  minxss_detector_response_common, minxss_detector_response
  if (n_elements(minxss_detector_response) lt 1) then RESTORE, minxss_instrument_structure_data_file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Calculate the Si_escape created count deviation (count that will be removed from the initial si detected flux)
;and the actual detected si-escape shifted count flux
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
minxss_x123_energy_bins_spectral_resolution_kev_array = minxss_detector_response.photon_energy
minxss_x123_spectral_resolution_array = minxss_detector_response.x123_nominal_spectral_resolution
FIT_ENERGY_ARRAY_KeV = minxss_detector_response.photon_energy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Si k_escape
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Si_k_secape
;Interpolate to the probability the the bin space
interpol_created_si_photon_flux_array = INTERPOL(detected_si_photon_flux_array, detected_si_photon_flux_energy_array_keV, FIT_ENERGY_ARRAY_KeV)
;get rid of negatives
INDEX_interpol_created_si_photon_flux_array = WHERE(interpol_created_si_photon_flux_array LT 0.0)
interpol_created_si_photon_flux_array[INDEX_interpol_created_si_photon_flux_array] = 0.0

;Calculate the count contribution
X123_created_counts_Si_k_escape_ARRAY = minxss_detector_response.x123_si_k_escape_probability*interpol_created_si_photon_flux_array
;Shift the created counts by the photon energy offset to get the detected counts
detected_counts_si_k_escape_energy_array_keV = FIT_ENERGY_ARRAY_KeV - minxss_detector_response.x123_si_k_photon_escape_energy_keV
X123_detected_counts_Si_k_escape_ARRAY = interpol(X123_created_counts_Si_k_escape_ARRAY, detected_counts_si_k_escape_energy_array_keV, FIT_ENERGY_ARRAY_KeV, /NAN)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;convolve the signal
convolve_X123_created_counts_Si_k_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_k_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;    convolve_X123_created_counts_Si_k_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_k_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
convolve_X123_detected_counts_Si_k_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_k_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;    convolve_X123_detected_counts_Si_k_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_k_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;integrate the counts to the bins
;Bin the electrons/counts into energy space
SHIFTED_converted_energy_bins = converted_energy_bins - (0.5*gain_x123_energy_bins_kev)

;interpolate tot the shifteed energy bins
shifted_convolve_X123_created_counts_Si_k_escape_ARRAY = interpol(convolve_X123_created_counts_Si_k_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
;get rid of negatives
INDEX_shifted_convolve_X123_created_counts_Si_k_escape_ARRAY = WHERE(shifted_convolve_X123_created_counts_Si_k_escape_ARRAY LT 0.0)
shifted_convolve_X123_created_counts_Si_k_escape_ARRAY[INDEX_shifted_convolve_X123_created_counts_Si_k_escape_ARRAY] = 0.0

shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY = interpol(convolve_X123_detected_counts_Si_k_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
;get rid of negatives
INDEX_shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY = WHERE(shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY LT 0.0)
shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY[INDEX_shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY] = 0.0


;bin the counts
final_shifted_convolve_X123_created_counts_Si_k_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)
final_shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)

;Sum the counts over the shirfted energy bins
FOR t = 0, n_positive_x123_energy_bins_kev  - 2 DO BEGIN ;Sum over 1 less indix becaus of the staggered bin
  final_shifted_convolve_X123_created_counts_Si_k_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_created_counts_Si_k_escape_ARRAY[t:t+1], /DOUBLE)
  final_shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY[t:t+1], /DOUBLE)
ENDFOR
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;insert the computed response to an array of the same size as the original but with 0's for the negative energies
  output_model_X123_created_counts_Si_k_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_detected_counts_Si_k_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)

  output_model_X123_created_counts_Si_k_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_created_counts_Si_k_escape_ARRAY
  output_model_X123_detected_counts_Si_k_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_detected_counts_Si_k_escape_ARRAY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;return the for array values
  output_model_X123_created_counts_Si_k_escape_signal=output_model_X123_created_counts_Si_k_escape_ARRAY
  output_model_X123_detected_counts_Si_k_escape_signal=output_model_X123_detected_counts_Si_k_escape_ARRAY
  OUTPUT_FIT_ENERGY_ARRAY_KeV=FIT_ENERGY_ARRAY_KeV
  OUTPUT_interpol_x123_si_k_escape_probability=minxss_detector_response.x123_si_k_escape_probability
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si l_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;Si_l_2s_secape
  ;Interpolate to the probability the the bin space
  interpol_created_si_photon_flux_array = INTERPOL(detected_si_photon_flux_array, detected_si_photon_flux_energy_array_keV, FIT_ENERGY_ARRAY_KeV)
  ;get rid of negatives
  INDEX_interpol_created_si_photon_flux_array = WHERE(interpol_created_si_photon_flux_array LT 0.0)
  interpol_created_si_photon_flux_array[INDEX_interpol_created_si_photon_flux_array] = 0.0

  ;Calculate the count contribution
  X123_created_counts_Si_l_2s_escape_ARRAY = minxss_detector_response.x123_si_l_2s_escape_probability*interpol_created_si_photon_flux_array
  ;Shift the created counts by the photon energy offset to get the detected counts
  detected_counts_Si_l_2s_escape_energy_array_keV = FIT_ENERGY_ARRAY_KeV - minxss_detector_response.x123_si_l_2s_photon_escape_energy_keV
  X123_detected_counts_Si_l_2s_escape_ARRAY = interpol(X123_created_counts_Si_l_2s_escape_ARRAY, detected_counts_Si_l_2s_escape_energy_array_keV, FIT_ENERGY_ARRAY_KeV, /NAN)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;convolve the signal
  convolve_X123_created_counts_Si_l_2s_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_l_2s_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;      convolve_X123_created_counts_Si_l_2s_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_l_2s_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
  convolve_X123_detected_counts_Si_l_2s_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_l_2s_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;      convolve_X123_detected_counts_Si_l_2s_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_l_2s_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;integrate the counts to the bins
  ;Bin the electrons/counts into energy space
  SHIFTED_converted_energy_bins = converted_energy_bins - (0.5*gain_x123_energy_bins_kev)

  ;interpolate tot the shifteed energy bins
  shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY = interpol(convolve_X123_created_counts_Si_l_2s_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY = WHERE(shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY LT 0.0)
  shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY[INDEX_shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY] = 0.0

  shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY = interpol(convolve_X123_detected_counts_Si_l_2s_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY = WHERE(shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY LT 0.0)
  shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY[INDEX_shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY] = 0.0


  ;bin the counts
  final_shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)
  final_shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)

  ;Sum the counts over the shirfted energy bins
  FOR t = 0, n_positive_x123_energy_bins_kev  - 2 DO BEGIN ;Sum over 1 less indix becaus of the staggered bin
    final_shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY[t:t+1], /DOUBLE)
    final_shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY[t:t+1], /DOUBLE)
  ENDFOR
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;insert the computed response to an array of the same size as the original but with 0's for the negative energies
  output_model_X123_created_counts_Si_l_2s_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_detected_counts_Si_l_2s_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)

  output_model_X123_created_counts_Si_l_2s_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_created_counts_Si_l_2s_escape_ARRAY
  output_model_X123_detected_counts_Si_l_2s_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_detected_counts_Si_l_2s_escape_ARRAY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;return the for array values
  output_model_X123_created_counts_Si_l_2s_escape_signal=output_model_X123_created_counts_Si_l_2s_escape_ARRAY
  output_model_X123_detected_counts_Si_l_2s_escape_signal=output_model_X123_detected_counts_Si_l_2s_escape_ARRAY
  OUTPUT_FIT_ENERGY_ARRAY_KeV=FIT_ENERGY_ARRAY_KeV
  OUTPUT_interpol_x123_Si_l_2s_escape_probability=minxss_detector_response.x123_si_l_2s_escape_probability
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Si k_escape
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;Si_l_2p_secape
  ;Interpolate to the probability the the bin space
  interpol_created_si_photon_flux_array = INTERPOL(detected_si_photon_flux_array, detected_si_photon_flux_energy_array_keV, FIT_ENERGY_ARRAY_KeV)
  ;get rid of negatives
  INDEX_interpol_created_si_photon_flux_array = WHERE(interpol_created_si_photon_flux_array LT 0.0)
  interpol_created_si_photon_flux_array[INDEX_interpol_created_si_photon_flux_array] = 0.0

  ;Calculate the count contribution
  X123_created_counts_Si_l_2p_escape_ARRAY = minxss_detector_response.x123_si_l_2p_escape_probability*interpol_created_si_photon_flux_array
  ;Shift the created counts by the photon energy offset to get the detected counts
  detected_counts_Si_l_2p_escape_energy_array_keV = FIT_ENERGY_ARRAY_KeV - minxss_detector_response.x123_si_l_2p_photon_escape_energy_keV
  X123_detected_counts_Si_l_2p_escape_ARRAY = interpol(X123_created_counts_Si_l_2p_escape_ARRAY, detected_counts_Si_l_2p_escape_energy_array_keV, FIT_ENERGY_ARRAY_KeV, /NAN)

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;convolve the signal
  convolve_X123_created_counts_Si_l_2p_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_l_2p_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;      convolve_X123_created_counts_Si_l_2p_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_created_counts_Si_l_2p_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
  convolve_X123_detected_counts_Si_l_2p_escape_ARRAY = gaussfold(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_l_2p_escape_ARRAY, minxss_detector_response.x123_nominal_spectral_resolution)
;      convolve_X123_detected_counts_Si_l_2p_escape_ARRAY = gauss_variable_fwhm_convolve(FIT_ENERGY_ARRAY_KeV, X123_detected_counts_Si_l_2p_escape_ARRAY, minxss_detector_response.photon_energy, minxss_detector_response.x123_spectral_resolution_array)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;integrate the counts to the bins
  ;Bin the electrons/counts into energy space
  SHIFTED_converted_energy_bins = converted_energy_bins - (0.5*gain_x123_energy_bins_kev)

  ;interpolate tot the shifteed energy bins
  shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY = interpol(convolve_X123_created_counts_Si_l_2p_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY = WHERE(shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY LT 0.0)
  shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY[INDEX_shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY] = 0.0

  shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY = interpol(convolve_X123_detected_counts_Si_l_2p_escape_ARRAY, FIT_ENERGY_ARRAY_KeV, SHIFTED_converted_energy_bins, /NAN)
  ;get rid of negatives
  INDEX_shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY = WHERE(shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY LT 0.0)
  shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY[INDEX_shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY] = 0.0


  ;bin the counts
  final_shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)
  final_shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY = DBLARR(n_positive_x123_energy_bins_kev)

  ;Sum the counts over the shirfted energy bins
  FOR t = 0, n_positive_x123_energy_bins_kev  - 2 DO BEGIN ;Sum over 1 less indix becaus of the staggered bin
    final_shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY[t:t+1], /DOUBLE)
    final_shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY[t] = INT_TABULATED(SHIFTED_converted_energy_bins[t:t+1], shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY[t:t+1], /DOUBLE)
  ENDFOR
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;insert the computed response to an array of the same size as the original but with 0's for the negative energies
  output_model_X123_created_counts_Si_l_2p_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)
  output_model_X123_detected_counts_Si_l_2p_escape_ARRAY = DBLARR(n_x123_energy_bins_kev)

  output_model_X123_created_counts_Si_l_2p_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_created_counts_Si_l_2p_escape_ARRAY
  output_model_X123_detected_counts_Si_l_2p_escape_ARRAY[index_positive_energies] = final_shifted_convolve_X123_detected_counts_Si_l_2p_escape_ARRAY
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;return the for array values
  output_model_X123_created_counts_Si_l_2p_escape_signal=output_model_X123_created_counts_Si_l_2p_escape_ARRAY
  output_model_X123_detected_counts_Si_l_2p_escape_signal=output_model_X123_detected_counts_Si_l_2p_escape_ARRAY
  OUTPUT_FIT_ENERGY_ARRAY_KeV=FIT_ENERGY_ARRAY_KeV
  OUTPUT_interpol_x123_Si_l_2p_escape_probability=minxss_detector_response.x123_si_l_2p_escape_probability
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;the counted photon flux from the edges
  output_model_x123_si_escape_all_created = output_model_X123_created_counts_Si_k_escape_signal + output_model_X123_created_counts_Si_l_2s_escape_signal + output_model_X123_created_counts_Si_l_2p_escape_signal


  ;Calculate the total contribution from all Si K and L escape
  output_model_x123_si_escape_all_signal = output_model_X123_detected_counts_Si_k_escape_signal + output_model_X123_detected_counts_Si_l_2s_escape_signal + output_model_X123_detected_counts_Si_l_2p_escape_signal
  ;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;return the model output signal
  return, output_model_x123_si_escape_all_signal


end
