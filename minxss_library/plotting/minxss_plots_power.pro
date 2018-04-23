;+
; NAME:
;	minxss_plots_power.pro
;
; PURPOSE:
;	Plot trends of MinXSS Power and merge into single PDF file.
;	User can pass MinXSS Tlm packets or specify date/time range for the plots.
;	This only works for HK packets.
;
; CATEGORY:
;	Useful for trending power plots with MinXSS Level 0B and Level 0C data.
;
; CALLING SEQUENCE:
;	minxss_power_plots, packet, timeRange=timeRange, pdf=pdf, level=level, /verbose
;
; INPUTS:
;	packet		Optional input for passing in Tlm HK packets
;	/timeRange		Optional input to specify date/time range for the plot
;				If timeRange is one number, then it specifies a date and packet is ignored
;					and it searches for Level 0 data files
;				If timeRange is two numbers, then it specifies a time range and either uses packet
;					or it searches for Level 0  data files if packet is not provided
;	/items		Optional input array to limit which Tags are plotted (either tag number or tag name)
;	/pdf		Optional input to specify that a PDF file is saved
;				If this option is not given, then it just displays the plots interactively with the user
;				This is normally for HK packets.  If not, then set PDF to 'ADCS', 'SCI', or other packet name
;	/level		Optional input to specify 'B' or 'C' for Level 0B or Level 0C (default) data
;	/fm			Optional input to specify flight model number 1 (default) or 2
;	/verbose	Option to print progress messages
;
; OUTPUTS:
;	Plots are displayed and if /pdf is given then PDF file is written with all the plots in one file
;	/output		Optional output of the data used in the plots (array of structure)
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;   1. Check validity of input
;	2. Find (read) the data if necessary
;	3. Make plots
;		A.  SA-1 & 2  Volt, Current, Power
;		B.  SA-3 & SA-Reg-Out  Volt, Current, Power
;		C.  3V & 5V Reg  Volt, Current, Power
;		D.  Battery FG Volt, FG SOC, Charge, Discharge, Power In, Power Out
;		E.  Temperature Plots with Charge/Discharge in bottom right too
;   4. OPTION:  Write PDF files to $minxss_data/trends/power/
;
; MODIFICATION HISTORY:
; 2015/02/05: Tom Woods:        Fist version of code - based on minxss_trend_plots.pro
;	2015/02/07:	Tom Woods:        Updated with /output option and Page 5 of temperature plots
;	2015/03/20:	Tom Woods:        Updated with /timelimit option
;	2015/08/21: James Paul Mason: Changed /TIMELIMIT to NO_TIME_LIMIT
;	2015/09/08: Tom Woods:        Update to work with Level 0C files too (added /fm option)
;	2015/10/23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;+

pro  minxss_plots_power, packet, timeRange=timeRange, pdf=pdf, level=level, fm=fm, verbose=verbose, $
		output=output, NO_TIME_LIMIT=NO_TIME_LIMIT

;
;   1. Check validity of input
;
if n_params() gt 0 then begin
   ; packet provided by user
  if keyword_set(timeRange) and (n_elements(timeRange) eq 1) then begin
    ; ignore packet input if timeRange is single date
    readFiles = 1
    time1 = timeRange[0]
    time2 = timeRange[0]+1L
  endif else begin
    readFiles = 0
  endelse
endif else if keyword_set(timeRange) then begin
  ; get data based on time in timeRange
  readFiles = 1
  if n_elements(timeRange) eq 1 then begin
    time1 = timeRange[0]
    time2 = timeRange[0]+1L
  endif else begin
    time1 = timeRange[0]
    time2 = timeRange[1]
  endelse
endif else begin
  ; no data or time inputs were provided so need to exit
  print, 'USAGE: minxss_power_plots, packet, timeRange=timeRange, pdf=pdf, level=level, /verbose, output=output'
  return
endelse

if not keyword_set(fm) then fm = 1
if (fm lt 1) or (fm gt 2) then fm = 1

