;+
; NAME:
;   minxss_plot_adcs_filter_residual_vs_time
;
; PURPOSE:
;   Plot the Kalman filter residual as a function of time
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
;   Plot of filter residual vs time
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
;   2016-12-28: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_filter_residual_vs_time, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Compute statistics
meanResidual1 = mean(adcs1.attitude_filter_residual1)
standardDeviationResidual1 = stddev(adcs1.attitude_filter_residual1)
meanResidual2 = mean(adcs2.attitude_filter_residual2)
standardDeviationResidual2 = stddev(adcs2.attitude_filter_residual2)
meanResidual3 = mean(adcs2.attitude_filter_residual3)
standardDeviationResidual3 = stddev(adcs2.attitude_filter_residual3)

; Create plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(adcs1.time_jd, adcs1.attitude_filter_residual1, '2', SYMBOL = 'square', /SYM_FILLED, COLOR = 'tomato', $ 
          TITLE = 'MinXSS-1 On-Orbit', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = 'Kalman Filter Residual [rad]', YRANGE = [-5e-3, 5e-3], $ 
          NAME = '1')
p2 = plot(adcs2.time_jd, adcs2.attitude_filter_residual2, '2', SYMBOL = '*', COLOR = 'lime green', /OVERPLOT, $ 
          NAME = '2')
p3 = plot(adcs2.time_jd, adcs2.attitude_filter_residual3, '2', SYMBOL = 'diamond', COLOR = 'dodger blue', /OVERPLOT, $
          NAME = '3')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.88, 0.84])
t1a = text(0.15, 0.22, '$\mu$ = ' + JPMPrintNumber(meanResidual1, /SCIENTIFIC), COLOR = 'tomato')
t1b = text(0.15, 0.18, '$\sigma$ = ' + JPMPrintNumber(standardDeviationResidual1, /SCIENTIFIC), COLOR = 'tomato')
t2a = text(0.35, 0.22, '$\mu$ = ' + JPMPrintNumber(meanResidual2, /SCIENTIFIC), COLOR = 'lime green')
t2b = text(0.35, 0.18, '$\sigma$ = ' + JPMPrintNumber(standardDeviationResidual2, /SCIENTIFIC), COLOR = 'lime green')
t3a = text(0.55, 0.22, '$\mu$ = ' + JPMPrintNumber(meanResidual3, /SCIENTIFIC), COLOR = 'dodger blue')
t3b = text(0.55, 0.18, '$\sigma$ = ' + JPMPrintNumber(standardDeviationResidual3, /SCIENTIFIC), COLOR = 'dodger blue')

; Save plot to disk
p1.save, saveloc + 'Filter Residual Vs Time.png'

END