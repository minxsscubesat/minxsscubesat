  function jd2ud, jd
;
; Translates Julian Day Number (and fraction) to double precision
; UARS mission day.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2UD translates its argument, a Julian Day Number of the    "
     print,"  form ddddddd.dd to a double-precision UARS mission day       "
     print,"  number, where UARS day 0.0 = 1991/254.0 = 1991 Sep 11.0.     "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  ud = jd2ud( jd )                                             "
     return,''
  endif
;
  return,jd2md(jd,1991254)
;
  end

