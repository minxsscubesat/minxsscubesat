;
;	minxss_make_report_plots.pro
;
;	Plot trends for MinXSS-1 weekly report
;		1)  Battery Voltage, 5V, 3.3V
;		2)  SA Power, System Power
;		3)  CDH Temp, EPS Temp, COMM Temp
;		4)  Battery Temp, Battery Heater
;		5)  SPS Temp, X123 Electronics Temp
;		6)  X123 Detector Temp
;		7)  SPS-XP Counts
;		8)  X123 Slow & Fast Counts
;		9)  CDH Mode, ADCS Mode
;		10) Solar Pointing Angle
;		11) Radio Rx & Tx bytes
;		12) Solar Spectra
;
;	5/29/16  Tom Woods
;	12/14/18 Tom Woods, Update for MinXSS-2
;

;
;	set Y range Max with filter
;
function max_filter, array
  the_max = max(array)
  wg = where( (array gt (mean(array)-2*stddev(array))) $
  			and (array lt (mean(array)+2*stddev(array))) )
  limit_stddev = stddev(array[wg])
  limit_max = mean(array)+3*limit_stddev
  if (the_max gt limit_max) then the_max = limit_max
return, the_max
end

;
;	oplot vertical dotted lines
;
pro oplot_vertical_lines, vertical_times, vertical_names, line_type=line_type
	if (n_elements(vertical_times) ge 1) and (vertical_times[0] ne 0) then begin
		if not keyword_set(line_type) then line_type = 1
		doTitle = 0
		if (n_params() ge 2) and (n_elements(vertical_times) eq n_elements(vertical_names)) then begin
			doTitle=1
			dx = (!x.crange[1]-!x.crange[0])*0.025
			if (!y.type eq 1) then begin
				; YLOG plot case
				my = 10.^((!y.crange[1]-!y.crange[0])*0.05)
				yy = (10.^!y.crange[1]) / my
				pyrange = 10.^!y.crange
			endif else begin
				dy = (!y.crange[1]-!y.crange[0])*0.05
				yy = !y.crange[1]-dy
				pyrange = !y.crange
			endelse
		endif
		; print, 'Do vertical lines...'
		csize=1.5
		for ii=0L,n_elements(vertical_times)-1 do begin
		  if (vertical_times[ii] ge !x.crange[0]) and (vertical_times[ii] le !x.crange[1]) then begin
			oplot, vertical_times[ii]*[1,1],pyrange, line=line_type
			if (doTitle ne 0) then $
				xyouts, vertical_times[ii]+dx, yy, vertical_names[ii],$
						charsize=csize, align=1.0,orient=90.
		  endif
		endfor
	endif
return
end

doEPS = 0
doTest = 0
loopCnt = 0L
;  OPTION TO JUMP TO SINGLE PLOT AFTER PROCEDURE HAS ALREADY RUN
; goto, PLOT_12

;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
endif else begin
    slash = '/'
endelse

fm = 2
; read, 'Enter FM number (1 or 2) ? ', fm
if (fm lt 1) then fm = 1
if (fm gt 2) then fm = 2
fmstr = strtrim(fm,2)
minxssfm = 'minxss'+fmstr
if (size(lastfm,/type) eq 0) then lastfm=0

;  what year do you want DOY values for ?
baseyear = 2018L
read, 'Enter date (YYYYDOY or YYYYMMDD) for display: ', date_in
if date_in gt 20180000L then begin
  date_str=strtrim(string(long(date_in)),2)
  date_yd = jd2yd(ymd2jd(long(strmid(date_str,0,4)),long(strmid(date_str,4,2)),long(strmid(date_str,6,2))))
endif else date_yd = date_in
baseyear = long(date_yd / 1000.)
year_str = strtrim(baseyear,2)
date_doy = long(date_yd) mod 1000L
if (size(last_baseyear,/type) eq 0) then last_baseyear=0

;
;	read the L0C merged file
;
if (n_elements(hk) lt 2) or (lastfm ne fm) or (baseyear ne last_baseyear) then begin
  ; file0c = 'minxss1_l0c_hk_mission_length.sav'
  ;  "all" file has all packet types for the MinXSS-1 mission (as of 6/10/2016)
  file0c = minxssfm+'_l0c_all_mission_length.sav'
  ; if (fm eq 2) then file0c = 'minxss2_l0c_all_tvac.sav'  ; special for TVAC
  dir0c = getenv('minxss_data')+slash+ 'fm'+fmstr +slash+ 'level0c' +slash
  print, 'READING L0C: ', dir0c+file0c
  restore, dir0c + file0c		; hk
  lastfm = fm
  last_baseyear = baseyear
endif

;if n_elements(sci) lt 2 then begin
;  file0c_sci = minxssfm + '_l0c_sci_mission_length.sav'
;  dir0c = getenv('minxss_data')+'/merged/'
;  restore, dir0c + file0c_sci		; sci
;endif

;
;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
;
doGOES = 1		; set to non-zero to overplot GOES XRS-B with XP or X123 counts

if n_elements(goes_doy) lt 2 then begin
	xrs_year = baseyear
	xrs_file = 'goes_1mdata_widx_'+strtrim(xrs_year,2)+'.sav'
	xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
	restore, xrs_dir + xrs_file   ; goes data structure
	goes_jd = gps2jd(goes.time)
	goes_doy = jd2yd(goes_jd) - xrs_year*1000.D0  ; convert GPS to DOY fraction
	goes_xrsb = goes.long
	goes_xrsa = goes.short
	goes=0L
