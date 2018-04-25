;+
; NAME:
;   rocket_x123_surfer_consolidate
;
; PURPOSE:
;   Consolidate relevant science data from X123 with SURFER data into a single structure
;
; INPUTS:
;   x123Data [arr of str]:   The X123 data as returned from *read_packets, sci=sci
;   surferData [arr of str]: The SURFER data as returned from read_surfer_data.pro
;
; OPTIONAL INPUTS:
;   timeBaseJd [double]: Julian Date reference time. All data will be reported as seconds since timeBaseJd.
;                        If timeBaseJd is NULL, times will be seconds after first data point, whose time will be returned in timeBaseJd for possible usage in subsequent calls
;
; KEYWORD PARAMETERS:
;   MANUALDARK:             Set to select dark intervals manually. Otherwise the first 30 seconds of data will be used as dark.
;   DONTCORRECTBEAMCURRENT: Set this to prevent the beam current correction code, surf_correct_bc, from being called. Otherwise it will be. 
;   
; OUTPUTS:
;   dataConsolidated [arr of str]: Consolidated data from X123 and SURFER on the same time grid. Each element in the array is a point in time. 
;                                   Each tag in the structure is a different measurement. 
;
; OPTIONAL OUTPUTS:
;   timeBaseJd [double]: Julian Date reference time. All data will be reported as seconds since timeBaseJd.
;                        If timeBaseJd as an input is NULL, times will be seconds after first data point, whose time will be returned in timeBaseJd for possible usage in subsequent calls
;
; RESTRICTIONS:
;   Requires the mess of SURF processing code
;
; EXAMPLE:
;   dataConsolidated = rocket_x123_surfer_consolidate(x123Data, surferData, /MANUALDARK)
;
; MODIFICATION HISTORY:
;   2018-03-29: James Paul Mason: Wrote script based on minxss_process_surferdata.
;   2018-04-02: James Paul Mason: Rewriting of this code from scratch, using minxss_process_surfdata.pro as a reference.
;-
FUNCTION rocket_x123_surfer_consolidate, x123Data, surferData, $
                                         timeBaseJd = timeBaseJd, $
                                         MANUALDARK = MANUALDARK, DONTCORRECTBEAMCURRENT = DONTCORRECTBEAMCURRENT

; Defaults
IF timeBaseJd EQ !NULL THEN BEGIN
  timeBaseJd = x123Data[0].jd
  message, /INFO, 'No base time provided. Setting to first X123 time: ' + strtrim(timeBaseJd, 2) + '(' + x123Data[0].human + ')'
ENDIF

; Define the consolidated data structure we want to use
numdata = n_elements(x123Data)
dataConsolidated = {jd: 0d0, sec_since_start: 0L, $ ; measurement time
                    x123_real_time: 0d0, x123_accum_time: 0d0, $ ; X123 integration time counters
                    x123_fast_cps: 0d0, x123_slow_cps: 0d0, x123_gp_cps: 0d0, $ ; X123 counters
                    x123_spectrum: dblarr(n_elements(x123Data[0].x123_spectrum)), $ ; X123 spectrum
                    surf_beam_current_ma: 0d0, surf_x_pos_inches: 0.0, surf_y_pos_inches: 0.0, surf_pitch_deg: 0.0, surf_yaw_deg: 0.0, $ ; SURF beam current and positions
                    surf_energy_mev: 0.0, surf_fuzz_factor: 0.0, surf_valves: 0.0} ; SURF beam energy and size (FUZZ --> size > 0)
dataConsolidated = replicate(dataConsolidated, numdata)

; Convert X123 integration time counters from milliseconds to seconds
x123Data.x123_real_time /= 1000. ; [sec]
x123Data.x123_accum_time /= 1000. ; [sec]

; Copy X123 data into array of structures
dataConsolidated.jd = x123Data.jd
dataConsolidated.x123_real_time = x123Data.x123_real_time
dataConsolidated.x123_accum_time = x123Data.x123_accum_time
dataConsolidated.x123_fast_cps = x123Data.x123_fast_count / x123Data.x123_accum_time
dataConsolidated.x123_slow_cps = x123Data.x123_slow_count / x123Data.x123_accum_time
dataConsolidated.x123_gp_cps = x123Data.x123_gp_count / x123Data.x123_accum_time
FOR i = 0, numdata - 1 DO BEGIN
  spectrum = x123Data[i].x123_spectrum
  spectrum /= x123Data[i].x123_accum_time
  dataConsolidated[i].x123_spectrum = spectrum
