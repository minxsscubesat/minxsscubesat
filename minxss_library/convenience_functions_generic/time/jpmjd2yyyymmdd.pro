;+
; NAME:
;   JPMjd2yyyymmdd
;
; PURPOSE:
;   Convert JD to year month day in yyyymmmdd format
;
; INPUTS:
;   jd [double/dblarr]: Standard Julian date (not mjd) as a double, not a structure
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this to get a string instead of a structure returned. Has format: yyyy-mm-dd
;
; OUTPUTS:
;   yyyymmdd [long/lonarr]: Year month day in yyyymmdd format. Returns array if input is array
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires mjd2date from solarsoft, which probably itself requires other programs. 
;   MinXSS standard package includes all necessary code for this to work. 
;
; EXAMPLE:
;   yyyymmdd = JPMjd2yyyymmdd(2457328.500000)
;
; MODIFICATION HISTORY:
;   2015-11-02: James Paul Mason: Wrote script
;   2016-11-12: James Paul Mason: Changed / in string date to - to conform to ISO
;-
FUNCTION JPMjd2yyyymmdd, jd, RETURN_STRING = RETURN_STRING

mjd2date, jd - 2400000.5, yearAll, monthAll, dayAll ; -2400000.5 for conversion to mjd

yyyymmdd = !NULL
FOR i = 0, n_elements(yearAll) - 1 DO BEGIN
  year = yearAll[i] & month = monthAll[i] & day = dayAll[i]
  IF month LT 10 THEN monthString = '0' + strtrim(month, 2) ELSE monthString = strtrim(month, 2)
  IF day LT 10 THEN dayString = '0' + strtrim(day, 2) ELSE dayString = strtrim(day, 2)
  IF keyword_set(RETURN_STRING) THEN yyyymmdd = [yyyymmdd, strtrim(year, 2) + '-' + monthString + '-' + dayString] ELSE $
                                     yyyymmdd = [yyyymmdd, long(strtrim(year, 2) + monthString + dayString)]
ENDFOR

return, yyyymmdd
END