  function yd2md, yd, epoch
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to 
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
     print,"  YD2MD translates its argument of the form yyyyddd.dd to a    "
     print,"  double-precision mission day number, where the epoch date     "
     print,"  is specified.  The argument may be a     "
     print,"  scalar or array.                                             "
     print,"                                                               "
     print,"  md = yd2md( yd, epoch )                                             "
     return,''
  endif
;
  return, jd2md( yd2jd( yd ),epoch )  
;
  end
