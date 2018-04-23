;+
; NAME:
;   minxss_plot_adcs_drag_vs_temperature
;
; PURPOSE:
;   Plot the estimated drag versus temperature to see if there is any trend
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
;   Plot of estimated drag versus temperature
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
PRO minxss_plot_adcs_drag_vs_temperature, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
  
; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Merge hk data with the adcs packet since we have those telemetry points for wheel 2 in both
timeJd = [adcs2.time_jd, hk.time_jd]
sortedIndices = sort(timeJd)
timeJd = timeJd[sortedIndices]
wheel1EstDrag = [adcs2.wheel_est_drag1, hk.xact_wheel1estdrag]
wheel1EstDrag = wheel1EstDrag[sortedIndices]
wheel2EstDrag = [adcs2.wheel_est_drag2, hk.xact_wheel2estdrag]
wheel2EstDrag = wheel2EstDrag[sortedIndices]
wheel3EstDrag = [adcs2.wheel_est_drag3, hk.xact_wheel3estdrag]
wheel3EstDrag = wheel3EstDrag[sortedIndices]

; Find the nearest reaction wheel temperature sample in time to the drag samples
ticObject = tic()
FOR i = 0, n_elements(timeJd) - 1 DO BEGIN

  ; Find the closest point in time to the drag samples for both adcs4 and hk
  closestIndexAdcs4 = closest(timeJd[i], adcs4.time_jd, /DECIDE)
  closestIndexHk = closest(timeJd[i], hk.time_jd, /DECIDE)
  
  ; Determine whether adcs4 or hk is closer
  IF (abs(timeJd[i] - adcs4[closestIndexAdcs4].time_jd)) LT (abs(timeJd[i] - hk[closestIndexHk].time_jd)) THEN BEGIN
    closestTemperature1 = adcs4[closestIndexAdcs4].rw1_temp
    closestTemperature2 = adcs4[closestIndexAdcs4].rw2_temp
    closestTemperature3 = adcs4[closestIndexAdcs4].rw3_temp
  ENDIF ELSE BEGIN
    closestTemperature2 = hk[closestIndexHk].xact_wheel2temp
  ENDELSE
  smallestTimeDifferenceDays = (abs(timeJd[i] - adcs4[closestIndexAdcs4].time_jd)) < (abs(timeJd[i] - hk[closestIndexHk].time_jd))
  
  ; If it's an hk packet then only store for wheel 2
  IF smallestTimeDifferenceDays EQ 0 THEN BEGIN
    temperature2 = (temperature2 NE !NULL) ? [temperature2, closestTemperature2] : closestTemperature2
    drag2 = (drag2 NE !NULL) ? [drag2, wheel2EstDrag[i]] : wheel2EstDrag[i]
    timeJd2 = (timeJd2 NE !NULL) ? [timeJd2, timeJd[i]] : timeJd[i]     
  ENDIF ELSE $ 

  ; Store samples for plotting only if time difference < 5 minutes
  IF smallestTimeDifferenceDays * 24. * 60. LT 5. THEN BEGIN
    temperature1 = (temperature1 NE !NULL) ? [temperature1, closestTemperature1] : closestTemperature1
    temperature2 = (temperature2 NE !NULL) ? [temperature2, closestTemperature2] : closestTemperature2
    temperature3 = (temperature3 NE !NULL) ? [temperature3, closestTemperature3] : closestTemperature3
    drag1 = (drag1 NE !NULL) ? [drag1, wheel1EstDrag[i]] : wheel1EstDrag[i]
    drag2 = (drag2 NE !NULL) ? [drag2, wheel2EstDrag[i]] : wheel2EstDrag[i]
    drag3 = (drag3 NE !NULL) ? [drag3, wheel3EstDrag[i]] : wheel3EstDrag[i]
    timeJd1and3 = (timeJd1and3 NE !NULL) ? [timeJd1and3, timeJd[i]] : timeJd[i]
    timeJd2 = (timeJd2 NE !NULL) ? [timeJd2, timeJd[i]] : timeJd[i]
  ENDIF
  
  IF i mod 100 EQ 0 THEN $
  progressBar = JPMProgressBar(float(i) / n_elements(timeJd) * 100., progressBar = progressBar, $
                               ticObject = ticObject, runTimeText = runTimeText, etaText = etaText)
ENDFOR ; Loop through drag samples

; Create plot
p1 = plot(temperature1, drag1, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'tomato', $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTITLE = 'Reaction Wheel Temperature [ºC]', $
          YTITLE = 'Estimated Drag [rad s$^{-2}$]', $
          NAME = '1')
p2 = plot(temperature2, drag2, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $
          NAME = '2')
p3 = plot(temperature3, drag3, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = '3')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.88, 0.84])

; Save plot to disk
p1.save, saveloc + 'Drag Vs Temperature.png'

END