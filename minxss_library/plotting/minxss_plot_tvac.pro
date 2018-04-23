;+
; NAME:
;   minxss_plot_tvac
;
; PURPOSE:
;   Make plots for analysis of MinXSS performance in TVAC
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path where you want plots to be saved. If none specified, 
;                     then won't automatically save to disk. 
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages to console
;
; OUTPUTS:
;   Plots of analysis, not saved to disk at this time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code package
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2016/08/22: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tvac, saveloc = saveloc, $ 
                      VERBOSE = VERBOSE

; Restore the data for MinXSS-1 and rename the hk variable so it isn't overwritten when restoring MinXSS-2 TVAC
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_tvac.sav'
hk1 = temporary(hk)

; Restore the data for MinXSS-2 and rename the hk variable for consistency
restore, getenv('minxss_data') + '/fm2/level0c/minxss2_l0c_all_tvac.sav'
hk2 = temporary(hk)

; Compute hours since start for both TVACs
hours1 = (hk1.time - hk1[0].time) / 3600. ; seconds to hours
hours2 = (hk2.time_jd - hk2[0].time_jd) * 24. ; fraction of day to hours

; Plot battery voltages side by side 
batteryYRange = [6.0, 8.5]
w1 = window(DIMENSIONS = [800, 800])
p1 = plot(hours1, hk1.eps_fg_volt, LAYOUT = [2, 2, 1], /CURRENT, $
          TITLE = 'MinXSS-1 Fuel Gauge', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'FG Battery Voltage [V]', YRANGE = batteryYRange)
p2 = plot(hours2, hk2.eps_fg_volt, LAYOUT = [2, 2, 2], /CURRENT, $
          TITLE = 'MinXSS-2 Fuel Gauge', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'FG Battery Voltage [V]', YRANGE = batteryYRange)
p3 = plot(hours1, hk1.cdh_batt_v, 'b', LAYOUT = [2, 2, 3], /CURRENT, $
          TITLE = 'MinXSS-1 CDH Battery Voltage', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'CDH Battery Voltage [V]', YRANGE = batteryYRange)
p4 = plot(hours2, hk2.cdh_batt_v, 'b', LAYOUT = [2, 2, 4], /CURRENT, $
          TITLE = 'MinXSS-2 CDH Battery Voltage', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'CDH Battery Voltage [V]', YRANGE = batteryYRange)
t1 = text(0.5, 0.96, 'TVAC Battery Voltage Comparison', ALIGNMENT = 0.5, TARGET = [p1])
IF saveloc NE !NULL THEN p1.save, saveloc + '/TVAC Battery Voltage Comparison.png'


; Plot total solar array current side by side
fm1SaCurrent = hk1.EPS_SA1_CUR + hk1.EPS_SA2_CUR + hk1.EPS_SA3_CUR
fm2SaCurrent = hk2.EPS_SA1_CUR + hk2.EPS_SA2_CUR + hk2.EPS_SA3_CUR
saCurrentYRange = [0., 1500.]
w2 = window(DIMENSIONS = [1000, 400])
p5 = plot(hours1, fm1SaCurrent, LAYOUT = [2, 1, 1], /CURRENT, $
          TITLE = 'MinXSS-1 SA Total Current', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'SA Current [mA]', YRANGE = saCurrentYRange)
p6 = plot(hours2, fm2SaCurrent, LAYOUT = [2, 1, 2], /CURRENT, $
          TITLE = 'MinXSS-2 SA Total Current', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'SA Current [mA]', YRANGE = saCurrentYRange)
t1 = text(0.5, 0.96, 'TVAC Total SA Current Comparison', ALIGNMENT = 0.5, TARGET = [p5])
IF saveloc NE !NULL THEN p5.save, saveloc + '/TVAC SA Current Comparison.png'

; Plot battery temperature side by side
batteryYRange = [-10, 50]
w3 = window(DIMENSIONS = [1000, 400])
p7 = plot(hours1, hk1.eps_batt_temp1, LAYOUT = [2, 1, 1], /CURRENT, $
          TITLE = 'MinXSS-1 Battery Temperature', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'Battery Temperature [ºC]', YRANGE = batteryYRange)
p8 = plot(hours1, hk1.eps_batt_temp2, 'b', /OVERPLOT)
pdash = plot(p7.xrange, [0, 0], 'r--', /OVERPLOT)
p9 = plot(hours2, hk2.eps_batt_temp1, LAYOUT = [2, 1, 2], /CURRENT, $
          TITLE = 'MinXSS-2 Battery Temperature', $
          XTITLE = 'Hours Since Start', $
          YTITLE = 'Battery Temperature [ºC]', YRANGE = batteryYRange)
p10 = plot(hours2, hk2.eps_batt_temp2, 'b', /OVERPLOT)
pdash = plot(p9.xrange, [0, 0], 'r--', /OVERPLOT)
t1 = text(0.5, 0.96, 'TVAC Battery Temperature Comparison', ALIGNMENT = 0.5, TARGET = [p7])
IF saveloc NE !NULL THEN p7.save, saveloc + '/TVAC Battery Temperature Comparison.png'

END