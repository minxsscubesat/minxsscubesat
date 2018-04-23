;+
; NAME:
;   minxss_plot_power_soc_and_voltage
;
; PURPOSE:
;   Plot the battery state of charage and voltage across the mission
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
;   Stacked plots
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS data
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2017-05-14: James Paul Mason: Wrote script.
;-
PRO minxss_plot_power_soc_and_voltage, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(hk.time_jd, hk.eps_fg_volt, LAYOUT = [1, 2, 1], FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Battery Voltage [V]', YRANGE = [6, 8.5])
p2 = plot(hk.time_jd, hk.eps_fg_soc, LAYOUT = [1, 2, 2], /CURRENT, MARGIN = [0.15, 0.25, 0.1, 0.1], FONT_SIZE = fontSize, $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, $
          YTITLE = 'Battery SoC [%]', YRANGE = [0, 100])
STOP          
; Save plot to disk
p1.save, saveloc + 'Battery Voltage and Soc Vs Time.png'


END