  function md2vms, md, epoch

; Translates mission day numbers to VMS-formatted date/time strings of the
; form 'dd-mmm-yyyy hh:mm:ss.ss'.

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(md)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  MD2VMS translates mission day numbers to VMS date/time "
     print,"  strings of the form 'dd-mmm-yyyy hh:mm:ss.ss. The input "
     print,"  argument may be a scalar or array.    "
     print,"                                                               "
     print,"  vms = md2vms( md, epoch )                                           "
     return,''
   endif
;
   s = ymd2vms( md2ymd( md, epoch ) )
;
; Return scalar or array?
   if info[0] ne 0 and n_elements(md) eq 1 then $
     return, [s] $
   else $
     return, s
;
 end
