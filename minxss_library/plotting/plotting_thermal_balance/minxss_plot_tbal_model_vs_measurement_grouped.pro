;+
; NAME:
;   minxss_plot_tbal_model_vs_measurement_grouped
;
; PURPOSE:
;   Dissertation plot. 
;   Create plot showing each of the temperature points compared between model and measurement i.e. 2 lines per plot, one model one measurement
;   but grouped into a 2x4 array of plots with some logical arrangement. 
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
;   2016/04/04: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_model_vs_measurement_grouped, dataPathMeasurement = dataPathMeasurement, dataPathModel = dataPathModel, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPathMeasurement) THEN datalocMeasurement = '/Users/' + getenv('username') + '/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/' + getenv('username') + '/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/' + getenv('username') + '/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)
savelocDissertation = '/Users/' + getenv('username') + '/Dropbox/Research/Woods_LASP/Papers/20160501 Dissertation/PhD_Dissertation/LaTeX/Images/'


; Setup
fontSize = 26
margin = 0.15
color1a = 'red'
color1b = 'firebrick'
color2a = 'saddle brown'
color2b = 'brown'
color3a = 'blue'
color3b = 'dark blue'
color4a = 'orange'
color4b = 'orange red'
color5a = 'forest green'
color5b = 'dark green'
color6a = 'yellow green'
color6b = 'green'
color7a = 'lime green'
color7b = 'sea green'
color8a = 'dark sea green'
color8b = 'olive drab'
color9a = 'purple'
color9b = 'indigo'
color10a = 'cornflower'
color10b = 'navy'
color11a = 'dark orange'
color11b = 'goldenrod'

; Update the model files -- convert the TD output txt to IDL saveset
minxss_plot_tbal_convert_model_txt_to_sav

; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

;
; Crap ton of plots
;

; Page 1 of plots - spacecraft TCs
coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 4]
meanHotMeasuredIndices = [0:n_elements(tcRelativeTimeHours) - 1]
meanHotModelIndices = [0:n_elements(timeModelHours) - 1]

w = window(DIMENSIONS = [1836., 2376.], /BUFFER) ; Corresponds to 8.5" x 11" * 4 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'
  
  leftTitle = text(0.25, 1, 'Cold Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)
  
  ; -X Middle TC
  meanTcMiddle = mean(tcMinusXMiddle[meanHotMeasuredIndices])
  meanTcModel = mean(tcMinusXMiddleModel[meanHotModelIndices])
  p1 = plot(tcRelativeTimeHours, tcMinusXMiddle, '4', COLOR = color1a, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 4, layoutColumn], MARGIN = margin, $
            TITLE = '-X Middle TC: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange, $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tcMinusXMiddleModel, COLOR = color1b, '4--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color1a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color1b, FONT_SIZE = fontSize - 2)
  l1 = legend(TARGET = [p1, p2], POSITION = [0.55, 0.55], FONT_SIZE = fontSize)

  ; +Y Top TC
  meanTcMiddle = mean(tcPlusYTop[meanHotMeasuredIndices])
  meanTcModel = mean(tcPlusYTopModel[meanHotModelIndices])
  p1 = plot(tcRelativeTimeHours, tcPlusYTop, COLOR = color2a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '+Y Top TC: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange)
  p2 = plot(timeModelHours, tcPlusYTopModel, COLOR = color2b, '4--', /OVERPLOT)
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color2a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color2b, FONT_SIZE = fontSize - 2)
  
  ; +X Bottom TC
  meanTcMiddle = mean(tcPlusXBottom[meanHotMeasuredIndices])
  meanTcModel = mean(tcPlusXBottomModel[meanHotModelIndices])
  p1 = plot(tcRelativeTimeHours, tcPlusXBottom, COLOR = color3a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '+X Bottom TC: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange)
  p2 = plot(timeModelHours, tcPlusXBottomModel, COLOR = color3b, '4--', /OVERPLOT)
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color3a, FONT_SIZE = fontSize - 2)
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color3b, FONT_SIZE = fontSize - 2)

  ; -Z TC
  meanTcMiddle = mean(tcMinusZ[meanHotMeasuredIndices])
  meanTcModel = mean(tcMinusZModel[meanHotModelIndices])
  p1 = plot(tcRelativeTimeHours, tcMinusZ, COLOR = color4a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 6], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '-Z TC: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)
  p2 = plot(timeModelHours, tcMinusZModel, COLOR = color4b, '4--', /OVERPLOT)
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color4a, FONT_SIZE = fontSize - 2)
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color4b, FONT_SIZE = fontSize - 2)
  
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    layoutColumn = 2   
    
    ; Read the measurement data
    restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'

    ; Read the hot balance model data
    restore, datalocModel + 'Hot Transient Measures.sav'
    
    ; Deal with the fact that I don't care about hot balance model convergence -- the mean values are just for hour 3-4 after convergence before radio transient
    meanHotMeasuredIndices = where(tcRelativeTimeHours GE 3 AND tcRelativeTimeHours LT 4)
    meanHotModelIndices = where(timeModelHours GE 3 AND timeModelHours LT 4)

  ENDIF
