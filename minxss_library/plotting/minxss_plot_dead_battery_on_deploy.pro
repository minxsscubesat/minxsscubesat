;+
; NAME:
;   minxss_plot_dead_battery_on_deploy
;
; PURPOSE:
;   Make plots to help figure out what happened to the battery after deployment of MinXSS-2. 
;   Did it really get super cold (< 5ºC)? 
;
; INPUTS:
;   None, but calls MinXSS l0c mission length saveset
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Various plots
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS-2 l0c mission length data
;
; EXAMPLE:
;   Just run it! 
;-
PRO minxss_plot_dead_battery_on_deploy

; Defaults
fontSize = 16

restore, getenv('minxss_data') + 'fm2/level0c/minxss2_l0c_all_mission_length.sav'

; Don't care about the whole mission, just the initial period with a dead then cold battery, until it recovered
hk = hk[0:200]

; Figure out when in eclipse/sunlight to overlay on plots
spacecraft_location, id_satellite = 43758, hk.time_jd, location, sunlight, /J2000

; Convert sunlight into a polygon
polyx = [hk.time_jd, reverse(hk.time_jd)]
polyy = [sunlight * 100 - 10, fltarr(n_elements(sunlight)) - 10]

w = window(DIMENSION = [1400, 1400], FONT_SIZE = fontSize)
p1 = plot(hk.time_jd, hk.eps_fg_volt, '--', SYMBOL = 'circle', SYM_SIZE = 0.5, /SYM_FILLED, THICK = 2, LAYOUT = [1, 5, 1], /CURRENT, $
          TITLE = 'MinXSS-2 Deploy Battery Anomaly', $
          XTICKUNITS = ['Hour'], XMAJOR = 20, $
          YTITLE = 'Battery Voltage [V]', $
          FONT_SIZE = fontSize, BACKGROUND_COLOR = 'light grey')
p2 = plot(hk.time_jd, hk.eps_batt_temp1, '--', COLOR = 'tomato', SYMBOL = 'circle', SYM_SIZE = 0.5, /SYM_FILLED, THICK = 2, LAYOUT = [1, 5, 2], /CURRENT, $
          XTICKUNITS = ['Hour'], XMAJOR = 20, $
          YTITLE = 'Battery Temperature [ºC]', $
          FONT_SIZE = fontSize, BACKGROUND_COLOR = 'light grey')
p3 = plot(hk.time_jd, hk.eps_batt_temp2, '--', COLOR = 'dodger blue', SYMBOL = 'circle', SYM_SIZE = 0.5, /SYM_FILLED, THICK = 2, /OVERPLOT)
p4 = plot(hk.time_jd, hk.enable_batt_heater, THICK = 2, LAYOUT = [1, 5, 3], /CURRENT, $
          XTICKUNITS = ['Hour'], XMAJOR = 20, $
          YTITLE = 'Battery Heater', YRANGE = [-1, 2], YTICKVALUES = [0, 1], YTICKNAME = ['Off', 'On'], $
          FONT_SIZE = fontSize, BACKGROUND_COLOR = 'light grey')
p5 = plot(hk.time_jd, hk.eps_batt_discharge / 1e3, '--', SYMBOL = 'circle', SYM_SIZE = 0.5, /SYM_FILLED, THICK = 2, LAYOUT = [1, 5, 4], /CURRENT, $
          XTICKUNITS = ['Hour'], XMAJOR = 20, $
          YTITLE = 'Batt Discharge [A]', $
          FONT_SIZE = fontSize, BACKGROUND_COLOR = 'light grey')
p6 = plot(hk.time_jd, hk.spacecraft_mode, THICK = 2, LAYOUT = [1, 5, 5], /CURRENT, $
          XTITLE = 'UTC Hour of ' + strmid(hk[0].time_human, 0, 10), XTICKUNITS = ['Hour'], XMAJOR = 20, $
          YTITLE = 'Spacecraft Mode', YRANGE = [0, 4], YTICKNAME = ['', '', 'Phoenix', '', 'Safe', '', '', '', 'Science'], $
          FONT_SIZE = fontSize, BACKGROUND_COLOR = 'light grey')

; Add sunlight periods as overlay
p = polygon(polyx, polyy, /DATA, /FILL_BACKGROUND, FILL_TRANSPARENCY = 80, FILL_COLOR = 'goldenrod', target = [p1])
p = polygon(polyx, polyy, /DATA, /FILL_BACKGROUND, FILL_TRANSPARENCY = 80, FILL_COLOR = 'goldenrod', target = [p2])
p = polygon(polyx, polyy, /DATA, /FILL_BACKGROUND, FILL_TRANSPARENCY = 80, FILL_COLOR = 'goldenrod', target = [p4])
p = polygon(polyx, polyy, /DATA, /FILL_BACKGROUND, FILL_TRANSPARENCY = 80, FILL_COLOR = 'goldenrod', target = [p5])
p = polygon(polyx, polyy, /DATA, /FILL_BACKGROUND, FILL_TRANSPARENCY = 80, FILL_COLOR = 'goldenrod', target = [p6])
t = text(0.80, 0.93, 'sunlight', COLOR = 'goldenrod', TARGET = [w], FONT_SIZE = fontSize)
t = text(0.88, 0.93, 'eclipse', COLOR = 'light grey', TARGET = [w], FONT_SIZE = fontSize)

END