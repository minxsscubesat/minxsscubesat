;+
; NAME:
;   daxss_processing
;
; PURPOSE:
;   Process DAXSS Level 0B, Level 0C, and optional level 0D and 1
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   DEBUG:      Set this to trigger stop statements in the code in good locations for debugging
;   TO_0C_ONLY: Set this to process up to level 0B only. Defaults to processing all the way to level 1.
;   VERBOSE:    Set to print processing messages
;
; OUTPUTS:
;   None directly, but each level of processing generates IDL savesets on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires DAXSS code package
;
; EXAMPLE:
;   IDL>  daxss_processing, /verbose
;
;-
PRO daxss_processing, TO_0C_ONLY=TO_0C_ONLY, COPY_GOES=COPY_GOES, VERBOSE=VERBOSE, DEBUG=DEBUG

  TIC	; start internal timer

  IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0B and L0C for the Full Mission'

  ; First Make Level 0B file using IIST processed Level 0 files
  ;	This only can be done on DAXSS Science Data Processing computer (due to GoogleDrive paths)
  spawn, 'hostname', hostname_output
  hostname = strupcase(hostname_output[n_elements(hostname_output)-1])
  if (hostname eq 'MACD3750') then begin
	; run daxss_make_level0b.pro
	daxss_make_level0b, verbose=VERBOSE
    ;  make Level 0C file next - this uses Level 0B binary file
    daxss_make_level0c, verbose=VERBOSE
  endif else begin
    ; ***** EXAMPLE OF daxss_make_level0c WITHOUT USING Level 0B FILE *****
    myPath = getenv('minxss_data')+'/fm3/hydra_tlm/flight'
    myFiles = file_search( myPath, 'ccsds_*', count=filesCount )
    IF keyword_set(verbose) THEN message, /INFO, 'No L0A file made. Number of Hydra files found = '+strtrim(filesCount,2)
    daxss_make_level0c, telemetryFileNamesArray=myFiles, /verbose
  endelse

  if keyword_set(debug) THEN stop, 'DEBUG daxss_processing after L0C processing...'

  ; daxss_make_mission_log, /VERBOSE ; TODO: implement this function

  IF ~keyword_set(TO_0C_ONLY) THEN BEGIN
    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0D for full mission'
    daxss_make_level0d_limited, VERBOSE = VERBOSE

    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L1 for full mission'
    daxss_make_level1, VERBOSE = VERBOSE

    ; IF keyword_set(verbose) THEN message, /INFO, 'Processing ' + MinXSS_name + ' L3 for full mission'

    ; IF keyword_set(COPY_GOES) THEN BEGIN
    ;  file_copy, '/timed/analysis/goes/goes_1mdata_widx_20*.sav', getenv('minxss_data') + 'ancillary/goes/', /OVERWRITE
    ; ENDIF
    ; daxss_merge_level3, VERBOSE = VERBOSE ; TODO: This should really be minxss_make_level3 but that can't yet handle the mission_length level1 file; implement this function

  ENDIF

  if keyword_set(debug) THEN stop, 'DEBUG daxss_processing at end...'

  message, /INFO, JPMsystime() + ' Processing completed in ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'

END

