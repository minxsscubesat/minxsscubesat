;
;	ttm_tune_test.pro
;
;	compare TTM jitter test with and without tracking
;
;	INPUT:
;		data	TLM data read from file by dualsps_read_file_ccsds(filename )
;		index1	Index where Jitter and Tracking have started
;		index2 	Index into data where Jitter Without Tracking has started
;		/period Period of Jitter (e.g. 1 sec for sine and 5 sec for Square; default=5 sec)
;
;	If index1 or index2 are not provided then User interactively selects those times.
;	Exact value for these start times are not important
;
pro ttm_tune_test, data, index1, index2, period=period, adc_packets=adc_packets, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE: ttm_tune_test, tlm_data, index1, index2'
	return
endif

setplot & cc=rainbow(7) & ans=' '
angle_factor = 0.25 * 3600.

if not keyword_set(period) then period = 5.0

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
;	get integer number of jitter cycles between Index1 and Index2
;
tshift = (long( (sod[index2]-sod[index1])/period + 0.5 ) + 1.0) * period

;
;	plot the Jitter With Tracking and over-plot Jitter Without Tracking with a time shift
;
plot, sod, data.sps_quad_x*angle_factor, /nodata, xr=[0,sod[index2]], yr=[-5,5],ys=1, $
	xtitle='Time (sec)',ytitle='SPS Quad X (arc-sec)'
oplot, sod, data.ttm_x_control_asec, psym=10, color=cc[3]  ; CONTROL Value with running mean
oplot, sod-tshift, data.sps_quad_x*angle_factor, psym=10, color=cc[0]
oplot, sod, data.sps_quad_x*angle_factor, psym=10

if keyword_set(adc_packets) then begin
	; over plot X error
	oplot, asod, adc_packets.ttm_sps_x_error, psym=10, color=cc[5]
endif

read, 'Next Plot ? ',ans

plot, sod, data.sps_quad_y*angle_factor, /nodata, xr=[0,sod[index2]], yr=[-5,5],ys=1, $
	xtitle='Time (sec)',ytitle='SPS Quad Y (arc-sec)'
oplot, sod, data.ttm_y_control_asec, psym=10, color=cc[3]  ; CONTROL Value with running mean
oplot, sod-tshift, data.sps_quad_y*angle_factor, psym=10, color=cc[0]
oplot, sod, data.sps_quad_y*angle_factor, psym=10

if keyword_set(adc_packets) then begin
	; over plot Y error
	oplot, asod, adc_packets.ttm_sps_y_error, psym=10, color=cc[5]
endif

read, 'Next Plot ? ',ans

if keyword_set(debug) then stop, 'DEBUG at end of ttm_tune_test...'
RETURN
end