endif

;
;	make hkdoy, datestr, and find indices for wel, wsun, wx123
;	also make scidoy
;
hkjd = gps2jd(hk.time)
hkdoy = jd2yd(hkjd) - baseyear*1000.D0
max_doy = long(max(hkdoy))
datestr = year_str + '_' + string(max_doy,format='(I03)')
wel = where( hk.eclipse_state ne 0 )
wsun = where( hk.eclipse_state eq 0 )
;  BUG in L0B processing for enable flags !!!
; wx123 = where( hk.enable_x123 ne 0, num_x123 )
wx123 = where( hk.x123_det_temp gt 0, num_x123 )
;  ECLIPSE flag can get stuck with I2C bus error; use instead SPS_SUM > 1.5E6
; wx123_el = where( hk.x123_det_temp gt 0 and hk.eclipse_state ne 0, num_x123_el )
; wx123_sun = where( hk.x123_det_temp gt 0 and hk.eclipse_state eq 0, num_x123_sun )
sps_sum_limit = 1.5E6
fast_count_limit = 10000.
slow_count_limit = 8000.
wx123_el = where( hk.x123_det_temp gt 0 and hk.sps_sum lt sps_sum_limit, num_x123_el )
wx123_el_best = where( hk.x123_det_temp gt 0 and hk.sps_sum lt sps_sum_limit $
					and hk.x123_slow_count lt slow_count_limit $
					and hk.x123_fast_count lt fast_count_limit, num_x123_el_best )
wx123_sun = where( hk.x123_det_temp gt 0 and hk.sps_sum ge sps_sum_limit, num_x123_sun )
wx123_sun_best = where( hk.x123_det_temp gt 0 and hk.sps_sum ge sps_sum_limit $
					and hk.x123_slow_count lt slow_count_limit $
					and hk.x123_fast_count lt fast_count_limit, num_x123_sun_best )

scijd = gps2jd(sci.time)
scidoy = jd2yd(scijd) - baseyear*1000.D0
adcs1jd = gps2jd(adcs1.time)
adcs1doy = jd2yd(adcs1jd) - baseyear*1000.D0
adcs2jd = gps2jd(adcs2.time)
adcs2doy = jd2yd(adcs2jd) - baseyear*1000.D0
adcs3jd = gps2jd(adcs3.time)
adcs3doy = jd2yd(adcs3jd) - baseyear*1000.D0
adcs4jd = gps2jd(adcs4.time)
adcs4doy = jd2yd(adcs4jd) - baseyear*1000.D0

plotdir = getenv('minxss_data')+slash+'trends'+slash+'report_eps'+slash
ans = ' '

;
;	set X-range
;
if (fm eq 1) then xrange = [130, long(max(hkdoy)/10.+0.5)*10.+10.] $
else  xrange=[337,long(max(hkdoy)/10.+0.5)*10.+10.]
xtitle='Time ('+year_str+' DOY)'
doFullMission = 1
read, 'Do you want full mission plot (0), week plot (1), or day plot (2) ? ', doFullMission

if (doFullMission eq 1) then begin
	x1 = max_doy - 9
	x2 = max_doy
	print, 'Weekly Plot default range is DOY '+strtrim(long(x1),2)+'-'+strtrim(long(x2),2)
	read, '>>>>>  Enter DOY range ? ', x1, x2
	xrange = [ x1, x2 + 1 ]
	doy_range = xrange
	datestr = year_str+'_'+ string(long(x2),format='(I03)') + '_week'
endif else if (doFullMission eq 2) then begin
	doy_select = 165L
	print, 'User entered DOY = ', date_doy
	read, ' >>>  Enter the DOY ? ', doy_select
	doy_str = string(doy_select,format='(I03)')
	doy_range = [doy_select, doy_select+1]
	hour_range = [ 0, 24.]
	read, ' >>>  Enter the Hour Range (min, max) ? ', hour_range
	xrange = hour_range
	if (hour_range[0] le -10) then hour_str = string(long(hour_range[0]),format='(I03)') $
	else hour_str = string(long(hour_range[0]),format='(I02)')
	datestr = year_str+'_'+ doy_str + '_' + hour_str + 'hour'
	xtitle = 'Hour ('+year_str+'/'+doy_str+')'
	hkdoy = (hkdoy - doy_select)*24.
	scidoy = (scidoy - doy_select)*24.
	adcs1doy = (adcs1doy - doy_select)*24.
	adcs2doy = (adcs2doy - doy_select)*24.
	adcs3doy = (adcs3doy - doy_select)*24.
	adcs4doy = (adcs4doy - doy_select)*24.
endif else begin
	; assume mission length plot
	labdate = label_date( date_format=["%M", "%Y"] )	; two-layer X axis with Month and Year
	xtickunits=['Time', 'Time']
	xtickformat='LABEL_DATE'
	xrange=[0,0]
	doy_range = [ min(hkdoy), max(hkdoy)+1 ]
	xticks = long((max(hkjd)-min(hkjd))/60.5)+1
endelse

