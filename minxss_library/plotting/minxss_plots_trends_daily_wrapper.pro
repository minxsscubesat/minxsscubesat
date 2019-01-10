;+
; NAME:
;   minxss_plots_trends_daily_wrapper
;
; PURPOSE:
;   A wrapper for minxss_plots_trends that will produce a PDF for each day of the mission
;   and the a single of plots spanning the whole mission
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
;   PDF files in Dropbox/minxss_dropbox/data/fm2/trends/hk/ (not bothering with fm1 since this code was written long after MinXSS-1 ended
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires that the minxss_dropbox environment variable has been set
;
; EXAMPLE:
;   Just run it! 
;
;-
PRO minxss_plots_trends_daily_wrapper

; Make an array with the date of each day of the mission
startjd = jpmiso2jd('2018-12-03T21:28:22Z')
endjd = systime(/JULIAN, /UTC)
datesOfMission = JPMjd2yyyymmdd(timegen(start=startjd, final=endjd, units='Days'))

; Loop the PDF plotter for each day
FOREACH date, datesOfMission DO BEGIN
  minxss_plots_trends, fm=2, timeRange=date, level = 'C', /PDF, /VERBOSE
ENDFOREACH

; Produce the mission length PDF
minxss_plots_trends, fm=2, /MISSION_LENGTH, level = 'C', /PDF, /VERBOSE

END