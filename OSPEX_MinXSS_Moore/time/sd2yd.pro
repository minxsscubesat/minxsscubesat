  function sd2yd, sd
;
; Translates SORCE mission day numbers (SORCE Day 0.0 = 2003 Jan 24.0) to
; double precision 'longdates' of the form yyyyddd.dd.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(sd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," SD2YD translates SORCE mission day numbers (SORCE Day 0.0 =  "
     print," 2003/024.0 = 2003 Jan 24.0) to double precision calendar     "
     print," dates of the form yyyyddd.dd.  The argument may be a scalar  "
     print," or array.                                                    "
     print,"                                                              "
     print," yd = sd2yd( sd )                                             "
     return,''
  endif
;
  return, md2yd(sd,2003024.0d0)
;
  end
