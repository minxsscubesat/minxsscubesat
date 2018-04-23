  function md2ymd, md, epoch
;
; Translates mission day numbers to double precision calendar dates of the
; form [yyyy, mm, dd.dd].
    
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(md)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  MD2YMD translates mission day numbers to double precision "
     print,"  calendar dates of the form [yyyy, mm, dd.dd].  "
     print,"  The argument may be a scalar or array.   "
     print,"                                                               "
     print,"  ymd = md2ymd( md, epoch )                                           "
     return,''
  endif
;
  return, jd2ymd( md2jd( md, epoch ) )
;
  end