;
;	2. Find (read) the data if necessary
;
if (readFiles ne 0) then begin
  ; FIXME:  default choice is L0B for now but will want to change it to be L0C for flight
  if keyword_set(level) then begin
    level_str = strlowcase(strmid(level,0,1))
  endif else level_str = 'c'
  if level_str ne 'b' and level_str ne 'c' then level_str = 'c'

  ;  Define time_day_str based on time1 value expected to be in YYYYDOY format
  time_date = long(time1)
  time_year = long(time_date / 1000.)
  time_doy = time_date mod 1000L
  time_date_str = strtrim(time_year,2) + '_'
  doy_str = strtrim(time_doy,2)
  while strlen(doy_str) lt 3 do doy_str = '0' + doy_str
  time_date_str += doy_str

  ;  Level 0B file
  data_dir = getenv('minxss_data') + '/level0' + level_str + '/'
  data_file = 'minxss_l0' + level_str + '_' + time_date_str + '.sav'

  if (level_str eq 'c') then begin
    ;  Level 0C file
    data_dir = getenv('minxss_data') + '/fm'+strtrim(fm,2)+'/level0' + level_str + '/'
    data_file = 'minxss'+strtrim(fm,2)+'_l0' + level_str + '_' + time_date_str + '.sav'
  endif

   ; see if file exists before continuing
   full_filename = file_search( data_dir + data_file, count=fcount )
   if (fcount gt 0) then begin
     if keyword_set(verbose) then print, 'Restoring data from ', data_file
     restore, data_dir + data_file
     packet = temporary(hk)  ;  use the HK packet
     pdf_type = 'hk'
   endif else begin
     print, 'ERROR: minxss_power_plots can not find file = ', data_file
     return
   endelse
endif

;
;	make time array in hours using the packet.TIME variable
;
packet_time_yd = jd2yd(gps2jd(packet.time))
if (readFiles eq 0) then begin
  if keyword_set(timeRange) and (n_elements(timeRange) gt 1) then begin
     time1 = timeRange[0]
     time2 = timeRange[1]
  endif else begin
    time1 = min(packet_time_yd)
    time2 = max(packet_time_yd)
  endelse
  ;  make time_date_str based on time1 value
  time_date = long(time1)
  time_year = long(time_date / 1000.)
  time_doy = time_date mod 1000L
  time_date_str = strtrim(time_year,2) + '_'
  doy_str = strtrim(time_doy,2)
  while strlen(doy_str) lt 3 do doy_str = '0' + doy_str
  time_date_str += doy_str
endif else begin
  if keyword_set(timeRange) and (n_elements(timeRange) le 1) then time2 = max(packet_time_yd)
endelse

;
; exclude data based on time1-time2 range if don't have /NO_TIME_LIMIT
; and make time in hours for plotting
;
IF ~keyword_set(NO_TIME_LIMIT) THEN BEGIN
  wgood = where( packet_time_yd ge time1 AND packet_time_yd le time2, numgood )
  IF (numgood LT 2) THEN BEGIN
    print, 'ERROR: minxss_trend_plots needs valid data in the time range of ' + strtrim(time1,2) + ' - ' + strtrim(time2,2)
    IF keyword_set(verbose) THEN stop, 'DEBUG ...'
    return
  ENDIF
ENDIF ELSE BEGIN
  numgood = n_elements(packet_time_yd)
  wgood = indgen(numgood, /long)
ENDELSE

yd_base = time_year * 1000L + time_doy
pdata = packet[wgood]
ptime = (packet_time_yd[wgood] - yd_base)*24.  ; convert to hours since time1 YD

;
;	write output array of structure
;
output1 = { time_yd: 0.D0, time_hour: 0.0, cdh_info: 0, $
	sa1_volt: 0.0, sa1_amp: 0.0, sa1_watt: 0.0, $
	sa2_volt: 0.0, sa2_amp: 0.0, sa2_watt: 0.0, $
	sa3_volt: 0.0, sa3_amp: 0.0, sa3_watt: 0.0, $
	reg_sa_volt: 0.0, reg_sa_amp: 0.0, reg_sa_watt: 0.0, $
	reg_3v_volt: 0.0, reg_3v_amp: 0.0, reg_3v_watt: 0.0, $
	reg_5v_volt: 0.0, reg_5v_amp: 0.0, reg_5v_watt: 0.0, $
	fg_volt: 0.0, fg_soc: 0.0, $
	batt_charge_amp: 0.0, batt_charge_watt: 0.0, $
	batt_discharge_amp: 0.0, batt_discharge_watt: 0.0, $
	spacecraft_watt: 0.0, batt_temp1: 0.0, batt_temp2: 0.0, $
	eps_temp1: 0.0, eps_temp2: 0.0, cdh_temp: 0.0, comm_temp: 0.0, $
	mb_temp1: 0.0, mb_temp2: 0.0, sps_temp: 0.0, x123_temp: 0.0, $
	sa1_temp: 0.0, sa2_temp: 0.0, sa3_temp: 0.0	}

