;+
; NAME:
;   rocket_eve_tm2_real_time_display
;
; PURPOSE:
;   Wraps around a read function and displays the interpreted telemetry for rocket EVE. Calls rocket_eve_tm2_read_packets (the interpreter) when new data comes over the pipe. 
;
; INPUTS:
;   port [integer]: The port number to open that DEWESoft will be commanded to stream data to. This requires that both machines are running on the same network.
;                   This is provided as an optional input only so that a hardcoded value can be specified and the IDLDE Run button hit, instead
;                   of needing to call the code from the command line each time. However, a known port is really is necessary.
;
; OPTIONAL INPUTS:
;   windowSize [integer, integer]:                           Set this to the pixel dimensions in [x, y] that you want the display. Default is [1984, 530],
;                                                            which works well on a 5K iMac with [3200, 1800] resolution.
;   windowSizeCsol [integer, integer]:                       Same idea as windowSize, but for CSOL science data.
;   windowSizeCsolHk [integer, integer]:                     Same idea as windowSizeCsol, but for the housekeeping data.
;   megsAStatisticsBox [integer, integer, integer, integer]: Hard-coded pixel indices for computing statistics. Default around the 304 Å line. 
;                                                            Format is [column1, row1, column2, row2] to define the square box. Ditto for megsB. 
;   megsAExpectedCentroid: [float, float]:                   The expected pixel index location of the centroid in the bounding statistics box. Expected in format [X, Y]. 
;                                                            Default is [1350, 400]. Ditto for megsB. 
;   frequencyOfImageDisplay [integer]:                       The refresh rate of images in the fun units of number of DEWESoftPackets per refresh. 
;
; KEYWORD PARAMETERS:
;   IS_ASYNCHRONOUSDATA: Set this if the DEWESoft software is using an asynchronous byte definition for your channels. Asynchronous data has a timestamp on every sample, 
;                        which increases the byte stream size by a factor of 5. 
;   DOMEGSA:             Set this to process and display MEGS-A data
;   DOMEGSB:             Set this to process and display MEGS-B data
;   DOCSOL:              Set this to process and display CSOL data
;   DEBUG:               Set to print debugging information, such as the sizes of and listed in the packets.
;   VERBOSE:             Set this to print processing messages.
;   LIGHT_BACKGROUND:    Set this to use a white background and dark font instead of the default (black background and white font)

;   
; OUTPUTS:
;   Produces 3 plot panes and a telemetry window with all the most important data in the world, displayed in real time from a remote socket.
;
; OPTIONAL OUTPUTS:
;   None
;   
; COMMON BLOCK VARIABLES: 
;   See rocket_eve_tm2_read_packets for a detailed description. And yes, I know common blocks are bad practice. However, we wanted socket reader / data interpreter modularity but still
;   require persistent data between the two. Passing variables back and forth between two functions is done by reference, but would result in messy code. So here we are with common blocks. 
;
; RESTRICTIONS:
;   Requires that the data pipe computer is not yet running. See procedure below for the critical step-by-step to get the link up. 
;   Requires the rocket_real_time path environment variable. Can do this in an IDL startup file or in shell. 
;   Requires JPMRange.pro
;   Requires JPMPrintNumber.pro
;
; PROCEDURE: 
;   Prior to running this code: 
;   1) Connect this machine to a network with the machine running DEWESoft. This can be done with a crossover cable connecting their two ethernet ports. 
;   
;   The following steps have been scripted so you can just hit the Run button on rocket_tm2_start.scpt. 
;   2) Open a terminal (e.g., terminal.app in OSX)
;   3) type: telnet ipAddress 8999 (where ipAddress is the IP address (duh) of the DEWESoft machine e.g., telnet 192.168.1.90 8999. 
;            8999 is the commanding port and should not need to be changed). You should get an acknowledgement: +CONNECTED DEWESoft TCP/IP server. 
;   4) type: listusedchs (This should return a list of all channels being used. EVE data is in three parallel streams, P1, P2, and P3. 
;            Note the corresponding channel numbers. For EVE these are presently ch 13, 14, and 12, respectively).
;   5) type: /stx preparetransfer
;   6) type: ch 13
;            ch 14
;            ch 12 (or whatever your relevant channel number/s are).
;   7) type: /etx You should get an acknowledgement: +OK
;   8) Now you can start this code. It will open the port specified in the input parameter, or use the hard-coded default if not provided in the call. Then it will STOP. Don't continue yet. 
;   Back to the terminal window
;   9) type: starttransfer port (where port is the same port IDL is using in step 8 above, e.g., starttransfer 8002)
;   10) type: setmode 1 You'll either see +ERR Already in this mode or +OK Mode 1 (control) selected, 
;             depending on if you've already done this step during debugging this when it inevitably doesn't work the first time. 
;   11) type: startacq You should get an acknowledgement: +OK Acquiring
;   12) Now you can continue running this code
;
; EXAMPLE:
;   See PROCEDURE above for examples of each step. 
;-
PRO rocket_eve_tm2_real_time_display, port=port, IS_ASYNCHRONOUSDATA=IS_ASYNCHRONOUSDATA, windowSize=windowSize, windowSizeCsol=windowSizeCsol, windowSizeCsolHk=windowSizeCsolHk, $
                                      megsAStatisticsBox=megsAStatisticsBox, megsBStatisticsBox=megsBStatisticsBox, $
                                      megsAExpectedCentroid=megsAExpectedCentroid, megsBExpectedCentroid=megsBExpectedCentroid, $
                                      frequencyOfImageDisplay=frequencyOfImageDisplay, noMod256=noMod256, $
                                      DOMEGSA=DOMEGSA,DOMEGSB=DOMEGSB,DOCSOL=DOCSOL, DEBUG=DEBUG, VERBOSE=VERBOSE, LIGHT_BACKGROUND=LIGHT_BACKGROUND
                                    
