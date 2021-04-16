;+
;
; PROJECT:
; MinXSS
;
; NAME:
; minxss_read_data
;
; PURPOSE:
; Read MinXSS-1 X123 solar data and times from a .sav format file, and put it into a format that OSPEX can read to perform spectral fits.
;
;
; CATEGORY:
; SPEX
;
; CALLING SEQUENCE:
; minxss_read_data, FILES=files, data_str=data_str[, ERR_CODE=err_code,
;                   ERR_MSG=err_msg, _REF_EXTRA=_ref_extra $
;                   verbose=verbose
;
; INPUT KEYWORDS:
;  FILES - Name of MinXSS-1 X123 .sav file to read. 
;  verbose - if set, print information about filtering. Default is 0.
;
; OUTPUT KEYWORDS:
;  data_str - structure containing the information read from the file (see
;   structure definition at end of code for fields in structure)
;  err_code - 0 / 1 means no error / error
;  err_msg - string containing error message. Blank if none.
;
; EXAMPLE:
; Can be called standalone:
;   read_messenger_pds_csv,files='xrs2007152.dat', data_str=data_str
; or, called from within OSPEX to load MESSENGER data
;
; Written: 9-Oct-2013, Kim Tolbert
; Modified by Christopher S. Moore,  University of Colorado, Boulder -> Laboratory for Atmospheric and Space Physics (LASP)\
;
; Modification History:
; 9-oct-2014, Kim. Extracted from messenger_read_pds
; 20-June-2017, C.S.M. altered to read in MinXSS-1 CubeSat X123 data.
;
;
;-
;------------------------------------------------------------------------------
pro minxss_read_data, FILES=files, data_str=data_str, ERR_CODE=err_code,$
  ERR_MSG=err_msg, _REF_EXTRA=_ref_extra

  ;Restore the data file, an idl sav set
  RESTORE, files[0]

  ;Restore the drm file
;  RESTORE, 'C:\Users\chmo1906\Documents\University_Colorado_APS_Grad_School\Research_LASP\MinXSS\MinXSS_Detector_Modeling\DETECTOR_RESPONSE_MATRIX_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX.SAV'
RESTORE, 'C:\Users\Robert\Dropbox\minxss_dropbox\code\OSPEX_MinXSS_Moore\Code\cmoore\DRM_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX_FWHM_0_240_keV.SAV'
;   RESTORE, 'C:\Users\chmo1906\Documents\University_Colorado_APS_Grad_School\Research_LASP\MinXSS\MinXSS_Detector_Modeling\DRM_COMPLETE_MINXSS_X123_FM1_ALL_OSPEX_FWHM_0_216_keV.SAV'

  ;DRM
  ;'C:\Users\chmo1906\Documents\University_Colorado_APS_Grad_School\Research_LASP\MinXSS\MinXSS_Data\Analysis\Minxss_fm1_Paper_Data_Structure_V2.SAV'

  min_energy_kev = 0.70
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  index_First_gt_1_kev = WHERE((MinXSS_X123_FM1_OSPEX_edges_out[0,*] gt min_energy_kev) and (MinXSS_X123_FM1_OSPEX_edges_in[0,*] gt min_energy_kev))
  index_Second_gt_1_kev = WHERE((MinXSS_X123_FM1_OSPEX_edges_out[1,*] gt min_energy_kev) and (MinXSS_X123_FM1_OSPEX_edges_in[1,*] gt min_energy_kev))
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  n_energy_bins = n_elements(minxss_x123_ospex_structure[0].ENERGY_BINS)
  delta_energy_bins = abs(minxss_x123_ospex_structure[0].ENERGY_BINS[0] - minxss_x123_ospex_structure[0].ENERGY_BINS[1])
  offset_energy_bins = minxss_x123_ospex_structure[0].ENERGY_BINS[0]
  minxss_energy_bins_kev = minxss_x123_ospex_structure[0].ENERGY_BINS - offset_energy_bins

  max_MinXSS_X123_FM1_OSPEX_edges_out = max(MinXSS_X123_FM1_OSPEX_edges_out[1,*])

  ingex_data_gt_1_kev_lt_30_keV = where((minxss_energy_bins_kev gt min_energy_kev) and (minxss_energy_bins_kev le (max_MinXSS_X123_FM1_OSPEX_edges_out + delta_energy_bins)))
  n_data = n_elements(ingex_data_gt_1_kev_lt_30_keV)

  energy_bin_edges = MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev] + (0.5*delta_energy_bins)

  drm_index_min = min(index_First_gt_1_kev)
  drm_index_max = max(index_First_gt_1_kev)


  n_times = n_elements(minxss_x123_ospex_structure.INTEGRATION_TIME)
  time_edges = dblarr(2, n_times)

;  if minxss_x123_ospex_structure.Minxss_version_flag eq 1.0 then begin
    data_name = 'MinXSS-1'
    title = 'MinXSS-1 SPECTRUM'
;  endif
 
