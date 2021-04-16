  function nint32, x
;
; Return the nearest integer to argument x
;
; B. Knapp, 2000-12-12
;
  return, long(x+sign(x)*0.5d0)
  end