; COMMON blocks for use with rocket_read_tm2_function. The blocks are defined here and there to allow them to be called independently.
COMMON MEGS_PERSISTENT_DATA, megsCcdLookupTable
COMMON MEGS_A_PERSISTENT_DATA, megsAImageBuffer, megsAImageIndex, megsAPixelIndex, megsATotalPixelsFound
COMMON MEGS_B_PERSISTENT_DATA, megsBImageBuffer, megsBImageIndex, megsBPixelIndex, megsBTotalPixelsFound
COMMON CSOL_PERSISTENT_DATA, csolImageBuffer, csolPixelIndex, csolRowNumberLatest, csolTotalPixelsFound, csolNumberGapPixels, csolHk
COMMON DEWESOFT_PERSISTENT_DATA, sampleSizeDeweSoft, offsetP1, numberOfDataSamplesP1, offsetP2, numberOfDataSamplesP2, offsetP3, numberOfDataSamplesP3 ; Note P1 = MEGS-A, P2 = MEGS-B, P3 = CSOL

; Defaults
IF ~keyword_set(port) THEN port = 8002
IF keyword_set(IS_ASYNCHRONOUSDATA) THEN sampleSizeDeweSoft = 10 ELSE sampleSizeDeweSoft = 2
IF ~keyword_set(windowSize) THEN windowSize = [1984, 530]
IF ~keyword_set(windowSizeCsol) THEN windowSizeCsol = [1984, 565]
IF ~keyword_set(windowSizeCsolHk) THEN windowSizeCsolHk = [300, 550]
IF ~keyword_set(megsAStatisticsBox) THEN megsAStatisticsBox = [402, 80, 442, 511]  ; Corresponds to He II 304 Å line
IF ~keyword_set(megsBStatisticsBox) THEN megsBStatisticsBox = [624, 514, 864, 754] ; Corresponds to center block
IF ~keyword_set(megsAExpectedCentroid) THEN megsAExpectedCentroid = [19.6, 215.15] ; Expected for He II 304 Å
IF ~keyword_set(megsBExpectedCentroid) THEN megsBExpectedCentroid = [120., 120.]
IF ~keyword_set(frequencyOfImageDisplay) THEN frequencyOfImageDisplay = 32
IF keyword_set(LIGHT_BACKGROUND) THEN BEGIN
  fontColor = 'black'
  backgroundColor = 'white'
  boxColor = 'light steel blue'
ENDIF ELSE BEGIN
  fontColor = 'white'
  backgroundColor = 'black'
  boxColor = 'grey'
ENDELSE
blueColor = 'dodger blue'
redColor = 'tomato'
greenColor = 'lime green'
fontSize = 18
fontSizeHk = 14
numberOfInstruments = keyword_set(DOMEGSA) + keyword_set(DOMEGSB) + keyword_set(DOCSOL)

