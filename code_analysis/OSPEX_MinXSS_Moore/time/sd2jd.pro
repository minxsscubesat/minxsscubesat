  function sd2jd, sd
;
; Translates SORCE mission day numbers (SORCE Day 0.0 = 2003 Jan 24.0) to
; double precision Julian Day Numbers.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(sd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," SD2JD translates SORCE mission day numbers (SORCE Day 0.0 =  "
     print," 2003/024.0 = 2003 Jan 24) to double precision Julian Day     "
     print," Numbers.  The argument may be a scalar or array.             "
     print,"                                                              "
     print," jd = sd2jd( sd )                                             "
     return,''
  endif
;
  return, md2jd(sd, 2003024.0d0)
;
  end
