;+
; NAME:
;   minxss_plot_adcs_imu_bias_vs_temperature
;
; PURPOSE:
;   Plot the IMU bias versus its temperature to see if there is any trend
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
;   Plot of IMU bias versus temperature
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
PRO minxss_plot_adcs_imu_bias_vs_temperature, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
  
; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Find the nearest reaction wheel 2 temperature sample in time to the IMU bias samples
; Using that temperature as representative for all of XACT and also have it in hk, which is sampled more often and downlinked more routinely as well
adcs4Count = 0
hkCount = 0
FOR i = 0, n_elements(adcs2) - 1 DO BEGIN
  
  ; Find the closest point in time to adcs2 for both adcs4 and hk
  closestIndexAdcs4 = closest(adcs2[i].time_jd, adcs4.time_jd, /DECIDE)
  closestIndexHk = closest(adcs2[i].time_jd, hk.time_jd, /DECIDE)
  
  ; Determine whether adcs4 or hk is closer 
  IF (abs(adcs2[i].time_jd - adcs4[closestIndexAdcs4].time_jd)) LT (abs(adcs2[i].time_jd - hk[closestIndexHk].time_jd)) THEN BEGIN
    closestTemperature = adcs4[closestIndexAdcs4].rw2_temp
    adcs4Count++
  ENDIF ELSE BEGIN
    closestTemperature = hk[closestIndexHk].xact_wheel2temp
    hkCount++
  ENDELSE
  smallestTimeDifferenceDays = (abs(adcs2[i].time_jd - adcs4[closestIndexAdcs4].time_jd)) < (abs(adcs2[i].time_jd - hk[closestIndexHk].time_jd))
  
  ; Store samples for plotting only if time difference < 5 minutes
  IF smallestTimeDifferenceDays * 24. * 60. LT 5. THEN BEGIN
    bias1 = (bias1 NE !NULL) ? [bias1, adcs2[i].estimated_gyro_bias1] : adcs2[i].estimated_gyro_bias1
    bias2 = (bias2 NE !NULL) ? [bias2, adcs2[i].estimated_gyro_bias2] : adcs2[i].estimated_gyro_bias2
    bias3 = (bias3 NE !NULL) ? [bias3, adcs2[i].estimated_gyro_bias3] : adcs2[i].estimated_gyro_bias3
    temperatureWheel2 = (temperatureWheel2 NE !NULL) ? [temperatureWheel2, closestTemperature] : closestTemperature
  ENDIF
  
ENDFOR ; Loop through adcs2 packet

; Create plot
p1 = plot(temperatureWheel2, bias1, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'tomato', $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTITLE = 'Reaction Wheel 2 Temperature [ºC]', $
          YTITLE = 'Gyro Bias [rad s$^{-1}$]', $ 
          NAME = '1')
p2 = plot(temperatureWheel2, bias2, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $
          NAME = '2')
p3 = plot(temperatureWheel2, bias3, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = '3')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.88, 0.84])

; Save plot to disk
p1.save, saveloc + 'IMU Bias Vs Temperature.png'

END