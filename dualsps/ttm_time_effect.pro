;
;	ttm_time_effect.pro
;
;	Characterize SPS data effects over time and calculate impact of sequential reading of quad elements
;
;	INPUT:
;		data	TLM data read from file by dualsps_read_file_ccsds(filename )
;		index1	Index start
;		index2 	Index end
;		/darks	Dark Signal for each quad element (default is V3.08 SPS#2 darks)
;
;	If index1 or index2 are not provided then User interactively selects those times.
;	Exact value for these start times are not important
;
pro ttm_time_effect, data, index1, index2, darks=darks, adc_packets=adc_packets, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE: ttm_time_effect, tlm_data, index1, index2'
	return
endif

setplot & cc=rainbow(7) & ans=' '
angle_factor = 0.25 * 3600.

if n_params() lt 3 then BEGIN
	; If index1 or index2 are not provided then User interactively selects those times.

	plot, data.sps_quad_y, yr=[-0.005,0.005],ys=1
	oplot, data.sps_quad_x, color=cc[3]
	oplot, data.ttm_state * 0.004, color=cc[0]
	print, ' '
	read, 'Place cursor over start time for Jitter With Tracking, then hit ENTER ', ans
	cursor,x1,y1,/nowait
	read, 'Place cursor over start time for Jitter withOUT Tracking, then hit ENTER ', ans
	cursor,x2,y2,/nowait
	index1 = x1 & index2 = x2
	if (x1 gt x2) then begin & index1 = x2 & index2 = x1 & endif else $
		begin & index1 = x1 & index2 = x2 & endelse
	print, 'Index1 = ', strtrim(index1,2), '  and Index2 = ', strtrim(index2,2)
endif

; setup darks[]
darks_default = [ 16416, 16416, 16416, 16416 ]
if not keyword_set(darks) then darks = darks_default
if n_elements(darks) lt 4 then begin
	print, 'ERROR for "darks", so assuming Default V3.08 values.'
	darks = darks_default
endif

; calculate Seconds Of Day (SOD)
jd_zero = long(median(data.jd))
sod = (data.jd - jd_zero) *24.*3600.
sod_zero = sod[index1]
sod -= sod_zero

if keyword_set(adc_packets) then begin
	asod = (adc_packets.jd - jd_zero) *24.*3600.
	asod -= sod_zero
endif

;
;	plot the SPS Quad diodes individual signals and Quad Sum
;
diode_min = fltarr(4) & diode_max = fltarr(4)
for ii=0,3 do begin
	diode_min[ii] = min(data[index1:index2].sps_diode_data[ii]) - darks[ii]
	diode_max[ii] = max(data[index1:index2].sps_diode_data[ii]) - darks[ii]
endfor
yrange = [ min(diode_min), max(diode_max) ]
setplot & cc = rainbow(7)
ccol = [ cc[0], cc[1], cc[3], cc[4] ]

plot, sod, data.sps_quad_sum/4., /nodata, xr=[0,sod[index2]], yr=yrange,ys=1, $
	xtitle='Time (sec)',ytitle='SPS Signal (DN)'
for ii=0,3 do begin
	oplot,sod, data.sps_diode_data[ii] - darks[ii], color=ccol[ii]
endfor
oplot, sod, data.sps_quad_sum/4.

;if keyword_set(adc_packets) then begin
	; over plot X error
;	oplot, asod, adc_packets.ttm_sps_x_error, psym=10, color=cc[5]
;endif

read, 'Next Plot ? ',ans

; examine noise over time - it appears SPS#2 diode[3] has different variation from intensity
;		double_DIFF = (diode - median_diode) - (sum - median_sum)/4
;
sum_stddev = stddev( data[index1:index2].sps_quad_sum ) / 4.
print, ' '
print, 'Std-Dev SUM/4 = ', sum_stddev
plot, sod, data.sps_quad_sum, /nodata, xr=[0,sod[index2]], yr=[-3.*sum_stddev,3.*sum_stddev],ys=1, $
	xtitle='Time (sec)',ytitle='(Diode-Median) - (Sum-Median_Sum)/4'
sum_diff_4 = (data.sps_quad_sum - median(data[index1:index2].sps_quad_sum)) / 4.
for ii=0,3 do begin
	diff = (data.sps_diode_data[ii] - median(data[index1:index2].sps_diode_data[ii]))
	double_diff = diff - sum_diff_4
	oplot,sod, double_diff, color=ccol[ii]
	print, 'Std-Dev Diode ',strtrim(ii,2), ' = ', stddev(data[index1:index2].sps_diode_data[ii]), $
		', Double_Diff Std-Dev = ', stddev(double_diff[index1:index2])
endfor
oplot, !x.crange, sum_stddev*[1,1], line=2
oplot, !x.crange, sum_stddev*[-1,-1], line=2
print, ' '

read, 'Next Plot ? ',ans

;
;	calculate error for X and Y calculation based on variation of Light Intensity
;	Sum4_rate = (sum[i] - sum[i-1])/4.  /  (sod[i] - sod[i-1])  ; DN / sec
;	Read_Time = 0.002 sec ; 2 msec read between ADC channels
;	X = (D0+D3-D1-D2) / SUM
;	X_adj = (D0+Sum4_rate*Read_Time*3 - D2+Sum4_rate*Read_Time - D1+Sum4_rate*Read_Time + D3)/SUM
;	X_err = (X_adj - X) ; * angle_factor to get arc-sec
;   Y = (D0+D1-D2-D3) / SUM
;	Y_adj = (D0+Sum4_rate*Read_Time*3 + D1+Sum4_rate*Read_Time*2 - D2+Sum4_rate*Read_Time - D3)/SUM
;	Y_err = (Y_adj - Y) ; * angle_factor to get arc-sec
;
num = index2 - index1
sum4_rate  = fltarr(num)
read_time = 0.002
for ii=0L,num-1 do BEGIN
	sum4_rate[ii] = (data[index1+1+ii].sps_quad_sum - data[index1+ii].sps_quad_sum) / $
			(sod[index1+1+ii] - sod[index1+ii])
endfor
temp = data[index1+1:index2].sps_diode_data
sum = data[index1+1:index2].sps_quad_sum
the_sod = sod[index1+1:index2]
for ii=0,3 do temp[*,ii] -= darks[ii]

x = reform(temp[0,*] + temp[3,*] - temp[1,*] - temp[2,*]) / sum
x_adj = ( (reform(temp[0,*])+Sum4_rate*Read_Time*3) - (reform(temp[2,*])+Sum4_rate*Read_Time) $
		- (reform(temp[1,*])+Sum4_rate*Read_Time*2) + reform(temp[3,*]) ) / sum
x_err_asec = (x_adj - x) * angle_factor

y = reform(temp[0,*] + temp[1,*] - temp[2,*] - temp[3,*]) / sum
y_adj = ( (reform(temp[0,*])+Sum4_rate*Read_Time*3) + (reform(temp[1,*])+Sum4_rate*Read_Time*2) $
		- (reform(temp[2,*])+Sum4_rate*Read_Time) - reform(temp[3,*]) ) / sum
y_err_asec = (Y_adj - Y) * angle_factor

print, ' '
print, 'X time shift error = ', mean(x_err_asec), ' +/- ', stddev(x_err_asec), ' arc-sec'
print, 'Y time shift error = ', mean(y_err_asec), ' +/- ', stddev(y_err_asec), ' arc-sec'
print, ' '

;  Intensity variation also causes error
;	X_mag = X * sum / (sum + sum_err)
;	Y_mag = Y * sum / (sum + sum_err)
sum_err = stddev(sum)
x_mag = X * sum / (sum + sum_err)
x_err_mag_asec = (x_mag - x) * angle_factor
y_mag = y * sum / (sum + sum_err)
y_err_mag_asec = (y_mag - y) * angle_factor
print, 'Intensity variation X error ', mean(x_err_mag_asec), ' +/- ', stddev(x_err_mag_asec), ' arc-sec'
print, 'Intensity variation Y error ', mean(y_err_mag_asec), ' +/- ', stddev(y_err_mag_asec), ' arc-sec'
print, ' '

yrange2 = [ min(y_err_asec) - 0.5, max(y_err_asec) + 0.5]
plot, the_sod, y_err_asec, /nodata, xr=[0,sod[index2]], yr=yrange2,ys=1, $
	xtitle='Time (sec)',ytitle='SPS Time Shift Error (arc-sec)'
oplot, the_sod, y_err_asec, color=cc[0]
oplot, the_sod, x_err_asec
xx = 5.
dy = (!y.crange[1] - !y.crange[0])/10.
yy = !y.crange[1] - dy
xyouts, xx, yy, 'Y', color=cc[0]
xyouts, xx, yy-dy, 'X'

read, 'Next Plot ? ',ans

if keyword_set(debug) then stop, 'DEBUG at end of ttm_time_effect...'
RETURN
end
