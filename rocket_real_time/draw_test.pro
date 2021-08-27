pro draw_test

p = plot(/test)
p.title = 'bla' 
p.xtitle='bla'




x=systime(1)
for i = 0, 500 do begin
  p.title = strtrim(i, 2)
  ;p.xtitle = strtrim(i, 2) + 'abdoifajeoija'
endfor
print, systime(1) - x 
print, float(i)/(systime(1)-x)

;print, 'new graphics'
;p = plot(findgen(10))
;x=systime(1)
;for i = 0, 500 do begin
;  p.setData, findgen(10)
;endfor
;print, systime(1) - x
;print, float(i)/(systime(1)-x)
;
;
;plot, findgen(10)
;print, 'old graphics'
;plot, findgen(10)
;x=systime(1)
;for i = 0, 500 do begin
;  plot, findgen(10)
;endfor
;print, systime(1) - x
;print, float(i)/(systime(1)-x)

end