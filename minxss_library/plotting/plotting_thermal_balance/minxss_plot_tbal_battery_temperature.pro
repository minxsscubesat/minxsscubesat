;+
; NAME:
;   minxss_plot_tbal_battery_temperature
;
; PURPOSE:
;   Create plot showing the battery temperature to get an idea of how the heaters are working
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPath [string]: The path to the data. Default is '/Users/jmason86/Drive/CubeSat/MinXSS Server/8000 Ground Software : Mission Ops/8020 Solar Panel Simulator Development/SASPowerRecord/'
;                      since James is the only one likely to use this code.
;   plotPath [string]: The path you want the plots saved to. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/'
;                      since James is the only one likely to use this code.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot as described in purpose
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;
; EXAMPLE:
;   None
;
; MODIFICATION HISTORY:
;   2016/03/24: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_battery_temperature, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'

coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  ; Store variables
  batteryTemperature = hk.EPS_BATT_TEMP1
  
  ; Ideally would also look at battery heater enable but at this time, the data have not been processed through the improved minxss_read_packets that extracts
  ; the enable values from hk.cdh_enables

  ; Create plot
  p1 = plot(relativeTimeHours, batteryTemperature, '2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Battery Temperature', $
            XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
            YTITLE = 'Temperature [ºC]', YRANGE = [0, 20])
  p2 = plot(relativeTimeHours, hk.ENABLE_BATT_HEATER, 'g4', /OVERPLOT)
  
  p = plot(p1.xrange, [5, 5], 'r--', /OVERPLOT)
  ;p = plot(p1.xrange, [10, 10], 'b--', /OVERPLOT)
  t1 = text(4, 5, 'Heaters On', /DATA, COLOR = 'red', ALIGNMENT = 1)
  ;t2 = text(4, 10, 'Heaters Off', /DATA, COLOR = 'blue', ALIGNMENT = 1)
  STOP
  ; Save plot
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Battery Temperature.png'

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'
  ENDIF
ENDWHILE

END