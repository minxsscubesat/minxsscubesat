;
;	dualsps_calc_noise.pro
;
pro dualsps_calc_noise, data, index1, index2

if n_params() lt 2 then begin
	print, 'USAGE: dualsps_calc_noise, tlm_data, index_array'
	print, ' or  : dualsps_calc_noise, tlm_data, index1, index2'
	return
endif

if n_params() lt 3 then index = index1 else index = indgen(index2-index1+1L) + index1

angle_factor = 0.25 * 3600.

print, ' '
print, 'Quad SUM = ', median(data[index].sps_quad_sum), ' +/- ', stddev(data[index].sps_quad_sum)
print, 'Quad  X  = ', median(data[index].sps_quad_x), ' +/- ', stddev(data[index].sps_quad_x)
print, 'Quad  Y  = ', median(data[index].sps_quad_y), ' +/- ', stddev(data[index].sps_quad_y)
print, ' '
print, 'Quad  X Std-Dev Arc-sec = ', stddev(data[index].sps_quad_x) * angle_factor
print, 'Quad  Y Std-Dev Arc-sec = ', stddev(data[index].sps_quad_y) * angle_factor
print, ' '
print, 'Quad  X  Peak-to-Peak Arc-sec = ', $
		(max(data[index].sps_quad_x) - min(data[index].sps_quad_x)) * angle_factor
print, 'Quad  X  Peak-to-Peak Arc-sec = ', $
		(max(data[index].sps_quad_y) - min(data[index].sps_quad_y)) * angle_factor
print, ' '
return
end
