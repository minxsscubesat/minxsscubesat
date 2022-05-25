;+
; NAME:
;   minxss_make_spectrum_movie
;
; PURPOSE:
;   Create a movie of MinXSS spectra through time
;
; INPUTS:
;   
;
; OPTIONAL INPUTS:
;   timeRange [double, double] or [string, string]: The date and time to bound the movie. Defaults to whole mission.
;                                                   Double format is for jd and string format is for human time (yyyy-mm-dd hh:mm:ss).
;   dimensions [integer, integer]:                  Pixel dimensions for the movie. Defaults to [800, 600].
;   
; KEYWORD PARAMETERS:
;   DARK_BACKGROUND: Set this to make a light plot against a dark background. Default is the opposite. 
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
;
; RESTRICTIONS:
;
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2017-04-27: James Paul Mason: Wrote script.
;-
PRO minxss_make_spectrum_movie, timeRange = timeRange, dimensions = dimensions, fm=fm, $
                                PREFLARE_SUBTRACT = PREFLARE_SUBTRACT, DARK_BACKGROUND = DARK_BACKGROUND

; Defaults
IF timeRange NE !NULL THEN BEGIN
  IF typename(timeRange[0]) EQ 'STRING' THEN BEGIN
    timeRange[0] = JPMyyyymmddhhmmss2jd(timeRange[0])
    timeRange[1] = JPMyyyymmddhhmmss2jd(timeRange[1])
  ENDIF
ENDIF
IF dimensions EQ !NULL THEN dimensions = [700, 700]
IF keyword_set(DARK_BACKGROUND) THEN BEGIN
  foregroundBlackOrWhite = 'white'
  backgroundColor = 'black'
ENDIF ELSE BEGIN
  foregroundBlackOrWhite = 'black'
  backgroundColor = 'white'
ENDELSE
IF fm EQ !NULL THEN fm = 1

; Setup
dataloc = '/Users/' + getenv('username') + '/Dropbox/Research/Data/EVE-GOES-MinXSS/'
saveloc = '/Users/' + getenv('username') + '/Dropbox/Research/Postdoc_LASP/Analysis/MinXSS-EVE Big Flare/'

; Movie configuration
movieObject = IDLffVideoWrite(saveloc + 'Spectrum Movie.mp4')
xsize = 800
ysize = 600
fps = 3
bitrate = 1e7
vidStream = movieObject.AddVideoStream(xsize, ysize, fps, BIT_RATE = bitrate)

; Restore data
restore, getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level1/minxss' + strtrim(fm, 2) + '_l1_mission_length.sav'

;
; Loop through the MinXSS spectra and plot
;

FOR spectrumIndex = 1, n_elements(minxsslevel1) - 1 DO BEGIN
  ; Optionally normalize everything by pre-flare so that the irradiance units are comparable
  IF keyword_set(PREFLARE_SUBTRACT) THEN BEGIN
    minxssIrradiance = minxsslevel1[spectrumIndex].irradiance - minxsslevel1[0].irradiance
  ENDIF
  
  ; Present plot
  !EXCEPT = 0 ; Disable annoying error messages
  w = window(DIMENSIONS = [800, 600], /BUFFER)
  p1a = plot(minxsslevel1[spectrumIndex].energy, minxssIrradiance, '2', COLOR = 'dodger blue', LAYOUT = [1, 2, 2], /CURRENT, MARGIN = 0.15, $
             AXIS_STYLE = 1, $
             XTITLE = 'Energy [keV]', XRANGE = [0.01, 10], /XLOG, $
             YTITLE = 'Irradiance [W m$^{-2}$ nm$^{-1}$]', /YLOG, YRANGE = [1e-20, 1e0], $
             NAME = 'MinXSS-1 X123')
  p1a.save, saveloc + 'Spectrum ' + minxss[spectrumIndex].time.human + '.png', /TRANSPARENT
  !EXCEPT = 1

  ; Insert frame into movie
  timeInMovie = movieObject.Put(vidStream, w.CopyWindow()) ; time returned in seconds
  w.close

ENDFOR

movieObject.Cleanup

END