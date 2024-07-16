  function ud2ymd, ud
;
; Translates UARS mission day numbers (UARS Day 0.0 = 1991 Sep 11.0) to
; double precision calendar dates of the form [yyyy, mm, dd.dd].
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2YMD translates UARS mission day numbers (UARS Day 0.0 =   "
     print,"  1991/254.0 = 1991 Sep 11.0) to double precision calendar     "
     print,"  dates of the form [yyyy, mm, dd.dd].  The argument may be    "
     print,"  a scalar or array.                                           "
     print,"                                                               "
     print,"  ymd = ud2ymd( ud )                                           "
     return,''
  endif
;
  return, md2ymd(ud,1991254)
;
  end