;
;	VERTICAL LINES OPTIONS for MinXSS-2
;
if (baseyear ge 2018) and (doFullMission eq 1) then doVerticalLines = 1 else doVerticalLines = 0
verticalDOY = 0L
if (baseyear eq 2018) and (doy_range[0] ge 337) and (doy_range[1] lt 367) then begin
  verticalDOY = [ 337.+(21.+37/60.)/24., 338.+(2.+52/60.)/24., $
  				341.+(18.+53/60.)/24., 344.+(22.+0/60.)/24., 347.+(21.+0/60.)/24., $
  				354.+(10.+33/60.)/24., 356.+(3.+44/60.)/24., 357.+(8.+52./60.)/24., $
  				358.+(8.+52./60.)/24., 360.+(23.+58./60.)/24., 361.+(22.+31/60.)/24, $
  				362.+(8.+18/60.)/24., 362.+(19.+11/60.)/24. ]
  verticalName = [ 'Deployed', 'Safe Mode', $
  			'Sci Mode', 'XACT Reset', 'RW Bias', $
  			'I2C LU', 'Radio LU', 'Radio Reset', $
  			'CDH Reset', 'XACT WDog', 'XACT Reset', $
  			'Radio LU', 'Radio Reset' ]
endif
if (baseyear eq 2019) and (doy_range[0] ge 0) and (doy_range[1] lt 365) then begin
  verticalDOY = [ 5.+(0.)/24., 5.+(19.)/24., 6.+(3.6)/24., 6.+(18.5)/24., $
  				7.+(2.5)/24., 7+(8.5)/24., 7.+(7.)/24., 7.+(19.)/24 ]

  verticalName = [ 'ADCS LU', 'ADCS Reset', 'Radio LU', 'Radio Reset', $
  			'Radio LU', 'Radio Reset', '3V High Cur', 'Hard Reset' ]
endif

;  OPTION TO JUMP TO SPECIFIC PLOT # LABEL
GOTO, PLOT_1

LOOP_START:

;
;		1)  Battery Voltage, 5V, 3.3V
;			hk.eps_fg_volt, hk.eps_5v_volt, hk.eps_3v_volt
;
PLOT_1:
plot1 = minxssfm + '_report_'+datestr+'_plot01.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plots to folder ', plotdir
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [3, 9]
ytitle='Volts'
mtitle='EPS Battery (diamond), 5V (triangle), 3.3V (plus)'

if doFullMission eq 0 then begin
  plot, hkjd, hk.eps_5v_volt, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  thk = hkjd
endif else begin
  plot, hkdoy, hk.eps_5v_volt, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
  thk = hkdoy
endelse

oplot, thk, hk.eps_3v_volt, psym=1
oplot, !x.crange, 6.9*[1,1], line=2, color=cc[0]  ; Phoenix Mode edge
oplot, thk[wel], hk[wel].eps_fg_volt, psym=4, color=celipse
oplot, thk[wsun], hk[wsun].eps_fg_volt, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		1B)  Battery Voltage, 5V, 3.3V - BUT from CDH monitors
;			hk.cdh_batt_v, hk.cdh_5v, hk.cdh_3v
;
PLOT_1B:
plot1 = minxssfm + '_report_'+datestr+'_plot01b.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [3, 9]
ytitle='Volts'
mtitle='CDH Battery (diamond), 5V (triangle), 3.3V (plus)'

if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.cdh_5v, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.cdh_5v, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, thk, hk.cdh_3v, psym=1
oplot, !x.crange, 6.9*[1,1], line=2, color=cc[0]  ; Phoenix Mode edge
oplot, thk[wel], hk[wel].cdh_batt_v, psym=4, color=celipse
oplot, thk[wsun], hk[wsun].cdh_batt_v, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		1)  Battery Voltage, 5V, 3.3V CURRENT instead of VOLT
;			hk.eps_batt_cur, hk.eps_5v_cur, hk.eps_3v_cur
;
PLOT_1C:
plot1 = minxssfm + '_report_'+datestr+'_plot01c.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plots to folder ', plotdir
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [0,1000]
ytitle='Current (mA)'
mtitle='EPS Battery/2 (diamond), 5V (triangle), 3.3V (plus)'

if doFullMission eq 0 then begin
  plot, hkjd, hk.eps_5v_cur, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  thk = hkjd
endif else begin
  plot, hkdoy, hk.eps_5v_cur, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
  thk = hkdoy
endelse

oplot, thk, hk.eps_3v_cur, psym=1
oplot, thk[wel], hk[wel].eps_batt_cur/2., psym=4, color=celipse
oplot, thk[wsun], hk[wsun].eps_batt_cur/2., psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		2)  SA Power, System Power, Battery Charge
;			SUM_N=1_to_3 ( hk.eps_saN_cur * hk.eps_saN_volt )
;			hk.eps_batt_volt * (hk.eps_batt_cur - hk.eps_batt_charge +
;									hk.eps_batt_discharge)
;			hk.eps_batt_volt *  hk.batt_charge
;
PLOT_2:
plot2 = minxssfm + '_report_'+datestr+'_plot02.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot2
	eps2_p,plotdir+plot2
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [0, 25]
ytitle='Power (Watts)'
mtitle='Panels (diamond), System (triangle), Charging (plus)'

sa_power = hk.eps_sa1_cur * hk.eps_sa1_volt / 1000.
sa_power += hk.eps_sa2_cur * hk.eps_sa2_volt / 1000.
sa_power += hk.eps_sa3_cur * hk.eps_sa3_volt / 1000.

sys_current = hk.eps_batt_cur - hk.eps_batt_charge + hk.eps_batt_discharge
sys_power = hk.eps_batt_volt * sys_current / 1000.

batt_charge = hk.eps_batt_volt * hk.eps_batt_charge / 1000.

