  function jd2md, jd, epoch
;
; Translates Julian Day Number (and fraction) to double precision
; mission day.
;
; N. Kungsakawin, 02.06.28
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2MD translates its argument, a Julian Day Number of the    "
     print,"  form ddddddd.dd to a double-precision mission day       "
     print,"  number, where the epoch day is specified   "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  md = jd2md( jd, epoch )                                             "
     return,''
  endif
;
  return, jd-yd2jd(epoch)
;
  end

