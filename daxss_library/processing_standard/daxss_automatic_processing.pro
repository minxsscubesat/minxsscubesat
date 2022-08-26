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
;+
PRO daxss_automatic_processing, version=version, $
                                VERBOSE=VERBOSE

IF version EQ !NULL THEN version = '2.0.0'

;;
; 1. Task 1: Infinite while loop with a 1 minute periodicity to check if the system time
;            in UTC is midnight ± 2 minutes and call minxss_processing if so
;;
WHILE 1 DO BEGIN
  currentTimeJulianShifted = systime(/UTC, /JULIAN) - 0.5 ; Set 0 to midnight instead of noon
  currentMinuteOfDay = (currentTimeJulianShifted - floor(currentTimeJulianShifted)) * 24. * 60.

  IF currentMinuteOfDay LT 2. THEN BEGIN
    ; First generate new flare scripts
    daxss_auto_generate_downlink_scripts, saveloc='/Users/minxss/My Drive (inspire.lasp@gmail.com)/IS1 On-Orbit Data/Scripts To Run/'

    message, /INFO, JPMsystime() + ' Starting automated DAXSS processing'
    daxss_processing, version=version, VERBOSE=VERBOSE
  ENDIF ELSE BEGIN
    message, /INFO, JPMsystime() + ' Processing will begin in ' + JPMPrintNumber(1440. - currentMinuteOfDay) + ' minutes'
    wait, 60.
  ENDELSE
ENDWHILE

END
