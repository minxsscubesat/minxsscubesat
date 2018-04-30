;+
; NAME:
;   rocket_xrs_real_time_display
;
; PURPOSE:
;   Wrapper script for reading from an ISIS socket. Calls rocket_read_packets when new data comes over the pipe. 
;
; INPUTS:
;   isisIP [string]: The local IP address of the computer running ISIS. This requires that both machines are running on the same network. 
;                    This is provided as an optional input only so that a hardcoded value can be specified and the Run button hit, instead
;                    of needing to call the code from the command line each time. However, a correct IP address really is necessary. 
;
; OPTIONAL INPUTS:
;   number_of_packets_to_store [integer]: The number of packets to store in ram for plotting time series
;   data_cadence [float]:                 The expected cadence of data in seconds/packet. Only used with time_window_to_store. Can change hardcode default. 
;   time_window_to_store [integer]:       Rather than number_of_packets_to_store, you can store the amount of time to display in the window in seconds
;   windowSize [integer, integer]:        Set this to the pixel dimensions in [x, y] that you want the display. Alternatively change hardcode defaults. 
;                                         A 15" Macbook Pro Retina Late 2013 or newer has [2880, 1800] resolution.
;                                         The 27" Dell from MinXSS all-in-one has         [2560, 1440] resolution. 
;    
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print out additional information about the status of the code as it processes
;
; OUTPUTS:
;   Produces a plot pane with all the most important data in the world, displayed in real time from an ISIS socket. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires that ISIS is running. Must provide IP address via the optional input or hard code.
;   Requires JPMRange.pro
;   Requires JPMPrintNumber.pro
;
; EXAMPLE:
;   Just hit run! 
;
; MODIFICATION HISTORY:
;   2015/03/30: James Paul Mason: Copied from minxss_real-time_socket_read_wrapper and modified for use with EVE rocket 36.300
;   2016/05/03: James Paul Mason: Changed color scheme default, added LIGHT_BACKGROUND keyword to maintain old color scheme. 
;                                 Also removed X123 plots since there isn't one on this flight. 
;-
PRO rocket_xrs_real_time_display, isisIP = isisIP, number_of_packets_to_store = number_of_packets_to_store, data_cadence = data_cadence, $
                                  time_window_to_store = time_window_to_store, windowSize = windowSize, $
                                  VERBOSE = VERBOSE, LIGHT_BACKGROUND = LIGHT_BACKGROUND

; Defaults
IF ~keyword_set(isisIP) THEN isisIP = '192.168.1.49' ; WinD2791 = 27" HP ; Rocket5 = 169.254.191.253, Rocket6 = 169.254.191.0
IF ~keyword_set(number_of_packets_to_store) THEN number_of_packets_to_store = 12
IF ~keyword_set(data_cadence) THEN data_cadence = 3. ; seconds/packet
IF keyword_set(time_window_to_store) THEN number_of_packets_to_store = time_window_to_store / data_cadence ; time_window_to_store in seconds
IF ~keyword_set(windowSize) THEN windowSize = [950, 950]

; Setup
numberOfPlotRows = 2
numberOfPlotColumns = 2
hkPacketBusy = 0
timeArray = JPMrange(0, number_of_packets_to_store * 10, inc = 10) ; Seconds
IF keyword_set(LIGHT_BACKGROUND) THEN BEGIN
  fontColor = 'black'
  backgroundColor = 'white'
  blueColor = 'blue'
  orangeColor = 'orange'
ENDIF ELSE BEGIN
  fontColor = 'white'
  backgroundColor = 'black'
  blueColor = 'light sky blue'
  orangeColor = 'orange'
ENDELSE

; Create place holder plots
w = window(DIMENSIONS = windowSize, /DEVICE, LOCATION = [2400, 20], WINDOW_TITLE = 'EVE Rocket 36.318 XRS Science Data', BACKGROUND_COLOR = backgroundColor)

; XRS A1 and B1 
; (xps_data and xps_data2)
p1a = plot(findgen(10), sin(findgen(10)), COLOR = orangeColor, '2*-', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 1], FONT_COLOR = fontColor, $
           TITLE = 'XRS A1 & B1', $
           XTITLE = 'Time [s]', XCOLOR = fontColor, $
           YTITLE = 'Intensity [DN/s]', YCOLOR = fontColor, $
           NAME = 'A1')
