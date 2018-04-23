;+
; NAME:
;   minxss_plot_adcs_drag_vs_time
;
; PURPOSE:
;   Plot the estimated drag as a function of time
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
;   Plot of estimated drag vs time and optionally altitude
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
PRO minxss_plot_adcs_drag_vs_time, saveloc = saveloc, $
                                   STACKPLOT_VS_ALTITUDE = STACKPLOT_VS_ALTITUDE
  
; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
  
; Setup
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  positionPlotBottom = [0.22, 0.15, 0.95, 0.45]
ENDIF ELSE BEGIN
  positionPlotBottom = [0.22, 0.1, 0.95, 0.95]
ENDELSE
smoothNumberOfPoints = 500
fontSize = 16
  
; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Merge hk data with the adcs packet since we have those telemetry points in both
timeJd = [adcs2.time_jd, hk.time_jd]
sortedIndices = sort(timeJd)
timeJd = timeJd[sortedIndices]
wheel1EstDrag = [adcs2.wheel_est_drag1, hk.xact_wheel1estdrag] * !RADEG
wheel1EstDrag = wheel1EstDrag[sortedIndices]
wheel2EstDrag = [adcs2.wheel_est_drag2, hk.xact_wheel2estdrag] * !RADEG
wheel2EstDrag = wheel2EstDrag[sortedIndices]
wheel3EstDrag = [adcs2.wheel_est_drag3, hk.xact_wheel3estdrag] * !RADEG
wheel3EstDrag = wheel3EstDrag[sortedIndices]

; Smooth the data
smooth1 = smooth(wheel1EstDrag, smoothNumberOfPoints)
smooth2 = smooth(wheel2EstDrag, smoothNumberOfPoints)
smooth3 = smooth(wheel3EstDrag, smoothNumberOfPoints)

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(timeJd, wheel1EstDrag, '*', COLOR = 'tomato', POSITION = positionPlotBottom, FONT_SIZE = fontSize, $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Estimated Drag [º s$^{-2}$]', $
          NAME = '1')
p2 = plot(timeJd, wheel2EstDrag, '*', COLOR = 'lime green', /OVERPLOT, $
          NAME = '2')
p3 = plot(timeJd, wheel3EstDrag, '*', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = '3')
p1a = plot(timeJd, smooth1, '2', COLOR = 'firebrick', /OVERPLOT, $
          NAME = '1 smooth*')
p2a = plot(timeJd, smooth2, '2', COLOR = 'lime', /OVERPLOT, $
          NAME = '2 smooth*')
p3a = plot(timeJd, smooth3, '2', COLOR = 'medium blue', /OVERPLOT, $
          NAME = '3 smooth*')
l1 = legend(TARGET = [p1, p2, p3, p1a, p2a, p3a], POSITION = [0.89, 0.45], FONT_SIZE = fontSize - 2)
t1 = text(0.89, 0.16, '*' + JPMPrintNumber(smoothNumberOfPoints, /NO_DECIMALS) + ' pt boxcar smooth', ALIGNMENT = 1, FONT_SIZE = fontSize - 2)

IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  altitude = minxss_get_altitude(timeJd = timeJd)
  p4 = plot(altitude, wheel1EstDrag, '*', COLOR = 'tomato', /CURRENT, POSITION = [0.22, 0.59, 0.95, 0.93], FONT_SIZE = fontSize, $
            TITLE = 'MinXSS-1 On-Orbit', $
            XTITLE = 'Altitude [km]', XRANGE = [430, 140])
  p5 = plot(altitude, wheel2EstDrag, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT)
  p6 = plot(altitude, wheel3EstDrag, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT)
  l1.position = [0.48, 0.75]
  t1.position = [0.83, 0.45]
  p1.title = ''
  p1.ytitle = ''
  t2 = text(0.04, 0.5, 'Estimated Drag [º s$^{-2}$]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)
ENDIF

; Save plot to disk
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  p1.save, saveloc + 'Drag Vs Time And Altitude.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'Drag Vs Time.png'
ENDELSE

END