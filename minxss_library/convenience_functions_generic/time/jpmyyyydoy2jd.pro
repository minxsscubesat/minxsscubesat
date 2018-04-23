;+
; NAME:
;   JPMyyyyDoy2JD
;
; PURPOSE:
;   Convert from yyyydoy format to jd, which the IDL plot function can interpret using the XTICKUNITS optional input
;
; INPUTS:
;   yyyyDoy [long]: The date in yyyyDoy format e.g., 2015195
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Returns the julian date in double format e.g., 2457217.5
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
;   2015/07/14: James Paul Mason: Wrote script.
;-
FUNCTION JPMyyyyDoy2JD, yyyyDoy

yyyyInput = long(strmid(strtrim(yyyyDoy, 2), 0, 4))
doyInput = long(strmid(strtrim(yyyyDoy, 2), 4, 3))

utc = doy2utc(doyInput, yyyyInput)
jd = anytim2jd(utc)
return, double(jd.int + jd.frac)

END