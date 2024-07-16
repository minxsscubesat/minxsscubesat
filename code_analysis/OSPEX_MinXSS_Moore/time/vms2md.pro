  function vms2md, vmsdate, epoch

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns double-precision mission date

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2MD translates VMS date string(s) of the form             "
     print,"  'dd-mmm-yyyy hh:mm:ss.ss' (e.g., '31-oct-1985 23:59:59.99')  "
     print,"  to double precision mission day number (mission) dates, where   "
     print,"  the epoch date is specified.  The input      "
     print,"  may be either a scalar or a string array.                    "
     print,"                                                               "
     print,"  md = vms2md( vmsdate )                                       "
     return,''
  endif
;
  return, jd2md( vms2jd( vmsdate ), epoch )
;
  end
