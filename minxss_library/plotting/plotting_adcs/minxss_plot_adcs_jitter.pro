;+
; NAME:
;   minxss_plot_adcs_jitter
;
; PURPOSE:
;   Plot the pointing jitter as a function of time
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
;   Plot of pointing jitter vs time and optionally altitude
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
;   2017-05-19: James Paul Mason: Wrote script.
;   2017-05-26: James Paul Mason: Updated to generate a histogram rather than a time series.
;   2018-04-24: James Paul Mason: Added an additional plot based on the format used by JPL's ASTERIA CubeSat. https://www.jpl.nasa.gov/news/news.php?feature=7097 slide 2.
;-
PRO minxss_plot_adcs_jitter, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Setup
smoothNumberOfPoints = 500
rad2rpm = 9.54929659643
fwhm2sigma = 2.355
fontSize = 16
xyrange = [-0.05, 0.05]

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Extract ADCS flags from adcs info
adcs_mode = ISHFT(adcs3.adcs_info AND '01'X, 0) ; extract 1-bit flag

; Filter for only data in fine reference mode
fineRefIndices = where(adcs_mode EQ 1)
adcs3 = adcs3[fineRefIndices]

; Filter out eclipse data
insolatedIndices = where(adcs3.SUN_POINT_ANGLE_ERROR LT 180)
adcs3 = adcs3[insolatedIndices]
eclipseStateSwitchIndices = uniq(hk.ECLIPSE_STATE)
jdOfEclipseStateChange = hk[eclipseStateSwitchIndices].time_jd
insolatedIndices = !NULL
FOR i = 1, n_elements(jdOfEclipseStateChange) - 1 DO BEGIN
  t1 = jdOfEclipseStateChange[i-1]
  t2 = jdOfEclipseStateChange[i]
  IF hk[eclipseStateSwitchIndices[i-1] + 1].eclipse_state EQ 0 THEN BEGIN
    tmp = where(adcs3.time_jd GT t1 AND adcs3.time_jd LT t2)
    IF tmp NE [-1] THEN BEGIN
      insolatedIndices = insolatedIndices EQ !NULL ? tmp : [insolatedIndices, tmp]
    ENDIF
  ENDIF
ENDFOR
adcs3 = adcs3[insolatedIndices]

; Filter out bad tracker data
goodTrackerIndices = where(adcs3.TRACKER_ATTITUDE_STATUS EQ 0)
adcs3 = adcs3[goodTrackerIndices]

; Filter out cruciform data -- just based on times in event logs with adcs_cruciform_scan script since there is no flag to indicate a cruciform scan
excludeCruciform1Indices = where(adcs3.time_jd LT jpmiso2jd('2016-09-09T09:05:29Z') OR adcs3.time_jd GT jpmiso2jd('2016-09-09T10:05:29Z'))
adcs3 = adcs3[excludeCruciform1Indices]
excludeCruciform2Indices = where(adcs3.time_jd LT jpmiso2jd('2016-11-10T08:18:22Z') OR adcs3.time_jd GT jpmiso2jd('2016-11-10T09:18:22Z'))
adcs3 = adcs3[excludeCruciform2Indices]
excludeCruciform3Indices = where(adcs3.time_jd LT jpmiso2jd('2016-11-12T07:44:57Z') OR adcs3.time_jd GT jpmiso2jd('2016-11-12T08:44:57Z'))
adcs3 = adcs3[excludeCruciform3Indices]
excludeCruciform4Indices = where(adcs3.time_jd LT jpmiso2jd('2017-01-03T10:52:19Z') OR adcs3.time_jd GT jpmiso2jd('2017-01-03T11:52:19Z'))
adcs3 = adcs3[excludeCruciform4Indices]
excludeCruciform5Indices = where(adcs3.time_jd LT jpmiso2jd('2017-01-04T08:08:05Z') OR adcs3.time_jd GT jpmiso2jd('2017-01-04T09:08:05Z'))
adcs3 = adcs3[excludeCruciform5Indices]
excludeCruciform6Indices = where(adcs3.time_jd LT jpmiso2jd('2017-01-04T09:43:02Z') OR adcs3.time_jd GT jpmiso2jd('2017-01-04T10:43:02Z'))
adcs3 = adcs3[excludeCruciform6Indices]
STOP


