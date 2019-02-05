;+
; NAME:
;   minxss_plot_3v_current
;
; PURPOSE:
;   Make a plot of the high 3.3V current anomaly in MinXSS-2
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
;   Plot of current
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS-2 l0c mission length data
;
; EXAMPLE:
;   Just run it!
;
;-
PRO minxss_plot_3v_current

restore, getenv('minxss_data') + 'fm2/level0c/minxss2_l0c_all_mission_length.sav'

eventIndices = where(hk.time_jd GT jpmiso2jd('2019-01-07T00:00:00Z') AND hk.time_jd LT jpmiso2jd('2019-01-08T00:00:00Z'))
hk = hk[eventIndices]

w = window(BACKGROUND_COLOR = 'black')
p1 = plot(hk.time_jd, hk.eps_batt_charge, symbol = 'circle', '--', thick = 3, SYM_COLOR = 'white', COLOR = 'white', SYM_SIZE = 2, /SYM_FILLED, font_size = 24, font_color = 'white', /CURRENT, $
          xtitle = 'UTC Hour of 2019-01-07', xtickunits = ['hour'], xcolor = 'white', $
          ytitle = '3.3 V Current [mA]', ycolor = 'white')

p1.save, 'MinXSS-2 3V Current Anomaly.png', /TRANSPARENT
STOP
END