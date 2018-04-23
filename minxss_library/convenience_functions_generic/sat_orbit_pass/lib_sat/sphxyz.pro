pro sphxyz, mode, sph, xyz, dsph, dxyz
;
; Convert position & velocity (and uncertainties) from spherical to 
; rectangular coordinates (mode = +1) or from rectangular to spherical 
; (mode = -1).
;
; B. Knapp, 1999-06-08, 2001-10-15
;           2003-11-04, accept array inputs
;           2003-11-11, handle uncertainties
;
; Input/Output (one each):
;
; i   (d)sph                              (d)xyz
;
; 0   Lon or RA  (rad, 0 TO 2*pi)         X (length unit)
; 1   Lat or Dec (rad, -pi to +pi)        Y (length unit)
; 2   Radius (length unit)                Z (length unit)
; 3   dLon/dT or dRA/dT (rad/time unit)   dX/dT (length unit/time unit)
; 4   dLat/dT or dDEC/dT (rad/time unit)  dY/dT (length unit/time unit)
; 5   dR/dT (length unit/time unit)       dZ/dT (length unit/time unit)
;
; Note: the notation used in the following is:
;   x, y, z, xV, yV, zV -- the rectangular coordinates & velocities
;   t, p, r, tV, pV, rV -- the spherical coordinates & velocities
;     (t for theta, the equatorial angle, p for phi the polar angle)
;   The prefix "d" is used both for uncertainties (e.g., dpV) and
;   for derivatives (e.g., dxdr).
;
  compile_opt idl2
;
  case mode of
;
    +1: begin
      info = size(sph)
      if info[0] eq 1 then $
        xyz = dblarr(6) $
      else $
        xyz = dblarr(6,info[2])
;
;     Position
      st = sin( double(sph[0,*]) )
      ct = cos( double(sph[0,*]) )
      sp = sin( double(sph[1,*]) )
      cp = cos( double(sph[1,*]) )
      r = double(sph[2,*])
      xyz[0,*] = r*cp*ct
      xyz[1,*] = r*cp*st
      xyz[2,*] = r*sp
;
;     Velocity
      dxdr =    cp*ct
      dxdp = -r*sp*ct
      dxdt = -r*cp*st
      dydr =    cp*st
      dydp = -r*sp*st
      dydt =  r*cp*ct
      dzdr =    sp
      dzdp =  r*cp
      tV = double(sph[3,*])
      pV = double(sph[4,*])
      rV = double(sph[5,*])
      xyz[3,*] = dxdr*rV + dxdp*pV + dxdt*tV
      xyz[4,*] = dydr*rV + dydp*pV + dydt*tV
      xyz[5,*] = dzdr*rV + dzdp*pV

      if n_params() eq 5 then begin

        dxyz = xyz
;
;       Uncertainty in position
        dt = double( dsph[0,*] )
        dp = double( dsph[1,*] )
        dr = double( dsph[2,*] )
        dxyz[0,*] = sqrt( (dxdt*dt)^2 + (dxdp*dp)^2 + (dxdr*dr)^2 )
        dxyz[1,*] = sqrt( (dydt*dt)^2 + (dydp*dp)^2 + (dydr*dr)^2 )
        dxyz[2,*] = sqrt(               (dzdp*dp)^2 + (dzdr*dr)^2 )
