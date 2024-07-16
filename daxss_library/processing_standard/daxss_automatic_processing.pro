;+
; NAME:
;   daxss_automatic_processing
;
; PURPOSE:
;   Run daxss_processing code every day starting at UTC midnight
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   version [string]: Set this to the version that output files should have. See code for default value.
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages to console
;
; OUTPUTS:
;   All DAXSS processing output files for level 0b, 0c, 0d, 1, and 3
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code package
;
; PROCEDURE:
;   1. Task 1: Infinite while loop with a 1 minute periodicity to check if the system time
;              in UTC is midnight ± 2 minutes and call minxss_processing if so
;
; HISTORY
;	2024-05-07	T. Woods, Updated to Version 2.1 default for updated Level 1 Version 2.1
;
;+
PRO daxss_automatic_processing, version=version, $
                                VERBOSE=VERBOSE

;; IF version EQ !NULL THEN version = '2.0.0'
IF version EQ !NULL THEN version = '2.1.0'		;; New default V2.1 (T. Woods, 5/7/2024)

;;
; 1. Task 1: Infinite while loop with a 1 minute periodicity to check if the system time
;            in UTC is midnight ± 2 minutes and call minxss_processing if so
;;
WHILE 1 DO BEGIN
  currentTimeJulianShifted = systime(/UTC, /JULIAN) - 0.5 ; Set 0 to midnight instead of noon
  currentMinuteOfDay = (currentTimeJulianShifted - floor(currentTimeJulianShifted)) * 24. * 60.

  IF currentMinuteOfDay LT 2. THEN BEGIN
    message, /INFO, JPMsystime() + ' Starting automated DAXSS processing'
    ; /COPY_GOES is broken now (Aug 2023)
    ; daxss_processing, version=version, VERBOSE=VERBOSE  ; , /COPY_GOES
    ;  Changed to new 2024 merged_raw option for processing
    daxss_processing, version=version, VERBOSE=VERBOSE, /merged_raw

    ; generate new flare scripts for yesterday
    message, /INFO, JPMsystime() + ' Making DAXSS flare scripts for yesterday.'
    ; saveloc default is updated with "Scripts To Run" default if it exists
    ; saveloc='/Users/minxss/My Drive (inspire.lasp@gmail.com)/IS1 On-Orbit Data/Scripts To Run/'
    ; 2023-Aug:  don't make scripts while in FLASH mode
    ; daxss_auto_generate_downlink_scripts

    ;  new addition Oct 2022
    message, /INFO, JPMsystime() + ' Making DAXSS Flare Plots per day.'
    daxss_plot_flare, /all, /pdf

    ;  new addition Oct 2022
    message, /INFO, JPMsystime() + ' Making DAXSS Calendar Plots.'
    daxss_make_calendar, /all

  ENDIF ELSE BEGIN
    message, /INFO, JPMsystime() + ' Processing will begin in ' + JPMPrintNumber(1440. - currentMinuteOfDay) + ' minutes'
    wait, 60.
  ENDELSE
ENDWHILE

END
