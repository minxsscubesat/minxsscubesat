;+
; NAME:
;   minxss_sort_telemetry.pro
;
; PURPOSE:
;   Accepts array of telemetry packets, sorts the packets in time, and returns them sorted by time
;	  This does require that the structure has time tag to be used for sorting
;
; CATEGORY:
;   MinXSS Generic, but primarily for MinXSS Level 0B and 0C
;
; CALLING SEQUENCE:
;   minxss_sort_telemetry, array
;
; INPUTS:
;   array [structure]: unsorted array of structures
;
; KEYWORD PARAMETERS:
;	  NO_EXCLUDE: Don't limit TIME to after 2014 (valid packets for FSW version 8 and later)
;	  NO_TIME_CORRECT:  Don't do time offset correction
;	  NO_UNIQUE:  Don't do removal of duplicate packets
;
; OUTPUTS:
;   Array sorted by time for the array of structures (return is same as input)
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   None
;
; PROCEDURE:
;   1. Task 1: Sort the MinXSS data structures by time
;   2. Task 2: Exclude any data before 2014 (prior to FSW version 8 or later)
;
; MODIFICATION HISTORY:
;   2015/01/26: James Paul Mason: Wrote script.
;   2015/01/31: Tom Woods: Version that works for any array of structures with TIME tag
;   2016/05/22: Amir Caspi: Include FM keyword and correction for inaccurate spacecraft time during early commissioning
;                           (use /no_time_correct to skip correction) ... added /verbose keyword
;
;+
PRO minxss_sort_telemetry, array, fm=fm, verbose=verbose, debug=debug, $
				no_exclude=no_exclude, no_unique=no_unique, no_time_correct=no_time_correct

  IF n_params() LT 1 THEN BEGIN
    print, 'USAGE: minxss_sort_telemetry, in_out_array, fm=fm [, /no_exclude, /no_unique, /no_time_correct]'
    return
  ENDIF

  IF NOT keyword_set(fm) THEN BEGIN
    IF keyword_set(verbose) THEN message, /info, "No FM specified; defaulting to FM = 1..."
    fm = 1
  ENDIF

  ;
  ; 1. Task 1: Sort the MinXSS data structures by time
  ;
  if array NE !NULL then array = temporary(array[sort(array.TIME)])

  ; Also remove duplicate packets (ones with same time)
  if NOT keyword_set(no_unique) then begin
  	if array NE !NULL then begin
  		array = array[UNIQ(array.TIME)]
  	endif
  endif

  ;
  ;	get launch time in GPS seconds
  ;
  CASE FM OF
      1: BEGIN
          timeMin = 1135641617.0d0 ; GPS seconds for 1 Jan 2016 00:00:00 UTC
          timeMax = 1180310413.0d0 ; GPS seconds for 1 June 2017
        END
      2: BEGIN
          timeMin = 1227657613.0d0 ; GPS seconds for 3 Dec 2018 00:00:00 UTC
          timeMax = 1233014413.0d0 ; GPS seconds for 1 Feb 2019
        END
      4: BEGIN
          timeMin = 1328832018.0d0 ; GPS seconds for 14 Feb 2022 00:00:00 UTC
          timeMax = 1514246413.0d0 ; GPS seconds for 31 Dec 2027
        END
      ELSE: BEGIN
          message, /info, "FM = "+strtrim(fm,2) + " not yet supported.  Times unchanged."
          timeMin = 1135641617.0d0 ; GPS seconds for 1 Jan 2016 00:00:00 UTC
          timeMax = 1514246413.0d0 ; GPS seconds for 31 Dec 2027
        END
  ENDCASE
  ; limit time to current time
  if (timeMax gt systime(/julian)) then timeMax = jd2gps(systime(/julian))

  ;
  ; 2. Task 2: Exclude any data before 2014 (prior to FSW version 8 or later)
  ;
  if keyword_set(debug) then stop, 'DEBUG minxss_sort_telemetry before EXCLUDE check...'
  if (not keyword_set(no_exclude)) AND (array NE !NULL) then begin
    ; GPS_SECONDS_2014001 =  1072569613.0D0
    ; wgood = where( array.time ge GPS_SECONDS_2014001, numgood)
    ; use the timeMin from above so unique for each mission
    wgood = where( array.time ge timeMin AND array.time lt timeMax, numgood)
    if (numgood gt 0) then array = temporary(array[wgood]) ; else leave alone
  endif
  if keyword_set(debug) then stop, 'DEBUG minxss_sort_telemetry after EXCLUDE check...'

  ;
  ; 3. Task 3: Correct timestamps after deployment, before setting spacecraft time
  ;
  IF NOT keyword_set(no_time_correct) THEN BEGIN
    CASE FM OF
      1: BEGIN
          timeSetAt = 1147678120.0d0 ; GPS seconds just prior to ground time set (19 May 2016 07:28:23 UTC)
          timeOffset = 7677156.0d0 - 9. ; Estimated offset from deployment time to real time (VERIFY AFTER PLAYBACK!! -- ASSUMES beacon prior to timeset wasn't missed)
        END
      2: BEGIN
          timeSetAt = 1228116215.0d0 ; GPS seconds just prior to ground time set (06 Dec 2018 07:23:18 UTC)
          timeOffset = 3535.492d0 - 3. ; Estimated offset from deployment time to real time (VERIFY AFTER PLAYBACK!! -- ASSUMES beacon prior to timeset wasn't missed)
        END
      4: BEGIN
          timeSetAt = 1328832018.0d0 ; GPS seconds just prior to ground time set (14 Feb 2022)
          timeOffset = 250. ; Estimated offset from deployment time to real time (VERIFY AFTER PLAYBACK!! -- ASSUMES beacon prior to timeset wasn't missed)
        END
      ELSE: BEGIN
          message, /info, "FM = "+strtrim(fm,2) + " not yet supported.  Times unchanged."
          timeSetAt = 0d0 ; ENTER AFTER FM2 DEPLOYMENT
          timeOffset = 0d0 ; ENTER AFTER FM2 DEPLOYMENT
        END
    ENDCASE
    wgood = where(array.time ge timeMin and array.time lt timeSetAt, numgood)
    IF (numgood gt 0) THEN BEGIN
      IF keyword_set(verbose) THEN message, /info, "Adjusting all times between " + strtrim(timeMin,2) + " and " + strtrim(timeSetAt,2) + " ... offset = +" + strTrim(timeOffset,2) + " seconds"
      array[wgood].time += timeOffset
    ENDIF
  ENDIF ELSE IF keyword_set(verbose) THEN message, /info, "Ignoring time correction per user request..."

END
