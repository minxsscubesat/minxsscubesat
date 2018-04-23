;+
; NAME:
;   minxss_real_time_socket_read_wrapper_adcs
;
; PURPOSE:
;   Wrapper script for reading from an ISIS socket specific to housekeeping data. Calls minxss_read_packets and minxss_science_display when new data comes over the pipe.
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
;   2014/12/11: James Paul Mason: Wrote script
;   2015/01/15: James Paul Mason: Added JPMPrintNumber to sensibly truncate the completion time output
;   2015/08/28: James Paul Mason: Updated to minxss_read_packets37 and using plotting experience from StarTestAdcsTelemetryPlots.pro
;   2015/08/30: James Paul Mason: Messed with code to try to get systemMomentum to work, but still plots funny. 
;                                 Also fixed timeArray. Integral erorr still reading 0 all the time but need real air bearing test to verify. 
;-
PRO minxss_real_time_socket_read_wrapper_adcs, isisIP = isisIP, number_of_packets_to_store = number_of_packets_to_store, MinXSSFlightModel = MinXSSFlightModel, $
                                               windowSize = windowSize, time_window_to_store = time_window_to_store

  ; Defaults
  IF ~keyword_set(isisIP) THEN isisIP = '192.168.1.75' ;'WinD2791' ; WinD2791 = 27" HP ; Rocket5 = 169.254.191.253, Rocket6 = 169.254.191.0
  IF ~keyword_set(number_of_packets_to_store) THEN number_of_packets_to_store = 24 
  IF keyword_set(time_window_to_store) THEN number_of_packets_to_store = time_window_to_store / 5 ; time_window_to_store in seconds
  IF ~keyword_set(MinXSSFlightModel) THEN MinXSSFlightModel = 1
  IF ~keyword_set(windowSize) THEN windowSize = [1600, 800]

  ; Setup
  numberOfPlotRows = 2
  numberOfPlotColumns = 3
  sciPacketBusy = 0
  timeArray = JPMrange(0, number_of_packets_to_store * 5, inc = 5) ; [s]
  
  ; Conversions
  rad2rpm = 9.54929659643
  rad2deg = 57.2957795

  ; Create place holder plots
  w = window(DIMENSIONS = windowSize, /DEVICE, WINDOW_TITLE = 'MinXSS ADCS Data', /NO_TOOLBAR)
  
  ; Wheel speeds plot
  p0a = plot(findgen(10), findgen(10), 'r2', TITLE = 'Wheel Speed', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 2], $
            YTITLE = 'Wheel Speed [RPM]', $
            XTITLE = 'Time [s]', $
            NAME = '1')
  p0b = plot(findgen(10), findgen(10) + 1, 'g2', /OVERPLOT, $
             NAME = '2')
  p0c = plot(findgen(10), findgen(10) + 2, 'b2', /OVERPLOT, $
             NAME = '3')
  l0 = legend(TARGET = [p0a, p0b, p0c], POSITION = [0.5, 0.4], FONT_SIZE = 12, HORIZONTAL_ALIGNMENT = 'center', VERTICAL_ALIGNMENT = 'bottom')
  
  ; Tracked stars plot
  p1a = plot(findgen(10), findgen(10), '10', TITLE = 'Tracked Star Statistics',  /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 6],$
             XTITLE = 'Time [s]', $
             YTITLE = 'Number Count', $
             NAME = 'Stars Used in Attitude')
  p1b = plot(findgen(10), findgen(10) + 1, 'r2', /OVERPLOT, $
            NAME = 'Stars on FOV')
  p1c = plot(findgen(10), findgen(10) + 2, 'g2', /OVERPLOT, $
            NAME = 'Tracked Stars')
  p1d = plot(findgen(10), findgen(10) + 3, 'b2', /OVERPLOT, $
            NAME = 'ID Stars')
  p1e = plot(findgen(10), findgen(10) + 4, '2', COLOR = 'orange', /OVERPLOT, $
            NAME = 'Bright Stars')
  l1 = legend(TARGET = [p1a, p1b, p1c, p1d, p1e], POSITION = [0.6, 0.17], HORIZONTAL_ALIGNMENT = 'center', VERTICAL_ALIGNMENT = 'bottom')  
  
  ; Attitude integral error plot
  p2a = plot(findgen(10), findgen(10), 'r2', TITLE = 'Attitude Integral Error', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 3], $
             XTITLE = 'Time [s]', $
             YTITLE = 'Attitude Integral Error [º]', $
             NAME = '1')
  p2b = plot(findgen(10), findgen(10) + 2, 'g2', /OVERPLOT, $
             NAME = '2')
  p2c = plot(findgen(10), findgen(10) + 3, 'b2', /OVERPLOT, $
             NAME = '3')
  
  ; System momentum components plot
  p3a = plot(findgen(10), findgen(10), 'r2', TITLE = 'System Momentum Components', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 4], $
             XTITLE = 'Time [s]', $
             YTITLE = 'System Momentum [Nms]', $
             NAME = '1')
  p3b = plot(findgen(10), findgen(10) + 2, 'g2', /OVERPLOT, $
             NAME = '2')
  p3c = plot(findgen(10), findgen(10) + 3, 'b2', /OVERPLOT, $
             NAME = '3')
  
  ; System momentum total plot
  p4a = plot(findgen(10), findgen(10) + 1, '2', COLOR = 'orange', TITLE = 'System Momentum Total', /CURRENT, LAYOUT = [numberOfPlotColumns, numberOfPlotRows, 1], $
             XTITLE = 'Time [s]', $
             YTITLE = 'System Momentum [Nms]', YRANGE = [0, 0.015], $
             NAME = 'Total')
  p4b = plot(p4a.XRANGE, [0.011, 0.011], '2--', COLOR = 'orange', /OVERPLOT, $
             NAME = 'Wheel Cutoff')
  
  t1 = text(0.5, 0.1, 'Sun Point Status: PeanutButterJelly', FONT_SIZE = 14, ALIGNMENT = 1.0)
  t2 = text(0.5, 0.05, 'Attitude Valid: ', FONT_SIZE = 14, ALIGNMENT = 1.0)
  t3 = text(0.5, 0.0, 'Mode: PeanutButterJelly', FONT_SIZE = 14, ALIGNMENT = 1.0)
  t = text(0.0, 0.0, 'Last refresh: ' + systime())
  sunBodyStatus = '' & attitudeValid = '' & adcsMode = ''
  
  ; Open up a socket to the ISIS computer stream
  ; Ports:
  ; 10000 = housekeeping
  ; 10001 = science
  ; 10002 = SD card playback
  ; 10003 = ADCS pages 1-4
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
      socketData = socketDataTmp

      minxss_read_packets, socketData, adcs1=adcs1Temp, adcs2=adcs2Temp, adcs3=adcs3Temp, adcs4=adcs4Temp

      ; The first time through this loop, create the array for time series
      IF adcs2Temp NE !NULL THEN IF n_elements(adcs2) EQ 0 THEN BEGIN
        adcs2Counter = 0
        adcs2 = replicate(adcs2Temp[0], number_of_packets_to_store)
      ENDIF
      IF adcs3Temp NE !NULL THEN IF n_elements(adcs3) EQ 0 THEN BEGIN
        adcs3Counter = 0
        adcs3 = replicate(adcs3Temp[0], number_of_packets_to_store)
        totalMomentum = dblarr(number_of_packets_to_store)
      ENDIF
      IF adcs2Temp EQ !NULL AND adcs3Temp EQ !NULL THEN CONTINUE
      

      ; Fill up the time series array
      IF adcs2Temp NE !NULL THEN BEGIN
        numberOfFreeSlots = number_of_packets_to_store - adcs2Counter
        IF numberOfFreeSlots GE n_elements(adcs2Temp) THEN BEGIN
          adcs2[adcs2Counter:adcs2Counter + n_elements(adcs2Temp) - 1] = adcs2Temp
          adcs2Counter += n_elements(adcs2Temp)
        ENDIF ELSE BEGIN ; Array is full so need to shift
          adcs2 = shift(temporary(adcs2), -(n_elements(adcs2Temp) - numberOfFreeSlots))
          adcs2[-n_elements(adcs2Temp):-1] = adcs2Temp
          adcs2Counter = number_of_packets_to_store ; Now at max
        ENDELSE
      ENDIF
      IF adcs3Temp NE !NULL THEN BEGIN
        numberOfFreeSlots = number_of_packets_to_store - adcs3Counter
        IF numberOfFreeSlots GE n_elements(adcs3Temp) THEN BEGIN
          adcs3[adcs3Counter:adcs3Counter + n_elements(adcs3Temp) - 1] = adcs3Temp
          totalMomentum[adcs3Counter:adcs3Counter + n_elements(adcs3Temp) - 1] = sqrt(adcs3Temp.SYSTEM_MOMENTUM1^2 + adcs3Temp.SYSTEM_MOMENTUM2^2 + adcs3Temp.SYSTEM_MOMENTUM3^2)
          adcs3Counter += n_elements(adcs3Temp)
        ENDIF ELSE BEGIN ; Array is full so need to shift
          adcs3 = shift(temporary(adcs3), -(n_elements(adcs3Temp) - numberOfFreeSlots))
          adcs3[-n_elements(adcs3Temp):-1] = adcs3Temp
          totalMomentum = shift(temporary(totalMomentum), -(n_elements(adcs3Temp) - numberOfFreeSlots))
          totalMomentum[-n_elements(adcs3Temp):-1] = sqrt(adcs3Temp.SYSTEM_MOMENTUM1^2 + adcs3Temp.SYSTEM_MOMENTUM2^2 + adcs3Temp.SYSTEM_MOMENTUM3^2)
          adcs3Counter = number_of_packets_to_store ; Now at max
        ENDELSE
      ENDIF
      
      ; -= MANIPULATE DATA AS NECESSARY =- ;
      IF adcs4Temp NE !NULL THEN BEGIN
        IF adcs4Temp[0].SUNBODY_STATUS EQ 0 THEN sunBodyStatus = 'Good'
        IF adcs4Temp[0].SUNBODY_STATUS EQ 1 THEN sunBodyStatus = 'Coarse'
        IF adcs4Temp[0].SUNBODY_STATUS EQ 2 THEN sunBodyStatus = 'Bad'
      ENDIF
      IF adcs2Temp NE !NULL THEN BEGIN
        IF adcs2Temp.ATTITUDE_VALID EQ 0 THEN attitudeValid = 'No'
        IF adcs2Temp.ATTITUDE_VALID EQ 1 THEN attitudeValid = 'Yes'
        IF adcs2Temp.ADCS_MODE EQ 0 THEN adcsMode = 'Sun Point'
        IF adcs2Temp.ADCS_MODE EQ 1 THEN adcsMode = 'Fine Ref'
      ENDIF
      
      ; -= UPDATE PLOT WINDOW =- ;

      ; Update plots
      !Except = 0 ; Disable annoying divide by 0 messages
      
      ; Wheel speeds
      IF adcs2Temp NE !NULL THEN BEGIN
        p0a.SetData, timeArray[0:adcs2Counter - 1], adcs2[0:adcs2Counter - 1].WHEEL_MEAS_SPEED1 * rad2rpm
        p0b.SetData, timeArray[0:adcs2Counter - 1], adcs2[0:adcs2Counter - 1].WHEEL_MEAS_SPEED2 * rad2rpm           
        p0c.SetData, timeArray[0:adcs2Counter - 1], adcs2[0:adcs2Counter - 1].WHEEL_MEAS_SPEED3 * rad2rpm
      ENDIF
      
      IF adcs3Temp NE !NULL THEN BEGIN
        ; Tracked star statistics
        p1a.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].NUM_STARS_USED_IN_ATTITUDE
        p1b.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].NUM_STARS_ON_FOV
        p1c.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].NUM_TRACKED_STARS
        p1d.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].NUM_ID_STARS
        p1e.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].NUM_BRIGHT_STARS
        
        ; Attitude integral error plot
        p2a.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].INTEGRAL_ERROR1 * rad2deg
        p2b.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].INTEGRAL_ERROR2 * rad2deg
        p2c.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].INTEGRAL_ERROR3 * rad2deg
        
        ; System momentum plot
        p3a.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].SYSTEM_MOMENTUM1
        p3b.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].SYSTEM_MOMENTUM2
        p3c.SetData, timeArray[0:adcs3Counter - 1], adcs3[0:adcs3Counter - 1].SYSTEM_MOMENTUM3
        p4a.SetData, timeArray[0:adcs3Counter - 1], totalMomentum[0:adcs3Counter - 1]
        p4b.SetData, p4a.XRANGE, [0.011, 0.011]
      ENDIF
      
      ; Update text
      t1.STRING =  'Sun Point Status: ' + sunBodyStatus
      t2.STRING = 'Attitude Valid: ' + attitudeValid
      t3.STRING = 'XACT Mode: ' + adcsMode
      t.STRING = 'Last refresh: ' + systime()

    ENDIF ELSE message, /INFO, 'Socket connected but no data posted within 60 seconds.'

    IF n_elements(logTemp) GT 0 THEN FOR i = 0, n_elements(logTemp)-1 DO print, 'LOG: ' + logTemp[i].message

    ; Reset values to nonexistant so that we don't hold old variables
    adcs1Temp = !NULL
    adcs2Temp = !NULL
    adcs3Temp = !NULL
    adcs4Temp = !NULL

  ENDWHILE ; Infinite loop

  ; These lines never get called since the only way to exit the above infinite loop is to stop the code
  free_lun, lun
  free_lun, lun2

END