function PRECESS_MATRIX, T
;
;     OBTAIN THE 3 X 3 ROTATION MATRIX WHICH WILL APPLY THE PRECESSION
;     AT DYNAMIC TIME T (JULIAN MILLENIA SINCE J2000)
;
;     T. Woods  02-05-2016
;
;     REFERENCE: J2000 ECI transformation to ECF W-84

	D2R = 3.14159265358979324D0/180.D0
	S2R = (1.D0/3600.D0)*D2R ;(CONVERT UNITS OF ARC SECONDS TO RADIANS)

	; convert equation of arc-sec into radians
	eps = (23062.181D0 * T + 30.188D0 * T^2. + 17.998 * T^3.) * S2R
	sinE = sin(eps)
	cosE = cos(eps)
	zeta = (23062.181D0 * T + 109.468D0* T^2. + 18.203 * T^3.) * S2R
	sinZ = sin(zeta)
	cosZ = cos(zeta)
	theta = (20043.109D0* T - 42.665D0 * T^2. - 41.833 * T^3.) * S2R
	sinT = sin(theta)
	cosT = cos(theta)

      P=dblarr(3,3)
	  P[0,0] =  cosZ * cosT * cosE - sinZ * sinE
      P[0,1] = -1.*cosZ*cosT*sinE - sinZ*cosE
      P[0,2] = -1.*cosZ*sinT
      P[1,0] =  sinZ * cosT * cosE + cosZ * sinE
      P[1,1] =  -1.*sinZ*cosT*sinE + cosZ*cosE
      P[1,2] =  -1.*sinZ*sinT
      P[2,0] =  sinT * cosE
      P[2,1] =  -1.*sinT * sinE
      P[2,2] =  cosT

      RETURN,P

END
