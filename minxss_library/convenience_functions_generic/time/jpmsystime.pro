;+
; NAME:
;   JPMsystime
;
; PURPOSE:
;   IDL's default systime() function has no options for formatting to human time (yyyy-mm-dd hh:mm:ss). This code does that. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   ISO: Set this to return time with the T and timezone correction at the end e.g., 2016-10-26T10:37:25+07:00
;
; OUTPUTS:
;   currentTimeHuman [string]: The current local time in human format: yyyy-mm-dd hh-mm-ss
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   message, /INFO, JPMsystime() + ' Processing complete'
;
; MODIFICATION HISTORY:
;   2016-09-02: James Paul Mason: Wrote script.
;   2016-10-26: James Paul Mason: Added the ISO keyword
;   2017-02-17: James Paul Mason: Made the UTC keyword also return with a Z at the end rather than the pos/neg local timezone offset
;-
FUNCTION JPMsystime, ISO = ISO, UTC = UTC

; Get the current time broken up into components 
caldat, systime(/JULIAN, UTC = UTC), month, day, year, hour, minute, second

; Convert to strings
yyyy = strtrim(year, 2)
IF month LT 10 THEN mm = '0' + strtrim(month, 2) ELSE mm = strtrim(month, 2)
IF day LT 10 THEN dd = '0' + strtrim(day, 2) ELSE dd = strtrim(day, 2)
IF hour LT 10 THEN hh = '0' + strtrim(hour, 2) ELSE hh = strtrim(hour, 2)
IF minute LT 10 THEN mmin = '0' + strtrim(minute, 2) ELSE mmin = strtrim(minute, 2)
IF second LT 10 THEN ss = '0' + JPMPrintNumber(second, /NO_DECIMALS) ELSE ss = JPMPrintNumber(second, /NO_DECIMALS)

IF keyword_set(ISO) THEN timeBreakCharacter = 'T' ELSE timeBreakCharacter = ' '

currentTimeHuman = yyyy + '-' + mm + '-' + dd + timeBreakCharacter + hh + ':' + mmin + ':' + ss

IF keyword_set(ISO) THEN BEGIN
  jdUtc = systime(/JULIAN, /UTC)
  jdLocal = systime(/JULIAN)
  hourDiff = abs(jdUtc - jdLocal) * 24.
  IF hourDiff EQ 0 THEN return, currentTimeHuman + 'Z'
  IF hourDiff LT 10 THEN hhDiff = '0' + JPMPrintNumber(hourDiff, /NO_DECIMALS) ELSE hhDiff = strtrim(hourDiff, 2)
  IF jdLocal GT jdUtc THEN posOrNeg = '+' ELSE posOrNeg = '-'
  
  IF keyword_set(UTC) THEN BEGIN
    return, currentTimeHuman = currentTimeHuman + 'Z'
  ENDIF
  
  return, currentTimeHuman = currentTimeHuman + posOrNeg + hhDiff + ':00' ; Not dealing with timezones that have a minute difference
ENDIF

return, currentTimeHuman

END