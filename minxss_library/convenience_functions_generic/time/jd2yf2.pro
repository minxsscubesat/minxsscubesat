  function jd2yf2, jd
;
; Translates Julian Day Number (and fraction) to 20th-century year and
; fraction, that is, the number of years of 365.25 days elapsed since
; 1900 Jan 1.0.  Note that the resulting year boundaries do not coincide
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
     print,"  JD2YF2 translates Julian Day Number (and fraction) to 20th-  "
     print,"  century year and fraction, that is, the number of years      "
     print,"  of 365.25 days elapsed since 1900 Jan 1.0.  Note that the    "
     print,"  resulting year boundaries will not coinicide precisely with  "
     print,"  civil calendar year boundaries, because the length of the    "
     print,"  civil calendar year is not constant.                         "
     print,"                                                               "
     print,"  yf2 = jd2yf2( jd )                                           "
     return,''
  endif
;
  yf2 = (jd-yd2jd(1904001.0d0))/365.25d0 + 4.0d0
;
; Return scalar or array?
  if info[0] eq 0 then $
     return,yf2[0] $
  else $
     return,yf2
;
  end