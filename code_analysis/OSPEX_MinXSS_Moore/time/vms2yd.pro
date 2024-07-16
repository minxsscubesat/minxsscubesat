  function vms2yd, vmsdate

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns double-precision yyyyddd.dd

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2YD translates its string argument to a double precision  "
     print,"  date of the form yyyyddd.dd.  Either a scalar argument       "
     print,"  containing a string of the form 'dd-mmm-yyyy hh:mm:ss.ss'    "
     print,"  (e.g., '31-oct-1985 23:59:59.99'), or an array of such, is   "
     print,"  permitted.                                                   "
     print,"                                                               "
     print,"  yd = vms2yd( vmsdate )                                       "
     return,''
  endif
;
  yd = ymd2yd( vms2ymd( vmsdate ) )
  if info[0] eq 0 then $
     return, yd[0] $
  else $
     return, yd
;
  end
