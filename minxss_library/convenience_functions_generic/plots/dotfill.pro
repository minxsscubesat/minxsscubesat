;
;	dotfill.pro
;	User symbol for plotting that is a dot
;
;	Pankratz
;	Revised dot.pro to have filled dot
;
pro dotfill,large=large,usersym=usersym,help=help,radius=radius

if keyword_set(help) then begin
  message,/info,'USAGE: IDL> dotfill[,/large,usersym=usersym,radius=radius,/help]
  print,'               /large  - defines a large dot'
  print,'               usersym - returns array of the vertices for the defined symbol'
  print,'               radius - specifies fractional radius (0.0-1.0) instead of default values'
  print,'               /help - prints this message'
  return
end

MIN_RADIUS = 0.25
LARGE_RADIUS = 2.0
if keyword_set(radius) then begin
  ;  assumes radius input is 0.0-1.0
  radius = radius * LARGE_RADIUS
  if radius lt MIN_RADIUS then radius = MIN_RADIUS
endif else begin
  if keyword_set(large) then radius=LARGE_RADIUS else radius=LARGE_RADIUS/3.
endelse

npts = 16L
theta = 360. * (findgen(npts+1) / npts) / !radeg
usersym=transpose(reform([cos(theta)*radius,sin(theta)*radius],npts+1,2))
usersym, usersym, /fill

return
end
