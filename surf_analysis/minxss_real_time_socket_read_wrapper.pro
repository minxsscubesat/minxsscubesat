;+
; NAME:
;   minxss_real_time_socket_read_wrapper
;
; PURPOSE:
;   Wrapper script for reading from an ISIS socket. Calls minxss_read_packets and minxss_science_display when new data comes over the pipe. 
;
; INPUTS:
;   isisIP [string]: The local IP address of the computer running ISIS. This requires that both machines are running on the same network. 
;                    This is provided as an optional input only so that a hardcoded value can be specified and the Run button hit, instead
;                    of needing to call the code from the command line each time. However, a correct IP address really is necessary. 
;
; OPTIONAL INPUTS:
;   number_of_packets_to_store [integer]: The number of packets to store in ram for plotting time series
;   time_window_to_store [integer]:       Rather than number_of_packets_to_store, you can store the amount of time to display in the window in seconds
;   MinXSSFlightModel [integer]:          Set this to 1 or 2
;   windowSize [integer, integer]:        Set this to the pixel dimensions in [x, y] that you want the display. Default is [1600, 900], 
;                                         which works well on a Macbook Pro Retina with [1920, 1200] resolution. 
;    
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Produces a plot pane with all the most important data in the world, displayed in real time from an ISIS socket. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires that ISIS is running. Must provide IP address via the optional input or hard code.
;
; EXAMPLE:
;   Just hit run! 
;
; MODIFICATION HISTORY:
;   Written by:
;     James Paul Mason
;     2014/10/08
;-
@minxss_read_packets28
PRO minxss_real_time_socket_read_wrapper, isisIP = isisIP, number_of_packets_to_store = number_of_packets_to_store, MinXSSFlightModel = MinXSSFlightModel, $
                                          windowSize = windowSize, time_window_to_store = time_window_to_store, debug = debug

; Defaults
IF ~keyword_set(isisIP) THEN isisIP = '169.254.191.253' ; WinD2791 = 27" HP ; Rocket5 = 169.254.191.253, Rocket6 = 169.254.191.0
IF ~keyword_set(number_of_packets_to_store) THEN number_of_packets_to_store = 40 ; When set to 1000 this code takes about 45 seconds to complete
IF keyword_set(time_window_to_store) THEN number_of_packets_to_store = time_window_to_store * 3 ; time_window_to_store in seconds
IF ~keyword_set(MinXSSFlightModel) THEN MinXSSFlightModel = 1
IF ~keyword_set(windowSize) THEN windowSize = [1600, 900]

; Setup
numberOfPlotRows = 2
numberOfPlotColumns = 3
sps001Gains = [7.1081, 6.3791, 6.5085, 5.5359] ; [fC/DN] This refers to SPS 001 which is in MinXSS 002 
sps002Gains = [6.5300, 6.4411, 6.7212, 6.8035] ; [fC/DN] This refers to SPS 002 which is in MinXSS 001
xp001Gain = 6.6302 ; [fC/DN]
xp002Gain = 6.4350 ; [fC/DN]
x123EnergyScaling001 = [0.0, 0.0] ; [gain, offset] This refers to X123 001 which is in MinXSS 002
x123EnergyScaling002 = [0.0, 0.0] ; [gain, offset] This refers to X123 002 which is in MinXSS 001
IF MinXSSFlightModel EQ 1 THEN BEGIN
  spsGains = sps002Gains
  xpGain = xp002Gain
  x123EnergyScaling = x123EnergyScaling002
ENDIF ELSE BEGIN
  spsGains = sps001Gains
  xpGain = xp001Gain
  x123EnergyScaling = x123EnergyScaling001
ENDELSE
sciPacketBusy = 0
timeArray = range(0, number_of_packets_to_store * 3, inc = 3) ; Seconds

; Create place holder plots
w = window(DIMENSIONS = windowSize, /DEVICE, WINDOW_TITLE = 'MinXSS Science Data')
p0 = plot(findgen(10), findgen(10), 'r2*-', TITLE = 'X123 Counters', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 1], $
          YTITLE = 'Counts/s', $
          XTITLE = 'Time [s]', $
          NAME = 'Fast Counts')
