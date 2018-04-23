;+
; NAME:
;   minxss_plot_adcs_tracker_background_vs_time
;
; PURPOSE:
;   Plot the star tracker median background level vs time
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
;   Plot the star tracker median background level vs time
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
;   2017-01-09: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_tracker_background_vs_time, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
smoothNumberOfPoints = 1000
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Smooth the data
trackerGoodIndices = where(adcs3.tracker_median_mean_background GT 0 AND adcs3.tracker_median_mean_background LT 200)
trackerSmooth = smooth(adcs3[trackerGoodIndices].tracker_median_mean_background, smoothNumberOfPoints)

; Linear fit to the data
trackerFit = linfit(adcs3[trackerGoodIndices].time_jd, adcs3[trackerGoodIndices].tracker_median_mean_background)

; Create plots versus time
labelDate = label_date(DATE_FORMAT = ['%M', '%Y']) 
p1 = plot(adcs3.time_jd, adcs3.tracker_median_mean_background, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'dark grey', FONT_SIZE = fontSize, $
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, MARGIN = [0.15, 0.15, 0.1, 0.1], $
          YTITLE = 'Star Tracker Median Background [counts]', $
          NAME = 'raw')
p1a = plot(adcs3[trackerGoodIndices].time_jd, trackerSmooth, '2', COLOR = 'black', /OVERPLOT, $
           NAME = 'smooth*')
l1 = legend(TARGET = [p1, p1a], POSITION = [0.40, 0.85], FONT_SIZE = fontSize - 2)
t0 = text(0.77, 0.75, '*' + JPMPrintNumber(smoothNumberOfPoints, /NO_DECIMALS) + ' pt boxcar smooth', ALIGNMENT = 1, FONT_SIZE = fontSize - 2)
t1 = text(0.42, 0.79, 'Slope = ' + JPMPrintNumber(trackerFit[1] * 365.15) + ' counts/year', COLOR = 'black', FONT_SIZE = fontSize - 2)

; Save plot to disk
p1.save, saveloc + 'Tracker Background Vs Time.png'

END