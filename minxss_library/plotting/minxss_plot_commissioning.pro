;+
; NAME:
;   minxss_plot_commissioning
;
; PURPOSE:
;   Plot up some commissioning time frame data for MinXSS-2
;
; INPUTS:
;
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
;
; RESTRICTIONS:
;
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2018-12-06: James Paul Mason: Wrote script.
;-
PRO minxss_plot_commissioning, showHours = showHours

saveloc = '/Users/jmason86/Google Drive/CubeSat/MinXSS Server/8000 Ground Software : Mission Ops/8085 Commissioning MinXSS-2/8085-001 Trending Plots and Analysis/'
restore, getenv('minxss_data') + 'fm2/level0c/minxss2_l0c_all_mission_length.sav'

; Setup
IF keyword_set(showHours) THEN BEGIN
  dates = ['hour', 'day', 'month']
  margin = [0.1, 0.18, 0.1, 0.1]
ENDIF ELSE BEGIN
  dates = ['day', 'month']
  margin = 0.15
ENDELSE
xhours = ['hour', 'day', 'month']
xdays = ['day', 'month']

hours = (hk.time_jd - hk[0].time_jd) * 24.
rad2rpm = 9.54929659643

; ADCS mode
p1 = plot(adcs2.time_jd, adcs2.ADCS_MODE, title = 'ADCS mode in hk', '*--', xtickunits = dates, margin = margin, $
          yrange = [-1, 2], ytickname = ['','','Sun Point', '', 'Fine Ref', '', ''], thick = 2)
p2 = plot(adcs3.time_jd, adcs3.adcs_info and '01'x, title = 'ADCS mode in page 3', '*--', xtickunits = dates, margin = margin, $
          yrange = [-1, 2], ytickname = ['','','Sun Point', '', 'Fine Ref', '', ''], thick = 2)
p3 = plot(adcs4.time_jd, adcs4.adcs_info and '01'x, title = 'ADCS mode in page 4', '*--', xtickunits = dates, margin = margin, $
          yrange = [-1, 2], ytickname = ['','','Sun Point', '', 'Fine Ref', '', ''], thick = 2)
p1.save, saveloc + 'adcs mode in hk.png'
p2.save, saveloc + 'adcs mode in page 3.png'
p3.save, saveloc + 'adcs mode in page 4.png'
STOP


; Battery voltage
p1 = plot(hk.time_jd, hk.eps_fg_volt, title = 'Battery voltage [V]', symbol = '*', linestyle = 'none', xtickunits = dates, margin = margin)
pa = plot(p1.xrange, [7.2, 7.2], linestyle = '--', 'tomato', /OVERPLOT, thick = 2)
pb = plot(p1.xrange, [6.6, 6.6], linestyle = '--', 'orange', /OVERPLOT, thick = 2)
t = text(80, 7.2 , 'Phoenix > Safe', /data, color = 'tomato', alignment = 1)
t.font_size = 13
t2 = text(80, 6.6 , 'Safe > Phoenix', /data, color = 'orange', alignment = 1)
t2.font_size = 13
p1.save, saveloc + 'battery voltage.png'

; Temperatures
p2 = plot(hk.time_jd, hk.eps_batt_temp1, 'tomato', symbol = '*', linestyle = 'none', title = 'Battery temperature [ºC]', xtickunits = dates, margin = margin)
p3 = plot(hk.time_jd, hk.eps_batt_temp2, 'dodger blue', symbol = '*', linestyle = 'none', yrange = [-10, 20], /overplot)
p4 = plot(hk.time_jd, hk.cdh_temp, 'tomato', symbol = '*', linestyle = 'none', title = 'CDH Temperature [ºC]', xtickunits = dates, margin = margin)
p2.save, 'battery temperature.png'
p4.save, saveloc + 'cdh temperature.png'

; Spacecraft mode
p6 = plot(hk.time_jd, hk.spacecraft_mode, title = 'Spacecraft mode', font_size = 14, yrange = [1,4], ymajor = 4, symbol = '*', linestyle = 'none', sym_color = 'tomato', xtickunits = dates, margin = margin)
p6.ytickname = ['Phoenix', 'Safe', '', 'Science']
p6.save, saveloc + 'mode.png'