output = replicate( output1, n_elements(ptime) )

output.time_yd = packet_time_yd[wgood]
output.time_hour = ptime
output.cdh_info = pdata.cdh_info

output.sa1_volt = pdata.eps_sa1_volt;
output.sa1_amp = pdata.eps_sa1_cur/1000.;
output.sa1_watt = output.sa1_volt * output.sa1_amp
output.sa2_volt = pdata.eps_sa2_volt;
output.sa2_amp = pdata.eps_sa2_cur/1000.;
output.sa2_watt = output.sa2_volt * output.sa2_amp
output.sa3_volt = pdata.eps_sa3_volt;
output.sa3_amp = pdata.eps_sa3_cur/1000.;
output.sa3_watt = output.sa3_volt * output.sa3_amp

output.reg_sa_volt = pdata.eps_batt_volt;
output.reg_sa_amp = pdata.eps_batt_cur/1000.;
output.reg_sa_watt = output.reg_sa_volt * output.reg_sa_amp
output.reg_3v_volt = pdata.eps_3v_volt;
output.reg_3v_amp = pdata.eps_3v_cur/1000.;
output.reg_3v_watt = output.reg_3v_volt * output.reg_3v_amp
output.reg_5v_volt = pdata.eps_5v_volt;
output.reg_5v_amp = pdata.eps_5v_cur/1000.;
output.reg_5v_watt = output.reg_5v_volt * output.reg_5v_amp

output.fg_volt = pdata.eps_fg_volt
output.fg_soc = pdata.eps_fg_soc

output.batt_charge_amp = pdata.eps_batt_charge/1000.
output.batt_charge_watt = output.fg_volt * output.batt_charge_amp
output.batt_discharge_amp = pdata.eps_batt_discharge/1000.
output.batt_discharge_watt = output.fg_volt * output.batt_discharge_amp
output.spacecraft_watt = output.reg_sa_watt + output.batt_discharge_watt - output.batt_charge_watt

output.batt_temp1 = pdata.eps_batt_temp1
output.batt_temp2 = pdata.eps_batt_temp2
output.eps_temp1 = pdata.eps_temp1
output.eps_temp2 = pdata.eps_temp2
output.cdh_temp = pdata.cdh_temp
output.comm_temp = pdata.comm_temp
output.mb_temp1 = pdata.mb_temp1
output.mb_temp2 = pdata.mb_temp2
output.sps_temp = pdata.sps_xps_temp
output.x123_temp = pdata.x123_brd_temp
output.sa1_temp = pdata.eps_sa1_temp
output.sa2_temp = pdata.eps_sa2_temp
output.sa3_temp = pdata.eps_sa3_temp

;
;	3. Make plots
;		A.  SA-1 & 2  Volt, Current, Power
;		B.  SA-3 & SA-Reg-Out  Volt, Current, Power
;		C.  3V & 5V Reg  Volt, Current, Power
;		D.  Battery FG Volt, FG SOC, Charge, Discharge, Power In, Power Out
;		E.  Temperature Plots with Charge/Discharge in bottom right too
;   4. OPTION:  Write PDF files to $minxss_data/trends/power/
;
;	Layout is landscape page at 150 dpi and assumes 4 x 3 plots per page
;
num_col = 2L
num_row = 3L
num_plots_per_page = num_col * num_row
page_num = 0L
page_last = 5L
ans = ' '

;  if /pdf is given, then prepare for PDF file to be made
if keyword_set(pdf) then begin
  pdf_type = 'power'
  pdf_dir = getenv('minxss_data') + '/trends/' + pdf_type + '/'
  pdf_file = 'minxss_' + pdf_type + '_' + time_date_str + '.pdf'
  ; if keyword_set(verbose) then $
    print, 'minxss_power_plots:  PDF file = ' + pdf_dir + pdf_file
endif

;
;	now make the pages of plots
;		Use the IDL plot() function with the /layout option and .SAVE method if making PDF file
;
title2 = time_date_str
fm_number = long(median(pdata.flight_model))
title1 = 'FM-' + strtrim(fm_number,2) + ': Page '

if (num_col gt 1) then begin
  xtitle='Time (hours)'
endif else begin
  xtitle = 'Hours of ' + time_date_str
