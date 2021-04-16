  function jd2sd, jd
;
; Translates Julian Day Number (and fraction) to double precision
; SORCE mission day.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," JD2SD translates its argument, a Julian Day Number of the    "
     print," form ddddddd.dd to a double-precision SORCE mission day      "
     print," number, where SORCE day 0.0 = 2003/024.0 = 2003 Jan 24.0.    "
     print," The argument may be a scalar or array.                       "
     print,"                                                              "
     print," sd = jd2sd( jd )                                             "
     return,''
  endif
;
  return,jd2md(jd,2003024);
;
  end


