;+
; NAME:
;   rocket_eve_tm1_real_time_display
;
; PURPOSE:
;   Wrapper script for reading from a remote socket. Calls rocket_eve_tm1_read_packets (the interpreter) when new data comes over the pipe. 
;
; INPUTS:
;   port [integer]: The port number to open that DEWESoft will be commanded to stream data to. This requires that both machines are running on the same network.
;                   This is provided as an optional input only so that a hardcoded value can be specified and the IDLDE Run button hit, instead
;                   of needing to call the code from the command line each time. However, a known port is really is necessary.
;
; OPTIONAL INPUTS:
;   windowSize [integer, integer]:     Set this to the pixel dimensions in [x, y] that you want the display. Default is [1000, 800].
;   frequencyOfImageDisplay [integer]: The refresh rate of images in the fun units of number of DEWESoftPackets per refresh. 
;
; KEYWORD PARAMETERS:
;   IS_ASYNCHRONOUSDATA: Set this if the DEWESoft software is using a synchronous byte definition for your channels. Asynchronous data has a timestamp on every sample, 
;                        which increases the byte stream size by a factor of 5. 
;   DEBUG:               Set to print debugging information, such as the sizes of and listed in the packets.
;   LIGHT_BACKGROUND:    Set this to use a white background and dark font instead of the default (black background and white font)
;
; OUTPUTS:
;   Produces 3 plot panes with all the most important data in the world, displayed in real time from a remote socket.
;
; OPTIONAL OUTPUTS:
;   None
;   
; COMMON BLOCK VARIABLES: 
;   See rocket_eve_tm1_read_packets for a detailed description. And yes, I know common blocks are bad practice. However, we wanted socket reader / data interpreter modularity but still
;   require persistent data between the two. Passing variables back and forth between two functions is done by reference, but would result in messy code. So here we are with common blocks. 
;
; RESTRICTIONS:
;   Requires that the data pipe computer IS NOT YET RUNNING. See procedure below for the critical step-by-step to get the link up. 
;   Requires JPMRange.pro
;   Requires JPMPrintNumber.pro
;
; PROCEDURE: 
;   Prior to running this code: 
;   0) Make sure your computer is on only one network i.e. turn off wifi if connected to the DEWESoft machine with ethernet (crossover cable)
;   1) Connect this machine to a network with the machine running DEWESoft. This can be done with a crossover cable connecting their two ethernet ports. 
;   2) Open a terminal (e.g., terminal.app in OSX)
;   3) type: telnet ipAddress 8999 (where ipAddress is the IP address (duh) of the DEWESoft machine e.g., telnet 192.168.1.90 8999. 
;            8999 is the commanding port and should not need to be changed). You should get an acknowledgement: +CONNECTED DEWESoft TCP/IP server. 
;   4) type: listusedchs (This should return a list of all channels being used. EVE data is in three parallel streams, P1, P2, and P3. 
;            Note the corresponding channel numbers. For EVE these are ch 13, 14, and 12, respectively).
;   5) type: /stx preparetransfer
;   6) type: ch 13
;            ch 14
;            ch 12 (or whatever your relevant channel number/s are).
;   7) type: /etx You should get an acknowledgement: +OK
;   8) NOW you can start this code. It will open the port specified in the input parameter, or use the hard-coded default if not provided in the call. Then it will STOP. Don't continue yet. 
;   Back to the terminal window
;   9) type: starttransfer port (where port is the same port IDL is using in step 8 above, e.g., starttransfer 8002)
;   10) type: setmode 1 You'll either see +ERR Already in this mode or +OK Mode 1 (control) selected, 
;             depending on if you've already done this step during debugging this when it inevitably doesn't work the first time. 
;   11) type: startacq You should get an acknowledgement: +OK Acquiring
;   12) NOW you can continue running this code
;
; EXAMPLE:
;   See PROCEDURE above for examples of each step. 
;
; MODIFICATION HISTORY:
;   2017-08-08: James Paul Mason: Wrote script based on rocket_eve_tm2_real_time_display.
;-
PRO rocket_eve_tm1_real_time_display, port = port, IS_ASYNCHRONOUSDATA = IS_ASYNCHRONOUSDATA, windowSize = windowSize, $
                                      frequencyOfImageDisplay = frequencyOfImageDisplay, noMod256 = noMod256, $
                                      DEBUG = DEBUG, DEBUG2 = DEBUG2, LIGHT_BACKGROUND = LIGHT_BACKGROUND
                                    
