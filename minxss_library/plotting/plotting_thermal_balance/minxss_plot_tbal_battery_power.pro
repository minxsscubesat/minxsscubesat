;+
; NAME:
;   minxss_plot_tbal_battery_power
;
; PURPOSE:
;   Create plot showing the battery charge and discharge current during thermal balance. Also compute power based on these times battery voltage. 
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
;   2016/04/01: James Paul Mason: Added calculated power plot. 
;-
PRO minxss_plot_tbal_battery_power, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

; Setup
dissipationSmoothing = 20.

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'

coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
xrange = [0, 4]
WHILE coldOrHot EQ 'Cold' DO BEGIN  
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'
  
  ; Store variables
  batteryChargeCurrent = hk.EPS_BATT_CHARGE / 1e3
  batteryDischargeCurrent = hk.EPS_BATT_DISCHARGE / 1e3
  batteryVoltage = hk.EPS_FG_VOLT
  
  ; Compute power
  chargePower = batteryVoltage * batteryChargeCurrent     
  dischargePower = batteryVoltage * batteryDischargeCurrent
  mergedPower = fltarr(n_elements(chargePower))
  FOR i = 0, n_elements(mergedPower) - 1 DO mergedPower[i] = chargePower[i] > dischargePower[i] > 0.
  
  ; Compute power dissipation inside battery
  heatDissipation = fltarr(n_elements(chargePower))
  FOR i = 0, n_elements(heatDissipation) - 1 DO heatDissipation[i] = batteryChargeCurrent[i] > batteryDischargeCurrent[0] > 0. 
  heatDissipation *= heatDissipation * 0.3 ; battery internal resistance is 0.3 ohms and P = I^2 * R
  heatDissipationSmooth = smooth(heatDissipation, dissipationSmoothing) ; Diminish small transients

  
  ; Compute power statistics
  chargeNonzeroIndices = where(batteryChargeCurrent GT 0.150)
  dischargeNonzeroIndices = where(batteryDischargeCurrent GT 0.150)
  chargeMin = min(batteryChargeCurrent[chargeNonzeroIndices])
  chargeMax = max(batteryChargeCurrent[chargeNonzeroIndices])
  chargeMean = mean(batteryChargeCurrent[chargeNonzeroIndices])
  dischargeMin = min(batteryDischargeCurrent[dischargeNonzeroIndices])
  dischargeMax = max(batteryDischargeCurrent)
  dischargeMean = mean(batteryDischargeCurrent[dischargeNonzeroIndices])
  
  chargePowerMin = min(chargePower[chargeNonzeroIndices])
  chargePowerMax = max(chargePower[chargeNonzeroIndices])
  chargePowerMean = mean(chargePower[chargeNonzeroIndices])
  dischargePowerMin = min(dischargePower[dischargeNonzeroIndices])
  dischargePowerMax = max(dischargePower)
  dischargePowerMean = mean(dischargePower[dischargeNonzeroIndices])
  mergedPowerMin = min(mergedPower)
  mergedPowerMax = max(mergedPower)
  mergedPowerMean = mean(mergedPower)
  
  ; Create voltage/current plot
  p1 = plot(relativeTimeHours, batteryChargeCurrent, 'b2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Battery Current', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Current [A]', YRANGE = [0, 1.5], $
            NAME = 'Charge')
  p2 = plot(relativeTimeHours, batteryDischargeCurrent, 'r2', /OVERPLOT, $
            NAME = 'Discharge')
  l = legend(TARGET = [p1, p2], POSITION = [0.5, 0.84], HORIZONTAL_ALIGNMENT = 0.5)
  t1min = text(0.15, 0.80, 'Min    = ' + JPMPrintNumber(chargeMin) + ' A', COLOR = 'blue')
  t1max = text(0.15, 0.77, 'Max   = ' + JPMPrintNumber(chargeMax) + ' A', COLOR = 'blue')
  t1mean = text(0.15, 0.74, 'Mean = ' + JPMPrintNumber(chargeMean) + ' A', COLOR = 'blue')
  t2min = text(0.7, 0.80, 'Min    = ' + JPMPrintNumber(dischargeMin) + ' A', COLOR = 'red')
  t2max = text(0.7, 0.77, 'Max   = ' + JPMPrintNumber(dischargeMax) + ' A', COLOR = 'red')
  t2mean = text(0.7, 0.74, 'Mean = ' + JPMPrintNumber(dischargeMean) + ' A', COLOR = 'red')

  ; Create power plot
  p3 = plot(relativeTimeHours, chargePower, 'b2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Battery Power', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Power [W]', YRANGE = [0, 12], $
            NAME = 'Charge')
  p4 = plot(relativeTimeHours, dischargePower, 'r2', /OVERPLOT, $
            NAME = 'Discharge')
  p5 = plot(relativeTimeHours, mergedPower, '2', /OVERPLOT, $
            NAME = 'Merged Power')
  l = legend(TARGET = [p3, p4, p5], POSITION = [0.5, 0.84], HORIZONTAL_ALIGNMENT = 0.5)
  t3min = text(0.15, 0.80, 'Min    = ' + JPMPrintNumber(chargePowerMin) + ' W', COLOR = 'blue')
  t3max = text(0.15, 0.77, 'Max   = ' + JPMPrintNumber(chargePowerMax) + ' W', COLOR = 'blue')
  t3mean = text(0.15, 0.74, 'Mean = ' + JPMPrintNumber(chargePowerMean) + ' W', COLOR = 'blue')
  t4min = text(0.7, 0.80, 'Min    = ' + JPMPrintNumber(dischargePowerMin) + ' W', COLOR = 'red')
  t4max = text(0.7, 0.77, 'Max   = ' + JPMPrintNumber(dischargePowerMax) + ' W', COLOR = 'red')
  t4mean = text(0.7, 0.74, 'Mean = ' + JPMPrintNumber(dischargePowerMean) + ' W', COLOR = 'red')
  t5min = text(0.5, 0.65, ' Min    = ' + JPMPrintNumber(mergedPowerMin) + ' W', ALIGNMENT = 0.5)
  t5max = text(0.5, 0.62, '  Max   = ' + JPMPrintNumber(mergedPowerMax) + ' W', ALIGNMENT = 0.5)
  t5mean = text(0.5, 0.59, 'Mean = ' + JPMPrintNumber(mergedPowerMean) + ' W', ALIGNMENT = 0.5)
  
  ; Save plots
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Battery Current.png'
  p3.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Battery Power.png'

  ; Output table of battery heat dissipation as function of time
  close, 1 & openw, 1, saveloc + 'BatteryHeatDissipation' + coldOrHot + 'Balance.txt', width = 200, /APPEND
  FOR i = 0, n_elements(heatDissipationSmooth) - 1, 36 DO printf, 1, strtrim(relativeTimeHours[i] * 3600., 2), ',', strtrim(heatDissipationSmooth[i], 2)
  close, 1

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'
  ENDIF 
ENDWHILE

END