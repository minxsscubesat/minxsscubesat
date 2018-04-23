  function ud2jd, ud
;
; Translates UARS mission day numbers (UARS Day 0.0 = 1991 Sep 11.0) to
; double precision Julian Day Numbers.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2JD translates UARS mission day numbers (UARS Day 0.0 =    "
     print,"  1991/254.0 = 1991 Sep 11.0) to double precision Julian Day   "
     print,"  Numbers.  The argument may be a scalar or array.             "
     print,"                                                               "
     print,"  jd = ud2jd( ud )                                             "
     return,''
  endif
;
  return, md2jd(ud, 1991254)
;
  end
