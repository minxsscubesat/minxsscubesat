;
;	plot_daxss_time_offset.pro
;
;	Check out time offsets for DAXSS data
;
;	T. Woods, 6/15/2022
;

yd = 2022090L
hr_range = [18,20.5]

;yd = 2022074L
;hr_range = [22.5,24]

yd = 2022081L
hr_range =  [1,2]  ; [10,12] ; [12,13.5]   ; [20,21]

;
; read Level 0C, 0D, 1 and GOES
;
file0c='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0c/daxss_l0c_all_mission_length_v1.1.0.sav'
file0d='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0d/daxss_l0d_mission_length_v1.1.0.sav'
file1='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level1/daxss_l1_mission_length_v1.1.0.sav'
fileGOES = '/Users/twoods/Dropbox/minxss_dropbox/data/ancillary/goes/goes_1mdata_widx_2022.sav'

if N_ELEMENTS(sci) lt 1 then restore, file0c
if N_ELEMENTS(daxss_level0d) lt 1 then restore, file0d
if N_ELEMENTS(daxss_level1_data) lt 1 then begin
	restore, file1
	daxss_level1_count = total(daxss_level1_data.spectrum_total_counts,1)
endif

if N_ELEMENTS(goes) lt 1 then restore, fileGOES
goes_long_model = 88328. + 1.811951E11 * GOES.long

;
;	plot DAXSS counts for YD and HR_RANGE
;
hour0c = (jd2yd(sci.time_jd) - yd)*24.D0
hour0d = (daxss_level0d.time_yd - yd)*24.D0
hour1 = (daxss_level1_data.time_yd - yd)*24.D0
goes_jd = gps2jd(goes.time)
hourGOES = (jd2yd(goes_jd) - yd)*24.D0

window,1,xsize=800,ysize=600,xpos=850,ypos=50
setplot
cc=rainbow(7)
window,0,xsize=800,ysize=600,xpos=50,ypos=50
setplot & cc=rainbow(7) & cs=2 & dots

; get MAX for the plot
wtime = where(hour1 ge hr_range[0] AND hour1 le hr_range[1], numtime)
if (numtime le 2) then stop, 'ERROR finding data for the YD-HR_RANGE !!!'
ymax = max(daxss_level1_count[wtime],wmax)
hrmax = hour1[wtime[wmax]]
ymin = min(daxss_level1_count[wtime],wmin)
hrmin = hour1[wtime[wmin]]

nudge = 0.

repeat_plot:
wset, 0

plot, hour0d + nudge/(3600.D0), daxss_level0d.x123_slow_count, psym=4, $
				xr=hr_range, xs=1, xtitle='Hour of '+strtrim(yd,2), $
				yr=[0,ymax*1.1], ys=1, ytitle='X123 Counts', title='0C=red, 0D=black, 1=gold, GOES=green'

oplot, hour0c + nudge/(3600.D0), sci.x123_slow_count, psym=8, color=cc[0]
oplot, hour1 + nudge/(3600.D0), daxss_level1_count, psym=4, color=cc[1]

wtime2 = where(hourGOES ge hr_range[0] AND hourGOES le hr_range[1], numtime2)
if (numtime2 le 2) then print, 'ERROR finding GOES data for the YD-HR_RANGE !!!' else begin
	ymax2 = max(GOES[wtime2].long,wmax2)
	ymin2 = min(GOES[wtime2].long,wmin2)
	goes_long_scaled = ymin + (GOES.long - ymin2) * (ymax-ymin) / (ymax2-ymin2)
	; oplot, hourGOES, goes_long_scaled, color=cc[3], psym=10
	oplot, hourGOES, goes_long_model, color=cc[4]

	goffset = (482.-250.)/60.  ; minutes
	; oplot, hourGOES+goffset/60., goes_long_scaled, color=cc[5], psym=10
endelse

wset,1
	daxss_level1_yd_long = long(daxss_level1_data.time_yd)
	wday = where( daxss_level1_yd_long eq yd )
	temp = LABEL_DATE( DATE_FORMAT='%H:%I' )
	plot, daxss_level1_data[wday].time_jd + nudge/(24.D0*3600.), daxss_level1_count[wday], psym=4, $
					XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time']
	oplot, goes_jd, goes_long_model, color=cc[4]

read, 'Enter time offset manually (0 to exit): ', nudge
if (nudge ne 0.0) then goto, repeat_plot

