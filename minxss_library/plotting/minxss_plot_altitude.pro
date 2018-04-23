;+
; NAME:
;   minxss_plot_altitude
;
; PURPOSE:
;   Plot the altitude of MinXSS over time, fit an exponential to it, and predict the time to reach 300 km and 0 km
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:     Set this to either 1 or 2, corresponding to the flight model of MinXSS. Defaults to 1. 
;   saveloc [string]: The path to save the plot into. Defaults to current directory. 
;   
; KEYWORD PARAMETERS:
;   NO_SHOW_PLOT:    Set this to only create the plot in the z-buffer. Otherwise, plot will be displayed on screen. 
;   NO_FIT:          Set this to not do the exponential fit to the data
;   DARK_BACKGROUND: Set this to make a light plot against a dark background. Default is the opposite. 
;   ANIMATE:         Set this to create an animation of the MinXSS altitude
;   
; OUTPUTS:
;   Plot of altitude versus time with fit equation and predictions
;
; OPTIONAL OUTPUTS:
;   None
;   
; RESTRICTIONS:
;   Requires MinXSS level 0D data
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016-11-12: James Paul Mason: Wrote script.
;   2016-11-30: James Paul Mason: Added present altitude annotation. 
;   2017-05-10: James Paul Mason: Added DARK_BACKGROUND keyword
;   2017-06-02: James Paul Mason: Added ANIMATE keyword
;-
PRO minxss_plot_altitude, fm = fm, saveloc = saveloc, $
                          NO_SHOW_PLOT = NO_SHOW_PLOT, NO_FIT = NO_FIT, DARK_BACKGROUND = DARK_BACKGROUND, ANIMATE = ANIMATE

; Defaults
IF fm EQ !NULL THEN fm = 1
IF saveloc EQ !NULL THEN saveloc = './'
IF keyword_set(NO_SHOW_PLOT) THEN buffer = 1 ELSE buffer = 0
IF keyword_set(DARK_BACKGROUND) THEN BEGIN
  foregroundBlackOrWhite = 'white'
  backgroundColor = 'black'
ENDIF ELSE BEGIN
  foregroundBlackOrWhite = 'black'
  backgroundColor = 'white'
ENDELSE

; Convert fm to a string since that's all it will be used as
fm = strtrim(fm, 2)

; Restore level 0D data
restore, getenv('minxss_data') + '/fm' + fm + '/level0c/minxss' + fm + '_l0c_all_mission_length.sav'

; Grab relevant variables
altitude = minxss_get_altitude(timeJd = hk.time_jd)
timeJd = hk.time_jd
timeRelative = timeJd - timeJd[0]

; Remove NANs
finiteIndices = where(finite(altitude) AND altitude LT 450 AND altitude GT 0)
altitude = altitude[finiteIndices]
timeJd = timeJd[finiteIndices]
timeRelative = timeRelative[finiteIndices]

IF NOT keyword_set(NO_FIT) THEN BEGIN
  ; Fit the data with an exponential
  fitParameters = comfit(timeRelative, altitude, [-1., 1., 400.], /EXPONENTIAL, YFIT = fitAltitude, STATUS = status)
  
  ; Predicted altitude on 2017-06-01, the date JSpOC predicts deorbit
  altitude20170601 = fitParameters[0] * fitParameters[1]^366d + fitParameters[2]
  
  ; Determine time to 300 km and 0 km
  timeTo300km = alog((300. - fitParameters[2]) / fitParameters[0]) / alog(fitParameters[1]) ; [days]
  timeTo0km = alog((0. - fitParameters[2]) / fitParameters[0]) / alog(fitParameters[1]) ; [days]
  
  ; Convert time relative to absolute date
  date300km = JPMjd2yyyymmdd((timeJd[0] + timeTo300km), /RETURN_STRING)
  date0km = JPMjd2yyyymmdd((timeJd[0] + timeTo0km), /RETURN_STRING)
  
  ; Run the extrapolation out to 2017-06-01 where JSpOC predicts deorbit
  timeRelativeExtrapolated = findgen(367)
  timeJdExtrapolated = JPMrange(timejd[0], timejd[0] + 366, inc = 1)
  altitudeExtrapolated = fitParameters[0] * fitParameters[1]^timeRelativeExtrapolated + fitParameters[2]
ENDIF

