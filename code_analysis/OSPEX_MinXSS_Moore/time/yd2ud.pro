  function yd2ud, yd
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to UARS
; mission day numbers.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2UD translates its argument of the form yyyyddd.dd to a    "
     print,"  double-precision UARS mission day number, where UARS day     "
     print,"  0.0 = 1991/254.0 = 1991 Sep 11.0.  The argument may be a     "
     print,"  scalar or array.                                             "
     print,"                                                               "
     print,"  ud = yd2ud( yd )                                             "
     return,''
  endif
;
  return, yd2md(yd, 1991254)
;
  end
