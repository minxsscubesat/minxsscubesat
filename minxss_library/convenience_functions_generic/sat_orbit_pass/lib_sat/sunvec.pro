;Return a unit vector from the center of the Earth towards the center of the Sun
;on the given GPS microsecond 
;
;input
;  TT   - GPS microseconds
;  JD=  - Julian day number. Use this or TT, but not both.
;  /ecef - Set if you want ecef coordinates, otherwise you get eci coordinates
;  
;output
;  R=  - Distance to the Sun in AU
;  alpha= - Right ascension (or longitude in ECEF) of Sun, degrees
;  delta= - Declination (or latitude in ECEF) of Sun, degrees
;
;return
;  a unit vector from the center of the Earth towards the center of the Sun
;  on the given moment
;
;Example
; s=sunvec(jd=2451545d) ; S is vector from Earth to Sun on 1 Jan 2000 12:00UTC in ECI coordinates
;
;Based on low-precision formula in Astronomical Almanac
function SunVec,TT,jd=jd,ecef=ecef,R=R,alpha=alpha,delta=delta
  if n_elements(jd) eq 0 then JD=usec2jd(TT)
  n=JD-2451545d
  L=mlmod(280.460d +0.9856474d*n,360d)                             ;Mean lon of Sun
  g=mlmod(357.528d +0.9856003d*n,360d)                             ;Mean Anomaly
  lambda=L+1.915d*sin(g*!dpi/180d)+0.020d*sin(2d*g*!dpi/180d)      ;Ecliptic longitude of Sun from Equation of Center
  epsilon=23.439d -0.0000004d*n                                    ;Obliquity of axis
  f=180.d/!dpi
  t=tan(epsilon/2.d*!dpi/180.d)^2
  alpha=lambda-f*t*sin(2.d*lambda*!dpi/180.d)+(f/2.d)*t^2*sin(4.d*lambda*!dpi/180.d) ;Right ascension of Sun, degrees
  delta=asin(sin(epsilon*!dpi/180.d)*sin(lambda*!dpi/180.d))*180.d/!dpi              ;Declination of Sun, degrees
  R=1.00014-0.01671*cos(g*!dpi/180d)-0.00014*cos(2*g*!dpi/180d)                      ;Distance to Sun, AU
  if keyword_set(ecef) then alpha-=gmst(jd,/julian)                                  ;If ECEF, convert right ascension to longitude
  return,llr_to_xyz(compose_grid(delta*!dtor,alpha*!dtor,1))
end
