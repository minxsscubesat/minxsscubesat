

;+
; NAME:
;   minxss_x123_compute_ospex_fit
;
; AUTHOR:
;   Chris Moore, LASP, Boulder, CO 80303
;   christopher.moore-1@colorado.edu
;
; PURPOSE: Use the OSPEX fitting routine supplied by in the SolarSoftWare (ssw) framework and IDL package set. Perform 1T and 2T spectral fits with a fixed input abundance (coronal), a variable First Ionization Potential (FIP) element scaling or all prescribe element varied individually.
; 
; MAJOR TOPICS:
;
; CALLING SEQUENCE: result = minxss_x123_compute_ospex_fit(data_spex_specfile, data_spex_file_reader, spex_fit_class, $
;    bk_time_cd_array=bk_time_cd_array, data_spex_specfile_bk_seperate=data_spex_specfile_bk_seperate, high_energy_average_counts_entire_integration_period=high_energy_average_counts_entire_integration_period, $
;  min_minxss_spex_erange=min_minxss_spex_erange, max_minxss_spex_erange=max_minxss_spex_erange, allfree_elemental_abundance_feature_minimal_signal_to_noise=allfree_elemental_abundance_feature_minimal_signal_to_noise, $
;  spex_systematic_uncertainty=spex_systematic_uncertainty, spex_mcurvefit_itmax=spex_mcurvefit_itmax, spex_mcurvefit_quiet=spex_mcurvefit_quiet, spex_fit_manual=spex_fit_manual, spex_autoplotting=spex_autoplotting, verbose=verbose)


; DESCRIPTION: Calculate spectral fits of MinXSS X123 level 1 data using OSPEX
;

; INPUTS:
; MinXSS X123 data structure (level 1 data), prepped for OSPEX using the minxss_x123_level1_make_ospex_structure.pro procedure (data_spex_specfile), name of the MinXSS data reader procedure for OSPEX (data_spex_file_reader),  a string of the model function that is desired to be fit to the data (spex_fit_class)
; and a range of keywords. 
;
; INPUT KEYWORD PARAMETERS: /verbose, bk_time_cd_array, data_spex_specfile_bk_seperate, min_minxss_spex_erange, max_minxss_spex_erange, high_energy_average_counts_entire_integration_period, allfree_elemental_abundance_feature_minimal_signal_to_noise, $
;                           spex_systematic_uncertainty, spex_mcurvefit_itmax, /spex_mcurvefit_quiet, /spex_fit_manual, /spex_autoplotting
;                          
;
;

; RETURNS:
;
;
; Details:!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;
;
;data_spex_specfile:                                                             [INPUT] absolute path of the MinXSS X123 data structure (level 1 data) .sav file, prepped for OSPEX using the minxss_x123_level1_make_ospex_structure.pro procedure (STRING)
;data_spex_file_reader:                                                          [INPUT] name of the MinXSS data reader procedure for OSPEX (STRING)
;spex_fit_class:                                                                 [INPUT] mane of the spectral model used to fit the data, options are currently only 6, '1TCoronal', '2TCoronal', '1TFree', '2TFree', '1TAllFree', '2TAllFree'  (STRING)
;bk_time_cd_array                                                                [INPUT/OPTIONAL KEYWORD] start and end dates to be used for background incorporation, in calendar date. Example bk_time_cd_array = [[bk_start_time_cd_array], [bk_end_time_cd_array]]  =  [[09, 15, 2016, 17, 43, 55], [09, 16, 2016, 03, 22, 41]] -> September, 15 2016 at 17:43:55 UT to September 16, 2016 at 03:22:41 UT (LONG), If not set, then the spectra is fit as is.
;data_spex_specfile_bk_seperate:                                                 [INPUT/OPTIONAL KEYWORD] absolute path to previously fit MinXSS data in OSPEX that the user wants to use as a background estimate for the current input fit. bk_time_cd_array needs to be set for this keyword to function. This adds the OSPEX fit data into the fit. Must be the same spex_fit_class that is being fit with the current data set. (STRING)
;high_energy_average_counts_entire_integration_period                            [INPUT/OPTIONAL KEYWORD] optional input to change the minimum average counts in an integration period in units of counts per second (cps), Default is 2 cps (DOUBLE)
;min_minxss_spex_erange:                                                         [INPUT/OPTIONAL KEYWORD] optional input to change the minimum energy to be fit in units of keV, can be a single value or an array (ntimes) (ARRAY)
;max_minxss_spex_erange:                                                         [INPUT/OPTIONAL KEYWORD] optional input to change the maximun energy to be fit in units of keV, can be a single value or an array (ntimes) (ARRAY)
;allfree_elemental_abundance_feature_minimal_signal_to_noise:                    [INPUT/OPTIONAL KEYWORD] For the 1TAllFree or 2TAllFree fits, the individual elements can be set free autonomously. This value is the minimum signal to noise ratio averaged over 5 minxss energy bins ~0.3 keV wide. (FLOAT) Default is S/N > 10
;spex_systematic_uncertainty:                                                    [INPUT/OPTIONAL KEYWORD] fractional systematic uncertainty added in addition to the input uncertainties. (FLOAT) Default is 0.0
;spex_mcurvefit_itmax:                                                           [INPUT/OPTIONAL KEYWORD] maximum number of iterations for MP curvefit (FLOAT)
;spex_mcurvefit_quiet:                                                           [BOOLEAN KEYWORD] if set (1) THEN mpCURVEFIT will be 'quiet', Default is 0 (Integer)
;spex_fit_manual:                                                                [BOOLEAN KEYWORD] If set (1) then the OSPEX GUI is initiated to fit each time interval manually
;spex_autoplotting:                                                              [BOOLEAN KEYWORD] If set (1) then the fits results for each time interval are displayed, if set to (0) then it is not.
;verbose:                                                                        [BOOLEAN KEYWORD] If set (1) then all information will be plotted