if doFullMission eq 0 then begin
  plot, hkjd, sys_power, psym=5, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  thk = hkjd
endif else begin
  plot, hkdoy, sys_power, psym=5, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
  thk = hkdoy
endelse

oplot, thk[wsun], batt_charge[wsun], psym=1, color=cc[0] ; red
; oplot, thk[wel], sa_power[wel], psym=4, color=celipse
oplot, thk[wsun], sa_power[wsun], psym=4, color=csun
oplot, thk, sys_power, psym=5  ; plot this on top

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		3)  CDH Temp, EPS Temp, COMM Temp
;			hk.cdh_temp, hk.eps_temp1, hk.comm_temp
;
PLOT_3:
plot3 = minxssfm + '_report_'+datestr+'_plot03.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot3
	eps2_p,plotdir+plot3
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-20, 50]
ytitle='Temperature (C)'
mtitle='EPS (diamond), CDH (triangle), COMM (plus)'

if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.cdh_temp, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.cdh_temp, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, thk, hk.comm_temp, psym=1
oplot, thk[wel], hk[wel].eps_temp1, psym=4, color=celipse
oplot, thk[wsun], hk[wsun].eps_temp1, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		4)  Battery Temp, Battery Heater
;			hk.eps_batt_temp1, hk.enable_batt_heater
;			Set Point = hk.battery_heatersetpoint
;
PLOT_4:
plot4 = minxssfm + '_report_'+datestr+'_plot04.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot4
	eps2_p,plotdir+plot4
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-5, 25]
ytitle='Temperature (C)'
mtitle='Battery (diamond), Heater Enabled (plus)'

if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.enable_batt_heater*10-10., psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.enable_batt_heater*10-10., psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, !x.crange, median(hk.battery_heatersetpoint)*[1,1], line=2, color=cc[0]
oplot, thk[wel], hk[wel].eps_batt_temp1, psym=4, color=celipse
oplot, thk[wsun], hk[wsun].eps_batt_temp1, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		5)  SPS Temp, X123 Electronics Temp
;			hk.sps_xps_temp, hk.x123_brd_temp
;
PLOT_5:
plot5 = minxssfm + '_report_'+datestr+'_plot05.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot5
	eps2_p,plotdir+plot5
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-10, 40]
ytitle='Temperature (C)'
mtitle='SPS-XP (diamond), X123 (triangle)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wx123], hk[wx123].x123_brd_temp, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wx123], hk[wx123].x123_brd_temp, psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, thk[wel], hk[wel].sps_xps_temp, psym=4, color=celipse
oplot, thk[wsun], hk[wsun].sps_xps_temp, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		6)  X123 Detector Temp
;
;
PLOT_6:
plot6 = minxssfm + '_report_'+datestr+'_plot06.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot6
	eps2_p,plotdir+plot6
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-60, 20]
ytitle='Temperature (C)'
mtitle='X123 Detector (triangle)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wx123], hk[wx123].x123_det_temp-273., psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wx123], hk[wx123].x123_det_temp-273., psym=5, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		7)  SPS-XP Counts
;
;
PLOT_7:
doSciPlot = 1	; option to only plot Sci packet info for this plot
plot7 = minxssfm + '_report_'+datestr+'_plot07.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot7
	eps2_p,plotdir+plot7
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [1E1, 1E6]
ytitle='Counts (DN/s)'
mtitle='XP-Light (diamond), XP-Dark (triangle), SPS (plus)'

if (doSciPlot eq 0) then begin
  ; plot with HK data only
  if doFullMission eq 0 then begin
    thk = hkjd
    plot, thk, hk.xps_data, psym=4, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
	  xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog, $
	  xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  endif else begin
    thk = hkdoy
    plot, thk, hk.xps_data, psym=4, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
		xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog
  endelse

  oplot, thk, hk.dark_data, psym=5, color=cc[0]
  ; oplot, thk[wel], hk[wel].sps_sum/10., psym=1, color=csun
  oplot, thk[wsun], hk[wsun].sps_sum/10., psym=1, color=csun
  oplot, thk, hk.xps_data, psym=4  ; put XP-light on top
endif else begin
  ; plot with SCI data also
  if doFullMission eq 0 then begin
    thk = hkjd
    tsci = scijd
    plot, thk, hk.xps_data, psym=4, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
	  xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog, $
	  xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  endif else begin
    thk = hkdoy
    tsci = scidoy
    plot, thk, hk.xps_data, psym=4, /nodata, xr=xrange, xs=1, yr=yr, ys=1, $
	  xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog
  endelse

  oplot, thk, hk.dark_data, psym=5, color=cc[0]
  oplot, tsci, sci.dark_data, psym=5, color=cc[0]
  ; oplot, thk[wel], hk[wel].sps_sum/10., psym=1, color=csun
  oplot, thk[wsun], hk[wsun].sps_sum/10., psym=1, color=csun
  ; oplot, thk, hk.xps_data, psym=4  ; put XP-light on top
  oplot, tsci, sci.xps_data, psym=4
endelse

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		8)  X123 Slow & Fast Counts
;
;
PLOT_8:
plot8 = minxssfm + '_report_'+datestr+'_plot08.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot8
	eps2_p,plotdir+plot8
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [1E2,5E4]
ytitle='X123 Total Signal (cts/sec)'
mtitle='HK: X123 Slow (diamond), X123 Fast (plus)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wx123], hk[wx123].x123_fast_count, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wx123], hk[wx123].x123_fast_count, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog
endelse

