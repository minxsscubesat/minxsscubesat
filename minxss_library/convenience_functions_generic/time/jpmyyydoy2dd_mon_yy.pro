;+
; NAME:
;   JPMyyydoy2dd_mon_yy
;
; PURPOSE:
;   Convert from yyyydoy format to dd_mon_yy format. Useful for GOES input
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
;   Returns the date in string format dd_mon_yy
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires doy2utc and anytim2jd
;
; EXAMPLE:
;   dd_mon_yy = JPMyyydoy2dd_mon_yy(2015195)
;
; MODIFICATION HISTORY:
;   2016/01/18: James Paul Mason: Wrote script.
;-
FUNCTION JPMyyydoy2dd_mon_yy, yyyydoy

yyyymmdd = JPMyyyydoy2yyyymmdd(yyyydoy)
 
return, JPMyyyymmdd2dd_mon_yy(yyyymmdd)

END