; Plot the data
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
;w = window(BACKGROUND_COLOR = backgroundColor)
;p1 = plot(timeJd, altitude, COLOR = foregroundBlackOrWhite, FONT_COLOR = foregroundBlackOrWhite, BUFFER = buffer, /CURRENT, $
;          TITLE = 'MinXSS-' + fm + ' Altitude Decay', $
;          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, XCOLOR = foregroundBlackOrWhite, $
;          YTITLE = 'Altitude [km]', YRANGE = [150, 420], YCOLOR = foregroundBlackOrWhite)
;IF NOT keyword_set(NO_FIT) THEN BEGIN
;  p2 = plot(timeJdExtrapolated, altitudeExtrapolated, '2--', COLOR = 'dodger blue', /OVERPLOT)
;  p3 = symbol(timeJd[-1], fitAltitude[-1], 'star', /DATA, SYM_COLOR = 'lime green', SYM_SIZE = 3, /SYM_FILLED, /OVERPLOT)
;  poly = polygon([p1.xrange, reverse(p1.xrange)], [altitude20170601, altitude20170601, p1.yrange[0], p1.yrange[0]], /DATA, COLOR = 'tomato', /OVERPLOT, $
;                 /FILL_BACKGROUND, FILL_COLOR = 'tomato', FILL_TRANSPARENCY = 60)
;  t1 = text(0.6, 0.8, 'y = ' + JPMPrintNumber(fitParameters[0]) + ' * ' + JPMPrintNumber(fitParameters[1]) + '$^{x}$ + ' + JPMPrintNumber(fitParameters[2]), COLOR = 'dodger blue')
;  t2 = text(JPMiso2jd('2017-06-01'), altitude20170601 - 7, 'deorbit', /DATA, ALIGNMENT = 1, COLOR = 'white')
;  t3 = text(timeJd[-300], min(altitude) - 5., 'present altitude = ' + JPMPrintNumber(fitAltitude[-1], /NO_DECIMALS) + ' km', /DATA, ALIGNMENT = 1, COLOR = 'lime green')
;ENDIF ELSE BEGIN
;  t3 = text(timeJd[-300], min(altitude) - 5., 'last known altitude = ' + JPMPrintNumber(min(altitude), /NO_DECIMALS) + ' km', /DATA, ALIGNMENT = 1, COLOR = foregroundBlackOrWhite)
;ENDELSE
;
;; Save plot
;p1.save, saveloc + strmid(JPMsystime(), 0, 10) + ' MinXSS-1 Mission Altitude.png', /TRANSPARENT

IF keyword_set(ANIMATE) THEN BEGIN
  ; Set up movie
  movieObject = IDLffVideoWrite('Altitude Movie.mp4')
  vidStream = movieObject.AddVideoStream(600, 600, 30, BIT_RATE = 2e3)
  
  ; Set up plot
  w = window(DIMENSIONS = [600, 600], BACKGROUND_COLOR = backgroundColor, BUFFER = buffer)
  p1 = plot(timeJd[0:1], altitude[0:1], COLOR = foregroundBlackOrWhite, FONT_COLOR = foregroundBlackOrWhite, BUFFER = buffer, FONT_SIZE = 16, MARGIN = [0.2, 0.15, 0.1, 0.1], /CURRENT, $
            TITLE = 'MinXSS-' + fm + ' Altitude Decay', $
            XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 2, XCOLOR = foregroundBlackOrWhite, $
            YTITLE = 'Altitude [km]', YRANGE = [150, 420], YCOLOR = foregroundBlackOrWhite)
  t3 = text(0.87, 0.19, 'last known altitude = ' + JPMPrintNumber(min(altitude[0:1]), /NO_DECIMALS) + ' km', ALIGNMENT = 1, FONT_SIZE = 14, COLOR = foregroundBlackOrWhite)

  ; Loop through each day and add data to plot
  FOR i = 0, n_elements(timeJd) - 1, 500 DO BEGIN
    IF i + 500 GT n_elements(timeJd) THEN BEGIN
      i = n_elements(timejd) - 1
    ENDIF
    p1.SetData, timeJd[0:i], altitude[0:i]
    t3.string = 'last known altitude = ' + JPMPrintNumber(min(altitude[0:i]), /NO_DECIMALS) + ' km'
    
    ; Insert frame into movie
    timeInMovie = movieObject.Put(vidStream, p1.CopyWindow()) ; time returned in seconds
    
    IF i MOD 30 EQ 0 THEN message, /INFO, JPMsystime() + ' Movie progress: ' + JPMPrintNumber(float(i) / (n_elements(timeJd) - 1) * 100.) + '%'
  ENDFOR
  
movieObject.Cleanup

ENDIF



END