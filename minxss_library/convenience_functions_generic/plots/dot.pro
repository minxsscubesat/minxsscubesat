;
;	dot.pro
;	User symbol for plotting that is a dot
;
;	Pankratz
;
pro dot,large=large,usersym=usersym,help=help

if keyword_set(help) then begin
  message,/info,'USAGE: IDL> dot[,/large,usersym=usersym]
  print,'               /large  - defines a large dot'
  print,'               usersym - returns array of the vertices for the defined symbol'
  return
end

if keyword_set(large) then radius=1.0 else radius=4.0

theta = 360. * (findgen(21) / 20.0) / !radeg
usersym=transpose(reform([cos(theta)/radius,sin(theta)/radius],21,2))
usersym, usersym

return
end
