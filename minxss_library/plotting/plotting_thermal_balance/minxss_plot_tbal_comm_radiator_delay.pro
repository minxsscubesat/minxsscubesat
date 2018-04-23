;+
; NAME:
;   minxss_plot_tbal_comm_radiator_delay
;
; PURPOSE:
;   Create plot showing the time delay between a COMM heating up from a long duration transmission (typical orbit pass playback time)
;   and the radiator plate peaking. Turns out the +X under solar array (SA) shows the biggest peak of the radiators, which is unexpected.  
;
; INPUTS:
;   None
;   
; OPTIONAL INPUTS:
;   dataPath [string]: The path to the data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' since James is the only one likely
;                      to use this code. 
;   plotPath [string]: The path you want the plots saved to. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/'
;                      since James is the only one likely to use this code. 
;   
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots as described in purpose, one each for hot and cold thermal balance. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;   Requires that minxss_plots_temperature was already run for thermal balance data and a .sav file from it saved to disk
;
; EXAMPLE:
;   None
;
; MODIFICATION HISTORY:
;   2016/03/18: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_comm_radiator_delay, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

;
; Cold balance
;

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'

; Find peaks
commMax = max(hk.COMM_TEMP, commMaxIndex)
tcMaxIndex = closest(3.179, tcRelativeTimeHours) ; Determined by inspection
tcMax = tcPlusYMiddle[tcMaxIndex]

; Determine delta temperature due to TX
initialTime = 3.02 ; Time just prior to TX turn on determined by inspection
commInitialIndex = closest(initialTime, relativeTimeHours)
tcInitialIndex = closest(initialTime, tcRelativeTimeHours)
commDeltaT = commMax - hk[commInitialIndex].COMM_TEMP
tcDeltaT = tcMax - tcPlusYMiddle[tcInitialIndex]

; Create cold balance plot
p1 = plot(relativeTimeHours, hk.COMM_TEMP, '2', $
          TITLE = 'Cold Balance TX Heat Propagation', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 4], $
          YTITLE = 'Temperature [ºC]', $
          NAME = 'MinXSS COMM')
p2 = plot(tcRelativeTimeHours, tcPlusYMiddle, 'r2', /OVERPLOT, $
          NAME = 'TC +Y Middle')
p3 = plot([relativeTimeHours[commMaxIndex], relativeTimeHours[commMaxIndex]], p1.yrange, '--', /OVERPLOT)
p4 = plot([tcRelativeTimeHours[tcMaxIndex], tcRelativeTimeHours[tcMaxIndex]], p1.yrange, 'r--', /OVERPLOT)
l = legend(TARGET = [p1, p2], POSITION = [0.44, 0.84])
t1 = text(3.3, 15, '$\Delta t = $' + JPMPrintNumber(round((tcRelativeTimeHours[tcMaxIndex] - relativeTimeHours[commMaxIndex]) * 3600.), /NO_DECIMALS) + ' s', /DATA)
aComm = arrow([initialTime, initialTime], [commMax, hk[commInitialIndex].COMM_TEMP], /DATA, ARROW_STYLE = 3, HEAD_ANGLE = 90, HEAD_INDENT = 1, HEAD_SIZE = 0.3)
aTc = arrow([initialTime, initialTime], [tcMax, tcPlusYMiddle[tcInitialIndex]], /DATA, ARROW_STYLE = 3, HEAD_ANGLE = 90, HEAD_INDENT = 1, HEAD_SIZE = 0.3, COLOR = 'red')
tComm = text(initialTime - 0.1, 0, '$\Delta T = $' + JPMPrintNumber(commDeltaT) + ' ºC', /DATA, ALIGNMENT = 1)
tTc = text(initialTime - 0.1, -11, '$\Delta T = $' + JPMPrintNumber(tcDeltaT) + ' ºC', /DATA, ALIGNMENT = 1, COLOR = 'red')
p3.setdata, [relativeTimeHours[commMaxIndex], relativeTimeHours[commMaxIndex]], p1.yrange ; Fix stupid IDL idiosyncrasy 

