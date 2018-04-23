;+
; NAME:
;   minxss_plot_tbal_solar_array_simulator
;
; PURPOSE:
;   Dissertation plot. 
;   Create plot showing the data from the solar array simulator (SAS) that provided power to the CubeSat. 
;   Also compute and show (on plot) the average power [W] that was fed into the system when power flow was enabled. 
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
PRO minxss_plot_tbal_solar_array_simulator, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Drive/CubeSat/MinXSS Server/8000 Ground Software : Mission Ops/8020 Solar Panel Simulator Development/SASPowerRecord/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

IF file_test(saveloc + 'Thermal Balance SAS.sav') THEN restore, saveloc + 'Thermal Balance SAS.sav' ELSE BEGIN
  ; Read SAS power data either from previous IDL saveset from this code or from the .csv
  readcol, dataloc + 'Thermal Balance FM1.csv', sasTimeIsoMt, sasVoltage, sasCurrent, format = 'a, f, f', /SILENT
  
  ; Convert time from the ISO standard (e.g., 2016-03-24T14:43:26-06:00) to julian day converted into UTC (the -06:00 in the timestamp indicates MT timezone)
  TimeStampToValues, sasTimeIsoMt, YEAR = year, MONTH = month, DAY = day, HOUR = hour, MINUTE = minute, SECOND = second, OFFSET = timeOffset
  sasTimeIsoUtc = TimeStamp(YEAR = year, MONTH = month, DAY = day, HOUR = hour, MINUTE = minute, SECOND = second, OFFSET = timeOffset, /UTC)
  TimeStampToValues, sasTimeIsoUtc, YEAR = year, MONTH = month, DAY = day, HOUR = hour, MINUTE = minute, SECOND = second, OFFSET = timeOffset
  jd = julday(month, day, year, hour, minute, second)
  
  ; Compute power statistics when power output was enabled
  powerOnIndices = where(sasVoltage GT 15)
  powerOnVoltages = sasVoltage[powerOnIndices]
  powerOnCurrents = sasCurrent[powerOnIndices]
  powerOnWattage = powerOnVoltages * powerOnCurrents
  wattsMin = min(powerOnWattage)
  wattsMax = max(powerOnWattage)
  wattsAverage = mean(powerOnWattage)
  
  ; Save all of the variables to saveset on disk
  save, FILENAME = saveloc + 'Thermal Balance SAS.sav', /COMPRESS
ENDELSE

timeHours = (jd - 2457106.5) * 24. ; 2457106.5 is the UTC start time of the cold balance test

; Create plot
w = window(DIMENSIONS = [800, 800])
p1 = plot(timeHours, sasVoltage, 'r2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          TITLE = 'Thermal Cold Balance Solar Array Simulator Output Power', $
          XRANGE = [0, 4], $ ; minmax(jd), $
          YRANGE = [0, 25])
p2 = plot(timeHours, sasCurrent, 'b2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          XRANGE = [0, 4], $ ; minmax(jd), $
          YRANGE = [0, 2])
a1 = axis('Y', LOCATION = 'left', TARGET = [p1], TITLE = 'Voltage [V]', COLOR = 'red')
a2 = axis('Y', LOCATION = 'right', TARGET = [p2], TITLE = 'Current [A]', COLOR = 'blue')
ax = axis('X', LOCATION = 'top', TARGET = [p1], SHOWTEXT = 0)
ax = axis('X', LOCATION = 'bottom', TARGET = [p1], TITLE = 'Time Since Start [hours]') ; really in UTC but it so happens that 0 UTC was the start time for cold balance
t1 = text(0.15, 0.8, 'Min   Power = ' + JPMPrintNumber(wattsMin) + ' W')
t2 = text(0.15, 0.78, 'Max  Power = ' + JPMPrintNumber(wattsMax) + ' W')
t3 = text(0.15, 0.76, 'Mean Power = ' + JPMPrintNumber(wattsAverage) + ' W')

; Save plot
p1.save, saveloc + 'Thermal Cold Balance SAS.png'

END