if (num_x123_el gt 1) then $
	oplot, thk[wx123_el_best], hk[wx123_el_best].x123_slow_count, psym=4, color=ceclipse
if (num_x123_sun gt 1) then $
	oplot, thk[wx123_sun_best], hk[wx123_sun_best].x123_slow_count, psym=4, color=csun

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		9)  CDH Mode, ADCS Mode
;		hk.spacecraft_mode, hk.adcs_mode
;
PLOT_9:
plot9 = minxssfm + '_report_'+datestr+'_plot09.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot9
	eps2_p,plotdir+plot9
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]
cs = 2.0

yr = [0,10]
ytitle='Mode'
mtitle='Spacecraft (diamond), ADCS (triangle)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.spacecraft_mode, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.spacecraft_mode, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
xyouts, xx, 1.0-0.5, 'Phoenix', charsize=cs, color=cc[0]
xyouts, xx, 2.0-0.5, 'Safe', charsize=cs, color=cc[1]
xyouts, xx, 4.0-0.5, 'Science', charsize=cs, color=cc[3]
oplot, !x.crange, 4.9*[1,1]

oplot, thk, hk.adcs_mode+5., psym=5
xyouts, xx, 5.2, 'Sun-Point', charsize=cs, color=cc[1]
xyouts, xx, 6.2, 'Fine-Ref', charsize=cs, color=cc[3]
wgd = where( hk.adcs_time_valid ne 0, numgd )
if (numgd gt 1) then oplot, thk[wgd], hk[wgd].adcs_time_valid+6., psym=5
xyouts, xx, 7.2, 'Time-Valid', charsize=cs
wgd = where( hk.adcs_refs_valid ne 0, numgd )
if (numgd gt 1) then oplot, thk[wgd], hk[wgd].adcs_refs_valid+7., psym=5
xyouts, xx, 8.2, 'Refs-Valid', charsize=cs
wgd = where( hk.adcs_attitude_valid ne 0, numgd )
if (numgd gt 1) then oplot, thk[wgd], hk[wgd].adcs_attitude_valid+8., psym=5
xyouts, xx, 9.2, 'Attitude-Valid', charsize=cs

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		10) Solar Pointing Angle - Y Axis
;		hk.sps_x (S/C Y) and hk.sps_y (S/C Z)  * 3deg/10000.
;		hk.xact_MeasSunBodyVectorX ...Y  and ...Z  (unit vector)
;
PLOT_10Y:
plot10 = minxssfm + '_report_'+datestr+'_plot10y.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot10
	eps2_p,plotdir+plot10
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-5,5]
ytitle='Solar Y Offset (deg)'
mtitle='SPS (diamond), ADCS (triangle)'
;  convert SPS range from -10000 to +10000 for its 3.0 deg FOV
sps_angle_y = hk.sps_x * 3. / 10000.
sps_angle_z = hk.sps_y * 3. / 10000.
; convert XACT SunBody vector into Y and Z axis angles in degrees
theta = atan(sqrt(hk.xact_MeasSunBodyVectorY^2.+hk.xact_MeasSunBodyVectorZ^2.) $
			/ abs(hk.xact_MeasSunBodyVectorX))
theta_deg = theta * 180./!pi
phi = atan( hk.xact_MeasSunBodyVectorZ, hk.xact_MeasSunBodyVectorY )
xact_y = theta_deg * cos(phi)
xact_z = theta_deg * sin(phi)
wgd_xact_sun = where( hk.xact_MeasSunBodyVectorX gt 0.9 and hk.eclipse_state eq 0, numgd_xact )
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, !x.crange, [0,0], line=2, color=cc[0]
oplot, thk[wsun], sps_angle_y[wsun], psym=4, color=cc[2]
if (numgd_xact gt 1) then oplot, thk[wgd_xact_sun], xact_y[wgd_xact_sun], psym=5, color=cc[1]

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		10) Solar Pointing Angle - Z axis
;		hk.sps_x (S/C Y) and hk.sps_y (S/C Z)  * 3deg/10000.
;		hk.xact_MeasSunBodyVectorX ...Y  and ...Z  (unit vector)
;
PLOT_10Z:
plot10 = minxssfm + '_report_'+datestr+'_plot10z.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot10
	eps2_p,plotdir+plot10
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-5,5]
ytitle='Solar Z Offset (deg)'
mtitle='SPS (diamond), ADCS (triangle)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, !x.crange, [0,0], line=2, color=cc[0]
oplot, thk[wsun], sps_angle_z[wsun], psym=4, color=cc[5]
if (numgd_xact gt 1) then oplot, thk[wgd_xact_sun], xact_z[wgd_xact_sun], psym=5, color=cc[4]

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		10) Solar Pointing Angle - Y & Z axis for SPS only
;		hk.sps_x (S/C Y) and hk.sps_y (S/C Z)  * 3deg/10000.
;
PLOT_10SPS:
plot10 = minxssfm + '_report_'+datestr+'_plot10sps.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot10
	eps2_p,plotdir+plot10
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

yr = [-3,3]
wsun2 = where( (hk.eclipse_state eq 0) and (thk ge xrange[0]) and (thk le xrange[1]), num2 )
if num2 gt 1 then begin
	sps_full = [ sps_angle_y[wsun2], sps_angle_z[wsun2] ]
	yr = [long(min(sps_full)*10.)/10.-0.1, long(max_filter(sps_full)*10.)/10.+0.1]
