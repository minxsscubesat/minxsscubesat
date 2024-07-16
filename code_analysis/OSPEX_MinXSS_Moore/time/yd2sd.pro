  function yd2sd, yd
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to SORCE
; mission day numbers.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," YD2SD translates its argument of the form yyyyddd.dd to a    "
     print," double-precision SORCE mission day number, where SORCE day   "
     print," 0.0 = 2003/024.0 = 2003 Jan 24.0.  The argument may be a     "
     print," scalar or array.                                             "
     print,"                                                              "
     print," sd = yd2sd( yd )                                             "
     return,''
  endif
;
  return, yd2md(yd, 2003024.0d0)
;
  end
