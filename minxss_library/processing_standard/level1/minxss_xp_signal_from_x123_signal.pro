

;+
; NAME:
;   minxss_XP_signal_from_X123_signal
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
; PURPOSE: Calculate the detected MinXSS xp signal (DN/s) from an input photon flux in units of photons/s/keV, derived from the inverted X123 measured count spectrum in units of counts/s/keV, /use_detector_area is set (units of cm^2)
;
;
;
; CALLING SEQUENCE: result = minxss_XP_signal_from_X123_signal(x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, $
;  output_uncertainty_XP_DN_signal_estimate_ARRAY=output_model_uncertainty_XP_DN_signal_estimate, $
;  output_XP_fC_signal_estimate_ARRAY=output_model_XP_fC_signal_estimate, $
;  output_uncertainty_XP_fC_signal_estimate_ARRAY=output_model_uncertainty_XP_fC_signal_estimate, $
;  output_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_DN_signal_estimate_be_si_photopeak_only, $
;  output_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only, $
;  output_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_fC_signal_estimate_be_si_photopeak_only, $
;  output_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only, $
;  output_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=output_model_xp_DN_signal_estimate_be_photoelectron_only, $
;  output_uncertainty_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=output_model_uncertainty_xp_DN_signal_estimate_be_photoelectron_only, $
;  output_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=output_model_xp_fC_signal_estimate_be_photoelectron_only, $
;  output_uncertainty_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=output_model_uncertainty_xp_fC_signal_estimate_be_photoelectron_only)

;
; DESCRIPTION: Converts the input photon flux (photons/s/keV/cm^2) derived from the minxss X123 measured count spectrum to MinXSS XP fC or DN with the keyword /use_detector_area is set, or (fC/cm^2) or (DN/cm^2) if keyword /use_detector_area is NOT set
;
;

; INPUTS: measured x123 count spectrum (counts/s/keV), x123 photon energy bins array (keV)

;
; INPUT KEYWORD PARAMETERS: /use_detector_area, the XP geometric aperture area, and the X123 geometric aperture area
;                           can use an alternative DN gain with the keyword, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn
;                           can out put uncertainties and contributions form different processes that contribute to the minxss spectrum

; RETURNS: estimated XP DN and/or fC (keyword) signal from the measured x123 count spectrum
;
;
; Details:!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;
;
;;X123_energy_bins_kev:                                                          [INPUT] input X123 energy bins (ARRAY)
;converted_energy_bins_offset_bins:                                              [INPUT] Offset in keV energy bins (FLOAT)
;x123_measured_counts:                                                           [INPUT] x123 measured count spectrum (ARRAY)
;counts_uncertainty                                                              [OPTIONAL INPUT] uncertainty in the x123 count spectrum (ARRAY)
;minxss_instrument_structure_data_file:                                          [INPUT] Full path and file name of the minxss_instrument_structure_data_file (ARRAY)
;use_detector_area                                                               [BOOLEAN KEYWORD] set this keyword to use the detector area in the calculation
;input_minxss_xp_gain_fC_per_dn:                                                 [INPUT/OPTIONAL KEYWORD] optinal input to use an alternative gain (fC per DN)
;output_convolve_interpol_input_photon_flux_ARRAY:                               [OUTPUT/RETURNED KEYWORD] input photon flux convolved and interpolated to the minxss x123 spectral resolution (ARRAY)
;output_uncertainty_XP_DN_signal_estimate_ARRAY:                                 [OUTPUT/RETURNED KEYWORD] uncertainty in the XP DN signal
;output_XP_fC_signal_estimate_ARRAY:                                             [OUTPUT/RETURNED KEYWORD] XP fC signal
;output_uncertainty_XP_fC_signal_estimate_ARRAY:                                 [OUTPUT/RETURNED KEYWORD] uncertainty in the XP fC signal
;output_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY:                        [OUTPUT/RETURNED KEYWORD] the XP DN signal from be_si_photopeak only
;output_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY:            [OUTPUT/RETURNED KEYWORD] uncertainty in the XP DN signal from be_si_photopeak only
;output_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY:                        [OUTPUT/RETURNED KEYWORD] the XP fc signal from be_si_photopeak only
;output_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY:            [OUTPUT/RETURNED KEYWORD] uncertainty in the XP fC signal from be_si_photopeak only
;output_xp_DN_signal_estimate_be_photoelectron_only_ARRAY:                       [OUTPUT/RETURNED KEYWORD] the XP DN signal from be_photoelectrons only
;output_uncertainty_xp_DN_signal_estimate_be_photoelectron_only_ARRAY:           [OUTPUT/RETURNED KEYWORD] uncertainty in the XP DN signal from be_ohotoelectrons only
;output_xp_fC_signal_estimate_be_photoelectron_only_ARRAY:                        [OUTPUT/RETURNED KEYWORD] the XP fC signal from be_photoelectrons only
;output_uncertainty_xp_fC_signal_estimate_be_photoelectron_only_ARRAY:            [OUTPUT/RETURNED KEYWORD] uncertainty the XP fC signal from be_photoelectrons only

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

