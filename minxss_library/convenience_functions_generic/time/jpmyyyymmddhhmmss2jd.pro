;+
; NAME:
;   JPMyyyymmddhhmmss2jd
;
; PURPOSE:
;   Convert time from the normal human unit string ('yyyy-mm-dd hh:mm:ss') to julian date. 
;   Really this is just a rebranding of the anytim function. This name is more explicit and clear.
;   This function also returns a double precision number for jd rather than a structure.  
;
; INPUTS:
;   yyyymmddhhmmss [string]: The date in ISO ('yyyy-mm-ddThh:mm:ss') or human ('yyyy mm dd hh:mm:ss') format to be converted. Can be an array. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   jd [double]: The julian date corresponding to the input yyyymmddhhmmss. If input was an array, output will be as well. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   jd = JPMyyyymmddhhmmss2jd('2016-07-14 09:38:25')
;   jd = JPMyyyymmddhhmmss2jd('2016-07-14T09:38:25Z')
;
; MODIFICATION HISTORY:
;   2016/07/14: James Paul Mason: Wrote script.
;-
FUNCTION JPMyyyymmddhhmmss2jd, yyyymmddhhmmss

jdStructure = anytim2jd(yyyymmddhhmmss)

return, jdStructure.int + jdStructure.frac

END