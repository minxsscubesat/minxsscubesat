; main_program xud2ymd
;
; Unit tester for ud2ymd.pro and ymd2ud.pro
;
; B. Knapp, 2001-12-10
;
; Generate an array of random UARS dates
  n = 1000L
  ud = randomu( seed, n )*2500.d0
;
  ymd = ud2ymd( ud )
  u2 = ymd2ud( ymd[0],ymd[1],ymd[2] )
;
  du = where( abs(ud-u2) gt 1e8, nd )
  if nd gt 0 then begin
     for j=0,nd-1 do $
        print,ud[j],u2[j],ud[j]-u2[j],format="(2f25.10,e12.3)"
     print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
  endelse
;
  end