p0a = plot(findgen(10), 10 - findgen(10), 'b2*-', /OVERPLOT, $
           NAME = 'Slow Counts')
t0 = text(0.0, 1.0, 'Fast = 100, Slow = 40', /RELATIVE, TARGET = p0)
l0 = legend(TARGET = [p0, p0a], POSITION = [0.14, 0.54], FONT_SIZE = 8)
p1 = plot(findgen(10) * 10 + 10, findgen(10) * 10 + 1, TITLE = 'X123 Spectrum', /HISTOGRAM, /STAIRSTEP, /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 2], $
             YTITLE = 'Intensity [counts/s]', YRANGE = [0.5, 1000], /YLOG, $
             XTITLE = 'Channel', XRANGE = [1, 350], /XLOG, $
             FILL_COLOR = 'white', SYMBOL = 'circle', SYM_FILL_COLOR = 'blue', /SYM_FILLED)
a1 = axis('X', LOCATION = -1.3, TITLE='Energy', TARGET = p1, COORD_TRANSFORM = [100., 1./32])
p2a = plot(findgen(10), sin(findgen(10)), COLOR = 'red', '2*-', TITLE = 'SPS', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 3], $
           YTITLE = 'Intensity [DN/s]', $
           XTITLE = 'Time [s]', $
           NAME = 'Upper Right Diode')
p2b = plot(findgen(10), sin(findgen(10) + 0.3), COLOR = 'orange', '2*-', /OVERPLOT, $
           NAME = 'Lower Right Diode')
p2c = plot(findgen(10), sin(findgen(10) + 0.6), COLOR = 'green', '2*-', /OVERPLOT, $
           NAME = 'Lower Left Diode')
p2d = plot(findgen(10), sin(findgen(10) + 0.9), COLOR = 'blue', '2*-', /OVERPLOT, $
           NAME = 'Upper Left Diode')
l2 = legend(TARGET = [p2a, p2b, p2c, p2d], POSITION = [1.03, 0.53], FONT_SIZE = 8)
t2 = text(0.0, 1.0, 'Total = 300 DN', /RELATIVE, TARGET = p2a)
p7 = plot(findgen(10), findgen(10), '2*-', TITLE = 'XP', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 4], $
          YTITLE = 'Intensity [DN/s]', $
          XTITLE = 'Time [s]')
t7 = text(0.0, 1.0, 'Intensity = 300 DN', /RELATIVE, TARGET = p7)
p8 = bubbleplot(-0.4, 0.8, MAGNITUDE = 10, EXPONENT = 0.5, MAX_VALUE = 2E6, COLOR = 'gold', /SHADED, AXIS_STYLE = 3, TITLE = 'SPS Position', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 6], $
                YRANGE = [-1, 1], $
                XRANGE = [-1, 1])
t8 = text(-1.0, -0.8, 'Position = -0.4, 0.8', /DATA, TARGET = p8) ; SPS position value
t_ = text(0.5, 0.2, 'Flight Model 00' + strtrim(string(MinXSSFlightModel), 2), FONT_SIZE = 30, ALIGNMENT = 0.5)
t_ = text(0.5, 0.1, 'IP = ' + strtrim(string(isisIP)), FONT_SIZE = 15, ALIGNMENT = 0.5)
t = text(0.0, 0.0, 'Last refresh: ' + systime())

; Open up a socket to the ISIS computer stream
; Ports:
; 10000 = housekeeping
; 10001 = science
; 10002 = SD card playback
get_lun, lun
socket, lun, isisIP, 10001, ERROR = socketError, CONNECT_TIMEOUT = 5, /RAWIO ; timeout is in seconds
;get_lun, lun2
;socket, lun2, isisIP, 10000, ERROR = socketError2, CONNECT_TIMEOUT = 5, /RAWIO ;timeout is in seconds

; DEBUG: Count the number of packets coming in (compression check)
IF keyword_set(debug) THEN pktCnt = 0

