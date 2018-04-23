;+
; NAME:
;   minxss_plot_adcs_mag_model_vs_measurement
;
; PURPOSE:
;   Plot the modeled and measured magnetic fields
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
;   Plot of magnetic field vector strengths as measured vs modeled
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
PRO minxss_plot_adcs_mag_model_vs_measurement, saveloc = saveloc, $
                                               STACKPLOT_VS_ALTITUDE = STACKPLOT_VS_ALTITUDE

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Setup
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  positionPlotBottom = [0.22, 0.15, 0.97, 0.45]
ENDIF ELSE BEGIN
  positionPlotBottom = [0.22, 0.1, 0.97, 0.95]
ENDELSE
fontSize = 16
  
; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Loop through all the adcs1 packets and find where (if any) adcs4 packets are within 2 minutes
FOR i = 0, n_elements(adcs1) - 1 DO BEGIN
  time1Jd = adcs1[i].time_jd
  time4ClosestIndex = closest(time1Jd, adcs4.time_jd, /DECIDE) 
  deltaTMinutes = abs(time1Jd - adcs4[time4ClosestIndex].time_jd) * 24. * 60. 
  IF deltaTMinutes LT 2. THEN BEGIN
    
    ; Store refs valid flag
    refsValid = (refsValid NE !NULL) ? [refsValid, adcs1[i].refs_valid] : adcs1[i].refs_valid
    
    ; Store model vector magnitudes 
    magModel1 = (magModel1 NE !NULL) ? [magModel1, adcs1[i].mag_model_vector_body1] : adcs1[i].mag_model_vector_body1
    magModel2 = (magModel2 NE !NULL) ? [magModel2, adcs1[i].mag_model_vector_body2] : adcs1[i].mag_model_vector_body2
    magModel3 = (magModel3 NE !NULL) ? [magModel3, adcs1[i].mag_model_vector_body3] : adcs1[i].mag_model_vector_body3
    
    ; Store measured vector magnitudes 
    magMeasuredl1 = (magMeasuredl1 NE !NULL) ? [magMeasuredl1, adcs4[time4ClosestIndex].mag_bodyx] : adcs4[time4ClosestIndex].mag_bodyx
    magMeasuredl2 = (magMeasuredl2 NE !NULL) ? [magMeasuredl2, adcs4[time4ClosestIndex].mag_bodyy] : adcs4[time4ClosestIndex].mag_bodyy
    magMeasuredl3 = (magMeasuredl3 NE !NULL) ? [magMeasuredl3, adcs4[time4ClosestIndex].mag_bodyz] : adcs4[time4ClosestIndex].mag_bodyz
    timeJd = (timeJd NE !NULL) ? [timeJd, time1Jd] : time1Jd
  ENDIF
ENDFOR

; Only plot data when a valid ephemeris was available
goodEphemerisIndices = where(refsValid EQ 1)
timeJd = timeJd[goodEphemerisIndices]
magMeasuredl1 = magMeasuredl1[goodEphemerisIndices]
magModel1 = magModel1[goodEphemerisIndices]
magMeasuredl2 = magMeasuredl2[goodEphemerisIndices]
magModel2 = magModel2[goodEphemerisIndices]
magMeasuredl3 = magMeasuredl3[goodEphemerisIndices]
magModel3 = magModel3[goodEphemerisIndices]

; Create plots versus time
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
;w = window(DIMENSIONS = [1600, 900])
;p1a = plot(timeJd, magMeasuredl1, '2', COLOR = 'tomato', LAYOUT = [1, 3, 1], /CURRENT, $
;          TITLE = '1', $
;          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
;          YTITLE = 'B Magnitude [T]', $
;          NAME = 'Measured')
;p1b = plot(timeJd, magModel1, '2--', COLOR = 'firebrick', /OVERPLOT, $
;          NAME = 'Model')
;l1 = legend(TARGET = [p1a, p1b], POSITION = [0.19, 0.83])
;p2a = plot(timeJd, magMeasuredl2, '2', COLOR = 'lime green', LAYOUT = [1, 3, 2], /CURRENT, $
;           TITLE = '2', $
;           XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
;           YTITLE = 'B Magnitude [T]', $
;           NAME = 'Measured')
;p2b = plot(timeJd, magModel2, '2--', COLOR = 'green', /OVERPLOT, $
;           NAME = 'Model')
;l2 = legend(TARGET = [p2a, p2b], POSITION = [0.19, 0.50])
;p3a = plot(timeJd, magMeasuredl3, '2', COLOR = 'dodger blue', LAYOUT = [1, 3, 3], /CURRENT, $
;           TITLE = '3', $
;           XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
;           YTITLE = 'B Magnitude [T]', $
;           NAME = 'Measured')
;p3b = plot(timeJd, magModel3, '2--', COLOR = 'medium blue', /OVERPLOT, $
;           NAME = 'Model')
;l3 = legend(TARGET = [p3a, p3b], POSITION = [0.19, 0.16])

; Save plot to disk
;p1a.save, saveloc + 'Measured and Modeled Mag Field Vs Time.png'

