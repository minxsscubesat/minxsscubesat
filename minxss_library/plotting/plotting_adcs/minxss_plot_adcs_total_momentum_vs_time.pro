;+
; NAME:
;   minxss_plot_adcs_total_momentum_vs_time
;
; PURPOSE:
;   Plot the total system momentum versus time
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory. 
;
; KEYWORD PARAMETERS:
;   STACKPLOT_VS_ALTITUDE: Set this to make a stacked plot vs time and vs altitude
;
; OUTPUTS:
;   Plot of total system momentum versus time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2016-12-28: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_total_momentum_vs_time, saveloc = saveloc, $
                                             STACKPLOT_VS_ALTITUDE = STACKPLOT_VS_ALTITUDE

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Setup
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  positionPlotBottom = [0.18, 0.15, 0.95, 0.45]
ENDIF ELSE BEGIN
  positionPlotBottom = [0.18, 0.1, 0.95, 0.95]
ENDELSE
fontSize = 16
  
; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Compute the total momentum, it's mean and standard deviation
totalMomentum = sqrt(adcs3.system_momentum1^2 + adcs3.system_momentum2^2 + adcs3.system_momentum3^2)
meanMomentum = mean(totalMomentum)
standardDeviationMomentum = stddev(totalMomentum)

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(adcs3.time_jd, totalMomentum, '2', COLOR = 'goldenrod', POSITION = positionPlotBottom, FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Total System Momentum [Nms]')
p2 = plot(p1.xrange, [0.011, 0.011], '2--', COLOR = 'tomato', /OVERPLOT)
t2 = text(0.90, 0.85, 'wheel cutoff', ALIGNMENT = 1, COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t3 = text(0.42, 0.38, '$\mu$ = ' + JPMPrintNumber(meanMomentum, /SCIENTIFIC_NOTATION), ALIGNMENT = 1, FONT_SIZE = fontSize - 2)
t4 = text(0.42, 0.34, '$\sigma$ = ' + JPMPrintNumber(standardDeviationMomentum, /SCIENTIFIC_NOTATION), ALIGNMENT = 1, FONT_SIZE = fontSize - 2)

IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  altitude = minxss_get_altitude(timeJd = adcs3.time_jd)
  p3 = plot(altitude, totalMomentum, '2', COLOR = 'goldenrod', SYMBOL = '*', LINESTYLE = 'none', POSITION = [0.18, 0.59, 0.95, 0.93], /CURRENT, $
            FONT_SIZE = fontSize, $
            TITLE = 'MinXSS-1 On-Orbit', $
            XTITLE = 'Altitude [km]', XRANGE = [430, 240])
  p4 = plot(p3.xrange, [0.011, 0.011], '2--', COLOR = 'tomato', /OVERPLOT)
  t4 = text(0.90, 0.38, 'wheel cutoff', ALIGNMENT = 1, COLOR = 'tomato', TARGET = p3, FONT_SIZE = fontSize - 2)
  t5 = text(0.05, 0.50, 'Total System Momentum [Nms]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)
  p1.title = ''
  p1.ytitle = ''
ENDIF

; Save plot to disk
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  p1.save, saveloc + 'Total Momentum Vs Time and Altitude.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'Total Momentum Vs Time.png'
ENDELSE

END