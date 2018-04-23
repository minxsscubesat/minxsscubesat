; main_program xyd2
;
; Unit tester for yd2.pro
;
; B. Knapp, 97.11.13
;           98.06.09, IDL v. 5 compliance
;
; Both arguments scalar
  yd1 = vms2yd(vmstime())
  ydm = yd2(yd1,-1000)
  ydp = yd2(yd1,1000)
  print,ydm,yd1,ydp,format="(3f20.8)"
;
; Scalar yd, vector d
  nv = 11
  d = dindgen(nv)-nv/2
  ydo = yd2(yd1,d)
;
; Vector yd, scalar d
  ydv = jd2yd(2450000.0d0+randomu(seed,nv)*1000.d0)
  ydvm = yd2(ydv,-1000)
  ydvp = yd2(ydv,1000)
;
; Vector yd, d
  dv = dindgen(nv)*100
  ydvvm = yd2(ydv,-dv)
  ydvvp = yd2(ydv,dv)
;
  end