; Create plot of measured vs model
p1 = plot(magModel1, magMeasuredl1, SYMBOL = '*', LINESTYLE = 'none', COLOR = 'tomato', FONT_SIZE = fontSize, MARGIN = [0.22, 0.1, 0.1, 0.1], $ 
          TITLE = 'MinXSS-1 On-Orbit', $
          XTITLE = 'Model B Magnitude [T]', XMAJOR = 5, $ 
          YTITLE = 'Measured B Magnitude [T]', $
          NAME = 'X')
p2 = plot(magModel2, magMeasuredl2, SYMBOL = '*', LINESTYLE = 'none', COLOR = 'lime green', /OVERPLOT, $
          NAME = 'Y')
p3 = plot(magModel3, magMeasuredl3, SYMBOL = '*', LINESTYLE = 'none', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = 'Z') 
axisRange = JPMrange(-7e-5, 7e-5, NPTS = 2)
p4 = plot(axisRange, axisRange, '--', /OVERPLOT)
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.87, 0.31], FONT_SIZE = fontSize - 2)
p1.yrange = axisRange
p1.xrange = axisRange

; Save plot to disk
p1.save, saveloc + 'Measured Vs Modeled Mag Field.png'

; Error statistics
meanError1 = mean(magModel1 - magMeasuredl1)
standardDeviationError1 = stddev(magModel1 - magMeasuredl1)
meanError2 = mean(magModel2 - magMeasuredl2)
standardDeviationError2 = stddev(magModel2 - magMeasuredl2)
meanError3 = mean(magModel3 - magMeasuredl3)
standardDeviationError3 = stddev(magModel3 - magMeasuredl3)

; Create plot of error over time
p1 = plot(timeJd, magModel1 - magMeasuredl1, '2', COLOR = 'tomato',  POSITION = positionPlotBottom, FONT_SIZE = fontSize, $ 
          TITLE = 'MinXSS-1 On-Orbit: B Model - Measured', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'B Magnitude Error [T]', $
          NAME = 'X')
p2 = plot(timeJd, magModel2 - magMeasuredl2, '2', COLOR = 'lime green', /OVERPLOT, $
          NAME = 'Y')
p3 = plot(timeJd, magModel3 - magMeasuredl3, '2', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = 'Z')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.88, 0.84])
tm = text(0.25, 0.21, '$\mu$ = ', FONT_SIZE = fontSize - 2)
ts = text(0.25, 0.17, '$\sigma$ = ', FONT_SIZE = fontSize - 2)
t1a = text(0.15, 0.22, JPMPrintNumber(meanError1, /SCIENTIFIC_NOTATION), COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t1b = text(0.15, 0.18, JPMPrintNumber(standardDeviationError1, /SCIENTIFIC_NOTATION), COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t2a = text(0.35, 0.22, ', ' + JPMPrintNumber(meanError2, /SCIENTIFIC_NOTATION), COLOR = 'lime green', FONT_SIZE = fontSize - 2)
t2b = text(0.35, 0.18, ', ' + JPMPrintNumber(standardDeviationError3, /SCIENTIFIC_NOTATION), COLOR = 'lime green', FONT_SIZE = fontSize - 2)
t3a = text(0.55, 0.22, ', ' + JPMPrintNumber(meanError3, /SCIENTIFIC_NOTATION), COLOR = 'dodger blue', FONT_SIZE = fontSize - 2)
t3b = text(0.55, 0.18, ', ' + JPMPrintNumber(standardDeviationError3, /SCIENTIFIC_NOTATION), COLOR = 'dodger blue', FONT_SIZE = fontSize - 2)

IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  altitude = minxss_get_altitude(timeJd = timeJd)
  p4 = plot(altitude, magModel1 - magMeasuredl1, '2', COLOR = 'tomato', SYMBOL = '*', LINESTYLE = 'none', POSITION = [0.22, 0.59, 0.97, 0.93], /CURRENT, FONT_SIZE = fontSize, $
            TITLE = 'MinXSS-1 On-Orbit: B Model - Measured', $
            XTITLE = 'Altitude [km]', XRANGE = [430, 140])
  p5 = plot(altitude, magModel2 - magMeasuredl2, '2', SYMBOL = '*', LINESTYLE = 'none', COLOR = 'lime green', /OVERPLOT)
  p6 = plot(altitude, magModel3 - magMeasuredl3, '2', SYMBOL = '*', LINESTYLE = 'none', COLOR = 'dodger blue', /OVERPLOT)
  l1.position = [0.34, 0.59]
  t1a.position = [0.31, 0.21]
  t1b.position = [0.31, 0.17]
  t2a.position = [0.50, 0.21]
  t2b.position = [0.50, 0.17]
  t3a.position = [0.71, 0.21]
  t3b.position = [0.71, 0.17]
  p1.title = ''
  p1.ytitle = ''
  t4 = text(0.04, 0.5, 'B Magnitude Error [T]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize)
ENDIF

; Save plot to disk
IF keyword_set(STACKPLOT_VS_ALTITUDE) THEN BEGIN
  p1.save, saveloc + 'Measured - Modeled Mag Field Error Vs Time And Altitude.png'
ENDIF ELSE BEGIN
  p1.save, saveloc + 'Measured - Modeled Mag Field Error Vs Time.png'
ENDELSE

END