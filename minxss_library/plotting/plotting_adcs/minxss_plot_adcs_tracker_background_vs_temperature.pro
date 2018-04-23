;+
; NAME:
;   minxss_plot_adcs_tracker_background_vs_temperature
;
; PURPOSE:
;   Plot the star tracker median background level vs temperature
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
;   Plot the star tracker median background level vs temperature
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
;   2017-01-10: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_tracker_background_vs_temperature, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Compute Pearson correlation coefficient
pcc = correlate(adcs3.tracker_detector_temp, adcs3.tracker_median_mean_background)

; Create plots versus temperature 
p1 = plot(adcs3.tracker_detector_temp, adcs3.tracker_median_mean_background, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dark grey', MARGIN = [0.15, 0.1, 0.1, 0.1], FONT_SIZE = fontSize,  $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTITLE = 'Temperature [ºC]', XRANGE = [-10, 30], $
          YTITLE = 'Star Tracker Median Background [counts]', $
          NAME = 'raw')
t1 = text(0.8, 0.8, 'PCC = ' + JPMPrintNumber(pcc), ALIGNMENT = 1, FONT_SIZE = fontSize - 2)

; Save plot to disk
p1.save, saveloc + 'Tracker Background Vs Temperature.png'

END