print, ' '
ans = ' '
read, 'Do time offset analysis for all days ? ', ans
if strupcase(strmid(ans,0,1)) ne 'Y' then stop, 'Done.'

;  correct Level 1 time back to original packet values
; time_offset_sec = -250.D0	; Line 74 in daxss_make_level0c.pro  Version 1.0.0
time_offset_sec = -116.D0	; Line 74 in daxss_make_level0c.pro  Version 1.1.0a
sci_time_gps = daxss_level1_data.time_gps - time_offset_sec
sci_time_jd = gps2jd(sci_time_gps)
sci_time_yd = jd2yd(sci_time_jd)

yd1 = long(min(sci_time_yd))  & jd1 = yd2jd(yd1)
yd2 = long(max(sci_time_yd))  & jd2 = yd2jd(yd2)
num_days = long(jd2-jd1+1L)
theJD = findgen(num_days) + jd1
theYD = long(jd2yd(theJD))
INVALID_OFFSET = -999999.
theTimeOffset = fltarr(num_days+1) + INVALID_OFFSET
sci_time_yd_long = long(sci_time_yd)
goes_yd_long = long(jd2yd(goes_jd))
MIN_POINTS = 25L
MIN_RATIO = 3.0
NUM_SEARCH = 1001L
search_time = findgen(NUM_SEARCH)-(NUM_SEARCH-1)*3./4.  ; +/- 500 sec
search_chisq = fltarr(NUM_SEARCH)
search_slope = fltarr(NUM_SEARCH)
ans2 = ' '
window,1,xsize=800,ysize=600,xpos=850,ypos=50
setplot
cc=rainbow(7)
window,0,xsize=800,ysize=600,xpos=50,ypos=50
setplot

for ii=0L,num_days do begin
	if (ii eq num_days) then wgd = where((daxss_level1_data.tangent_ray_height ge 450.), numgd) $
	else wgd = where((sci_time_yd_long eq theYD[ii]) and (daxss_level1_data.tangent_ray_height ge 450.), numgd)
	if (numgd ge MIN_POINTS) then begin
		cmax = max(daxss_level1_count[wgd])
		cmin = min(daxss_level1_count[wgd])
		if (cmax/cmin) ge MIN_RATIO then begin
			; there are enough points and enough change in intensity to find time shift
			; find shift by finding best relationship with GOES flare transitions
			if (ii eq num_days) then wgdgoes = where( goes_yd_long gt min(theYD) )$
			else wgdgoes = where( goes_yd_long eq theYD[ii] )
			for k=0L,NUM_SEARCH-1 do begin
				goes_long = interpol(GOES.long, goes_jd, sci_time_jd[wgd] + search_time[k]/(24.D0*3600.))
				; cctemp = poly_fit(goes_long, daxss_level1_count[wgd],1, chisq=chisq)
				cctemp = robust_linefit(goes_long, daxss_level1_count[wgd],1,yyfit,sig_chisq)
				search_chisq[k] = sig_chisq[1]
				search_slope[k] = cctemp[1]
			endfor
			chimin = min(search_chisq,wbest)
			; slopemax = max(search_slope,wbest)			; maximum slope is better indicator of best time offset
			theTimeOffset[ii] = search_time[wbest]
			wset,1
			plot, search_time, search_chisq, $
					title='YD = '+strtrim(theYD[ii < (num_days-1)],2)+', dTime='+strtrim(long(theTimeOffset[ii]),2)+'sec'
			oplot,theTimeOffset[ii]*[1,1],!y.crange,line=2
			wset,0
			temp = LABEL_DATE( DATE_FORMAT='%H:%I' )
			plot, sci_time_jd[wgd] + theTimeOffset[ii]/(24.*3600.), daxss_level1_count[wgd], psym=4, $
					XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time'], $
					title='With offset=Black, Without=Red, GOES=Green'
			if (ii lt num_days) then oplot, sci_time_jd[wgd], daxss_level1_count[wgd], psym=4, color=cc[0]
			factor = cmax / max(goes_long)
			oplot, goes_jd, goes.long * factor, psym=10, color=cc[3]
			oplot, goes_jd, goes_long_model, psym=10, color=cc[4]
			read, 'Next day ? ', ans2
		endif
	endif
endfor

;
;	fit trend for time offsets ???
;
; +++++



end
