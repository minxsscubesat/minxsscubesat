;
;	daxss_live_time_fix.pro
;
;	Study and fix the DAXSS integration time involving ACCUM_TIME and LIVE_TIME
;	Day 2022/074 is used during flare - it shows spikes up every 10 spectra for LIVE_TIME and SLOW_COUNT
;
;	Tom Woods,  6/25/2022
;
;	CONCLUSION:    signal = counts / ((accum_time + live_time)/2.)
;			instead of using signal = counts / accum_time
;	CONSEQUENCE:  this is increase irradiance by about 10%
;

;
;	read L0C file
;
if n_elements(sci74) lt 1 then begin
	dpath = getenv('minxss_data')
	restore, dpath + '/fm3/level0c/daxss_l0c_all_mission_length_v1.1.0.sav'
	sci_yd = jd2yd(gps2jd(sci.time))
	wgd = where( sci_yd ge 2022074.9708D0 AND sci_yd lt 2022075.D0 )
	sci74 = sci[wgd]
	sci74_hr = (sci_yd[wgd]-2022074.D0)*24.
endif

;  make variables used for plots / analysis
accum_time = sci74.x123_accum_time/1000.
live_time = sci74.x123_live_time/1000.
real_time = sci74.x123_real_time/1000.
avg_time = (accum_time + live_time)/2.

; dead time calculated per Amptek Application-Note about Acquistion-Time
dead_time = (sci74.x123_fast_count - sci74.x123_slow_count) / sci74.x123_fast_count
accum_dead_time = accum_time * (1. - dead_time)

slow_count_cps = sci74.x123_slow_count / accum_time
slow_count_cps_alt = sci74.x123_slow_count / ((live_time + accum_time)/2.)
slow_count4 = slow_count_cps/2E4
slow_count4_alt = slow_count_cps_alt/2E4

fast_count_cps = sci74.x123_fast_count / accum_time
fast_count_cps_alt = sci74.x123_fast_count / ((live_time + accum_time)/2.)
fast_count4 = fast_count_cps/2E4
fast_count4_alt = fast_count_cps_alt/2E4

total_cps = fast_count_cps / (1. - fast_count_cps * 0.1E-6)

;
;	make plot
;
setplot & cc=rainbow(7) & ans=' '

plot, sci74_hr, accum_time, psym=-4, xtitle='Hour of 2022/074', ytitle='Time (sec)', $
		title='Black=Accum, Red=Live, Green=Real, Gold=Slow/2E4, Purple=Fast'
oplot, sci74_hr, live_time, psym=-4, color=cc[0]
oplot, sci74_hr, real_time, psym=-4, color=cc[3]
oplot, sci74_hr, slow_count4, psym=-5, color=cc[1]
oplot, sci74_hr, slow_count4_alt, psym=-5, color=cc[4]
oplot, sci74_hr, fast_count4, psym=-6, color=cc[6]
; oplot, sci74_hr, accum_dead_time, psym=-4, color=cc[5]
; oplot, sci74_hr, avg_time, psym=-4, color=cc[6]

read, 'Next plot ? ', ans

;
;	compare adjacent spectra to verify they look the same
;
wbad = [4,14,24,34,44,54]
num_bad = n_elements(wbad)
energy = findgen(1024)*0.0199706  + (-0.00939901)
for ii=0,num_bad-1 do begin
	k=wbad[ii] & k1=wbad[ii]-1 & k2=wbad[ii]+1
	sp_adjacent = (sci74[k1].x123_spectrum/accum_time[k1] + sci74[k2].x123_spectrum/accum_time[k2])/2.
	sp_bad = sci74[k].x123_spectrum/accum_time[k]
	sp_bad_total = total(sp_bad) & sp_adjacent_total = total(sp_adjacent)
	factor = sp_bad_total / sp_adjacent_total
	print, ' '
	print, 'Index = ', strtrim(k,2), ': Total Bad = ', strtrim(sp_bad_total,2), $
				', Total Adjacent = ', strtrim(sp_adjacent_total,2), ', Ratio = ', strtrim(factor,2)
	live_time_factor = (accum_time[k]*factor - accum_time[k])/live_time[k]
	avg_time_factor = (accum_time[k] / ((accum_time[k]+live_time[k])/2.))
	print, '          Accum_Time = ', strtrim(accum_time[k],2), $
				', Live_Time = ', strtrim(live_time[k],2), ', LT_Factor = ', strtrim(live_time_factor,2)
	bad_time_avg = (accum_time[k] + live_time[k])/2.
	adjacent_time_avg = ((accum_time[k1] + live_time[k1])/2. + (accum_time[k2] + live_time[k2])/2.)/2.
	print, '          Bad_Time_Avg = ', strtrim(bad_time_avg,2), $
				', Adjacent_Time_Avg = ', strtrim(bad_time_adjacent,2), $
				', Ratio_Avg_Bad-2-Adjacent = ', strtrim( bad_time_avg / adjacent_time_avg, 2 )
	count_difference_str = strtrim(((1. - (bad_time_avg / accum_time[k]))*100.),2) + '%'
	print, '          **** Intensity Difference for using Average Time = ', count_difference_str
	; plot spectra
	plot, energy, sp_bad, psym=10, xr=[0.6,2.6], xs=1, xtitle='Energy (keV)', $
				yr=[0,max(sp_bad)*1.1], ys=1, ytitle='Signal (cps)', $
				title='Index='+strtrim(k,2)+': Black=Bad, Green=Adjacent, Red=Bad/Factor'
	oplot, energy, sp_adjacent, psym=10, color=cc[3]
	oplot, energy, sp_bad / factor, psym=10, color=cc[0]
	read, 'Next plot ? ', ans
endfor

end
