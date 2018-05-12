;+
; NAME:
;   rocket_eve_tm2_real_time_display
;
; PURPOSE:
;   Wrapper script for reading from a remote socket. Calls rocket_eve_tm2_read_packets (the interpreter) when new data comes over the pipe. 
;
; INPUTS:
;   port [integer]: The port number to open that DEWESoft will be commanded to stream data to. This requires that both machines are running on the same network.
;                   This is provided as an optional input only so that a hardcoded value can be specified and the IDLDE Run button hit, instead
;                   of needing to call the code from the command line each time. However, a known port is really is necessary.
;
; OPTIONAL INPUTS:
;   windowSize [integer, integer]:                           Set this to the pixel dimensions in [x, y] that you want the display. Default is [1600, 900],
;                                                            which works well on a Macbook Pro Retina with [1920, 1200] resolution.
;   windowSizeCsol [integer, integer]:                       Same idea as windowSize, but for CSOL science data.
;   windowSizeCsolHk [integer, integer]:                     Same idea as windowSizeCsol, but for the housekeeping data.
;   megsAStatisticsBox [integer, integer, integer, integer]: Hard-coded pixel indices for computing statistics. Default is arbitrary at the moment but should be around the 304 Å line. 
;                                                            Format is [column1, row1, column2, row2] to define the square box. Ditto for megsB. 
;   megsAExpectedCentroid: [float, float]:                   The expected pixel index location of the centroid in the bounding statistics box. Expected in format [X, Y]. 
;                                                            Default is [1350, 400]. Ditto for megsB. 
;   frequencyOfImageDisplay [integer]:                       The refresh rate of images in the fun units of number of DEWESoftPackets per refresh. 
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
;   See rocket_eve_tm2_read_packets for a detailed description. And yes, I know common blocks are bad practice. However, we wanted socket reader / data interpreter modularity but still
;   require persistent data between the two. Passing variables back and forth between two functions is done by reference, but would result in messy code. So here we are with common blocks. 
;
; RESTRICTIONS:
;   Requires that the data pipe computer IS NOT YET RUNNING. See procedure below for the critical step-by-step to get the link up. 
;   Requires the rocket_real_time path environment variable. Can do this in an IDL startup file or in shell. 
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
;   2015-02-19: James Paul Mason: Wrote script based on minxss_real_time_socket_read_wrapper.pro. 
;   2015-04-23: James Paul Mason: Extensive edits to make this code compatible with DEWESoft running on an Altair system from NASA Wallops 
;                                 rather than White Sands Misile Range Chapter 10.
;   2015-04-25: James Paul Mason: More extensive edits to the same purpose. Now tested and functioning. Improved code effiency with where's instead of for's and the temporary function. 
;   2016-05-03: James Paul Mason: Changed color scheme default, added LIGHT_BACKGROUND keyword to maintain old color scheme. 
;   2018-05-10: James Paul Mason: Support for Compact SOLSTICE (CSOL), which replaces XRI everywhere in the code. 
;-
PRO rocket_eve_tm2_real_time_display, port = port, IS_ASYNCHRONOUSDATA = IS_ASYNCHRONOUSDATA, windowSize = windowSize, windowSizeCsol = windowSizeCsol, windowSizeCsolHk = windowSizeCsolHk, $
                                      megsAStatisticsBox = megsAStatisticsBox, megsBStatisticsBox = megsBStatisticsBox, $
                                      megsAExpectedCentroid = megsAExpectedCentroid, megsBExpectedCentroid = megsBExpectedCentroid, $
                                      frequencyOfImageDisplay = frequencyOfImageDisplay, noMod256 = noMod256, $
                                      DEBUG = DEBUG, DEBUG2 = DEBUG2, LIGHT_BACKGROUND = LIGHT_BACKGROUND
                                    
