;+
; NAME:
;   minxss_plot_adcs_sun_sensors_vs_time
;
; PURPOSE:
;   Plot the raw sun sensor data versus time to see if there is any degradation
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot of each sun sensor data versus time
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
;   2017-01-09: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_sun_sensors_vs_time, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
smoothNumberOfPoints = 1000
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Grab the 1 AU distance as a function of time
sunVector = sunvec(jd = adcs4.time_jd, r = earth_sun_distance, alpha = right_ascension, delta = declination)

; Correct the raw data for 1 AU
adcs4.sunsensor_data1 *= earth_sun_distance^2
adcs4.sunsensor_data2 *= earth_sun_distance^2
adcs4.sunsensor_data3 *= earth_sun_distance^2
adcs4.sunsensor_data4 *= earth_sun_distance^2

; Smooth the data
sensor1GoodIndices = where(adcs4.sunsensor_data1 GT 1400)
sensor2GoodIndices = where(adcs4.sunsensor_data2 GT 1400)
sensor3GoodIndices = where(adcs4.sunsensor_data3 GT 1400)
sensor4GoodIndices = where(adcs4.sunsensor_data4 GT 1400)
sensor1Smooth = smooth(adcs4[sensor1GoodIndices].sunsensor_data1, smoothNumberOfPoints)
sensor2Smooth = smooth(adcs4[sensor2GoodIndices].sunsensor_data2, smoothNumberOfPoints)
sensor3Smooth = smooth(adcs4[sensor3GoodIndices].sunsensor_data3, smoothNumberOfPoints)
sensor4Smooth = smooth(adcs4[sensor4GoodIndices].sunsensor_data4, smoothNumberOfPoints)

; Linear fits to the data
sensor1Fit = linfit(adcs4[sensor1GoodIndices].time_jd, adcs4[sensor1GoodIndices].sunsensor_data1)
sensor2Fit = linfit(adcs4[sensor2GoodIndices].time_jd, adcs4[sensor2GoodIndices].sunsensor_data2)
sensor3Fit = linfit(adcs4[sensor3GoodIndices].time_jd, adcs4[sensor3GoodIndices].sunsensor_data3)
sensor4Fit = linfit(adcs4[sensor4GoodIndices].time_jd, adcs4[sensor4GoodIndices].sunsensor_data4)

; Create plots versus time
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])

p1 = plot(adcs4.time_jd, adcs4.sunsensor_data1, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'tomato', FONT_SIZE = fontSize, $
           TITLE = 'MinXSS-1 On-Orbit', $
           XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Minute', 'Hour'], XTICKINTERVAL = 10, $
           YTITLE = 'Raw Sun Sensor Output [DN]', YRANGE = [1100, 1800], $
           NAME = '+Z')
p2 = plot(adcs4.time_jd, adcs4.sunsensor_data2, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $
           NAME = '+Y')
p3 = plot(adcs4.time_jd, adcs4.sunsensor_data3, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT, $
            NAME = '-Z')
p4 = plot(adcs4.time_jd, adcs4.sunsensor_data4, LINESTYLE = 'none', SYMBOL = '*',  COLOR = 'gold', /OVERPLOT, $
           NAME = '-Y')
p1a = plot(adcs4[sensor1GoodIndices].time_jd, sensor1Smooth, '2', COLOR = 'firebrick', /OVERPLOT, $
           NAME = '1 smooth*')
p2a = plot(adcs4[sensor2GoodIndices].time_jd, sensor2Smooth, '2', COLOR = 'lime', /OVERPLOT, $
           NAME = '2 smooth*')
p3a = plot(adcs4[sensor3GoodIndices].time_jd, sensor3Smooth, '2', COLOR = 'medium blue', /OVERPLOT, $
           NAME = '3 smooth*') 
p4a = plot(adcs4[sensor4GoodIndices].time_jd, sensor4Smooth, '2', COLOR = 'goldenrod', /OVERPLOT, $
           NAME = '4 smooth*')         
l1 = legend(TARGET = [p1, p2, p3, p4], POSITION = [0.34, 0.37], FONT_SIZE = fontSize - 2)
t0 = text(0.82, 0.16, 'solids = ' + JPMPrintNumber(smoothNumberOfPoints, /NO_DECIMALS) + ' pt boxcar smooth', ALIGNMENT = 1, FONT_SIZE = fontSize - 2)
t1 = text(0.52, 0.38, '+Z slope = ' + JPMPrintNumber(sensor1Fit[1] * 365.15) + ' DN/year', COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t2 = text(0.52, 0.32, '+Y slope = ' + JPMPrintNumber(sensor2Fit[1] * 365.15) + ' DN/year', COLOR = 'lime green', FONT_SIZE = fontSize - 2)
t3 = text(0.52, 0.26, '-Z slope = ' + JPMPrintNumber(sensor3Fit[1] * 365.15) + ' DN/year', COLOR = 'dodger blue', FONT_SIZE = fontSize - 2)
t4 = text(0.52, 0.20, '-Y slope = ' + JPMPrintNumber(sensor4Fit[1] * 365.15) + ' DN/year', COLOR = 'gold', FONT_SIZE = fontSize - 2)

; Save plot to disk
p1.save, saveloc + 'Sun Sensors Vs Time.png'

END