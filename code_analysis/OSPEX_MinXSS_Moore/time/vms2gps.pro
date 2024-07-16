function vms2gps, vmsdate

; Given VMS-style date/time string 'dd-mmm-yyyy hh:mm:ss.ss',
; returns gps time

; N. Kungsakawin, 02.02.07
;           98.06.09, IDL v. 5 compliance

; Print usage?
    info = size(vmsdate, /type)
  if (info[0] ne 7) then begin
     print,"  VMS2GPS translates VMS date string(s) of the form             "
     print,"  'dd-mmm-yyyy hh:mm:ss.ss' (e.g., '31-oct-1985 23:59:59.99')  "
     print,"  to gps time     "
     print,"                                                               "
     print,"  gps = vms2gps( vmsdate )                                       "
  endif
;
  return, jd2gps(vms2jd(vmsdate))
;
  end
