; main_program xsd2yd
;
; Unit tester for sd2yd.pro and yd2sd.pro
;
; B. Knapp, 2001-12-10
;
; Generate an array of random UARS dates
  n = 1000L
  sd = randomu( seed, n )*2500.d0
;
  yd = sd2yd( sd )
  u2 = yd2sd( yd )
;
  du = where( abs(sd-u2) gt 1e8, nd )
  if nd gt 0 then begin
     for j=0,nd-1 do $
        print,sd[j],u2[j],sd[j]-u2[j],format="(2f25.10,e12.3)"
     print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
  endelse
;
  end
