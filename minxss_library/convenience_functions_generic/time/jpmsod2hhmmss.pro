;+
; NAME:
;   JPMsod2hhmmss
;
; PURPOSE:
;   Convert second of day (sod) to hours minutes seconds (hhmmss). 
;
; INPUTS:
;   sod [integer]: The second of day to be converted. Must be less than 86400 (24 hours)
;                  May be an array of seconds
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this to get a string instead of a structure returned. Has format: hh:mm:ss
;
; OUTPUTS:
;   Returns structure in the form: {hour, minute, second} with those tags. If input was an array, output
;   is an array of structures. 
;
; OPTIONAL OUTPUTS:
;   See RETURN_STRING keyword description above. 
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   hhmmss = sod2hhmmss(76432, /RETURN_STRING)
;
; MODIFICATION HISTORY:
;   2015/05/29: James Paul Mason: Wrote script
;   2015/11/02: James Paul Mason: Can now deal with an input array and appropriately return an array
;   2016/06/14: James Paul Mason: Deals with rouding resulting in 60 seconds or 60 minutes
;-
FUNCTION JPMsod2hhmmss, sod, RETURN_STRING = RETURN_STRING

IF n_elements(sod) GT 1 THEN inputIsArray = 1 ELSE inputIsArray = 0

IF inputIsArray EQ 0 THEN BEGIN
  IF sod GT 86400 THEN BEGIN
    message, /INFO, 'Input second of day greater than 86400 (24 hours). What did you do wrong?!'
    return, -1
  ENDIF
ENDIF ELSE BEGIN
  FOR i = 0, n_elements(sod) - 1 DO BEGIN
    IF sod[i] GT 86400 THEN BEGIN
      message, /INFO, 'Input array element ' + JPMPrintNumber(i) + ' second of day greater than 86400 (24 hours). What did you do wrong?!'
      return, -1
    ENDIF
  ENDFOR
ENDELSE

hour = floor(sod / 3600.)
minuteFraction = (sod / 3600. - hour) * 60
minute = floor(minuteFraction)
second = round((minuteFraction - minute) * 60)
FOR i = 0, n_elements(second) - 1 DO BEGIN
  IF second[i] EQ 60 THEN BEGIN
    minute[i]++
    second[i] = 0
  ENDIF
ENDFOR
FOR i = 0, n_elements(minute) - 1 DO BEGIN
  IF minute[i] EQ 60 THEN BEGIN
    hour[i]++
    minute[i] = 0
  ENDIF
ENDFOR

IF ~keyword_set(RETURN_STRING) THEN BEGIN
  IF inputIsArray NE 1 THEN return, {hhmmss, hour:hour, minute:minute, second:second} ELSE BEGIN
    hhmmss = {hour:hour[0], minute:minute[0], second:second[0]}
    FOR i = 1, n_elements(sod) - 1 DO hhmmss = [hhmmss, {hour:hour[i], minute:minute[i], second:second[i]}]
    return, hhmmss
  ENDELSE
ENDIF ELSE BEGIN
  IF inputIsArray NE 1 THEN BEGIN
    IF hour   LT 10 THEN hourString   = '0' + JPMPrintNumber(hour,   /NO_DECIMALS) ELSE hourString   = JPMPrintNumber(hour,   /NO_DECIMALS)
    IF minute LT 10 THEN minuteString = '0' + JPMPrintNumber(minute, /NO_DECIMALS) ELSE minuteString = JPMPrintNumber(minute, /NO_DECIMALS)
    IF second LT 10 THEN secondString = '0' + JPMPrintNumber(second, /NO_DECIMALS) ELSE secondString = JPMPrintNumber(second, /NO_DECIMALS)
    return, hourString + ':' + minuteString + ':' + secondString
  ENDIF ELSE BEGIN
    hhmmss = strarr(n_elements(sod))
    FOR i = 0, n_elements(sod) - 1 DO BEGIN
      IF hour[i]   LT 10 THEN hourString   = '0' + JPMPrintNumber(hour[i],   /NO_DECIMALS) ELSE hourString   = JPMPrintNumber(hour[i],   /NO_DECIMALS)
      IF minute[i] LT 10 THEN minuteString = '0' + JPMPrintNumber(minute[i], /NO_DECIMALS) ELSE minuteString = JPMPrintNumber(minute[i], /NO_DECIMALS)
      IF second[i] LT 10 THEN secondString = '0' + JPMPrintNumber(second[i], /NO_DECIMALS) ELSE secondString = JPMPrintNumber(second[i], /NO_DECIMALS)
      hhmmss[i] = hourString + ':' + minuteString + ':' + secondString
    ENDFOR
    return, hhmmss
  ENDELSE
ENDELSE

END