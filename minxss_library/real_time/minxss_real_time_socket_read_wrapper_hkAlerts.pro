;+
; NAME:
;   minxss_real_time_socket_read_wrapper_hkAlerts
;
; PURPOSE:
;   Wrapper script for reading housekeeping from an ISIS socket. Will send email if a monitor is found out of limits. 
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
;   emailAddress [string]:                An email address to alert if a housekeeping monitor is out of range. Default is James Paul Mason (jmason86@gmail.com)
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
;   Requires JPMRange.pro
;   Requires JPMPrintNumber.pro
;
; EXAMPLE:
;   Just hit run! 
;
; MODIFICATION HISTORY:
;   2015/01/20: James Paul Mason: Wrote Script
;-
PRO minxss_real_time_socket_read_wrapper_hkAlerts, isisIP = isisIP, number_of_packets_to_store = number_of_packets_to_store, MinXSSFlightModel = MinXSSFlightModel, $
                                                   windowSize = windowSize, time_window_to_store = time_window_to_store, $
                                                   emailAddress = emailAddress

; Defaults
IF ~keyword_set(isisIP) THEN isisIP = 'WinD2791' ; WinD2791 = 27" HP ; Rocket5 = 169.254.191.253, Rocket6 = 169.254.191.0
IF ~keyword_set(number_of_packets_to_store) THEN number_of_packets_to_store = 40 ; When set to 1000 this code takes about 45 seconds to complete
IF keyword_set(time_window_to_store) THEN number_of_packets_to_store = time_window_to_store * 3 ; time_window_to_store in seconds
IF ~keyword_set(MinXSSFlightModel) THEN MinXSSFlightModel = 1
IF ~keyword_set(windowSize) THEN windowSize = [1066, 450]

; Setup
numberOfPlotRows = 1
numberOfPlotColumns = 2
sciPacketBusy = 0
timeArray = JPMrange(0, number_of_packets_to_store * 3, inc = 3) ; Seconds

; Create place holder plots
;w = window(DIMENSIONS = windowSize, /DEVICE, WINDOW_TITLE = 'MinXSS ADCS Data')
;p0a = plot(findgen(10), findgen(10) + 1, 'r2*-', TITLE = 'Wheel Speed', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 1], $
;           YTITLE = 'Wheel Speed [rad/sec]', $
;           XTITLE = 'Time [s]', $
;           NAME = 'Wheel 1 Speed')
;p0b = plot(findgen(10), findgen(10) + 2, 'g2*-', /OVERPLOT, $
;           NAME = 'Wheel 2 Speed')
;p0c = plot(findgen(10), findgen(10), 'b2*-', /OVERPLOT, $
;           NAME = 'Wheel 3 Speed')
;p0d = plot(findgen(10), fltarr(10) + 8, '4', /OVERPLOT, $
;           NAME = 'Saturation Limit')
;l0 = legend(TARGET = [p0a, p0b, p0c, p0d], POSITION = [0.58, 0.9], FONT_SIZE = 12)
;t1 = text(1.0, 0.2, 'Sun Point Status: PeanutButterJelly', FONT_SIZE = 20, ALIGNMENT = 1.0)
;t2 = text(1.0, 0.1, 'Attitude Valid: ', FONT_SIZE = 20, ALIGNMENT = 1.0)
;t3 = text(1.0, 0.0, 'Mode: PeanutButterJelly', FONT_SIZE = 20, ALIGNMENT = 1.0)

; Open up a socket to the ISIS computer stream
; Ports:
; 10000 = housekeeping
; 10001 = science
; 10002 = SD card playback
get_lun, lun
socket, lun, isisIP, 10000, ERROR = socketError, CONNECT_TIMEOUT = 5, /RAWIO ; timeout is in seconds

; Start an infinite loop
WHILE 1 DO BEGIN

  ; Start a timer
  wrapperClock = TIC()

  ; Trigger when data shows up on port then write single packet to file
  IF file_poll_input(lun, TIMEOUT = 60.0d) THEN BEGIN ; Timeout is in seconds

    ; Read data on the socket
    socketDataTmp = bytarr((fstat(lun)).size)
    readu, lun, socketDataTmp
    socketData = socketDataTmp
    
    minxss_read_packets, socketData, hk=hkTemp, sci=sciTemp, adcs1=adcsTemp, log=logTemp, diag=diagTemp, xactimage=imageTemp
    
    MinXSSHKRealTimeMonitor, hkTemp, emailAddress = emailAddress
    
    ; The first time through this loop, create the array for time series
    IF hkTemp NE !NULL THEN IF n_elements(hk) EQ 0 THEN BEGIN
      hkCounter = 0
      hk = replicate(hkTemp[0], number_of_packets_to_store)
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

    ; -= UPDATE PLOT WINDOW =- ;

    ; Update plots
;    !Except = 0 ; Disable annoying divide by 0 messages
;    p0a.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].XACT_WHEEL1MEASSPEED / 4.15411e+06
;    p0b.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].XACT_WHEEL2MEASSPEED / 4.15411e+06           
;    p0c.SetData, timeArray[0:hkCounter - 1], hk[0:hkCounter - 1].XACT_WHEEL3MEASSPEED / 4.15411e+06
;    p0d.SetData, p0a.XRANGE, fltarr(n_elements(hkCounter) > 2) + 700.0
;
;    ; Update text
;    t1.STRING =  'Sun Point Status: Need IDL Update'
;    t2.STRING = 'Attitude Valid: Need IDL Update'
;    t3.STRING = 'XACT Mode: Need IDL Update'

  ENDIF ELSE message, /INFO, 'Socket connected but no data posted within 60 seconds.'

  IF n_elements(logTemp) GT 0 THEN FOR i = 0, n_elements(logTemp)-1 DO print, 'LOG: ' + logTemp[i].message

  ; Reset values to nonexistant so that we don't hold old variables
  hkTemp = !NULL
  sciTemp = !NULL
  adcsTemp = !NULL
  logTemp = !NULL
  diagTemp = !NULL
  imageTemp = !NULL

  IF TOC(wrapperClock) GE 5 THEN $
    message, /INFO, 'Completed in time = ' +  JPMPrintNumber(TOC(wrapperClock))
  
  IF TOC(wrapperClock) GE 120.0 THEN $
    spawn, 'echo "No beacons received for two minutes!" | mailx -s "MinXSS CubeSat HK Alert" ' + emailAddress
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, lun
free_lun, lun2
END