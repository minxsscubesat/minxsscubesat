;Function LLR_to_XYZ
;  Convert a given location relative to a sphere in lat,lon,and distance,
;  into an equivalent cartesian vector
;
;Input
;  LLR - A grid of vectors. First element is geocentric latitude in radians,
;        second is longitude in radians, third is distance from the center of the sphere
;Keyword input
;  sid - Greenwich Mean Siderial time, in radians. If set appropriately,
;        returned vector will be in ECI rather than ECEF. Defaults to zero, giving ECEF
;Returns
;  A grid of xyz vectors, in the same length unit as distance input
function llr_to_xyz,llr,sid=sid
  if n_elements(sid) eq 0 then sid=0
  resolve_grid,llr,x=lat,y=lon,z=r
  lon+=sid
  x = r * cos(lat) * cos(lon);
  y = r * cos(lat) * sin(lon);
  z = r * sin(lat);
  return,compose_grid(x,y,z);

end
