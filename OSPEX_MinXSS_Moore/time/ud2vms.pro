  function ud2vms, ud

; Translates UARS mission day numbers (UARS day 0.0 = 1991/254.0) to
; VMS-formatted date/time strings of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(ud)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  UD2VMS translates UARS mission day numbers (UARS day 0.0 =   "
     print,"  1991/254.0 = 1991 Sep 11.0) to VMS date/time strings of the  "
     print,"  form 'dd-mmm-yyyy hh:mm:ss.ss. The input argument may be a   "
     print,"  scalar or array.                                             "
     print,"                                                               "
     print,"  vms = ud2vms( ud )                                           "
     return,''
  endif
;
  s = md2vms(ud,1991254)
;
; Return scalar or array?
  if info[0] ne 0 and n_elements(ud) eq 1 then $
     return, [s] $
  else $
     return, s
;
  end
