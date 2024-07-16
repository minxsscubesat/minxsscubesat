  function gps2ud, gps
;
; Translates double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0) to UARS mission day.
;
; N. Kungsakawin, 02.06.28
;
; Print usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  GPS2UD translates its argument, double precision TAI seconds "
     print,"  since the GPS epoch (1980 Jan 6.0) to a double-precision UARS mission day       "
     print,"  number, where UARS day 0.0 = 1991/254.0 = 1991 Sep 11.0.     "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  ud = gps2ud(gps)                                             "
     return,''
  endif
;
  return, gps2md(gps,1991254)
;
  end