; Open a port that the DEWESoft computer will be commanded to stream to (see PROCEDURE in this code's header)
socket, connectionCheckLUN, port, /LISTEN, /GET_LUN, /RAWIO
;STOP, 'Wait until DEWESoft is set to startacq. Then click go.'
wait, 5

; Prepare a separate logical unit (LUN) to read the actual incoming data
get_lun, socketLun

; Wait for the connection from DEWESoft to be detected
isConnected = 0
WHILE isConnected EQ 0 DO BEGIN
  IF file_poll_input(connectionCheckLUN, timeout=5.0) THEN BEGIN ; Timeout is in seconds
    socket, socketLun, accept=connectionCheckLUN, /RAWIO, connect_timeout=30., read_timeout=30., write_timeout=30., /SWAP_IF_BIG_ENDIAN
    isConnected = 1
  ENDIF ELSE message, /INFO, JPMsystime() + ' No connection detected yet.'
ENDWHILE

; Prepare a socket read buffer
socketDataBuffer = !NULL

; Mission specific setup. Edit this to tailor data.
; e.g., instrument calibration arrays such as gain to be used in the MANIPULATE DATA section below
; None needed for EVE

; -= CREATE PLACE HOLDER PLOTS =- ;
; Edit here to change axis ranges, titles, locations, etc. 
statsTextSpacing = 0.02
statsBoxHeight = statsTextSpacing * 20
statsYPositions = reverse(JPMRange(0.005, statsBoxHeight - 0.05, npts = 8))
hkHSpacing = 0.02 ; Horizontal spacing
hkVSpacing = 1./19. ; Vertical spacing for 18 rows of text
topLinePosition = 0.90

; MEGS-A
IF keyword_set(DOMEGSA) then begin
  wa = window(dimensions=windowSize, /NO_TOOLBAR, location=[0, 0], background_color=backgroundColor)
  p0 = image(findgen(2048L, 1024L), title='EVE MEGS A', window_title='EVE MEGS A', /CURRENT, margin=[0.1, 0.02, 0., 0.02], rgb_table='Rainbow', font_size=fontSize, font_color=fontColor)
  c0 = colorbar(target=p0, orientation=1, position=[0.85, 0.03, 0.87, 0.98], textpos=1, font_size=fontSize - 2, text_color=fontColor)
  readArrowMegsALeft = arrow([-50., 0], [1023., 1023.], /DATA, color=blueColor, thick=3, /CURRENT)
  readArrowMegsARight = arrow([2098., 2048], [0, 0], /DATA, color=blueColor, thick=3, /CURRENT)
  statsTextBoxCoords = [[0, 0], [0., statsBoxHeight], [0.21, statsBoxHeight], [0.21, 0]]
  statsTextBox = polygon(statsTextBoxCoords, /FILL_BACKGROUND, fill_color=boxColor, thick=2)
  megsAStatsBoxCoords = [[megsAStatisticsBox[0], megsAStatisticsBox[1]], [megsAStatisticsBox[0], megsAStatisticsBox[3]], [megsAStatisticsBox[2], megsAStatisticsBox[3]], [megsAStatisticsBox[2], megsAStatisticsBox[1]]] ; Polygon uses different structure, so convert
  megsAStatsBox = polygon(megsAStatsBoxCoords, thick=2, fill_transparency=100, /DATA, color=boxColor)
  t = text(0.21/2, statsBoxHeight + 0.005, 'MEGS-A Statistics', alignment=0.5, font_size=fontSize, font_color=fontColor)
  megsACentroidText =    text(0, statsYPositions[0], 'X:Y Centroid [pixel index]: (1350, 400)', font_size=fontSizeHk, font_color=fontColor)
  megsAOffsetText =      text(0, statsYPositions[1], 'X:Y Offset Angles [arcmin]: (0.431, 1.403)', font_size=fontSizeHk, font_color=fontColor)
  megsAMeanText =        text(0, statsYPositions[2], 'Mean [DN]: 32041', font_size=fontSizeHk, font_color=fontColor)
  megsATotalText =       text(0, statsYPositions[3], 'Total [DN]: 593013', font_size=fontSizeHk, font_color=fontColor)
  megsAMaxText =         text(0, statsYPositions[4], 'Max [DN]: 30252', font_size=fontSizeHk, font_color=fontColor)
  megsAMaxLocationText = text(0, statsYPositions[5], 'X:Y Max Location [pixel index]: (1350, 400)', font_size=fontSizeHk, font_color=fontColor)
  megsAMinText =         text(0, statsYPositions[6], 'Min [DN]: 205', font_size=fontSizeHk, font_color=fontColor)
  megsAMinLocationText = text(0, statsYPositions[7], 'X:Y Min Location [pixel index]: (1301, 305)', font_size=fontSizeHk, font_color=fontColor)
  megsARefreshText =     text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), color=blueColor, alignment=1.0)