; REFERENCES:
;
; MODIFICATION HISTORY:
;   Written, July 15, 2017, Christopher S. Moore
;   Laboratory for Atmospheric and Space Physics
;
;
;-
;-
function minxss_x123_compute_ospex_fit,  data_spex_specfile, data_spex_file_reader, spex_fit_class, $
  bk_time_cd_array=bk_time_cd_array,  data_spex_specfile_bk_seperate=data_spex_specfile_bk_seperate, high_energy_average_counts_entire_integration_period=high_energy_average_counts_entire_integration_period, $
  min_minxss_spex_erange=min_minxss_spex_erange, max_minxss_spex_erange=max_minxss_spex_erange, allfree_elemental_abundance_feature_minimal_signal_to_noise=allfree_elemental_abundance_feature_minimal_signal_to_noise, $
  spex_systematic_uncertainty=spex_systematic_uncertainty, spex_mcurvefit_itmax=spex_mcurvefit_itmax, spex_mcurvefit_quiet=spex_mcurvefit_quiet, spex_fit_manual=spex_fit_manual, spex_autoplotting=spex_autoplotting, verbose=verbose
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;list the input for the ospex fitting routine using anyspecfile
  ;use the latest (version 8) Chianti line list
  ;supply the full file path to the chianti continuum and line files to be used in spectral fitting
  setenv, 'Chianti_cont_file=C:'+path_sep()+'ssw'+path_sep()+'packages'+path_sep()+'xray'+path_sep()+'dbase'+path_sep()+'chianti'+path_sep()+'chianti_setup_cont_01_30_v8_5MK_8MK.geny'
  setenv, 'chianti_lines_file=C:'+path_sep()+'ssw'+path_sep()+'packages'+path_sep()+'xray'+path_sep()+'dbase'+path_sep()+'chianti'+path_sep()+'chianti_lines_01_30_v8_5MK_8MK.sav'

  ;initiate the ospex object without the gui, unless keyword manual is set (/manual)
  o=ospex(/no_gui) ; or  ospex_proc, o, /no_
  ;o = ospex()

  ;set the name of the minxss data reader procedure
  ;o->set, spex_file_reader='xxx'
  o->set, spex_file_reader=data_spex_file_reader

  ;set the data file absolute path to read in
  ;o->set,spex_specfile='yourspectrumfile.yyy'
  o->set,spex_specfile=data_spex_specfile

  ;No seperate drm file call is needed right now. It is currently called in the spex_file_reader procedure
  ;o->set, spex_drmfile='yourdrmfile.yyy'

  ;resture the data file (currently only in the .sav format) to compute various aspects
  restore, data_spex_specfile

 if keyword_set(data_spex_specfile_bk_seperate) then begin
   ;resture the bk ospex structure fit previously. the data file (currently only in the .sav format)
   restore, data_spex_specfile_bk_seperate
   minxss_pre_fit_bk_function_data_structure = minxss_test_function_data_structure
 endif
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;set the background intervals
  if keyword_set(bk_time_cd_array) then begin

    ; set the start and end times in jd for the MinXSS-1 mission
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;choose the time frame if interest to plot
    ;define the index positions
    index_month = 0
    index_day = 1
    index_year = 2
    index_hour = 3
    index_minute = 4
    index_second = 5
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;choose the time frame if interest to plot
    ;;result = julday(month, day, year, hour, minute, second)
    ;; start time example = june 9, 2016, 00:00:00 ut
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; end time = april 25, 2017, 23:59:59 ut
    if keyword_set(bk_time_cd_array) then begin
      bk_start_time_jd = julday(bk_time_cd_array[index_month,0], bk_time_cd_array[index_day,0], bk_time_cd_array[index_year,0], bk_time_cd_array[index_hour,0], bk_time_cd_array[index_minute,0], bk_time_cd_array[index_second,0])
      ;    if bk_start_time_jd lt bk_start_time_jd_nominal then print, '!!Warning - start time is earlier than any MinXSS data!!!
    endif
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if keyword_set(bk_time_cd_array) then begin
      bk_end_time_jd = julday(bk_time_cd_array[index_month,1], bk_time_cd_array[index_day,1], bk_time_cd_array[index_year,1], bk_time_cd_array[index_hour,1], bk_time_cd_array[index_minute,1], bk_time_cd_array[index_second,1])
      ;    if bk_end_time_jd lt bk_end_time_jd_nominal then print, '!!Warning - end time is later than any MinXSS data!!!
    endif
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    if bk_start_time_jd gt bk_end_time_jd then print, '!! ERROR !! start time is later than end time!!!'
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seconds_between_19790101_19800106 = (60.0*60.0*24.0*365.0) + (60.0*60.0*24.0*5.0)
    ;convert time from seconds since 1980/01/06 to seconds from 1979/01/01 which is needed for the correct time in ospex
    ;  utc_edges_minxss_time_array = gps2utc(transpose([[minxss_data_structure[0].time.spacecraftgpsformat], [minxss_data_structure[n_datatimes_per_structure-1].time.spacecraftgpsformat]]))

    bk_start_time_gps = jd2gps(bk_start_time_jd)
    bk_end_time_gps = jd2gps(bk_end_time_jd)
    bk_start_time_utc = gps2utc(bk_start_time_gps)
    bk_end_time_utc = gps2utc(bk_end_time_gps)
    bk_start_time_ut = bk_start_time_utc + seconds_between_19790101_19800106
    bk_end_time_ut = bk_end_time_utc + seconds_between_19790101_19800106

    index_bk_time_ut_minxss_structure_data = where((minxss_x123_ospex_structure.ut_edges[0] ge bk_start_time_ut) and (minxss_x123_ospex_structure.ut_edges[1] le bk_end_time_ut), n_bk,  COMPLEMENT=index_fit_time_ut_minxss_structure_data, NCOMPLEMENT=n_times_MinXSS_Fit)
  endif else begin
    n_times_MinXSS_Fit = n_elements(reform(minxss_x123_ospex_structure.ut_edges[0]))
    index_fit_time_ut_minxss_structure_data = indgen(n_times_MinXSS_Fit, /LONG)
  endelse
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  n_all_times_MinXSS_Fit = n_elements(reform(minxss_x123_ospex_structure.ut_edges[0]))
  n_minxss_native_energy_bins = n_elements(minxss_x123_ospex_structure[0].energy_bins)
  nominal_minxss_energy_bin_width = abs(minxss_x123_ospex_structure[0].energy_bins[0] - minxss_x123_ospex_structure[0].energy_bins[1])

  ;find the maximum energy renge to fit automatically based on the data
  ;set the minimum average countrate
  if keyword_set(high_energy_average_counts_entire_integration_period) then begin
    minxss_average_counts_entire_integration_period = high_energy_average_counts_entire_integration_period
  endif else begin
    ;default is 2 counts per entire integration period
    minxss_average_counts_entire_integration_period = 2.E0
  endelse

  ;set the number of bins to average the signal over to estimate the E mas to fit vs. energy
  n_minxss_energy_bins_average = 10.0
  ;minxss_average_count_rate_entire_period = n_minxss_energy_bins_average*(minxss_average_counts_entire_integration_period/minxss_x123_ospex_structure.integration_time)
  minxss_average_count_rate_entire_period = (minxss_average_counts_entire_integration_period/minxss_x123_ospex_structure.integration_time)

  ;find the energy bin that satisfy the minimum average count criteria
  ;create the array
  summed_count_rate_array = dblarr(n_minxss_native_energy_bins, n_all_times_MinXSS_Fit)

  for w = 0, n_all_times_MinXSS_Fit - 1 do begin
    for p = 0, n_minxss_native_energy_bins - n_minxss_energy_bins_average - 1 do begin
      summed_count_rate_array[p,w] = minxss_x123_ospex_structure[w].count_rate[p]
      if n_minxss_energy_bins_average gt 1.0 then begin
        summed_count_rate_array[p,w] = mean(minxss_x123_ospex_structure[w].count_rate[p:(p+(n_minxss_energy_bins_average-1))], /double, /nan)
      endif
    endfor
  endfor

  ;find the leftmost index that satisfies the minxss_average_counts_entire_integration_period criteria over the summed_count_rate_array
  min_index_summed_count_rate_array_minxss_average_count_rate_entire_period = dblarr(n_all_times_MinXSS_Fit)
  max_index_summed_minxss_x123_nominal_energy_bin_kev_value = dblarr(n_all_times_MinXSS_Fit)
  ;estimated Minxss energy bin offset
  estimated_minxss_energy_min_offset_kev = -0.15

  for w = 0, n_all_times_MinXSS_Fit - 1 do begin
    ;  min_index_summed_count_rate_array_minxss_average_count_rate_entire_period[w] = max(where(summed_count_rate_array[*,w] ge minxss_average_count_rate_entire_period[w])) + n_minxss_energy_bins_average
    min_index_summed_count_rate_array_minxss_average_count_rate_entire_period[w] = max(where(summed_count_rate_array[*,w] ge minxss_average_count_rate_entire_period[w]))

    ;  max_index_summed_minxss_x123_nominal_energy_bin_kev_value[w] = minxss_x123_ospex_structure[w].energy_bins[min_index_summed_count_rate_array_minxss_average_count_rate_entire_period[w]] + estimated_minxss_energy_min_offset_kev
    max_index_summed_minxss_x123_nominal_energy_bin_kev_value[w] = minxss_x123_ospex_structure[w].energy_bins[min_index_summed_count_rate_array_minxss_average_count_rate_entire_period[w]]
  endfor


  Minxss_spex_erange = dblarr(2,n_all_times_MinXSS_Fit)
  ;low energy_limit
  if keyword_set(min_minxss_spex_erange) then begin
    Minxss_spex_erange[0,*] = min_minxss_spex_erange
  endif else begin
    Minxss_spex_erange[0,*] = 0.93
  endelse

  ;high energy_limit
  if keyword_set(max_minxss_spex_erange) then begin
    Minxss_spex_erange[1,*] = max_minxss_spex_erange
  endif else begin
    ;if a specified value is not passed in, the high energy value for fitting is determined automatically
    Minxss_spex_erange[1,*] = max_index_summed_minxss_x123_nominal_energy_bin_kev_value
  endelse

  ;set the function class to fit, if a class is not chossen 1Tcoronal is the default
  if keyword_set(spex_fit_class) then begin
    minxss_fit_class = spex_fit_class
  endif else begin
    minxss_fit_class = '1TCoronal'
  endelse

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if (minxss_fit_class eq '1TAllFree') or (minxss_fit_class eq '2TAllFree') then begin

    ;Find the energy bin grouping for a minimum count rate to decide if particular elements are allowed to be set free and fit in the 1TFree and 2TFree spectral models
    n_minxss_energy_bins_abundance = 10.0

    ;calculate the signal to noise per bin
    if keyword_set(allfree_elemental_abundance_feature_minimal_signal_to_noise) then begin
      minimal_signal_to_noise = allfree_elemental_abundance_feature_minimal_signal_to_noise
    endif else begin
      ;default signal to noise to fit an element (from the measured element's spectral feature is currently 5
      minimal_signal_to_noise = 5.0
;      minimal_signal_to_noise = 10.0
    endelse

    signal_to_noise_array = dblarr(n_minxss_native_energy_bins, n_all_times_MinXSS_Fit)
    ;Calculate the signal to noise
    for w = 0, n_times_MinXSS_Fit - 1 do begin
      for p = 0, n_minxss_native_energy_bins - 1 do begin
        signal_to_noise_array[p,index_fit_time_ut_minxss_structure_data[w]] = minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[w]].count_rate[p]/minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[w]].uncertainty_count_rate[p]
      endfor
    endfor

    ;create the mean signal to noise array
    mean_signal_to_noise_array_abundance = dblarr(n_minxss_native_energy_bins, n_all_times_MinXSS_Fit)

    for w = 0, n_times_MinXSS_Fit - 1 do begin
      for p = 0, n_minxss_native_energy_bins - n_minxss_energy_bins_abundance - 1 do begin
        mean_signal_to_noise_array_abundance[p,index_fit_time_ut_minxss_structure_data[w]] = signal_to_noise_array[p,index_fit_time_ut_minxss_structure_data[w]]
        if n_minxss_energy_bins_abundance gt 1.0 then begin
          mean_signal_to_noise_array_abundance[p,index_fit_time_ut_minxss_structure_data[w]] = mean(signal_to_noise_array[p:(p+(n_minxss_energy_bins_abundance-1)),index_fit_time_ut_minxss_structure_data[w]], /double, /nan)
        endif
      endfor
    endfor


    ;set which elements are free and not free automatically, based on the data
    ;Fe and Ni have line complexes near 0.9 - 1.2 keV and higher, depending on the plasma temperature, so it will always be set free. The re is also an fe line complex near 6.7 keV and an Fe Ni complex near 8.1 keV
    free_Fe_Ni = lonarr(n_all_times_MinXSS_Fit)

    free_Ca = lonarr(n_all_times_MinXSS_Fit)
    ;features are near 3.9 keV
    min_energy_keV_Ca = 3.8
    index_energy_bins_kev_near_ca = min(where((minxss_x123_ospex_structure.energy_bins + estimated_minxss_energy_min_offset_kev) ge min_energy_keV_Ca))

    free_S = lonarr(n_all_times_MinXSS_Fit)
    ;features near 2.2 - 2.3 keV
    min_energy_keV_S = 2.1
    index_energy_bins_kev_near_S = min(where((minxss_x123_ospex_structure.energy_bins + estimated_minxss_energy_min_offset_kev) ge min_energy_keV_S))

    free_Mg = lonarr(n_all_times_MinXSS_Fit)
    ;features near 1.3 - 1.5 keV
    min_energy_keV_Mg = 1.25
    index_energy_bins_kev_near_Mg = min(where((minxss_x123_ospex_structure.energy_bins + estimated_minxss_energy_min_offset_kev) ge min_energy_keV_Mg))

    free_SI = lonarr(n_all_times_MinXSS_Fit)
    ;features near 1.8 - 1.9 keV
    min_energy_keV_Si = 1.7
    index_energy_bins_kev_near_Si = min(where((minxss_x123_ospex_structure.energy_bins + estimated_minxss_energy_min_offset_kev) ge min_energy_keV_Si))

    free_Ar = lonarr(n_all_times_MinXSS_Fit)
    ;features near 3.0 - 3.1 keV
    min_energy_keV_Ar = 2.9
    index_energy_bins_kev_near_Ar = min(where((minxss_x123_ospex_structure.energy_bins + estimated_minxss_energy_min_offset_kev) ge min_energy_keV_Ar))

    ;there is no one feature for He_C_N_O_F_Ne_Na_Al_K, it is mostly the free-free continuum, which is SLIGHTLY effected by the abundance of these high FIP elements
    free_He_C_N_O_F_Ne_Na_Al_K = lonarr(n_all_times_MinXSS_Fit)


    ;free_Fe_Ni
    ;because of features near 1.1 keV, it is always set free,
    free_Fe_Ni[*] = 1

    for w = 0, n_times_MinXSS_Fit - 1 do begin
      ;free_Ca
      if (Minxss_spex_erange[1,index_fit_time_ut_minxss_structure_data[w]] gt (min_energy_keV_Ca + (0.5*n_minxss_energy_bins_abundance*nominal_minxss_energy_bin_width))) and (mean_signal_to_noise_array_abundance[index_energy_bins_kev_near_ca,index_fit_time_ut_minxss_structure_data[w]] ge minimal_signal_to_noise) then begin
        free_Ca[index_fit_time_ut_minxss_structure_data[w]] = 1
      endif else begin
        free_Ca[index_fit_time_ut_minxss_structure_data[w]] = 0
      endelse

      ;free_S
      if (Minxss_spex_erange[1,index_fit_time_ut_minxss_structure_data[w]] gt (min_energy_keV_S + (0.5*n_minxss_energy_bins_abundance*nominal_minxss_energy_bin_width))) and (mean_signal_to_noise_array_abundance[index_energy_bins_kev_near_S,index_fit_time_ut_minxss_structure_data[w]] ge minimal_signal_to_noise) then begin
        free_S[index_fit_time_ut_minxss_structure_data[w]] = 1
      endif else begin
        free_S[index_fit_time_ut_minxss_structure_data[w]] = 0
      endelse

      ;free_Mg
      if (Minxss_spex_erange[1,index_fit_time_ut_minxss_structure_data[w]] gt (min_energy_keV_Mg + (0.5*n_minxss_energy_bins_abundance*nominal_minxss_energy_bin_width))) and (mean_signal_to_noise_array_abundance[index_energy_bins_kev_near_Mg,index_fit_time_ut_minxss_structure_data[w]] ge minimal_signal_to_noise) then begin
        free_Mg[index_fit_time_ut_minxss_structure_data[w]] = 1
      endif else begin
        free_Mg[index_fit_time_ut_minxss_structure_data[w]] = 0
      endelse

      ;free_Si
      if (Minxss_spex_erange[1,index_fit_time_ut_minxss_structure_data[w]] gt (min_energy_keV_Si + (0.5*n_minxss_energy_bins_abundance*nominal_minxss_energy_bin_width))) and (mean_signal_to_noise_array_abundance[index_energy_bins_kev_near_Si,index_fit_time_ut_minxss_structure_data[w]] ge minimal_signal_to_noise) then begin
        free_Si[index_fit_time_ut_minxss_structure_data[w]] = 1
      endif else begin
        free_Si[index_fit_time_ut_minxss_structure_data[w]] = 0
      endelse

      ;free_Ar
      if (Minxss_spex_erange[1,index_fit_time_ut_minxss_structure_data[w]] gt (min_energy_keV_Ar + (0.5*n_minxss_energy_bins_abundance*nominal_minxss_energy_bin_width))) and (mean_signal_to_noise_array_abundance[index_energy_bins_kev_near_Ar,index_fit_time_ut_minxss_structure_data[w]] ge minimal_signal_to_noise) then begin
        free_Ar[index_fit_time_ut_minxss_structure_data[w]] = 1
      endif else begin
        free_Ar[index_fit_time_ut_minxss_structure_data[w]] = 0
      endelse
    endfor

    ;due to tested lack of sensitivity to the nominal MinXSS-1 spectrum, free_He_C_N_O_F_Ne_Na_Al_K is always set fixed, free_He_C_N_O_F_Ne_Na_Al_K = 0
    free_He_C_N_O_F_Ne_Na_Al_K[*] = 0
  endif
  ;
  ;
  ;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;perform fits with a pre-ospex fit background added to the spectral fits vs. subtracting the background
