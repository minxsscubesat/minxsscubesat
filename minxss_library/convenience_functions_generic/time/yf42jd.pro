  function yf42jd, yf4
;
; Translates 'YF4' Gregorian year and fraction (i.e., number of years of
; 365.2425 days since Gregorian year 0 Jan 1.0) to Julian Day Number (and
; fraction)
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
  info = size(yf4)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YF42JD translates 'YF4' Gregorian year and fraction (i.e.,   "
     print,"  number of years of 365.2425 days elapsed since Gregorian     "
     print,"  year 0 Jan 1.0) to Julian Day Number (and fraction).  Note   "
     print,"  that the 'YF4' year boundaries do not coinicide precisely    "
     print,"  with the civil calendar year boundaries, because the length  "
     print,"  of the civil calendar year is not constant.                  "
     print,"                                                               "
     print,"  jd = yf42jd( yf4 )                                           "
     return,''
  endif
;
  jd = yd2jd(1.0d0)+yf4*365.2425d0
;
; Return scalar or array?
  if info[0] eq 0 then $
     return,jd[0] $
  else $
     return,jd
;
  end