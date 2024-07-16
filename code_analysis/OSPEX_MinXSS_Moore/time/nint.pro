FUNCTION nint,x

; IDL version of Fortran's NINT function;
; Result is long integer type.

; B. G. Knapp, 86/05/09

  rnd = DOUBLE(x GT 0)-0.5
  RETURN,LONG(x+rnd)

END
