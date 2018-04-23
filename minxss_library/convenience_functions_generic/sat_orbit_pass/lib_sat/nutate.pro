;Calculate IAU 1980 Nutation model
; input
;   T    - kiloyears past J2000 TDT
; output
;   4 element array [dpsi,deps,ddpsi,ddeps]
;   dpsi - Nutation in longitude, rad
;   deps - Nutation in obliquity, rad
;   ddpsi- rate of nutation in longitude, rad/kiloyear
;   ddeps- rate of nutation in obliquity, rad/kiloyear
function nutate,T
  if n_elements(t) gt 1 then begin
    ;Handle the array case
    result=dblarr(n_elements(t),4)
    for i=0,n_elements(t)-1 do result[i,*]=nutate(t[i])
    return,result
  end
  D2R = 3.14159265358979324D0/180.D0
  S2R = 1.D-4/3600.D0*D2R ;(CONVERT UNITS OF 10000 ARC SECONDS TO RADIANS)

  ;Column labels for nutate_table
  CM=0
  CE=1
  CF=2
  CD=3
  CO=4
  PSI0=5
  PSI1=6
  EPS0=7
  EPS1=8

  ;Polynomials, all in deg/kiloyear^i
  ;     MEAN ANOMALY OF THE MOON
  PM=[ 1.349629813888889D+2,  4.771988673980556D+6, 8.697222222222222D-1,  1.777777777777778D-2]

  ;     MEAN ANOMALY OF THE SUN (EARTH)
  PE=[ 3.575277233333333D+2,  3.599905034000000D+5,-1.602777777777778D-2, -3.333333333333333D-3]

  ;     MOON'S ARGUMENT OF LATITUDE
  PF=[ 9.327191027777778D+1,  4.832020175380556D+6,-3.682500000000000D-1,  3.055555555555556D-3]

  ;     MEAN ELONGATION OF THE MOON FROM THE SUN
  PD=[ 2.978503630555556D+2,  4.452671114800000D+6,-1.914166666666667D-1,  5.277777777777778D-3]

  ;   LONGITUDE OF THE ASCENDING NODE OF THE MOON'S MEAN ORBIT ON THE
  ;   ECLIPTIC, MEASURED FROM THE MEAN EQUINOX OF THE DATE
  PO=[ 1.250445222222222D+2, -1.934136260833333D+4, 2.070833333333333D-1,  2.222222222222222D-3]

  common nutate,n
  if n_elements(n) eq 0 then n=nutation_const()

  ;   EVALUATE THE FUNDAMENTAL ARGUMENTS
  M   = poly(T,PM);
  D_M = poly(T,(indgen(4)*PM)[1:3]);
  E   = poly(T,PE);
  D_E = poly(T,(indgen(4)*PE)[1:3]);
  F   = poly(T,PF);
  D_F = poly(T,(indgen(4)*PF)[1:3]);
  D   = poly(T,PD);
  D_D = poly(T,(indgen(4)*PD)[1:3]);
  O   = poly(T,PO);
  D_O = poly(T,(indgen(4)*PO)[1:3]);

; COMPUTE THE SUM OF ALL TERMS
  DPSI = 0.D0
  DEPS = 0.D0
  DDPSI = 0.D0
  DDEPS = 0.D0
  L  =  ((n[*,CM]* M   + n[*,CE]* E   + n[*,CF]* F   + n[*,CD]* D   + n[*,CO]* O) mod 360.D0 )*D2R
  D_L = ( n[*,CM]* D_M + n[*,CE]* D_E + n[*,CF]* D_F + n[*,CD]* D_D + n[*,CO]* D_O           )*D2R
  SL = SIN( L )
  CL = COS( L )
  PSI = n[*,PSI0] + n[*,PSI1]*T
  EPS = n[*,EPS0] + n[*,EPS1]*T
  DPSI = total(PSI*SL)*S2R
  DEPS = total(EPS*CL)*S2R
  DDPSI = total(PSI*CL*D_L + SL*n[*,PSI1])*S2R
  DDEPS = total(EPS*SL*D_L + CL*n[*,EPS1])*S2R

  return,[DPSI,DEPS,DDPSI,DDEPS]

end
