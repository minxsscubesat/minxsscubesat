; main_program xudtf_ms_dif
;
; Exercise driver for udtf_ms_dif
;
; B. Knapp, 98.09.24
;
; Scalar udtf times
  u2 = [98100l,10000000l]
  u1 = udtf_ms_add( u2, 100000l )
  dp = udtf_ms_dif( u1, u2 )
  dn = udtf_ms_dif( u2, u1 )
  if abs(dp)-abs(dn) ne 0 then begin
    
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
  
;
  end
