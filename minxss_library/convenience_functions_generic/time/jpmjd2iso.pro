;+
; NAME:
;   JPMjd2iso
;
; PURPOSE:
;   Convert JD to the ISO-8601 standard of yyyy-mm-ddThh:mm:ssZ e.g, 2016-06-13T16:50:02Z
;   This assumes that jd is already converted to UTC. 
;
; INPUTS:
;   jd [double / dblarr]: Standard Julian date (not mjd) as a double, not a structure in UTC. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   NO_T_OR_Z: Set this to get rid fo the T and Z in the ISO time. Instead use a space and nothin instead, respectively. 
;
; OUTPUTS:
;   timeIso [string / strarr]: Time in ISO-8601 standard of yyyy-mm-ddThh:mm:ssZ e.g, 2016-06-13T16:50:02Z
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires mjd2date from solarsoft, which probably itself requires other programs. 
;   MinXSS standard package includes all necessary code for this to work. 
;
; EXAMPLE:
;   timeIso = JPMjd2iso(2457328.500000)
;
; MODIFICATION HISTORY:
;   2016-06-13: James Paul Mason: Wrote script
;   2016-07-08: James Paul Mason: Added handling for end of day second (increments day and month, year if appropriate)
;   2016-09-03: James Paul Mason: Changed method from using a loop and ssw routine to using where statement and built-in caldat
;                                 to improve processing time by a factor of 10,000
;   2016-09-08: James Paul Mason: Added a check that lowMonth etc are not -1, to avoid getting results for month like 010 instead of 10
;   2018-08-21: James Paul Mason: Round seconds before converting to string and truncating the fraction of a second off.
;                                 For example, 1.45e-5 seconds should be 0 seconds, not 1 second. 
;-
FUNCTION JPMjd2iso, jd, NO_T_OR_Z = NO_T_OR_Z

; Convert date from jd to yyyy, mm, dd
caldat, jd, monthAll, dayAll, yearAll, hourAll, minuteAll, secondAll

; Create strings with 0 padding
yearAllString = strtrim(yearAll, 2)

lowMonth = where(monthAll LT 10) 
monthAllString = strtrim(monthAll, 2)
IF lowMonth NE [-1] THEN monthAllString[lowMonth] = '0' + monthAllString[lowMonth]

lowDay = where(dayAll LT 10)
dayAllString = strtrim(dayAll, 2)
IF lowDay NE [-1] THEN dayAllString[lowDay] = '0' + DayAllString[lowDay]

lowHour = where(hourAll LT 10)
hourAllString = strtrim(hourAll, 2)
IF lowHour NE [-1] THEN hourAllString[lowHour] = '0' + hourAllString[lowHour]

lowMinute = where(minuteAll LT 10)
minuteAllString = strtrim(minuteAll, 2)
IF lowMinute NE [-1] THEN minuteAllString[lowMinute] = '0' + minuteAllString[lowMinute]

secondAll = round(secondAll)
lowSecond = where(secondAll LT 10)
secondAllString = strtrim(secondAll, 2)
IF lowSecond NE [-1] THEN secondAllString[lowSecond] = '0' + secondAllString[lowSecond]
secondAllString = strmid(secondAllString, 0, 2)

; Construct the string
isoTime = !NULL
IF keyword_set(NO_T_OR_Z) THEN isoTime = [isoTime, yearAllString + '-' + monthAllString + '-' + dayAllString + ' ' + hourAllString + ':' + minuteAllString + ':' + secondAllString] ELSE $
                               isoTime = [isoTime, yearAllString + '-' + monthAllString + '-' + dayAllString + 'T' + hourAllString + ':' + minuteAllString + ':' + secondAllString + 'Z']

return, isoTime
END