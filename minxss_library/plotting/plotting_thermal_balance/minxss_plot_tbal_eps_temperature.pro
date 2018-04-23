;+
; NAME:
;   minxss_plot_tbal_eps_temperature
;
; PURPOSE:
;   Create plot showing the eps temperature to get an idea of the power cycling. Also plots the incoming SA power. 
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
;   2016/03/25: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_eps_temperature, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

; Setup
epsEfficiency = 0.875
epsDissipationSmoothing = 20 ; Number of samples to smooth over

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'


coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
XRANGE = [0, 4]
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'
  
  ; Store variables
  epsTemperature1 = hk.EPS_TEMP1
  epsTemperature2 = hk.EPS_TEMP2
  saMinusYPower = hk.EPS_SA1_CUR / 1000. * hk.EPS_SA1_VOLT ; [W]
  saPlusXPower = hk.EPS_SA2_CUR / 1000. * hk.EPS_SA2_VOLT ; [W] but should be 0 because no power was connected to this port
  saPlusYPower = hk.EPS_SA3_CUR / 1000. * hk.EPS_SA3_VOLT ; [W]
  
  ; Combine power for total
  saTotalPower = saMinusYPower + saPlusYPower 
  
  ; Get statistics on power
  powerOnIndices = where(hk.EPS_SA1_VOLT GT 10)
  powerMin = min(saTotalPower[powerOnIndices])
  powerMax = max(saTotalPower[powerOnIndices])
  powerMean = mean(saTotalPower[powerOnIndices])
  
  ; Determine heat dissipated in EPS board
  epsHeatDissipated = saTotalPower * (1 - epsEfficiency)
  epsHeatDissipatedSmooth = smooth(epsHeatDissipated, epsDissipationSmoothing) ; Diminish small transients
  
  ; Create temperature plot
  p1 = plot(relativeTimeHours, epsTemperature1, 'r2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance EPS Temperature', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Sensor 1')
  p2 = plot(relativeTimeHours, epsTemperature2, 'b2', /OVERPLOT, $
            NAME = 'Sensor 2')
  l = legend(TARGET = [p1, p2], POSITION = [0.35, 0.85])
  
  ; Create power input plot
  p3 = plot(relativeTimeHours, saTotalPower, '2', $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Total SA Power Input to EPS (87.5% efficient)', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Power [W]', YRANGE = [0, 20])
  t1 = text(0.15, 0.8, 'Min   Power = ' + JPMPrintNumber(powerMin) + ' W')
  t2 = text(0.15, 0.77, 'Max  Power = ' + JPMPrintNumber(powerMax) + ' W')
  t3 = text(0.15, 0.74, 'Mean Power = ' + JPMPrintNumber(powerMean) + ' W')
  
  ; Create voltage and current plot
  w = window(DIMENSIONS = [800, 800])
  p4 = plot(relativeTimeHours, hk.EPS_SA1_VOLT, 'r2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
            TITLE = 'Thermal ' + coldOrHot + ' Balance SA Power Input to EPS', $
            XRANGE = xrange, $
            YRANGE = [0, 25], $
            NAME = '-Y Voltage')
  p5 = plot(relativeTimeHours, hk.EPS_SA3_VOLT, '2--', COLOR = 'dark red', /OVERPLOT, $
            NAME = '+Y Voltage')
  p6 = plot(relativeTimeHours, hk.EPS_SA1_CUR / 1000., 'b2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
            XRANGE = xrange, $
            YRANGE = [0, 2], $
            NAME = '-Y Current')
  p7 = plot(relativeTimeHours, hk.EPS_SA3_CUR / 1000., '2--', COLOR = 'sky blue', /OVERPLOT, $
            NAME = '+Y Current')
  l4 = legend(TARGET = [p4, p5, p6, p7], POSITION = [0.86, 0.85])
  a4 = axis('Y', LOCATION = 'left', TARGET = [p4], TITLE = 'Voltage [V]', COLOR = 'red')
  a4 = axis('Y', LOCATION = 'right', TARGET = [p6], TITLE = 'Current [A]', COLOR = 'blue')
  ax = axis('X', LOCATION = 'top', TARGET = [p4], SHOWTEXT = 0)
  ax = axis('X', LOCATION = 'bottom', TARGET = [p4], TITLE = 'Time Since Start [hours]')
  t1 = text(0.15, 0.8, 'Min   Power = ' + JPMPrintNumber(powerMin) + ' W')
  t2 = text(0.15, 0.77, 'Max  Power = ' + JPMPrintNumber(powerMax) + ' W')
  t3 = text(0.15, 0.74, 'Mean Power = ' + JPMPrintNumber(powerMean) + ' W')
  
  ; Plot EPS dissipated heat
  p8 = plot(relativeTimeHours, epsHeatDissipated, '2', $
            TITLE = 'EPS Heat Dissipation', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Power [W]', $
            NAME = 'Raw')
  p9 = plot(relativeTimeHours, epsHeatDissipatedSmooth, 'r2--', /OVERPLOT, $
            NAME = 'Smooth ' + JPMPrintNumber(epsDissipationSmoothing, /NO_DECIMALS) + ' Samples')
  l8 = legend(TARGET = [p8, p9], POSITION = [0.45, 0.9])
  
  ; Save plot
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance EPS Temperature.png'
  p3.save, saveloc + 'Thermal ' + coldOrHot + ' Balance SA Power.png'
  p4.save, saveloc + 'Thermal ' + coldOrHot + ' Balance SA Current and Voltage.png'
  p8.save, saveloc + 'Thermal ' + coldOrHot + ' Balance EPS Heat Dissipation.png'
  
  ; Output table of EPS heat dissipation as function of time
  close, 1 & openw, 1, saveloc + 'EpsHeatDissipation' + coldOrHot + 'Balance.txt', width = 200, /APPEND
  FOR i = 0, n_elements(epsHeatDissipated) - 1, 36 DO printf, 1, strtrim(relativeTimeHours[i] * 3600., 2), ',', strtrim(epsHeatDissipatedSmooth[i], 2)
  close, 1

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]

    ; Read the measurement data
    restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'

  ENDIF
ENDWHILE

END