ENDIF

; MEGS-B
IF keyword_set(DOMEGSB) then begin
  wb = window(dimensions=windowSize, /NO_TOOLBAR, location=[0, windowSize[1] + 50], background_color=backgroundColor)
  p1 = image(findgen(2048L, 1024L), title='EVE MEGS B', window_title='EVE MEGS B', /CURRENT, /NO_TOOLBAR, margin=[0.1, 0.02, 0., 0.02], rgb_table='Rainbow', font_size=fontSize, font_color=fontColor)
  c1 = colorbar(target=p1, orientation=1, position=[0.85, 0.03, 0.87, 0.98], textpos=1, font_size=fontSize - 2, text_color=fontColor)
  readArrowMegsBLeft = arrow([-50., 0], [1023., 1023.], /DATA, color=redColor, thick=3, /CURRENT)
  readArrowMegsBRight=arrow([2098., 2048], [0, 0], /DATA, color=redColor, thick=3, /CURRENT)
  statsTextBox = polygon(statsTextBoxCoords, /FILL_BACKGROUND, fill_color=boxColor, thick=2)
  megsBStatsBoxCoords = [[megsBStatisticsBox[0], megsBStatisticsBox[1]], [megsBStatisticsBox[0], megsBStatisticsBox[3]], [megsBStatisticsBox[2], megsBStatisticsBox[3]], [megsBStatisticsBox[2], megsBStatisticsBox[1]]] ; Polygon uses different structure, so convert
  megsBStatsBox=polygon(megsBStatsBoxCoords, thick=2, fill_transparency=100, /DATA, color=boxColor)
  t = text(0.21/2, statsBoxHeight + 0.005, 'MEGS-B Statistics', alignment=0.5, font_size=fontSize, font_color=fontColor)
  megsBCentroidText =    text(0, statsYPositions[0], 'X:Y Centroid [pixel index]: (1350, 400)', font_size=fontSizeHk, font_color=fontColor)
  megsBOffsetText =      text(0, statsYPositions[1], 'X:Y Offset Angles [arcmin]: (0.431, 1.403)', font_size=fontSizeHk, font_color=fontColor)
  megsBMeanText =        text(0, statsYPositions[2], 'Mean [DN]: 32041', font_size=fontSizeHk, font_color=fontColor)
  megsBTotalText =       text(0, statsYPositions[3], 'Total [DN]: 593013', font_size=fontSizeHk, font_color=fontColor)
  megsBMaxText =         text(0, statsYPositions[4], 'Max [DN]: 30252', font_size=fontSizeHk, font_color=fontColor)
  megsBMaxLocationText = text(0, statsYPositions[5], 'X:Y Max Location [pixel index]: (1350, 400)', font_size=fontSizeHk, font_color=fontColor)
  megsBMinText =         text(0, statsYPositions[6], 'Min [DN]: 205', font_size=fontSizeHk, font_color=fontColor)
  megsBMinLocationText = text(0, statsYPositions[7], 'X:Y Min Location [pixel index]: (1301, 305)', font_size=fontSizeHk, font_color=fontColor)
  megsBRefreshText =     text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), color=redColor, alignment=1.0)
ENDIF

