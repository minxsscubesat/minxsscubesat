; Copyright (c) 2012-2015, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.

;+
; NAME:
; TIMESTAMP
; 
; PURPOSE:
;   This function takes in information about a specific date/time and returns 
;   an ISO 8601 standardized date/time string.
;   
;   This is the inverse of TimestampToValues.pro
; 
; CALLING SEQUENCE:
;   result = TIMESTAMP(YEAR=year, MONTH=month, DAY=day, HOUR=hour, $
;     MINUTE=minute, SECOND=second, OFFSET=offset, /UTC, /ZERO)
; 
; RETURN VALUE:
;   A standardized string in ISO 8601 format associated with the date provided. 
;   The format is:
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
;     OOO is either a + or a - followed by a 2 digit UTF offset indicating the
;       time zone. This may be followed by an optional partial-hour offset
;       in the form of :mm where mm is the number of minutes.
;       
;   If arrays are provided, then the return value will be an array of strings
;     with respective elements.
;     
; ARGUMENTS:
;   None.
;   
; KEYWORDS:
;   YEAR - A 4-digit integer representing the year. If this keyword is not set
;   and ZERO is not set, then the current year is used.
;   MONTH - An integer between 1 and 12, representing the month. If this keyword
;     is not set and ZERO is not set, the current month will be used.
;   DAY - An integer value representing the day of the month. If this keyword 
;     is not set and ZERO is not set, the current day will be used.
;   HOUR - An  integer value representing the hour, using 24-hour time. If this 
;     keyword is not set, 0 will be used. If HOUR, MINUTE, and SECOND are all
;     omitted, then the string will only consist of the date, and the OFFSET and
;     UTC keywords will be ignored.
;   MINUTE - An integer value representing the minute. If this keyword is not 
;     set, 0 will be used.
;   SECOND - Either an integer, a float, or a double representing the second.
;     If this keyword is not set, the integer 0 will be used.
;   OFFSET - If the date provided is based in a different time zone than UTC, 
;     then set this keyword to the UTC offset for the time zone used. For 
;     example, if the time provided is based in U.S. Eastern Time during 
;     Daylight Savings Time, then the UTC offset would be -4. If this keyword is 
;     not provided, it is assumed that the time provided is already in UTC. For
;     partial hour offsets, use a decimal value (so a +9:30 offset would be 
;     expressed as 9.5)
;   UTC (boolean) - Set this keyword to indicate that the return value should
;     be in UTC. The capital letter 'Z' will be appended to the string to
;     indicate the time is in UTC. If the OFFSET keyword is not provided, then
;     the UTC keyword is implied. If the OFFSET keyword is provided and UTC is
;     set, then the string will be converted from local time to UTC using the
;     offset. If the OFFSET keyword is provided and UTC is set to 0, then the
;     string will be in local time and not converted, and the offset will be
;     appended to the end of the string instead of a 'Z'. The offset will be
;     added in the form of '-04:00' for UTC-4. 
;   ZERO (boolean) - Set this keyword to return a time string containing all 
;     zeros ('0000-00-00T00:00:00Z'). If this keyword is set, the following 
;     keywords will be ignored: YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, 
;     OFFSET, UTC.
;     
;   Note: If YEAR, MONTH, DAY, HOUR, MINUTE, SECOND, and ZERO are all omitted, 
;     the timestamp will contain the full current system time, including
;     hours, minutes, and seconds.
; 
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   None.
; 
; RESTRICTIONS:
;   Double-precision seconds are limited to 14 decimal places. Floating-point
;   precision seconds are limited to 5 decimal places.
; 
; MODIFICATION HISTORY:
;   Written by:  bforeback, Exelis VIS, August 2012
;-



