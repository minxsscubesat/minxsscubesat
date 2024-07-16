  function gps2md, gps, epoch
;
; Translates double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0) to mission day.
;
; N. Kungsakawin, 02.06.28
;
; Print usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  GPS2MD translates its argument, double precision TAI seconds "
     print,"  since the GPS epoch (1980 Jan 6.0) to a double-precision mission day "
     print,"  number, where the epoch day is specified     "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  md = gps2md(gps, epoch)                                             "
     return,''
  endif
;
  return, jd2md((gps2jd(gps)),epoch)
;
  end

