  function jd_to_ymd, jd
;
; Translates Julian Day Number (and fraction) to Gregorian calendar date
; of the form [yyyy, mm, dd.dd].
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2YMD translates its argument, a Julian Day Number of the   "
     print,"  form ddddddd.dd to a double-precision calendar date triple   "
     print,"  of the form [yyyy, mm, dd.dd]. The argument may be a scalar  "
     print,"  or array of a 4-byte or 8-byte numerical type.               "
     print,"                                                               "
     print,"  ymd = jd2ymd( jd )                                           "
     return,''
  endif
;
  return, yd2ymd( jd2yd( jd ) )
;
  end

