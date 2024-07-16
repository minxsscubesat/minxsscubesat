  function md2yd, md, epoch
;
; Translates mission day numbers to double precision 'longdates' of the
; form yyyyddd.dd.    
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(md)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  MD2YD translates mission day numbers to double precision "
     print,"  calendar dates of the form yyyyddd.dd.  "
     print,"  The argument may be a scalar or array.                       "
     print,"                                                               "
     print,"  yd = md2yd( md, epoch )                                             "
     return,''
  endif
;
  return, jd2yd( md2jd( md, epoch ) )
;
  end
