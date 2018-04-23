;+
; NAME:
;   minxss_plot_adcs_wheel_power
;
; PURPOSE:
;   Plot the power consumptions of the wheels and ancillary data as a function of time
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot of wheel power consumption vs time and optionally altitude
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-05-25: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_wheel_power, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Setup
smoothNumberOfPoints = 500
rad2rpm = 9.54929659643

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Grab wheel powers
wheel1Power = adcs2.coarse_wheel_current1 * 12. ; [W]
wheel2Power = adcs2.coarse_wheel_current2 * 12. ; [W]
wheel3Power = adcs2.coarse_wheel_current3 * 12. ; [W]

; Extract ADCS flags from adcs info
adcsMode = ISHFT(adcs2.adcs_info AND '01'X, 0) ; extract 1-bit flag

; Find coarse point indices
coarsePointIndices = where(adcsMode EQ 0)

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(adcs2.time_jd, wheel1Power, COLOR = 'lime green', '*', LINESTYLE = 'none', LAYOUT = [1, 3, 1], $
          TITLE = 'MinXSS-1 On Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = 'Wheel 1 Power [W]', $
          NAME = 'Fine Ref')
p1a = plot(adcs2[coarsePointIndices].time_jd, wheel1Power[coarsePointIndices], COLOR = 'tomato', '*', LINESTYLE = 'none', /OVERPLOT, $
           NAME = 'Sun Point')
p2 = plot(adcs2.time_jd, wheel2Power, COLOR = 'lime green', '*', LINESTYLE = 'none', LAYOUT = [1, 3, 2], /CURRENT, $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = 'Wheel 2 Power [W]')
p2a = plot(adcs2[coarsePointIndices].time_jd, wheel2Power[coarsePointIndices], COLOR = 'tomato', '*', LINESTYLE = 'none', /OVERPLOT)
p3 = plot(adcs2.time_jd, wheel3Power, COLOR = 'lime green', '*', LINESTYLE = 'none', LAYOUT = [1, 3, 3], /CURRENT, $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = 'Wheel 3 Power [W]')
p3a = plot(adcs2[coarsePointIndices].time_jd, wheel3Power[coarsePointIndices], COLOR = 'tomato', '*', LINESTYLE = 'none', /OVERPLOT)
l1 = legend(POSITION = [0.95, 0.36], TARGET = [p1, p1a])

p1.save, saveloc + 'Wheel Power Vs Time.png'

END