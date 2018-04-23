function gstime, jdut1
  twopi = 2.0d * !DPI;
  deg2rad = !DPI / 180.0d;

  tut1 = (jdut1 - 2451545.0d) / 36525.0d;
  a3=-6.2d-6* tut1 * tut1 * tut1;
  a2=+ 0.093104d * tut1 * tut1;
  a1=(876600.0d*3600 + 8640184.812866d) * tut1;
  a0=67310.54841d
  temp=a3+a2+a1+a0;
  temp = -6.2d-6* tut1 * tut1 * tut1 + 0.093104d * tut1 * tut1 + $
           (876600.0d*3600 + 8640184.812866d) * tut1 + 67310.54841d;  // sec
  temp = (temp * deg2rad / 240.0d) mod (twopi); //360/86400 = 1/240, to deg, to rad

  ; ------------------------ check quadrants ---------------------
  w=where(temp lt 0.0d,count)
  if count gt 0 then temp[w] += twopi;
  return,temp
end