endelse
xrange = [min(ptime), max(ptime)]

xdim = num_col * 300L
ydim = num_row * 250L
if num_plots_per_page lt 2 then begin
  xdim *= 2L
  ydim *= 2L
endif

plotobj = objarr(num_plots_per_page)
plotobj[0] = plot( indgen(10), indgen(10), dimension=[xdim,ydim], /current )  ; dummy plot so window will be erased

;
;		3A.  SA-1 & 2  Volt, Current, Power
;
page_num = 1L
if (plotobj[0] ne !NULL) then begin
    ; erase the current window
    ; if (not keyword_set(pdf)) then read, 'Ready for next plot ? ', ans
    w = plotobj[0].window
    w.Erase
endif

      mtitle=title1 + strtrim(page_num,2)
      plotobj[0] = plot( ptime, pdata.EPS_SA1_VOLT, xrange=xrange, yrange=[0,20], $
        		xtitle=xtitle, ytitle='SA1 (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 1] )
      mtitle=' '
      plotobj[1] = plot( ptime, pdata.EPS_SA1_CUR/1000., xrange=xrange, yrange=[0,1], $
        		xtitle=xtitle, ytitle='SA1 (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 3] )
      plotobj[2] = plot( ptime, pdata.EPS_SA1_VOLT * pdata.EPS_SA1_CUR/1000., xrange=xrange, yrange=[0,10], $
        		xtitle=xtitle, ytitle='SA1 (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 5] )

      mtitle=title2
      plotobj[3] = plot( ptime, pdata.EPS_SA2_VOLT, xrange=xrange, yrange=[0,20], $
        		xtitle=xtitle, ytitle='SA2 (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 2] )
      mtitle=' '
      plotobj[4] = plot( ptime, pdata.EPS_SA2_CUR/1000., xrange=xrange, yrange=[0,1], $
        		xtitle=xtitle, ytitle='SA2 (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 4] )
      plotobj[5] = plot( ptime, pdata.EPS_SA2_VOLT * pdata.EPS_SA2_CUR/1000., xrange=xrange, yrange=[0,10], $
        		xtitle=xtitle, ytitle='SA2 (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 6] )
;
;  write this page of plots to PDF file
;
if keyword_set(pdf) then begin
     if (page_num lt page_last) then plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append $
     else plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append, /close
endif

;
;		B.  SA-3 & SA-Reg-Out  Volt, Current, Power
;
page_num = 2L
if (plotobj[0] ne !NULL) then begin
    ; erase the current window
    if (not keyword_set(pdf)) then read, 'Ready for next plot ? ', ans
    w = plotobj[0].window
    w.Erase
endif

      mtitle=title1 + strtrim(page_num,2)
      plotobj[0] = plot( ptime, pdata.EPS_SA3_VOLT, xrange=xrange, yrange=[0,20], $
        		xtitle=xtitle, ytitle='SA3 (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 1] )
      mtitle=' '
      plotobj[1] = plot( ptime, pdata.EPS_SA3_CUR/1000., xrange=xrange, yrange=[0,1], $
        		xtitle=xtitle, ytitle='SA3 (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 3] )
      plotobj[2] = plot( ptime, pdata.EPS_SA3_VOLT * pdata.EPS_SA3_CUR/1000., xrange=xrange, yrange=[0,10], $
        		xtitle=xtitle, ytitle='SA3 (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 5] )

      mtitle=title2
      plotobj[3] = plot( ptime, pdata.EPS_BATT_VOLT, xrange=xrange, yrange=[6,8.5], $
        		xtitle=xtitle, ytitle='SA Reg (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 2] )
      mtitle=' '
      plotobj[4] = plot( ptime, pdata.EPS_BATT_CUR/1000., xrange=xrange, yrange=[0,3], $
        		xtitle=xtitle, ytitle='SA Reg (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 4] )
      plotobj[5] = plot( ptime, pdata.EPS_BATT_VOLT * pdata.EPS_BATT_CUR/1000., xrange=xrange, yrange=[0,20], $
        		xtitle=xtitle, ytitle='SA Reg (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 6] )
;
;  write this page of plots to PDF file
;
if keyword_set(pdf) then begin
     if (page_num lt page_last) then plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append $
     else plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append, /close
endif

;
;		C.  3V & 5V Reg  Volt, Current, Power
;
page_num = 3L
if (plotobj[0] ne !NULL) then begin
    ; erase the current window
    if (not keyword_set(pdf)) then read, 'Ready for next plot ? ', ans
    w = plotobj[0].window
    w.Erase
endif

      mtitle=title1 + strtrim(page_num,2)
      plotobj[0] = plot( ptime, pdata.EPS_3V_VOLT, xrange=xrange, yrange=[3,4], $
        		xtitle=xtitle, ytitle='3V Reg (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 1] )
      mtitle=' '
      plotobj[1] = plot( ptime, pdata.EPS_3V_CUR/1000., xrange=xrange, yrange=[0,0.3], $
        		xtitle=xtitle, ytitle='3V Reg (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 3] )
      plotobj[2] = plot( ptime, pdata.EPS_3V_VOLT * pdata.EPS_3V_CUR/1000., xrange=xrange, yrange=[0,1], $
        		xtitle=xtitle, ytitle='3V Reg (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 5] )

      mtitle=title2
      plotobj[3] = plot( ptime, pdata.EPS_5V_VOLT, xrange=xrange, yrange=[4.5,5.5], $
        		xtitle=xtitle, ytitle='5V Reg (Volts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 2] )
      mtitle=' '
      plotobj[4] = plot( ptime, pdata.EPS_5V_CUR/1000., xrange=xrange, yrange=[0,1], $
        		xtitle=xtitle, ytitle='5V Reg (Amps)', $
        		title=mtitle, /current, layout=[num_col, num_row, 4] )
      plotobj[5] = plot( ptime, pdata.EPS_5V_VOLT * pdata.EPS_5V_CUR/1000., xrange=xrange, yrange=[0,5], $
        		xtitle=xtitle, ytitle='5V Reg (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 6] )
;
;  write this page of plots to PDF file
;
if keyword_set(pdf) then begin
     if (page_num lt page_last) then plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append $
     else plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append, /close
endif

;
;		D.  Battery FG Volt, FG SOC, Charge, Discharge, Power In, Power Out
;			Also overplot CDH_Info S/C Mode on SOC plot
;
page_num = 4L
if (plotobj[0] ne !NULL) then begin
    ; erase the current window
    if (not keyword_set(pdf)) then read, 'Ready for next plot ? ', ans
    w = plotobj[0].window
    w.Erase
endif

      mtitle=title1 + strtrim(page_num,2)
      plotobj[0] = plot( ptime, pdata.EPS_FG_SOC, xrange=xrange, yrange=[0,100], $
        		xtitle=xtitle, ytitle='FG SOC', $
        		title=mtitle, /current, layout=[num_col, num_row, 1] )
      plot0a = plot( ptime, (pdata.cdh_info and '0007'X)*10., '.g', /overplot )
      plot0b = plot( ptime, (pdata.cdh_info and '0008'X)*10., '.r', /overplot )
      xx = plotobj[0].position[0]*0.5 + plotobj[0].position[2]*0.5
      yy = plotobj[0].position[1]*0.1 + plotobj[0].position[3]*0.9
      text0a = text( xx, yy, 'Mode (10,20,40:grn), Eclipse (80:red)', color='black', position=[xx,yy], font_size=12 )

      mtitle=' '
      plotobj[1] = plot( ptime, pdata.EPS_FG_VOLT, xrange=xrange, yrange=[6,8.5], $
        		xtitle=xtitle, ytitle='FG Volts', $
        		title=mtitle, /current, layout=[num_col, num_row, 3] )
      p2 = plot(plotobj[1].xrange, [min(pdata.EPS_FG_VOLT), min(pdata.EPS_FG_VOLT)], 'r--', /OVERPLOT)

      ; System power = SA power + battery discharge power - battery charge power
      power_in = pdata.EPS_BATT_VOLT * pdata.EPS_BATT_CUR/1000. $
      		+ pdata.EPS_FG_VOLT * pdata.EPS_BATT_DISCHARGE/1000. $
      		- pdata.EPS_FG_VOLT * pdata.EPS_BATT_CHARGE/1000.
      ; Power Out = Batt Discharge power
      power_out = pdata.EPS_BATT_VOLT * pdata.EPS_BATT_DISCHARGE/1000.
      plotobj[2] = plot( ptime, power_out, '-r', xrange=xrange, yrange=[0,20], $
        		xtitle=xtitle, ytitle='S/C Power (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 5] )
      plot7 = plot( ptime, power_in, /overplot, layout=[num_col, num_row, 5] )
      xx = plotobj[2].position[0]*0.5 + plotobj[2].position[2]*0.5
      yy1 = plotobj[2].position[1]*(-0.1) + plotobj[2].position[3]*1.1
      yy2 = plotobj[2].position[1]*0.1 + plotobj[2].position[3]*0.9
      text5a = text( xx, yy1, 'Discharge', color='red', position=[xx,yy2], font_size=14 )
      text5b = text( xx, yy2, 'Spacecraft', color='black', position=[xx,yy1], font_size=14 )

      mtitle=title2
      plotobj[3] = plot( ptime, pdata.EPS_BATT_CHARGE/1000., xrange=xrange, yrange=[0,2], $
        		xtitle=xtitle, ytitle='Batt Charge (A)', $
        		title=mtitle, /current, layout=[num_col, num_row, 2] )
      mtitle=' '
      plotobj[4] = plot( ptime, pdata.EPS_BATT_DISCHARGE/1000., '-r', $
      			xrange=xrange, yrange=[0,2], $
        		xtitle=xtitle, ytitle='Batt Discharge (A)', $
        		title=mtitle, /current, layout=[num_col, num_row, 4] )
      plotobj[5] = plot( ptime, pdata.EPS_BATT_VOLT * pdata.EPS_BATT_DISCHARGE/1000., '-r', $
      			xrange=xrange, yrange=[0,15], $
        		xtitle=xtitle, ytitle='Batt Power (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 6] )
      plot6 = plot( ptime, pdata.EPS_BATT_VOLT * pdata.EPS_BATT_CHARGE/1000., /overplot, $
      			layout=[num_col, num_row, 6] )
      xx = plotobj[5].position[0]*0.5 + plotobj[5].position[2]*0.5
      yy1 = plotobj[5].position[1]*(-0.1) + plotobj[5].position[3]*1.1
      yy2 = plotobj[5].position[1]*0.1 + plotobj[5].position[3]*0.9
      text6a = text( xx, yy1, 'Discharge', color='red', position=[xx,yy2], font_size=14 )
      text6b = text( xx, yy2, 'Charge', color='black', position=[xx,yy1], font_size=14 )
;
;  write this page of plots to PDF file
;
if keyword_set(pdf) then begin
     if (page_num lt page_last) then plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append $
     else plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append, /close
endif

;
;		E.  Temperature Plots with Charge/Discharge in bottom right too
;			LEFT:  (CDH, COMM, MB)  (SPS, X123)  (SA1-3)
;			RIGHT: (EPS)  (Battery)  (Charge/Discharge)
;
page_num = 5L
if (plotobj[0] ne !NULL) then begin
    ; erase the current window
    if (not keyword_set(pdf)) then read, 'Ready for next plot ? ', ans
    w = plotobj[0].window
    w.Erase
endif

      mtitle=title1 + strtrim(page_num,2)  ; LEFT TOP = (CDH, COMM, MB)
      yrange = temperature_range( [output.cdh_temp, output.comm_temp, output.mb_temp1] )
      plotobj[0] = plot( ptime, output.cdh_temp, xrange=xrange, yrange=yrange, $
        		xtitle=xtitle, ytitle='Temperature (C)', $
        		title=mtitle, /current, layout=[num_col, num_row, 1] )
      plot0a = plot(ptime, output.comm_temp, '-r', /OVERPLOT )
      plot0b = plot(ptime, output.mb_temp1, '-g', /OVERPLOT )
      plot0c = plot(ptime, output.mb_temp2, '-b', /OVERPLOT )
      xx = plotobj[0].position[0]*0.5 + plotobj[0].position[2]*0.5
      yy = plotobj[0].position[1]*0.1 + plotobj[0].position[3]*0.9
      text0a = text( xx, yy, 'CDH (blk), COMM (red), MB (grn,blue)', color='black', position=[xx,yy], font_size=12 )

      mtitle=' '   ; LEFT MIDDLE = (SPS, X123)
      yrange = temperature_range( [output.sps_temp, output.x123_temp] )
      plotobj[1] = plot( ptime, output.sps_temp, xrange=xrange, yrange=yrange, $
        		xtitle=xtitle, ytitle='Temperature (C)', $
        		title=mtitle, /current, layout=[num_col, num_row, 3] )
      plot1a = plot(ptime, output.x123_temp, '-r', /OVERPLOT )
      xx = plotobj[1].position[0]*0.5 + plotobj[1].position[2]*0.5
      yy = plotobj[1].position[1]*0.1 + plotobj[1].position[3]*0.9
      text1a = text( xx, yy, 'SPS (blk), X123 (red)', color='black', position=[xx,yy], font_size=12 )

      mtitle=' '   ; LEFT BOTTOM = (SA1-3)
      yrange = temperature_range( [output.sa1_temp, output.sa2_temp, output.sa3_temp] )
      plotobj[2] = plot( ptime, output.sa1_temp, '-r', xrange=xrange, yrange=yrange, $
        		xtitle=xtitle, ytitle='SA Temperature (C)', $
        		title=mtitle, /current, layout=[num_col, num_row, 5] )
      plot2a = plot(ptime, output.sa2_temp, '-g', /OVERPLOT )
      plot2b = plot(ptime, output.sa3_temp, '-b', /OVERPLOT )
      xx = plotobj[2].position[0]*0.5 + plotobj[2].position[2]*0.5
      yy = plotobj[2].position[1]*0.1 + plotobj[2].position[3]*0.9
      text2a = text( xx, yy, 'SA1 (red), SA2 (grn), SA3 (blue)', color='black', position=[xx,yy], font_size=12 )

      mtitle=title2  ; RIGHT TOP  (EPS)
      yrange = temperature_range( [output.eps_temp1, output.eps_temp2] )
      plotobj[3] = plot( ptime, output.eps_temp1, xrange=xrange, yrange=yrange, $
        		xtitle=xtitle, ytitle='EPS Temperature (C)', $
        		title=mtitle, /current, layout=[num_col, num_row, 2] )
      plot3a = plot(ptime, output.eps_temp2, '-b', /OVERPLOT )
      ; xx = plotobj[3].position[0]*0.5 + plotobj[3].position[2]*0.5
      ; yy = plotobj[3].position[1]*0.1 + plotobj[3].position[3]*0.9
      ; text3a = text( xx, yy, 'EPS (blk,blue)', color='black', position=[xx,yy], font_size=12 )

      mtitle=' '  ;  RIGHT MIDDLE  (Battery)
      yrange = temperature_range( [output.batt_temp1, output.batt_temp2] )
      plotobj[4] = plot( ptime, output.batt_temp1, xrange=xrange, yrange=yrange, $
        		xtitle=xtitle, ytitle='BATT Temperature (C)', $
        		title=mtitle, /current, layout=[num_col, num_row, 4] )
      plot4a = plot(ptime, output.batt_temp2, '-b', /OVERPLOT )
      ; xx = plotobj[4].position[0]*0.5 + plotobj[4].position[2]*0.5
      ; yy = plotobj[4].position[1]*0.1 + plotobj[4].position[3]*0.9
      ; text4a = text( xx, yy, 'Batt (blk,blue)', color='black', position=[xx,yy], font_size=12 )

      mtitle=' '  ;  RIGHT BOTTOM (Charge/Discharge)
      plotobj[5] = plot( ptime, pdata.EPS_BATT_VOLT * pdata.EPS_BATT_DISCHARGE/1000., '-r', $
      			xrange=xrange, yrange=[0,15], $
        		xtitle=xtitle, ytitle='Batt Power (Watts)', $
        		title=mtitle, /current, layout=[num_col, num_row, 6] )
      plot5a = plot( ptime, pdata.EPS_BATT_VOLT * pdata.EPS_BATT_CHARGE/1000., /overplot )
      xx = plotobj[5].position[0]*0.5 + plotobj[5].position[2]*0.5
      yy1 = plotobj[5].position[1]*(-0.1) + plotobj[5].position[3]*1.1
      yy2 = plotobj[5].position[1]*0.1 + plotobj[5].position[3]*0.9
      text5a = text( xx, yy1, 'Discharge', color='red', position=[xx,yy2], font_size=14 )
      text5b = text( xx, yy2, 'Charge', color='black', position=[xx,yy1], font_size=14 )
;
;  write this page of plots to PDF file
;
if keyword_set(pdf) then begin
     if (page_num lt page_last) then plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append $
     else plotobj[0].Save, pdf_dir + pdf_file, resolution=150, /append, /close
endif

;
;  end of Power Plots
;
if keyword_set(verbose) then begin
  print, 'minxss_power_plots: completed all of the plots'
  ; stop, 'DEBUG the data used in the plots...'
endif

return
end