; COMMON blocks for use with rocket_eve_tm1_read_packets. The blocks are defined here and there to allow them to be called independently.
; TODO: Common buffers may not be needed at all since that function returns a structure directly
COMMON MONITORS_PERSISTENT_DATA, monitorsBuffer
COMMON DEWESOFT_PERSISTENT_DATA, sampleSizeDeweSoft, offsetP1, numberOfDataSamplesP1, offsetP2, numberOfDataSamplesP2, offsetP3, numberOfDataSamplesP3 ; Note P1 = MEGS-A, P2 = MEGS-B, P3 = XRI

; Defaults
port = read_csv('~/Dropbox/Development/IDLWorkspace/Rocket/test_port.txt')
port = (uint(byte(port.field1[0]), 0, 2))[1] ; Just for testing
IF ~keyword_set(port) THEN port = 8002
IF keyword_set(IS_ASYNCHRONOUSDATA) THEN sampleSizeDeweSoft = 10 ELSE sampleSizeDeweSoft = 2
IF ~keyword_set(windowSize) THEN windowSize = [1000, 800]
IF ~keyword_set(frequencyOfImageDisplay) THEN frequencyOfImageDisplay = 8
IF keyword_set(LIGHT_BACKGROUND) THEN BEGIN
  fontColor = 'black'
  backgroundColor = 'white'
  boxColor = 'light steel blue'
  blueColor = 'blue'
  redColor = 'red'
ENDIF ELSE BEGIN
  fontColor = 'white'
  backgroundColor = 'black'
  boxColor = 'midnight blue'
  blueColor = 'light sky blue'
  redColor = 'salmon'
ENDELSE
fontSize = 14

; Mission specific setup. Edit this to tailor data.
; e.g., instrument calibration arrays such as gain to be used in the MANIPULATE DATA section below

; -= CREATE PLACE HOLDER PLOTS =- ;
; Edit here to change axis ranges, titles, locations, etc. 
textVSpacing = 0.05 ; Vertical spacing
textHSpacing = 0.02 ; Horizontal spacing
topLinePosition = 0.90

; Monitors
; Note that all of the t = below are just static labels so they do not need unique variables
wa = window(DIMENSIONS = windowSize, /NO_TOOLBAR, LOCATION = [0, 0], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'Monitors')

