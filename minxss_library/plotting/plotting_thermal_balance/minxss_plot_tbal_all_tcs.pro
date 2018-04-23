;+
; NAME:
;   minxss_plot_tbal_all_tcs
;
; PURPOSE:
;   Create plot showing all of the thermocouples to determine if there are any out of family. 
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
;   2016/03/31: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_all_tcs, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

;
; Cold balance
;

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'

; Create system TC plot
w = window(DIMENSIONS = [800, 700])
p1 = plot(tcRelativeTimeHours, tcPlusZ, '2--', /CURRENT, MARGIN = [0.1, 0.1, 0.27, 0.1], $
          TITLE = 'Thermal Cold Balance Spacecraft Thermocouples', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
          YTITLE = 'Temperature [ºC]', $
          NAME = '+Z Plate')
p2 = plot(tcRelativeTimeHours, tcMinusZ, '2', /OVERPLOT, $
          NAME = '-Z Plate')
p3 = plot(tcRelativeTimeHours, tcPlusYTop, '2--', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Top')
p4 = plot(tcRelativeTimeHours, tcPlusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Middle')
p5 = plot(tcRelativeTimeHours, tcPlusYBottom, '2:', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Bottom')
p6 = plot(tcRelativeTimeHours, tcPlusXTop, '2--', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Top')
p7 = plot(tcRelativeTimeHours, tcPlusXOnSA, '2', COLOR = 'lime green', /OVERPLOT, $
          NAME = '+X Plate On SA')
p8 = plot(tcRelativeTimeHours, tcPlusXUnderSA, '2', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Under SA')
p9 = plot(tcRelativeTimeHours, tcPlusXBottom, '2:', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Bottom')
p10 = plot(tcRelativeTimeHours, tcMinusYTop, '2--', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
          NAME = '-Y Plate Top')
p11 = plot(tcRelativeTimeHours, tcMinusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
          NAME = '-Y Plate Middle')
p12 = plot(tcRelativeTimeHours, tcMinusYBottom, '2:', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
           NAME = '-Y Plate Bottom')
p13 = plot(tcRelativeTimeHours, tcMinusXTop, '2--', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Top')
p14 = plot(tcRelativeTimeHours, tcMinusXMiddle, '2', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Middle')
p15 = plot(tcRelativeTimeHours, tcMinusXBottom, '2:', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Bottom')
l1 = legend(TARGET = [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15], POSITION = [1, 0.8])

; Save plot
p1.save, saveloc + 'Thermal Cold Balance All Spacecraft TCs.png'

; Create environment TC plot
w = window(DIMENSIONS = [800, 700])
p1 = plot(tcRelativeTimeHours, tcPlatenBackLeft, 'r4', /CURRENT, FONT_SIZE = 18, $
          TITLE = 'Thermal Cold Balance Environment Thermocouples', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
          YTITLE = 'Temperature [ºC]', YRANGE = [-80, 80], YMAJOR = 9, $
          NAME = 'Platen Back Left')
;p2 = plot(tcRelativeTimeHours, tcGasHeater, '2', /OVERPLOT, $
;          NAME = 'Gas Heater')
;p3 = plot(tcRelativeTimeHours, tcGetter, '2:', /OVERPLOT, $
;          NAME = 'Getter')
;p6 = plot(tcRelativeTimeHours, tcShroudInput, 'b2', /OVERPLOT, $
;          NAME = 'Shroud Input')
p7 = plot(tcRelativeTimeHours, tcShroudBack, 'b4--', /OVERPLOT, $
          NAME = 'Shroud Back')
p8 = plot(tcRelativeTimeHours, tcShroudLeftFront, '4', COLOR = 'sky blue', /OVERPLOT, $
          NAME = 'Shroud Left Front')
p9 = plot(tcRelativeTimeHours, tcShroudRightFront, '4--', COLOR = 'sky blue', /OVERPLOT, $
          NAME = 'Shroud Right Front')
p10 = plot(tcRelativeTimeHours, tcShroudLeftRear, '4', COLOR = 'dark blue', /OVERPLOT, $
           NAME = 'Shroud Left Rear')
p11 = plot(tcRelativeTimeHours, tcShroudTopRear, '4--', COLOR = 'dark blue', /OVERPLOT, $
           NAME = 'Shroud Top Rear')
;l1 = legend(TARGET = [p1, p7, p8, p9, p10, p11], POSITION = [0.85, 0.5])

; Save plot
p1.save, saveloc + 'Thermal Cold Balance All Environment TCs.png'

;
; Hot balance
;

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'

; Create  plot
w = window(DIMENSIONS = [800, 700])
p1 = plot(tcRelativeTimeHours, tcPlusZ, '2--', /CURRENT, MARGIN = [0.1, 0.1, 0.27, 0.1], $
          TITLE = 'Thermal Hot Balance Spacecraft Thermocouples', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 5], $
          YTITLE = 'Temperature [ºC]', $
          NAME = '+Z Plate')
p2 = plot(tcRelativeTimeHours, tcMinusZ, '2', /OVERPLOT, $
          NAME = '-Z Plate')
p3 = plot(tcRelativeTimeHours, tcPlusYTop, '2--', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Top')
p4 = plot(tcRelativeTimeHours, tcPlusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Middle')
p5 = plot(tcRelativeTimeHours, tcPlusYBottom, '2:', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
          NAME = '+Y Plate Bottom')
p6 = plot(tcRelativeTimeHours, tcPlusXTop, '2--', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Top')
p7 = plot(tcRelativeTimeHours, tcPlusXOnSA, '2', COLOR = 'lime green', /OVERPLOT, $
          NAME = '+X Plate On SA')
p8 = plot(tcRelativeTimeHours, tcPlusXUnderSA, '2', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Under SA')
p9 = plot(tcRelativeTimeHours, tcPlusXBottom, '2:', COLOR = JPMColors(/SIMPLE, 2), /OVERPLOT, $
          NAME = '+X Plate Bottom')
p10 = plot(tcRelativeTimeHours, tcMinusYTop, '2--', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
          NAME = '-Y Plate Top')
p11 = plot(tcRelativeTimeHours, tcMinusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
          NAME = '-Y Plate Middle')
p12 = plot(tcRelativeTimeHours, tcMinusYBottom, '2:', COLOR = JPMColors(/SIMPLE, 3), /OVERPLOT, $
           NAME = '-Y Plate Bottom')
p13 = plot(tcRelativeTimeHours, tcMinusXTop, '2--', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Top')
p14 = plot(tcRelativeTimeHours, tcMinusXMiddle, '2', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Middle')
p15 = plot(tcRelativeTimeHours, tcMinusXBottom, '2:', COLOR = JPMColors(/SIMPLE, 4), /OVERPLOT, $
           NAME = '-X Plate Bottom')
l1 = legend(TARGET = [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15], POSITION = [1, 0.8])

; Save plot
p1.save, saveloc + 'Thermal Hot Balance Spacecraft TCs.png'

; Create environment TC plot
w = window(DIMENSIONS = [800, 700])
p1 = plot(tcRelativeTimeHours, tcPlatenBackLeft, 'r4', /CURRENT, FONT_SIZE = 18, $
          TITLE = 'Thermal Hot Balance Environment Thermocouples', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 5], $
          YTITLE = 'Temperature [ºC]', YRANGE = [-80, 80], YMAJOR = 9, $
          NAME = 'Platen Back Left')
;p2 = plot(tcRelativeTimeHours, tcGasHeater, '2', /OVERPLOT, $
;          NAME = 'Gas Heater')
;p3 = plot(tcRelativeTimeHours, tcGetter, '2:', /OVERPLOT, $
;          NAME = 'Getter')
;p6 = plot(tcRelativeTimeHours, tcShroudInput, 'b2', /OVERPLOT, $
;          NAME = 'Shroud Input')
p7 = plot(tcRelativeTimeHours, tcShroudBack, 'b4--', /OVERPLOT, $
          NAME = 'Shroud Back')
p8 = plot(tcRelativeTimeHours, tcShroudLeftFront, '4', COLOR = 'sky blue', /OVERPLOT, $
          NAME = 'Shroud Left Front')
p9 = plot(tcRelativeTimeHours, tcShroudRightFront, '4--', COLOR = 'sky blue', /OVERPLOT, $
          NAME = 'Shroud Right Front')
p10 = plot(tcRelativeTimeHours, tcShroudLeftRear, '4', COLOR = 'dark blue', /OVERPLOT, $
           NAME = 'Shroud Left Rear')
p11 = plot(tcRelativeTimeHours, tcShroudTopRear, '4--', COLOR = 'dark blue', /OVERPLOT, $
           NAME = 'Shroud Top Rear')
l1 = legend(TARGET = [p1, p7, p8, p9, p10, p11], POSITION = [0.85, 0.76], FONT_SIZE = 16)
STOP
; Save plot
p1.save, saveloc + 'Thermal Hot Balance All Environment TCs.png'

END