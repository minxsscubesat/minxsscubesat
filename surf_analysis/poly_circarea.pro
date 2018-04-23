function encircled, coords, radius, center

; Returns 1 if coords are within circle defined by radius and center, 0 otherwise
; Coords must be 2xN array (e.g. [[x],[y]])
; Center must be 2-element array (e.g. [xc,yc]), defaults to (0,0) if missing
; Returns bytarr of length N

npts = n_elements(coords)/2

if n_elements(radius) eq 0 then message, "Radius must be defined."
if n_elements(center) eq 0 then begin
  center = [0,0]
  message, /info, "WARNING: center not defined, defaulting to [0,0] ..."
endif

; Point is within circle if (x-xc)^2 + (y-yc)^2 <= radius (boundary counts as inside)
inside = (((coords[0,*] - center[0])^2 + (coords[1,*] - center[1])^2) le radius^2)

return, inside
end


function poly_circclip, coords, radius, center, intersect_inds = intersect_inds

; Returns coordinates of polygon clipped by circular mask, with polygon defined by coords and circle defined by radius and center
; Coords must be 2xN array (e.g. [[x],[y]]) of polygon vertices IN ORDER (clockwise or counter-clockwise)
; Polygon must be convex (concave not supported yet) and SMALLER than circle (such that there are either 0 or 2 intersections and no more)
; Center must be 2-element array (e.g. [xc,yc]), defaults to (0,0) if missing
; Returns coordinates (2xM) of new polygon defined by points contained within circle and the intersection points of the circle and polygon boundaries, -1 if no intersection (polygon wholly excluded)
; OPTIONALLY returns array indices of the intersection points, undefined if there are no intersections (polygon wholly excluded or included)

npts = n_elements(coords)/2

if n_elements(radius) eq 0 then message, "Radius must be defined."
if n_elements(center) eq 0 then begin
  center = [0,0]
  message, /info, "WARNING: center not defined, defaulting to [0,0] ..."
endif

; Translate to circle-centric coords and close polygon (repeat first point)
x = reform(coords[0,*] - center[0])  &  x = [x,x[0]]
y = reform(coords[1,*] - center[1])  &  y = [y,y[0]]

for i=0,npts-1 do begin
  ; If current point is inside the circle, add it to the output list
  P = [x[i],y[i]]
  if encircled(P, radius, [0,0]) then out_coords = (n_elements(out_coords) eq 0) ? P : [[out_coords], [P]]
  ; Determine if an intersection exists between circle and edge defined by P(i) -> P(i+1)
  dx = x[i+1] - x[i]
  dy = y[i+1] - y[i]
  dr2 = dx^2 + dy^2
  D = x[i]*y[i+1] - x[i+1]*y[i]
  delta = radius^2 * dr2 - D^2
  if (delta gt 0) then begin
    ; We have an intersection of the infinite line... find out if (and where) it is on the line segment
    xi1 = ( D * dy + sign(dy,/noz) * dx * sqrt(delta)) / dr2
    xi2 = ( D * dy - sign(dy,/noz) * dx * sqrt(delta)) / dr2
    yi1 = (-D * dx +  abs(dy) *      sqrt(delta)) / dr2
    yi2 = (-D * dx -  abs(dy) *      sqrt(delta)) / dr2
    ; Only ONE of these points should be on the line segment, if the polygon is small, as required
    ok1 = bounded(xi1, x[i], x[i+1]) and bounded(yi1, y[i], y[i+1])
    ok2 = bounded(xi2, x[i], x[i+1]) and bounded(yi2, y[i], y[i+1])
    if (ok1 or ok2) then begin
      if (ok1 and ok2) then message, "ERROR: Two intersections with a line segment... polygon is too small!"
      P = ok1 ? [xi1,yi1] : [xi2,yi2]
      out_coords = (n_elements(out_coords) eq 0) ? P : [[out_coords], [P]]
      inds = (n_elements(inds) eq 0) ? n_elements(out_coords)/2 - 1: [inds, n_elements(out_coords)/2 - 1]
    endif
  endif
endfor

i = temporary(intersect_inds)
if (n_elements(inds) ne 0) then intersect_inds = inds

if (n_elements(out_coords) eq 0) then begin
;  message, /info, "WARNING: No intersection, returning -1..."
  return, -1
endif else begin
  ; Translate back to correct coords
  out_coords += rebin(center,size(out_coords,/dim))
endelse

return, out_coords
end


function poly_circarea, coords, radius, center

; Returns area of polygon covered by circular mask, with polygon defined by coords and circle defined by radius and center
; Coords must be 2xN array (e.g. [[x],[y]]) of polygon vertices IN ORDER (clockwise or counter-clockwise)
; Polygon must be convex (concave not supported yet) and SMALLER than circle (such that there are either 0 or 2 intersections and no more)
; Center must be 2-element array (e.g. [xc,yc]), defaults to (0,0) if missing

if n_elements(radius) eq 0 then message, "Radius must be defined."
if n_elements(center) eq 0 then begin
  center = [0,0]
  message, /info, "WARNING: center not defined, defaulting to [0,0] ..."
endif

; Get coordinates of clipped polygon with circular arc segment
polycoords = poly_circclip(coords, radius, center, intersect = arccoords)

; If returns -1 (or, really, only a single element), no overlap --> zero area
if (n_elements(polycoords) eq 1) then return, 0

; If we're here, we have valid coordinates... translate to circle-centric coords for easier calculations
polycoords -= rebin(center,size(polycoords,/dim))
npts = n_elements(polycoords)/2
; Close polygon
polycoords = [[polycoords], [polycoords[*,0]]]
; Polygon area = sum of cross products around each vertex (Green's Theorem)
polyarea = total(((polycoords[0,0:npts-1] * polycoords[1,1:npts]) - (polycoords[1,0:npts-1] * polycoords[0,1:npts])))/2.

; If arc intersections don't exist (polygon wholly contained), we're done
if (n_elements(arccoords) eq 0) then return, polyarea

; If we're here, we have an arc and need to calculate its area...
; Isolate coordinates of arc endpoints (there should be only 2 for a convex polygon of sufficiently small size)
arccoords = polycoords[*,arccoords]
; Arc central angle = arccos( (A_x*B_x + A_y*B_y) / sqrt( (A_x^2 + A_y^2) * (B_x^2 + B_y^2))) = arccos( (A dot B) / radius^2)
; angle = 2*acos(sqrt(total((total(arccoords,2)/2.)^2))/radius)
angle = acos(total(product(arccoords,2)) / radius^2)  ; Equivalent to above but slightly simpler/faster for calculation
; Arc area = area of circular sector minus inscribed triangle
arcarea = (radius^2/2.) * (angle - sin(angle))

return, polyarea + arcarea
end