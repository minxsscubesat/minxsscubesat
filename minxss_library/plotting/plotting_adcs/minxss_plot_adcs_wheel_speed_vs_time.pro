;+
; NAME:
;   minxss_plot_adcs_wheel_speed_vs_time
;
; PURPOSE:
;   Plot the wheel speeds as a function of time
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
;   Plot of wheel speeds vs time
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
;   2016-12-29: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_wheel_speed_vs_time, saveloc = saveloc, $
                                          STACKPLOT_VS_ALTITUDE = STACKPLOT_VS_ALTITUDE

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
smoothNumberOfPoints = 5000

; Setup
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  positionPlotBottom = [0.18, 0.15, 0.95, 0.45]
ENDIF ELSE BEGIN
  positionPlotBottom = [0.18, 0.1, 0.95, 0.95]
ENDELSE
rad2rpm = 9.54929659643
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Merge hk data with the adcs packet since we have those telemetry points in both
timeJd = [adcs2.time_jd, hk.time_jd]
sortedIndices = sort(timeJd)
timeJd = timeJd[sortedIndices] 
wheel1Speed = [-adcs2.wheel_meas_speed2, -hk.xact_wheel2measspeed] ; [rad/sec], MinXSS +X = XACT -Y
wheel1Speed = wheel1Speed[sortedIndices] * rad2rpm ; [RPM]
wheel2Speed = [adcs2.wheel_meas_speed1, hk.xact_wheel1measspeed] ; [rad/sec],  MinXSS +Y = XACT +X
wheel2Speed = wheel2Speed[sortedIndices] * rad2rpm ; [RPM] 
wheel3Speed = [adcs2.wheel_meas_speed3, hk.xact_wheel3measspeed] ; [rad/sec], MinXSS +Z = XACT +Z
wheel3Speed = wheel3Speed[sortedIndices] * rad2rpm ; [RPM]

; Smooth the data to more easily see if there's a trend
wheel1SpeedSmooth = smooth(wheel1Speed, smoothNumberOfPoints)
wheel2SpeedSmooth = smooth(wheel2Speed, smoothNumberOfPoints)
wheel3SpeedSmooth = smooth(wheel3Speed, smoothNumberOfPoints)

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(timeJd, wheel1Speed, '2', SYMBOL = '*', COLOR = 'tomato', POSITION = positionPlotBottom, FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Wheel Speed [RPM]', $
          NAME = 'X')
p2 = plot(timeJd, wheel2Speed, '2', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $
          NAME = 'Y')
p3 = plot(timeJd, wheel3Speed, '2', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = 'Z')
p1a = plot(timeJd, wheel1SpeedSmooth, '2', COLOR = 'firebrick', /OVERPLOT, $
           NAME = '1 smooth*') 
p2a = plot(timeJd, wheel2SpeedSmooth, '2', COLOR = 'lime', /OVERPLOT, $
           NAME = '2 smooth*')
p3a = plot(timeJd, wheel3SpeedSmooth, '2', COLOR = 'medium blue', /OVERPLOT, $
           NAME = '3 smooth*')
pdash = plot(p1.xrange, [1, 1], '--', /OVERPLOT)
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.35, 0.40], FONT_SIZE = fontSize - 2)
t1 = text(0.37, 0.16, 'solids = ' + JPMPrintNumber(smoothNumberOfPoints, /NO_DECIMALS) + ' pt boxcar smooth', FONT_SIZE = fontSize - 2)

IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  altitude = minxss_get_altitude(timeJd = timeJd)
  STOP
  p4 = plot(altitude, wheel1Speed, '2', SYMBOL = '*', COLOR = 'tomato', POSITION = [0.18, 0.59, 0.95, 0.93], /CURRENT, FONT_SIZE = fontSize, $
            TITLE = 'MinXSS-1 On-Orbit', $
            XTITLE = 'Altitude [km]', XRANGE = [430, 140])
  p5 = plot(altitude, wheel2Speed, '2', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT)
  p6 = plot(altitude, wheel3Speed, '2', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT)
  ;p4a = plot(altitude, wheel1SpeedSmooth, '2', COLOR = 'firebrick', /OVERPLOT)
  ;p5a = plot(altitude, wheel2SpeedSmooth, '2', COLOR = 'lime', /OVERPLOT)
  ;p6a = plot(altitude, wheel3SpeedSmooth, '2', COLOR = 'medium blue', /OVERPLOT)
  pdash = plot(p4.xrange, [1, 1], '--', /OVERPLOT)
  l1.position = [0.31, 0.62]
  t1.position = [0.32, 0.45]
  p1.title = ''
  p1.ytitle = ''
  t2 = text(0.04, 0.5, 'Wheel Speed [RPM]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)
ENDIF 

; Save plot to disk
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  p1.save, saveloc + 'Wheel Speed Vs Time and Altitude.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'Wheel Speed Vs Time.png'
ENDELSE

END