; Wheel speed
p1 = plot(hk.time_jd, hk.XACT_WHEEL1MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'tomato', title = 'Wheel speeds [RPM]', xtickunits = dates, font_size = 14, name = '1',  xtickunits = dates, margin = margin)
p2 = plot(hk.time_jd, hk.XACT_WHEEL2MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'lime green', /overplot, name = '2')
p3 = plot(hk.time_jd, hk.XACT_WHEEL3MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'dodger blue', /overplot, name = '3')
p1.save, saveloc + 'wheel speeds.png'

; IMU rates
mins = (adcs4.time_jd - adcs4[0].time_jd) * 24. * 60.
p1 = plot(mins, adcs4.IMU_BODY_RATE1 * !RADEG, symbol = '*', linestyle = 'none', 'tomato', xtitle = 'Minutes since XACT boot', font_size = 14, title = 'IMU body rates [º s$^{-1}$]')
p2 = plot(mins, adcs4.IMU_BODY_RATE2 * !RADEG, symbol = '*', linestyle = 'none', 'lime green', /overplot)
p3 = plot(mins, adcs4.IMU_BODY_RATE3 * !RADEG, symbol = '*', linestyle = 'none', 'dodger blue', /overplot)
p1.save, saveloc + 'imu.png'

; Torque rod duty cycle
p1 = plot(mins, adcs4.tr2_duty_cycle, '2', COLOR = 'lime green', symbol = '*', linestyle = 'none', FONT_SIZE = 14, TITLE = 'Torque rod duty cycle [%]', XTITLE = 'Minutes since XACT boot')
p2 = plot(mins, adcs4.tr3_duty_cycle, '2', COLOR = 'dodger blue', symbol = '*', linestyle = 'none', /OVERPLOT)
mins3 = (adcs3.time_jd - adcs3[0].time_jd) * 24. * 60.
p3 = plot(mins3, adcs3.tr1_duty_cycle, '2', COLOR = 'tomato', symbol = '*', linestyle = 'none', /current, xshow = 0, yshow = 0, axis_style = 4)
p1.save, saveloc + 'torque rod duty cycle.png'

; Sun body vector
p1 = plot(mins, adcs4.SUNBODY_X, symbol = '*', yrange = [-1.5, 1.5], linestyle = 'none', 'tomato', xtitle = 'Minutes since XACT boot', font_size = 14, title = 'Sun body X')
p1.save, saveloc + 'sunbodyx.png'

; Momentum body vector
mins = (adcs3.time_jd - adcs4[0].time_jd) * 24. * 60.
p1 = plot(mins, adcs3.BODY_ONLY_MOMENTUM_IN_BODY1, symbol = '*', linestyle = 'none', 'tomato', xtitle = 'Minutes since XACT boot', font_size = 14, title = 'Momentum Body Only [Nms]')
p2 = plot(mins, adcs3.BODY_ONLY_MOMENTUM_IN_BODY2, symbol = '*', linestyle = 'none', 'lime green', /overplot)
p3 = plot(mins, adcs3.BODY_ONLY_MOMENTUM_IN_BODY3, symbol = '*', linestyle = 'none', 'dodger blue', /overplot)
p1.save, saveloc + 'momentum body only.png'

totalMomentum = sqrt(adcs3.system_momentum1^2 + adcs3.system_momentum2^2 + adcs3.system_momentum3^2)
meanMomentum = mean(totalMomentum)
standardDeviationMomentum = stddev(totalMomentum)

; System momentum
p1 = plot(mins, totalMomentum, '2', COLOR = 'goldenrod', FONT_SIZE = 14, $
          TITLE = 'Total System Momentum [Nms]', $
          XTITLE = 'Minutes since XACT boot')
p2 = plot(p1.xrange, [0.011, 0.011], '2--', COLOR = 'tomato', /OVERPLOT)
t2 = text(0.90, 0.85, 'wheel cutoff', ALIGNMENT = 1, COLOR = 'tomato', FONT_SIZE = 12)
t3 = text(0.42, 0.38, '$\mu$ = ' + JPMPrintNumber(meanMomentum, /SCIENTIFIC_NOTATION), ALIGNMENT = 1, FONT_SIZE = 12)
t4 = text(0.42, 0.34, '$\sigma$ = ' + JPMPrintNumber(standardDeviationMomentum, /SCIENTIFIC_NOTATION), ALIGNMENT = 1, FONT_SIZE = 12)
p1.save, saveloc + 'momentum system.png'

STOP

END