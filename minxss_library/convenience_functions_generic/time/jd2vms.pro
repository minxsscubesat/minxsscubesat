  function jd2vms, jd

; Given date(s) as Julian Day Number(s) and fraction,
; return string(s) of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 2000-10-26

; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2VMS translates Julian Day Numbers (and fraction) to       "
     print,"  VMS date strings of the form 'dd-mmm-yyyy hh:mm:ss.ss'.      "
     print,"  The input argument may be a scalar or array of a 4-byte      "
     print,"  or 8-byte numerical type.                                    "
     print,"                                                               "
     print,"  vms = jd2vms( jd )                                           "
     return,''
  endif
;
  s = ymd2vms( jd2ymd( jd ) )
;
; Return scalar or string?
  if info[0] ne 0 and n_elements(jd) eq 1 then $
     return,[s] $
  else $
     return,s
;
  end