; Determine jitter over 10-second period (MinXSS requirement)
timeJd = !NULL
FOR i = 0, n_elements(adcs3) - 1 DO BEGIN
  currentTime = adcs3[i].time
  within10SecondsIndices = where(adcs3.time GE currentTime AND adcs3.time LT currentTime + 10, numInBin)
  
  IF numInBin EQ 1 THEN CONTINUE
  
  minmax1 = minmax(-adcs3[within10SecondsIndices].attitude_error2 * !RADEG) ; MinXSS +X = XACT -Y
  minmax2 = minmax(adcs3[within10SecondsIndices].attitude_error1 * !RADEG)  ; MinXSS +Y = XACT +X
  minmax3 = minmax(adcs3[within10SecondsIndices].attitude_error3 * !RADEG)  ; MinXSS +Z = XACT +Z
  
  jitter1 = (jitter1 EQ !NULL) ? minmax1[1] - minmax1[0] : [jitter1, minmax1[1] - minmax1[0]]
  jitter2 = (jitter2 EQ !NULL) ? minmax2[1] - minmax2[0] : [jitter2, minmax2[1] - minmax2[0]]
  jitter3 = (jitter3 EQ !NULL) ? minmax3[1] - minmax3[0] : [jitter3, minmax3[1] - minmax3[0]]
  
  numPointsInBin = (numPointsINBin EQ !NULL) ? numInBin : [numPointsInBin, numInBin]
  
  timeJd = (timeJd EQ !NULL) ? adcs3[i].time_jd : [timeJd, adcs3[i].time_jd]
  
  i += numInBin
ENDFOR

; Create histogram data
xHistogram = histogram(jitter1, NBINS = 1000000, LOCATIONS = xBins)
yHistogram = histogram(jitter2, NBINS = 1000000, LOCATIONS = yBins)
zHistogram = histogram(jitter3, NBINS = 1000000, LOCATIONS = zBins)

; Determine the sigma value
; At what jitter value are 66% of the points captured
binIndex = 0
foundXSigma = 0
foundYSigma = 0
foundZSigma = 0
WHILE foundXSigma EQ 0 OR foundYSigma EQ 0 OR foundZSigma EQ 0 DO BEGIN
  IF foundXSigma EQ 0 AND total(xHistogram[0:binIndex]) / total(xHistogram) GE 0.66 THEN BEGIN
    foundXSigma = 1
    xSigma = xBins[binIndex]
  ENDIF
  IF foundYSigma EQ 0 AND total(yHistogram[0:binIndex]) / total(yHistogram) GE 0.66 THEN BEGIN
    foundYSigma = 1
    ySigma = yBins[binIndex]
  ENDIF
  IF foundZSigma EQ 0 AND total(zHistogram[0:binIndex]) / total(zHistogram) GE 0.66 THEN BEGIN
    foundZSigma = 1
    zSigma = zBins[binIndex]
  ENDIF
  
  binIndex++
ENDWHILE

; Plot histograms
p1 = plot(xBins, xHistogram, COLOR = 'tomato', /HISTOGRAM, THICK = 2, LAYOUT = [1, 3, 1], FONT_SIZE = fontSize, $
          XTITLE = 'Jitter [º (10 s$^{-1}$)]', XRANGE = [0, 0.05], $
          YTITLE = '#', $
          NAME = 'X')
p2 = plot(yBins, yHistogram, COLOR = 'lime green', /HISTOGRAM, THICK = 2, LAYOUT = [1, 3, 2], /CURRENT, FONT_SIZE = fontSize, $
          XTITLE = 'Jitter [º (10 s$^{-1}$)]', XRANGE = [0, 0.05], $
          YTITLE = '#', $
          NAME = 'Y')
