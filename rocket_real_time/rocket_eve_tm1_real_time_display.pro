;+
; NAME:
;   rocket_eve_tm1_real_time_display
;
; PURPOSE:
;   Wrapper script for reading from a remote socket. Calls rocket_eve_tm1_analog_read_packets (the interpreter) when new data comes over the pipe. 
;   Note: rocket_eve_tm1_read_packets is deprecated and handled the launch prior to 36.336
;
; INPUTS:
;   port [integer]: The port number to open that DEWESoft will be commanded to stream data to. This requires that both machines are running on the same network.
;                   This is provided as an optional input only so that a hardcoded value can be specified and the IDLDE Run button hit, instead
;                   of needing to call the code from the command line each time. However, a known port is really is necessary.
;
; OPTIONAL INPUTS:
;   windowSize [integer, integer]:     Set this to the pixel dimensions in [x, y] that you want the display. Default is [1000, 800].
;
; KEYWORD PARAMETERS:
;   DEBUG:               Set to print debugging information, such as the sizes of and listed in the packets.
;   LIGHT_BACKGROUND:    Set this to use a white background and dark font instead of the default (black background and white font)
;
; OUTPUTS:
;   Produces 2 display pages with all the most important data in the world, displayed in real time from a remote socket.
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
;   0) Connect this machine to a network with the machine running DEWESoft. This can be done with a crossover cable connecting their two ethernet ports. 
;   1) Start rocket_tm1_start.scpt (Note: this expects the Dewesoft computers IP to be 169.254.17.237 with port 8999 and tranfer port 8002 so if you change
;      these defaults you'll have to change both what this IDL procedure is expecting and what the apple script is doing)
;   
;   Or if you hate yourself and want to do things manually:
;   0) Connect this machine to a network with the machine running DEWESoft. This can be done with a crossover cable connecting their two ethernet ports. 
;   1) Open a terminal (e.g., terminal.app in OSX)
;   2) type: telnet ipAddress 8999 (where ipAddress is the IP address (duh) of the DEWESoft machine e.g., telnet 169.254.17.237 8999. 
;            8999 is the commanding port and should not need to be changed). You should get an acknowledgement: +CONNECTED DEWESoft TCP/IP server. 
;   3) type: listusedchs (This should return a list of all channels being used. EVE data is in three parallel streams, P1, P2, and P3. 
;            Note the corresponding channel numbers. For EVE these are ch 13, 14, and 12, respectively).
;   4) type: /stx preparetransfer
;   5) type: ch 56
;            ch 58
;            ch 62
;            ch ... (For each channel. There should be 23 in total...).
;   6) type: /etx You should get an acknowledgement: +OK
;   7) NOW you can start this code. It will open the port specified in the input parameter, or use the hard-coded default if not provided in the call. Then it will STOP. Don't continue yet. 
;   Back to the terminal window
;   8) type: starttransfer port (where port is the same port IDL is using in step 8 above, e.g., starttransfer 8002)
;   9) type: setmode 1 You'll either see +ERR Already in this mode or +OK Mode 1 (control) selected, 
;             depending on if you've already done this step during debugging this when it inevitably doesn't work the first time. 
;   10) type: startacq You should get an acknowledgement: +OK Acquiring
;   11) NOW you can continue running this code
;
; EXAMPLE:
;   See PROCEDURE above for examples of each step. 
;
; MODIFICATION HISTORY:
;   2017-08-08: James Paul Mason: Wrote script based on rocket_eve_tm2_real_time_display.
;   2018-05-29: Robert Henry Alexander Sewell: Updated for 36.336 launch
;-
PRO rocket_eve_tm1_real_time_display, port = port, windowSize = windowSize, $
                                      DEBUG = DEBUG, LIGHT_BACKGROUND = LIGHT_BACKGROUND

; Defaults
;port = read_csv('~/Dropbox/minxss_dropbox/code/rocket_real_time/test_port.txt')
;port = (uint(byte(port.field1[0]), 0, 2))[1] ; Just for testing
IF ~keyword_set(port) THEN port = 8002
IF ~keyword_set(windowSize) THEN windowSize = [1000, 700]
IF keyword_set(LIGHT_BACKGROUND) THEN BEGIN
  fontColor = 'black'
  backgroundColor = 'white'
  boxColor = 'light steel blue'
  blueColor = 'dodger blue'
  redColor = 'tomato'
  greenColor='lime green'