p1b = plot(findgen(10), sin(findgen(10) + 0.3), COLOR = blueColor, '2*-', /OVERPLOT, $
           NAME = 'B1')
t1a = text(0.0, 1.0, 'A1 = 300 DN', /RELATIVE, TARGET = p1a, FONT_COLOR = orangeColor)
t1b = text(1.0, 1.0, 'B1 = 300 DN', /RELATIVE, ALIGNMENT = 1.0, TARGET = p1a, FONT_COLOR = blueColor)

; XRS A2 and B2
; (sps_sum and sps_sum2)
p2a = plot(findgen(10), tan(findgen(10)), COLOR = orangeColor, '2*-', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 2], FONT_COLOR = fontColor, $
           TITLE = 'XRS A2 & B2 Sum', $
           YTITLE = 'Intensity [fA]', YCOLOR = fontColor, $
           XTITLE = 'Time [s]', XCOLOR = fontColor, $
           NAME = 'A2')
p2b = plot(findgen(10), tan(findgen(10) + 0.3), COLOR = blueColor, '2*-', /OVERPLOT, $
           NAME = 'B2')
t2a = text(0.0, 1.0, 'A2 Sum = 300 fA', /RELATIVE, TARGET = p2a, FONT_COLOR = orangeColor)
t2b = text(1.0, 1.0, 'B2 Sum = 300 fA', /RELATIVE, ALIGNMENT = 1.0, TARGET = p2a, FONT_COLOR = blueColor)

; XRS dark diodes
; dark_data and dark_data2
p3a = plot(findgen(10), exp(reverse(findgen(10))), '2*-', COLOR = orangeColor, /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 3], FONT_COLOR = fontColor, $
           TITLE = 'XRS Dark', $
           XTITLE = 'Time [s]', XCOLOR = fontColor, $
           YTITLE = 'Intensity [DN/s]', YCOLOR = fontColor, $
           NAME = 'A')
p3b = plot(findgen(10), exp(reverse(findgen(10) + 0.3)), COLOR = blueColor, '2*-', /OVERPLOT, $
           NAME = 'B')
t3a = text(0.0, 1.0, 'A Dark = 32 DN', /RELATIVE, TARGET = p3a, FONT_COLOR = orangeColor)
t3b = text(1.0, 1.0, 'B Dark = 46 DN', ALIGNMENT = 1.0, /RELATIVE, TARGET = p3a, FONT_COLOR = blueColor)

; XRS A2 and B2 position
p4a = bubbleplot(-0.4, 0.8, MAGNITUDE = 1E5, EXPONENT = 0.5, MAX_VALUE = 1E5, COLOR = 'gold', /SHADED, AXIS_STYLE = 3, /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 4], FONT_COLOR = fontColor, $
                TITLE = 'XRS A2 & B2 Position [º]', $
                YRANGE = [-1, 1], YCOLOR = fontColor, $
                XRANGE = [-1, 1], XCOLOR = fontColor)
p4b = bubbleplot(0.2, -0.3, MAGNITUDE = 1E5, EXPONENT = 0.5, MAX_VALUE = 1E5, COLOR = blueColor, AXIS_STYLE = 3, /SHADED, /OVERPLOT)
t4a = text(-1.0, -0.83, 'A2 = [-0.4, 0.8]º', /DATA, TARGET = p4a, FONT_COLOR = orangeColor)
t4b = text(-1.0, -0.95, 'B2 = [0.2, -0.3]º', /DATA, TARGET = p4a, FONT_COLOR = blueColor)

; Refresh text output
t = text(0.0, 0.0, 'Last refresh: ' + systime())

; Open up a  to the ISIS computer stream
; Ports:
; 10000 = housekeeping
; 10001 = science
; 10002 = SD card playback
get_lun, lun
socket, lun, isisIP, 10003, ERROR = socketError, CONNECT_TIMEOUT = 5, /RAWIO ; timeout is in seconds