p3 = plot(zBins, zHistogram, COLOR = 'dodger blue', /HISTOGRAM, THICK = 2, LAYOUT = [1, 3, 3], /CURRENT, FONT_SIZE = fontSize, $
          XTITLE = 'Jitter [º (10 s$^{-1}$)]', XRANGE = [0, 0.05], $
          YTITLE = '#', $
          NAME = 'Z')
l1 = legend(POSITION = [0.26, 0.41], TARGET = [p1, p2, p3], FONT_SIZE = fontSize - 2)
t1 = text(0.25, 0.87, '3$\sigma$ = ' + JPMPrintNumber(3 * xSigma, NUMBER_OF_DECIMALS = 4) + '$\deg$ (10 s$^{-1}$)', COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t2 = text(0.25, 0.55, '3$\sigma$ = ' + JPMPrintNumber(3 * ySigma, NUMBER_OF_DECIMALS = 4) + '$\deg$ (10 s$^{-1}$)', COLOR = 'lime green', FONT_SIZE = fontSize - 2)
t3 = text(0.25, 0.21, '3$\sigma$ = ' + JPMPrintNumber(3 * zSigma, NUMBER_OF_DECIMALS = 4) + '$\deg$ (10 s$^{-1}$)', COLOR = 'dodger blue', FONT_SIZE = fontSize - 2)

; Save plot to disk
p1.save, saveloc + 'Jitter Histogram.png'

; Solar pointing error in degrees
yError = adcs3.attitude_error1 * !RADEG ; MinXSS +Y = XACT +X
zError = adcs3.attitude_error3 * !RADEG ; MinXSS +Z = XACT +Z

; Statistics on number of points within sigma circles
tmp = where(yError LT 1 * ysigma AND zError LT 1 * zsigma, numberOfPointsIn1Sigma)
tmp = where(yError LT 2 * ysigma AND zError LT 2 * zsigma, numberOfPointsIn2Sigma)
tmp = where(yError LT 3 * ysigma AND zError LT 3 * zsigma, numberOfPointsIn3Sigma)
percentOfPointsIn1Sigma = float(numberOfPointsIn1Sigma) / n_elements(yError) * 100.
percentOfPointsIn2Sigma = float(numberOfPointsIn2Sigma) / n_elements(yError) * 100.
percentOfPointsIn3Sigma = float(numberOfPointsIn3Sigma) / n_elements(yError) * 100.

; Find 1, 2, and 3 sigma circles
;FOR sigma = 0., 0.06, 0.001 DO BEGIN
;  tmp = where(yError LT 1 * sigma AND zError LT 1 * sigma, numberOfPointsIn1Sigma)
;  tmp = where(yError LT 2 * sigma AND zError LT 2 * sigma, numberOfPointsIn2Sigma)
;  tmp = where(yError LT 3 * sigma AND zError LT 3 * sigma, numberOfPointsIn3Sigma)
;  percentOfPointsIn1SigmaTmp = float(numberOfPointsIn1Sigma) / n_elements(yError) * 100.
;  percentOfPointsIn2SigmaTmp = float(numberOfPointsIn2Sigma) / n_elements(yError) * 100.
;  percentOfPointsIn3SigmaTmp = float(numberOfPointsIn3Sigma) / n_elements(yError) * 100.
;  
;  IF percentOfPointsIn1SigmaTmp GT 67 AND percentOfPointsIn1SigmaTmp LT 69 THEN BEGIN
;    percentOfPointsIn1Sigma = percentOfPointsIn1SigmaTmp
;    oneSigma = sigma
;  ENDIF
;  IF percentOfPointsIn2SigmaTmp GT 94 AND percentOfPointsIn2SigmaTmp LT 96 THEN BEGIN
;    percentOfPointsIn2Sigma = percentOfPointsIn2SigmaTmp
;    twoSigma = sigma
;  ENDIF
;  IF percentOfPointsIn3SigmaTmp GT 99 AND percentOfPointsIn3SigmaTmp LT 100 THEN BEGIN
;    percentOfPointsIn3Sigma = percentOfPointsIn3SigmaTmp
;    threeSigma = sigma
;    BREAK
;  ENDIF
;ENDFOR

; Plot just like ASTERIA from JPL: https://www.jpl.nasa.gov/news/news.php?feature=7097
p2 = scatterplot(yError, zError, FONT_SIZE = fontSize, AXIS_STYLE = 3, $
                 SYMBOL = 'circle', SYM_SIZE = 0.7, /SYM_FILLED, SYM_TRANSPARENCY = 80, $
                 XRANGE = xyrange, XTICKVALUES = [-0.04, -0.02, 0.02, 0.04], $
                 YRANGE = xyrange, YTICKVALUES = [-0.04, -0.02, 0.02, 0.04])
xtitle = text(0.5, 0.02, 'Pointing Error [º]', ALIGNMENT = 0.5, FONT_SIZE = fontSize - 2)
ytitle = text(0.03, 0.5, 'Pointing Error [º]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize - 2)
c1 = ellipse(0, 0, MAJOR = ysigma, MINOR = zsigma, /DATA, THICK = 2, FILL_BACKGROUND = 0, COLOR = 'lime green', NAME = '1')
c2 = ellipse(0, 0, MAJOR = 2 * ysigma, MINOR = 2 * zsigma, /DATA, THICK = 2, FILL_BACKGROUND = 0, COLOR = 'gold', NAME = '2')
c3 = ellipse(0, 0, MAJOR = 3 * ysigma, MINOR = 3 * zsigma, /DATA, THICK = 2, FILL_BACKGROUND = 0, COLOR = 'tomato', NAME = '3')
l1 = text(0.85, 0.89, JPMPrintNumber(percentOfPointsIn1Sigma, /NO_DECIMALS) + '%', COLOR = c1.color, FONT_SIZE = fontSize - 4)
l2 = text(0.85, 0.85, JPMPrintNumber(percentOfPointsIn2Sigma, /NO_DECIMALS) + '%', COLOR = c2.color, FONT_SIZE = fontSize - 4)
l3 = text(0.85, 0.81, JPMPrintNumber(percentOfPointsIn3Sigma, /NO_DECIMALS) + '%', COLOR = c3.color, FONT_SIZE = fontSize - 4)
p2.save, saveloc + 'Jitter Zoom.png'

; Same plot but with whole sun size shown for scale
p3 = scatterplot(yError, zError, FONT_SIZE = fontSize, AXIS_STYLE = 3, ASPECT_RATIO = 1, $
                 SYMBOL = 'circle', SYM_SIZE = 0.7, /SYM_FILLED, SYM_TRANSPARENCY = 80, $
                 XRANGE = [-0.5, 0.5], XCOLOR = 'dark grey', $
                 YRANGE = [-0.5, 0.5], YCOLOR = 'dark grey')
xtitle = text(0.5, 0.02, 'Pointing Error [º]', ALIGNMENT = 0.5, FONT_SIZE = fontSize - 2)
ytitle = text(0.03, 0.5, 'Pointing Error [º]', ALIGNMENT = 0.5, ORIENTATION = 90, FONT_SIZE = fontSize - 2)
c3 = ellipse(0, 0, MAJOR = 3 * ysigma, MINOR = 3 * zsigma, /DATA, THICK = 2, FILL_BACKGROUND = 0, COLOR = 'tomato')
c4 = ellipse(0, 0, MAJOR = 0.265, MINOR = 0.265, /DATA, THICK = 2, FILL_COLOR = 'gold', COLOR = 'gold')
c4.Order, /SEND_TO_BACK
l1 = text(0.85, 0.89, 'Sun', COLOR = c4.color, FONT_SIZE = fontSize - 4)
l2 = text(0.85, 0.85, JPMPrintNumber(percentOfPointsIn3Sigma, /NO_DECIMALS) + '%', COLOR = c3.color, FONT_SIZE = fontSize - 4)
p3.save, saveloc + 'Jitter Wide.png'

END