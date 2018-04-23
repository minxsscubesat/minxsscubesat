;+
; NAME:
;   minxss_plot_beta
;
; PURPOSE:
;   Create a plot of beta over the mission
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot into. Defaults to current directory. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot of beta over the mission
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss_get_beta and dependencies therein
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-03-24: James Paul Mason: Wrote script.
;-
PRO minxss_plot_beta, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN saveloc = './'

jdBeta = minxss_get_beta()

; Compute beta where fully sunlit
restore, getenv('minxss_data') + '/fm1/level0d/minxss1_l0d_mission_length.sav'
minxsslevel0d = minxsslevel0d[where(minxsslevel0d.altitude GT 0 AND minxsslevel0d.altitude LT 450)] ; Get rid of bad data
altitude = minxsslevel0d.altitude
timeRelative = minxsslevel0d.time.jd - minxsslevel0d[0].time.jd
fitParameters = comfit(timeRelative, altitude, [-1., 1., 400.], /EXPONENTIAL, YFIT = fitAltitude, STATUS = status)
altitudeFit = fitParameters[0] * fitParameters[1]^timeRelative + fitParameters[2]
earthRadius = 6371.
fullySunlitBeta = asin(earthRadius / (earthRadius + altitudeFit)) * !RADEG

labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(jdBeta.jd, jdBeta.beta, '2', $
          TITLE = 'MinXSS-1 Mission Length $\beta$ Angle', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = '$\beta$ [º]', YRANGE = [0, 90])
p2 = plot(jdBeta.jd, fullySunlitBeta, '--', COLOR = 'tomato', /OVERPLOT, $
          XRANGE = p1.xrange)
t2 = text(0.65, 0.72, 'fully sunlit', COLOR = 'tomato')

; Save plot
p1.save, saveloc + strmid(JPMsystime(), 0, 10) + ' MinXSS-1 Mission Beta.png'

END