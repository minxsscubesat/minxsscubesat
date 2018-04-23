;+
; NAME:
;   minxss_plot_adcs_detumble
;
; PURPOSE:
;   Plot a detumble maneuver performed at the end of MinXSS-1 mission life. 
;
; INPUTS:
;   None, but uses a prepared IDL saveset
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   A plot of the sun body x vector versus time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the prepared IDL saveset as input
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-05-08: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_detumble, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
fontSize = 16
  
; Load the data
restore, getenv('minxss_data') + '/fm1/minxss1_detumble/MinXSS-1 Detumble 2017-05-05 15:26:45.sav'

; Find maneuver start
safeIndices = where(hk.spacecraft_mode GT 1)
firstSafeIndex = safeIndices[0]
timeOfManeuverStart = hk[firstSafeIndex].time
hk = hk[where(hk.time GT timeOfManeuverStart)]
adcs4 = adcs4[where(adcs4.time GT timeOfManeuverStart)]

; Merge hk data with the adcs packet since we have those telemetry points in both
timeSpacecraft = [adcs4.time, hk.time]
sortedIndices = sort(timeSpacecraft)
timeSpacecraft = timeSpacecraft[sortedIndices] 
sunBodyX = [adcs4.SUNBODY_X, hk.XACT_MEASSUNBODYVECTORX]
sunBodyX = sunBodyX[sortedIndices]

; Determine how long the maneuver took
sunLockIndices = where(sunBodyX GT 0)
firstSunLockIndex = sunLockIndices[0]
timeOfSunLock = timeSpacecraft[firstSunLockIndex]
timeToAchieveSunLock = timeOfSunLock - timeSpacecraft[0]

; Make plot
p1 = plot(timeSpacecraft - timeSpacecraft[0], sunBodyX, SYMBOL = 'square', COLOR = 'tomato', SYM_SIZE = 2, FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTITLE = 'Time Since Maneuver Start [s]', $
          YTITLE = 'Sun-Body Unit Vector +X', YRANGE = [-2, 2])
t = text(0.3, 0.5, JPMPrintNumber(timeToAchieveSunLock, /NO_DECIMALS) + ' s to de-tumble and lock on sun', COLOR = 'tomato', FONT_SIZE = fontSize - 2)

; Save plot to disk
p1.save, saveloc + 'De-tumble Timing.png'

END