; Save plot
p1.save, saveloc + 'Cold Balance TX Heat Propagation.png'

; Create plot to compare the +X Under SA TC in hot and cold balance
p0a = plot(tcRelativeTimeHours + 1.11, tcPlusXUnderSa + 25.2, 'b2', $
           TITLE = 'TC +X Under SA Comparison', $
           XTITLE = 'Time Since Start [hours]', $
           YTITLE = 'Temperature [ºC]', $
           NAME = 'Scaled Cold Balance')

;
; Hot balance
;

; Read hot balance data
restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'

; Finish plot to copmare the +X Under SA TC in hot and cold balance
p0b = plot(tcRelativeTimeHours, tcPlusXUnderSa, 'r2', /OVERPLOT, $
           XRANGE = [3, 5], $
           YRANGE = [16.5, 19.5], $
           NAME = 'Hot Balance')
l0 = legend(TARGET = [p0a, p0b], POSITION = [0.48, 0.84])
p0a.save, saveloc + 'TX Heat In TC +X Under SA Hot vs Cold Balance.png'

; Find peaks
commMax = max(hk.COMM_TEMP, commMaxIndex)
tcMaxIndex = closest(4.354, tcRelativeTimeHours) ; Determined by inspection
tcMax = tcPlusYMiddle[tcMaxIndex]

; Determine delta temperature due to TX
initialTime = 4.119 ; Time just prior to TX turn on determined by inspection
commInitialIndex = closest(initialTime, relativeTimeHours)
tcInitialIndex = closest(initialTime, tcRelativeTimeHours)
commDeltaT = commMax - hk[commInitialIndex].COMM_TEMP
tcDeltaT = tcMax - tcPlusYMiddle[tcInitialIndex]

; Create Hot balance plot
p1 = plot(relativeTimeHours, hk.COMM_TEMP, '2', $
          TITLE = 'Hot Balance TX Heat Propagation', $
          XTITLE = 'Time Since Start [hours]', XRANGE = [0, 5], $
          YTITLE = 'Temperature [ºC]', $
          NAME = 'MinXSS COMM')
p2 = plot(tcRelativeTimeHours, tcPlusYMiddle, 'r2', /OVERPLOT, $
          NAME = 'TC +Y Middle')
p3 = plot([relativeTimeHours[commMaxIndex], relativeTimeHours[commMaxIndex]], p1.yrange, '--', /OVERPLOT)
p4 = plot([tcRelativeTimeHours[tcMaxIndex], tcRelativeTimeHours[tcMaxIndex]], p1.yrange, 'r--', /OVERPLOT)
l = legend(TARGET = [p1, p2], POSITION = [0.44, 0.84])
t1 = text(4.3, 36, '$\Delta t = $' + JPMPrintNumber(round((tcRelativeTimeHours[tcMaxIndex] - relativeTimeHours[commMaxIndex]) * 3600.), /NO_DECIMALS) + ' s', /DATA)
aComm = arrow([initialTime, initialTime], [commMax, hk[commInitialIndex].COMM_TEMP], /DATA, ARROW_STYLE = 3, HEAD_ANGLE = 90, HEAD_INDENT = 1, HEAD_SIZE = 0.3)
aTc = arrow([initialTime, initialTime], [tcMax, tcPlusYMiddle[tcInitialIndex]], /DATA, ARROW_STYLE = 3, HEAD_ANGLE = 90, HEAD_INDENT = 1, HEAD_SIZE = 0.3, COLOR = 'red')
tComm = text(initialTime - 0.1, 25, '$\Delta T = $' + JPMPrintNumber(commDeltaT) + ' ºC', /DATA, ALIGNMENT = 1)
tTc = text(initialTime - 0.1, 12, '$\Delta T = $' + JPMPrintNumber(tcDeltaT) + ' ºC', /DATA, ALIGNMENT = 1, COLOR = 'red')
p3.setdata, [relativeTimeHours[commMaxIndex], relativeTimeHours[commMaxIndex]], p1.yrange ; Fix stupid IDL idiosyncrasy 

; Save plot
p1.save, saveloc + 'Hot Balance TX Heat Propagation.png'

END