; Start an infinite loop
WHILE 1 DO BEGIN

  ; Start a timer
  wrapperClock = TIC()
  
  ; Trigger when data shows up on port then write single packet to file
  IF file_poll_input(lun, TIMEOUT = 60.0d) THEN BEGIN ; Timeout is in seconds
    
    ; Read data on the socket
    socketDataTmp = bytarr((fstat(lun)).size)
    readu, lun, socketDataTmp
    
    ; If science packet is busy being read, append to the bytarr, otherwise replace it
    IF hkPacketBusy THEN socketData = [temporary(socketData), socketDataTmp] ELSE socketData = socketDataTmp
    
    read_hydra_rxrs, socketData, sps = hkTemp, VERBOSE = VERBOSE
    
    ; The first time through this loop, create the array for time series
    IF hkTemp NE !NULL THEN BEGIN
      IF n_elements(hk) EQ 0 THEN BEGIN
        hkCounter = 0
        hk = replicate(hkTemp[0], number_of_packets_to_store)
      ENDIF
    ENDIF
    
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

    ; -= MANIPULATE DATA AS NECESSARY =- ;
    
    ; Compute XRS-A2 position - still called sps from MinXSS code heritage
    spsTotal = hk.sps_sum
    spsXposition = hk.sps_x
    spsYposition = hk.sps_y
    
    ; Compute XRS-B2 position - still called sps from MinXSS code heritage
    sps2Total = hk.sps_sum2
    sps2Xposition = hk.sps_x2
    sps2Yposition = hk.sps_y2
        
    ; -= UPDATE PLOT WINDOW =- ;
    
    ; Update plots
    !Except = 0 ; Disable annoying divide by 0 messages
    p1a.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].xps_data    ; A1 
    p1b.SetData, timeArray[0:hkCounter - 1],  hk[0:hkCounter - 1].xps_data2  ; B1
    p2a.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].sps_sum     ; A2
    p2b.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].sps_sum2    ; B2
    p3a.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].dark_data   ; A dark
    p3b.SetData, timeArray[0:hkCounter - 1],  hk[0:hkCounter - 1].dark_data2 ; B dark  
    p4a.SetData, spsXposition, spsYposition                                  ; A2 position
    p4a.MAGNITUDE = spsTotal                                                 ; A2 position magnitude
    p4b.SetData, sps2Xposition, sps2Yposition                                ; B2 position
    p4b.MAGNITUDE = sps2Total                                                ; B2 position magnitude
    !Except = 1 ; Re-enable math error logging
    
    ; Update text
    t.STRING = 'Last refresh: ' + systime()
    t1a.STRING = 'A1 = ' + JPMPrintNumber(round(hk[hkCounter - 1].xps_data), /NO_DECIMALS) + ' DN'
    t1b.STRING = 'B1 = ' + JPMPrintNumber(round(hk[hkCounter - 1].xps_data2), /NO_DECIMALS) + ' DN'
    t2a.STRING = 'A2 Sum = ' + JPMPrintNumber(hk[hkCounter - 1].sps_sum) + ' fA'
    t2b.STRING = 'B2 Sum = ' + JPMPrintNumber(hk[hkCounter - 1].sps_sum2) + ' fA'
    t3a.STRING = 'A Dark = ' + JPMPrintNumber(round(hk[hkCounter - 1].dark_data), /NO_DECIMALS) + ' DN'
    t3b.STRING = 'B Dark = ' + JPMPrintNumber(round(hk[hkCounter - 1].dark_data2), /NO_DECIMALS) + ' DN'
    t4a.STRING = 'A2 = [' + strmid(JPMPrintNumber(spsXposition), 0, 7) + ', ' + strmid(JPMPrintNumber(spsYposition), 0, 6) + ']º'
    t4b.STRING = 'B2 = [' + strmid(JPMPrintNumber(sps2Xposition), 0, 7) + ', ' + strmid(JPMPrintNumber(sps2Yposition), 0, 6) + ']º'

  ENDIF ELSE message, /INFO, 'Socket connected but no data posted within 60 seconds.'
  
  IF n_elements(logTemp) GT 0 THEN FOR i = 0, n_elements(logTemp)-1 DO print, 'LOG: ' + logTemp[i].message
  
  ; Reset values to nonexistant so that we don't hold old variables
  hkTemp = !NULL
  
  IF TOC(wrapperClock) GE data_cadence THEN $
    message, /INFO, 'Completed in time = ' +  JPMPrintNumber(TOC(wrapperClock))
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, lun
free_lun, lun2

END