; main_program xdyd
;
; Unit tester for dyd.pro
;
; B. Knapp, 97.11.13
;           98.06.09, IDL v. 5 compliance
;
; Both arguments scalar
  yd1 = vms2yd(vmstime())
  ydn = yd2(yd1,100.0d0)
  d1 = dyd(yd1,ydn)
  print,yd1,ydn,d1,format="(3f20.8)"
;
; Scalar yd1, vector ydn
  nv = 11
  dv = dindgen(nv)-nv/2
  ydv = yd2(yd1,dv)
  dvx = dyd(yd1,ydv)
;
; Vector yd1, scalar ydn
  dvy = dyd(ydv,yd1)
;
; Vector yd1, ydn
  ydvvm = yd2(ydv,-dv)
  ydvvp = yd2(ydv,dv)
  ddv = dyd(ydvvm,ydvvp)
;
  end
