  function sd2vms, sd

; Translates SORCE mission day numbers (SORCE day 0.0 = 2003/024.0) to
; VMS-formatted date/time strings of the form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(sd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," SD2VMS translates SORCE mission day numbers (SORCE day 0.0 = "
     print," 2003/024.0 = 2003 Jan 24.0) to VMS date/time strings of the  "
     print," form 'dd-mmm-yyyy hh:mm:ss.ss. The input argument may be a   "
     print," scalar or array.                                             "
     print,"                                                              "
     print," vms = sd2vms( sd )                                           "
     return,''
  endif
;
  s = md2vms(sd,2003024.0d0)
;
; Return scalar or array?
  if info[0] ne 0 and n_elements(sd) eq 1 then $
     return, [s] $
  else $
     return, s
;
  end