; CSOL
IF keyword_set(DOCSOL) then begin
    ;REMOVE /NO_TOOLBAR if want interactive cursor to tell you the pixel location of cursor (useful for STIM LAMP test)
  wc = window(DIMENSIONS = windowSizeCsol, /NO_TOOLBAR, LOCATION = [0, 2 * windowSize[1] + 78], BACKGROUND_COLOR = backgroundColor)
  p3 = image(findgen(2000L, 480L), TITLE = 'CSOL', WINDOW_TITLE = 'CSOL', /CURRENT, MARGIN = [0.1, 0.02, 0.1, 0.02], $
             LOCATION = [windowSizeCsol[0] + 5, 0], RGB_TABLE = 'Rainbow', FONT_SIZE = fontSize, FONT_COLOR = fontColor)
  c3 = colorbar(TARGET = p3, ORIENTATION = 1, POSITION = [0.91, 0.18, 0.93, 0.82], TEXTPOS = 1, FONT_SIZE = fontSize - 6, TEXT_COLOR = fontColor)
  readArrowCSOL = arrow([0, 0], [-50, 0], /DATA, COLOR = greenColor, THICK = 3, /CURRENT)
  t = text(0.09, 0.75, 'Dark', FONT_SIZE = fontSizeHk, FONT_COLOR = 'grey', ALIGNMENT = 1)
  t = text(0.09, 0.61, 'MUV', FONT_SIZE = fontSizeHk, FONT_COLOR = 'dark violet', ALIGNMENT = 1)
  t = text(0.09, 0.48, 'Dark', FONT_SIZE = fontSizeHk, FONT_COLOR = 'grey', ALIGNMENT = 1)
  t = text(0.09, 0.34, 'FUV', FONT_SIZE = fontSizeHk, FONT_COLOR = 'dodger blue', ALIGNMENT = 1)
  t = text(0.09, 0.21, 'Dark', FONT_SIZE = fontSizeHk, FONT_COLOR = 'grey', ALIGNMENT = 1)
  csolRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = greenColor, ALIGNMENT = 1.0)
  
  ; CSOL housekeeping data
  wchk = window(DIMENSIONS = windowSizeCsolHk, /NO_TOOLBAR, LOCATION = [windowSizeCsol[0] + 5, 2 * windowSize[1] + 78], BACKGROUND_COLOR = backgroundColor, WINDOW_TITLE = 'CSOL Housekeeping Data')
  t          = text(0.5,              topLinePosition - (0   * hkVSpacing), 'Temperatures', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
  t          = text(0.7,              topLinePosition - (1   * hkVSpacing), 'Detector 0 [ºC] = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tThermDet0 = text(0.7 + hkHSpacing, topLinePosition - (1   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (2   * hkVSpacing), 'Detector 1 [ºC] = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tThermDet1 = text(0.7 + hkHSpacing, topLinePosition - (2   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (3   * hkVSpacing), 'FPGA [ºC]         = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tThermFPGA = text(0.7 + hkHSpacing, topLinePosition - (3   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.5,              topLinePosition - (4   * hkVSpacing), 'Power', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
  t          = text(0.7,              topLinePosition - (5   * hkVSpacing), 'Current [mA] = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tCurrent5v = text(0.7 + hkHSpacing, topLinePosition - (5   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (6   * hkVSpacing), 'Voltage [V]    = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tVoltage5v = text(0.7 + hkHSpacing, topLinePosition - (6   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.5,              topLinePosition - (7   * hkVSpacing), 'Enables', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
  t          = text(0.7,              topLinePosition - (8   * hkVSpacing), 'TEC Enable         = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tTecEnable = text(0.7 + hkHSpacing, topLinePosition - (8   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (9   * hkVSpacing), 'FF Lamp Enable = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tFFLEnable = text(0.7 + hkHSpacing, topLinePosition - (9   * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.5,              topLinePosition - (10  * hkVSpacing), 'SD Card', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
  t          = text(0.7,              topLinePosition - (11  * hkVSpacing), 'Start Frame     = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tSdStart   = text(0.7 + hkHSpacing, topLinePosition - (11  * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (12  * hkVSpacing), 'Current Frame = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tSdCurrent = text(0.7 + hkHSpacing, topLinePosition - (12  * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  
  t          = text(0.5,              topLinePosition - (13  * hkVSpacing), 'Int Time', ALIGNMENT = 0.5, FONT_COLOR = blueColor, FONT_SIZE = fontSizeHk + 6)
  t          = text(0.7,              topLinePosition - (14  * hkVSpacing), 'Row Period      = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tRowPeriod = text(0.7 + hkHSpacing, topLinePosition - (14  * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (15  * hkVSpacing), 'Row per Int   = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tRowPerInt = text(0.7 + hkHSpacing, topLinePosition - (15  * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  t          = text(0.7,              topLinePosition - (16  * hkVSpacing), 'Int Time (s)  = ', ALIGNMENT = 1, FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  tIntTime   = text(0.7 + hkHSpacing, topLinePosition - (16  * hkVSpacing), '--', FONT_COLOR = fontColor, FONT_SIZE = fontSizeHk)
  
  csolHkRefreshText = text(1.0, 0.0, 'Last full refresh: ' + JPMsystime(), COLOR = greenColor, ALIGNMENT = 1.0)
ENDIF

; Initialize COMMON buffer variables
restore, getenv('rocket_real_time') + 'MegsCcdLookupTable.sav'
megsAImageBuffer = uintarr(2048L, 1024L)
megsBImageBuffer = uintarr(2048L, 1024L)
csolNumberGapPixels = 10
csolImageBuffer = uintarr(2000L, (5L * 88L) + (csolNumberGapPixels * 4L))
megsAImageIndex = 0L
megsBImageIndex = 0L
megsAPixelIndex = -1LL
megsBPixelIndex = -1LL
csolpixelindex = -1LL
megsATotalPixelsFound = 0
megsBTotalPixelsFound = 0
csolTotalPixelsFound = 0
csolRowNumberLatest = -1 

; Prepare image counter for how often to refresh the images
displayImagesCounterMegsA = 0
displayImagesCounterMegsB = 0
displayImagesCounterCsol = 0

processCounter = 0L ; count loops executed
lastProcessCounter = -1L

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
    wait, 0.5 ; tune the wait time to reduce CPU load from tiny reads, usually reads abotu 80,000 bytes
    readu, socketLun, socketData
    print,'number of bytes read = '+strtrim(n_elements(socketData),2)
    
    ; Stuff the new socketData into the buffer. This will work even the first time around when the buffer is !NULL. 
    socketDataBuffer = [temporary(socketDataBuffer), temporary(socketData)]
    
    ; Do an efficient search for just the last DEWESoft sync byte
    sync7Indices = where(socketDataBuffer EQ 7 AND $
       shift(socketDataBuffer,-1) EQ 6 AND $
       shift(socketDataBuffer,-2) EQ 5 AND $
       shift(socketDataBuffer,-3) EQ 4 AND $
       shift(socketDataBuffer,-4) EQ 3 AND $
       shift(socketDataBuffer,-5) EQ 2 AND $
       shift(socketDataBuffer,-6) EQ 1 AND $
       shift(socketDataBuffer,-7) EQ 0 $
       , numSync7s)
  
    ; If some 0x07 sync bytes were found, then loop to verify the rest of the sync byte pattern (0x00 0x01 0x02 0x03 0x04 0x05 0x06)
    ; and process the data between every set of two verified sync byte patterns
    IF numSync7s GE 2 THEN BEGIN
      
      ; Reset the index of the verified sync patterns
      verifiedSync7Index = !NULL
;      verifiedSync7Index = wStartSync[0]
      
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
;        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 7 + 12] NE 0 THEN CONTINUE ; check packet type
;        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 7 + 13] NE 0 THEN CONTINUE ; check packet type
;        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 7 + 14] NE 0 THEN CONTINUE ; check packet type
;        IF socketDataBuffer[sync7Indices[sync7LoopIndex] - 7 + 15] NE 0 THEN CONTINUE ; check packet type

        
        ; If this is the first syncLoopIndex, then verify this sync pattern and continue to the next sync pattern to determine 
        ; the data to process (singleFullDeweSoftPacket) between the two sync patterns
        IF sync7LoopIndex EQ 0 THEN BEGIN
          verifiedSync7Index = sync7Indices[sync7LoopIndex]
            CONTINUE
        ENDIF
;        IF verifiedSync7Index EQ !NULL THEN BEGIN
;           verifiedSync7Index = sync7Indices[sync7LoopIndex] 
;           CONTINUE
;         ENDIF
         
        ; Store the data to be processed between two DEWESoft sync patterns
        singleFullDeweSoftPacket = socketDataBuffer[verifiedSync7Index - 7:sync7Indices[sync7LoopIndex] - 8]
               
        ;Checking if packet type is 0 (i.e. a data packet) else skip
        packetType = byte2ulong(singleFullDeweSoftPacket[12:12+3])

        IF packetType NE 0 THEN BEGIN
          IF keyword_set(debug1) THEN print, "Skipping as datatype is", packetType
          verifiedSync7Index = sync7Indices[sync7LoopIndex]
          CONTINUE
        ENDIF

        ; -= PROCESS DATA =- ;
        
        ; Grab packet samples for all 3 instrument packets
        offsetP1 = 36
        numberOfDataSamplesP1 = byte2ulong(singleFullDeweSoftPacket[offsetP1:offsetP1 + 3])
        offsetP2 = offsetP1 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP1
        numberOfDataSamplesP2 = byte2ulong(singleFullDeweSoftPacket[offsetP2:offsetP2 + 3])
        
        IF keyword_set(DOCSOL) THEN BEGIN
          offsetP3 = offsetP2 + 4 + sampleSizeDeweSoft * numberOfDataSamplesP2
          numberOfDataSamplesP3 = byte2ulong(singleFullDeweSoftPacket[offsetP3:offsetP3 + 3])
        ENDIF ELSE BEGIN
          numberOfDataSamplesP3 = 0
        ENDELSE
        
        halfwayOffsetP1 = numberOfDataSamplesP1 / 2L + offsetP1 + 4
        halfwayOffsetP2 = numberOfDataSamplesP2 / 2L + offsetP2 + 4
        IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime() + ' MEGS-A number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP1) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP1: halfwayOffsetP1 + 1]), /NO_DECIMALS)
        IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime() + ' MEGS-B number of data samples in DEWESoft packet: ' $
                                    + JPMPrintNumber(numberOfDataSamplesP2) + ' First word: ' + JPMPrintNumber(byte2uint(singleFullDeweSoftPacket[halfwayOffsetP2: halfwayOffsetP2 + 1]), /NO_DECIMALS)

        
        expectedPacketSize = sampleSizeDeweSoft * (numberOfDataSamplesP1 + numberOfDataSamplesP2 + numberOfDataSamplesP3) + 4L * numberOfInstruments + 44
        IF expectedPacketSize NE n_elements(singleFullDeweSoftPacket) THEN BEGIN
           message, /INFO, JPMsystime() + ' Measured single DEWESoft packet length not equal to expectation. Expected: ' $ 
                           + JPMPrintNumber(expectedPacketSize, /NO_DECIMAL) + ' bytes but received ' $
                           + JPMPrintNumber(n_elements(singleFullDeweSoftPacket), /NO_DECIMAL) + ' bytes.'
        ENDIF
        
        IF keyword_set(DEBUG) THEN BEGIN
          print, 'Socket:', socketDataSize, byte2ulong(singleFullDeweSoftPacket[8:11]), numberOfDataSamplesP1, $
            byte2uint(singleFullDeweSoftPacket[offsetP1 + 4: offsetP1 + 5]), $
            numberOfDataSamplesP2, byte2uint(singleFullDeweSoftPacket[offsetP2 + 4: offsetP2 + 5]), $
            format='(a8, 3i12, z5, i12, z5, i12, z5)'
        ENDIF

        ; Prepare for comparisons before and after interpretation
        megsAPixelIndexBefore = megsAPixelIndex
        megsBPixelIndexBefore = megsBPixelIndex
        csolPixelIndexBefore = csolPixelIndex

        rocket_eve_tm2_read_packets, singleFullDeweSoftPacket, DOMEGSA=DOMEGSA, DOMEGSB=DOMEGSB, DOCSOL=DOCSOL, DEBUG=DEBUG ; Output and additional inputs via COMMON buffers

        ; If did not see anything update after reading packet, then set flag to skip that part of processing in this loop
        doMegsAProcessing = 0
        if keyword_set(DOMEGSA) then begin
          IF megsAPixelIndex NE megsAPixelIndexBefore THEN BEGIN
            displayImagesCounterMegsA++
            IF displayImagesCounterMegsA GT frequencyOfImageDisplay THEN BEGIN 
              doMegsAProcessing = 1
              displayImagesCounterMegsA = 0
            ENDIF
          ENDIF
        ENDIF
        doMegsBProcessing = 0
        if keyword_set(DOMEGSB) then begin
          IF megsBPixelIndex NE megsBPixelIndexBefore THEN BEGIN
            displayImagesCounterMegsB++
            IF displayImagesCounterMegsB GT frequencyOfImageDisplay THEN BEGIN
              doMegsBProcessing = 1
              displayImagesCounterMegsB = 0
            ENDIF
          ENDIF
        ENDIF
        doCsolProcessing = 0
        if keyword_set(DOCSOL) then begin
          IF csolPixelIndex NE csolPixelIndexBefore THEN BEGIN
            displayImagesCounterCsol++
            IF displayImagesCounterCsol GT frequencyOfImageDisplay THEN BEGIN
              doCsolProcessing = 1
              displayImagesCounterCsol = 0
            ENDIF
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
          IF keyword_set(noMod256) THEN p3.SetData, csolImageBuffer ELSE $
                                        p3.SetData, csolImageBuffer MOD 256

          ; Update read indicator arrow
          readArrowCSOL.SetData, [csolRowNumberLatest, csolRowNumberLatest], [-30, 0]

          csolRefreshText.String = 'Last refresh: ' + JPMsystime()
          
          ; Update hk telemetry
          IF csolHk NE !NULL THEN BEGIN
            tThermDet0.String = JPMPrintNumber(csolHk.thermDet0)
            tThermDet1.String = JPMPrintNumber(csolHk.thermDet1)
            tThermFPGA.String = JPMPrintNumber(csolHk.thermFPGA)
            tCurrent5v.String = JPMPrintNumber(csolHk.current5v)
            tVoltage5v.String = JPMPrintNumber(csolHk.voltage5v)
            IF csolHk.tecEnable EQ 1 THEN tTecEnable.String = 'True' ELSE IF csolHk.tecEnable EQ 0 THEN tTecEnable.String = 'False' ELSE tTecEnable.String = JPMPrintNumber(csolHk.tecEnable, /NO_DECIMALS)
            IF csolHk.fflEnable EQ 1 THEN tFFLEnable.String = 'True' ELSE IF csolHk.fflEnable EQ 0 THEN tFFLEnable.String = 'False' ELSE tFFLEnable.String = JPMPrintNumber(csolHk.fflEnable, /NO_DECIMALS)
            tSdStart.String = JPMPrintNumber(csolHk.sdStartFrameAddress, /NO_DECIMALS)
            tSdCurrent.String = JPMPrintNumber(csolHk.sdCurrentFrameAddress, /NO_DECIMALS)
            tRowPeriod.String = JPMPrintNumber(csolHk.rowPeriod, /NO_DECIMALS)
            tRowPerInt.String = JPMPrintNumber(csolHk.rowPerInt, /NO_DECIMALS)
            tIntTime.String = JPMPrintNumber(csolHk.intTime)
            
            ; Limit check / red/green coloring
            IF csolHk.thermDet0 LT 20 OR csolHk.thermDet0 GT 0 THEN tThermDet0.Color = greenColor ELSE tThermDet0.Color = redColor
            IF csolHk.thermDet1 LT 20 OR csolHk.thermDet1 GT 0 THEN tThermDet1.Color = greenColor ELSE tThermDet1.Color = redColor
            IF csolHk.thermFPGA LT 60 OR csolHk.thermFPGA GT 15 THEN tThermFPGA.Color = greenColor ELSE tThermFPGA.Color = redColor
            IF csolHk.current5v LT 380 OR csolHk.current5v GT 300 THEN tCurrent5v.Color = greenColor ELSE tCurrent5v.Color = redColor
            IF csolHk.voltage5v LT 5.5 OR csolHk.voltage5v GT 4.5 THEN tVoltage5v.Color = greenColor ELSE tVoltage5v.Color = redColor
            IF csolHk.tecEnable EQ 1 THEN tTecEnable.Color = greenColor ELSE tTecEnable.Color = redColor
            IF csolHk.fflEnable EQ 0 THEN tFFLEnable.Color = greenColor ELSE tFFLEnable.Color = redColor
            IF csolHk.intTime GT 10.23 AND csolHK.intTime LT 10.25 THEN tIntTime.Color = greenColor ELSE tIntTime.Color = redColor

            csolHkRefreshText.String = 'Last refresh: ' + JPMsystime()
          ENDIF
          
          csolHk = !NULL
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

  IF keyword_set(VERBOSE) THEN BEGIN
    message, /INFO, JPMsystime() + ' Finished processing socket data in ' + JPMPrintNumber(TOC(wrapperClock), /NO_DECIMALS) + ' seconds'
  ENDIF
  processCounter++
ENDWHILE ; Infinite loop

; These lines never get called since the only way to exit the above infinite loop is to stop the code
free_lun, socketlun
free_lun, lun

END