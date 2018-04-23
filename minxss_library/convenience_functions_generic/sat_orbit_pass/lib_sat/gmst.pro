;Given Time in GPS microseconds 
;return the Greenwich Mean Siderial Time, in degrees. This is defined as the
;right ascension of the celestial meridian which is over Greenwich at this time

function gmst,Time,julian=julian
  if keyword_set(julian) then jd=time else JD=usec2jd(Time)
  J2000=2451545.0d; julday(1,1,2000,12,0,0)
  d=JD-J2000;
;  return,mlmod(280.46061837d + 360.98564736629d*d,360.0d)

  T=(JD-J2000)/36525.0d;
  thetag=poly(T,[67310.54841d,(876600d*3600d +8640184.812866d),0.093104d,-6.2d-6])
  thetag=thetag mod 86400d
  thetag=thetag/240d
  thetag=mlmod(thetag,360)
  return,thetag
end
