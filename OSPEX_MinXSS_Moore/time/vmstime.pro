  function vmstime
;
; Return system time formatted exactly as obsolete system variable
; !STIME, intended to be used to replace references to !STIME
;
; B. Knapp, 2000-01-04
;
  s = systime()
  m = ''
  d = ''
  t = ''
  y = ''
  reads, s, m, d, t, y, format="(4x,a3,x,a2,a9,x,a4)"
  return, d + '-' + m + '-' + y + t + '.00'
  end