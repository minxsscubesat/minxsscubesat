function SIDTIME_MATRIX, T, Bdot=Bdot
;
;     OBTAIN THE 3 X 3 ROTATION MATRIX WHICH WILL APPLY THE SIDERIAL TIME change
;     AT DYNAMIC TIME T (JULIAN MILLENIA SINCE J2000)
;
;     T. Woods  02-05-2016
;
;     REFERENCE: J2000 ECI transformation to ECF W-84

	D2R = 3.14159265358979324D0/180.D0
	S2R = (1.D0/3600.D0)*D2R ;(CONVERT UNITS OF ARC SECONDS TO RADIANS)

	; convert equation of arc-sec into radians
	FTU = T*1000.*365.25D0	; JD days float
	LTU = long(FTU)
	TU = (LTU+0.5D0) / (365.25D0*1000.)  ; convert back to JD per century
	deltaTime = (FTU - LTU) *24.D0*3600.D0  ; seconds of day above LTU
	E = (84381.448 - 468.150D0 * T - 0.059 * T^2. + 1.813 * T^3.)*S2R
	cosE = cos(E)
	deltaH = atan(cosE)
	H = (24110.54841D0 + 86401848.12866D0 * TU + 9.3104 * TU^2. - 6.2D-3 * TU^3. )*S2R
	w = (7.2921158553D-5 + 4.3D-14 * TU)*S2R
	A = H + deltaH + w*deltaTime
	sinA = sin(A)
	cosA = cos(A)

	stop, 'DEBUG as this is not working right ...'

      B=dblarr(3,3)
	  B[0,0] =  cosA
      B[0,1] = sinA
      B[0,2] = 0.0
      B[1,0] =  -1.*sinA
      B[1,1] =  cosA
      B[1,2] =  0.0
      B[2,0] =  0.0
      B[2,1] =  0.0
      B[2,2] =  1.0

      Bdot=dblarr(3,3)
	  Bdot[0,0] =  -1.*w*sinA
      Bdot[0,1] = w*cosA
      Bdot[0,2] = 0.0
      Bdot[1,0] =  -1.*w*cosA
      Bdot[1,1] =  -1.*w*sinA
      Bdot[1,2] =  0.0
      Bdot[2,0] =  0.0
      Bdot[2,1] =  0.0
      Bdot[2,2] =  0.0

      RETURN,B

END
