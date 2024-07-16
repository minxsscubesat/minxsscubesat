function md2jd, md, epoch
;
; Translates mission day numbers to double precision Julian Day Numbers.
  
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
     print,"  MD2JD translates mission day numbers to double precision "
     print,"  Julian Day Number of the form ddddddd.dd   "
     print,"  The argument may be a scalar or array.             "
     print,"                                                               "
     print,"  jd = md2jd( md, epoch )                                      "
     return,''
   endif
;
   return, yd2jd(epoch)+md
;
 end
