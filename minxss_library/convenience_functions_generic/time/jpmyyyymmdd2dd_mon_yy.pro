;+
; NAME:
;   JPMyyyymmdd2dd_mon_yy
;
; PURPOSE:
;   Convert from yyyydoy format to dd_mon_yy. Useful for GOES input. 
;
; INPUTS:
;   yyyymmdd [long or string]: The date in yyyymmdd format e.g., 20160118
;                              or as an iso string e.g., '2016-01-18' 
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
;   dd_mon_yy = JPMyyyymmdd2dd_mon_yy(20160118)
;
; MODIFICATION HISTORY:
;   2016-01-18: James Paul Mason: Wrote script.
;   2016-10-26: James Paul Mason: Added ability to handle ISO string style input
;-
FUNCTION JPMyyyymmdd2dd_mon_yy, yyyymmdd

yyyyInput = strmid(strtrim(yyyymmdd, 2), 0, 4)
IF isa(yyyymmdd, 'long') THEN BEGIN
  mmInput = long(strmid(strtrim(yyyymmdd, 2), 4, 2))
  ddInput = strmid(strtrim(yyyymmdd, 2), 6, 2)
ENDIF ELSE BEGIN
  mmInput = long(strmid(yyyymmdd, 5, 2))
  ddInput = strmid(yyyymmdd, 8, 2)
ENDELSE


; Convert month from nueric to letters
CASE mmInput OF 
  1: mmOutput = 'jan'
  2: mmOutput = 'feb'
  3: mmOutput = 'mar'
  4: mmOutput = 'apr'
  5: mmOutput = 'may'
  6: mmOutput = 'jun'
  7: mmOutput = 'jul'
  8: mmOutput = 'aug'
  9: mmOutput = 'sep'
  10: mmOutput = 'oct'
  11: mmOutput = 'nov'
  12: mmOutput = 'dec'
ENDCASE

; Convert 4 digit year to 2 digit 
yyOutput = strmid(yyyyInput, 2, 2)

; Nothing to do to ddInput but for consistency make it output variable
ddOutput = ddInput

return, ddOutput + '-' + mmOutput + '-' + yyOutput

END