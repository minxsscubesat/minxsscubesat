;+
; NAME:
;   minxss_plot_tbal_battery_current
;
; PURPOSE:
;   Create plot showing the battery charge and discharge current during thermal balance. 
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
PRO minxss_plot_tbal_battery_current, dataPath = dataPath, plotPath = plotPath

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
  batteryChargeCurrent = hk.EPS_BATT_CHARGE
  batteryDischargeCurrent = hk.EPS_BATT_DISCHARGE
  
  ; Compute power statistics
  chargeNonzeroIndices = where(batteryChargeCurrent GT 150)
  dischargeNonzeroIndices = where(batteryDischargeCurrent GT 150)
  chargeMin = round(min(batteryChargeCurrent[chargeNonzeroIndices]))
  chargeMax = round(max(batteryChargeCurrent[chargeNonzeroIndices]))
  chargeMean = round(mean(batteryChargeCurrent[chargeNonzeroIndices]))
  dischargeMin = round(min(batteryDischargeCurrent[dischargeNonzeroIndices]))
  dischargeMax = round(max(batteryDischargeCurrent))
  dischargeMean = round(mean(batteryDischargeCurrent[dischargeNonzeroIndices]))
  
  ; Create plot
  p1 = plot(relativeTimeHours, batteryChargeCurrent, '2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Battery Current', $
            XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
            YTITLE = 'Current [mA]', YRANGE = [0, 1500], $
            NAME = 'Charge')
  p2 = plot(relativeTimeHours, batteryDischargeCurrent, 'r2', /OVERPLOT, $
            NAME = 'Discharge')
  l = legend(TARGET = [p1, p2], POSITION = [0.5, 0.84], HORIZONTAL_ALIGNMENT = 0.5)
  t1min = text(0.15, 0.80, 'Min    = ' + JPMPrintNumber(chargeMin, /NO_DECIMALS) + ' mA')
  t1max = text(0.15, 0.77, 'Max   = ' + JPMPrintNumber(chargeMax, /NO_DECIMALS) + ' mA')
  t1mean = text(0.15, 0.74, 'Mean = ' + JPMPrintNumber(chargeMean, /NO_DECIMALS) + ' mA')
  t2min = text(0.7, 0.80, 'Min    = ' + JPMPrintNumber(dischargeMin, /NO_DECIMALS) + ' mA', COLOR = 'red')
  t2max = text(0.7, 0.77, 'Max   = ' + JPMPrintNumber(dischargeMax, /NO_DECIMALS) + ' mA', COLOR = 'red')
  t2mean = text(0.7, 0.74, 'Mean = ' + JPMPrintNumber(dischargeMean, /NO_DECIMALS) + ' mA', COLOR = 'red')

  ; Save plot
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Battery Current.png'

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'
  ENDIF 
ENDWHILE

STOP


END