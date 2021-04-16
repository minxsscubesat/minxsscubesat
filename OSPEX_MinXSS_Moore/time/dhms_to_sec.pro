  function dhms_to_sec, dhms
;
; Convert a string of the form 'ddd hh:mm:ss.ss' to a long integer
; number of seconds.
;
; B. Knapp, 92.04.24
;
  dhms_local = strtrim( dhms, 2 )
  p = strpos( dhms_local, ' ' )
  d = double( strmid( dhms_local, 0, p ) )
  h = double( strmid( dhms_local, p+1, 2 ) )
  m = double( strmid( dhms_local, p+4, 2 ) )
  s = double( strmid( dhms_local, p+7, 5 ) )
;
  return, 86400.d0*d + 3600.d0*h + 60.d0*m + s
  end
