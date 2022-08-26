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
;   version [string]: Set this to the version that should be used for output files. Default is '1.1.0'.
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
PRO daxss_processing, version=version, $
                      TO_0C_ONLY=TO_0C_ONLY, COPY_GOES=COPY_GOES, VERBOSE=VERBOSE, DEBUG=DEBUG

  TIC	; start internal timer
  IF version EQ !NULL THEN version = '2.0.0'
  IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0B and L0C for the Full Mission'

  ; First Make Level 0B file using IIST processed Level 0 files
  ;	This only can be done on DAXSS Science Data Processing computer (due to GoogleDrive paths)
  spawn, 'hostname', hostname_output
  hostname = strupcase(hostname_output[n_elements(hostname_output)-1])
  if (hostname eq 'MACD3750') then begin
   	message, /INFO, 'Processing Level 0B and Level 0C on '+hostname
    daxss_make_level0c, version=version, VERBOSE=VERBOSE ; Also makes level 0b internally so need need to call that separately
  endif else begin
    ; ***** EXAMPLE OF daxss_make_level0c WITHOUT USING Level 0B FILE *****
    message, /INFO, 'Processing Level 0C only on '+hostname
    myPath = getenv('minxss_data')+'/fm3/hydra_tlm/flight'
    myFiles = file_search( myPath, 'ccsds_*', count=filesCount )
    IF keyword_set(verbose) THEN message, /INFO, 'No L0A file made. Number of Hydra files found = '+strtrim(filesCount,2)
    daxss_make_level0c, telemetryFileNamesArray=myFiles, version=version, VERBOSE=VERBOSE
  endelse

  if keyword_set(debug) THEN stop, 'DEBUG daxss_processing after L0C processing...'

  ; daxss_make_mission_log, /VERBOSE ; TODO: implement this function

  IF ~keyword_set(TO_0C_ONLY) THEN BEGIN
    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0D for full mission'
    daxss_make_level0d_limited, version=version, VERBOSE=VERBOSE

    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L1 for full mission'
    daxss_make_level1, version=version, VERBOSE=VERBOSE


    IF keyword_set(COPY_GOES) THEN BEGIN
		minxss_goes_dir = getenv('minxss_data')+path_sep()+'ancillary'+path_sep()+'goes'+path_sep()
    	IF keyword_set(verbose) THEN message, /INFO, 'Copying over GOES data to minxss_dropbox'
 		; Copy GOES annual file from timed-see.lasp.colorado.edu
		;  file_copy, '/evenetapp/store2/timed/analysis/goes/goes_1mdata_widx_2022.sav', minxss_goes_dir, /OVERWRITE
    ENDIF

    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L2 and L3 for full mission'
    daxss_make_x123_average, 1, version=version, VERBOSE=VERBOSE ; L2 1-min averages
    daxss_make_x123_average, 60, version=version, VERBOSE=VERBOSE ; L2 1-hour averages
    daxss_make_x123_average, 24*60L, version=version, VERBOSE=VERBOSE ; L3 1-day averages

  ENDIF

  if keyword_set(debug) THEN stop, 'DEBUG daxss_processing at end...'

  message, /INFO, JPMsystime() + ' Processing completed in ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'

END

