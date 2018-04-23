;+
; NAME:
;   minxss_automatic_processing
;
; PURPOSE:
;   Run minxss_processing code every day starting at UTC midnight
;
; CATEGORY:
;   All levels
;
; CALLING SEQUENCE:
;   minxss_automatic_processing
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages to console
;
; OUTPUTS:
;   All MinXSS processing output files for level 0b, 0c, 0d, and level 1
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
; MODIFICATION HISTORY:
;   2016-09-01: James Paul Mason: Wrote program.
;   2017-03-09: James Paul Mason: Added COPY_GOES keyword call in minxss_processing
;+
PRO minxss_automatic_processing

;;
; 1. Task 1: Infinite while loop with a 1 minute periodicity to check if the system time
;            in UTC is midnight ± 2 minutes and call minxss_processing if so
;;
WHILE 1 DO BEGIN
  currentTimeJulianShifted = systime(/UTC, /JULIAN) - 0.5 ; Set 0 to midnight instead of noon
  currentMinuteOfDay = (currentTimeJulianShifted - floor(currentTimeJulianShifted)) * 24. * 60.

  IF currentMinuteOfDay GT 1438. THEN BEGIN ; 1440 minutes per day, so 1438 is within 2 minutes of midnight
    message, /INFO, JPMsystime() + ' Starting automated MinXSS processing' 
    minxss_processing, /COPY_GOES
  ENDIF ELSE BEGIN
    message, /INFO, JPMsystime() + ' Processing will begin in ' + JPMPrintNumber(1440. - currentMinuteOfDay) + ' minutes'
    wait, 60.
  ENDELSE
ENDWHILE

END