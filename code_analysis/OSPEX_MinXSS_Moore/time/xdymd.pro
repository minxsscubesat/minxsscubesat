; main_program xdymd
;
; Unit tester for dymd.pro
;
; B. Knapp, 97.11.13
;           98.06.09, IDL v. 5 compliance
;
; Both arguments scalar
  ymd1 = vms2ymd(vmstime())
  ymdn = ymd2(ymd1,100.0d0)
  d1 = dymd(ymd1,ymdn)
  print,ymd1,ymdn,d1,format="(3f20.8)"
;
; Scalar ymd1, vector ymdn
  nv = 11
  dv = dindgen(nv)-nv/2
  ymdv = ymd2(ymd1,dv)
  dvx = dymd(ymd1,ymdv)
;
; Vector ymd1, scalar ymdn
  dvy = dymd(ymdv,ymd1)
;
; Vector ymd1, ymdn
  ymdvvm = ymd2(ymdv,-dv)
  ymdvvp = ymd2(ymdv,dv)
  ddv = dymd(ymdvvm,ymdvvp)
;
  end
