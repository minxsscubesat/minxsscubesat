; main_program xymd2
;
; Unit tester for ymd2.pro
;
; B. Knapp, 97.11.13
;           98.06.09, IDL v. 5 compliance
;
; Both arguments scalar
  ymd1 = vms2ymd(vmstime())
  ymdm = ymd2(ymd1,-1000)
  ymdp = ymd2(ymd1,1000)
  print,ymdm,ymd1,ymdp,format="(f8.1,f6.1,f13.8)"
;
; Scalar ymd, vector d
  nv = 11
  d = dindgen(nv)-nv/2
  ymdo = ymd2(ymd1,d)
;
; Vector ymd, scalar d
  ymdv = jd2ymd(2450000.0d0+randomu(seed,nv)*1000.d0)
  ymdvm = ymd2(ymdv,-1000)
  ymdvp = ymd2(ymdv,1000)
;
; Vector ymd, d
  dv = dindgen(nv)*100
  ymdvvm = ymd2(ymdv,-dv)
  ymdvvp = ymd2(ymdv,dv)
;
  end
