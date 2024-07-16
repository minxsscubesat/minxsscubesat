  function gps2sd, gps
;
; Translates double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0) to SORCE mission day.
;
; N. Kungsakawin, 02.06.28
;
; Print usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
    print,"                                                                "
    print," GPS2SD translates its argument, double precision TAI seconds   "
    print," since the GPS epoch (1980 Jan 6.0) to a double-precision       "
    print," SORCE mission day number, where SORCE day 0.0 = 2003/024.0 =   " 
    print," 2003 Jan 24.0.  The argument may be a scalar or array.         "
    print,"                                                                "
    print,"  sd = gps2sd(gps)                                              "
     return,''
  endif
;
  return, gps2md(gps,2003024.0d0)
;
  end