endif
ytitle='SPS Solar Offset (deg)'
mtitle='SPS Y (diamond), SPS Z (plus)'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk[wsun], sps_angle_y[wsun], /nodata, psym=4, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

oplot, !x.crange, [0,0], line=2, color=cc[0]
oplot, thk[wsun], sps_angle_y[wsun], psym=4, color=cc[2]
oplot, thk[wsun], sps_angle_z[wsun], psym=1, color=cc[5]

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		11) Radio  - Rx Bytes
;			hk.radio_received,  hk.radio_transmitted
;
PLOT_11RX:
plot11 = minxssfm + '_report_'+datestr+'_plot11Rx.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot11
	eps2_p,plotdir+plot11
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

ytitle='Radio Received (bytes)'
mtitle='Li-1 Radio Receiver Counter'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.radio_received, psym=-4, xr=xrange, xs=1, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, yr=[0,4E5], $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.radio_received, psym=-4, xr=xrange, xs=1, ys=1, yr=[0,4E5], $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		11) Radio  - Tx Bytes
;			hk.radio_received,  hk.radio_transmitted
;
PLOT_11TX:
plot11 = minxssfm + '_report_'+datestr+'_plot11Tx.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot11
	eps2_p,plotdir+plot11
endif
setplot
cc=rainbow(7)
dots, /large
celipse = cc[4]
csun = cc[3]

ytitle='Radio Transmitted (bytes)'
mtitle='Li-1 Radio Transceiver Counter'
if doFullMission eq 0 then begin
  thk = hkjd
  plot, thk, hk.radio_transmitted, psym=-4, xr=xrange, xs=1, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, yr=[0,max_filter(hk.radio_transmitted)], $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  plot, thk, hk.radio_transmitted, psym=-4, xr=xrange, xs=1, ys=1, $
  	yr=[0,max_filter(hk.radio_transmitted)], $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
endelse

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;		12) Solar Spectrum
;			sci.x123_spectrum but excluded for
;				sci.x123_radio_flag < 2
;				sum (= total(sci.sps_data[0:3],1) / sci.sps_xp_integration_time) < 280,000.
;				date range of a week
;
sp = float(sci.x123_spectrum)
num_sci = n_elements(sci)
; convert to counts per sec (cps) with smallest time
for ii=0,num_sci-1 do sp[*,ii] = sp[*,ii] / (sci[ii].x123_live_time/1000.)

fast_count = sci.x123_fast_count / (sci.x123_accum_time/1000.)
fast_limit = 1E5
slow_count = sci.x123_slow_count / (sci.x123_live_time/1000.)

sps_sum = total(sci.sps_data[0:3],1) / float(sci.sps_xp_integration_time)
; FM1: June 2016 it is 310K; this  allows for 1-AU changes and 5% degradation
; FM2: Dec 2018
if (fm eq 1) then sps_sum_sun_min = 280000. else sps_sum_sun_min = 280000.

xmin = xrange[0]
xmax = xrange[1]
if (doFullMission eq 1) and (baseyear eq 2016) then begin
	if (fm eq 1) then begin
		; if (xmin lt 159) then xmin = 159	; wait until X123 Threshold was set
		if (baseyear eq 2018) and (xmin lt 161) then xmin = 161	; wait fine point (normal solar)
	endif else begin
		; FM-2
		if (baseyear eq 2018) and (xmin lt 345) then xmin = 345	; wait fine point (normal solar)
	endelse
endif

if (fm eq 1) then begin
	;  original way for getting good X123 packets
	; wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
	;		and (scidoy ge xmin) and (scidoy lt xmax), num_sp )
	;
	; exclude spectra with radio on (flag > 1), not in sun, and high low counts
	lowcnts = total( sp[20:24,*], 1 )
	lowLimit = 2.0		; median is 1.0 for bins 20-24
	lowLimit = 7.0		; new level for good M-class flare data
	wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
			and (scidoy ge xmin) and (scidoy lt xmax) $
			and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp )

	wsci_noise = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
			and (scidoy ge xmin) and (scidoy lt xmax) $
			and ((lowcnts ge lowLimit) or (fast_count ge fast_limit)), num_sp_noise )
	wsci_noise1 = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
			and (scidoy ge xmin) and (scidoy lt xmax) $
			and (lowcnts ge lowLimit), num_sp_noise1 )
	wsci_noise2 = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
			and (scidoy ge xmin) and (scidoy lt xmax) $
			and (fast_count ge fast_limit), num_sp_noise2 )
endif else begin
	; FM-2 selection of good X123 spectra
	lowcnts = total( sp[20:24,*], 1 )
	lowLimit = 7.0
	wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
			and (scidoy ge xmin) and (scidoy lt xmax), num_sp )
endelse

PLOT_12:

