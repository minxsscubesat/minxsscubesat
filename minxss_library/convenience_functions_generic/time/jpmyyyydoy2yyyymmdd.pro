;+
; NAME:
;   JPMyyyydoy2yyyymmdd
;
; PURPOSE:
;   Convert from yyyydoy format to yyyymmdd
;
; INPUTS:
;   yyyyDoy [long]: The date in yyyyDoy format e.g., 2015195
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this to return a string in the format yyyy-mm-dd
;
; OUTPUTS:
;   Returns the date in double format yyyymmdd
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires doy2utc and anytim2jd
;
; EXAMPLE:
;   jd = jpmyyyydoy2jd(2015195)
;
; MODIFICATION HISTORY:
;   2016-01-18: James Paul Mason: Wrote script.
;   2016-01-21: James Paul Mason: Added return_string keyword option
;   2017-03-24: James Paul Mason: Changed output string to use - instead of / as separater
;-
FUNCTION JPMyyyydoy2yyyymmdd, yyyyDoy, RETURN_STRING = RETURN_STRING

jd = JPMyyyyDoy2JD(yyyydoy)

IF ~keyword_set(RETURN_STRING) THEN BEGIN 
  return, JPMjd2yyyymmdd(jd)    
ENDIF ELSE BEGIN
  yyyymmdd = strtrim(JPMjd2yyyymmdd(jd), 2)
  return, strmid(yyyymmdd, 0, 4) + '-' + strmid(yyyymmdd, 4, 2) + '-' + strmid(yyyymmdd, 6, 2)
ENDELSE

END