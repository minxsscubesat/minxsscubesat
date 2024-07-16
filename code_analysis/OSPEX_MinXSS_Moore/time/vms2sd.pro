  function vms2sd, vmsdate

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns double-precision SORCE mission date

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                              "
     print," VMS2SD translates VMS date string(s) of the form             "
     print," 'dd-mmm-yyyy hh:mm:ss.ss' (e.g., '01-Jan-2004 23:59:59.99')  "
     print," to double precision SORCE day number (mission) dates, where  "
     print," SORCE day 0.0 is 2003/024.0 (2003 Jan 24.0).  The input      "
     print," may be either a scalar or a string array.                    "
     print,"                                                              "
     print," sd = vms2sd( vmsdate )                                       "
     return,''
  endif
;
  return, vms2md(vmsdate,2003024.0d0)
;
  end
