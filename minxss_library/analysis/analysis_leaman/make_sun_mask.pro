;;; Used in make_sun_picture to mask to solar disk
;; CL-Summer 2016

function make_sun_mask, xc,yc,r
mask=fltarr(4096, 4096)
r2=float(r)^2
for x=0.0, 4095 do begin
for y=0.0, 4095 do begin
if (((x-xc)^2) + ((y-yc)^2)) lt r2 then mask[x, y] =1
endfor
endfor
return, mask
end
