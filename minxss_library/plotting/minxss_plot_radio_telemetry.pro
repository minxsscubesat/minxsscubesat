;+
; NAME:
;   minxss_plot_radio_telemetry
;
; PURPOSE:
;   Make a few plots from the flight Li-1 radio to assess its performance
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Some plots on screen
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data and MinXSS code package
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2017-01-17: James Paul Mason: Wrote script.
;-
PRO minxss_plot_radio_telemetry

; Restore the data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Dates of interest for Li-1 latch up
startJd = JPMiso2jd('2017-01-02T00:00:00Z')
endJd = JPMiso2jd('2017-01-14T12:59:59Z')

; Restrict data to time range 
hk = hk[where(hk.time_jd GE startJd AND hk.time_jd LE endJd)]

; Plot radio received
labelDate = label_date(DATE_FORMAT = ['%D', '%Y %M'])
p1 = plot(hk.time_jd, hk.radio_received, '2*--', $
          TITLE = 'MinXSS-1 Li-1 Radio Upset', $
          XTICKINTERVAL = 1, XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'Radio Received [bytes]', $
          NAME = 'Actual')
p2 = plot(hk.time_jd, hk.radio_received - 225000., '2*--', COLOR = 'tomato', /OVERPLOT, $
          NAME = '-225,000 Offset')
l1 = legend(TARGET = [p1, p2], POSITION = [0.45, 0.3])

; Plot radio transmitted
p3 = plot(hk.time_jd, hk.radio_transmitted, '2*--', $
          TITLE = 'MinXSS-1 Li-1 Radio Upset', $
XTICKINTERVAL = 1, XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'Radio Transmitted [bytes]', $
          NAME = 'Actual')
p4 = plot(hk.time_jd, hk.radio_transmitted - 1.45e8, '2*--', COLOR = 'tomato', /OVERPLOT, $
         NAME = '-1.45e8 Offset')
l2 = legend(TARGET = [p3, p4], POSITION = [0.45, 0.3])

; Plot temperature 
p5 = plot(hk.time_jd, hk.radio_temp, '2*--', $
          TITLE = 'MinXSS-1 Li-1 Radio Upset', $
          XTICKINTERVAL = 1, XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Day', 'Month', 'Year'], $
          YTITLE = 'Temperature [ºC]', $
          NAME = 'Radio Internal')
p6 = plot(hk.time_jd, hk.cdh_temp, '2*--', COLOR = 'tomato', /OVERPLOT, $
          NAME = 'CDH')          
l3 = legend(TARGET = [p5, p6], POSITION = [0.45, 0.88])

STOP

END