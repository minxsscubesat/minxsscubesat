;
;	make temperature range for plot
;
function temperature_range, array
	if (n_params() lt 1) then begin
		yrange = [-30,50]
	endif else begin
	    ; remove spikes
	    sig3 = stddev(array) * 3
	    med = median(array)
	    wgood = where( (array gt (med-sig3)) and (array lt (med+sig3)), numgood )
	    if (numgood gt 1) then garray = array[wgood] else garray=array
		ymin = long(min(garray)/10.)*10.
		if (ymin le 0) then ymin -= 10.
		ymax = long(max(garray)/10.)*10. + 20.
		yrange = [ymin, ymax]
	endelse
	return, yrange
end
