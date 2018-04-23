;+
; NAME:
;   JPMjd2yyyydoy
;
; PURPOSE:
;   Convert between julian date (jd) as returned from systime(/JULIAN) into yyyydoy in long format. 
;
; INPUTS:
;   julianDate [double]: The julian date as returned from systime(/JULIAN)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this to return a single string in yyyydoy format instead of a structure with yyyy and doy tags. 
;
; OUTPUTS:
;   [structure]: year and doy fields, with corresponding values. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   yearDoy = JPMjd2yyyydoy(systime(/JULIAN))
;
; MODIFICATION HISTORY:
;   2016/05/23: James Paul Mason: Wrote script
;-

FUNCTION JPMjd2yyyydoy, julianDate, RETURN_STRING = RETURN_STRING

yyyyDoyString = JPMyyyymmdd2yyyydoy(JPMjd2yyyymmdd(julianDate), /RETURN_STRING)
yyyyDoy = yyyyDoyString[0]

; Handle doys < 100 by prepending the extra 0
IF strlen(yyyyDoy) EQ 6 THEN yyyyDoy = strmid(yyyyDoy, 0, 4) + '0' + strmid(yyyyDoy, 4, 2)

IF keyword_set(RETURN_STRING) THEN return, yyyyDoy ELSE return, long(yyyyDoy)

END