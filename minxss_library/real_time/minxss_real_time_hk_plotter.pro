;+
; NAME:
;   minxss_real_time_hk_plotter
;
; PURPOSE:
;   Wrapper script for reading from an ISIS socket. Calls minxss_read_packets when new data comes over the pipe. 
;   Intended for viewing time sensitive critical telemetry during commissioning. 
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
;   windowLocation [integer, integer]:    The position on the screen to make the window appear. 
;   retryWaitTime [integer]:              How long to wait after reaching the end of data on the socket buffer before trying to get more. Default is 0. 
;   
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print additional console output messages
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
;   2016-02-18: James Paul Mason: Wrote script based on other real time wrappers of this sort
;   2016-09-14: James Paul Mason: Added windowLocation optional input and changed date plotting to use actual time instead of an assumed time
;   2017-07-20: James Paul Mason: Changed name of function from minxss_real_time_socket_read_wrapper_safe and changed default flight model to 2
;-
PRO minxss_real_time_hk_plotter, isisIP = isisIP, number_of_packets_to_store = number_of_packets_to_store, MinXSSFlightModel = MinXSSFlightModel, $
                                 windowSize = windowSize, windowLocation = windowLocation, time_window_to_store = time_window_to_store, retryWaitTime = retryWaitTime, $
                                 VERBOSE = VERBOSE 

; Defaults
IF ~keyword_set(isisIP) THEN isisIP = 'WinD2791' ; WinD2791 = 27" HP ; Rocket5 = 169.254.191.253, Rocket6 = 169.254.191.0
IF ~keyword_set(number_of_packets_to_store) THEN number_of_packets_to_store = 240 ; 240 packets at 3 seconds per packet is 12 minutes
IF keyword_set(time_window_to_store) THEN number_of_packets_to_store = time_window_to_store * 3 ; time_window_to_store in seconds
IF ~keyword_set(MinXSSFlightModel) THEN MinXSSFlightModel = 2
IF ~keyword_set(windowSize) THEN windowSize = [1600, 1030]
IF ~keyword_set(windowLocation) THEN windowLocation = [310, 0]
IF ~keyword_set(retryWaitTime) THEN retryWaitTime = 0.0

; Setup
numberOfPlotRows = 2
numberOfPlotColumns = 3
timeArray = JPMrange(systime(/JULIAN), systime(/JULIAN) + 5, NPTS = 100) ; Julian date

; Conversions
rad2rpm = 9.54929659643
rad2deg = 57.2957795

;;
; Create place holder plots
;;
w = window(DIMENSIONS = windowSize, LOCATION = windowLocation, /DEVICE, WINDOW_TITLE = 'MinXSS Housekeeping Data', /NO_TOOLBAR, BACKGROUND_COLOR = 'black' )
labelDate = label_date(DATE_FORMAT = ['%H', '%D'])

; Wheel speeds
p1a = plot(timeArray, findgen(n_elements(timeArray)), 'r2*-', TITLE = 'Wheel Speed [RPM]', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 2],$
           YTITLE = 'Wheel Speed [RPM]', YCOLOR = 'white', $
           XTITLE = 'Local Hour (top), Day of Month (bottom)', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XCOLOR = 'white', $
           NAME = '1')
p1b = plot(timeArray, findgen(n_elements(timeArray)) + 50, '2*-', COLOR = 'spring green', /OVERPLOT, $
           NAME = '2')
p1c = plot(timeArray, findgen(n_elements(timeArray)) + 80, '2*-', COLOR = 'deep sky blue', /OVERPLOT, $
           NAME = '3')

; Body rates
p2a = plot(timeArray, JPMRange(0, 0.5, NPTS = n_elements(timeArray)), 'r2*-', TITLE = 'Body Rates [º/sec]', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 3],$
           YTITLE = 'Body Rates [º/sec]', YCOLOR = 'white', $
           XTITLE = 'Local Hour (top), Day of Month (bottom)', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XCOLOR = 'white', $
           NAME = '1 | X')
p2b = plot(timeArray, JPMRange(0, 0.5, NPTS = n_elements(timeArray)) + 0.1, '2*-', COLOR = 'spring green', /OVERPLOT, $
           NAME = '2 | Y')
p2c = plot(timeArray, JPMRange(0, 0.5, NPTS = n_elements(timeArray)) + 0.2, '2*-', COLOR = 'deep sky blue', /OVERPLOT, $
           NAME = '3 | Z')