ENDWHILE ; First page of plots
p1.save, saveloc + 'Thermal Balance External TCs Model Vs Measurement.png'
p1.save, savelocDissertation + 'ThermalBalanceExternalTCsModelVsMeasurement.png'


; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

; Page 2 of plots - passive boards
coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 4]
meanHotMeasuredIndices = [0:n_elements(tcRelativeTimeHours) - 1]
meanHotMeasuredHkIndices = [0:n_elements(relativeTimeHours) - 1]
meanHotModelIndices = [0:n_elements(timeModelHours) - 1]

w = window(DIMENSIONS = [1836., 2376.], /BUFFER) ; Corresponds to 8.5" x 11" * 4 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  leftTitle = text(0.25, 1, 'Cold Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)

  ; Motherboard
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].MB_TEMP1)
  meanTcModel = mean(tlmMotherboardModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.MB_TEMP1, '4', COLOR = color5a, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 4, layoutColumn], MARGIN = margin, $
            TITLE = 'Motherboard: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange, $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmMotherboardModel, COLOR = color5b, '4--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color5a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color5b, FONT_SIZE = fontSize - 2)
  l1 = legend(TARGET = [p1, p2], POSITION = [0.55, 0.55], FONT_SIZE = fontSize)

  ; CDH
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].CDH_TEMP)
  meanTcModel = mean(tlmCdhModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.CDH_TEMP, COLOR = color6a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'CDH Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange)
  p2 = plot(timeModelHours, tlmCdhModel, COLOR = color6b, '4--', /OVERPLOT)
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color6a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color6b, FONT_SIZE = fontSize - 2)

  ; +X Solar Array
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].EPS_SA2_TEMP)
  meanTcModel = mean(tlmSaPlusXModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.EPS_SA2_TEMP, COLOR = color7a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = '+X Solar Array: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange)
  p2 = plot(timeModelHours, tlmSaPlusXModel, COLOR = color7b, '4--', /OVERPLOT)
  IF coldDone EQ 0 THEN t1yposition = meanTcMiddle + 1.5 ELSE t1yposition = meanTcMiddle + 0.5
  t1 = text(0.25, t1yposition, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color7a, FONT_SIZE = fontSize - 2)
  t2 = text(0.25, meanTcModel, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color7b, FONT_SIZE = fontSize - 2)

  ; X123 electronics
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].X123_BRD_TEMP)
  meanTcModel = mean(tlmX123BoardModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.X123_BRD_TEMP, COLOR = color8a, '4', /CURRENT, LAYOUT = [2, 4, layoutColumn + 6], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'X123 Electronics: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)
  p2 = plot(timeModelHours, tlmX123BoardModel, COLOR = color8b, '4--', /OVERPLOT)
  IF coldDone EQ 0 THEN t1yposition = meanTcMiddle + 1.5 ELSE t1yposition = meanTcMiddle + 0.5
  t1 = text(0.25, t1yposition, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color8a, FONT_SIZE = fontSize - 2)
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color8b, FONT_SIZE = fontSize - 2)

  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    layoutColumn = 2

    ; Read the measurement data
    restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'

    ; Read the hot balance model data
    restore, datalocModel + 'Hot Transient Measures.sav'

    ; Deal with the fact that I don't care about hot balance model convergence -- the mean values are just for hour 3-4 after convergence before radio transient
    meanHotMeasuredIndices = where(tcRelativeTimeHours GE 3 AND tcRelativeTimeHours LT 4)
    meanHotMeasuredHkIndices = where(relativeTimeHours GE 3 AND relativeTimeHours LT 4)
    meanHotModelIndices = where(timeModelHours GE 3 AND timeModelHours LT 4)

  ENDIF