; COMMON blocks for use with rocket_read_tm2_function. The blocks are defined here and there to allow them to be called independently.
COMMON MEGS_PERSISTENT_DATA, megsCcdLookupTable
COMMON MEGS_A_PERSISTENT_DATA, megsAImageBuffer, megsAImageIndex, megsAPixelIndex, megsATotalPixelsFound
COMMON MEGS_B_PERSISTENT_DATA, megsBImageBuffer, megsBImageIndex, megsBPixelIndex, megsBTotalPixelsFound
COMMON CSOL_PERSISTENT_DATA, csolImageBuffer, csolImageIndex, csolRowNumberInStart, csolTotalPixelsFound, csolNumberGapPixels, csolHk
COMMON DEWESOFT_PERSISTENT_DATA, sampleSizeDeweSoft, offsetP1, numberOfDataSamplesP1, offsetP2, numberOfDataSamplesP2, offsetP3, numberOfDataSamplesP3 ; Note P1 = MEGS-A, P2 = MEGS-B, P3 = CSOL

; Defaults
IF ~keyword_set(port) THEN port = 8002
IF keyword_set(IS_ASYNCHRONOUSDATA) THEN sampleSizeDeweSoft = 10 ELSE sampleSizeDeweSoft = 2
IF ~keyword_set(windowSize) THEN windowSize = [1240, 350] * 2
IF ~keyword_set(windowSizeCsol) THEN windowSizeCsol = [1000, 440]
IF ~keyword_set(windowSizeCsolHk) THEN windowSizeCsol = [400, 400]
IF ~keyword_set(megsAStatisticsBox) THEN megsAStatisticsBox = [402, 80, 442, 511]  ; Corresponds to He II 304 Å line
IF ~keyword_set(megsBStatisticsBox) THEN megsBStatisticsBox = [624, 514, 864, 754] ; Corresponds to center block
IF ~keyword_set(megsAExpectedCentroid) THEN megsAExpectedCentroid = [19.6, 215.15] ; Expected for He II 304 Å
IF ~keyword_set(megsBExpectedCentroid) THEN megsBExpectedCentroid = [120., 120.]
IF ~keyword_set(frequencyOfImageDisplay) THEN frequencyOfImageDisplay = 8
IF keyword_set(LIGHT_BACKGROUND) THEN BEGIN
  fontColor = 'black'
  backgroundColor = 'white'
  boxColor = 'light steel blue'
  blueColor = 'dodger blue'
  redColor = 'tomato'
  greenColor = 'lime green'
ENDIF ELSE BEGIN
  fontColor = 'white'
  backgroundColor = 'black'
  boxColor = 'midnight blue'
  blueColor = 'dodger blue'
  redColor = 'tomato'
  greenColor = 'lime green'
ENDELSE
fontSize = 20
fontSizeHk = 14

; Mission specific setup. Edit this to tailor data.
; e.g., instrument calibration arrays such as gain to be used in the MANIPULATE DATA section below
; None needed for EVE

; -= CREATE PLACE HOLDER PLOTS =- ;
; Edit here to change axis ranges, titles, locations, etc. 
statsTextSpacing = 0.03
statsBoxHeight = statsTextSpacing * 20
statsYPositions = reverse(JPMRange(0.005, statsBoxHeight - 0.05, npts = 8))
hkVSpacing = 0.07 ; Vertical spacing
topLinePosition = 0.90

