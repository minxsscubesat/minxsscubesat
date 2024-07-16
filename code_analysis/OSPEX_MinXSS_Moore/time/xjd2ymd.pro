; main_program xjd2ymd
;
; Unit tester for jd2ymd.pro and ymd2jd.pro
;
; B. Knapp, 2001-12-10
;
; Generate an array of random UARS dates
  n = 1000L
  jd = randomu( seed, n )*2500.d0
;
  ymd = jd2ymd( jd )
  u2 = ymd2jd( ymd[0],ymd[1],ymd[2] )
;
  du = where( abs(jd-u2) gt 1e8, nd )
  if nd gt 0 then begin
     for j=0,nd-1 do $
        print,jd[j],u2[j],jd[j]-u2[j],format="(2f25.10,e12.3)"
     print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
  endelse
;
  end
