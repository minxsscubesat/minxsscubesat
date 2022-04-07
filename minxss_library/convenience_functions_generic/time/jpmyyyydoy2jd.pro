;+
; NAME:
;   JPMyyyyDoy2JD
;
; PURPOSE:
;   Convert from yyyydoy (or yyyydoyhhmmss) format to jd
;
; INPUTS:
;   yyyyDoy [long]: The date in yyyyDoy format e.g., 2015195. 
;                   Can also handle hhmmss on the end, e.g., 2015195213542
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
;   2015-07-14: James Paul Mason: Wrote script.
;   2022-03-24: James Paul Mason: Added handling for hhmmss input
;-
FUNCTION JPMyyyyDoy2JD, yyyyDoy

yyyyInput = long(strmid(strtrim(yyyyDoy, 2), 0, 4))
doyInput = long(strmid(strtrim(yyyyDoy, 2), 4, 3))

utc = doy2utc(doyInput, yyyyInput)
jd = anytim2jd(utc)
jd = double(jd.int + jd.frac)

IF strlen(yyyyDoy) GT 12 THEN BEGIN
  hhInput = strtrim(strmid(strtrim(yyyyDoy, 2), 7, 2), 2)
  mmInput = strtrim(strmid(strtrim(yyyyDoy, 2), 9, 2), 2)
  ssInput = strtrim(strmid(strtrim(yyyyDoy, 2), 11, 2), 2)
  
  iso = jpmjd2iso(jd)
  iso = iso[0]
  iso_split1 = iso.split(':')
  iso_split2 = iso_split1[0].split('T')
  iso_split2[1] = hhInput
  iso_split1[0] = iso_split2.join('T')
  iso_split1[1] = mminput
  iso_split1[2] = ssinput + 'Z'
  iso = iso_split1.join(':')
  jd = jpmiso2jd(iso)
ENDIF


return, jd

END