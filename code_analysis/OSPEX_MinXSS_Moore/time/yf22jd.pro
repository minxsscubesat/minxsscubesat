  function yf22jd, yf2
;
; Translates 'YF2' 20th-century year and fraction (i.e., number of years
; of 365.25 days since 1900 Jan 1.0) to Julian Day Number (and fraction)
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
  info = size(yf2)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YF22JD translates 'YF2' 20th-century year and fraction (i.e.,"
     print,"  number of years of 365.25 days elapsed since 1900 Jan 1.0)   "
     print,"  to Julian Day Number (and fraction).  Note that the 'YF2'    "
     print,"  year boundaries do not coinicide precisely with the civil    "
     print,"  calendar year boundaries, because the length of the civil    "
     print,"  calendar year is not constant.                  "
     print,"                                                               "
     print,"  jd = yf22jd( yf2 )                                           "
     return,''
  endif
;
  jd = yd2jd(1904001.0d0)+(yf2-4.0d0)*365.25d0
;
; Return scalar or array?
  if info[0] eq 0 then $
     return,jd[0] $
  else $
     return,jd
;
  end