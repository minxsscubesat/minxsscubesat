; main_program xjd2yd
;
; Unit tester for functions jd2yd.pro and yd2jd.pro
;
; B. Knapp, 97.11.11
;           98.06.09, IDL v. 5 compliance
;
; First, a known date
jd0 = 2448988.5d0               ;(1993 Jan 1.0)
jd = jd0
yd = jd2yd(jd)
jd2 = yd2jd(yd)
;  print,jd,yd,jd2, format="(3f18.6)"
if (jd-jd2) ne 0 then begin
  print, "Test failed"
endif else begin
  print, "Test passed"
endelse

;
; Now an array, starting from a known date
jd = jd0+dindgen(500)
yd = jd2yd(jd)
jd2 = yd2jd(yd)
; for j=0,499 do print,jd[j],yd[j],jd2[j],jd2[j]-jd[j],format="(4f18.6)"
bad = where(jd2 ne jd,nb)
if nb gt 0 then begin
  for j=0,nb-1 do begin
    print,jd[bad[j]],yd[bad[j]],jd2[bad[j]],format="(3f18.6)" 
    print,"test failed"
  endfor 
endif else begin
  print, "Test passed"
endelse

;
; Now some random dates
jd = randomu(seed,100000L)*2500000.0d0+1.d0
yd = jd2yd(jd)
jd2 = yd2jd(yd)
d = jd2-jd
bad = where(abs(d) ge 3.d-8, nb)
if nb gt 0 then begin
  for j=0,nb-1 do begin
    print,jd[bad[j]],yd[bad[j]],jd2[bad[j]],d[bad[j]],format="(3f18.6,e12.4)" 
    print,"Test failed"
  endfor
endif else begin
  
  print, "Test passed"
endelse


end