ENDFOR

; Convert times to seconds since start
dataConsolidated.sec_since_start = long((x123Data.jd - timeBaseJd) * 86400.)
surferData = JPMAddTagsToStructure(surferData, 'sec_since_start', 'long')
surferData.sec_since_start = long((surferData.jd - timeBaseJd) * 86400.)

; Restrict time range to where both sets exist
firstSec = surferData[0].sec_since_start > dataConsolidated[0].sec_since_start
lastSec = surferData[-1].sec_since_start < dataConsolidated[-1].sec_since_start
surferTimeInRangeIndices = where(surferData.sec_since_start GE firstSec AND surferData.sec_since_start LE lastSec)
surferData = surferData[surferTimeInRangeIndices]
dataConsolidatedTimeInRangeIndices = where(dataConsolidated.sec_since_start GE firstSec AND dataConsolidated.sec_since_start LE lastSec)
dataConsolidated = dataConsolidated[dataConsolidatedTimeInRangeIndices]

; Optionally have user select dark data, else use first 5 minutes of data for dark
IF keyword_set(MANUALDARK) THEN BEGIN
  setplot, thick = 1.5
  plot, dataConsolidated.sec_since_start, dataConsolidated.x123_slow_cps, $
        TITLE = 'Select Dark Times', $
        XTITLE = 'Time [seconds since start]', $
        YTITLE = 'X123 Intensity [counts / sec]'
  
  ; Shade the times where the valves are closed, unless there's no valve data
  IF median(surferData.valves) NE -1 THEN BEGIN
    polyfill, [surferData[0].sec_since_start, reform(surferData.sec_since_start), surferData[-1].sec_since_start],$
              10^[!y.crange[0], reform((surferData.valves eq 7)*!y.crange[0] + (surferData.valves ne 7)*!y.crange[1]), !y.crange[0]], $
              NOCLIP = 0, color='dddddd'x
  ENDIF
  
  ; Get user input for dark ranges
  message, /INFO, 'Manual dark subtraction'
  REPEAT BEGIN
    keyboardInput = 'Y'
    print, 'Move cursor to LEFT side of the dark data and click'
    cursor, x1, y1, /DOWN
    oplot, [x1, x1], !y.crange, LINE = 2, /NOCLIP
    print, 'Move cursor to RIGHT side of the dark data and click'
    cursor, x2, y2, /DOWN
    oplot, [x2, x2], !y.crange, LINE = 2, /NOCLIP
    
    darkIndicesTemp = where(dataConsolidated.sec_since_start GE x1 AND dataConsolidated.sec_since_start LE x2, numdark)
    
    IF numdark LT 2 THEN BEGIN
      darkIndicesTemp = !NULL
      message, /INFO, 'ERROR: Insufficient dark data selected. Pick a larger time range.'
    ENDIF ELSE BEGIN
      darkIndices = (darkIndices EQ !NULL) ? darkIndicesTemp : [darkIndices, darkIndicesTemp]
    ENDELSE
    
    read, prompt = 'Select additional darks for time interpolation? (Y or N): ', keyboardInput
    keyboardInput = strupcase(strtrim(keyboardInput, 2))
  ENDREP UNTIL (keyboardInput NE 'Y')
ENDIF ELSE BEGIN ; End Manual dark begin automatic dark
  message, /INFO, "Automatic dark subtraction: using first 30 seconds of consolidated data for dark"
  darkIndices = where(dataConsolidated.sec_since_start LE 30, numdark)
ENDELSE

; Subtract dark from X123 measurements
dataConsolidated.x123_fast_cps -= mean(dataConsolidated[darkIndices].x123_fast_cps)
dataConsolidated.x123_slow_cps -= mean(dataConsolidated[darkIndices].x123_slow_cps)
dataConsolidated.x123_gp_cps -= mean(dataConsolidated[darkIndices].x123_gp_cps)
dataConsolidated.x123_spectrum -= mean(dataConsolidated[darkIndices].x123_spectrum, DIMENSION = 2)