FUNCTION Timestamp,YEAR=year, MONTH=month, DAY=day, HOUR=hour, $
  MINUTE=minute, SECOND=second, OFFSET=offset, UTC=useUTC, ZERO=createZero
  
  COMPILE_OPT IDL2
  
  IF (KEYWORD_SET(createZero)) THEN  BEGIN
    RETURN, '0000-00-00T00:00:00Z'
  ENDIF
  
  IF (N_ELEMENTS(year) EQ 0 || $
      N_ELEMENTS(month) eq 0 || $
      N_ELEMENTS(day) eq 0) THEN BEGIN
    IF (N_ELEMENTS(offset) EQ 0) THEN BEGIN
      systemTime = SYSTIME(/JULIAN, /UTC)
    ENDIF ELSE BEGIN
      systemTime = SYSTIME(/JULIAN)
    ENDELSE
    CALDAT, systemTime, currMonth, currDay, currYear, currHour, currMin, currSec
    IF (N_ELEMENTS(year) EQ 0 && $
        N_ELEMENTS(month) EQ 0 && $
        N_ELEMENTS(day) EQ 0 && $
        N_ELEMENTS(hour) EQ 0 && $
        N_ELEMENTS(minute) EQ 0 && $
        N_ELEMENTS(second) EQ 0) THEN BEGIN
      hour = currHour
      minute = currMin
      second = currSec
    ENDIF
  ENDIF
  
  ; Handle arrays (see note above):
  IF (N_ELEMENTS(useUTC) GT 1) THEN BEGIN
    MESSAGE, 'UTC must be a single boolean parameter.'
    RETURN, !NULL
  ENDIF
  nYears = N_ELEMENTS(year)
  nMonths = N_ELEMENTS(month)
  nDays = N_ELEMENTS(day)
  nHours = N_ELEMENTS(hour)
  nMinutes = N_ELEMENTS(minute)
  nSeconds = N_ELEMENTS(second)
  nOffsets = N_ELEMENTS(offset)
  
  nElementsOut = MAX([nYears, nMonths, nDays, $
    nHours, nMinutes, nSeconds, nOffsets]) > 1
  
  IF (nYears EQ 0) THEN BEGIN
    year = MAKE_ARRAY(nElementsOut, VALUE=currYear, /LONG)
  ENDIF ELSE IF (nYears NE 1 && nYears NE nElementsOut) THEN BEGIN
    MESSAGE, 'Inconsistent array dimensions.'
    RETURN, !NULL
  ENDIF
  
  IF (nMonths EQ 0) THEN BEGIN
    month = MAKE_ARRAY(nElementsOut, VALUE=CurrMonth, /LONG)
  ENDIF ELSE IF (nMonths NE 1 && nMonths NE nElementsOut) THEN BEGIN
    MESSAGE, 'Inconsistent array dimensions.'
    RETURN, !NULL
  ENDIF
  
  IF (nDays EQ 0) THEN BEGIN
    day = MAKE_ARRAY(nElementsOut, VALUE=currDay, /LONG)
  ENDIF ELSE IF (nDays NE 1 && nDays NE nElementsOut) THEN BEGIN
  MESSAGE, 'Inconsistent array dimensions.'
    RETURN, !NULL
  ENDIF
  
  ; Error-check to verify that values passed in are valid.
  result = WHERE(year LT 1000, count1)
  result = WHERE(year GT 9999, count2)
  IF (count1 GT 0 || count2 GT 0) THEN BEGIN
    MESSAGE, 'Years must have four digits.'
    RETURN, !NULL
  ENDIF
  
  IF (~ISA(month, /NUMBER)) THEN BEGIN
    MESSAGE, 'Month must contain numbers between 1 and 12.'
    RETURN, !NULL
  ENDIF
  result = WHERE(month LE 0, count1)
  result = WHERE(month GT 12, count2)
  IF (count1 GT 0 || count2 GT 0) THEN BEGIN
    MESSAGE, 'Month must contain numbers between 1 and 12.'
    RETURN, !NULL
  ENDIF
  
  result = WHERE(day LE 0, count1)
  result = WHERE(day GT 31, count2)
  IF (count1 GT 0 || count2 GT 0) THEN BEGIN
    MESSAGE, 'Day must contain numbers between 1 and 31.'
    RETURN, !NULL
  ENDIF
  
  IF (nHours EQ 0 && nMinutes EQ 0 && nSeconds EQ 0) THEN BEGIN
    dateOnly = 1
  ENDIF ELSE BEGIN
    dateOnly = 0
    
    IF (nHours EQ 0) THEN BEGIN
      hour = LONARR(nElementsOut)
    ENDIF ELSE IF (nHours NE 1 && nHours NE nElementsOut) THEN BEGIN
      MESSAGE, 'Inconsistent array dimensions.'
      RETURN, !NULL
    ENDIF
      
    IF (nMinutes EQ 0) THEN BEGIN
      minute = LONARR(nElementsOut)
    ENDIF ELSE IF (nMinutes NE 1 && nMinutes NE nElementsOut) THEN BEGIN
      MESSAGE, 'Inconsistent array dimensions.'
      RETURN, !NULL
    ENDIF
      
    IF (nSeconds EQ 0) THEN BEGIN
      second = LONARR(nElementsOut)
    ENDIF ELSE IF (nSeconds NE 1 && nSeconds NE nElementsOut) THEN BEGIN
      MESSAGE, 'Inconsistent array dimensions.'
      RETURN, !NULL
    ENDIF
    
    IF (nOffsets EQ 0) THEN BEGIN
      offset = DBLARR(nElementsOut)
      nOffsets = nElementsOut
    ENDIF ELSE IF (nOffsets NE 1 && nOffsets NE nElementsOut) THEN BEGIN
      MESSAGE, 'Inconsistent array dimensions.'
      RETURN, !NULL
    ENDIF
    
    ; Error-check to verify that values passed in are valid.
    result = WHERE(hour LT 0, count1)
    result = WHERE(hour GT 23, count2)
    IF (count1 GT 0 || count2 GT 0) THEN BEGIN
      MESSAGE, 'Hour must contain numbers between 0 and 23.'
      RETURN, !NULL
    ENDIF
    
    result = WHERE(minute LT 0, count1)
    result = WHERE(minute GT 59, count2)
    IF (count1 GT 0 || count2 GT 0) THEN BEGIN
      MESSAGE, 'Minute must contain numbers between 0 and 59.'
      RETURN, !NULL
    ENDIF
    
    result = WHERE(second LT 0.0D, count1)
    result = WHERE(second GE 60.0D, count2)
    IF (count1 GT 0 || count2 GT 0) THEN BEGIN
      MESSAGE, 'Second must contain numbers greater than or ' + $
        'equal to 0.0 and less than 60.0'
      RETURN, !NULL
    ENDIF
  
    result = WHERE(offset LT -12, count1)
    result = WHERE(offset GT 14, count2)
    IF (count1 GT 0 || count2 GT 0) THEN BEGIN
      MESSAGE, 'UTC offset must contain numbers between -12 and +14.'
      RETURN, !NULL
    ENDIF
  ENDELSE
  
  IF (KEYWORD_SET(useUTC) && dateOnly EQ 0) THEN BEGIN
    julian = JULDAY(month, day, year, hour, minute, second)
    julian -= DOUBLE(offset)/24.0d
    CALDAT, julian, OutMonth, outDay, outYear, outHour, outMinute
  ENDIF ELSE BEGIN
    outYear = year
    outMonth = month
    outDay = day
    IF (dateOnly EQ 0) THEN BEGIN
      outHour = hour
      outMinute = minute
    ENDIF
  ENDELSE
  
  IF (nElementsOut GT 1 && N_Elements(outYear) EQ 1) THEN BEGIN
    timeString = REPLICATE(STRING(outYear, FORMAT='(I4)') + '-', nElementsOut)
  ENDIF ELSE BEGIN
    timeString = STRING(outYear, FORMAT='(I4)') + '-'
  ENDELSE
  timeString += STRING(outMonth, FORMAT='(I02)') + '-'
  timeString += STRING(outDay, FORMAT='(I02)')
  IF (dateOnly EQ 1) THEN RETURN, timeString
  timeString += 'T'
  timeString += STRING(outHour, FORMAT='(I02)') + ':'
  timeString += STRING(outMinute, FORMAT='(I02)') + ':'
  ; Julday has a max precision level. Handle decimal seconds using the original
  ; input and not the result from CALDAT.
  secondType = SIZE(second, /TYPE)
  CASE secondTYPE OF
    4: format = '(D08.5)'
    5: format = '(D017.14)'
    ELSE: format = '(D03.0)'
  ENDCASE
  timeString += STRING(second, FORMAT=format)
  count = nElementsOut
  WHILE (count GT 0) DO BEGIN
    pos = STRPOS(timeString, '0', /REVERSE_SEARCH)
    result = WHERE(pos EQ STRLEN(timeString)-1, count)
    IF (count EQ 0) THEN BREAK
    i = L64INDGEN(count)
    timeString[result] = $
      (STRMID(timeString[result], 0, STRLEN(timeString[result])-1))[i,i]
  ENDWHILE
  pos = STRPOS(timeString, '.', /REVERSE_SEARCH)
  result = WHERE(pos EQ STRLEN(timeString)-1, count)
  IF (count GT 0) THEN BEGIN
    i = L64INDGEN(count)
    timeString[result] = $
      (STRMID(timeString[result], 0, STRLEN(timeString[result])-1))[i,i]
  ENDIF
  
  
  IF (KEYWORD_SET(useUTC))THEN BEGIN
    timeString += 'Z'
  ENDIF ELSE BEGIN
    IF (nOffsets EQ 1) THEN BEGIN
      IF (offset EQ 0.0D) THEN BEGIN 
        timeString += 'Z'
      ENDIF ELSE BEGIN 
        IF (offset GT 0.0D) THEN BEGIN
          timeString += '+' + STRING(FIX(offset), FORMAT='(I02)')
        ENDIF ELSE BEGIN
          timeString += STRING(FIX(offset), FORMAT='(I03)')
        ENDELSE
        timeString += ':' + STRING(FIX(ABS(offset MOD 1) * 60), FORMAT='(I02)')
      ENDELSE
    ENDIF ELSE BEGIN
      append = WHERE(offset EQ 0.0D, count)
      IF (count GT 0) THEN timeString[append]+='Z'
      append = WHERE(offset GT 0.0D, count)
      IF (count GT 0) THEN timeString[append] += $
        '+' + STRING(FIX(offset[append]), FORMAT='(I02)')
      append = WHERE(offset LT 0.0D, count)
      IF (count GT 0) THEN timeString[append] += $
        STRING(FIX(offset[append]), FORMAT='(I03)')
      offsetMinutes = FIX(ABS(offset MOD 1) * 60)
      append = WHERE(offset NE 0.0D, count)
      IF (count GT 0) THEN timeString[append] += ':' + $
        STRING(offsetMinutes[append], FORMAT='(I02)')
    ENDELSE
  ENDELSE
  
  RETURN, timeString
  
END