if (num_sp gt 1) and (doFullMission ge 1) then begin
  plot12 = minxssfm + '_report_'+datestr+'_plot12_sp.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot12
	eps2_p,plotdir+plot12
  endif
  setplot
  ncolors = num_sp
  if (ncolors lt 7) then ncolors = 7
  if (ncolors gt 255) then ncolors = 255
  ccc = rainbow( ncolors)
  num_sp_str = strtrim(num_sp,2)
  ; print, 'Plot 12 NOTE: Plotting ' + num_sp_str + ' X123 spectra'

  ytitle='X123 Signal (cps)'
  mtitle='X123 Spectra ('+num_sp_str+')'

  erange = [0.5, 10.]
  esp = findgen(1024) * 0.02930 - 0.13  ; ??? energy scale ???
  yrange = [0.1,1E2]
  sp_avg = fltarr(1024)

  plot, esp, reform(sp[*,0]), /nodata, psym=10, xr=erange, xs=1, yr=yrange, ys=1, /xlog, /ylog, $
	xtitle='Energy (keV)', ytitle=ytitle, title=mtitle
  for ii=0,num_sp-1 do begin
    sp1 = reform(sp[*,wsci[ii]])
  	oplot, esp, sp1, psym=10, color=ccc[ii mod ncolors]
  	sp_avg += sp1
  endfor
  sp_avg /= float(num_sp)
  oplot, esp, sp_avg, thick=3, psym=10

  if doEPS ne 0 then send2 else read, 'Next ? ', ans
endif else begin
  print, 'Plot 12: Warning that X123 spectra plot was not generated.'
endelse

PLOT_12avg:

if (num_sp gt 1) and (doFullMission ge 1) then begin
  plot12a = minxssfm + '_report_'+datestr+'_plot12_sp_avg.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot12a
	eps2_p,plotdir+plot12a
  endif

  sp_stddev = fltarr(1024)
  for ii=0,1023 do sp_stddev[ii] = stddev( reform(sp[ii,wsci]) )

  setplot
  ccc = rainbow( 7 )

  ytitle='X123 Signal (cps)'
  mtitle='X123 Spectrum (average)'

  yrange = [0.1,1E2]
  if (num_sp) gt 20 then yrange=[0.01,1E2]
  if (max(sp_avg) lt 1E1) then yrange[1] = 1E1

  plot, esp, sp_avg, psym=10, /nodata, xr=erange, xs=1, yr=yrange, ys=1, /xlog, /ylog, $
	xtitle='Energy (keV)', ytitle=ytitle, title=mtitle

  xsp = [ esp[0], esp, reverse(esp), esp[0] ]
  ysp = [ sp_avg[0], sp_avg-sp_stddev, reverse(sp_avg+sp_stddev), sp_avg[0]]
  ysp = ysp > yrange[0]
  polyfill, xsp, ysp, noclip=0, clip=[erange[0]*1.03,yrange[0]*1.05,erange[1]*0.97,yrange[1]*0.95], $
  		color='F0F0F0'x  ; !color.light_grey
  oplot, esp, sp_avg, psym=10, thick=3

  if doEPS ne 0 then send2 else read, 'Next ? ', ans
endif

;
;		12)  X123 Slow & Fast Counts from SCI packets instead of HK packets
;		Changed to plot X123 Slow Counts only and overplot GOES XRS
;
num_xrs = 0L
if (num_sp gt 1) then begin

PLOT_12X123:
plot12 = minxssfm + '_report_'+datestr+'_plot12_x123_goes.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot12
	eps2_p,plotdir+plot12
endif
setplot
cc=rainbow(7)

wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scidoy ge xrange[0]) and (scidoy lt xrange[1]) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp )

wsci2 = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scidoy ge xrange[0]) and (scidoy lt xrange[1]) )
ans = 'Y'
; read, 'Do you want all X123 data in the plot ? ', ans
if strupcase(strmid(ans,0,1)) eq 'Y' then wsci = wsci2

if (doEPS eq 0) then begin
  ans = 'N'
  ; read, 'Do you want the X123 HK data plotted too ? ', ans
  if strupcase(strmid(ans,0,1)) eq 'Y' then doX123HK = 1 else doX123HK = 0
endif

yr_org = [1E1,1E5]
yr = [1E0,1E4]		; reduce to A class flares for MinXSS-2 low solar activity
ytitle='X123 Total Signal (cts/sec)'
; mtitle='SCI: X123 Slow (diamond), X123 Fast (plus)'
mtitle='X123 (SCI=diamond, HK=plus), GOES XRS (red)'
if doX123HK eq 0 then mtitle='X123 (green diamonds), GOES XRS (red)'
if doFullMission eq 0 then begin
  thk = hkjd
  tsci = scijd
  plot, tsci[wsci], fast_count[wsci], /nodata, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
endif else begin
  thk = hkdoy
  tsci = scidoy
  plot, tsci[wsci], fast_count[wsci], /nodata, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog
endelse
if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName

if doX123HK ne 0 then oplot, thk[wx123_sun_best], hk[wx123_sun_best].x123_slow_count, psym=1, color=csun
oplot, tsci[wsci], slow_count[wsci], psym=4, color=csun

if (doGOES ne 0) then begin
  if (doFullMission eq 0) then begin
    goes_time = goes_jd
  endif else if (doFullMission eq 2) then begin
    goes_time = (goes_doy - doy_select)*24.
  endif else begin
    goes_time = goes_doy
  endelse
  wxrs = where( (goes_time ge xrange[0]) and (goes_time le xrange[1]), num_xrs )
  ; xfactor = yr[0] / 1E-7
  xfactor = yr_org[0] / 1E-7
  if (num_xrs gt 1) then oplot, goes_time[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
  ; flare_name = [ 'B', 'C', 'M', 'X' ]
  flare_name = [ 'A', 'B', 'C', 'M' ]
  xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
  for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]
endif

if doEPS ne 0 then send2 else read, 'Next ? ', ans

endif  ;  for the "if (num_sp gt 1)" block of wsci plot

