; main_program xvmstime
;
; Unit tester for function vmstime
;
; B. Knapp, 98.06.09
;
  old = !stime
  new = vmstime()
  print, old
  print, new
  print, (vms2jd( old )-vms2jd( new ))*86400.d0
;
  end