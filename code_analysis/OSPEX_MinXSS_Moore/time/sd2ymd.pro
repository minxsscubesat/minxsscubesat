  function sd2ymd, sd
;
; Translates SORCE mission day numbers (SORCE Day 0.0 = 2003 Jan 24.0) to
; double precision calendar dates of the form [yyyy, mm, dd.dd].

;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(sd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," SD2YMD translates SORCE mission day numbers (SORCE Day 0.0 = "
     print," 2003/024.0 = 2003 Jan 24.0) to double precision calendar     "
     print," dates of the form [yyyy, mm, dd.dd].  The argument may be    "
     print," a scalar or array.                                           "
     print,"                                                              "
     print," ymd = sd2ymd( sd )                                           "
     return,''
  endif
;
  return, md2ymd(sd,2003024.0d0)
;
  end
