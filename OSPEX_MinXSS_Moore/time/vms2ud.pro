  function vms2ud, vmsdate

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns double-precision UARS mission date

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2UD translates VMS date string(s) of the form             "
     print,"  'dd-mmm-yyyy hh:mm:ss.ss' (e.g., '31-oct-1985 23:59:59.99')  "
     print,"  to double precision UARS day number (mission) dates, where   "
     print,"  UARS day 0.0 is 1991/254.0 (1991 Sept 11.0).  The input      "
     print,"  may be either a scalar or a string array.                    "
     print,"                                                               "
     print,"  ud = vms2ud( vmsdate )                                       "
     return,''
  endif
;
  return, vms2md(vmsdate,1991254)
;
  end
