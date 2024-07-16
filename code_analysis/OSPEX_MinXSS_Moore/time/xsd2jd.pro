; main_program xsd2jd
;
; Unit tester for sd2jd.pro and jd2sd.pro
;
; B. Knapp, 97.11.13
;           98.06.09, IDL v. 5 compliance
;
; Generate an array of random UARS dates
  n = 1000L
  sd = randomu( seed, n )*2500.d0
;
  jd = sd2jd( sd )
  u2 = jd2sd( jd )
;
  du = where( sd ne u2, nd )
  if nd gt 0 then begin
    for j=0,nd-1 do $
      print,sd[j],u2[j],sd[j]-u2[j],format="(2f25.10,e12.3)"
    print, 'Test failed!'
  endif else begin
     print, 'Test passed.'
   endelse
   
   end

 
