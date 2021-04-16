; main_program xyd2ymd
;
; Unit tester for function yd2ymd.pro
;
; B. Knapp, 97.11.11
;           98.06.09, IDL v. 5 compliance
;
  dfmt = "(f16.6,f8.1,f5.1,f11.6,f16.6)"
; Scalar argument
  yd = 1997001.123d0
  ymd = yd2ymd(yd)
  yd2 = ymd2yd(ymd)
;  print,yd,ymd,yd2,format=dfmt
  if (yd[0]-yd2[0]) ne 0 then begin
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
  
;
; Array argument
  yd = 1997001.12345d0+dindgen(60)
  ymd = yd2ymd(yd)
  yd2 = ymd2yd(ymd)
  for i=0,59 do begin
;  print,yd[j],ymd[*,j],yd2[j],format=dfmt
;
  if (yd[i]-yd2[i]) ne 0 then begin
    print, "Test failed"
  endif
endfor

end
