function md2gps, md, epoch
;
; Translates mission day numbers to double precision TAI seconds since the
; GPS epoch (1980 Jan 6.0) 

; NB: the epoch is the mission start date in yd, so for UARS it's 1991254.0d0
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(md)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  MD2JD translates mission day numbers to double precision     "
     print,"  TAI seconds since the GPS epoch (1980 Jan 6.0)               "
     print, " The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  gps =  md2gps( ud, epoch )                                   "
     return,''
  endif
;
  return, jd2gps(md2jd(md, epoch))
;
  end
