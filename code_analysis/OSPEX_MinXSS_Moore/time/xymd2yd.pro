; main_program xymd2yd
;
; Unit tester for ymd2yd.pro
;
; B. Knapp, 97.11.11
;
  dfmt = "(f20.8)"
;
; Single date y, m, d
  out1 = ymd2yd( 1997, 11, 11.12345d0 )
  ;print, out, format=dfmt
  ;print,' '
;
; Single date [y,m,d]
  out2 = ymd2yd( [1997,11,11.12345d0] )
  ;print, out, format=dfmt
  ;print,' '
  if out1[0]-out2[0] gt 0 then begin
    print, "Test Failed"
  endif else begin
    print, "Test passed"
  endelse
  
;
; Multiple dates, three arrays
  n = 5
  y = replicate(1997,5)
  m = replicate(11,5)
  d = 11+dindgen(5)/10
  
  out3 = ymd2yd(y,m,d)
  ;print, out, format=dfmt
  ;print,' '
;
; Multiple dates, two-dimensional array
  ymd = transpose( [ [y],[m],[d] ] )
  out4 = ymd2yd(ymd)
  ;print, out, format=dfmt
;
  for i=0,4 do begin
    if out3[i]-out4[i] gt 0 then begin
      print, "Test Failed"
    endif else begin
      print, "Test passed"
    endelse
  endfor
  
end
