;+
; NAME:
;   minxss_plot_tbal_model_vs_measurement
;
; PURPOSE:
;   Create plot showing each of the temperature points compared between model and measurement i.e. 2 lines per plot, one model one measurement
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
;   DARK_BACKGROUND: Set this to make the plot background color transparent and flip the dark colors in the plot to light colors (e.g., black -> white text)
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
;   2016/03/29: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_model_vs_measurement, dataPathMeasurement = dataPathMeasurement, dataPathModel = dataPathModel, plotPath = plotPath, $
                                           DARK_BACKGROUND = DARK_BACKGROUND

; Defaults
dark_background = 1
IF ~keyword_set(dataPathMeasurement) THEN datalocMeasurement = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)
IF keyword_set(DARK_BACKGROUND) THEN BEGIN
  foregroundBlackOrWhite = 'white'
  otherHighContrastColor = 'deep pink'
  backgroundColor = 'slate grey' ; Will be used as the transparency mask for the png
ENDIF ELSE BEGIN
  foregroundBlackOrWhite = 'black'
  otherHighContrastColor = 'red'
  backgroundColor = 'white'
ENDELSE

; Update the model files -- convert the TD output txt to IDL saveset
minxss_plot_tbal_convert_model_txt_to_sav

; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

coldOrHot = 'Cold' ; Do cold balance plot first
coldDone = 0
xrange = [0, 4]
saveloc = saveloc + 'Steady-State Cold Balance Model Vs Measurement/'
WHILE coldOrHot EQ 'Cold' DO BEGIN
  IF coldDone EQ 1 THEN coldOrHot = 'Hot'
  
  ;
  ; Crap ton of plots
  ;
  
  ; Bulk plot of all measurements and model together with just two colors and line styles and no other differentiation
  w = window(BACKGROUND_COLOR = backgroundColor)
  p1 = plot(tcRelativeTimeHours, tcPlusYTop, '2', COLOR = foregroundBlackOrWhite, FONT_COLOR = foregroundBlackOrWhite, /CURRENT, $
            TITLE = 'Thermal ' + coldOrHot + ' Balance Bulk Temperature Measurement vs Model', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, XCOLOR = foregroundBlackOrWhite, $
            YTITLE = 'Temeprature [ºC]', YRANGE = [-20, 50], YCOLOR = foregroundBlackOrWhite, $
            NAME = 'Measurement')
  p2 = plot(tcRelativeTimeHours, tcPlusYMiddle, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p3 = plot(tcRelativeTimeHours, tcMinusZ, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p4 = plot(tcRelativeTimeHours, tcPlusXTop, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p5 = plot(tcRelativeTimeHours, tcPlusXOnSA, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p6 = plot(tcRelativeTimeHours, tcPlusXUnderSA, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p7 = plot(tcRelativeTimeHours, tcPlusXBottom, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p8 = plot(tcRelativeTimeHours, tcMinusYTop, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p9 = plot(tcRelativeTimeHours, tcMinusYMiddle, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p11 = plot(tcRelativeTimeHours, tcMinusYBottom, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p11 = plot(tcRelativeTimeHours, tcMinusXTop, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p12 = plot(tcRelativeTimeHours, tcMinusXMiddle, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p13 = plot(tcRelativeTimeHours, tcMinusXBottom, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p14 = plot(relativeTimeHours, hk.CDH_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p15 = plot(relativeTimeHours, hk.RADIO_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p16 = plot(relativeTimeHours, hk.COMM_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p17 = plot(relativeTimeHours, hk.MB_TEMP1, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p18 = plot(relativeTimeHours, hk.MB_TEMP2, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p19 = plot(relativeTimeHours, hk.EPS_TEMP1, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p20 = plot(relativeTimeHours, hk.EPS_TEMP2, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p21 = plot(relativeTimeHours, hk.EPS_SA1_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p22 = plot(relativeTimeHours, hk.EPS_SA2_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p23 = plot(relativeTimeHours, hk.EPS_SA3_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p24 = plot(relativeTimeHours, hk.EPS_BATT_TEMP1, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p25 = plot(relativeTimeHours, hk.EPS_BATT_TEMP2, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p26 = plot(relativeTimeHours, hk.SPS_XPS_PWR_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p27 = plot(relativeTimeHours, hk.SPS_XPS_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p28 = plot(relativeTimeHours, hk.XPS_XPS_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)
  p29 = plot(relativeTimeHours, hk.X123_BRD_TEMP, '2', COLOR = foregroundBlackOrWhite, /OVERPLOT)

  p30 = plot(timeModelHours, tcPlusYTopModel, '2--', COLOR = otherHighContrastColor, /OVERPLOT, $
             NAME = 'Model')
  p31 = plot(timeModelHours, tcPlusYMiddleModel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p32 = plot(timeModelHours, tcminuszmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p33 = plot(timeModelHours, tcplusxtopmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p34 = plot(timeModelHours, tcPlusXOnSAmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p35 = plot(timeModelHours, tcPlusXUnderSAmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p36 = plot(timeModelHours, tcPlusXBottommodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p37 = plot(timeModelHours, tcMinusYTopmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p38 = plot(timeModelHours, tcMinusYMiddlemodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p39 = plot(timeModelHours, tcMinusYBottommodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p40 = plot(timeModelHours, tcMinusXTopmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p41 = plot(timeModelHours, tcMinusXMiddlemodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p42 = plot(timeModelHours, tcMinusXBottommodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p43 = plot(timeModelHours, tlmcdhmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p45 = plot(timeModelHours, tlmcommmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p46 = plot(timeModelHours, tlmmotherboardmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p48 = plot(timeModelHours, tlmepsmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p50 = plot(timeModelHours, tlmsaminusymodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p51 = plot(timeModelHours, tlmsaplusxmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p52 = plot(timeModelHours, tlmsaplusymodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p53 = plot(timeModelHours, tlmbatterymodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  p58 = plot(timeModelHours, tlmx123boardmodel, '2--', COLOR = otherHighContrastColor, /OVERPLOT)
  IF coldDone EQ 0 THEN l1 = legend(TARGET = [p1, p30], POSITION = [0.4, 0.85], TRANSPARENCY = 100, TEXT_COLOR = foregroundBlackOrWhite)
  
  IF keyword_set(DARK_BACKGROUND) THEN BEGIN
    p1.save, '/Users/jmason86/Dropbox/Research/Woods_LASP/Presentations/20160425 PhD Defense/Images/BulkTemperatureComparison' + coldOrHot + '.png', /TRANSPARENT
    GOTO, SKIP_TO_END
  ENDIF ELSE p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Bulk Temperature Measurements vs Model.png'
  STOP
  ; -X Middle TC
  meanTcMiddle = mean(tcMinusXMiddle)
  meanTcModel = mean(tcMinusXMiddleModel)
  p1 = plot(tcRelativeTimeHours, tcMinusXMiddle, 'r2', /BUFFER, $
            TITLE = '-X Middle Thermocouple: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tcMinusXMiddleModel, COLOR = 'maroon', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'red')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'maroon')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])     
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance -X Middle TC Model Vs Measurement.png'
  
  ; +Y Top TC
  meanTcMiddle = mean(tcPlusYTop)
  meanTcModel = mean(tcPlusYTopModel)
  p1 = plot(tcRelativeTimeHours, tcPlusYTop, COLOR = 'saddle_brown', '2', /BUFFER, $
            TITLE = '+Y Top Thermocouple: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tcPlusYTopModel, COLOR = 'brown', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'saddle_brown')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'brown')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance +Y Top TC Model Vs Measurement.png'
  
  ; +X Bottom TC
  meanTcMiddle = mean(tcPlusXBottom)
  meanTcModel = mean(tcPlusXBottomModel)
  p1 = plot(tcRelativeTimeHours, tcPlusXBottom, COLOR = 'blue', '2', /BUFFER, $
            TITLE = '+X Bottom Thermocouple: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tcPlusXBottomModel, COLOR = 'dark_blue', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'blue')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_blue')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance +X Bottom TC Model Vs Measurement.png'
  
  ; -Z TC
  meanTcMiddle = mean(tcMinusZ)
  meanTcModel = mean(tcMinusZModel)
  p1 = plot(tcRelativeTimeHours, tcMinusZ, COLOR = 'orange', '2', /BUFFER, $
            TITLE = '-Z Thermocouple: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tcMinusZModel, COLOR = 'orange_red', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 0.5, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'orange')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'orange_red')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance -Z TC Model Vs Measurement.png'
  
  ; +X SA
  meanTcMiddle = mean(hk.EPS_SA2_TEMP)
  meanTcModel = mean(tlmSaPlusXModel)
  p1 = plot(relativeTimeHours, hk.EPS_SA2_TEMP, COLOR = 'blue_violet', '2', /BUFFER, $
            TITLE = '+X Solar Array: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmSaPlusXModel, COLOR = 'indigo', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.1, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'blue_violet')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'indigo')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance +X SA Model Vs Measurement.png'
  
  ; EPS
  meanTcMiddle = mean(hk.EPS_TEMP1)
  meanTcModel = mean(tlmEpsModel)
  p1 = plot(relativeTimeHours, hk.EPS_TEMP1, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'EPS Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmEpsModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle, 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board EPS Model Vs Measurement.png'
  
  ; Battery
  meanTcMiddle = mean(hk.EPS_BATT_TEMP1)
  meanTcModel = mean(tlmBatteryModel)
  p1 = plot(relativeTimeHours, hk.EPS_BATT_TEMP1, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'Battery Pack: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmBatteryModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.0 , 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board Battery Model Vs Measurement.png'
  
  ; CDH
  meanTcMiddle = mean(hk.CDH_TEMP)
  meanTcModel = mean(tlmCdhModel)
  p1 = plot(relativeTimeHours, hk.CDH_TEMP, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'CDH Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmCdhModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.0 , 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board CDH Model Vs Measurement.png'
  
  ; COMM
  meanTcMiddle = mean(hk.COMM_TEMP)
  meanTcModel = mean(tlmCommModel)
  p1 = plot(relativeTimeHours, hk.COMM_TEMP, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'COMM Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmCommModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.0 , 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.4, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board COMM Model Vs Measurement.png'
  
  ; X123 Electronics
  meanTcMiddle = mean(hk.X123_BRD_TEMP)
  meanTcModel = mean(tlmX123BoardModel)
  p1 = plot(relativeTimeHours, hk.X123_BRD_TEMP, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'X123 Electronics Board: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmX123BoardModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.0 , 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board X123 Electronics Model Vs Measurement.png'
  
  ; Motherboard
  meanTcMiddle = mean(hk.MB_TEMP1)
  meanTcModel = mean(tlmMotherboardModel)
  p1 = plot(relativeTimeHours, hk.MB_TEMP1, COLOR = 'forest_green', '2', /BUFFER, $
            TITLE = 'Motherboard: $\Delta$Mean = ' + JPMPrintNumber(abs(meanTcMiddle - meanTcModel)) + ' ºC', $
            XTITLE = 'Time Since Start [hours]', XRANGE = xrange, $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'Measurement')
  p2 = plot(timeModelHours, tlmMotherboardModel, COLOR = 'dark_green', '2--', /OVERPLOT, $
            NAME = 'Model')
  t1 = text(0.25, meanTcMiddle + 1.0 , 'Mean = ' + JPMPrintNumber(meanTcMiddle) + ' ºC', /DATA, COLOR = 'forest_green')
  t2 = text(0.25, meanTcModel + 0.5, 'Mean = ' + JPMPrintNumber(meanTcModel) + ' ºC', /DATA, COLOR = 'dark_green')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.9, 0.5])
  p1.save, saveloc + 'Thermal ' + coldOrHot + ' Balance Board Motherboard Electronics Model Vs Measurement.png'

  SKIP_TO_END:
  IF coldOrHot EQ 'Cold' THEN BEGIN
    coldDone = 1
    xrange = [0, 5]
    saveloc = saveloc + '../Transient Hot Balance Model Vs Measurement/'
    
    ; Read the measurement data 
    restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'
    
    ; Read the hot balance model data
    restore, datalocModel + 'Hot Transient Measures.sav'
    
  ENDIF
ENDWHILE

END