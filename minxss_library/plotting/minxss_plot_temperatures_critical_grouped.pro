;+
; NAME:
;   minxss_plot_temperatures_critical_grouped
;
; PURPOSE:
;   Create a page of plots of critical temperatures on MinXSS over the duration of the mission with requirements annotated
;
; INPUTS:
;   None, though uses l0c mission length file
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot of temperatures
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS data and code package
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-06-01: James Paul Mason: Wrote script.
;-
PRO minxss_plot_temperatures_critical_grouped, saveloc = saveloc, fm=fm

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
IF fm EQ !NULL THEN fm = 2
fontSize = 16
margin = [0.25, 0.21, 0.1, 0.1]

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss' + strtrim(fm, 2) + '_l0c_all_mission_length.sav'

; Create plot
w = window(DIMENSIONS = [1000, 1600])
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
t0 = text(0.04, 0.5, 'Temperature [ºC]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)

; Motherboard
goodData = where(hk.mb_temp1 GT -40 AND hk.mb_temp1 LT 50)
p1 = plot(hk[goodData].time_jd, hk[goodData].mb_temp1, COLOR = 'forest green', THICK = 2, LAYOUT = [2, 4, 1], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'Motherboard', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-50, 100])
p1a = plot(p1.xrange, [-40, -40], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [-30, -30], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [70, 70], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [85, 85], '2--', COLOR = 'red', /OVERPLOT)

; EPS board
goodData = where(hk.eps_temp1 GT -30 AND hk.eps_temp1 LT 60)
p1 = plot(hk[goodData].time_jd, hk[goodData].eps_temp1, COLOR = 'purple', THICK = 2, LAYOUT = [2, 4, 2], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'EPS Board', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-50, 100])
p1a = plot(p1.xrange, [-40, -40], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [-30, -30], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [70, 70], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [85, 85], '2--', COLOR = 'red', /OVERPLOT)

; CDH board
p1 = plot(hk[goodData].time_jd, hk[goodData].cdh_temp, COLOR = 'yellow green', THICK = 2, LAYOUT = [2, 4, 3], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'CDH Board', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-50, 100])
p1a = plot(p1.xrange, [-40, -40], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [-30, -30], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [70, 70], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [85, 85], '2--', COLOR = 'red', /OVERPLOT)

; Batteries
goodData = where(hk.eps_batt_temp1 LT 100 AND hk.eps_batt_temp1 GT -100)
p1 = plot(hk[goodData].time_jd, hk[goodData].eps_batt_temp1, COLOR = 'cornflower', THICK = 2, LAYOUT = [2, 4, 4], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'Batteries', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-30, 80])
p1a = plot(p1.xrange, [-20, -20], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [0, 0], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [40, 40], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [70, 70], '2--', COLOR = 'red', /OVERPLOT)

; Solar arrays
goodData = where(hk.eps_sa1_temp LT 100 AND hk.eps_sa1_temp GT -100)
p1 = plot(hk[goodData].time_jd, hk[goodData].eps_sa1_temp, COLOR = 'dodger blue', THICK = 2, LAYOUT = [2, 4, 5], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'Solar Arrays', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-120, 120])
goodData = where(hk.eps_sa2_temp LT 100 AND hk.eps_sa2_temp GT -100)
p2 = plot(hk[goodData].time_jd, hk[goodData].eps_sa2_temp, COLOR = 'purple', /OVERPLOT)
goodData = where(hk.eps_sa3_temp LT 100 AND hk.eps_sa3_temp GT -100)
p3 = plot(hk[goodData].time_jd, hk[goodData].eps_sa3_temp, COLOR = 'sea green', /OVERPLOT)
t1 = text(0.15, 0.44, '-Y', COLOR = 'dodger blue', FONT_SIZE = fontSize - 2)
t2 = text(0.15, 0.42, '+X', COLOR = 'purple', FONT_SIZE = fontSize - 2)
t3 = text(0.15, 0.40, '+Y', COLOR = 'sea green', FONT_SIZE = fontSize - 2)
p1a = plot(p1.xrange, [-75, -75], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [-75, -75], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [100, 100], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [100, 100], '2--', COLOR = 'red', /OVERPLOT)

; COMM board
goodData = where(hk.comm_temp GT -50 AND hk.comm_temp LT 75)
p1 = plot(hk[goodData].time_jd, hk[goodData].comm_temp, COLOR = 'dark orange', THICK = 2, LAYOUT = [2, 4, 6], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'COMM Board', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2)
p1b = plot(p1.xrange, [-30, -30], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [70, 70], '2--', COLOR = 'tomato', /OVERPLOT)

; X123 electronics
p1 = plot(hk.time_jd, hk.x123_brd_temp, COLOR = 'dark sea green', THICK = 2, LAYOUT = [2, 4, 7], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'X123 Electronics', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YRANGE = [-50, 100])
p1a = plot(p1.xrange, [-40, -40], '2--', COLOR = 'dark blue', /OVERPLOT)
p1b = plot(p1.xrange, [-20, -20], '2--', COLOR = 'light blue', /OVERPLOT)
p1c = plot(p1.xrange, [50, 50], '2--', COLOR = 'tomato', /OVERPLOT)
p1d = plot(p1.xrange, [85, 85], '2--', COLOR = 'red', /OVERPLOT)

; X123 detector
hk.x123_det_temp = hk.x123_det_temp - 273.15
goodData = where(hk.x123_det_temp GT -100)
p1 = plot(hk[goodData].time_jd, hk[goodData].x123_det_temp, COLOR = 'dark sea green', THICK = 2, LAYOUT = [2, 4, 8], /CURRENT, FONT_SIZE = fontSize, $
          MARGIN = margin, $
          TITLE = 'X123 Detector', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2)
p1a = plot(p1.xrange, [-50, -50], '2--', /OVERPLOT)

p1.save, saveloc + 'MissionLengthTemperatures.png'

END