; Smooth beam current to remove fast fluctuations
surferData.beam_current_ma = smooth(surferData.beam_current_ma, 3, /EDGE_TRUNC)
IF ~keyword_set(DONTCORRECTBEAMCURRENT) THEN BEGIN
  surferData.beam_current_ma = surf_correct_bc(surferData.beam_current_ma)
ENDIF

; Interpolate SURFER to X123 measurements 
dataConsolidated.surf_beam_current_ma = interpol(surferData.beam_current_ma, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_x_pos_inches = interpol(surferData.x_pos_inches, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_y_pos_inches = interpol(surferData.y_pos_inches, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_pitch_deg = interpol(surferData.pitch_deg, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_yaw_deg = interpol(surferData.yaw_deg, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_energy_mev = interpol(surferData.energy_mev, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_fuzz_factor = interpol(surferData.fuzz_factor, surferData.sec_since_start, dataConsolidated.sec_since_start)
dataConsolidated.surf_valves = interpol(surferData.valves, surferData.sec_since_start, dataConsolidated.sec_since_start)

; Scale X123 measurements by SURF beam current
dataConsolidated.x123_fast_cps /= dataConsolidated.surf_beam_current_ma
dataConsolidated.x123_slow_cps /= dataConsolidated.surf_beam_current_ma
dataConsolidated.x123_gp_cps /= dataConsolidated.surf_beam_current_ma
FOR i = 0, n_elements(dataConsolidated) - 1 DO BEGIN
  spectrum = dataConsolidated[i].x123_spectrum
  spectrum /= dataConsolidated[i].surf_beam_current_ma
  dataConsolidated[i].x123_spectrum = spectrum
ENDFOR 

; User select time range of interest for output
setplot, thick = 1.5
cc = rainbow(7)
cc = cc[[0, 4, 1]]
!p.multi=[0,1,2]
keyboardInput = 'Y'
WHILE keyboardInput EQ 'Y' DO BEGIN
  xr = plotrange(dataConsolidated.sec_since_start, margin=0.05)
  yr1 = plotrange([dataConsolidated.surf_x_pos_inches, dataConsolidated.surf_y_pos_inches, dataConsolidated.surf_pitch_deg, dataConsolidated.surf_yaw_deg])
  plot, /NODATA, [dataConsolidated.sec_since_start, dataConsolidated.sec_since_start, dataConsolidated.sec_since_start, dataConsolidated.sec_since_start], $
                 [dataConsolidated.surf_x_pos_inches, dataConsolidated.surf_y_pos_inches, dataConsolidated.surf_pitch_deg, dataConsolidated.surf_yaw_deg], $
                 xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2, 2]
  
  ; Shade the times where the valves are closed, unless there's no valve data
  IF median(surferData.valves) NE -1 THEN BEGIN
    polyfill, [surferData[0].sec_since_start, reform(surferData.sec_since_start), surferData[-1].sec_since_start], $
              [yr1[0], reform((surferData.valves eq 7)*yr1[0] + (surferData.valves ne 7)*yr1[1]), yr1[0]], $
              NOCLIP = 0, color='dddddd'x
  ENDIF
  
  !p.multi[0] = 0
  plot, /NOERASE, /NODATA, [dataConsolidated.sec_since_start, dataConsolidated.sec_since_start, dataConsolidated.sec_since_start, dataConsolidated.sec_since_start], $
                 [dataConsolidated.surf_x_pos_inches, dataConsolidated.surf_y_pos_inches, dataConsolidated.surf_pitch_deg, dataConsolidated.surf_yaw_deg], $
                 TITLE = 'DATA SELECTION - please restrict data window (if needed)', $
                 /XS, xrange = !x.crange, xtitle = 'Seconds Since Start', $
                 /YS, yrange = !y.crange, ymargin=[2,2], ytitle = 'SURF XYUV'

  oplot, dataConsolidated.sec_since_start, dataConsolidated.surf_x_pos_inches, PSYM = 4, COLOR = cc[0]
  oplot, dataConsolidated.sec_since_start, dataConsolidated.surf_y_pos_inches, PSYM = 1
  oplot, dataConsolidated.sec_since_start, dataConsolidated.surf_pitch_deg, PSYM = 7, COLOR = cc[1]
  oplot, dataConsolidated.sec_since_start, dataConsolidated.surf_yaw_deg, PSYM = 6, COLOR = cc[2]
  xyouts, [0.135, 0.135, 0.135, 0.135], [0.9, 0.875, 0.85, 0.825], /norm, ['X','Y','Pitch','Yaw'], color=[cc[0],!p.color,cc[1],cc[2]]
  
  !p.multi[0] = 1
  plot, /NODATA, /NOERASE, dataConsolidated.sec_since_start, dataConsolidated.x123_slow_cps, $
        xs = 5, xrange = !x.crange, $
        ys = 4, yrange = plotrange(dataConsolidated.x123_slow_cps)
    
  ; Shade the times where the valves are closed, unless there's no valve data
  IF median(surferData.valves) NE -1 THEN BEGIN
    polyfill, [surferData[0].sec_since_start, reform(surferData.sec_since_start), surferData[-1].sec_since_start], $
              [!y.crange[0], reform((surferData.valves eq 7)*!y.crange[0] + (surferData.valves ne 7)*!y.crange[1]), !y.crange[0]], $
              NOCLIP = 0, color='dddddd'x
  ENDIF
  
  plot, /NOERASE, dataConsolidated.sec_since_start, dataConsolidated.x123_slow_cps, $
        /XS, xrange = !x.crange, xtitle = "Seconds Since Start", $
        ytitle = "X123 Slow Channel [cps]", /ys, yrange = !y.crange, ymargin=[2,2]
  !p.multi[0] = 0
  
  ; Decide to do time restriction or not
  keyboardInput = 'Y'
  read, prompt = 'Do you need to restrict the scan time? (Y or N): ', keyboardInput
  keyboardInput = strupcase(strtrim(keyboardInput, 2))
  
  WHILE keyboardInput EQ 'Y' DO BEGIN
    ; Actual time range restriction
    print, 'Move cursor to LEFT side of desired time range and click (either plot window is fine)'
    cursor, x1, y1, /DOWN
    plot, /NOERASE, [x1, x1], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]
    !p.multi[0] = 1
    plot, /NOERASE, [x1, x1], !y.crange, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
    print, 'Move cursor to RIGHT side of desired time range and click (either plot window is fine)'
    cursor, x2, y2, /DOWN
    plot, /NOERASE, [x2, x2], !y.crange, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
    !p.multi[0] = 0
    plot, /NOERASE, [x2, x2], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]
    
    ; Store the selected time range
    selectedTimeRangeIndices = where((dataConsolidated.sec_since_start GE x1) AND (dataConsolidated.sec_since_start) LE x2, numtime)
    IF numtime LT 2 THEN BEGIN
      message, /INFO, 'ERROR: no valid time range selected; try again.'
    ENDIF ELSE BEGIN
      selectedConsolidatedData = (selectedConsolidatedData EQ !NULL) ? dataConsolidated[selectedTimeRangeIndices]:[temporary(selectedConsolidatedData), dataConsolidated[selectedTimeRangeIndices]]
      read, prompt = 'Do you want to define any additional time ranges? (Y or N): ', keyboardInput
      keyboardInput = strupcase(strmid(keyboardInput, 0, 1))
    ENDELSE
    
    IF (n_elements(selectedConsolidatedData) NE 0) THEN BEGIN
      ; Make sure we don't have duplicate data if the user accidentally selected overlapping times...
      selectedConsolidatedData = selectedConsolidatedData[uniq(selectedConsolidatedData.sec_since_start, sort(selectedConsolidatedData.sec_since_start))]
      read, prompt = 'Re-plot restricted data set? (Y or N): ', keyboardInput
      keyboardInput = strupcase(strmid(keyboardInput, 0, 1))
      IF (keyboardInput EQ 'Y') THEN dataConsolidated = temporary(selectedConsolidatedData)
    ENDIF
  ENDWHILE
ENDWHILE


; If we haven't selected anything yet, then select all
IF selectedConsolidatedData EQ !NULL THEN BEGIN
  message, /INFO, "Selecting all data"
  selectedConsolidatedData = dataConsolidated
ENDIF

!p.multi=[0,1,1]

return, selectedConsolidatedData

END