if keyword_set(data_spex_specfile_bk_seperate) then begin

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Do the initial fit to create the structure to replicate
  print, 'Do initial fit to set the data structure'
  print, 'Fitting spex_class = ', minxss_fit_class

  o->set, spex_fit_time_interval= [minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[0]].ut_edges]
  o->set, spex_erange=Minxss_spex_erange[*,index_fit_time_ut_minxss_structure_data[0]]; Energy range(s) to fit over (2,n). Units: keV
  ;o->set, spex_fit_auto_emax_thresh=1.0 ;Float,  Threshold for #counts/bin for automatically setting upper limit of energy range to fit.  Units: counts/bin
  o->set, spex_fit_auto_emin=0;Flag, If set, automatically set lower limit of energy range to fit (only applies to RHESSI) , Option: 0 or 1
  o->set, spex_fit_auto_erange=0;Flag, If set, automatically set upper limit of energy range to fit . Option: 0 or 1

  ;1TCoronal
  if minxss_fit_class eq '1TCoronal' then begin
    o->set, fit_function='gain_mod+vth+vth' ;Pointer,  Fit function used
    o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
       minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
        minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters
    o->set, fit_comp_free = [0, 1, 1 ,1 ,0, $
      0 ,0 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
    o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., $
       1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
    o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, $
      1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
    o->set, fit_comp_spectrum=['', 'full', $
      'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
    o->set, fit_comp_model=['', 'chianti', $
       'chianti'] ;String, Fit function model, Options:chianti / mewe
  endif

  ;2TCoronal
  if minxss_fit_class eq '2TCoronal' then begin
    o->set, fit_function='gain_mod+2vth+2vth' ;Pointer,  Fit function used
    o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters] ;Pointer, Fit function parameters
    o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,0, $
      1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
    o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., $
      1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
    o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01, $
      1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
    o->set, fit_comp_spectrum=['', 'full', $
      'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
    o->set, fit_comp_model=['', 'chianti', $
      'chianti'] ;String, Fit function model, Options:chianti / mewe
  endif

      ;1TFree
      if minxss_fit_class eq '1TFree' then begin
        o->set, fit_function='gain_mod+vth+vth' ;Pointer,  Fit function used
    o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
       minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
        minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters
    o->set, fit_comp_free = [0, 1, 1 ,1 ,1, $
      0 ,0 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
    o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., $
       1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
    o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, $
      1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
    o->set, fit_comp_spectrum=['', 'full', $
      'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
    o->set, fit_comp_model=['', 'chianti', $
       'chianti'] ;String, Fit function model, Options:chianti / mewe
  endif

      ;2TFree
      if minxss_fit_class eq '2TFree' then begin
        o->set, fit_function='gain_mod+2vth+2vth' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,1, $
          1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., $
           1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01, $
           1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum=['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model=['', 'chianti', $
          'chianti'] ;String, Fit function model, Options:chianti / mewe
      endif

      ;1TAllFree
      if minxss_fit_class eq '1TAllFree' then begin
        o->set, fit_function='gain_mod+vth_abun+vth_abun' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_FE_NI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_CA_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_S_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_MG_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_SI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_AR_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_HE_C_N_O_F_NE_NA_AL_K_MULTIPLIER]] ;Pointer, Fit function parameters

        o->set, fit_comp_free = [0, 1, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[0]], free_Ca[index_fit_time_ut_minxss_structure_data[0]], free_S[index_fit_time_ut_minxss_structure_data[0]], free_Mg[index_fit_time_ut_minxss_structure_data[0]], free_Si[index_fit_time_ut_minxss_structure_data[0]], free_Ar[index_fit_time_ut_minxss_structure_data[0]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[0]], $
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10., $
          1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, $
          1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum= ['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model= ['', 'chianti', $
          'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
      endif

      ;2TAllFree
      if minxss_fit_class eq '2TAllFree' then begin
        o->set, fit_function='gain_mod+2vth_abun+2vth_abun' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_FE_NI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_CA_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_S_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_MG_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_SI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_AR_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_HE_C_N_O_F_NE_NA_AL_K_MULTIPLIER]] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1, 1, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[0]], free_Ca[index_fit_time_ut_minxss_structure_data[0]], free_S[index_fit_time_ut_minxss_structure_data[0]], free_Mg[index_fit_time_ut_minxss_structure_data[0]], free_Si[index_fit_time_ut_minxss_structure_data[0]], free_Ar[index_fit_time_ut_minxss_structure_data[0]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[0]], $
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10., $
        1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, $
           1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum= ['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model= ['', 'chianti', $
           'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
      endif
  if keyword_set(spex_systematic_uncertainty) then begin
    o->set, spex_uncert = spex_systematic_uncertainty
  endif else begin
    o->set, spex_uncert = 0.0 ;Float, Systematic Uncertainty
  endelse

  o->set, spex_error_use_expected=1 ;Flag,  If set, use expected counts to calc error. Options: 0 or 1

  if keyword_set(spex_mcurvefit_itmax) then begin
    o->set, mcurvefit_itmax = spex_mcurvefit_itmax
  endif else begin
    o->set, mcurvefit_itmax = 50 ;Byte  Maximum number of iterations in mcurvefit fit
  endelse

  if keyword_set(spex_mcurvefit_quiet) then begin
    o->set, mcurvefit_quiet = spex_mcurvefit_quiet
  endif else begin
    o->set, mcurvefit_quiet = 0 ;Flag, 0/1 quiet/verbose during mcurvefit
  endelse

  o->set, spex_allow_diff_energy = 1 ;Flag, If set, allow saved (spex_summ) energy values to differ from data energies , Values 0 or 1
  o->set, spex_fit_reverse=0 ; Interval Loop direction, 0 = forward, 1 = reverse
  o->set, spex_fit_start_method='previous_int' ;String, Method for getting starting params for fit after first interval, Options: default / previous_int / previous_start / previous_iter

  if keyword_set(spex_fit_manual) then begin
    o->set, spex_fit_manual = spex_fit_manual
  endif else begin
    o->set, spex_fit_manual=0 ;0=automatic, 1=manual on first interval, 2=manual on all intervals
  endelse

  if keyword_set(spex_autoplotting) then begin
    o->set, spex_autoplot_enable = spex_autoplotting
  endif else begin
    o->set, spex_autoplot_enable=1; Flag, If set, automatically plot after fitting , Options: 0 or 1
  endelse

  o->set, spex_fit_progbar=1 ;Flag, If set, show progress bar during fit loop through intervals. Options: 0 or 1
  o->set, spex_autoplot_bksub=1 ;Flag, If set, plot data-bk, not data with bk in autoplot. Options: 0 or 1
  o->set, spex_autoplot_enable=1 ;Flag, If set, automatically plot after fitting. Options: 0 or 1
  o->set, spex_autoplot_overlay_back=1 ;Flag, If set, overlay bk in autoplot. Options: 0 or 1
  o->set, spex_autoplot_overlay_bksub=0 ;Flag, If set, overlay data-bk in autoplot. Options: 0 or 1
  o->set, spex_autoplot_photons=0 ;Flag, If set, plot in photon space in autoplot. Options: 0 or 1
  o->set, spex_autoplot_show_err=1 ;Flag, If set, show error bars in autoplot. Options: 0 or 1
  o->set, spex_autoplot_units='rate' ;String, Units for autoplot ("counts", "rate", "flux"). Options: "counts", "rate", "flux"

  if keyword_set(spex_autoplotting) then begin
    o->set, spex_fitcomp_autoplot_enable = spex_autoplotting
  endif else begin
    o->set, spex_fitcomp_autoplot_enable=1 ;Flag, If set, autoplot in FITCOMP widget after any change . Options: 0 or 1
  endelse

  o->set, spex_fitcomp_plot_resid=1; Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
  o->set, spex_fitcomp_plot_bk=0 ;Flag, If set, overlay bk on plot in FITCOMP widget . Options: 0 or 1
  o->set, spex_fitcomp_plot_err=1 ;Flag, If set, show errors on plot in FITCOMP widget. Options: 0 or 1
  o->set, spex_fitcomp_plot_photons=0 ;Flag, If set, plot in photon space in FITCOMP widget. Options: 0 or 1
  o->set, spex_fitcomp_plot_resid=1 ;Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
  o->set, spex_fitcomp_plot_units='rate' ;String, Units for plot in FITCOMP widget . Options: counts / rate / flux

;  if keyword_set(bk_time_cd_array) then begin
;    o->set, spex_bk_eband = [Minxss_spex_erange[*,index_bk_time_ut_minxss_structure_data]] ;Energy bands for background if spex_bk_sep is set
;    o->set, spex_bk_poisson_error=0 ;Flag, If set, bk data errors are sqrt(counts). Otherwise errors are averaged. Options: 0 or 1
;    o->set, spex_bk_sep=1 ;Flag, If set, separate background for different energy bands. Options: 0 or 1
;    o->set, spex_bk_time_interval=[minxss_x123_ospex_structure[index_bk_time_ut_minxss_structure_data].ut_edges] ;Pointer, Units for plot in FITCOMP widget . Options: counts / rate / flux
;  endif

  o->dofit, /all        ; this will bring up the xfit_comp widget since spex_fit_manual=1
  ; o->xfitview ;bring up GUI to interactively view the fit results.
  minxss_ospex_structure_output_0 = o -> get(/spex_summ)
  ;reset the ospex parameters
  o->init_params
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if n_times_MinXSS_Fit gt 1 then begin
    ;replicate the structure for the full temporal fits
    minxss_ospex_structure_output = replicate(minxss_ospex_structure_output_0, n_times_MinXSS_Fit)
    ;start the loop for the fit
    for w = 0, n_times_MinXSS_Fit - 1 do begin
      print, 'Performing actual data fit!'
      print, 'Fitting spex_class = ', minxss_fit_class

      ;as a test set verbose = 1
      verbose = 1
      if keyword_set(verbose) then print, 'interval # = ', w
      o->set, spex_fit_time_interval= [minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[w]].ut_edges]
      o->set, spex_erange=Minxss_spex_erange[*,index_fit_time_ut_minxss_structure_data[w]]; Energy range(s) to fit over (2,n). Units: keV
      ;o->set, spex_fit_auto_emax_thresh=1.0 ;Float,  Threshold for #counts/bin for automatically setting upper limit of energy range to fit.  Units: counts/bin
      o->set, spex_fit_auto_emin=0;Flag, If set, automatically set lower limit of energy range to fit (only applies to RHESSI) , Option: 0 or 1
      o->set, spex_fit_auto_erange=0;Flag, If set, automatically set upper limit of energy range to fit . Option: 0 or 1

  ;1TCoronal
  if minxss_fit_class eq '1TCoronal' then begin
    o->set, fit_function='gain_mod+vth+vth' ;Pointer,  Fit function used
    o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
       minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
        minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters
    o->set, fit_comp_free = [0, 1, 1 ,1 ,0, $
      0 ,0 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
    o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., $
       1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
    o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, $
      1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
    o->set, fit_comp_spectrum=['', 'full', $
      'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
    o->set, fit_comp_model=['', 'chianti', $
       'chianti'] ;String, Fit function model, Options:chianti / mewe
  endif


      ;2TCoronal
      if minxss_fit_class eq '2TCoronal' then begin
        o->set, fit_function='gain_mod+2vth+2vth' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,0, $
          1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., $
           1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01, $
           1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum=['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model=['', 'chianti', $
          'chianti'] ;String, Fit function model, Options:chianti / mewe
      endif

      ;1TFree
      if minxss_fit_class eq '1TFree' then begin
        o->set, fit_function='gain_mod+vth+vth' ;Pointer,  Fit function used
    o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., $
      minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
       minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
        minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters
    o->set, fit_comp_free = [0, 1, 1 ,1 ,1, $
      0 ,0 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
    o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., $
       1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
    o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, $
      1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
    o->set, fit_comp_spectrum=['', 'full', $
      'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
    o->set, fit_comp_model=['', 'chianti', $
       'chianti'] ;String, Fit function model, Options:chianti / mewe
  endif

      ;2TFree
      if minxss_fit_class eq '2TFree' then begin
        o->set, fit_function='gain_mod+2vth+2vth' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.index_fip_multiplier]] ;Pointer, Fit function parameters] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,1, $
          1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., $
           1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01, $
           1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum=['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model=['', 'chianti', $
          'chianti'] ;String, Fit function model, Options:chianti / mewe
      endif

      ;1TAllFree
      if minxss_fit_class eq '1TAllFree' then begin
        o->set, fit_function='gain_mod+vth_abun+vth_abun' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_FE_NI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_CA_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_S_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_MG_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_SI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_AR_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_HE_C_N_O_F_NE_NA_AL_K_MULTIPLIER]] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[w]], free_Ca[index_fit_time_ut_minxss_structure_data[w]], free_S[index_fit_time_ut_minxss_structure_data[w]], free_Mg[index_fit_time_ut_minxss_structure_data[w]], free_Si[index_fit_time_ut_minxss_structure_data[w]], free_Ar[index_fit_time_ut_minxss_structure_data[w]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[w]], $
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10., $
          1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, $
          1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum= ['', 'full', $
           'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model= ['', 'chianti', $
          'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
      endif

      ;2TAllFree
      if minxss_fit_class eq '2TAllFree' then begin
        o->set, fit_function='gain_mod+2vth_abun+2vth_abun' ;Pointer,  Fit function used
        o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1., $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T1], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_VEM2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_T2], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_FE_NI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_CA_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_S_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_MG_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_SI_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_AR_MULTIPLIER], $
          minxss_pre_fit_bk_function_data_structure.results_structure.SPEX_SUMM_PARAMS[minxss_pre_fit_bk_function_data_structure.info_structure.INDEX_HE_C_N_O_F_NE_NA_AL_K_MULTIPLIER]] ;Pointer, Fit function parameters
        o->set, fit_comp_free = [0, 1, 1, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[w]], free_Ca[index_fit_time_ut_minxss_structure_data[w]], free_S[index_fit_time_ut_minxss_structure_data[w]], free_Mg[index_fit_time_ut_minxss_structure_data[w]], free_Si[index_fit_time_ut_minxss_structure_data[w]], free_Ar[index_fit_time_ut_minxss_structure_data[w]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[w]], $
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
        o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10., $
        1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
        o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, $
           1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
        o->set, fit_comp_spectrum= ['', 'full', $
          'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
        o->set, fit_comp_model= ['', 'chianti', $
           'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
      endif

      if keyword_set(spex_systematic_uncertainty) then begin
        o->set, spex_uncert = spex_systematic_uncertainty
      endif else begin
        o->set, spex_uncert = 0.0 ;Float, Systematic Uncertainty
      endelse

      o->set, spex_error_use_expected=1 ;Flag,  If set, use expected counts to calc error. Options: 0 or 1

      if keyword_set(spex_mcurvefit_itmax) then begin
        o->set, mcurvefit_itmax = spex_mcurvefit_itmax
      endif else begin
        o->set, mcurvefit_itmax = 50 ;Byte  Maximum number of iterations in mcurvefit fit
      endelse

      if keyword_set(spex_mcurvefit_quiet) then begin
        o->set, mcurvefit_quiet = spex_mcurvefit_quiet
      endif else begin
        o->set, mcurvefit_quiet = 0 ;Flag, 0/1 quiet/verbose during mcurvefit
      endelse

      o->set, spex_allow_diff_energy = 1 ;Flag, If set, allow saved (spex_summ) energy values to differ from data energies , Values 0 or 1
      o->set, spex_fit_reverse=0 ; Interval Loop direction, 0 = forward, 1 = reverse
      o->set, spex_fit_start_method='previous_int' ;String, Method for getting starting params for fit after first interval, Options: default / previous_int / previous_start / previous_iter

      if keyword_set(spex_fit_manual) then begin
        o->set, spex_fit_manual = spex_fit_manual
      endif else begin
        o->set, spex_fit_manual=0 ;0=automatic, 1=manual on first interval, 2=manual on all intervals
      endelse

      if keyword_set(spex_autoplotting) then begin
        o->set, spex_autoplot_enable = spex_autoplotting
      endif else begin
        o->set, spex_autoplot_enable=1; Flag, If set, automatically plot after fitting , Options: 0 or 1
      endelse

      o->set, spex_fit_progbar=1 ;Flag, If set, show progress bar during fit loop through intervals. Options: 0 or 1
      o->set, spex_autoplot_bksub=1 ;Flag, If set, plot data-bk, not data with bk in autoplot. Options: 0 or 1
      o->set, spex_autoplot_overlay_back=1 ;Flag, If set, overlay bk in autoplot. Options: 0 or 1
      o->set, spex_autoplot_overlay_bksub=0 ;Flag, If set, overlay data-bk in autoplot. Options: 0 or 1
      o->set, spex_autoplot_show_err=1 ;Flag, If set, show error bars in autoplot. Options: 0 or 1
      o->set, spex_autoplot_photons=0 ;Flag, If set, plot in photon space in autoplot. Options: 0 or 1
      o->set, spex_autoplot_units='rate' ;String, Units for autoplot ("counts", "rate", "flux"). Options: "counts", "rate", "flux"

      if keyword_set(spex_autoplotting) then begin
        o->set, spex_fitcomp_autoplot_enable = spex_autoplotting
      endif else begin
        o->set, spex_fitcomp_autoplot_enable=1 ;Flag, If set, autoplot in FITCOMP widget after any change . Options: 0 or 1
      endelse

      o->set, spex_fitcomp_plot_resid=1; Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
      o->set, spex_fitcomp_plot_bk=0 ;Flag, If set, overlay bk on plot in FITCOMP widget . Options: 0 or 1
      o->set, spex_fitcomp_plot_err=1 ;Flag, If set, show errors on plot in FITCOMP widget. Options: 0 or 1
      o->set, spex_fitcomp_plot_photons=0 ;Flag, If set, plot in photon space in FITCOMP widget. Options: 0 or 1
      o->set, spex_fitcomp_plot_resid=1 ;Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
      o->set, spex_fitcomp_plot_units='rate' ;String, Units for plot in FITCOMP widget . Options: counts / rate / flux

;      if keyword_set(bk_time_cd_array) then begin
;        o->set, spex_bk_eband = [Minxss_spex_erange[*,index_bk_time_ut_minxss_structure_data]] ;Energy bands for background if spex_bk_sep is set
;        o->set, spex_bk_poisson_error=0 ;Flag, If set, bk data errors are sqrt(counts). Otherwise errors are averaged. Options: 0 or 1
;        o->set, spex_bk_sep=1 ;Flag, If set, separate background for different energy bands. Options: 0 or 1
;        o->set, spex_bk_time_interval=[minxss_x123_ospex_structure[index_bk_time_ut_minxss_structure_data].ut_edges] ;Pointer, Units for plot in FITCOMP widget . Options: counts / rate / flux
;      endif

      o->dofit, /all        ; this will bring up the xfit_comp widget since spex_fit_manual=1
      ; o->xfitview ;bring up GUI to interactively view the fit results.
      minxss_ospex_structure_output_temp = o -> get(/spex_summ)
      ;stuff the output into the array
      minxss_ospex_structure_output[w] = minxss_ospex_structure_output_temp
      ;reset the ospex parameters
      o->init_params

    endfor
  endif else begin
    minxss_ospex_structure_output = minxss_ospex_structure_output_0
  endelse


  ;Should save the energy fit min and max in the final structure.
  ;also make an array or meta data structure that identifies the index for each respective element fo abundance purposes, I should do this for all the structures....
  if (minxss_fit_class eq '1TCoronal') or (minxss_fit_class eq '1TFree') then begin
    minxss_ospex_supplement_structure = {completion_date: systime(), $
      fit_type: minxss_fit_class, $
      fit_energy_edges: Minxss_spex_erange, $
      fit_energy_edges_units: 'keV', $
      index_energy_gain: 0, $
      index_energy_gain_units: 'keV bin $^{-1}$', $
      index_energy_offset_kev: 1, $
      index_energy_offset_units: 'keV', $
      index_vem1: 2, $
      index_vem_units: 'cm $^{-3}$', $
      index_T1: 3, $
      index_T_units: 'keV', $
      index_fip_multiplier: 4, $
      index_fip_multiplier_units: 'multiplier of the chossen abundance file, for elements Fe, Si, Mg, Ca, and half of this value for S', $
      index_vem1_bk: 5, $
      index_T1_bk: 6, $
      index_fip_multiplier_bk: 7}
  endif


  ;Should save the energy fit min and max in the final structure.
  if (minxss_fit_class eq '2TCoronal') or (minxss_fit_class eq '2TFree') then begin
    minxss_ospex_supplement_structure = {completion_date: systime(), $
      fit_type: minxss_fit_class, $
      fit_energy_edges: Minxss_spex_erange, $
      fit_energy_edges_units: 'keV', $
      index_energy_gain: 0, $
      index_energy_gain_units: 'keV bin $^{-1}$', $
      index_energy_offset_kev: 1, $
      index_energy_offset_units: 'keV', $
      index_vem1: 2, $
      index_vem_units: 'cm $^{-3}$', $
      index_T1: 3, $
      index_T_units: 'keV', $
      index_vem2: 4, $
      index_T2: 5, $
      index_fip_multiplier: 6, $
      index_fip_multiplier_units: 'multiplier of the chossen abundance file, for elements Fe, Si, Mg, Ca, and half of this value for S', $
      index_vem1_bk: 5, $
      index_T1_bk: 6, $
      index_vem2_bk: 7, $
      index_T2_bk: 8, $
      index_fip_multiplier_bk: 9}
  endif


  ;Should save the energy fit min and max in the final structure.
  if (minxss_fit_class eq '1TAllFree') then begin
    minxss_ospex_supplement_structure = {completion_date: systime(), $
      fit_type: minxss_fit_class, $
      fit_energy_edges: Minxss_spex_erange, $
      fit_energy_edges_units: 'keV', $
      index_energy_gain: 0, $
      index_energy_gain_units: 'keV bin $^{-1}$', $
      index_energy_offset_kev: 1, $
      index_energy_offset_units: 'keV', $
      index_vem1: 2, $
      index_vem_units: 'cm $^{-3}$', $
      index_T1: 3, $
      index_T_units: 'keV', $
      index_fe_ni_multiplier: 4, $
      index_fe_ni_multiplier_units: 'multiplier of the chossen abundance file, for Fe and Ni', $
      index_ca_multiplier: 5, $
      index_ca_multiplier_units: 'multiplier of the chossen abundance file, for Ca', $
      index_s_multiplier: 6, $
      index_s_multiplier_units: 'multiplier of the chossen abundance file, for S', $
      index_mg_multiplier: 7, $
      index_mg_multiplier_units: 'multiplier of the chossen abundance file, for Mg', $
      index_si_multiplier: 8, $
      index_si_multiplier_units: 'multiplier of the chossen abundance file, for Si', $
      index_ar_multiplier: 9, $
      index_ar_multiplier_units: 'multiplier of the chossen abundance file, for Ar', $
      index_he_c_n_o_f_ne_na_al_k_multiplier: 10, $
      index_he_c_n_o_f_ne_na_al_k_multiplier_units: 'multiplier of the chossen abundance file, for He C N O F Ne Na Al K', $
      index_vem1_bk: 11, $
      index_T1_bk: 12, $
      index_fe_ni_multiplier_bk: 13, $
      index_ca_multiplier_bk: 14, $
      index_s_multiplier_bk: 15, $
      index_mg_multiplier_bk: 16, $
      index_si_multiplier_bk: 17, $
      index_ar_multiplier_bk: 18, $
      index_he_c_n_o_f_ne_na_al_k_multiplier_bk: 19}
  endif


  ;Should save the energy fit min and max in the final structure.
  if (minxss_fit_class eq '2TAllFree') then begin
    minxss_ospex_supplement_structure = {completion_date: systime(), $
      fit_type: minxss_fit_class, $
      fit_energy_edges: Minxss_spex_erange, $
      fit_energy_edges_units: 'keV', $
      index_energy_gain: 0, $
      index_energy_gain_units: 'keV bin $^{-1}$', $
      index_energy_offset_kev: 1, $
      index_energy_offset_units: 'keV', $
      index_vem1: 2, $
      index_vem_units: 'cm $^{-3}$', $
      index_T1: 3, $
      index_T_units: 'keV', $
      index_vem2: 4, $
      index_T2: 5, $
      index_fe_ni_multiplier: 6, $
      index_fe_ni_multiplier_units: 'multiplier of the chossen abundance file, for Fe and Ni', $
      index_ca_multiplier: 7, $
      index_ca_multiplier_units: 'multiplier of the chossen abundance file, for Ca', $
      index_s_multiplier: 8, $
      index_s_multiplier_units: 'multiplier of the chossen abundance file, for S', $
      index_mg_multiplier: 9, $
      index_mg_multiplier_units: 'multiplier of the chossen abundance file, for Mg', $
      index_si_multiplier: 10, $
      index_si_multiplier_units: 'multiplier of the chossen abundance file, for Si', $
      index_ar_multiplier: 11, $
      index_ar_multiplier_units: 'multiplier of the chossen abundance file, for Ar', $
      index_he_c_n_o_f_ne_na_al_k_multiplier: 12, $
      index_he_c_n_o_f_ne_na_al_k_multiplier_units: 'multiplier of the chossen abundance file, for He C N O F Ne Na Al K', $
      index_vem1_bk: 11, $
      index_T1_bk: 12, $
      index_vem2_bk: 13, $
      index_T2_bk: 14, $
      index_fe_ni_multiplier_bk: 15, $
      index_ca_multiplier_bk: 16, $
      index_s_multiplier_bk: 17, $
      index_mg_multiplier_bk: 18, $
      index_si_multiplier_bk: 19, $
      index_ar_multiplier_bk: 20, $
      index_he_c_n_o_f_ne_na_al_k_multiplier_bk: 21}
  endif

 endif else begin ; the normal computation with the option to subtract the background

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;Do the initial fit to create the structure to replicate
   print, 'Do initial fit to set the data structure'
   print, 'Fitting spex_class = ', minxss_fit_class

   o->set, spex_fit_time_interval= [minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[0]].ut_edges]
   o->set, spex_erange=Minxss_spex_erange[*,index_fit_time_ut_minxss_structure_data[0]]; Energy range(s) to fit over (2,n). Units: keV
   ;o->set, spex_fit_auto_emax_thresh=1.0 ;Float,  Threshold for #counts/bin for automatically setting upper limit of energy range to fit.  Units: counts/bin
   o->set, spex_fit_auto_emin=0;Flag, If set, automatically set lower limit of energy range to fit (only applies to RHESSI) , Option: 0 or 1
   o->set, spex_fit_auto_erange=0;Flag, If set, automatically set upper limit of energy range to fit . Option: 0 or 1

   ;1TCoronal
   if minxss_fit_class eq '1TCoronal' then begin
     o->set, fit_function='gain_mod+vth' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
   endif

   ;2TCoronal
   if minxss_fit_class eq '2TCoronal' then begin
     o->set, fit_function='gain_mod+2vth' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
   endif

   ;1TFree
   if minxss_fit_class eq '1TFree' then begin
     o->set, fit_function='gain_mod+vth' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1, 1, 1] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
   endif

   ;2TFree
   if minxss_fit_class eq '2TFree' then begin
     o->set, fit_function='gain_mod+2vth' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,1] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
   endif

   ;1TAllFree
   if minxss_fit_class eq '1TAllFree' then begin
     o->set, fit_function='gain_mod+vth_abun' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[0]], free_Ca[index_fit_time_ut_minxss_structure_data[0]], free_S[index_fit_time_ut_minxss_structure_data[0]], free_Mg[index_fit_time_ut_minxss_structure_data[0]], free_Si[index_fit_time_ut_minxss_structure_data[0]], free_Ar[index_fit_time_ut_minxss_structure_data[0]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[0]]] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
   endif

   ;2TAllFree
   if minxss_fit_class eq '2TAllFree' then begin
     o->set, fit_function='gain_mod+2vth_abun' ;Pointer,  Fit function used
     o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1.] ;Pointer, Fit function parameters
     o->set, fit_comp_free = [0, 1, 1, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[0]], free_Ca[index_fit_time_ut_minxss_structure_data[0]], free_S[index_fit_time_ut_minxss_structure_data[0]], free_Mg[index_fit_time_ut_minxss_structure_data[0]], free_Si[index_fit_time_ut_minxss_structure_data[0]], free_Ar[index_fit_time_ut_minxss_structure_data[0]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[0]]] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
     o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
     o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
     o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
     o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
   endif

   if keyword_set(spex_systematic_uncertainty) then begin
     o->set, spex_uncert = spex_systematic_uncertainty
   endif else begin
     o->set, spex_uncert = 0.0 ;Float, Systematic Uncertainty
   endelse

   o->set, spex_error_use_expected=1 ;Flag,  If set, use expected counts to calc error. Options: 0 or 1

   if keyword_set(spex_mcurvefit_itmax) then begin
     o->set, mcurvefit_itmax = spex_mcurvefit_itmax
   endif else begin
     o->set, mcurvefit_itmax = 50 ;Byte  Maximum number of iterations in mcurvefit fit
   endelse

   if keyword_set(spex_mcurvefit_quiet) then begin
     o->set, mcurvefit_quiet = spex_mcurvefit_quiet
   endif else begin
     o->set, mcurvefit_quiet = 0 ;Flag, 0/1 quiet/verbose during mcurvefit
   endelse

   o->set, spex_allow_diff_energy = 1 ;Flag, If set, allow saved (spex_summ) energy values to differ from data energies , Values 0 or 1
   o->set, spex_fit_reverse=0 ; Interval Loop direction, 0 = forward, 1 = reverse
   o->set, spex_fit_start_method='previous_int' ;String, Method for getting starting params for fit after first interval, Options: default / previous_int / previous_start / previous_iter

   if keyword_set(spex_fit_manual) then begin
     o->set, spex_fit_manual = spex_fit_manual
   endif else begin
     o->set, spex_fit_manual=0 ;0=automatic, 1=manual on first interval, 2=manual on all intervals
   endelse

   if keyword_set(spex_autoplotting) then begin
     o->set, spex_autoplot_enable = spex_autoplotting
   endif else begin
     o->set, spex_autoplot_enable=1; Flag, If set, automatically plot after fitting , Options: 0 or 1
   endelse

   o->set, spex_fit_progbar=1 ;Flag, If set, show progress bar during fit loop through intervals. Options: 0 or 1
   o->set, spex_autoplot_bksub=1 ;Flag, If set, plot data-bk, not data with bk in autoplot. Options: 0 or 1
   o->set, spex_autoplot_enable=1 ;Flag, If set, automatically plot after fitting. Options: 0 or 1
   o->set, spex_autoplot_overlay_back=1 ;Flag, If set, overlay bk in autoplot. Options: 0 or 1
   o->set, spex_autoplot_overlay_bksub=0 ;Flag, If set, overlay data-bk in autoplot. Options: 0 or 1
   o->set, spex_autoplot_photons=0 ;Flag, If set, plot in photon space in autoplot. Options: 0 or 1
   o->set, spex_autoplot_show_err=1 ;Flag, If set, show error bars in autoplot. Options: 0 or 1
   o->set, spex_autoplot_units='rate' ;String, Units for autoplot ("counts", "rate", "flux"). Options: "counts", "rate", "flux"

   if keyword_set(spex_autoplotting) then begin
     o->set, spex_fitcomp_autoplot_enable = spex_autoplotting
   endif else begin
     o->set, spex_fitcomp_autoplot_enable=1 ;Flag, If set, autoplot in FITCOMP widget after any change . Options: 0 or 1
   endelse

   o->set, spex_fitcomp_plot_resid=1; Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
   o->set, spex_fitcomp_plot_bk=0 ;Flag, If set, overlay bk on plot in FITCOMP widget . Options: 0 or 1
   o->set, spex_fitcomp_plot_err=1 ;Flag, If set, show errors on plot in FITCOMP widget. Options: 0 or 1
   o->set, spex_fitcomp_plot_photons=0 ;Flag, If set, plot in photon space in FITCOMP widget. Options: 0 or 1
   o->set, spex_fitcomp_plot_resid=1 ;Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
   o->set, spex_fitcomp_plot_units='rate' ;String, Units for plot in FITCOMP widget . Options: counts / rate / flux

   if keyword_set(bk_time_cd_array) then begin
     o->set, spex_bk_eband = [Minxss_spex_erange[*,index_bk_time_ut_minxss_structure_data]] ;Energy bands for background if spex_bk_sep is set
     o->set, spex_bk_poisson_error=0 ;Flag, If set, bk data errors are sqrt(counts). Otherwise errors are averaged. Options: 0 or 1
     o->set, spex_bk_sep=1 ;Flag, If set, separate background for different energy bands. Options: 0 or 1
     o->set, spex_bk_time_interval=[minxss_x123_ospex_structure[index_bk_time_ut_minxss_structure_data].ut_edges] ;Pointer, Units for plot in FITCOMP widget . Options: counts / rate / flux
   endif

   o->dofit, /all        ; this will bring up the xfit_comp widget since spex_fit_manual=1
   ; o->xfitview ;bring up GUI to interactively view the fit results.
   minxss_ospex_structure_output_0 = o -> get(/spex_summ)
   ;reset the ospex parameters
   o->init_params
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;replicate the structure for the full temporal fits
   minxss_ospex_structure_output = replicate(minxss_ospex_structure_output_0, n_times_MinXSS_Fit)
   if n_times_MinXSS_Fit gt 1 then begin
     ;start the loop for the fit
     for w = 0, n_times_MinXSS_Fit - 1 do begin
       print, 'Performing actual data fit!'
       print, 'Fitting spex_class = ', minxss_fit_class

       ;as a test set verbose = 1
       verbose = 1
       if keyword_set(verbose) then print, 'interval # = ', w
       o->set, spex_fit_time_interval= [minxss_x123_ospex_structure[index_fit_time_ut_minxss_structure_data[w]].ut_edges]
       o->set, spex_erange=Minxss_spex_erange[*,index_fit_time_ut_minxss_structure_data[w]]; Energy range(s) to fit over (2,n). Units: keV
       ;o->set, spex_fit_auto_emax_thresh=1.0 ;Float,  Threshold for #counts/bin for automatically setting upper limit of energy range to fit.  Units: counts/bin
       o->set, spex_fit_auto_emin=0;Flag, If set, automatically set lower limit of energy range to fit (only applies to RHESSI) , Option: 0 or 1
       o->set, spex_fit_auto_erange=0;Flag, If set, automatically set upper limit of energy range to fit . Option: 0 or 1

       ;1TCoronal
       if minxss_fit_class eq '1TCoronal' then begin
         o->set, fit_function='gain_mod+vth' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
       endif

       ;2TCoronal
       if minxss_fit_class eq '2TCoronal' then begin
         o->set, fit_function='gain_mod+2vth' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,0] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
       endif

       ;1TFree
       if minxss_fit_class eq '1TFree' then begin
         o->set, fit_function='gain_mod+vth' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1, 1, 1] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
       endif

       ;2TFree
       if minxss_fit_class eq '2TFree' then begin
         o->set, fit_function='gain_mod+2vth' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1 ,1, 1 ,1 ,1] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 1.e-20, 0.1, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum=['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model=['', 'chianti'] ;String, Fit function model, Options:chianti / mewe
       endif

       ;1TAllFree
       if minxss_fit_class eq '1TAllFree' then begin
         o->set, fit_function='gain_mod+vth_abun' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[w]], free_Ca[index_fit_time_ut_minxss_structure_data[w]], free_S[index_fit_time_ut_minxss_structure_data[w]], free_Mg[index_fit_time_ut_minxss_structure_data[w]], free_Si[index_fit_time_ut_minxss_structure_data[w]], free_Ar[index_fit_time_ut_minxss_structure_data[w]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[w]]] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
       endif

       ;2TAllFree
       if minxss_fit_class eq '2TAllFree' then begin
         o->set, fit_function='gain_mod+2vth_abun' ;Pointer,  Fit function used
         o->set, fit_comp_params=[0., 0., 1.0, 0.2, 1.0, 0.2, 1., 1., 1., 1., 1., 1., 1.] ;Pointer, Fit function parameters
         o->set, fit_comp_free = [0, 1, 1, 1, 1, 1, free_Fe_Ni[index_fit_time_ut_minxss_structure_data[w]], free_Ca[index_fit_time_ut_minxss_structure_data[w]], free_S[index_fit_time_ut_minxss_structure_data[w]], free_Mg[index_fit_time_ut_minxss_structure_data[w]], free_Si[index_fit_time_ut_minxss_structure_data[w]], free_Ar[index_fit_time_ut_minxss_structure_data[w]], free_He_C_N_O_F_Ne_Na_Al_K[index_fit_time_ut_minxss_structure_data[w]]] ;Pointer, Fit function parameter free/fixed mask. Values: 0 or 1
         o->set, fit_comp_maxima = [1., 1., 1.e20, 8., 1.e20, 8., 10., 10., 10., 10., 10., 10., 10.] ;Pointer, Fit function parameter maximum values
         o->set, fit_comp_minima = [-0.1, -1., 1.e-20, 0.1,  1.e-20, 0.1, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01] ;Pointer, Fit function parameter minimum values
         o->set, fit_comp_spectrum= ['', 'full'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
         o->set, fit_comp_model= ['', 'chianti'] ;String, Fit function spectrum type (for thermal). Options: full / continuum / lines
       endif

       if keyword_set(spex_systematic_uncertainty) then begin
         o->set, spex_uncert = spex_systematic_uncertainty
       endif else begin
         o->set, spex_uncert = 0.0 ;Float, Systematic Uncertainty
       endelse

       o->set, spex_error_use_expected=1 ;Flag,  If set, use expected counts to calc error. Options: 0 or 1

       if keyword_set(spex_mcurvefit_itmax) then begin
         o->set, mcurvefit_itmax = spex_mcurvefit_itmax
       endif else begin
         o->set, mcurvefit_itmax = 50 ;Byte  Maximum number of iterations in mcurvefit fit
       endelse

       if keyword_set(spex_mcurvefit_quiet) then begin
         o->set, mcurvefit_quiet = spex_mcurvefit_quiet
       endif else begin
         o->set, mcurvefit_quiet = 0 ;Flag, 0/1 quiet/verbose during mcurvefit
       endelse

       o->set, spex_allow_diff_energy = 1 ;Flag, If set, allow saved (spex_summ) energy values to differ from data energies , Values 0 or 1
       o->set, spex_fit_reverse=0 ; Interval Loop direction, 0 = forward, 1 = reverse
       o->set, spex_fit_start_method='previous_int' ;String, Method for getting starting params for fit after first interval, Options: default / previous_int / previous_start / previous_iter

       if keyword_set(spex_fit_manual) then begin
         o->set, spex_fit_manual = spex_fit_manual
       endif else begin
         o->set, spex_fit_manual=0 ;0=automatic, 1=manual on first interval, 2=manual on all intervals
       endelse

       if keyword_set(spex_autoplotting) then begin
         o->set, spex_autoplot_enable = spex_autoplotting
       endif else begin
         o->set, spex_autoplot_enable=1; Flag, If set, automatically plot after fitting , Options: 0 or 1
       endelse

       o->set, spex_fit_progbar=1 ;Flag, If set, show progress bar during fit loop through intervals. Options: 0 or 1
       o->set, spex_autoplot_bksub=1 ;Flag, If set, plot data-bk, not data with bk in autoplot. Options: 0 or 1
       o->set, spex_autoplot_overlay_back=1 ;Flag, If set, overlay bk in autoplot. Options: 0 or 1
       o->set, spex_autoplot_overlay_bksub=0 ;Flag, If set, overlay data-bk in autoplot. Options: 0 or 1
       o->set, spex_autoplot_show_err=1 ;Flag, If set, show error bars in autoplot. Options: 0 or 1
       o->set, spex_autoplot_photons=0 ;Flag, If set, plot in photon space in autoplot. Options: 0 or 1
       o->set, spex_autoplot_units='rate' ;String, Units for autoplot ("counts", "rate", "flux"). Options: "counts", "rate", "flux"

       if keyword_set(spex_autoplotting) then begin
         o->set, spex_fitcomp_autoplot_enable = spex_autoplotting
       endif else begin
         o->set, spex_fitcomp_autoplot_enable=1 ;Flag, If set, autoplot in FITCOMP widget after any change . Options: 0 or 1
       endelse

       o->set, spex_fitcomp_plot_resid=1; Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
       o->set, spex_fitcomp_plot_bk=0 ;Flag, If set, overlay bk on plot in FITCOMP widget . Options: 0 or 1
       o->set, spex_fitcomp_plot_err=1 ;Flag, If set, show errors on plot in FITCOMP widget. Options: 0 or 1
       o->set, spex_fitcomp_plot_photons=0 ;Flag, If set, plot in photon space in FITCOMP widget. Options: 0 or 1
       o->set, spex_fitcomp_plot_resid=1 ;Flag, If set, plot residuals in autoplot in FITCOMP widget . Options: 0 or 1
       o->set, spex_fitcomp_plot_units='rate' ;String, Units for plot in FITCOMP widget . Options: counts / rate / flux

       if keyword_set(bk_time_cd_array) then begin
         o->set, spex_bk_eband = [Minxss_spex_erange[*,index_bk_time_ut_minxss_structure_data]] ;Energy bands for background if spex_bk_sep is set
         o->set, spex_bk_poisson_error=0 ;Flag, If set, bk data errors are sqrt(counts). Otherwise errors are averaged. Options: 0 or 1
         o->set, spex_bk_sep=1 ;Flag, If set, separate background for different energy bands. Options: 0 or 1
         o->set, spex_bk_time_interval=[minxss_x123_ospex_structure[index_bk_time_ut_minxss_structure_data].ut_edges] ;Pointer, Units for plot in FITCOMP widget . Options: counts / rate / flux
       endif

       o->dofit, /all        ; this will bring up the xfit_comp widget since spex_fit_manual=1
       ; o->xfitview ;bring up GUI to interactively view the fit results.
       minxss_ospex_structure_output_temp = o -> get(/spex_summ)
       ;stuff the output into the array
       minxss_ospex_structure_output[w] = minxss_ospex_structure_output_temp
       ;reset the ospex parameters
       o->init_params

     endfor
   endif else begin
     minxss_ospex_structure_output = minxss_ospex_structure_output_0
   endelse


   ;Should save the energy fit min and max in the final structure.
   ;also make an array or meta data structure that identifies the index for each respective element fo abundance purposes, I should do this for all the structures....
   if (minxss_fit_class eq '1TCoronal') or (minxss_fit_class eq '1TFree') then begin
     minxss_ospex_supplement_structure = {completion_date: systime(), $
       fit_type: minxss_fit_class, $
       fit_energy_edges: Minxss_spex_erange, $
       fit_energy_edges_units: 'keV', $
       index_energy_gain: 0, $
       index_energy_gain_units: 'keV bin $^{-1}$', $
       index_energy_offset_kev: 1, $
       index_energy_offset_units: 'keV', $
       index_vem1: 2, $
       index_vem_units: 'cm $^{-3}$', $
       index_T1: 3, $
       index_T_units: 'keV', $
       index_fip_multiplier: 4, $
       index_fip_multiplier_units: 'multiplier of the chossen abundance file, for elements Fe, Si, Mg, Ca, and half of this value for S'}
   endif


   ;Should save the energy fit min and max in the final structure.
   if (minxss_fit_class eq '2TCoronal') or (minxss_fit_class eq '2TFree') then begin
     minxss_ospex_supplement_structure = {completion_date: systime(), $
       fit_type: minxss_fit_class, $
       fit_energy_edges: Minxss_spex_erange, $
       fit_energy_edges_units: 'keV', $
       index_energy_gain: 0, $
       index_energy_gain_units: 'keV bin $^{-1}$', $
       index_energy_offset_kev: 1, $
       index_energy_offset_units: 'keV', $
       index_vem1: 2, $
       index_vem_units: 'cm $^{-3}$', $
       index_T1: 3, $
       index_T_units: 'keV', $
       index_vem2: 4, $
       index_T2: 5, $
       index_fip_multiplier: 6, $
       index_fip_multiplier_units: 'multiplier of the chossen abundance file, for elements Fe, Si, Mg, Ca, and half of this value for S'}
   endif


   ;Should save the energy fit min and max in the final structure.
   if (minxss_fit_class eq '1TAllFree') then begin
     minxss_ospex_supplement_structure = {completion_date: systime(), $
       fit_type: minxss_fit_class, $
       fit_energy_edges: Minxss_spex_erange, $
       fit_energy_edges_units: 'keV', $
       index_energy_gain: 0, $
       index_energy_gain_units: 'keV bin $^{-1}$', $
       index_energy_offset_kev: 1, $
       index_energy_offset_units: 'keV', $
       index_vem1: 2, $
       index_vem_units: 'cm $^{-3}$', $
       index_T1: 3, $
       index_T_units: 'keV', $
       index_fe_ni_multiplier: 4, $
       index_fe_ni_multiplier_units: 'multiplier of the chossen abundance file, for Fe and Ni', $
       index_ca_multiplier: 5, $
       index_ca_multiplier_units: 'multiplier of the chossen abundance file, for Ca', $
       index_s_multiplier: 6, $
       index_s_multiplier_units: 'multiplier of the chossen abundance file, for S', $
       index_mg_multiplier: 7, $
       index_mg_multiplier_units: 'multiplier of the chossen abundance file, for Mg', $
       index_si_multiplier: 8, $
       index_si_multiplier_units: 'multiplier of the chossen abundance file, for Si', $
       index_ar_multiplier: 9, $
       index_ar_multiplier_units: 'multiplier of the chossen abundance file, for Ar', $
       index_he_c_n_o_f_ne_na_al_k_multiplier: 10, $
       index_he_c_n_o_f_ne_na_al_k_multiplier_units: 'multiplier of the chossen abundance file, for He C N O F Ne Na Al K' }
   endif


   ;Should save the energy fit min and max in the final structure.
   if (minxss_fit_class eq '2TAllFree') then begin
     minxss_ospex_supplement_structure = {completion_date: systime(), $
       fit_type: minxss_fit_class, $
       fit_energy_edges: Minxss_spex_erange, $
       fit_energy_edges_units: 'keV', $
       index_energy_gain: 0, $
       index_energy_gain_units: 'keV bin $^{-1}$', $
       index_energy_offset_kev: 1, $
       index_energy_offset_units: 'keV', $
       index_vem1: 2, $
       index_vem_units: 'cm $^{-3}$', $
       index_T1: 3, $
       index_T_units: 'keV', $
       index_vem2: 4, $
       index_T2: 5, $
       index_fe_ni_multiplier: 6, $
       index_fe_ni_multiplier_units: 'multiplier of the chossen abundance file, for Fe and Ni', $
       index_ca_multiplier: 7, $
       index_ca_multiplier_units: 'multiplier of the chossen abundance file, for Ca', $
       index_s_multiplier: 8, $
       index_s_multiplier_units: 'multiplier of the chossen abundance file, for S', $
       index_mg_multiplier: 9, $
       index_mg_multiplier_units: 'multiplier of the chossen abundance file, for Mg', $
       index_si_multiplier: 10, $
       index_si_multiplier_units: 'multiplier of the chossen abundance file, for Si', $
       index_ar_multiplier: 11, $
       index_ar_multiplier_units: 'multiplier of the chossen abundance file, for Ar', $
       index_he_c_n_o_f_ne_na_al_k_multiplier: 12, $
       index_he_c_n_o_f_ne_na_al_k_multiplier_units: 'multiplier of the chossen abundance file, for He C N O F Ne Na Al K' }
   endif
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 endelse
  
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;Minxss output structure
  minxss_ospex_fit_structure = {results_structure: minxss_ospex_structure_output, $
    info_structure: minxss_ospex_supplement_structure}

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


  ;return the model output signal
  return, minxss_ospex_fit_structure


end