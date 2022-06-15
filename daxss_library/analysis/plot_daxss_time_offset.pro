;
;	plot_daxss_time_offset.pro
;
;	Check out time offsets for DAXSS data
;
;	T. Woods, 6/15/2022
;

yd = 2022090L
hr_range = [18,19.5]

;
; read Level 0C, 0D, 1 and GOES
;
file0c='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0c/daxss_l0c_all_mission_length_v1.0.0.sav'
file0d='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0d/daxss_l0d_mission_length_v1.0.0.sav'
file1='/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level1/daxss_l1_mission_length_v1.0.0.sav'
fileGOES = '/Users/twoods/Dropbox/minxss_dropbox/data/ancillary/goes/goes_1mdata_widx_2022.sav'

if N_ELEMENTS(sci) lt 1 then restore, file0c
if N_ELEMENTS(daxss_level0d) lt 1 then restore, file0d
if N_ELEMENTS(daxss_level1_data) lt 1 then begin
	restore, file1
	daxss_level1_count = total(daxss_level1_data.spectrum_total_counts,1)
endif
if N_ELEMENTS(goes) lt 1 then restore, fileGOES

;
;	plot DAXSS counts for YD and HR_RANGE
;
hour0c = (jd2yd(sci.time_jd) - yd)*24.D0
hour0d = (daxss_level0d.time_yd - yd)*24.D0
hour1 = (daxss_level1_data.time_yd - yd)*24.D0
hourGOES = (jd2yd(gps2jd(goes.time)) - yd)*24.D0

setplot & cc=rainbow(7) & cs=2 & dots

; get MAX for the plot
wtime = where(hour1 ge hr_range[0] AND hour1 le hr_range[1], numtime)
if (numtime le 2) then stop, 'ERROR finding data for the YD-HR_RANGE !!!'
ymax = max(daxss_level1_count[wtime],wmax)
hrmax = hour1[wtime[wmax]]
ymin = min(daxss_level1_count[wtime],wmin)
hrmin = hour1[wtime[wmin]]

plot, hour0d, daxss_level0d.x123_slow_count, psym=4, $
				xr=hr_range, xs=1, xtitle='Hour of '+strtrim(yd,2), $
				yr=[0,ymax], ys=1, ytitle='X123 Counts', title='0C=red, 0D=black, 1=gold, GOES=green'

oplot, hour0c, sci.x123_slow_count, psym=8, color=cc[0]
oplot, hour1, daxss_level1_count, psym=4, color=cc[1]

wtime2 = where(hourGOES ge hr_range[0] AND hourGOES le hr_range[1], numtime2)
if (numtime2 le 2) then print, 'ERROR finding GOES data for the YD-HR_RANGE !!!' else begin
	ymax2 = max(GOES[wtime2].long,wmax2)
	ymin2 = min(GOES[wtime2].long,wmin2)
	goes_long_scaled = ymin + (GOES.long - ymin2) * (ymax-ymin) / (ymax2-ymin2)
	oplot, hourGOES, goes_long_scaled, color=cc[3], psym=10

	goffset = -3.0  ; seconds
	; oplot, hourGOES+goffset/60., goes_long_scaled, color=cc[5], psym=10
endelse

end
