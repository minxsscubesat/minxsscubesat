;+
; NAME:
;   minxss_plot_tbal_model_measures
;
; PURPOSE:
;   Create plot showing the all of the measure points from the model. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPath [string]: The path to the data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/'
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
;   2016/03/29: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_model_measures, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

;
; Cold balance
;

; Read cold balance data -- can't read both because variables will overwrite
readcol, dataloc + 'Cold Steady State Measures.csv', timeSeconds, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
                                                     tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
                                                     tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
                                                     tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
                                                     tcMinusZModel, tcPlusZModel, $
                                                     tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
                                                     tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
                                                     tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel, SKIPLINE = 1, /SILENT
                                                     
; Convert timet to hours
timeModel = timeSeconds / 3600. 

; Create temperature plot
w = window(DIMENSIONS = [1000, 800])
p1 = plot(timeModel, tcMinusXTopModel, 'r2--', /CURRENT, MARGIN = [0.1, 0.1, 0.27, 0.1], $
          TITLE = 'Thermal Cold Balance Steady-State Model Temperatures', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
          YTITLE = 'Temperature [ºC]', $
          NAME = 'TC -X Top')
p2 = plot(timeModel, tcMinusXMiddleModel, 'r2', /OVERPLOT, $
          NAME = 'TC -X Middle')
p3 = plot(timeModel, tcMinusXBottomModel, 'r2-.', /OVERPLOT, $
          NAME = 'TC -X Bottom')
p4 = plot(timeModel, tcPlusYTopModel, COLOR = 'saddle_brown', '2--', /OVERPLOT, $
          NAME = 'TC +Y Top')
p5 = plot(timeModel, tcPlusYMiddleModel, COLOR = 'saddle_brown', '2', /OVERPLOT, $
          NAME = 'TC +Y Middle')
p6 = plot(timeModel, tcPlusYBottomModel, COLOR = 'saddle_brown', '2-.', /OVERPLOT, $
          NAME = 'TC +Y Bottom')
p7 = plot(timeModel, tcPlusXTopModel, 'b2--', /OVERPLOT, $
          NAME = 'TC +X Top')
p8 = plot(timeModel, tcPlusXUnderSaModel , 'b2', /OVERPLOT, $
          NAME = 'TC +X Middle Under SA')
p9 = plot(timeModel, tcPlusXBottomModel, 'g2-.', /OVERPLOT, $
          NAME = 'TC +X Bottom')
p10 = plot(timeModel, tcPlusXOnSaModel, 'g2:', /OVERPLOT, $
          NAME = 'TC +X On SA')
p11 = plot (timeModel, tcMinusYTopModel, '2--', /OVERPLOT, $
           NAME = 'TC -Y Top')
p12 = plot(timeModel, tcMinusYMiddleModel, '2', /OVERPLOT, $
           NAME = 'TC -Y Middle')
p13 = plot(timeModel, tcMinusYBottomModel, '2-.', /OVERPLOT, $
           NAME = 'TC -Y Bottom')
p14 = plot(timeModel, tcMinusZModel, COLOR = 'magenta', '2', /OVERPLOT, $
           NAME = 'TC -Z')
p15 = plot(timeModel, tcPlusZModel, COLOR = 'orange', '2', /OVERPLOT, $
           NAME = 'TC +Z')
p16 = plot(timeModel, tlmSaPlusYModel, COLOR = 'blue_violet', '2--', /OVERPLOT, $
           NAME = 'TLM +Y SA')
p17 = plot(timeModel, tlmSaMinusYModel, COLOR = 'blue_violet', '2', /OVERPLOT, $
           NAME = 'TLM -Y SA')
p18 = plot(timeModel, tlmSaPlusXModel, COLOR = 'blue_violet', '2-.', /OVERPLOT, $
          NAME = 'TLM +X SA')
p19 = plot (timeModel, tlmEpsModel, 'g2--', /OVERPLOT, $
            NAME = 'TLM EPS')
p20 = plot(timeModel, tlmBatteryModel, 'g2', /OVERPLOT, $
           NAME = 'TLM Battery')
p21 = plot(timeModel, tlmCdhModel, 'g2-.', /OVERPLOT, $
           NAME = 'TLM CDH')
p22 = plot(timeModel, tlmCommModel, 'g2:', /OVERPLOT, $
           NAME = 'TLM COMM')
p23 = plot(timeModel, tlmMotherboardModel, 'g2__', /OVERPLOT, $
           NAME = 'TLM Motherboard')
p24 = plot(timeModel, tlmX123DetectorModel, COLOR = 'cyan', '2', /OVERPLOT, $
           NAME = 'X123 Detector')
p25 = plot(timeModel, tlmX123BoardModel, COLOR = 'yellow_green', '2', /OVERPLOT, $
           NAME = 'X123 Electronics')
     
l1 = legend(TARGET = [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25], POSITION = [1.0, 0.85])

STOP
; Save plot
p1.save, saveloc + 'Thermal Cold Balance Steady-State Model Temperatures.png'

;
; Hot balance
;

END