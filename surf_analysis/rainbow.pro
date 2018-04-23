;
;	rainbow.pro
;
;	Load color values based on rainbow color table
;
;	Tom Woods
;	7/11/02
;
;	Updated to support image colors on a X-window device (with tv, tvscl )
;	Tom Woods    1/7/03
;
;	Updated to make colors darker (better screen visibility)
;	Tom Woods    11/07/03
;
function rainbow, num_colors, image=image, debug=debug

if n_params() lt 1 then begin
  print, 'USAGE:  colors = rainbow( num_colors, [/image] )'
  print, '   sets rainbow color table to display'
  print, '   if num_colors eq 7 then colors = ROY G BIV'
  print, '   otherwise, colors go from Red to Blue'
  print, '   The /image option is needed for displaying images using tv, tvscl'
  num_colors=7 
endif

if (strupcase(!d.name) eq 'X') or (strupcase(!d.name) eq 'Z') then begin
  if keyword_set(image) then device, decomposed=0 $
  else device, decomposed=1
endif

if (num_colors lt 7) then num_colors = 7
if (num_colors ge !d.table_size) then num_colors = !d.table_size - 1

colors = ulonarr(num_colors)

;
;	define rainbow (like IDL rainbow but with white at end)
;
ntable = !d.table_size
b0 = 0L
b1 = ntable/5L - 1L
b01 = b1 / 2L
b2 = b1 * 2L
b3 = b1 * 3L
b4 = b1 * 4L
b5 = b1 * 5L
b6 = ntable-1L
r = intarr(ntable)
g = r
b = r
factor = long(long(ntable*0.98) / b1 + 0.5)
factor = factor * 0.6  ; make darker colors: TNW 11/03
maxcolor = b1 * factor
; print, maxcolor, !d.table_size
oldway = 0
if (oldway ne 0) then begin
  r[b0:b01] = indgen(b01+1)*factor
  r[b01:b1] = reverse(indgen(b1-b01+1)*factor)
  r[b3:b4]= indgen(b1+1)*factor
  r[b4:b6] = maxcolor
  g[b1:b2] = indgen(b1+1)*factor
  g[b4:b5] = reverse(g[b1:b2])
  g[b2:b4] = maxcolor
  g[b5+1:b6] = maxcolor
  b[b0:b1] = indgen(b1+1)*factor
  b[b2:b3] = reverse(b[b0:b1])
  b[b1:b2] = maxcolor
  b[b5+1:b6] = maxcolor
endif else begin
  r[b0:b01] = indgen(b01+1)*factor
  r[b01:b1] = reverse(indgen(b1-b01+1)*factor)
  r[b3:b4]= indgen(b1+1)*factor
  r[b4:b6] = maxcolor
  g[b1:b2] = indgen(b1+1)*factor
  g[b3:b4] = reverse(g[b1:b2])
  g[b4:b5] = reverse(g[b1:b2])
  g[b3+b01:b4] = reverse(g[b3:b3+b01])
  g[b2:b3] = maxcolor
  g[b5+1:b6] = maxcolor
  b[b0:b1] = indgen(b1+1)*factor
  b[b2:b3] = reverse(b[b0:b1])
  b[b1:b2] = maxcolor
  b[b5+1:b6] = maxcolor
endelse

;
;	load the color table now
;
tvlct, r, g, b

;
;	index for ROY G BIV 
;
index = reverse(long(indgen(num_colors) * (b5-b01) / (num_colors-1.) + b01 ))

;
;	24-bit display is special case
;
if (!d.n_colors gt 256) then begin
  colors = r[index] + 256UL * (g[index] + 256UL * b[index])
endif else begin
  colors = index
endelse

if keyword_set(debug) then stop, 'Check out  R, G, B and colors ...'

return, colors
end
