function gps2vms, gps

; Translates double precision TAI seconds since the GPS epoch (1980 Jan
; 6.0) to VMS-formatted date/time strings of the form 'dd-mmm-yyyy
; hh:mm:ss.ss'. 

; N. Kungsakawin 02.02.07
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(gps)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  GPS2VMS translates its argument, double precision TAI seconds "
     print,"  since the GPS epoch (1980 Jan 6.0) to VMS date/time strings of the  "
     print,"  form 'dd-mmm-yyyy hh:mm:ss.ss. The input argument may be a   "
     print,"  scalar or array.                                             "
     print,"                                                               "
     print,"  vms = gps2vms( gps )                                           "
     return,''
  endif
;
  s = jd2vms(gps2jd(gps))
;
; Return scalar or array?
  if info[0] ne 0 and n_elements(gps) eq 1 then $
     return, [s] $
  else $
     return, s
;
  end
