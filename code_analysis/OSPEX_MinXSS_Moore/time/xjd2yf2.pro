; main_program xjd2yf2
;
; Unit tester for jd2yf2.pro and yf22jd.pto
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Scalar input
  jd1 = (vms2jd(vmstime()))[0]
  yf1 = jd2yf2(jd1)
  jd2 = yf22jd(yf1)
;  help, jd1, yf1, jd2
  if (jd1-jd2) ne 0 then begin
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
; Vector input
  jd3 = jd1+dindgen(5)*1000.
  yf3 = jd2yf2(jd3)
  jd4 = yf22jd(yf3)
;  help, jd3,yf3,jd4
  for i=0, n_elements(jd3)-1 do begin
    if (jd3[i]-jd4[i]) ne 0 then begin
      print, "Test failed"
    endif else begin
      print, "Test passed"
    endelse
  endfor
  
;
  end