; Left column
t =     text(0.25, 0.95, 'Payload', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.4, topLinePosition, 'A23 Exp +28V Monitor = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta23 =  text(0.4 + textHSpacing, topLinePosition, '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (1 * textVSpacing), 'A124 TM Exp Bus Volt [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta124 = text(0.4 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (2 * textVSpacing), 'A106 TM Exp Bus Curr [A] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta106 = text(0.4 + textHSpacing, topLinePosition - (2 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (4 * textVSpacing), 'A25 Vac Valve Position = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta25 =  text(0.4 + textHSpacing, topLinePosition - (4 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (5 * textVSpacing), 'A13 Solar Section Pressure = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta13 =  text(0.4 + textHSpacing, topLinePosition - (5 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (7 * textVSpacing), 'A14 CryoCooler Cold Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta14a = text(0.4 + textHSpacing, topLinePosition - (7 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (8 * textVSpacing), 'A14 Cryo Cold Finger Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta14b = text(0.4 + textHSpacing, topLinePosition - (8 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (10 * textVSpacing), 'A29 FPGA +5V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta29 =  text(0.4 + textHSpacing, topLinePosition - (10 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (11 * textVSpacing), 'A30 Camera +12V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta30 =  text(0.4 + textHSpacing, topLinePosition - (11 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.25, topLinePosition - (12 * textVSpacing), 'XPS', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.4, topLinePosition - (13 * textVSpacing), 'A7 XPS +5V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta7 =   text(0.4 + textHSpacing, topLinePosition - (13 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)

; Right column
t =     text(0.75, 0.95, 'MEGS', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.9, topLinePosition, 'A3 MEGS A Heater = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta3 =   text(0.9 + textHSpacing, topLinePosition, '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (1 * textVSpacing), 'A15 MEGS B Heater = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta15 =  text(0.9 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (2 * textVSpacing), 'A19 MEGS A CCD Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta19 =  text(0.9 + textHSpacing, topLinePosition - (2 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (3 * textVSpacing), 'A20 MEGS B CCD Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta20 =  text(0.9 + textHSpacing, topLinePosition - (3 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (5 * textVSpacing), 'A31 MEGS A FF Lamp = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta31 =  text(0.9 + textHSpacing, topLinePosition - (5 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (6 * textVSpacing), 'A32 MEGS B FF Lamp = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta32 =  text(0.9 + textHSpacing, topLinePosition - (6 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (8 * textVSpacing), 'A1 MEGS-P Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta1 =   text(0.9 + textHSpacing, topLinePosition - (8 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (9 * textVSpacing), 'S4 MEGS-P Data Raw = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ts4 =   text(0.9 + textHSpacing, topLinePosition - (9 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.75, topLinePosition - (11 * textVSpacing), 'ESP', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.9, topLinePosition - (12 * textVSpacing), 'S3 ESP Quad = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ts3a =  text(0.9 + textHSpacing, topLinePosition - (12 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.9, topLinePosition - (13 * textVSpacing), 'S3 ESP Data Raw = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ts3b =  text(0.9 + textHSpacing, topLinePosition - (13 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.75, topLinePosition - (14 * textVSpacing), 'XRS', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.9, topLinePosition - (15 * textVSpacing), 'A7 XRS +5V Monitor = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta7 =   text(0.9 + textHSpacing, topLinePosition - (15 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
monitorsRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = blueColor, ALIGNMENT = 1.0)

; MEGS-P Spectrum
wb = window(DIMENSIONS = [windowSize[0], windowSize[1] / 2. - 15.], /NO_TOOLBAR, LOCATION = [windowSize[0] + 6, 0], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'MEGS-P Plot')
p1 = image(findgen(128, 10), TITLE = 'S4 MEGS-P Spectrum', /CURRENT, MARGIN = [0.1, 0.02, 0.1, 0.02], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
c1 = colorbar(TARGET = p1, ORIENTATION = 1, POSITION = [0.92, 0.1, 0.94, 0.98], TEXTPOS = 1, FONT_SIZE = fontSize - 2, TEXT_COLOR = fontColor)
megsPRefreshText =     text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = redColor, ALIGNMENT = 1.0)

; ESP Spectrum
wc = window(DIMENSIONS = [windowSize[0], windowSize[1] / 2. - 12.], /NO_TOOLBAR, LOCATION = [windowSize[0] + 6, windowSize[1] / 2 + 34], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'ESP Plots')
p2 = image(findgen(28, 10), TITLE = 'S3 ESP Spectrum', /CURRENT, MARGIN = [0.1, 0.5, 0.1, 0.08], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
c2 = colorbar(TARGET = p2, ORIENTATION = 1, POSITION = [0.92, 0.55, 0.94, 0.98], TEXTPOS = 1, FONT_SIZE = fontSize - 2, TEXT_COLOR = fontColor)
p3 = plot(findgen(28), sin(findgen(28)), TITLE = 'S3 ESP Quad', /CURRENT, POSITION = [0.1, 0.13, 0.95, 0.45], COLOR = redColor, FONT_SIZE = fontSize, FONT_COLOR = fontColor, $
          XCOLOR = fontColor, $
          YCOLOR = fontColor)
espRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = redColor, ALIGNMENT = 1.0)

; Initialize COMMON buffer variables
monitorsBuffer = uintarr(112)

; Open a port that the DEWESoft computer will be commanded to stream to (see PROCEDURE in this code's header)
socket, connectionCheckLUN, port, /LISTEN, /GET_LUN, /RAWIO
;STOP, 'Wait until DEWESoft is set to startacq. Then click go or type ".c".'

; Prepare a separate logical unit (LUN) to read the actual incoming data
get_lun, socketLun

; Wait for the connection from DEWESoft to be detected
isConnected = 0
WHILE isConnected EQ 0 DO BEGIN
  IF file_poll_input(connectionCheckLUN, timeout = 5.0) THEN BEGIN ; Timeout is in seconds
    socket, socketLun, accept = connectionCheckLUN, /RAWIO, CONNECT_TIMEOUT = 30., READ_TIMEOUT = 30., WRITE_TIMEOUT = 30., /SWAP_IF_BIG_ENDIAN
    isConnected = 1
  ENDIF ELSE message, /INFO, JPMsystime() + ' No connection detected yet.'
ENDWHILE

; Prepare a socket read buffer
socketDataBuffer = !NULL

; Prepare image counter for how often to refresh the images
displayMonitorsCounter = 0

; Start an infinite loop to check the socket for data
WHILE 1 DO BEGIN

  ; Start a timer
  IF !version.release GT '8.2.2' THEN wrapperClock = TIC() ELSE $
                                      wrapperClock = JPMsystime(/SECONDS)
  
  ; Store how many bytes are on the socket
  socketDataSize = (fstat(socketLun)).size
  
  ; Trigger data processing if there's actually something to process
  IF socketDataSize GT 0 THEN BEGIN
    
    ; Read data on the socket
    socketData = bytarr((fstat(socketLun)).size)
    readu, socketLun, socketData
    
    ; Stuff the new socketData into the buffer. This will work even the first time around when the buffer is !NULL. 
    socketDataBuffer = [temporary(socketDataBuffer), temporary(socketData)]
    
    ; Do an efficient search for just the last DEWESoft sync byte
    sync7Indices = where(socketDataBuffer EQ 7, numSync7s)
    
    ; If some 0x07 sync bytes were found, then loop to verify the rest of the sync byte pattern (0x00 0x01 0x02 0x03 0x04 0x05 0x06)
    ; and process the data between every set of two verified sync byte patterns
    IF numSync7s GE 2 THEN BEGIN
      
      ; Reset the index of the verified sync patterns
      verifiedSync7Index = !NULL
      
      FOR sync7LoopIndex = 0, numSync7s - 1 DO BEGIN
        
        ; Verify the rest of the sync pattern
        IF sync7Indices[0] LT 7 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 1] NE 6 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 2] NE 5 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 3] NE 4 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 4] NE 3 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 5] NE 2 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 6] NE 1 THEN CONTINUE
        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 7] NE 0 THEN CONTINUE
        
        ; If this is the first syncLoopIndex, then verify this sync pattern and continue to the next sync pattern to determine 
        ; the data to process (singleFullDeweSoftPacket) between the two sync patterns
        IF sync7LoopIndex EQ 0 THEN BEGIN
          verifiedSync7Index = sync7Indices[sync7LoopIndex]
          CONTINUE
        ENDIF
        
        ; Store the data to be processed between two DEWESoft sync patterns
        singleFullDeweSoftPacket = socketDataBuffer[verifiedSync7Index - 7:sync7Indices[sync7LoopIndex] - 8]
        
        ; -= PROCESS DATA =- ;
        
        ; Grab packet samples
        offsetP1 = 36 ; TODO: What is the offset for analogs
        numberOfDataSamplesP1 = byte2ulong(singleFullDeweSoftPacket[offsetP1:offsetP1 + 3])
        offsetP2 = offsetP1 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP1
        numberOfDataSamplesP2 = byte2ulong(singleFullDeweSoftPacket[offsetP2:offsetP2 + 3])
;        offsetP3 = offsetP2 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP2
;        numberOfDataSamplesP3 = byte2ulong(singleFullDeweSoftPacket[offsetP3:offsetP3 + 3])
       
        IF keyword_set(DEBUG2) THEN BEGIN
          halfwayOffsetP1 = numberOfDataSamplesP1 / 2L + offsetP1 + 4 ; Why is the first word halfway through? 
          halfwayOffsetP2 = numberOfDataSamplesP2 / 2L + offsetP2 + 4
          message, /INFO, JPMsystime() + ' MEGS-A number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP1) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP1: halfwayOffsetP1 + 1]))
          message, /INFO, JPMsystime() + ' MEGS-B number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP2) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP2: halfwayOffsetP2 + 1]))
        ENDIF

        expectedPacketSize = 2 * (numberOfDataSamplesP1 + numberOfDataSamplesP2) + 4L * 2L + 44 ; TODO: Update expected size
        IF expectedPacketSize NE n_elements(singleFullDeweSoftPacket) THEN $
           message, /INFO, JPMsystime() + ' Measured single DEWESoft packet length not equal to expectation. Expected: ' $ 
                           + JPMPrintNumber(expectedPacketSize) + ' bytes but received ' $
                           + JPMPrintNumber(n_elements(singleFullDeweSoftPacket)) + 'bytes.'
        
        IF keyword_set(DEBUG) THEN BEGIN
          print, 'Socket:', socketDataSize, byte2ulong(singleFullDeweSoftPacket[8:11]), numberOfDataSamplesP1, $
            byte2uint(singleFullDeweSoftPacket[offsetP1 + 4: offsetP1 + 5]), $
            numberOfDataSamplesP2, byte2uint(singleFullDeweSoftPacket[offsetP2 + 4: offsetP2 + 5]), $
            ;numberOfDataSamplesP3, byte2uint(singleFullDeweSoftPacket[offsetP3 + 4: offsetP3 + 5]), $
            format = '(a8, 3i12, z5, i12, z5, i12, z5)'
        ENDIF
        
        ; Actually read/interpret the data
        monitorsStructure = rocket_eve_tm1_read_packets(singleFullDeweSoftPacket, VERBOSE = VERBOSE, DEBUG = DEBUG)

        displayMonitorsCounter++
        IF displayMonitorsCounter GT frequencyOfImageDisplay THEN BEGIN 
          doMonitorsProcessing = 1
          displayMonitorsCounter = 0
        ENDIF

        ; -= MANIPULATE DATA AS NECESSARY =- ;        
        IF doMonitorsProcessing THEN BEGIN
          
        ENDIF ; doMegsAProcessing
                
        ; -= UPDATE PLOT WINDOWS WITH REASONABLE REFRESH RATE =- ;

        !Except = 0 ; Disable annoying divide by 0 messages
        IF doMonitorsProcessing THEN BEGIN

          ; Update display text
          ta23.string = strtrim(monitorsStructure.tm_28v_bus_voltage, 2)
          ta124.string = strtrim(monitorsStructure.exp_28v_bus_voltage, 2)
          ta106.string = strtrim(monitorsStructure.tm_28v_bus_current, 2)
          ta25.string = strtrim(monitorsStructure.gate_valve_position, 2)
          ta13.string = strtrim(monitorsStructure.solar_section_pressure, 2)
          ta14b.string = strtrim(monitorsStructure.cryo_hot_temp, 2)
          ta29.string = strtrim(monitorsStructure.fpga_5v_voltage, 2)
          ta30.string = strtrim(monitorsStructure.camera_12v_voltage, 2)
          ta7.string = strtrim(monitorsStructure.xrs_5v_voltage, 2)
          ta3.string = strtrim(monitorsStructure.megsa_heater, 2)
          ta15.string = strtrim(monitorsStructure.megsb_heater, 2)
          ta19.string = strtrim(monitorsStructure.megsa_ccd_temp, 2)
          ta20.string = strtrim(monitorsStructure.megsb_ccd_temp, 2)
          ta31.string = strtrim(monitorsStructure.megsa_ff, 2)
          ta32.string = strtrim(monitorsStructure.megsb_ff, 2)
          ta1.string = strtrim(monitorsStructure.megsp_temp, 2)
          ta7.string = strtrim(monitorsStructure.xrs_5v_voltage, 2)          

          monitorsRefreshText.String = 'Last refresh: ' + JPMsystime()
        ENDIF ; doMegsAProcessing
        !Except = 1 ; Re-enable math error logging

        ; Set the index of this verified sync pattern for use in the next iteration of the DEWESoft sync7Loop
        verifiedSync7Index = sync7Indices[sync7LoopIndex]
      ENDFOR ; sync7LoopIndex = 0, numSync7s - 1
      
      ; Now that all processable data has been processed, overwrite the buffer to contain only bytes from the beginning of 
      ; last sync pattern to the end of socketDataBuffer
      socketDataBuffer = socketDataBuffer[verifiedSync7Index - 7:-1]
    ENDIF ; IF numSync7s GE 2
  ENDIF ;ELSE IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime() + ' Socket connected but 0 bytes on socket.' ; If socketDataSize GT 0

  ;IF keyword_set(DEBUG) THEN BEGIN
    ;IF !version.release GT '8.2.2' THEN message, /INFO, JPMsystime() + ' Finished processing socket data in time = ' + JPMPrintNumber(TOC(wrapperClock)) ELSE $
  ;                                      message, /INFO, JPMsystime() + ' Finished processing socket data in time = ' + JPMPrintNumber(JPMsystime(/SECONDS) - wrapperClock)
  ;ENDIF
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, lun

END