p2d = plot(p2a.xrange, [0.2, 0.2], '2--', COLOR = 'white', /OVERPLOT)
p2d = plot(p2a.xrange, [0.2, 0.2], '2--', COLOR = 'white', /OVERPLOT) ; Repeated because the first one expands the xrange slightly
t2 = text(p2d.xrange[1], 0.2, 'Expected IMU Bias', /DATA, ALIGNMENT = 1.0, TARGET = p2d, FONT_COLOR = 'white')
l2 = legend(TARGET = [p2a, p2b, p2c], POSITION = [0.67, 0.56], FONT_SIZE = 12, HORIZONTAL_ALIGNMENT = 'center', VERTICAL_ALIGNMENT = 'bottom')

; SPS position
p3 = bubbleplot(-0.4, 0.8, MAGNITUDE = 2E6, EXPONENT = 0.5, MAX_VALUE = 5E6, COLOR = 'gold', /SHADED, AXIS_STYLE = 3, TITLE = 'SPS Position [º]', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 6], $
                YRANGE = [-6, 6], YCOLOR = 'white', $
                XRANGE = [-6, 6], XCOLOR = 'white')
t3a = text(-6, 6, 'Total = 300 fC', /DATA, VERTICAL_ALIGNMENT = 1.0, TARGET = p3, FONT_COLOR = 'white')
t3b = text(6, 6, 'X = -0.4º', /DATA, VERTICAL_ALIGNMENT = 1.0, ALIGNMENT = 1.0, TARGET = p3, FONT_COLOR = 'white')
t3c = text(6, 5, 'Y = 0.8º', /DATA, VERTICAL_ALIGNMENT = 1.0, ALIGNMENT = 1.0, TARGET = p3, FONT_COLOR = 'white')

; COMM temperature
p4a = plot(timeArray, findgen(n_elements(timeArray)), '2*-', COLOR = 'white', TITLE = 'COMM Temperature [ºC]', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 4],$
           YTITLE = 'COMM Temperature [ºC]', YCOLOR = 'white', $
           XTITLE = 'Local Hour (top), Day of Month (bottom)', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XCOLOR = 'white')
p4b = plot(p4a.xrange, [45, 45], '2--', COLOR = 'goldenrod', /OVERPLOT)
p4b = plot(p4a.xrange, [45, 45], '2--', COLOR = 'goldenrod', /OVERPLOT) ; repeated because the first one expands the xrange slightly 
p4c = plot(p4a.xrange, [55, 55], 'r2--', /OVERPLOT)
p4d = plot(p4a.xrange, [70, 70], 'r4--', /OVERPLOT)
t4 = text(p4c.xrange[1], 70, 'Survival Limit', /DATA, ALIGNMENT = 1.0, COLOR = 'red', TARGET = p4d, FONT_COLOR = 'white')

; Battery voltage
p6a = plot(timeArray, JPMRange(8.3, 6.0, NPTS = n_elements(timeArray)), '2*-', COLOR = 'white', TITLE = 'Battery Voltage [V]', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 5], $
           YTITLE = 'Battery Voltage [V]', YRANGE = [5.5, 8.5], YCOLOR = 'white', $
           XTITLE = 'Local Hour (top), Day of Month (bottom)', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XCOLOR = 'white')
p6b = plot(p6a.xrange, [7.1, 7.1], '2--', COLOR = 'goldenrod', /OVERPLOT)
p6b = plot(p6a.xrange, [7.1, 7.1], '2--', COLOR = 'goldenrod', /OVERPLOT) ; repeated because the first call expands the xrange slightly
p6c = plot(p6a.xrange, [6.9, 6.9], 'r2--', /OVERPLOT)
p6d = plot(p6a.xrange, [6.0, 6.0], 'r4--', /OVERPLOT)
t6b = text(p6a.xrange[1], 7.1, 'Science->Safe', /DATA, ALIGNMENT = 1.0, COLOR = 'goldenrod', TARGET = p6b, FONT_COLOR = 'white')
t6c = text(p6a.xrange[1], 6.9, 'Safe->Phoenix', /DATA, ALIGNMENT = 1.0, COLOR = 'red', TARGET = p6c, FONT_COLOR = 'white')
t6d = text(p6a.xrange[1], 6.0, 'Dead Battery', /DATA, ALIGNMENT = 1.0, COLOR = 'red', TARGET = p6d, FONT_COLOR = 'white')

; Identifier information
;im = image('/Users/minxss/Pictures/All Pictures as of 20151217/MinXSS CubeSat Logo White.png', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 1])
t_ = text(0.17, 0.55, 'Flight Model ' + strtrim(string(MinXSSFlightModel), 2), TARGET = im, FONT_SIZE = 26, FONT_NAME = 'Courier', FONT_STYLE = 'Bold', ALIGNMENT = 0.5, FONT_COLOR = 'white')
t_ = text(0.17, 0.53, 'IP = ' + strtrim(string(isisIP)), TARGET = im, FONT_SIZE = 15, ALIGNMENT = 0.5, FONT_COLOR = 'white')
t = text(1.0, 0.0, 'Last refresh: ' + JPMsystime(), ALIGNMENT = 1.0, FONT_COLOR = 'white')