;
;		12)  X123 Slow at largest flare of week
;
;
PLOT_12TS:
if (doGOES ne 0) and (num_xrs gt 1) and (doFullMission eq 1) then begin
  plot12 = minxssfm + '_report_'+datestr+'_plot12_ts_flare.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot12
	eps2_p,plotdir+plot12
  endif
  setplot
  cc=rainbow(7)

  ; limit XRANGE to around the largest flare during the week
  ; wxrs = where( (goes_doy ge xrange[0]) and (goes_doy le xrange[1]), num_xrs )
  temp = max( goes_xrsb[wxrs], wmax )
  doy_base = long(goes_doy[wxrs[wmax]])
  wgpeak = wxrs[wmax]
  if (doy_base eq 163) then begin
  	doy_base = 165L
  	www=where(goes_doy ge 165.D0 and goes_doy lt 166.D0)
  	temp = max( goes_xrsb[www], wmax2 )
  	wgpeak = www[wmax2]
  endif
  scihour = (scidoy -  doy_base) * 24.  ; convert to hours
  goes_hour = (goes_doy - doy_base) * 24.

  yr = [1E1,1E5]
  ytitle='X123 Total Signal (cts/sec)'
  mtitle='X123 (diamond), XP (plus), GOES(red)'

  xrange2 = goes_hour[wgpeak] + [ -20., 40.]/60.  ; -10 min to +40 min
  xtitle2 = 'DOY ' + strtrim(doy_base,2) + ' Hours'

  xp_cps = sci.xps_data / float(sci.sps_xp_integration_time)
  dark_cps = sci.dark_data / float(sci.sps_xp_integration_time)
  wxp = where( (scihour gt xrange2[0]) and (scihour lt xrange2[1]) and (xp_cps gt 0), num_xp )

  plot, scihour[wsci], fast_count[wsci], /nodata, psym=1, xr=xrange2, xs=1, yr=yr, ys=1, $
	xtitle=xtitle2, ytitle=ytitle, title=mtitle, /ylog
  oplot, scihour[wsci], slow_count[wsci], psym=4
  if (num_xp gt 1) then oplot, scihour[wxp], xp_cps[wxp], psym=1, color=cc[3]

  xfactor = yr[0] / 1E-7
  oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
  flare_name = [ 'B', 'C', 'M', 'X' ]
  xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
  for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  hkhour = (hkdoy -  doy_base) * 24.  ; convert to hours
  ;  NOISE might be wheel speed or torque rod or ???
  ; stop, 'DEBUG Flare Noise...'

PLOT_12SP:
  plot12 = minxssfm + '_report_'+datestr+'_plot12_sp_flare.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot12
	eps2_p,plotdir+plot12
  endif
  xmin2 = xrange2[0]
  xmax2 = xrange2[1]
  wsci2 = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scihour ge xmin2) and (scihour lt xmax2) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp2 )

  setplot
  ncolors = num_sp2
  if (ncolors lt 7) then ncolors = 7
  if (ncolors gt 255) then ncolors = 255
  ccc = rainbow( ncolors)
  num_sp2_str = strtrim(num_sp2,2)
  ; print, 'Plot 12 NOTE: Plotting ' + num_sp2_str + ' X123 spectra for flare'

  ytitle='X123 Signal (cps)'
  mtitle='X123 Flare Spectra ('+num_sp2_str+')'

  erange = [0.5, 10.]
  ;esp = findgen(1024) * 0.02930 + 0.01  ; ??? energy scale ???
  yrange = [0.1,1E2]

  plot, esp, reform(sp[*,0]), /nodata, psym=10, xr=erange, xs=1, yr=yrange, ys=1, /xlog, /ylog, $
	xtitle='Energy (keV)', ytitle=ytitle, title=mtitle
  for ii=0,num_sp2-1 do begin
  	oplot, esp, reform(sp[*,wsci2[ii]]), psym=10, color=ccc[ii mod ncolors]
  endfor

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

endif


;
;		1)  PLOT Reaction Wheel Speeds
;
PLOT_13:
plot13 = minxssfm + '_report_'+datestr+'_plot13.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot13
	eps2_p,plotdir+plot13
endif
setplot
cc=rainbow(7)
dots, /large

yr = [-200,200]
ytitle='Reaction Wheel Speeds'
mtitle='RW1 (diamond), RW2 (triangle), RW3 (plus)'

if doFullMission eq 0 then begin
  plot, hkjd, hk.xact_wheel1measspeed, /nodata, $
  	xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, $
	xtickunits=xtickunits, xtickformat=xtickformat, xticks=xticks
  thk = hkjd
endif else begin
  plot, hkdoy, hk.xact_wheel1measspeed, /nodata, $
  	xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle
  thk = hkdoy
endelse

oplot, thk, hk.xact_wheel1measspeed, psym=5, color=cc[0]
oplot, thk, hk.xact_wheel2measspeed, psym=5, color=cc[3]
oplot, thk, hk.xact_wheel3measspeed, psym=1, color=cc[5]

if (doVerticalLines gt 0) then oplot_vertical_lines, verticalDOY, verticalName
if doEPS ne 0 then send2 else read, 'Next ? ', ans

;  END OF LOOP

loopcnt += 1
if (loopcnt eq 1) and (doTest eq 0) then begin
	; make EPS files now
	print, ' '
	print, 'MAKING EPS FILES ...'
   doEPS = 1
   goto, LOOP_START
endif

setplot & cc=rainbow(7)

end
