  function jd2yf4, jd
;
; Translates Julian Day Number (and fraction) to a Gregorian year (and
; fraction).  Note that the resulting year boundaries do not coincide
; precisely with the civil year boundaries, since the length of the
; civil year is not constant.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2YF4 translates Julian Day Number (and fraction) to a      "
     print,"  Gregorian Year and fraction, i.e., the number of years       "
     print,"  of 365.2425 days elapsed since Gregorian year 0, Jan 1.0.    "
     print,"  Note that the resulting year boundaries will not coinicide   "
     print,"  precisely with civil calendar year boundaries, because the   "
     print,"  length of the civil calendar year is not constant.           "
     print,"                                                               "
     print,"  yf4 = jd2yf4( jd )                                           "
     return,''
  endif
;
  yf4 = (jd-yd2jd(1.0d0))/365.2425d0
;
; Return scalar or array?
  if info[0] eq 0 then $
     return,yf4[0] $
  else $
     return,yf4
;
  end