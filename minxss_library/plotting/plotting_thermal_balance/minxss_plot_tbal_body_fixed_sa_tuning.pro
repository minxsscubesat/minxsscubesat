;+
; NAME:
;   minxss_plot_tbal_body_fixed_sa_tuning
;
; PURPOSE:
;   Dissertation plot. 
;   Create plot showing the model vs measurement for the under and on SA. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPathMeasurements [string]: The path to the measurement data. Default is '/Users/jmason86/Drive/CubeSat/MinXSS Server/8000 Ground Software : Mission Ops/8020 Solar Panel Simulator Development/SASPowerRecord/'
;                                  since James is the only one likely to use this code.
;   dataPathModel [string]:        The path to the model data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/'
;                                  since James is the only one likely to use this code.
;   plotPath [string]:             The path you want the plots saved to. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/'
;                                  since James is the only one likely to use this code.
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
;   2016-04-04: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_body_fixed_sa_tuning, dataPathMeasurement = dataPathMeasurement, dataPathModel = dataPathModel, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPathMeasurement) THEN datalocMeasurement = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)
savelocDissertation = '/Users/jmason86/Dropbox/Research/Woods_LASP/Papers/20160501 Dissertation/PhD_Dissertation/LaTeX/Images/'

; Update the model files -- convert the TD output txt to IDL saveset
minxss_plot_tbal_convert_model_txt_to_sav

; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
xrange = [0, 4]
yrange = [-10, 10]
saveloc = saveloc + 'Steady-State Cold Balance Model Vs Measurement/'
meanHotMeasuredIndices = [0:n_elements(tcRelativeTimeHours) - 1]
meanHotModelIndices = [0:n_elements(timeModelHours) - 1]
w = window(DIMENSIONS = [1600, 800])
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  ; Plot
  meanTcOnSa = mean(tcPlusXOnSa[meanHotMeasuredIndices])
  meanTcOnSaModel = mean(tcPlusXOnSaModel[meanHotMeasuredIndices])
  meanTcUnderSa = mean(tcPlusXUnderSa[meanHotMeasuredIndices])
  meanTcUnderSaModel = mean(tcPlusXUnderSaModel[meanHotMeasuredIndices])
  
  p1 = plot(tcRelativeTimeHours, tcPlusXOnSa, COLOR = 'orchid', '2', /CURRENT, LAYOUT = [2, 1, coldDone + 1], MARGIN = 0.15, FONT_SIZE = 20, $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Conduction Through +X SA', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', YRANGE = [-10, 35], $
            NAME = 'On SA Measurement')
  p2 = plot(timeModelHours, tcPlusXOnSaModel, COLOR = 'plum', '2--', /OVERPLOT, $
            NAME = 'On SA Model')
  p3 = plot(tcRelativeTimeHours, tcPlusXUnderSa, COLOR = 'crimson', '2', /OVERPLOT, $
            NAME = 'Under SA Measurement')
  p4 = plot(timeModelHours, tcPlusXUnderSaModel, COLOR = 'tomato', '2--', /OVERPLOT, $
            NAME = 'Under SA Model') 
  t1 = text(0.25, meanTcOnSa + 0.5, 'Mean = ' + JPMPrintNumber(meanTcOnSa) + ' ºC', /DATA, COLOR = 'orchid', TARGET = p1, FONT_SIZE = 16)
  t2 = text(0.25, meanTcOnSaModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcOnSaModel) + ' ºC', /DATA, COLOR = 'plum', TARGET = p1, FONT_SIZE = 16)
  t3 = text(0.25, meanTcUnderSa + 0.5, 'Mean = ' + JPMPrintNumber(meanTcUnderSa) + ' ºC', /DATA, COLOR = 'crimson', TARGET = p1, FONT_SIZE = 16)
  t4 = text(0.25, meanTcUnderSaModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcUnderSaModel) + ' ºC', /DATA, COLOR = 'tomato', TARGET = p1, FONT_SIZE = 16)
  l1 = legend(TARGET = [p1, p2, p3, p4], POSITION = [0.9, 0.4])

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    yrange = [-10, 35]
    saveloc = saveloc + '../Transient Hot Balance Model Vs Measurement/'

    ; Read the measurement data
    restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'

    ; Read the hot balance model data
    restore, datalocModel + 'Hot Transient Measures.sav'
    
    ; Deal with the fact that I don't care about hot balance model convergence -- the mean values are just for hour 3-4 after convergence before radio transient
    meanHotMeasuredIndices = where(tcRelativeTimeHours GE 3 AND tcRelativeTimeHours LT 4)
    meanHotModelIndices = where(timeModelHours GE 3 AND timeModelHours LT 4)

  ENDIF
ENDWHILE

p1.save, saveloc + 'Thermal Balance +X SA Conduction.png'
p1.save, savelocdissertation + 'ThermalBalancePlusXSaConduction.png'

END