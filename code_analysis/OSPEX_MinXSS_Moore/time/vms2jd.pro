  function vms2jd, vmsdate

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns double-precision Julian Day Number ddddddd.dd

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  string_type = 7
  info = size(vmsdate)
  type = info[info[0]+1]
  if type ne string_type then begin
     print,"                                                               "
     print,"  VMS2JD translates its string argument to a double precision  "
     print,"  Julian Day Number.  Either a scalar argument containing      "
     print,"  a string of the form 'dd-mmm-yyyy hh:mm:ss.ss', (e.g.,       "
     print,"  '31-oct-1985 23:59:59.99'), or an array of such, is accepted."
     print,"                                                               "
     print,"  jd = vms2jd( vmsdate )                                       "
     return,''
  endif
;
  jd = ymd2jd( vms2ymd( vmsdate ) )
;
; Return scalar or array?
  if info[0] eq 0 then $
     return, jd[0] $
  else $
     return, jd
;
  end
