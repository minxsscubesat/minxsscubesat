;this is a standard function in FORTRAN to return a number with the same
;magnitude as a, with the sign of b.
function dsign,a,b
  result=0*b+abs(a); This makes result the right size. if either a or b
                   ; is scalar and other vector, or both scalar, or both
                   ; are arrays of same size, this works
  OnAxis=(b lt 0)
  OnAxis=where(OnAxis,Count)
  if(Count ne 0) then begin
    result[OnAxis]*=-1;
  end
  return,result
end

;constrain a value to the range of +-q/2. Distinct from mlmod(),
;that constrains a value from 0-q
function constrain, a, q
  b = a mod q
  neg = where(b lt -q/2, count)
  if count gt 0 then b[neg] = b[neg]+q
  neg = where(b gt q/2, count)
  if count gt 0 then b[neg] = b[neg]-q
  return, b
end

pro idl_geodetic,r,z,phi,h,a=a,f=f
;   converts (r,z), the in-equatorial-plane and out-of-plane components of a
;   a cartesian earth-centered vector, into (phi,h)
;   containing geodetic latitude in radians, and altitude above
;   ellipsoid, in that order. North latitudes are positive
;   numbers. The inputs may scalar or array, as long as they are compatible
;   with eachother. The outputs will be scalar or array depending on the inputs.
;
;   The distance unit used in the input vector matches the distance unit used
;   for the ellipsoid radius, kilometers by default.
;
;   Optional parameters a and flat set up a custom ellipsoid. A is the
;   equatorial radius of the ellipsoid and flat is the flattening ratio
;   (f=1-a/b, where b is the polar radius). Lat and lon remain in radians, and
;   the units of alt are the same as A. By default, this function uses the size
;   and shape of the WGS-84 ellipsoid, in kilometers.
;
;   This is a straightforward implemtation of the algorithm presented in
;   KAZIMIERZ M. BORKOWSKI, TRANSFORMATION OF GEOCENTRIC TO GEODETIC
;   COORDINATES WITHOUT APPROXIMATIONS, Astrophysics and Space Science, 139 (1987), 1-4
;                                       Erratum: vol. 146, (No. 1, July 1988), 201
;   http://www.astro.uni.torun.pl/~kb/Papers/geod/Geod-GK.htm (in polish,
;   but contains fortran code commented in english)
;   http://www.astro.uni.torun.pl/~kb/Papers/ASS/Geod-ASS.htm (Derivation
;   in english)
;   This algorithm is used because it requires no iterations, and can therefore
;   be easily vectorized. An entire grid of input coordinates are done at once,
;   using the full-blown IDL array operation optimization.
;
;   There is a singlarity in the algorithm at the equator and pole. In cases where
;   the input value is exactly on the equator (z=0) or axis (x=y=0) this is detected
;   and handled properly. There seems to be no loss of precision close to the equator,
;   but there is a minor loss of precision near the pole. It is subtracting two nearly
;   equal numbers there. This causes errors of as much as a few centimeters a millionth
;   of a degree from the pole. See, I said it was minor.
;
;   Example: The south goalpost at Folsom Field, University of Colorado
;   at Boulder is located at ECEF location:
;     R (km)          Z (km)
;   -------------  ------------
;    4893.3082884  4079.7783407
;
;IDL> idl_geodetic,4893.3082884d,4079.7783407d,phi,h
;IDL> print,phi,h,format='(%"%18.14f")'
;  0.69828684115784
;  1.61259991304178
;
;

  ;Default WGS-84 ellipsoid if none is specified
  ;if n_elements(a)    eq 0 then a=6378.137d
  ;if n_elements(flat) eq 0 then flat=1.0d/298.257223563d
  ;WGS-72 constants
  if n_elements(a)    eq 0 then a=6378.135d
  if n_elements(flat) eq 0 then flat=1.0d/298.26d

  ; Set the size for the return vars
  phi=z;
  h=z;

  ; x or y should not appear below here
  ; Ellipsoid polar radius, with same sign as z
  b=dsign(a*(1.0d - flat),z);

  ; On the rotation axis?
  OnAxis=where((0.0d eq r),nOnAxis,complement=NotOnAxis,ncomplement=nNotOnAxis)
  if(nNotOnAxis ne 0) then begin
    ; Not on the rotation axis.
    ; On the equator?
    OnEqu=where(NotOnAxis and (0.0d eq z),nOnEqu,complement=NotOnEqu,ncomplement=nNotOnEqu)
    if(nNotOnEqu ne 0) then begin
      ;Not on equator or axis, chug through the hard part
      ;All of these variable names match those given in Borkowski
      E=((z[NotOnEqu]+b[NotOnEqu])*b[NotOnEqu]/a-a)/r[NotOnEqu];
      F=((z[NotOnEqu]-b[NotOnEqu])*b[NotOnEqu]/a+a)/r[NotOnEqu];
      P=4.0d*(E*F+1.0d)/3.0d;
      Q=(E^2.0d -F^2.0d)*2.0d;
      D=P^3.0d +Q^2.0d;
      s=sqrt(D)+Q;
      s=dsign(abs(s)^(1.0d/3.0d),s);
      v=P/s-s;
      v=-(2.0d*Q+v^3.0d)/(3.0d*P);
      G=(E+sqrt(E^2.0d +v))/2.0d;
      t=sqrt(G^2.0d +(F-v*G)/(2*G-E))-G;
      phi[NotOnEqu]=atan((1.0d -t*t)*a/(2.0d*b[NotOnEqu]*t));
      h[NotOnEqu]=(r[NotOnEqu]-a*t)*cos(phi[NotOnEqu])+(z[NotOnEqu]-b[NotOnEqu])*sin(phi[NotOnEqu]);
    end
    if(nOnEqu ne 0) then begin
      ; On the equatorial plane. Shortcut.
      phi[OnEqu]=0d;
      h[OnEqu]=r[OnEqu]-a;
    end
  end
  if(nOnAxis ne 0) then begin
    ; On the axis. Shortcut
    phi[OnAxis]=dsign(!dpi/2.0d,z[OnAxis]);
    h[OnAxis]=abs(z[OnAxis])-abs(b[OnAxis]);
  end
end