;
;       Uncertainty in velocity
        dxdpdp = -r*cp*ct
        dxdtdt = dxdpdp
        dxdrdp =   -sp*ct
        dxdrdt =   -cp*st
        dxdpdt =  r*sp*st
        dydpdp = -r*cp*st
        dydtdt = dydpdp
        dydrdp =   -sp*st
        dydrdt =    cp*ct
        dydpdt = -r*sp*ct
        dzdpdp = -r*sp
        dzdrdp =    cp

        dtV = double( dsph[3,*] )
        dpV = double( dsph[4,*] )
        drV = double( dsph[5,*] )
        dxyz[3,*] = sqrt( $
          ( (dxdtdt*tV + dxdpdt*pV + dxdrdt*rV)*dt )^2 + $
          ( (dxdpdt*tV + dxdpdp*pV + dxdrdp*rV)*dp )^2 + $
          ( (dxdrdt*tV + dxdrdp*pV            )*dr )^2 + $
          (dxdt*dtV)^2 + (dxdp*dpV)^2 + (dxdr*drV)^2 )
        dxyz[4,*] = sqrt( $
          ( (dydtdt*tV + dydpdt*pV + dydrdt*rV)*dt )^2 + $
          ( (dydpdt*tV + dydpdp*pV + dydrdp*rV)*dp )^2 + $
          ( (dydrdt*tV + dydrdp*pV            )*dr )^2 + $
          (dydt*dtV)^2 + (dydp*dPV)^2 + (dydr*drV)^2 )
        dxyz[5,*] = sqrt( $
          ( (            dzdpdp*pV + dzdrdp*rV)*dp )^2 + $
          ( (                        dzdrdp*pV)*dr )^2 + $
                        (dzdp*dpV)^2 + (dzdr*drV)^2 )
      endif
    end
;
    -1: begin
      info = size(xyz)
      if info[0] eq 1 then $
        sph = dblarr(6) $
      else $
        sph = dblarr(6,info[2])
;
;     Position
      x = double(xyz[0,*])
      y = double(xyz[1,*])
      z = double(xyz[2,*])
      r = sqrt(x^2 + y^2 + z^2)
      t = atan( y, x )
      ltz = where(t lt 0., nltz)
      if nltz gt 0 then t[ltz] = t[ltz] + 2.d0*!dpi
      sph[0,*] = t
      zr = z/r
      sph[1,*] = asin( zr )
      sph[2,*] = r
;
;     Velocity
      xV = double(xyz[3,*])
      yV = double(xyz[4,*])
      zV = double(xyz[5,*])
      q2 = x^2 + y^2
      q = sqrt(q2)
      rV = (x*xV+y*yV+z*zV)/r
      tV = (x*yV-y*xV)/q2
      qr = q*r
      pV = (r*zV-z*rV)/qr
      sph[3,*] = tV
      sph[4,*] = pV
      sph[5,*] = rV
;
      if n_params() eq 5 then begin

        dsph = sph

;       Position uncertainty
        dx = double(dxyz[0,*])
        dy = double(dxyz[1,*])
        dz = double(dxyz[2,*])
        dr = sqrt( (x*dx)^2 + (y*dy)^2 + (z*dz)^2 )/r
        dsph[0,*] = sqrt( (y*dx)^2 + (x*dy)^2 )/q2
        dsph[1,*] = sqrt( (r*dz)^2 + (z*dr)^2 )/qr
        dsph[2,*] = dr
;
;       Velocity uncertainty
        dxV = double(dxyz[3,*])
        dyV = double(dxyz[4,*])
        dzV = double(dxyz[5,*])
        dsph[3,*] = sqrt( ((yV-2.d0*tV*x)*dx)^2 + $
                          ((xV+2.d0*tV*y)*dy)^2 + $
                          (y*dxV)^2 + (x*dyV)^2 )/q2
        qq = r/q + q/r
        zVr = zV/r
        rVr = rV/r
        dsph[4,*] = sqrt( $
          ((x*zVr   -(xV-x*rVr)*zr-pV*qq   *x)*dx)^2 + $
          ((y*zVr   -(yV-y*rVr)*zr-pV*qq   *y)*dy)^2 + $
          ((z*zVr-rV-(zV-z*rVr)*zr-pV*(q/r)*z)*dz)^2 + $
          (zr*x*dxV)^2 + (zr*y*dyV)^2 + (q2/r*dzV)^2)/qr

        dsph[5,*] = sqrt( $
          ((xV-x*rVr)*dx)^2 + $
          ((yV-y*rVr)*dy)^2 + $
          ((zV-z*rVr)*dz)^2 + $
          (x*dxV)^2 + (y*dyV)^2 + (z*dzV)^2 )/r
      endif
    end
;
    else: ;do nothing
  endcase
  return
end
