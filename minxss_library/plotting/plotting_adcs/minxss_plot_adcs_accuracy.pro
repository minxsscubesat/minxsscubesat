;+
; NAME:
;   minxss_plot_adcs_accuracy
;
; PURPOSE:
;   Plot the pointing accuracy as a histogram
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
;   Plot of pointing accuracy histogram
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
;   2017-05-26: James Paul Mason: Updated to do histogram rather than time series
;-
PRO minxss_plot_adcs_accuracy, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF

; Setup
smoothNumberOfPoints = 500
rad2rpm = 9.54929659643
fwhm2sigma = 2.355
fontSize = 16

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Extract ADCS flags from adcs info
adcsMode = ISHFT(adcs3.adcs_info AND '01'X, 0) ; extract 1-bit flag

; Filter for only data in fine reference mode for at least the last 5 minutes
fineRefIndices = where(adcsMode EQ 1)
adcs3 = adcs3[fineRefIndices]

; Create histogram data
xHistogram = histogram(adcs3.attitude_error1 * !RADEG, BINSIZE = 1. / 3600., LOCATIONS = xBins) ; This XACT telemetry is in MinXSS body-frame
yHistogram = histogram(adcs3.attitude_error2 * !RADEG, BINSIZE = 1. / 3600., LOCATIONS = yBins) ; This XACT telemetry is in MinXSS body-frame
zHistogram = histogram(adcs3.attitude_error3 * !RADEG, BINSIZE = 1. / 3600., LOCATIONS = zBins) ; This XACT telemetry is in MinXSS body-frame

; Determine the sigma value
xUpperIndices = where(xHistogram GE max(xHistogram) / 2.)
xFwhm = max(xBins[xUpperIndices]) - min(xBins[xUpperIndices])
xSigma = xFwhm / fwhm2sigma
yUpperIndices = where(yHistogram GE max(yHistogram) / 2.)
yFwhm = max(yBins[yUpperIndices]) - min(yBins[yUpperIndices])
ySigma = yFwhm / fwhm2sigma
zUpperIndices = where(zHistogram GE max(zHistogram) / 2.)
zFwhm = max(zBins[zUpperIndices]) - min(zBins[zUpperIndices])
zSigma = zFwhm / fwhm2sigma

; Plot histograms
p1 = plot(xBins, xHistogram, COLOR = 'tomato', /HISTOGRAM, THICK = 2, POSITION = [0.15, 0.70, 0.95, 0.99], FONT_SIZE = fontSize, $
          XTITLE = 'Pointing Error [º]', XRANGE = [-0.05, 0.05], XSHOWTEXT = 0, $
          YTITLE = '#', YRANGE = [-100, 1600], $
          NAME = 'X')
p2 = plot(yBins, yHistogram, COLOR = 'lime green', /HISTOGRAM, THICK = 2, POSITION = [0.15, 0.40, 0.95, 0.68], /CURRENT, FONT_SIZE = fontSize, $
           XTITLE = 'Pointing Error [º]', XRANGE = [-0.05, 0.05], XSHOWTEXT = 0, $
           YTITLE = '#', YRANGE = [-100, 700], $
           NAME = 'Y')
p3 = plot(zBins, zHistogram, COLOR = 'dodger blue', /HISTOGRAM, THICK = 2, POSITION = [0.15, 0.1, 0.95, 0.38], /CURRENT, FONT_SIZE = fontSize,$
           XTITLE = 'Pointing Error [º]', XRANGE = [-0.05, 0.05], $
           YTITLE = '#', YRANGE = [-100, 1200], $
           NAME = 'Z')
l1 = legend(POSITION = [0.94, 0.65], TARGET = [p1, p2, p3], FONT_SIZE = fontSize - 2)
t1 = text(0.17, 0.92, '3$\sigma$ = ' + JPMPrintNumber(3 * xSigma, NUMBER_OF_DECIMALS = 4) + '$\deg$', COLOR = 'tomato', FONT_SIZE = fontSize - 2)
t2 = text(0.17, 0.58, '3$\sigma$ = ' + JPMPrintNumber(3 * ySigma, NUMBER_OF_DECIMALS = 4) + '$\deg$', COLOR = 'lime green', FONT_SIZE = fontSize - 2)
t3 = text(0.17, 0.31, '3$\sigma$ = ' + JPMPrintNumber(3 * zSigma, NUMBER_OF_DECIMALS = 4) + '$\deg$', COLOR = 'dodger blue', FONT_SIZE = fontSize -2)
STOP
; Save plot to disk
p1.save, saveloc + 'Accuracy Histogram.png'

END