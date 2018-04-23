;+
; NAME:
;   minxss_plot_tbal_x123_related_temperatures
;
; PURPOSE:
;   Dissertation plot. 
;   Create plot showing the X123-related temperatures. These are the X123 detector and board temperatures and the -Y bottom thermocouple. 
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
;   2016-03-29: James Paul Mason: Wrote script.
;   2017-03-03: James Paul Mason: Updated to display model and measure temperatures
;-
PRO minxss_plot_tbal_x123_related_temperatures, dataPathMeasurement = dataPathMeasurement, dataPathModel = dataPathModel, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPathMeasurement) THEN datalocMeasurement = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)
savelocDissertation = '/Users/jmason86/Dropbox/Research/Woods_LASP/Papers/20160501 Dissertation/PhD_Dissertation/LaTeX/Images/'
savelocThermalPaper = '/Users/jmason86/Dropbox/Research/Postdoc_LASP/Papers/2017 CubeSat Thermal/Figures/'

w = window(DIMENSIONS = [1600, 800])

;
; Cold balance
;

; Read cold balance measurement data -- can't read the hot at the same time because variables will overwrite
restore, datalocMeasurement + 'FM-1 Cold Thermal Balance Data.sav'

; Read the cold balance model data
restore, datalocModel + 'Cold Steady State Measures.sav'

; Store variables
x123DetectorTemperature = hk.X123_DET_TEMP - 273.15 ; [ºC]
x123BoardTemperature = hk.X123_BRD_TEMP             ; [ºC]

; Statistics
meanDetectorTemperatureMeasurement = mean(x123DetectorTemperature)
meanBoardTemperatureMeasurement = mean(x123BoardTemperature)
meanRadiatorTemperatureMeasurement = mean(tcMinusYBottom)
meanRadiatorTemeperatureModel = mean(tcMinusYBottomModel)

; Create temperature plot
p1 = plot(relativeTimeHours, x123DetectorTemperature, 'r2', /CURRENT, LAYOUT = [2, 1, 1], MARGIN = 0.15, FONT_SIZE = 20, $
          TITLE = 'Thermal Cold Balance X123-Related Temperatures', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
          YTITLE = 'Temperature [ºC]', YRANGE = [-50, 20], $
          NAME = 'Detector')
;p2 = plot(relativeTimeHours, x123BoardTemperature, 'g2', /OVERPLOT, $
;          NAME = 'Board')
p3 = plot(tcRelativetimehours, tcMinusYBottom, 'b2', /OVERPLOT, $
          NAME = '-Y Bottom Radiator Measurement')
p4 = plot(timeModelHours, tcMinusYBottomModel, 'b2--', /OVERPLOT, $
          NAME = '-Y Bottom Radiator Model')
t1 = text(0.25, meanDetectorTemperatureMeasurement + 1., 'Mean = ' + JPMPrintNumber(meanDetectorTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'red', FONT_SIZE = 16)
;t2 = text(0.25, meanBoardTemperatureMeasurement + 1., 'Mean = +' + JPMPrintNumber(meanBoardTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'green')
t3 = text(0.25, meanRadiatorTemperatureMeasurement + 1., 'Mean = ' + JPMPrintNumber(meanRadiatorTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'blue', FONT_SIZE = 16)
t4 = text(0.25, meanRadiatorTemeperatureModel + 1., 'Mean = ' + JPMPrintNumber(meanRadiatorTemeperatureModel) + ' ºC', /DATA, COLOR = 'blue', FONT_SIZE = 16)
t5 = text(3.75, meanDetectorTemperatureMeasurement + 1., 'X123 Power = 1.93 W', /DATA, ALIGNMENT = 1, FONT_SIZE = 16)
l1 = legend(TARGET = [p3, p4, p1], POSITION = [0.35, 0.8])

;
; Hot balance
;

; Read hot balance measurement data -- can't read both because variables will overwrite
restore, datalocMeasurement + 'FM-1 Hot Thermal Balance Data.sav'

; Read the hot balance model data
restore, datalocModel + 'Hot Transient Measures.sav'

; Store variables
x123DetectorTemperature = hk.X123_DET_TEMP - 273.15 ; [ºC]
x123BoardTemperature = hk.X123_BRD_TEMP             ; [ºC]

; Statistics
meanDetectorTemperatureMeasurement = mean(x123DetectorTemperature)
meanBoardTemperatureMeasurement = mean(x123BoardTemperature)
meanRadiatorTemperatureMeasurement = mean(tcMinusYBottom)
meanRadiatorTemeperatureModel = mean(tcMinusYBottomModel)

; Create temperature plot
p1 = plot(relativeTimeHours, x123DetectorTemperature, 'r2', /CURRENT, LAYOUT = [2, 1, 2], MARGIN = 0.15 , FONT_SIZE = 20, $
          TITLE = 'Thermal Hot Balance X123-Related Temperatures', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 5], $
          YTITLE = 'Temperature [ºC]', YRANGE = [-50, 20], $
          NAME = 'Detector')
;p2 = plot(relativeTimeHours, x123BoardTemperature, 'g2', /OVERPLOT, $
;          NAME = 'Board')
p3 = plot(tcRelativetimehours, tcMinusYBottom, 'b2', /OVERPLOT, $
          NAME = '-Y Bottom Radiator')
p4 = plot(timeModelHours, tcMinusYBottomModel, 'b2--', /OVERPLOT, $
          NAME = '-Y Bottom Radiator Model')
t1 = text(0.25, meanDetectorTemperatureMeasurement + 1., 'Mean = ' + JPMPrintNumber(meanDetectorTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'red', FONT_SIZE = 16, TARGET = p1)
;t2 = text(0.25, meanBoardTemperatureMeasurement + 1., 'Mean = +' + JPMPrintNumber(meanBoardTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'green')
t3 = text(3.0, meanRadiatorTemperatureMeasurement + 1., 'Mean = +' + JPMPrintNumber(meanRadiatorTemperatureMeasurement) + ' ºC', /DATA, COLOR = 'blue', FONT_SIZE = 16, TARGET = p1)
t4 = text(0.65, meanRadiatorTemeperatureModel - 12, 'Mean = ' + JPMPrintNumber(meanRadiatorTemeperatureModel) + ' ºC', /DATA, COLOR = 'blue', FONT_SIZE = 16, TARGET = p1)
t5 = text(4.75, meanDetectorTemperatureMeasurement + 1., 'X123 Power = 2.43 W', /DATA, ALIGNMENT = 1, FONT_SIZE = 16, TARGET = p1)
l1 = legend(TARGET = [p3, p4, p1], POSITION = [0.85, 0.5])

; Save plot
p1.save, saveloc + 'Thermal Balance X123-Related Temperatures.png'
p1.save, savelocDissertation + 'ThermalBalanceX123RelatedTemperatures.png'
p1.save, savelocThermalPaper + 'ThermalBalanceX123RelatedTemperatures.png'

END