ENDIF ELSE BEGIN
  fontColor = 'white'
  backgroundColor = 'black'
  boxColor = 'midnight blue'
  blueColor = 'dodger blue'
  redColor = 'tomato'
  greenColor='lime green'
ENDELSE
fontSize = 16

; Open a port that the DEWESoft computer will be commanded to stream to (see PROCEDURE in this code's header)
socket, connectionCheckLUN, port, /LISTEN, /GET_LUN, /RAWIO
STOP, 'Wait until DEWESoft is set to startacq. Then click go.'

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

; Mission specific setup. Edit this to tailor data.
; e.g., instrument calibration arrays such as gain to be used in the PROCESS DATA section below
synctype=[0,0,0,1,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1];Index which channels are synchronous (0) or async (1) corresponding to channel order pulled
;Arrays for thermal conversions for 36.336 monitors
;TODO move the thermal conversions to a different function call
woods5=[0.00147408,0.00023701459,1.0839894e-7]
woods6=[0.0014051,0.0002369,1.019e-7]
woods7=[0.001288,0.0002356,9.557e-8]
woods8=[0.077,0.1037,0.0256]
woods11=[15.0,11.75,5.797]
woods14=[15.0,12.22,5.881]
woods15=[15.0,11.71,5.816]
woods17=[257.122,-257.199]


;Initialize monitor structure
analogMonitorsStructure = {megsp_temp: 0.0, megsa_htr: 0.0, xrs_5v:0.0, csol_5v:0.0, $
  slr_pressure:0.0,cryo_cold:0.0,megsb_htr:0.0,xrs_temp:0.0,$
  megsa_ccd_temp:0.0,megsb_ccd_temp:0.0,cryo_hot:0.0,exprt_28v:0.0,$
  vac_valve_pos:0.0,hvs_pressure:0.0,exprt_15v:0.0,fpga_5v:0.0,$
  tv_12v:0.0,megsa_ff_led:0.0,megsb_ff_led:0.0,exprt_bus_cur:0.0,$
  exprt_main_28v:0.0,esp_fpga_time:0.0,esp_rec_counter:0.0,esp1:0.0,$
  esp2:0.0,esp3:0.0,esp4:0.0,esp5:0.0,esp6:0.0,esp7:0.0,esp8:0.0,esp9:0.0,$
  megsp_fpga_time:0.0,megsp1:0.0,megsp2:0.0}

;Initialize invalid Dewesoft packet counters
stale_a=0
stale_s=0

; -= CREATE PLACE HOLDER PLOTS =- ;
; Edit here to change axis ranges, titles, locations, etc. 
textVSpacing = 0.05 ; Vertical spacing
textHSpacing = 0.02 ; Horizontal spacing
topLinePosition = 0.90

; Monitors
; Note that all of the t = below are just static labels so they do not need unique variables

;Serial monitor window
;Displays ESP and MEGS-P diode readouts
wb = window(DIMENSIONS = [400,750], /NO_TOOLBAR, LOCATION = [0, 0], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'Serial Monitors')

t =     text(0.4, 0.95, 'ESP', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.6, topLinePosition, 'ESP FPGA Time = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_time =  text(0.6 + textHSpacing, topLinePosition, '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (1 * textVSpacing), 'Record Counter = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_cnt = text(0.6 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (2 * textVSpacing), 'Diode 1 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp1 = text(0.6 + textHSpacing, topLinePosition - (2 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (3 * textVSpacing), 'Diode 2 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp2 = text(0.6 + textHSpacing, topLinePosition - (3 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (4 * textVSpacing), 'Diode 3 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp3 =  text(0.6 + textHSpacing, topLinePosition - (4 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (5 * textVSpacing), 'Diode 4 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp4 =  text(0.6 + textHSpacing, topLinePosition - (5 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (6 * textVSpacing), 'Diode 5 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp5 =  text(0.6 + textHSpacing, topLinePosition - (6 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (7 * textVSpacing), 'Diode 6 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp6 = text(0.6 + textHSpacing, topLinePosition - (7 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (8 * textVSpacing), 'Diode 7 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp7 = text(0.6 + textHSpacing, topLinePosition - (8 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (9 * textVSpacing), 'Diode 8 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp8 =  text(0.6 + textHSpacing, topLinePosition - (9 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (10 * textVSpacing), 'Diode 9 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s3_esp9 =  text(0.6 + textHSpacing, topLinePosition - (10 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.4, topLinePosition - (11 * textVSpacing), 'MEGS-P', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.6, topLinePosition-(12 * textVSpacing), 'MEGS-P FPGA Time = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s4_time =   text(0.6 + textHSpacing, topLinePosition-(12 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (13 * textVSpacing), 'Diode 1 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s4_megsp1 =  text(0.6 + textHSpacing, topLinePosition - (13 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.6, topLinePosition - (14 * textVSpacing), 'Diode 2 = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
s4_megsp2 =  text(0.6 + textHSpacing, topLinePosition - (14 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
monitorsSerialRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = blueColor, ALIGNMENT = 1.0,font_size=14)

;Analog monitor window
;Displays limit checked hk
wa = window(DIMENSIONS = [1000, 750], /NO_TOOLBAR, LOCATION = [406, 0], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'Analog Monitors')

; Left column
t =     text(0.25, 0.95, 'Payload', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.35, topLinePosition, 'A23 Exp +28V Monitor = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta23 =  text(0.35 + textHSpacing, topLinePosition, '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)

;A28 wasn't outputing for flight 36.336
;t =     text(0.4, topLinePosition - (1 * textVSpacing), 'A28 Exp +15V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
;ta28 = text(0.4 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)

t =     text(0.35, topLinePosition - (1 * textVSpacing), 'A124 TM Exp Bus Volt [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta124 = text(0.35 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (2 * textVSpacing), 'A106 TM Exp Bus Curr [A] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta106 = text(0.35 + textHSpacing, topLinePosition - (2 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (4 * textVSpacing), 'A25 Vac Valve Position = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta25 =  text(0.35 + textHSpacing, topLinePosition - (4 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (5 * textVSpacing), 'A26 HVS Pressure = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta26 =  text(0.35 + textHSpacing, topLinePosition - (5 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (6 * textVSpacing), 'A13 Solar Section Pressure = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta13 =  text(0.35 + textHSpacing, topLinePosition - (6 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (8 * textVSpacing), 'A14 Cryo Cold Finger Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta14 =  text(0.35 + textHSpacing, topLinePosition - (8 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (9 * textVSpacing), 'A22 Cryo Hot Side Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta22 =  text(0.35 + textHSpacing, topLinePosition - (9 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (11 * textVSpacing), 'A29 FPGA +5V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta29 =  text(0.35 + textHSpacing, topLinePosition - (11 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.35, topLinePosition - (12 * textVSpacing), 'A30 Camera +12V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta30 =  text(0.35 + textHSpacing, topLinePosition - (12 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)

;A8 (CSOL 5V) isn't decoded correctly on tm1 altair but it is displayed in tm2 real time code
;t =     text(0.25, topLinePosition - (13 * textVSpacing), 'CSOL', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
;t =     text(0.3, topLinePosition - (14 * textVSpacing), 'A8 CSOL +5V Monitor [V] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
;ta8 =   text(0.3 + textHSpacing, topLinePosition - (14 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)

; Right column
t =     text(0.75, 0.95, 'MEGS', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.8, topLinePosition, 'A3 MEGS A Heater = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta3 =   text(0.8 + textHSpacing, topLinePosition, '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (1 * textVSpacing), 'A15 MEGS B Heater = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta15 =  text(0.8 + textHSpacing, topLinePosition - (1 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (2 * textVSpacing), 'A19 MEGS A CCD Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta19 =  text(0.8 + textHSpacing, topLinePosition - (2 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (3 * textVSpacing), 'A20 MEGS B CCD Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta20 =  text(0.8 + textHSpacing, topLinePosition - (3 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (5 * textVSpacing), 'A31 MEGS A FF Lamp = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta31 =  text(0.8 + textHSpacing, topLinePosition - (5 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (6 * textVSpacing), 'A32 MEGS B FF Lamp = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta32 =  text(0.8 + textHSpacing, topLinePosition - (6 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (8 * textVSpacing), 'A1 MEGS-P Temp [ºC] = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta1 =   text(0.8 + textHSpacing, topLinePosition - (8 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.75, topLinePosition - (10 * textVSpacing), 'XRS', FONT_SIZE = fontSize + 6, FONT_COLOR = blueColor)
t =     text(0.8, topLinePosition - (11 * textVSpacing), 'A7 XRS +5V Monitor = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta7 =   text(0.8 + textHSpacing, topLinePosition - (11 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
t =     text(0.8, topLinePosition - (12 * textVSpacing), 'A16 XRS Temp = ', ALIGNMENT = 1.0, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
ta16 =  text(0.8 + textHSpacing, topLinePosition - (12 * textVSpacing), '--', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
monitorsRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = blueColor, ALIGNMENT = 1.0,font_size=14)

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
        
        ;Checking if packet type is 0 (i.e.a data packet) else skip
        packetType=byte2ulong(singleFullDeweSoftPacket[12:12+3])

        IF packetType NE 0 then begin
          if keyword_set(debug) then print, "Skipping as datatype is ",packetType
          verifiedSync7Index = sync7Indices[sync7LoopIndex]
          continue
        endif
        
        ; -= PROCESS DATA =- ;
        
        ;Offsets will be an array of where in the Dewesoft packet our data is per channel
        offsets=[]
        ;Samplesize is the length of each of our data channels within the Dewesoft packet
        samplesize=[]
        
        ; Grab packet samples
        for i=0, n_elements(synctype)-13 do begin
          if i eq 0 then begin
            offsets=[offsets,36];Header of Dewesoft packet is 36 bytes long until the first packet size
            samplesize=[samplesize,byte2ulong(singleFullDeweSoftPacket[offsets[i]:offsets[i] + 3])];Sample size is the next long word
          endif else begin
            if synctype[i-1] eq 0 then begin
              sampleSizeDeweSoft=2;This is the multiplication factor for synchronus data to get the data channel size
            endif else begin
              sampleSizeDeweSoft=10;This is the multiplication factor for asynchronus data to get the data channel size
            endelse
            if samplesize[i-1] eq 0 then break;Handle when dewesoft pads packets for some reason and we can no longer get the correct offsets
            offsets=[offsets,offsets[i-1] + 4 + sampleSizeDeweSoft * samplesize[i-1]]
            samplesize=[samplesize,byte2ulong(singleFullDeweSoftPacket[offsets[i]:offsets[i] + 3])]
          endelse
        endfor
        offsets=[offsets,n_elements(singleFullDeweSoftPacket)];Last offset is the end of the Dewesoft packet +1
        
        ; -= INTERPRET DATA =- ;
        ;rocket_eve_tm1_read_packets actually processes the channel data using offsets and sample size and passes back a struct with our data
        analogMonitors=rocket_eve_tm1_read_packets(singleFullDeweSoftPacket,analogMonitorsStructure, offsets,samplesize,monitorsRefreshText,monitorsSerialRefreshText, stale_a, stale_s)
        
        ;Convert voltages to temperature for the 36.336 flight
        ;TODO move these to a seperate function
        R_therm_MEGSP=woods14[1]/((woods14[0]/(analogMonitors.megsp_temp))-(woods14[1]/woods14[2])-1)*1000
        t_MEGSP=1/(woods7[0]+woods7[1]*alog(R_therm_MEGSP)+woods7[2]*((alog(R_therm_MEGSP))^3))-273.15
        
        R_therm_XRS1=woods15[1]/((woods15[0]/(analogMonitors.xrs_temp))-(woods15[1]/woods15[2])-1)*1000
        t_XRS1=1/(woods6[0]+woods6[1]*alog(R_therm_XRS1)+woods6[2]*((alog(R_therm_XRS1))^3))-273.15
        
        R_therm_Cryo_Hotside=woods11[1]/((woods11[0]/(analogMonitors.cryo_hot))-(woods11[1]/woods11[2])-1)*1000
        t_Cryo_Hotside=1/(woods5[0]+woods5[1]*alog(R_therm_Cryo_Hotside)+woods5[2]*((alog(R_therm_Cryo_Hotside))^3))-273.15
        
        v_convert_=woods8[2]*(analogMonitors.cryo_cold)^2+woods8[1]*(analogMonitors.cryo_cold)+woods8[0]
        t_Cold_Finger=woods17[0]*v_convert_+woods17[1]
        
        megsa_ccd=34.5*analogMonitors.megsa_ccd_temp-143
        megsb_ccd=34.45*analogMonitors.megsb_ccd_temp-156
        
                
        ; -= UPDATE PLOT WINDOWS WITH REASONABLE REFRESH RATE =- ;

        !Except = 0 ; Disable annoying divide by 0 messages

        ;We continually update the display as, even if we don't get a new valid Dewesoft packet, the valid data is still in the monitor struct
        ;Window 1 display
        ta23.string = jpmprintnumber(analogMonitors.exprt_main_28v)
        ta124.string = jpmprintnumber(analogMonitors.exprt_28v)
        ta106.string = jpmprintnumber(analogMonitors.exprt_bus_cur)
        ta13.string = jpmprintnumber(analogMonitors.slr_pressure)
        ta14.string = jpmprintnumber(t_Cold_Finger)
        ta29.string = jpmprintnumber(analogMonitors.fpga_5v)
        ta30.string = jpmprintnumber(analogMonitors.tv_12v)
        ta7.string = jpmprintnumber(analogMonitors.xrs_5v)
        ta19.string = jpmprintnumber(megsa_ccd)+" ("+jpmprintnumber(analogMonitors.megsa_ccd_temp)+")"
        ta20.string = jpmprintnumber(megsb_ccd)+" ("+jpmprintnumber(analogMonitors.megsb_ccd_temp)+")"
        ta1.string = jpmprintnumber(t_MEGSP)
        ta7.string = jpmprintnumber(analogMonitors.xrs_5v) 
        ta26.string = jpmprintnumber(analogMonitors.hvs_pressure)
        ta22.string = jpmprintnumber(t_Cryo_Hotside)
        ta16.string = jpmprintnumber(t_XRS1)
        ;Window 0 display
        s3_time.string = jpmprintnumber(analogMonitors.esp_fpga_time)
        s3_cnt.string = jpmprintnumber(analogMonitors.esp_rec_counter)
        s3_esp1.string = jpmprintnumber(analogMonitors.esp1)
        s3_esp2.string = jpmprintnumber(analogMonitors.esp2)
        s3_esp3.string = jpmprintnumber(analogMonitors.esp3)
        s3_esp4.string = jpmprintnumber(analogMonitors.esp4)
        s3_esp5.string = jpmprintnumber(analogMonitors.esp5)
        s3_esp6.string = jpmprintnumber(analogMonitors.esp6)
        s3_esp7.string = jpmprintnumber(analogMonitors.esp7)
        s3_esp8.string = jpmprintnumber(analogMonitors.esp8)
        s3_esp9.string = jpmprintnumber(analogMonitors.esp9)
        s4_time.string = jpmprintnumber(analogMonitors.megsp_fpga_time)
        s4_megsp1.string = jpmprintnumber(analogMonitors.megsp1)
        s4_megsp2.string = jpmprintnumber(analogMonitors.megsp2)
        
        
        ; -= LIMIT CHECKING =- ;
        
        ;Sets the refresh text at the bottom of the analog window to purple if we get 20 invalid dewesoft packets
        if (stale_a gt 20) then begin       
          monitorsRefreshText.font_color = 'purple'
        endif else begin
          monitorsRefreshText.font_color = bluecolor
        endelse
    
        ;Sets the refresh text at the bottom of the serial window to purple if we get 20 invalid dewesoft packets
        if (stale_s gt 20) then begin
          monitorsSerialRefreshText.font_color = 'purple'
        endif else begin
          monitorsSerialRefreshText.font_color = bluecolor
        endelse
        
        if (analogMonitors.megsa_htr le -1 or analogMonitors.megsa_htr ge 0.2) then begin
          ta3.string = 'Heater ON ('+jpmprintnumber(analogMonitors.megsa_htr)+')'
          ta3.font_color=redcolor
        endif else begin
          ta3.string = 'Heater OFF('+jpmprintnumber(analogMonitors.megsa_htr)+')'
          ta3.font_color=greencolor
        endelse
        
        if (analogMonitors.megsb_htr le -1 or analogMonitors.megsb_htr ge 0.2) then begin
          ta15.string = 'Heater ON ('+jpmprintnumber(analogMonitors.megsb_htr)+')'
          ta15.font_color=redcolor
        endif else begin
          ta15.string = 'Heater OFF ('+jpmprintnumber(analogMonitors.megsb_htr)+')'
          ta15.font_color=greencolor
        endelse
        
        if (analogMonitors.xrs_5v le 4.5 or analogMonitors.xrs_5v ge 5.5) then begin
          ta7.font_color=redcolor
        endif else begin
          ta7.font_color=greencolor
        endelse
        
        if (analogMonitors.exprt_main_28v le 22 or analogMonitors.exprt_main_28v ge 35) then begin
          ta23.font_color=redcolor
        endif else begin
          ta23.font_color=greencolor
        endelse
        
        if ((analogMonitors.vac_valve_pos le 0.2 and analogMonitors.vac_valve_pos gt -1) or (analogMonitors.vac_valve_pos ge 3.3 and analogMonitors.vac_valve_pos lt 3.6)) then begin
          ta25.font_color='yellow'
          ta25.string="Moving ("+jpmprintnumber(analogMonitors.vac_valve_pos)+")"
        endif else if (analogMonitors.vac_valve_pos le -1 or analogMonitors.vac_valve_pos ge 3.6) then begin
          ta25.font_color=redcolor
          ta25.string="Open ("+jpmprintnumber(analogMonitors.vac_valve_pos)+")"
        endif else begin
          ta25.font_color=greencolor
          ta25.string="Closed ("+jpmprintnumber(analogMonitors.vac_valve_pos)+")"
        endelse
        
        if (analogMonitors.fpga_5v le 4.5 or analogMonitors.fpga_5v ge 5.5) then begin
          ta29.font_color=redcolor
        endif else begin
          ta29.font_color=greencolor
        endelse
        
        if (analogMonitors.megsa_ff_led le .15) then begin
          ta31.font_color=greencolor
          ta31.string = "OFF ("+jpmprintnumber(analogMonitors.megsa_ff_led)+")"
        endif else if (analogMonitors.megsa_ff_led ge .2) then begin
          ta31.font_color=redcolor
          ta31.string = "ON ("+jpmprintnumber(analogMonitors.megsa_ff_led)+")"
        endif else begin
          ta31.font_color=redcolor
          ta31.string = "UNKNOWN ("+jpmprintnumber(analogMonitors.megsa_ff_led)+")"
        endelse
        
        if (analogMonitors.megsb_ff_led le .15) then begin
          ta32.font_color=greencolor
          ta32.string = "OFF ("+jpmprintnumber(analogMonitors.megsb_ff_led)+")"
        endif else if (analogMonitors.megsb_ff_led ge .2) then begin
          ta32.font_color=redcolor
          ta32.string = "ON ("+jpmprintnumber(analogMonitors.megsb_ff_led)+")"
        endif else begin
          ta32.font_color=redcolor
          ta32.string = "UNKNOWN ("+jpmprintnumber(analogMonitors.megsb_ff_led)+")"
        endelse
        
        if (analogMonitors.exprt_bus_cur le .9 or analogMonitors.exprt_bus_cur ge 2) then begin
          ta106.font_color=redcolor
        endif else begin
          ta106.font_color=greencolor
        endelse
        
        if (analogMonitors.exprt_28v le 24 or analogMonitors.exprt_28v ge 40) then begin
          ta124.font_color=redcolor
        endif else begin
          ta124.font_color=greencolor
        endelse
          
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