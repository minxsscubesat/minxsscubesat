function sd2gps, sd
;
; Translates SORCE mission day numbers (SORCE Day 0.0 = 2003 Jan 24.0) to
; double precision double precision TAI seconds since the GPS epoch 
; (1980 Jan 6.0).  NB: the epoch is the mission start date in yd, so for 
; SORCE it's 2003024.0d0
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Print usage?
  info = size(sd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," UD2JD translates mission day numbers (i.e. SORCE Day 0.0 =   "
     print," 2003/024.0 = 2002 Jan 24.0) to double precision TAI seconds  "
     print," since the GPS epoch (1980 Jan 6.0)                           "
     print," The argument may be a scalar or array.                       "
     print,"                                                              "
     print," gps =  sd2gps( sd )                                          "
     return,''
  endif
;
  return, md2gps(sd, 2003024.0d0)
;
  end
