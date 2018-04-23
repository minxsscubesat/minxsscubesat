; Copyright (c) 2012-2015, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
; TIMESTAMPTOVALUES
; 
; PURPOSE:
;   Takes in an ISO 8601 standardized date/time string and passes out the year,
;   month, day, hour, minute, second, and UTC offset that is extracted from 
;   the string.
;   
;   This is the inverse of Timestamp.pro
; 
; CALLING SEQUENCE:
;   TIMESTAMPTOVALUES, timeString, YEAR=year, MONTH=month, DAY=day, HOUR=hour, $
;     MINUTE=minute, SECOND=second, OFFSET=offset
; 
; ARGUMENTS:
;   timeString - ISO 8601 tandardized date/time string. The format is:
;   YYYY-MM-DD or
;   YYYY-MM-DDTHH:MM:SS.DZ or
;   YYYY-MM-DDTHH:MM:SS.DOOO, where
;     YYYY is the 4 digit year
;     MM is the 2 digit Month
;     DD is the 2 digit Day
;     T Separates the Date and Time
;     HH is the 2 digit Hour
;     MM is the 2 digit Minute
;     SS is the 2 digit Second
;     D is the decimal fraction of a second with up to double precision.
;     Z indicates that the time is in UTC.
;     OOO is either a + or a - followed by a 2 digit UTC offset indicating the
;       time zone. This may be followed by an optional partial-hour offset
;       in the form of :mm where mm is the number of minutes.
;       
;   If an array of strings is provided, then the values passed out will also be 
;     arrays with respective elements.
;       
; KEYWORDS
;   YEAR - A named variable that, upon output, contains a long integer 
;     representing the number of the desired year (e.g. 2012).
;   MONTH - A named variable that, upon output, contains a long integer 
;     representing the number of the month (1 = January, ..., 12 = December).
;   DAY - A named variable that, upon output, contains a long integer 
;     representing the day of the month (1-31).
;   HOUR - A named variable that, upon output, contains a long integer 
;     representing the hour of the day, in 24-hour time (0-23).
;   MINUTE - A named variable that, upon output, contains a long integer 
;     representing the number of minutes after the hour (0-59).
;   SECOND - A named variable that, upon output, contains a double-precision 
;     value representing the number of seconds after the minute.
;   OFFSET - A named variable that, upon output, contains a double-precision 
;     value representing the time zone offset from UTC in number of hours.
;     
; OUTPUTS:
; 
; COMMON BLOCKS:
; None.
;
; SIDE EFFECTS:
; None.
; 
; RESTRICTIONS:
; Double-precision seconds are limited to approximately 14 decimal places.
; 
; MODIFICATION HISTORY:
;   Written by:  bforeback, Exelis VIS, August 2012
;-


PRO TimestampToValues, timeString, YEAR=year, MONTH=month, DAY=day, $
  HOUR=hour, MINUTE=minute, SECOND=second, OFFSET=offset
  
  COMPILE_OPT IDL2
  
  ON_IOERROR, invalidInput
  
  IF (~ISA(timeString, 'string')) THEN $
    MESSAGE, 'Time string must be a string or array of strings.'
  
  numStrings = N_ELEMENTS(timeString)
  IF (numStrings EQ 1) THEN BEGIN
    year = 0L
    month = 0L
    day = 0L
    hour = 0L
    minute = 0L
    second = 0.0D
    offset = 0.0D
  ENDIF ELSE BEGIN
    year = LONARR(numStrings)
    month = LONARR(numStrings)
    day = LONARR(numStrings)
    hour = LONARR(numStrings)
    minute = LONARR(numStrings)
    second = DBLARR(numStrings)
    offset = DBLARR(numStrings)
  ENDELSE
  
  result = WHERE(STRLEN(timeString) LT 10, count)
  IF (count GT 0) THEN MESSAGE, 'Time string is too short.'
  
  year = LONG(STRMID(timeString,0,4))
  month = LONG(STRMID(timeString,5,2))
  day = LONG(STRMID(timeString,8,2))
  result = WHERE(STRLEN(timeString) GT 10, count)
  IF (count EQ 0) THEN RETURN
  hour = LONG(STRMID(timeString,11,2))
  minute = LONG(STRMID(timeString,14,2))
  remainder = STRMID(timeString,17)
  second = DOUBLE(remainder)
  zPos = STRPOS(remainder, 'Z')
  result = WHERE(zPos GE 0 AND zPos LT STRLEN(remainder)-1, count)
  IF (count GT 0) THEN BEGIN
    MESSAGE, 'Time string must end in either a Z or a valid offset.'
  ENDIF
  plusPos = STRPOS(remainder, '+')
  minusPos = STRPOS(remainder, '-')
  result = WHERE(zPos[result] LT 0 $
             AND plusPos[result] LT 0 $
             AND minusPos[result] LT 0, count)
  IF (count GT 0) THEN BEGIN
    MESSAGE, 'Time string must end in either a Z or a valid offset.'
  ENDIF
  result = WHERE(plusPos GE 0, count)
  if (count GT 0) THEN BEGIN
    offset[result] = $
      DIAG_MATRIX(DOUBLE(STRMID(remainder[result], plusPos[result])))
  ENDIF
  result = WHERE(minusPos GE 0, count)
  if (count GT 0) THEN BEGIN
    offset[result] = $
      DIAG_MATRIX(DOUBLE(STRMID(remainder[result], minusPos[result])))
  ENDIF
  pos = STRPOS(remainder, ':')
  result = WHERE(pos GE 0 AND offset GT 0.0D, count)
  IF (count GT 0) THEN BEGIN
    offset[result] += $
      DIAG_MATRIX(DOUBLE(STRMID(remainder[result], pos[result]+1))) / 60.0D
  ENDIF
  result = WHERE(pos GE 0 AND offset LT 0.0D, count)
  IF (count GT 0) THEN BEGIN
    offset[result] -= $
      DIAG_MATRIX(DOUBLE(STRMID(remainder[result], pos[result]+1))) / 60.0D
  ENDIF
 
  RETURN
  
  invalidInput: MESSAGE, 'Input is invalid.'

END