;  if minxss_x123_ospex_structure.Minxss_version_flag eq 2.0 then begin
;    data_name = 'MinXSS-2'
;    title = 'MinXSS-2 SPECTRUM'
;  endif
  
  units = 'counts'
  atten_states= -1
  ltimes = dblarr(n_data, n_times)
  
  if n_times gt 1.0 then begin
    for k = 0, n_times - 1 do begin
      ltimes[*,k] = minxss_x123_ospex_structure[k].INTEGRATION_TIME
    endfor
  endif else begin
    ltimes[*,*] = minxss_x123_ospex_structure.INTEGRATION_TIME
  endelse


  ;MODIFIED to NOT USE energies below 0.8 keV on photon side

  data_str = { $
    START_TIME: minxss_x123_ospex_structure.ut_edges[0,*], $  ;start time of data in sec rel to 79/1/1
    END_TIME:  minxss_x123_ospex_structure.ut_edges[1,*], $  ;end time of data in sec rel to 79/1/1
    RCOUNTS: minxss_x123_ospex_structure.total_counts[ingex_data_gt_1_kev_lt_30_keV], $  ; SOLAR_MON_SPECTRUM_23_253 - xrs data (nenergy, ntime)
    ERCOUNTS: minxss_x123_ospex_structure.UNCERTAINTY_total_counts[ingex_data_gt_1_kev_lt_30_keV], $  ; error in X123 data (nenergy, ntime)
    UT_EDGES: minxss_x123_ospex_structure.ut_edges, $  ;edges of time bins of xrs data in sec rel to 79/1/1 (2,ntime)
    UNITS: units, $  ; 'counts'
    AREA: MinXSS_X123_FM1_OSPEX_APERTURE_AREA_cm, $  ; detector area corrected to Earth view
    LTIME: ltimes, $  ;live times in seconds (nenergy, ntime)
    CT_EDGES: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev], $  ;edges of energy bins in keV (2,nenergy)
    ;    CT_EDGES: energy_bin_edges, $  ;edges of energy bins in keV (2,nenergy)
    data_name: data_name, $ ; instrument/satellite name 'MESSENGER'
    TITLE: title, $  ; label for data 'MESSENGER SPECTRUM'
    RESPFILE: {drm: MinXSS_X123_FM1_OSPEX_RESPONSE_MATRIX[drm_index_min:drm_index_max, drm_index_min:drm_index_max], edges_in: MinXSS_X123_FM1_OSPEX_edges_in[*,index_First_gt_1_kev], edges_out: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev]}, $  ; DRM matrix, ras added edges, 17-feb-2014
    ;    RESPFILE: {drm: MinXSS_X123_FM1_OSPEX_RESPONSE_MATRIX[index_First_gt_1_kev, index_SECOND_gt_1_kev], edges_in: MinXSS_X123_FM1_OSPEX_edges_in[*,index_First_gt_1_kev], edges_out: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev]}, $  ; DRM matrix, ras added edges, 17-feb-2014
    detused: 'MinXSS-1 X123', $  ; label for detector name for main data in RCOUNTS
    atten_states: atten_states, $   ; -1, not used
    DECONVOLVED:0, $
    PSEUDO_LIVETIME:1, $
    int_time: minxss_x123_ospex_structure.INTEGRATION_TIME, $
    XYOFFSET: [0,0] } ; integration time in seconds


  ;  data_str = { $
  ;    START_TIME: 1.1831112e+009, $  ;start time of data in sec rel to 79/1/1
  ;    END_TIME:  1.1831112e+009, $  ;end time of data in sec rel to 79/1/1
  ;    ;    START_TIME: minxss_ut_edges[0,0], $  ;start time of data in sec rel to 79/1/1
  ;    ;    END_TIME:  minxss_ut_edges[1,0], $  ;end time of data in sec rel to 79/1/1
  ;    RCOUNTS: minxss_x123_ospex_structure[0].total_counts[ingex_data_gt_1_kev_lt_30_keV], $  ; SOLAR_MON_SPECTRUM_23_253 - xrs data (nenergy, ntime)
  ;    ERCOUNTS: minxss_x123_ospex_structure[0].UNCERTAINTY_total_counts[ingex_data_gt_1_kev_lt_30_keV], $  ; error in X123 data (nenergy, ntime)
  ;    UT_EDGES: minxss_ut_edges[*,0], $  ;edges of time bins of xrs data in sec rel to 79/1/1 (2,ntime)
  ;    UNITS: units, $  ; 'counts/s'
  ;    AREA: MinXSS_X123_FM1_OSPEX_APERTURE_AREA_cm, $  ; detector area corrected to Earth view
  ;    LTIME: ltimes[*,0], $  ;live times in seconds (nenergy, ntime)
  ;    CT_EDGES: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev], $  ;edges of energy bins in keV (2,nenergy)
  ;    ;    CT_EDGES: energy_bin_edges, $  ;edges of energy bins in keV (2,nenergy)
  ;    data_name: data_name, $ ; instrument/satellite name 'MESSENGER'
  ;    TITLE: title, $  ; label for data 'MESSENGER SPECTRUM'
  ;    RESPFILE: {drm: MinXSS_X123_FM1_OSPEX_RESPONSE_MATRIX[drm_index_min:drm_index_max, drm_index_min:drm_index_max], edges_in: MinXSS_X123_FM1_OSPEX_edges_in[*,index_First_gt_1_kev], edges_out: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev]}, $  ; DRM matrix, ras added edges, 17-feb-2014
  ;    ;    RESPFILE: {drm: MinXSS_X123_FM1_OSPEX_RESPONSE_MATRIX[index_First_gt_1_kev, index_SECOND_gt_1_kev], edges_in: MinXSS_X123_FM1_OSPEX_edges_in[*,index_First_gt_1_kev], edges_out: MinXSS_X123_FM1_OSPEX_edges_out[*,index_First_gt_1_kev]}, $  ; DRM matrix, ras added edges, 17-feb-2014
  ;    detused: 'MinXSS-1 X123', $  ; label for detector name for main data in RCOUNTS
  ;    atten_states: atten_states, $   ; -1, not used
  ;    DECONVOLVED:0, $
  ;    PSEUDO_LIVETIME:1, $
  ;    int_time: minxss_x123_ospex_structure[0].INTEGRATION_TIME, $
  ;    XYOFFSET: [0,0] } ; integration time in seconds


END