;Estimate the XP signal (DN) form the invertd photon flux from the measured X123 counts

function minxss_XP_signal_from_X123_signal, x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose, $
                                            output_uncertainty_XP_DN_signal_estimate_ARRAY=output_model_uncertainty_XP_DN_signal_estimate, $
                                            output_XP_fC_signal_estimate_ARRAY=output_model_XP_fC_signal_estimate, $
                                            output_uncertainty_XP_fC_signal_estimate_ARRAY=output_model_uncertainty_XP_fC_signal_estimate, $
                                            output_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_DN_signal_estimate_be_si_photopeak_only, $
                                            output_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_DN_signal_estimate_be_si_photopeak_only, $
                                            output_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_xp_fC_signal_estimate_be_si_photopeak_only, $
                                            output_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only_ARRAY=output_model_uncertainty_xp_fC_signal_estimate_be_si_photopeak_only, $
                                            output_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=output_model_xp_DN_signal_estimate_be_photoelectron_only, $
                                            output_uncertainty_xp_DN_signal_estimate_be_photoelectron_only_ARRAY=output_model_uncertainty_xp_DN_signal_estimate_be_photoelectron_only, $
                                            output_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=output_model_xp_fC_signal_estimate_be_photoelectron_only, $
                                            output_uncertainty_xp_fC_signal_estimate_be_photoelectron_only_ARRAY=output_model_uncertainty_xp_fC_signal_estimate_be_photoelectron_only
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
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Invert the X123 measured signal to estimate the input photon flux
      X123_photon_estimate_ARRAY = minxss_X123_invert_count_to_photon_estimate(x123_energy_bins_kev, converted_energy_bins_offset_bins, x123_measured_counts, counts_uncertainty=uncertainty_x123_measured_counts, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file,  use_detector_area=use_detector_area, $
                                   uncertainty_X123_photon_estimate_ARRAY=uncertainty_X123_photon_estimate, $
                                   X123_photon_estimate_be_si_photopeak_only_ARRAY=x123_inverted_counts_to_photons_be_si_photopeak_only, $
                                   uncertainty_X123_photon_estimate_be_si_photopeak_only_ARRAY=uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only, $
                                   X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=x123_inverted_counts_to_photons_be_photoelectron_only, $
                                   uncertainty_X123_inverted_counts_to_photons_be_photoelectron_only_ARRAY=uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, $
                                   X123_inverted_count_to_photon_estimate_valid_flag_ARRAY=X123_invert_count_to_photon_estimate_valid_flag, $
                                   X123_inverted_valid_flag_fractional_difference_level=X123_inverted_valid_flag_fractional_difference_maximum_threshold)
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
  X123_photon_estimate_ARRAY_positive = X123_photon_estimate_ARRAY[index_positive_energies]
  ;use the positive indicies
  x123_inverted_counts_to_photons_be_si_photopeak_only_positive = x123_inverted_counts_to_photons_be_si_photopeak_only[index_positive_energies]
  x123_inverted_counts_to_photons_be_photoelectron_only_positive = x123_inverted_counts_to_photons_be_photoelectron_only[index_positive_energies]


  If KEYWORD_SET(uncertainty_x123_measured_counts) THEN BEGIN
    uncertainty_X123_photon_estimate_positive = uncertainty_X123_photon_estimate[index_positive_energies]
    uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only_positive = uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only[index_positive_energies]
    uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only_positive = uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only[index_positive_energies]
  Endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Corrected inverted photon flux
