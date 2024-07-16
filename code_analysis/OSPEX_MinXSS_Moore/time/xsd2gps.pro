; main_program xsd2gps
;
; Unit tester for sd2gps.pro and gps2sd.pro
;
; B. Knapp, 2001-12-10
;
; Generate an array of random UARS dates
  n = 1000L
  sd = randomu( seed, n )*2500.d0
;
  gps = sd2gps( sd )
  u2 = gps2sd( gps )
;
  du = where( sd ne u2, nd )
  if nd gt 0 then begin
     for j=0,nd-1 do $
        print,sd[j],u2[j],sd[j]-u2[j],format="(2f25.10,e12.3)"
     print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
  endelse
;
  end
