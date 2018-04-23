pro pair_difference,tle1,tle2, dT, dR, dV, dRdT, dVdT
;
;     Compute the position and velocity errors propagating from tle(j1)
;     to tle(j2)
;
;     B. Knapp, 1999-08-19
;
      dT = tle2.jdEpoch-tle1.jdepoch

      sgp4core_sgp4,tle1,dT*1440.d0,rj1,vj1
      sgp4core_sgp4,tle2,0d,rj2,vj2

      dr=sqrt(total((rj1-rj2)^2))
      dv=sqrt(total((vj1-vj2)^2))
      drdt=dr/dt
      dvdt=dv/dt

end
