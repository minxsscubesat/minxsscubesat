;+
; NAME:
;   daxss_processing
;
; PURPOSE:
;   Process DAXSS Level 0B, 0C, merged log, and optional level 0D and 1
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   start_date [long or string]: First date of data to process in either yyyydoy long format (e.g., 2016137L) or yyyymmdd string format (e.g., '20160516').
;                                Defaults to 5 days ago.
;   end_date [long or string]:   Same as start_date but for the end date to process.
;                                Defaults to today.
;
; KEYWORD PARAMETERS:
;   DEBUG:      Set this to trigger stop statements in the code in good locations for debugging
;   TO_0C_ONLY: Set this to process up to level 0C only. Defaults to processing all the way to level 1.
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
;   Just run it!
;
;-
PRO daxss_processing, start_date = start_date, end_date = end_date, $
                      DEBUG = DEBUG, TO_0C_ONLY = TO_0C_ONLY, COPY_GOES = COPY_GOES, VERBOSE = VERBOSE

  TIC

  ; Defaults
  IF start_date EQ !NULL THEN start_date = jd2yd(systime(/JULIAN) - 5.)
  IF end_date EQ !NULL THEN end_date = jd2yd(systime(/JULIAN) + 1.)

  ; Deal with time input
  IF isa(start_date, 'string') THEN start_date = JPMyyyymmdd2yyyydoy(start_date)
  IF isa(end_date, 'string') THEN end_date = JPMyyyymmdd2yyyydoy(end_date)
  start_jd = yd2jd(start_date)
  end_jd = yd2jd(end_date)

  IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0B from ', start_date, ' to ', end_date

  for jd=start_jd, end_jd, 1.0 do begin
    yd = long(jd2yd(jd))
    daxss_make_level0b, yyyydoy=yd, VERBOSE=VERBOSE
  endfor

  if keyword_set(debug) THEN stop, 'DEBUG minxss_processing after L0B processing...'

  IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0C and LOG for full mission'

  daxss_make_level0c, /MAKE_MISSION_LENGTH, VERBOSE=VERBOSE

  ; daxss_make_mission_log, /VERBOSE ; TODO: implement this function

  IF ~keyword_set(TO_0C_ONLY) THEN BEGIN
    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L0D for full mission'
    daxss_make_level0d, VERBOSE = VERBOSE ; TODO: implement this function

    IF keyword_set(verbose) THEN message, /INFO, 'Processing DAXSS L1 for full mission'
    daxss_make_level1, VERBOSE = VERBOSE ; TODO: implement this function

    IF keyword_set(verbose) THEN message, /INFO, 'Processing ' + MinXSS_name + ' L3 for full mission'
    
    IF keyword_set(COPY_GOES) THEN BEGIN
      file_copy, '/timed/analysis/goes/goes_1mdata_widx_20*.sav', getenv('minxss_data') + 'ancillary/goes/', /OVERWRITE
    ENDIF
    daxss_merge_level3, VERBOSE = VERBOSE ; TODO: This should really be minxss_make_level3 but that can't yet handle the mission_length level1 file; implement this function
    
  ENDIF

  if keyword_set(debug) THEN stop, 'DEBUG minxss_processing at end...'

  message, /INFO, JPMsystime() + ' Processing completed in ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'

END