; MEGS-A
wa = window(DIMENSIONS = windowSize, /NO_TOOLBAR, LOCATION = [0, 0], BACKGROUND_COLOR = backgroundColor)
p0 = image(findgen(2048L, 1024L), TITLE = 'EVE MEGS A', WINDOW_TITLE = 'EVE MEGS A', /CURRENT, MARGIN = [0.1, 0.02, 0., 0.02], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
c0 = colorbar(TARGET = p0, ORIENTATION = 1, POSITION = [0.85, 0.03, 0.87, 0.98], TEXTPOS = 1, FONT_SIZE = fontSize - 2, TEXT_COLOR = fontColor)
readArrowMegsALeft = arrow([-50., 0], [1023., 1023.], /DATA, COLOR = blueColor, THICK = 3, /CURRENT)
readArrowMegsARight = arrow([2098., 2048], [0, 0], /DATA, COLOR = blueColor, THICK = 3, /CURRENT)
statsTextBoxCoords = [[0, 0], [0., statsBoxHeight], [0.26, statsBoxHeight], [0.26, 0]]
statsTextBox = polygon(statsTextBoxCoords, /FILL_BACKGROUND, FILL_COLOR = boxColor, THICK = 2)
megsAStatsBoxCoords = [[megsAStatisticsBox[0], megsAStatisticsBox[1]], [megsAStatisticsBox[0], megsAStatisticsBox[3]], [megsAStatisticsBox[2], megsAStatisticsBox[3]], [megsAStatisticsBox[2], megsAStatisticsBox[1]]] ; Polygon uses different structure, so convert
megsAStatsBox = polygon(megsAStatsBoxCoords, THICK = 2, FILL_TRANSPARENCY = 100, /DATA)
t = text(0.26/2, statsBoxHeight + 0.005, 'MEGS-A Statistics', ALIGNMENT = 0.5, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsACentroidText =    text(0, statsYPositions[0], 'X:Y Centroid [pixel index]: (1350, 400)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAOffsetText =      text(0, statsYPositions[1], 'X:Y Offset Angles [arcmin]: (0.431, 1.403)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAMeanText =        text(0, statsYPositions[2], 'Mean [DN]: 32041', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsATotalText =       text(0, statsYPositions[3], 'Total [DN]: 593013', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAMaxText =         text(0, statsYPositions[4], 'Max [DN]: 30252', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAMaxLocationText = text(0, statsYPositions[5], 'X:Y Max Location [pixel index]: (1350, 400)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAMinText =         text(0, statsYPositions[6], 'Min [DN]: 205', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsAMinLocationText = text(0, statsYPositions[7], 'X:Y Min Location [pixel index]: (1301, 305)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsARefreshText =     text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = blueColor, ALIGNMENT = 1.0)

; MEGS-B
wb = window(DIMENSIONS = windowSize, /NO_TOOLBAR, LOCATION = [0, windowSize[1] + 50], BACKGROUND_COLOR = backgroundColor)
p1 = image(findgen(2048L, 1024L), TITLE = 'EVE MEGS B', WINDOW_TITLE = 'EVE MEGS B', /CURRENT, MARGIN = [0.1, 0.02, 0., 0.02], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
c1 = colorbar(TARGET = p1, ORIENTATION = 1, POSITION = [0.85, 0.03, 0.87, 0.98], TEXTPOS = 1, FONT_SIZE = fontSize - 2, TEXT_COLOR = fontColor)
readArrowMegsBLeft = arrow([-50., 0], [1023., 1023.], /DATA, COLOR = redColor, THICK = 3, /CURRENT)
readArrowMegsBRight = arrow([2098., 2048], [0, 0], /DATA, COLOR = redColor, THICK = 3, /CURRENT)
statsTextBox = polygon(statsTextBoxCoords, /FILL_BACKGROUND, FILL_COLOR = boxColor, THICK = 2)
megsBStatsBoxCoords = [[megsBStatisticsBox[0], megsBStatisticsBox[1]], [megsBStatisticsBox[0], megsBStatisticsBox[3]], [megsBStatisticsBox[2], megsBStatisticsBox[3]], [megsBStatisticsBox[2], megsBStatisticsBox[1]]] ; Polygon uses different structure, so convert
megsBStatsBox = polygon(megsBStatsBoxCoords, THICK = 2, FILL_TRANSPARENCY = 100, /DATA)
t = text(0.26/2, statsBoxHeight + 0.005, 'MEGS-B Statistics', ALIGNMENT = 0.5, FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBCentroidText =    text(0, statsYPositions[0], 'X:Y Centroid [pixel index]: (1350, 400)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBOffsetText =      text(0, statsYPositions[1], 'X:Y Offset Angles [arcmin]: (0.431, 1.403)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBMeanText =        text(0, statsYPositions[2], 'Mean [DN]: 32041', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBTotalText =       text(0, statsYPositions[3], 'Total [DN]: 593013', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBMaxText =         text(0, statsYPositions[4], 'Max [DN]: 30252', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBMaxLocationText = text(0, statsYPositions[5], 'X:Y Max Location [pixel index]: (1350, 400)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBMinText =         text(0, statsYPositions[6], 'Min [DN]: 205', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBMinLocationText = text(0, statsYPositions[7], 'X:Y Min Location [pixel index]: (1301, 305)', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
megsBRefreshText =     text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = redColor, ALIGNMENT = 1.0)

; CSOL
wc = window(DIMENSIONS = windowSizeCsol, /NO_TOOLBAR, LOCATION = [0, windowSizeCsol[1] + 100], BACKGROUND_COLOR = backgroundColor)
p3 = image(findgen(1000L, 440L), TITLE = 'CSOL', WINDOW_TITLE = 'CSOL', /CURRENT, MARGIN = [0.1, 0.02, 0.1, 0.02], /NO_TOOLBAR, $
           LOCATION = [windowSizeCsol[0] + 5, 0], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
readArrowCSOL = arrow([-50, 0], [0, 0], /DATA, COLOR = greenColor, THICK = 3, /CURRENT)
csolRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = greenColor, ALIGNMENT = 1.0)

; CSOL housekeeping data
wchk = window(DIMENSIONS = windowSizeCsolHk, /NO_TOOLBAR, LOCATION = [0, windowSizeCsol[1] + 150], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'CSOL Housekeeping Data')
t          = text(0.5, topLinePosition - (0  * hkVSpacing), 'Temperatures', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
tThermDet0 = text(0.1, topLinePosition - (1  * hkVSpacing), 'Detector 0 [ºC] = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
tThermDet1 = text(0.1, topLinePosition - (2  * hkVSpacing), 'Detector 1 [ºC] = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
tThermFPGA = text(0.1, topLinePosition - (3  * hkVSpacing), 'FPGA [ºC]         = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
t          = text(0.5, topLinePosition - (4  * hkVSpacing), 'Power', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
tCurrent5v = text(0.1, topLinePosition - (5  * hkVSpacing), 'Current [mA] = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
tVoltage5v = text(0.1, topLinePosition - (6  * hkVSpacing), 'Voltage [V]    = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
t          = text(0.5, topLinePosition - (7  * hkVSpacing), 'Enables', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
tTecEnable = text(0.1, topLinePosition - (8  * hkVSpacing), 'TEC Enable         = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
tFFLEnable = text(0.1, topLinePosition - (9  * hkVSpacing), 'FF Lamp Enable = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
t          = text(0.5, topLinePosition - (10 * hkVSpacing), 'SD Card', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
tSdStart   = text(0.1, topLinePosition - (11  * hkVSpacing), 'SD Start Frame     = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
tSdCurrent = text(0.1, topLinePosition - (12  * hkVSpacing), 'SD Current Frame = ', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)

; Initialize COMMON buffer variables
restore, getenv('rocket_real_time') + 'MegsCcdLookupTable.sav'
megsAImageBuffer = uintarr(2048L, 1024L)
megsBImageBuffer = uintarr(2048L, 1024L)
csolNumberGapPixels = 10
csolImageBuffer =   uintarr(2000L, (5L * 88L) + (csolNumberGapPixels * 4L))
csolRowBuffer = uintarr(1024L)
megsAImageIndex = 0L
megsBImageIndex = 0L
csolImageIndex = 0L
megsAPixelIndex = -1LL
megsBPixelIndex = -1LL
megsATotalPixelsFound = 0
megsBTotalPixelsFound = 0
csolTotalPixelsFound = 0
csolRowNumberInStart = -1 

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

; Prepare image counter for how often to refresh the images
displayImagesCounterMegsA = 0
displayImagesCounterMegsB = 0
displayImagesCounterCsol = 0

; Start an infinite loop to check the socket for data
WHILE 1 DO BEGIN

  ; Start a timer
  wrapperClock = TIC()
  
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
        
        ; Grab packet samples for all 3 instrument packets
        offsetP1 = 36
        numberOfDataSamplesP1 = byte2ulong(singleFullDeweSoftPacket[offsetP1:offsetP1 + 3])
        offsetP2 = offsetP1 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP1
        numberOfDataSamplesP2 = byte2ulong(singleFullDeweSoftPacket[offsetP2:offsetP2 + 3])
;        offsetP3 = offsetP2 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP2
;        numberOfDataSamplesP3 = byte2ulong(singleFullDeweSoftPacket[offsetP3:offsetP3 + 3])
        
        halfwayOffsetP1 = numberOfDataSamplesP1 / 2L + offsetP1 + 4
        halfwayOffsetP2 = numberOfDataSamplesP2 / 2L + offsetP2 + 4
        IF keyword_set(DEBUG2) THEN message, /INFO, JPMsystime() + ' MEGS-A number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP1) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP1: halfwayOffsetP1 + 1]))
        IF keyword_set(DEBUG2) THEN message, /INFO, JPMsystime() + ' MEGS-B number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP2) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP2: halfwayOffsetP2 + 1]))

        
        ;expectedPacketSize = 2 * (numberOfDataSamplesP1 + numberOfDataSamplesP2 + numberOfDataSamplesP3) + 4L * 3L + 44
        expectedPacketSize = 2 * (numberOfDataSamplesP1 + numberOfDataSamplesP2) + 4L * 2L + 44
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

        ; Prepare for comparisons before and after interpretation
        megsAPixelIndexBefore = megsAPixelIndex
        megsBPixelIndexBefore = megsBPixelIndex
        csolPixelIndexBefore = csolPixelIndex

        rocket_eve_tm2_read_packets, singleFullDeweSoftPacket, DEBUG = DEBUG ; Output and additional inputs via COMMON buffers

        ; If did not see anything update after reading packet, then set flag to skip that part of processing in this loop
        doMegsAProcessing = 0
        IF megsAPixelIndex NE megsAPixelIndexBefore THEN BEGIN
          displayImagesCounterMegsA++
          IF displayImagesCounterMegsA GT frequencyOfImageDisplay THEN BEGIN 
            doMegsAProcessing = 1
            displayImagesCounterMegsA = 0
          ENDIF
        ENDIF
        doMegsBProcessing = 0
        IF megsBPixelIndex NE megsBPixelIndexBefore THEN BEGIN
          displayImagesCounterMegsB++
          IF displayImagesCounterMegsB GT frequencyOfImageDisplay THEN BEGIN
            doMegsBProcessing = 1
            displayImagesCounterMegsB = 0
          ENDIF
        ENDIF
        doCsolProcessing = 0
        IF csolPixelIndex NE csolPixelIndexBefore THEN BEGIN
          displayImagesCounterCsol++
          IF displayImagesCounterCsol GT frequencyOfImageDisplay THEN BEGIN
            doCsolProcessing = 1
            displayImagesCounterCsol = 0
          ENDIF
        ENDIF

        ; -= MANIPULATE DATA AS NECESSARY =- ;        
        IF doMegsAProcessing THEN BEGIN
          megsAStatsPixels = megsAImageBuffer[megsAStatisticsBox[0]:megsAStatisticsBox[2], megsAStatisticsBox[1]:megsAStatisticsBox[3]]

          ; Compute centroid in statistics boxes and compute angle offset
          megsACentroid = centroid(megsAStatsPixels)
          xOffsetPixels = megsAExpectedCentroid[0] - megsACentroid[0]
          yOffsetPixels = megsAExpectedCentroid[1] - megsACentroid[1]

          ; Convert from pixel offset to arcmin
          megsAXOffsetArcmin = xOffsetPixels * 5.64
          megsAYOffsetArcmin = yOffsetPixels * 5.64

          ; Compute mean inside stats box
          megsAMean = mean(megsAStatsPixels)

          ; Compute total inside stats box
          megsATotal = total(float(megsAStatsPixels))

          ; Compute max and location of max inside stats box
          megsAMax = max(megsAStatsPixels, maxIndex)
          megsAMaxIndices = array_indices(megsAStatsPixels, maxIndex)

          ; Compute min and location of min inside stats box
          megsAMin = min(megsAStatsPixels, minIndex)
          megsAMinIndices = array_indices(megsAStatsPixels, minIndex)

          ; Compute new location of arrows
          IF megsAPixelIndex MOD 2 NE 0 THEN megsACurrentColumn = (megsAPixelIndex - 1) / 4094L ELSE $
                                             megsACurrentColumn = megsAPixelIndex / 4094L
        ENDIF ; doMegsAProcessing
        
        IF doMegsBProcessing THEN BEGIN
          megsBStatsPixels = megsBImageBuffer[megsBStatisticsBox[0]:megsBStatisticsBox[2], megsBStatisticsBox[1]:megsBStatisticsBox[3]]

          ; Compute centroid in statistics boxes and compute angle offset
          megsBCentroid = centroid(megsBStatsPixels)
          xOffsetPixels = megsBExpectedCentroid[0] - megsBCentroid[0]
          yOffsetPixels = megsBExpectedCentroid[1] - megsBCentroid[1]

          ; Would convert from pixels to arcmin, but we don't use MEGS-B for pointing knowledge
          megsBXOffsetArcmin = xOffsetPixels * 1
          megsBYOffsetArcmin = yOffsetPixels * 1

          ; Compute mean inside stats box
          megsBMean = mean(megsBStatsPixels)

          ; Compute total inside stats box
          megsBTotal = total(float(megsBStatsPixels))

          ; Compute max and location of max inside stats box
          megsBMax = max(megsBStatsPixels, maxIndex)
          megsBMaxIndices = array_indices(megsBStatsPixels, maxIndex)

          ; Compute min and location of min inside stats box
          megsBMin = min(megsBStatsPixels, minIndex)
          megsBMinIndices = array_indices(megsBStatsPixels, minIndex)

          ; Compute new location of arrows
          IF megsBPixelIndex MOD 2 NE 0 THEN megsBCurrentColumn = (megsBPixelIndex - 1) / 4094L ELSE $
                                             megsBCurrentColumn = megsBPixelIndex / 4094L
          IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime() + ' MEGS-B pixel index = ' + JPMPrintNumber(megsBPixelIndex)
        ENDIF ; doMegsBProcessing
        
        ; -= UPDATE PLOT WINDOWS WITH REASONABLE REFRESH RATE =- ;

        !Except = 0 ; Disable annoying divide by 0 messages

        IF doMegsAProcessing THEN BEGIN
          ; Update image
          IF keyword_set(noMod256) THEN p0.SetData, megsAImageBuffer ELSE $
                                        p0.SetData, megsAImageBuffer MOD 256

          ; Update read indicator arrows
          readArrowMegsALeft.SetData, [-50, 0], [1023 - megsACurrentColumn, 1023 - megsACurrentColumn]
          readArrowMegsARight.SetData, [2098., 2048.], [megsACurrentColumn, megsACurrentColumn]

          ; Update statisitics text
          megsACentroidText.String = 'X:Y Centroid [pixel index]: (' + JPMPrintNumber(round(megsACentroid[0])) + ',' + JPMPrintNumber(round(megsACentroid[1])) + ')'
          megsAOffsetText.String = 'X:Y Offset Angles [arcmin]: (' + JPMPrintNumber(megsAXOffsetArcmin) + ',' + JPMPrintNumber(megsAYOffsetArcmin) + ')'
          megsAMeanText.String = 'Mean [DN]: ' + strtrim(round(megsAMean), 2)
          megsATotalText.String = 'Total [DN]: ' + strtrim((megsATotal), 2)
          megsAMaxText.String = 'Max [DN]: ' + strtrim(megsAMax, 2)
          megsAMaxLocationText.String = 'X:Y Max Location [pixel index]: (' + strtrim(megsAMaxIndices[0], 2) + ',' + strtrim(megsAMaxIndices[1], 2) + ')'
          megsAMinText.String = 'Min [DN]: ' + strtrim(megsAMin, 2)
          megsAMinLocationText.String = 'X:Y Min Location [pixel index]: (' + strtrim(megsAMinIndices[0], 2) + ',' + strtrim(megsAMinIndices[1], 2) + ')'

          megsARefreshText.String = 'Last refresh: ' + JPMsystime()
        ENDIF ; doMegsAProcessing
        
        IF doMegsBProcessing THEN BEGIN
          ; Update image
          IF keyword_set(noMod256) THEN p1.SetData, megsBImageBuffer ELSE $
                                        p1.SetData, megsBImageBuffer MOD 256

          ; Update read indicator arrows
          readArrowMegsBLeft.SetData, [-50, 0], [1023 - megsBCurrentColumn, 1023 - megsBCurrentColumn]
          readArrowMegsBRight.SetData, [2098., 2048.], [megsBCurrentColumn, megsBCurrentColumn]

          ; Update statisitics text
          megsBCentroidText.String = 'X:Y Centroid [pixel index]: (' + JPMPrintNumber(round(megsBCentroid[0])) + ',' + JPMPrintNumber(round(megsBCentroid[1])) + ')'
          megsBOffsetText.String = 'X:Y Offset Angles [arcmin]: (' + JPMPrintNumber(megsBXOffsetArcmin) + ',' + JPMPrintNumber(megsBYOffsetArcmin) + ')'
          megsBMeanText.String = 'Mean [DN]: ' + strtrim(round(megsBMean), 2)
          megsBTotalText.String = 'Total [DN]: ' + strtrim(megsBTotal, 2)
          megsBMaxText.String = 'Max [DN]: ' + strtrim(megsBMax, 2)
          megsBMaxLocationText.String = 'X:Y Max Location [pixel index]: (' + strtrim(megsBMaxIndices[0], 2) + ',' + strtrim(megsBMaxIndices[1], 2) + ')'
          megsBMinText.String = 'Min [DN]: ' + strtrim(megsBMin, 2)
          megsBMinLocationText.String = 'X:Y Min Location [pixel index]: (' + strtrim(megsBMinIndices[0], 2) + ',' + strtrim(megsBMinIndices[1], 2) + ')'

          megsBRefreshText.String = 'Last refresh: ' + JPMsystime()
        ENDIF ; doMegsBProcessing
        
        IF doCsolProcessing THEN BEGIN
          ; Update image
          p3.SetData, csolImageBuffer

          ; Update read indicator arrow
          readArrowCSOL.SetData, [-50, 0], [csolRowNumberInStart, csolRowNumberInStart]

          csolRefreshText.String = 'Last refresh: ' + JPMsystime()
        ENDIF ; doCsolProcessing        
        
        !Except = 1 ; Re-enable math error logging

        ; Set the index of this verified sync pattern for use in the next iteration of the DEWESoft sync7Loop
        verifiedSync7Index = sync7Indices[sync7LoopIndex]
      ENDFOR ; sync7LoopIndex = 0, numSync7s - 1
      
      ; Now that all processable data has been processed, overwrite the buffer to contain only bytes from the beginning of 
      ; last sync pattern to the end of socketDataBuffer
      socketDataBuffer = socketDataBuffer[verifiedSync7Index - 7:-1]
    ENDIF ; If numSync7s GE 2
  ENDIF ; If socketDataSize GT 0

  IF keyword_set(DEBUG) THEN BEGIN
    message, /INFO, JPMsystime() + ' Finished processing socket data in time = ' + JPMPrintNumber(TOC(wrapperClock))
  ENDIF
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, lun

END