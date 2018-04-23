  function ud2yd, ud
;
; Translates UARS mission day numbers (UARS Day 0.0 = 1991 Sep 11.0) to
; double precision 'longdates' of the form yyyyddd.dd.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2YD translates UARS mission day numbers (UARS Day 0.0 =    "
     print,"  1991/254.0 = 1991 Sep 11.0) to double precision calendar     "
     print,"  dates of the form yyyyddd.dd.  The argument may be a scalar  "
     print,"  or array.                                                    "
     print,"                                                               "
     print,"  yd = ud2yd( ud )                                             "
     return,''
  endif
;
  return, md2yd(ud,1991254)
;
  end