; Open up a socket to the ISIS computer stream
; Ports:
; 10000 = housekeeping
; 10001 = science
; 10002 = SD card playback

socketErrorCounter = 0
keepGoing = 1
hk = !NULL
timeArray = !NULL

WHILE keepGoing DO BEGIN ; Infinite loop to reopen socket on error
  IF keyword_set(verbose) THEN message, /info, JPMsystime() + " -- " + "Opening socket to " + isisIP + ":10000 ..."
  socket, lun, isisIP, 10000, ERROR = socketError, CONNECT_TIMEOUT = 5. * (socketErrorCounter EQ 0 ? 1 : 12), /RAWIO, /GET_LUN ; timeout is in seconds
  
  IF (socketError NE 0) THEN BEGIN
    message, /info, JPMsystime() + " -- " + "Could not open socket to " + isisIP + ":10000 ... retrying! (60 sec timeout)"
    socketErrorCounter++
    kbrdInput = get_kbrd(0, /escape)
    IF (kbrdInput EQ string([27b, 113b])) THEN BEGIN
      IF keyword_set(verbose) THEN message, /info, "Received QUIT [ESC-Q]..."
      keepGoing = 0
    ENDIF
    CONTINUE
  ENDIF ELSE BEGIN
    message, /info, JPMsystime() + " -- " + "Successfully opened socket to " + isisIP + ":10000 ... waiting for data ..."
    socketErrorCounter = 0
  ENDELSE
  
  ; If the socket opened OK, then...
  WHILE (socketError eq 0) DO BEGIN
  
    ; Start a timer
    wrapperClock = TIC()

    kbrdInput = get_kbrd(0, /escape)
    IF (kbrdInput EQ string([27b, 113b])) THEN BEGIN
      IF keyword_set(verbose) THEN message, /info, "Received QUIT [ESC-Q]..."
      keepGoing = 0
      socketError = 1
      CONTINUE
    ENDIF ELSE IF (kbrdInput EQ string([27b, 114b])) THEN BEGIN
      IF keyword_set(verbose) THEN message, /info, "Received RECYCLE [ESC-R]..."
      socketError = 1
      CONTINUE
    ENDIF ELSE IF (kbrdInput EQ string([27b, 115b])) THEN BEGIN
      IF keyword_set(verbose) THEN message, /info, "Received SAVE [ESC-S]..."
      filename = '/Users/minxss/Desktop/MinXSS-1 ScreenShots/HK Screenshot ' + systime() + '.png'
      w.save, filename, resolution = 96
      IF keyword_set(verbose) THEN message, /info, "Wrote screenshot to " + filename
    ENDIF
    
    ; Trigger when data shows up on port then write single packet to file
    IF file_poll_input(lun, TIMEOUT = 60.0d) THEN BEGIN ; Timeout is in seconds
      
      ; Read data on the socket
      IF ((fstat(lun)).size NE 0) THEN BEGIN
        socketData = bytarr((fstat(lun)).size)
        readu, lun, socketData
      ENDIF ELSE BEGIN
        socketError = 1
        message, /info, JPMsystime() + " -- " + "EOF reached on socket... trying to reopen in " + strtrim(retryWaitTime) + " seconds..."
        wait, retryWaitTime
        CONTINUE
      ENDELSE

      ; We're only here if the socket had data on it...
      minxss_read_packets, socketData, hk = hkTemp, log = logTemp, verbose = verbose
      
      FOR i = 0, n_elements(logTemp) - 1 DO BEGIN
        timejd = gps2jd(log[i].time)
        timeyd = jd2yd(timejd)
        caldat, timejd, Month, Day, Year, Hour, Minute, Second
        DOY = long(timeyd) MOD 1000L
        timestr = string(long(Year),format='(I04)') + '-' + string(long(Month),format='(I02)') + $
                  '-' + string(long(Day),format='(I02)') + ' ' + string(DOY,format='(I03)') + $
                  ' ' + string(long(Hour),format='(I02)') + ':' + string(long(Minute),format='(I02)') + $
                  ':' + string(long(Second),format='(I02)')
        print, 'LOG: ' + timestr + ' -- ' + log[i].message
      ENDFOR
        
      ; -= MANIPULATE DATA AS NECESSARY =- ;
      hk = [hk, hkTemp[-1]] ; Occasionally get 2 hk packets in hkTemp for some reason, so only grab the last one
      spacecraftTimeGps = hk[-1].time
      jd = gps2jd(spacecraftTimeGps)
      timeArray = [timeArray, jd]
      
      ; -= UPDATE PLOT WINDOW =- ;
      !Except = 0 ; Disable annoying divide by 0 messages    
      
      ; Wheel speeds
      p1a.SetData, timeArray, hk.XACT_WHEEL1MEASSPEED * rad2rpm
      p1b.SetData, timeArray, hk.XACT_WHEEL2MEASSPEED * rad2rpm
      p1c.SetData, timeArray, hk.XACT_WHEEL3MEASSPEED * rad2rpm
      
      ; Body rates
      p2a.SetData, timeArray, hk.XACT_BODYFRAMERATEX * rad2deg
      p2b.SetData, timeArray, hk.XACT_BODYFRAMERATEY * rad2deg
      p2c.SetData, timeArray, hk.XACT_BODYFRAMERATEZ * rad2deg
      ;p2d = plot([timeArray[0], timeArray[-1]], [0.2, 0.2], '2--', /OVERPLOT)
      ;p2d = plot([timeArray[0], timeArray[-1]], [0.2, 0.2], '2--', /OVERPLOT) ; repeated because the first call expands the xrange slightly
      
      ; SPS position
      spsXdeg = hkTemp.sps_x / 10000. * 3. ; convert to degrees
      spsYdeg = hkTemp.sps_y / 10000. * 3. ; convert to degrees
      p3.SetData, spsXdeg, spsYdeg
      p3.MAGNITUDE = hkTemp.sps_sum
      t3a.STRING = 'Total = ' + JPMPrintNumber(hkTemp.sps_sum, /NO_DECIMALS) + ' fC'
      t3b.STRING = 'X = ' + JPMPrintNumber(spsXdeg) + 'º'
      t3c.STRING = 'Y = ' + JPMPrintNumber(spsYdeg) + 'º'
      
      ; COMM temperature
      p4a.SetData, timeArray, hk.COMM_TEMP
      ;p4b = plot([timeArray[0], timeArray[-1]], [45, 45], '2--', COLOR = 'goldenrod', /OVERPLOT)
      ;p4b = plot([timeArray[0], timeArray[-1]], [45, 45], '2--', COLOR = 'goldenrod', /OVERPLOT) ; repeated because the first one expands the xrange slightly
      ;p4c = plot([timeArray[0], timeArray[-1]], [55, 55], 'r2--', /OVERPLOT)
      ;p4d = plot([timeArray[0], timeArray[-1]], [70, 70], 'r4--', /OVERPLOT)
      
      ; Battery voltage
      p6a.SetData, timeArray, hk.EPS_FG_VOLT
      ;p6b = plot([timeArray[0], timeArray[-1]], [7.1, 7.1], '2--', COLOR = 'goldenrod', /OVERPLOT)
      ;p6b = plot([timeArray[0], timeArray[-1]], [7.1, 7.1], '2--', COLOR = 'goldenrod', /OVERPLOT) ; repeated because the first call expands the xrange slightly
      ;p6c = plot([timeArray[0], timeArray[-1]], [6.9, 6.9], 'r2--', /OVERPLOT)
      ;p6d = plot([timeArray[0], timeArray[-1]], [6.0, 6.0], 'r4--', /OVERPLOT)
      
      !Except = 1 ; Re-enable math error logging
      
      ; Update text
      t.STRING = 'Last refresh: ' + JPMsystime()
      IF (!VERSION.OS EQ 'darwin') THEN spawn, '(afplay /System/Library/Sounds/Submarine.aiff &)' ELSE beep
  
    ENDIF ELSE BEGIN
      message, /INFO, JPMsystime() + " -- " + 'Socket connected but no data posted within 60 seconds.'
    ENDELSE
    
    
;    IF n_elements(logTemp) GT 0 THEN FOR i = 0, n_elements(logTemp)-1 DO print, 'LOG: ' + logTemp[i].message
    
    ; Reset values to nonexistent so that we don't hold old variables
    hkTemp = !NULL
    
    IF TOC(wrapperClock) GE 5 THEN $
      message, /INFO, 'Completed in time = ' +  JPMPrintNumber(TOC(wrapperClock))
  ENDWHILE ; Process socket
  filename = '/Users/minxss/Desktop/MinXSS-1 ScreenShots/HK Screenshot ' + JPMsystime() + '.png'
  w.save, filename, resolution = 96
  IF keyword_set(verbose) THEN message, /info, "Wrote screenshot to " + filename
  free_lun, lun
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
IF (lun NE !NULL) THEN free_lun, lun

END