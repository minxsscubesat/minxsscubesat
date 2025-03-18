;
;	xyouts_optimize
;
;	Optimize xyouts string print to fit a specific width
;
;	string_width should be  (string_width_pixels / !D.X_VSIZE)
;
;	10/1/2022  T. Woods
;
pro xyouts_optimize, x, y, string, string_width, limit=limit, color=color, align=align, debug=debug

;  first get width of xyouts string in pixels (this does not print it)
xyouts, x, y, string, width=str_out_width, charsize=-1

charsize_optimal = string_width / str_out_width
if keyword_set(limit) then begin
	if (charsize_optimal gt limit) then charsize_optimal = limit
endif

; now print the string with optimal width
xyouts, x, y, string, charsize=charsize_optimal, color=color, align=align

if keyword_set(debug) then stop, 'STOP: debug at end of xyouts_optimize ...'
return
end