; Start an infinite loop
WHILE 1 DO BEGIN

  ; Trigger when data shows up on port then write single packet to file
  IF file_poll_input(lun, TIMEOUT = 60.0d) THEN BEGIN ; Timeout is in seconds
    
    ; Start a timer for the plotting portion only (else it includes the wait time for a packet)
    wrapperClock = TIC()
  
    ; Read data on the socket
    socketDataTmp = bytarr((fstat(lun)).size)
    readu, lun, socketDataTmp
    
    ; If science packet is busy being read, append to the bytarr, otherwise replace it
    IF sciPacketBusy THEN socketData = [temporary(socketData), socketDataTmp] ELSE socketData = socketDataTmp

    minxss_read_packets28, socketData, hk=hkTemp, sci=sciTemp, adcs=adcsTemp, log=logTemp, diag=diagTemp, image=imageTemp
    
    ; The first time through this loop, create the array for time series
    IF hkTemp NE !NULL THEN IF n_elements(hk) EQ 0 THEN BEGIN 
      hkCounter = 0
      hk = replicate(hkTemp[0], number_of_packets_to_store)
    ENDIF
    IF sciTemp NE !NULL THEN BEGIN
      ; If sciTemp is -1 then we are in the middle of a science packet and must read more... set a busy flag
      IF size(sciTemp, /TYPE) NE 8 && sciTemp EQ -1 THEN BEGIN
        sciPacketBusy = 1
        ; undefine sciTemp so we don't try plotting it
        junk = temporary(sciTemp)
      ENDIF ELSE BEGIN
        sciPacketBusy = 0
        IF n_elements(sci) EQ 0 THEN BEGIN
          sciCounter = 0
          sci = replicate(sciTemp[0], number_of_packets_to_store)
        ENDIF
      ENDELSE
    ENDIF

  ;; DEBUG: If the science packet is busy, we have multiple packets, so count them up...
  IF keyword_set(debug) THEN BEGIN
    IF sciPacketBusy THEN BEGIN
      pktCnt += 1
      message, /info, "Got packet "+strtrim(pktCnt,2)+" of multiple packets"
    ENDIF ELSE BEGIN
      IF pktCnt NE 0 then message, /info, "Got packet "+strtrim(pktCnt,2)+" of multiple packets"
      pktCnt = 0
    ENDELSE
  ENDIF

    ; If science packet is busy, skip the rest of the loop
    IF (sciPacketBusy OR ((hkTemp EQ !NULL) AND (sciTemp EQ !NULL))) THEN CONTINUE
        
    ; Fill up the time series array
    IF hkTemp NE !NULL THEN BEGIN
      numberOfFreeSlots = number_of_packets_to_store - hkCounter
      IF numberOfFreeSlots GE n_elements(hkTemp) THEN BEGIN
        hk[hkCounter:hkCounter + n_elements(hkTemp) - 1] = hkTemp
        hkCounter += n_elements(hkTemp)
      ENDIF ELSE BEGIN ; Array is full so need to shift
        hk = shift(temporary(hk), -(n_elements(hkTemp) - numberOfFreeSlots))
        hk[-n_elements(hkTemp):-1] = hkTemp
        hkCounter = number_of_packets_to_store ; Now at max
      ENDELSE
    ENDIF
 
    ; Fill up the time series array
    IF sciTemp NE !NULL THEN BEGIN
      numberOfFreeSlots = number_of_packets_to_store - sciCounter
      IF numberOfFreeSlots GE n_elements(sciTemp) THEN BEGIN
        sci[sciCounter:sciCounter + n_elements(sciTemp) - 1] = sciTemp
        sciCounter += n_elements(sciTemp)
      ENDIF ELSE BEGIN ; Array is full so need to shift
        sci = shift(temporary(sci), -(n_elements(sciTemp) - numberOfFreeSlots))
        sci[-n_elements(sciTemp):-1] = sciTemp
        sciCounter = number_of_packets_to_store ; Now at max
      ENDELSE

      ;; DEBUG: Print the compression info
      IF keyword_set(debug) THEN $
        FOR i=0,n_elements(sciTemp)-1 DO message, /info, "Packet "+strtrim(i,2)+": "+((sciTemp[i].x123_cmp_info eq 0) ? "NOT COMPRESSED" : "CmpInfo = "+strtrim(sciTemp[i].x123_cmp_info,2))
    ENDIF

    ; -= MANIPULATE DATA AS NECESSARY =- ;
    
    ; Compute SPS position
    spsUpperLeft = sci[sciCounter - 1].sps_data[3] * spsGains[3] / (sci[sciCounter - 1].sps_xps_count > 1)
    spsUpperRight = sci[sciCounter - 1].sps_data[0] * spsGains[0] / (sci[sciCounter - 1].sps_xps_count > 1)
    spsLowerLeft = sci[sciCounter - 1].sps_data[2] * spsGains[2] / (sci[sciCounter - 1].sps_xps_count > 1)
    spsLowerRight = sci[sciCounter - 1].sps_data[1] * spsGains[1] / (sci[sciCounter - 1].sps_xps_count > 1)
    spsTotal = spsUpperLeft + spsUpperRight + spsLowerLeft + spsLowerRight
    spsXposition = ((spsUpperRight + spsLowerRight) - (spsUpperLeft + spsLowerLeft)) / spsTotal
    spsYposition = ((spsUpperLeft + spsUpperRight) - (spsLowerLeft + spsLowerRight)) / spsTotal
    
    ; X123 Normalization
    accumulationTime = sci[sciCounter - 1].x123_accum_time / 1000.
    sci[sciCounter - 1].x123_fast_count /= accumulationTime
    sci[sciCounter - 1].x123_slow_count /= accumulationTime
    sci[sciCounter - 1].x123_spectrum /= accumulationTime
    
    ; -= UPDATE PLOT WINDOW =- ;
    
    ; Update plots
    !Except = 0 ; Disable annoying divide by 0 messages
    p0.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].x123_fast_count                                           ; X123 fast counter
    p0a.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].x123_slow_count                                          ; X123 slow counter
    p1.SetData, findgen(n_elements(sci[sciCounter - 1].x123_spectrum)), sci[sciCounter - 1].x123_spectrum                    ; X123 spectrum
    p2a.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].sps_data[0] / (sci[0:sciCounter - 1].sps_xps_count > 1)  ; SPS upper right
    p2b.SetData,timeArray[0:sciCounter - 1],  sci[0:sciCounter - 1].sps_data[1] / (sci[0:sciCounter - 1].sps_xps_count > 1)  ; SPS lower right
    p2c.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].sps_data[2] / (sci[0:sciCounter - 1].sps_xps_count > 1)  ; SPS lower left
    p2d.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].sps_data[3] / (sci[0:sciCounter - 1].sps_xps_count > 1)  ; SPS upper left
    p7.SetData, timeArray[0:sciCounter - 1], sci[0:sciCounter - 1].xps_data / (sci[0:sciCounter - 1].sps_xps_count > 1)      ; XP
    p8.SetData, spsXposition, spsYposition                                                                                   ; SPS position
    p8.MAGNITUDE = spsTotal                                                                                                  ; SPS position
    !Except = 1 ; Re-enable math error logging
    
    ; Update text
    t.STRING = 'Last refresh: ' + systime()
    t0.STRING = 'Fast = ' + strtrim(string(round(sci[sciCounter - 1].x123_fast_count)), 2) + '   Slow = ' + strtrim(string(round(sci[sciCounter - 1].x123_slow_count)), 2)
    t2.STRING = 'Total = ' + strtrim(string(round(spsTotal)), 2)
    t7.STRING = 'Intensity = ' + strtrim(string(round(sci[sciCounter - 1].xps_data / (sci[sciCounter - 1].sps_xps_count > 1) )), 2)
    t8.STRING = 'Pos = ' + strmid(strtrim(string(spsXposition), 2), 0, 7) + ' :: ' + strmid(strtrim(string(spsYposition), 2), 0, 6)

  ENDIF ELSE message, /INFO, 'Socket connected but no data posted within 60 seconds.'
  
  IF n_elements(logTemp) GT 0 THEN FOR i = 0, n_elements(logTemp)-1 DO print, 'LOG: ' + logTemp[i].message
  
  ; Reset values to nonexistant so that we don't hold old variables
  hkTemp = !NULL
  sciTemp = !NULL
  adcsTemp = !NULL
  logTemp = !NULL
  diagTemp = !NULL
  imageTemp = !NULL
  
  IF TOC(wrapperClock) GE 2 THEN $
    message, /INFO, 'Completed in time = ' +  strtrim(string(TOC(wrapperClock)), 2)
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, lun
free_lun, lun2

END