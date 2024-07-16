function ud2gps, ud
;
; Translates UARS mission day numbers (UARS Day 0.0 = 1991 Sep 11.0) to
; double precision TAI seconds since the GPS epoch (1980 Jan 6.0).
; NB: the epoch is the mission start date in yd, so for UARS it's 1991254.0d0
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2GPS translates UARS mission day numbers "
     print,"  (i.e. UARS Day 0.0 = 1991/254.0 = 1991 Sep 11.0) to double "
     print,"  precision TAI seconds since the GPS epoch (1980 Jan 6.0).  "
     print,"  The argument may be a scalar or array.  "
     print,"                                                               "
     print,"  gps =  ud2gps(ud)                                      "
     return,''
  endif
;
  return, md2gps(ud, 1991254)
;
  end
