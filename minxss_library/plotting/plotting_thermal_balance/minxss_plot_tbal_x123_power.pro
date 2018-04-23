;+
; NAME:
;   minxss_plot_tbal_x123_power
;
; PURPOSE:
;   Create plot showing the X123 power (5 V line) for input into the thermal model. 
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
;   2016/03/28: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_x123_power, dataPath = dataPath, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPath) THEN dataloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Thermal Balance Rev2 (Based on MinXSS Rev7)/' ELSE saveloc = temporary(plotPath)

;
; Cold balance
; 

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Cold Thermal Balance Data.sav'

; Store variables
x123Current = hk.EPS_5V_CUR / 1000.   ; [A] 
x123Voltage = hk.EPS_5V_VOLT          ; [V]
x123Power = x123Current * x123Voltage ; [W]
wheel1Speed = hk.XACT_WHEEL1MEASSPEED

; Create temperature plot
w = window(DIMENSIONS = [800, 600])
p1 = plot(relativeTimeHours, x123Power, '2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          TITLE = 'Thermal Cold Balance X123 Power (5 V line)', $
          XRANGE = [0, 4])
p2 = plot(relativeTimeHours, wheel1Speed, 'r2--', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          XRANGE = [0, 4])
a1 = axis('Y', LOCATION = 'left', TARGET = [p1], TITLE = 'Power [W]')
a2 = axis('Y', LOCATION = 'right', TARGET = [p2], TITLE = 'Wheel 1 Speed [rad/s]', COLOR = 'red')
ax = axis('X', LOCATION = 'top', TARGET = [p1], SHOWTEXT = 0)
ax = axis('X', LOCATION = 'bottom', TARGET = [p1], TITLE = 'Time Since Start [hours]')
t1 = text(0.25, 1.94, 'Power = ' + JPMPrintNumber(mean(x123Power)) + ' W', /DATA)

; Save plot
p1.save, saveloc + 'Thermal Cold Balance X123 Power.png'

;
; Hot balance
;

; Read cold balance data -- can't read both because variables will overwrite
restore, dataloc + 'FM-1 Hot Thermal Balance Data.sav'

; Store variables
x123Current = hk.EPS_5V_CUR / 1000.   ; [A]
x123Voltage = hk.EPS_5V_VOLT          ; [V]
x123Power = x123Current * x123Voltage ; [W]
commTemp = hk.COMM_TEMP               ; [T]

; Equilibrium time
equilibriumIndices = where(relativeTimeHours GT 3 AND relativeTimeHours LT 4)
equilibriumPower = mean(x123Power[equilibriumIndices])


; Create temperature plot
w = window(DIMENSIONS = [800, 600])
p1 = plot(relativeTimeHours, x123Power, '2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          TITLE = 'Thermal Hot Balance X123 Power (5 V line)', $
          XRANGE = [0, 5])
p2 = plot(relativeTimeHours, commTemp, 'r2', /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          XRANGE = [0, 5])
a1 = axis('Y', LOCATION = 'left', TARGET = [p1], TITLE = 'Power [W]')
a2 = axis('Y', LOCATION = 'right', TARGET = [p2], TITLE = 'COMM Temperature [ºC]', COLOR = 'red')
ax = axis('X', LOCATION = 'top', TARGET = [p1], SHOWTEXT = 0)
ax = axis('X', LOCATION = 'bottom', TARGET = [p1], TITLE = 'Time Since Start [hours]')
t1 = text(2.55, 2.43, 'Power = ' + JPMPrintNumber(mean(equilibriumPower)) + ' W', /DATA)

; Save plot
p1.save, saveloc + 'Thermal Hot Balance X123 Power.png'

END