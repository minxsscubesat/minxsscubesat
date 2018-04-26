;+
; NAME:
;   minxss_make_sps_movie
;
; PURPOSE:
;   Make a movie of SPS data plotted using bubbleplot
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   timeRange [double, double] or [string, string]: The date and time to bound the movie. Defaults to whole mission. 
;                                                   Double format is for jd and string format is for human time (yyyy-mm-dd hh:mm:ss). 
;   fm [integer]:                                   The flight model to plot. Defaults to 1.
;   dimensions [integer, integer]:                  Pixel dimensions for the movie. Defaults to [700, 700]. 
;   
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Creates a movie in the current folder of a bubbleplot animated through time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS IDL software package
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016/08/03: James Paul Mason: Wrote script.
;-
PRO minxss_make_sps_movie, timeRange = timeRange, fm = fm, dimensions = dimensions, DARK_BACKGROUND = DARK_BACKGROUND

; Defaults
IF timeRange NE !NULL THEN BEGIN
  IF typename(timeRange[0]) EQ 'STRING' THEN BEGIN
    timeRange[0] = JPMyyyymmddhhmmss2jd(timeRange[0])
    timeRange[1] = JPMyyyymmddhhmmss2jd(timeRange[1])
  ENDIF
ENDIF
IF fm EQ !NULL THEN fm = 1
IF dimensions EQ !NULL THEN dimensions = [700, 700]
IF keyword_set(DARK_BACKGROUND) THEN BEGIN
  foregroundBlackOrWhite = 'white'
  backgroundColor = 'black'
ENDIF ELSE BEGIN
  foregroundBlackOrWhite = 'black'
  backgroundColor = 'white'
ENDELSE

; Restore level 0C
restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss1_l0c_all_mission_length.sav'

; Convert time range to index range and truncate array accordingly
IF timeRange EQ !NULL THEN selectedRangeIndices = [0:n_elements(hk)] $
ELSE selectedRangeIndices = where(hk.time_jd GT timeRange[0] AND hk.time_jd LT timeRange[1])
hk = hk[selectedRangeIndices]

; Filter out times with no SPS data
validSpsIndices = where(hk.sps_x NE 0 AND hk.sps_y NE 0 AND hk.sps_sum NE 0)
hk = hk[validSpsIndices]

; Extract needed variables
time_human = hk.time_human
time_jd = hk.time_jd
sps_y = hk.sps_x / 10000. * 3.0
sps_z = hk.sps_y / 10000. * 3.0
sps_sum = hk.sps_sum
adcs_mode = hk.adcs_mode

; Set bubble color to gold when in fine reference mode and blue when in coarse sun point mode
bubble_color = strarr(n_elements(adcs_mode))
bubble_color[where(adcs_mode EQ 0)] = 'dodger blue'
bubble_color[where(adcs_mode EQ 1)] = 'gold'

; Setup movie
movieObject = IDLffVideoWrite('SPS Movie.mp4')
vidStream = movieObject.AddVideoStream(dimensions[0], dimensions[1], 30, BIT_RATE = 2e3)

w = window(DIMENSIONS = dimensions, BACKGROUND_COLOR = backgroundColor, /BUFFER)
p1 = bubbleplot(sps_y[0], sps_z[0], MAGNITUDE = sps_sum[0], EXPONENT = 0.5, MAX_VALUE = 2E6, /SHADED, AXIS_STYLE = 3, /CURRENT, $ 
                COLOR = 'gold', FONT_COLOR = foregroundBlackOrWhite, FONT_SIZE = 20, $
                TITLE = 'Relative Sun Position [º]', $
                YRANGE = [-6, 6], YCOLOR = foregroundBlackOrWhite, YTICKFONT_SIZE = 16, $
                XRANGE = [-6, 6], XCOLOR = foregroundBlackOrWhite, XTICKFONT_SIZE = 16)
t1a = text(-6, 6, 'Total = ' + strtrim(round(sps_sum[0]), 2) + ' fC', /DATA, FONT_SIZE = 16, FONT_COLOR = foregroundBlackOrWhite, VERTICAL_ALIGNMENT = 1.0, TARGET = p1)
t1b = text(6, 6, 'X = ' + JPMPrintNumber(sps_y[0]) + 'º', /DATA, FONT_SIZE = 16, FONT_COLOR = foregroundBlackOrWhite, VERTICAL_ALIGNMENT = 1.0, ALIGNMENT = 1.0, TARGET = p1)
t1c = text(6, 5.5, 'Y = ' + JPMPrintNumber(sps_z[0]) + 'º', /DATA, FONT_SIZE = 16, FONT_COLOR = foregroundBlackOrWhite, VERTICAL_ALIGNMENT = 1.0, ALIGNMENT = 1.0, TARGET = p1)
t1d = text(6, -6, time_human[0], /DATA, FONT_SIZE = 16, FONT_COLOR = foregroundBlackOrWhite, ALIGNMENT = 1.0, TARGET = p1)
t1e = text(-6, -5.5, 'Fine Point Mode', /DATA, FONT_SIZE = 16, FONT_COLOR = 'gold', TARGET = p1)
t1f = text(-6, -6, 'Coarse Point Mode', /DATA, FONT_SIZE = 16, FONT_COLOR = 'dodger blue', TARGET = p1)

tic
FOR timeIndex = 0, n_elements(sps_y) - 1 DO BEGIN
  p1.SetData, sps_y[timeIndex], sps_z[timeIndex]
  p1.color = bubble_color[timeIndex]
  p1.MAGNITUDE = sps_sum[timeIndex]
  t1a.STRING = 'Total = ' + strtrim(round(sps_sum[timeIndex]), 2) + ' fC'
  t1b.STRING = 'X = ' + JPMPrintNumber(sps_y[timeIndex]) + 'º'
  t1c.STRING = 'Y = ' + JPMPrintNumber(sps_z[timeIndex]) + 'º'
  t1d.STRING = time_human[timeIndex]
  
  ; Insert frame into movie
  timeInMovie = movieObject.Put(vidStream, p1.CopyWindow()) ; time returned in seconds
  
  IF timeIndex MOD 50 EQ 0 THEN message, /INFO, JPMsystime() + ' SPS movie progress: ' + JPMPrintNumber(float(timeIndex) / (n_elements(sps_y) - 1) * 100.) + '%'
ENDFOR

movieObject.Cleanup
message, /INFO, JPMsystime() + ' Time to complete movie: ' + JPMPrintNumber(toc()) + ' seconds'

message, /INFO, JPMsystime() + ' -= Program normal completion =-'
END