;+
; NAME:
;   minxss_plot_adcs_torque_rod_duty_cycle_vs_time
;
; PURPOSE:
;   Plot the torque rod duty cycle over time
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
;   Plot the torque rod duty cycle over time
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
;   2017-01-10: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_torque_rod_duty_cycle_vs_time, saveloc = saveloc, $
                                                    STACKPLOT_VS_ALTITUDE = STACKPLOT_VS_ALTITUDE

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
smoothNumberOfPoints = 500

; Setup
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  positionPlotBottom = [0.18, 0.15, 0.95, 0.45]
ENDIF ELSE BEGIN
  positionPlotBottom = [0.18, 0.1, 0.95, 0.95]
ENDELSE
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Smooth the data
smooth1 = smooth(adcs4.tr2_duty_cycle, smoothNumberOfPoints) ; MinXSS +X = XACT -Y
smooth2 = smooth(adcs3.tr1_duty_cycle, smoothNumberOfPoints) ; MinXSS +Y = XACT +X
smooth3 = smooth(adcs4.tr3_duty_cycle, smoothNumberOfPoints) ; MinXSS +Z = XACT +Z

; Create plots versus time
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(adcs4.time_jd, adcs4.tr2_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'tomato', POSITION = positionPlotBottom, FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Torque Rod Duty Cycle [%]', YRANGE = [-10, 100], $
          NAME = 'X')
p2 = plot(adcs3.time_jd, adcs3.tr1_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $
          NAME = 'Y')
p3 = plot(adcs4.time_jd, adcs4.tr3_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = 'Z')
p1a = plot(adcs4.time_jd, smooth1, '2', COLOR = 'firebrick', /OVERPLOT, $
           NAME = '1 smooth*')
p2a = plot(adcs3.time_jd, smooth2, '2', COLOR = 'lime', /OVERPLOT, $
           NAME = '2 smooth*')
p3a = plot(adcs4.time_jd, smooth3, '2', COLOR = 'medium blue', /OVERPLOT, $
           NAME = '3 smooth*')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.89, 0.45], FONT_SIZE = fontSize - 2)
t1 = text(0.89, 0.16, 'solids = ' + JPMPrintNumber(smoothNumberOfPoints, /NO_DECIMALS) + ' pt boxcar smooth', ALIGNMENT = 1, FONT_SIZE = fontSize - 2)

IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  altitude3 = minxss_get_altitude(timeJd = adcs3.time_jd)
  altitude4 = minxss_get_altitude(timeJd = adcs4.time_jd)
  p4 = plot(altitude4, adcs4.tr2_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'tomato', POSITION = [0.18, 0.59, 0.95, 0.93], /CURRENT, FONT_SIZE = fontSize, $
            TITLE = 'MinXSS-1 On-Orbit', $
            XTITLE = 'Altitude [km]', XRANGE = [430, 140], $
            YRANGE = [-10, 100])
  p5 = plot(altitude3, adcs3.tr1_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT)
  p6 = plot(altitude4, adcs4.tr3_duty_cycle, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT)
  l1.position = [0.31, 0.62]
  t1.position = [0.78, 0.45]
  p1.title = ''
  p1.ytitle = ''
  t2 = text(0.05, 0.5, 'Torque Rod Duty Cycle [%]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)
ENDIF

; Save plot to disk
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  p1.save, saveloc + 'Torque Rod Duty Cycle Vs Time And Altitude.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'Torque Rod Duty Cycle Vs Time.png'
ENDELSE

END