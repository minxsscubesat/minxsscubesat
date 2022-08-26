;
;	daxss_test_dead_time.pro
;
;	Test new DAXSS dead time correction with in-flight data
;
;	T. Woods, 6/28/22
;
if n_elements(sci) lt 1 then begin
	; Read DAXSS Level 0C data
	restore, '/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0c/daxss_l0c_all_mission_length_v1.1.0.sav'
	fast = sci.x123_fast_count / (sci.x123_accum_time/1000. > 0.001)
	slow = sci.x123_slow_count / (sci.x123_accum_time/1000. > 0.001)
	sci_jd = gps2jd(sci.time)
	sci_yd = jd2yd(sci_jd)
endif

; day 1 data
wgd = where( sci_yd ge 2022059.0D0 AND sci_yd lt 2022060.D0 )
sci1 = sci[wgd]
sci1_hr = (sci_yd[wgd]-2022059.D0)*24.

; largest flare
wgd = where( sci_yd ge 2022110.0D0 AND sci_yd lt 2022111.D0 )
sci1 = sci[wgd]
sci1_hr = (sci_yd[wgd]-2022110.D0)*24.

; second largest flare
wgd = where( sci_yd ge 2022107.0D0 AND sci_yd lt 2022108.D0 )
sci1 = sci[wgd]
sci1_hr = (sci_yd[wgd]-2022107.D0)*24.

; a later day
wgd = where( sci_yd ge 2022125.0D0 AND sci_yd lt 2022126.D0 )
sci1 = sci[wgd]
sci1_hr = (sci_yd[wgd]-2022125.D0)*24.

; get 2022/074 flare data for checking that spikes are fixed
wgd = where( sci_yd ge 2022074.9708D0 AND sci_yd lt 2022075.D0 )
sci1 = sci[wgd]
sci1_hr = (sci_yd[wgd]-2022074.D0)*24.

dead_times = 1.95E-6 * [ 0.8, 0.9, 1.0, 1.1, 1.2 ]
num = n_elements(dead_times)

for ii=0,num-1 do begin
	dt = daxss_dead_time( fast, slow, SLOW_DEAD_TIME=dead_times[ii], /verbose )
	if (ii eq 0) then begin
		setplot & cc=rainbow(7)
		plot, sci1_hr, slow[wgd]*dt[wgd]*1.2, /nodata, xtitle='Hour', ytitle='Signal (cps)'
		oplot, sci1_hr, slow[wgd], psym=-4
	endif
	oplot, sci1_hr, slow[wgd]*dt[wgd], color=cc[ii+1]
endfor

end
