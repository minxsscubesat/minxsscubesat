  function yd2vms, yd

; Given date(s) in the form of yyyyddd.dd, returns VMS date
; string(s) of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2VMS translates dates of the form yyyyddd.dd to VMS date   "
     print,"  strings of the form 'dd-mmm-yyyy hh:mm:ss.ss. The input      "
     print,"  argument may be a scalar or array of a 4-byte or 8-byte      "
     print,"  numerical type.                                              "
     print,"                                                               "
     print,"  vms = yd2vms( yd )                                           "
     return,''
  endif
;
  s = ymd2vms( yd2ymd( yd ) )
;
; Return scalar or string?
  if info[0] ne 0 and n_elements(yd) eq 1 then $
     return,[s] $
  else $
     return,s
;
  end