output_model_xp_DN_signal_estimate = minxss_xp_signal_estimate(converted_energy_bins, X123_photon_estimate_ARRAY_positive, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
;be_si_photopeak_only
output_model_xp_DN_signal_estimate_be_si_photopeak_only = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_si_photopeak_only_positive, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_si_photopeak_only, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
;be photoelectron_onlyoutput_model_xp_DN_signal_estimate_be_si_photopeak_only
output_model_xp_DN_signal_estimate_be_photoelectron_only = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_photoelectron_only_positive, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_photoelectron_only, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;calculate uncertatinty on the XP data

If KEYWORD_SET(uncertainty_x123_measured_counts) THEN BEGIN
  ;corrected counts
  ;high
  output_model_xp_DN_signal_estimate_high = minxss_xp_signal_estimate(converted_energy_bins, X123_photon_estimate_ARRAY_positive+uncertainty_X123_photon_estimate, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_high, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;low
  output_model_xp_DN_signal_estimate_low = minxss_xp_signal_estimate(converted_energy_bins, X123_photon_estimate_ARRAY_positive-uncertainty_X123_photon_estimate, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_low, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;DN
  Delta_output_model_xp_DN_signal_estimate = abs(output_model_xp_DN_signal_estimate_high - output_model_xp_DN_signal_estimate_low)
  output_model_uncertainty_XP_DN_signal_estimate = 0.5*Delta_output_model_xp_DN_signal_estimate
  ;fC
  Delta_output_model_xp_fC_signal_estimate = abs(output_model_xp_fC_signal_estimate_high - output_model_xp_fC_signal_estimate_low)
  output_model_uncertainty_XP_fC_signal_estimate = 0.5*Delta_output_model_xp_fC_signal_estimate

  ;be_si_photopeak_counts
  ;high
  output_model_xp_DN_signal_estimate_be_si_photopeak_only_high = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_si_photopeak_only_positive+uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only_positive, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_si_photopeak_only_high, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;low
  output_model_xp_DN_signal_estimate_be_si_photopeak_only_low = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_si_photopeak_only_positive-uncertainty_x123_inverted_counts_to_photons_be_si_photopeak_only_positive, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_si_photopeak_only_low, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;DN
  Delta_output_model_xp_DN_signal_estimate_be_si_photopeak_only = abs(output_model_xp_DN_signal_estimate_be_si_photopeak_only_high - output_model_xp_DN_signal_estimate_be_si_photopeak_only_low)
  output_model_uncertainty_XP_DN_signal_estimate_be_si_photopeak_only = 0.5*Delta_output_model_xp_DN_signal_estimate_be_si_photopeak_only
  ;fC
  Delta_output_model_xp_fC_signal_estimate_be_si_photopeak_only = abs(output_model_xp_fC_signal_estimate_be_si_photopeak_only_high - output_model_xp_fC_signal_estimate_be_si_photopeak_only_low)
  output_model_uncertainty_XP_fC_signal_estimate_be_si_photopeak_only = 0.5*Delta_output_model_xp_fC_signal_estimate_be_si_photopeak_only


  ;be_photoelectron
  ;high
  output_model_xp_DN_signal_estimate_be_photoelectron_only_high = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_photoelectron_only_positive+uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_photoelectron_only_high, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;low
  output_model_xp_DN_signal_estimate_be_photoelectron_only_low = minxss_xp_signal_estimate(converted_energy_bins, x123_inverted_counts_to_photons_be_photoelectron_only_positive-uncertainty_x123_inverted_counts_to_photons_be_photoelectron_only, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, use_detector_area=use_detector_area, output_minxss_xp_signal_fC=output_model_xp_fC_signal_estimate_be_photoelectron_only_low, input_minxss_xp_gain_fC_per_dn=input_minxss_xp_gain_fC_per_dn, verbose=verbose)
  ;DN
  Delta_output_model_xp_DN_signal_estimate_be_photoelectron_only = abs(output_model_xp_DN_signal_estimate_be_photoelectron_only_high - output_model_xp_DN_signal_estimate_be_photoelectron_only_low)
  output_model_uncertainty_XP_DN_signal_estimate_be_photoelectron_only = 0.5*Delta_output_model_xp_DN_signal_estimate_be_photoelectron_only
  ;fC
  Delta_output_model_xp_fC_signal_estimate_be_photoelectron_only = abs(output_model_xp_fC_signal_estimate_be_photoelectron_only_high - output_model_xp_fC_signal_estimate_be_photoelectron_only_low)
  output_model_uncertainty_XP_fC_signal_estimate_be_photoelectron_only = 0.5*Delta_output_model_xp_fC_signal_estimate_be_photoelectron_only
Endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;return the model output signal
  return, output_model_xp_DN_signal_estimate


end