ENDWHILE ; First page of plots
p1.save, saveloc + 'Thermal Balance Passive Boards Model Vs Measurement.png' 
p1.save, savelocDissertation + 'ThermalBalancePassiveBoardsModelVsMeasurements.png'

; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

; Page 3 of plots - active boards
coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
layoutColumn = 1
xrange = [0, 4]
meanHotMeasuredIndices = [0:n_elements(tcRelativeTimeHours) - 1]
meanHotMeasuredHkIndices = [0:n_elements(relativeTimeHours) - 1]
meanHotModelIndices = [0:n_elements(timeModelHours) - 1]

w = window(DIMENSIONS = [1836., 1782.], /BUFFER) ; Corresponds to 8.5" x 11" * 3 with resolution of 72 dpi (can't change res)
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'

  leftTitle = text(0.25, 1, 'Cold Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  rightTitle = text(0.75, 1, 'Hot Balance', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize + 4, FONT_STYLE = 'bold')
  xTitle = text(0, 0.5, 'Temperature [ºC]', VERTICAL_ALIGNMENT = 1, ALIGNMENT = 0.5, FONT_SIZE = fontSize, ORIENTATION = 90)

  ; EPS
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].EPS_TEMP1)
  meanTcModel = mean(tlmEpsModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.EPS_TEMP1, '4', COLOR = color9a, FONT_SIZE = fontSize, /CURRENT, LAYOUT = [2, 3, layoutColumn], MARGIN = margin, $
            TITLE = 'EPS Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange, $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmEpsModel, COLOR = color9b, '4--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color9a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color9b, FONT_SIZE = fontSize - 2)
  l1 = legend(TARGET = [p1, p2], POSITION = [0.55, 0.55], FONT_SIZE = fontSize)

  ; Batteries
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].EPS_BATT_TEMP1)
  meanTcModel = mean(tlmBatteryModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.EPS_BATT_TEMP1, COLOR = color10a, '4', /CURRENT, LAYOUT = [2, 3, layoutColumn + 2], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'Batteries: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XRANGE = xrange)
  p2 = plot(timeModelHours, tlmBatteryModel, COLOR = color10b, '4--', /OVERPLOT)
  IF coldDone EQ 0 THEN t1yposition = meanTcMiddle + 2.5 ELSE t1yposition = meanTcMiddle + 0.5
  t1 = text(0.25, t1yposition, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color10a, FONT_SIZE = fontSize - 2)
  IF coldDone EQ 1 THEN t2yposition = meanTcModel - 2 ELSE t2yposition = meanTcModel + 0.5
  t2 = text(0.25, t2yposition, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color10b, FONT_SIZE = fontSize - 2)

  ; COMM
  meanTcMiddle = mean(hk[meanHotMeasuredHkIndices].COMM_TEMP)
  meanTcModel = mean(tlmCommModel[meanHotModelIndices])
  p1 = plot(relativeTimeHours, hk.COMM_TEMP, COLOR = color11a, '4', /CURRENT, LAYOUT = [2, 3, layoutColumn + 4], FONT_SIZE = fontSize, MARGIN = margin, $
            TITLE = 'COMM Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange)
  p2 = plot(timeModelHours, tlmCommModel, COLOR = color11b, '4--', /OVERPLOT)
  IF coldDone EQ 0 THEN t1yposition = meanTcMiddle + 1.5 ELSE t1yposition = meanTcMiddle + 0.5
  t1 = text(0.25, t1yposition, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color11a, FONT_SIZE = fontSize - 2)
  t2 = text(0.25, meanTcModel, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, TARGET = [p1, p2], COLOR = color11b, FONT_SIZE = fontSize - 2)
STOP
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    layoutColumn = 2

    ; Read the measurement data
    restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'

    ; Read the hot balance model data
    restore, datalocModel + 'Hot Transient Measures.sav'

    ; Deal with the fact that I don't care about hot balance model convergence -- the mean values are just for hour 3-4 after convergence before radio transient
    meanHotMeasuredIndices = where(tcRelativeTimeHours GE 3 AND tcRelativeTimeHours LT 4)
    meanHotMeasuredHkIndices = where(relativeTimeHours GE 3 AND relativeTimeHours LT 4)
    meanHotModelIndices = where(timeModelHours GE 3 AND timeModelHours LT 4)

  ENDIF
ENDWHILE ; First page of plots
p1.save, saveloc + 'Thermal Balance Active Boards Model Vs Measurement.png'
p1.save, savelocDissertation + 'ThermalBalanceActiveBoardsModelVsMeasurements.png'

END