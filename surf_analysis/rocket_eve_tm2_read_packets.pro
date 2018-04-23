;+
; NAME:
;   rocket_eve_tm2_read_packets
;
; PURPOSE:
;   Stripped down code with similar purpose as read_tm2_all_cd.pro, designed to return the data via a common buffer rather than save to disk as a .dat.
;   Designed to work in conjunction with eve_xri_real_time_socket_read_wrapper.pro, which shares the COMMON blocks. That code is responsible for initializing
;   many of the variables in the common blocks.
;
; INPUTS:
;   socketData [bytarr]: Data retrieved from an IP socket. 
;
; OPTIONAL INPUTS:
;   None
;   
; KEYWORD PARAMETERS:
;   VERBOSE: Set to print out additional information about how the processing is proceeding. 
;   DEBUG: Set to print out additional information useful for debugging. 
;
; COMMON BUFFER VARIABLES: 
;   megsCcdLookupTable [fltarr] [input]:         A 3 x 2 million array containing pixel indices 0-2,097,151 and their corresponding column and row in the MEGS CCD.
;                                                Passed via common buffer so that it uses a pointer rather than copying the whole array as it would with an optional input. 
;   megsAImageBuffer [uintarr] [input/output]:   A 2048 * 1024 image to be filled in. This program updates the buffer with the current socketData. 
;                                                Ditto for megsBImageBuffer. Ditto for xriImageBuffer, except its a 1024 * 1024 image. 
;   megsAImageIndex [long] [input/output]:       The number of images received so far. This program updates the value if a fiducial for MEGS is found. 
;                                                Ditto for megsBImageIndex and xriImageIndex.
;   megsAPixelIndex [long] [input/output]:       A single number indicating the pixel index in the CCD. This program updates it with the number of pixels read in socketData. 
;                                                Ditto for megsBPixelIndex.
;   megsATotalPixelsFound [long] [input/output]: Incremements by the number of pixels found in socketData. Used for checking whether too much or too little data were
;                                                collected for an image, which should be 2048 * 1024 pixels. Ditto for megsBTotalPixelsFound and xriTotalPixelsFound.
;   xriRowBuffer [bytarr] [input/output]:        Same idea as the image buffers but just for XRI rows. XRI packet metadata includes a row number and frame (image) number. 
;                                                Once a full row is buffered, can store it in the correct row of the xriImageBuffer using that metadata. 
;   xriFrameNumberInStart [long] [input/output]: If the frame (image) number is found at the start of a new image, this program updates it. It's used for checking 
;                                                image validity by comparing its value to xriFrameNumberInEnd. 
;   xriRowNumberInStart [long] [input/output]:   Same idea as xriFrameNumberInStart, but for the row number. 
;   xriRowNumberInEnd [long] [input/output]:     The complement to xriRowNumberInStart, but found at the end of an image row. 
;   xriFrameNumberInEnd [long] [input/output]:   The complement to xriFrameNumberInStart, but found at the end of an image.
;   sampleSizeDeweSoft [integer] [input]:        This is =2 if using synchronous data in DeweSoft for instrument channels, or =10 if using asynchronous. The additional bytes
;                                                are from timestamps on every sample. 
;   offsetP1 [long] [input]:                     How far into the DEWESoftPacket to get to the "Data Samples" bytes of the DEWESoft channel definitions according to the binary
;                                                data format documentation. P1 corresponds to MEGS-A. Note that another 4 bytes need to be skipped to get to the actual data. 
;                                                The bytes of instrument samples range from [offsetP1 + 4, (offsetP1 + 4) + (numberOfDataSamplesP1 * sampleSizeDeweSoft)]                                         
;   numberOfDataSamplesP1 [ulong] [input]:       The number of instrument samples contained in the complete DEWESoft packet for the P1 (MEGS-A for EVE) defined stream. 
;   offsetP2 [long] [input]:                     Same idea as offsetP1, but for MEGS-B. 
;   numberOfDataSamplesP2 [ulong] [input]:       Same idea as numberOfDataSamplesP1, but for MEGS-B. 
;   offsetP3 [long] [input]:                     Same idea as offsetP1, but for XRI. 
;   numberOfDataSamplesP3 [ulong] [input]:       Same idea as numberOfDataSamplesP1, but for XRI. 
; 
; OUTPUTS:
;   No direct outputs. See common buffer variables above. 
;   
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMPrintNumber, JPMsystime
;   Requires StripDeweSoftHeaderAndTrailer. 
;
; PROCEDURE: 
;   TASK 1: Strip DEWESoft headers and trailers to get raw instrument data. Should end up with xriPacketDataWithFiller, megsAPacketDataWithFiller, megsBPacketDataWithFiller. 
;           The rest of the code should be repeated for each instrument separately. “instrument” variable names below would be replaced with the relevant instrument int the code. 
;   TASK 2: Remove filler. For XRI this is 0x3FF and WSMR stuffs in 0x7E7E. End up with new variable, instrumentPacketData. 
;   TASK 3: Store pixels in common buffer. (Note: XRI will have to first fill a rowBuffer, then move that full row into the imageBuffer). (Note: MEGS needs to be “unzipped”). 
;   TASK 4: Check limits:
;      4.1: If totalPixels GT imageSize, issue warning. 
;      4.2: If totalPixels LE imageSize, issue warning. 
; 
; EXAMPLE:
;   rocket_eve_tm2_read_packets, socketData
;
; MODIFICATION HISTORY:
;   2015-04-13: James Paul Mason: Wrote script.
;   2015-04-25: James Paul Mason: The last few days have seen extensive edits to this code to get it work in the field where real debugging could be done. 
;-
PRO rocket_eve_tm2_read_packets, socketData, VERBOSE = VERBOSE, DEBUG = DEBUG

; COMMON blocks for use with eve_real_time_socket_read_wrapper. The blocks are defined here and there to allow them to be called independently.
COMMON MEGS_PERSISTENT_DATA, megsCcdLookupTable
COMMON MEGS_A_PERSISTENT_DATA, megsAImageBuffer, megsAImageIndex, megsAPixelIndex, megsATotalPixelsFound
COMMON MEGS_B_PERSISTENT_DATA, megsBImageBuffer, megsBImageIndex, megsBPixelIndex, megsBTotalPixelsFound
COMMON XRI_PERSISTENT_DATA, xriImageBuffer, xriImageIndex, xriRowBuffer, xriFrameNumberInStart, xriRowNumberInStart, xriRowNumberInEnd, xriFrameNumberInEnd, xriTotalPixelsFound
COMMON DEWESOFT_PERSISTENT_DATA, sampleSizeDeweSoft, offsetP1, numberOfDataSamplesP1, offsetP2, numberOfDataSamplesP2, offsetP3, numberOfDataSamplesP3 ; Note P1 = MEGS-A, P2 = MEGS-B, P3 = XRI

; Telemetry stream packet structure
telemetryStreamPacketNumberOfWords = 82L ; 85L if reading a binary file, because WSMR includes 3 words of time information
telemetryStreamPacketNumberOfRows = 3L
nbytes = telemetryStreamPacketNumberOfWords * 2L * telemetryStreamPacketNumberOfRows   ; sync_1 + 3 words of time + sfid + mid + 78 words of data + sync_2
nint = nbytes / 2L

; WSMR telemetry packet sync words
wordMask = 'FFFF'X    ; Tom: don't need to mask
sync1Value = '2840'X
sync1Offset = nint - 1L ; 0L if reading binary file, because WSMR moves this syncbyte to the beginning of the packet
sync2Value = 'FE6B'X
sync2Offset = nint - 2L ; 1L if reading binary file, because WSMR moves sync1 to beginning of packet, making sync2 the end of the packet

; Instrument packet fiducial values (sync words)
xriFrameStartFiducialValue1 = '3E'X
xriFrameStartFiducialValue2 = '46'X
xriFrameStartFiducialValue3 = '42'X
xriFrameStartFiducialValue4 = '65'X
xriFrameStartFiducialValue5 = '67'X
xriFrameStartFiducialValue6 = '2A'X
xriRowStartFiducialValue1   = '3E'X
xriRowStartFiducialValue2   = '4C'X
xriRowStartFiducialValue3   = '42'X
xriRowStartFiducialValue4   = '65'X
xriRowStartFiducialValue5   = '67'X
xriRowEndFiducialValue1     = '3C'X
xriRowEndFiducialValue2     = '4C'X
xriRowEndFiducialValue3     = '45'X
xriRowEndFiducialValue4     = '6E'X
xriRowEndFiducialValue5     = '64'X
xriFrameEndFiducialValue1   = '3C'X
xriFrameEndFiducialValue2   = '3C'X
xriFrameEndFiducialValue3   = '46'X
xriFrameEndFiducialValue4   = '45'X
xriFrameEndFiducialValue5   = '6E'X
xriFrameEndFiducialValue6   = '64'X
megsFiducialValue1          = 'FFFF'X ; Was called mfidvalue1
megsFiducialValue2          = 'AAAA'X ; Was called mfidvalue2

;
; TASK 1: Strip DEWESoft headers and trailers to get raw instrument data. Should end up with xriPacketDataWithFiller, megsAPacketDataWithFiller, megsBPacketDataWithFiller.
;
megsAPacketDataWithFiller = strip_dewesoft_header_and_trailer(socketData, offsetP1, numberOfDataSamplesP1, sampleSizeDeweSoft) ; [uintarr]
megsBPacketDataWithFiller = strip_dewesoft_header_and_trailer(socketData, offsetP2, numberOfDataSamplesP2, sampleSizeDeweSoft) ; [uintarr]
;xriPacketDataWithFiller   = strip_dewesoft_header_and_trailer(socketData, offsetP3, numberOfDataSamplesP3, sampleSizeDeweSoft) ; [uintarr]

;
;
; -= INSTRUMENT: MEGS-A =- ;
;
;

;
; TASK 2: Remove filler. WSMR stuffs in 0x7E7E. End up with new variable, instrumentPacketData.
;
megsAPacketDataGoodIndices = where(megsAPacketDataWithFiller NE 0 AND megsAPacketDataWithFiller NE '7E7E'X, numberOfFoundMegsAPixels)
IF numberOfFoundMegsAPixels NE 0 THEN BEGIN 

  megsAPacketData = megsAPacketDataWithFiller[megsAPacketDataGoodIndices]
  
  ;
  ; TASK 3: Store pixels in common buffer. (Note: MEGS needs to be “unzipped”). 
  ;
  FOR packetIndex = 0, n_elements(megsAPacketData) - 1 DO BEGIN
    IF megsAPixelIndex LT 2048LL * 1024LL THEN BEGIN
      megsACcdColumnRow = megsCcdLookupTable[1:2, megsAPixelIndex]
      megsAImageBuffer[megsACcdColumnRow[0], megsACcdColumnRow[1]] = ((megsAPacketData[packetIndex] + '2000'X) AND '3FFF'X) ; The 0x2000 and 0x3FFF mask out the extra 2 bits (14 bits instead of 16)
      megsAPixelIndex++
    ENDIF
  ENDFOR
  megsATotalPixelsFound += n_elements(megsAPacketData)
  IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime() + ' MEGS-A total pixels found in this image so far: ' + JPMPrintNumber(megsATotalPixelsFound)
  
  ;
  ;   TASK 4: Check limits:
  ;      4.1: If totalPixels GT imageSize, issue warning.
  ;
  IF megsATotalPixelsFound GT 2048LL * 1024LL THEN BEGIN
    message, /INFO, JPMsystime() + ' MEGS A image has accumulated too many pixels. Expected 2048x1024 = 2,097,152 pixels but received ' + JPMPrintNumber(megsATotalPixelsFound)
    megsAPixelIndex = 0LL
    megsATotalPixelsFound = 0L
    megsAImageIndex++
  ENDIF
ENDIF ELSE BEGIN ; End of numberOfFoundMegsAPixels NE 0
  
  ; Getting to this point implies that all data in the packet was 0 or 0x7e7e (filler), which only (should) happen when the image is finished being dumped and WSMR is filling
  ; the remaining bandwidth (10 Mbps) of the telemetry link with filler. 
  
  ;
  ; TASK 4.2: If totalPixels LE imageSize, issue warning.
  ;
  IF megsATotalPixelsFound LT 2048L * 1024L - 2L AND megsATotalPixelsFound NE 0 THEN message, /INFO, JPMsystime() + $ ; -2 because we're expecting to lose two pixels due to including fiducials
    'Some MEGS A data in previous image was lost. Expected 2048x1024 = 2,097,152 pixels but received ' + JPMPrintNumber(megsATotalPixelsFound)
  
  ; Reset image pointers for a new image
  megsAPixelIndex = 0LL
  megsATotalPixelsFound = 0L
  
  ; Increment the number of image read
  megsAImageIndex++  
ENDELSE

;
;
; -= INSTRUMENT: MEGS-B =- ;
;
;

;
; TASK 2: Remove filler. WSMR stuffs in 0x7E7E. End up with new variable, instrumentPacketData.
;
megsBPacketDataGoodIndices = where(megsBPacketDataWithFiller NE 0 AND megsBPacketDataWithFiller NE '7E7E'X, numberOfFoundMegsBPixels)
IF numberOfFoundMegsBPixels NE 0 THEN BEGIN
  
  megsBPacketData = megsBPacketDataWithFiller[megsBPacketDataGoodIndices]
   
  ;
  ; TASK 3: Store pixels in common buffer. (Note: MEGS needs to be “unzipped”).
  ;
  FOR packetIndex = 0, n_elements(megsBPacketData) - 1 DO BEGIN
    IF megsBPixelIndex LT 2048LL * 1024LL THEN BEGIN
      megsBCcdColumnRow = megsCcdLookupTable[1:2, megsBPixelIndex]
      megsBImageBuffer[megsBCcdColumnRow[0], megsBCcdColumnRow[1]] = ((megsBPacketData[packetIndex] + '2000'X) AND '3FFF'X) ; The 0x2000 and 0x3FFF mask out the extra 2 bits (14 bits instead of 16)
      megsBPixelIndex++
    ENDIF
  ENDFOR
  megsBTotalPixelsFound += n_elements(megsBPacketData)
  IF keyword_set(DEBUG) THEN message, /INFO, JPMsystime () + 'MEGS-B total pixels found in this image so far: ' + JPMPrintNumber(megsBTotalPixelsFound)
  
  ;
  ;   TASK 4: Check limits:
  ;      4.1: If totalPixels GT imageSize, issue warning.
  ;
  IF megsBTotalPixelsFound GT 2048L * 1024L THEN BEGIN
    message, /INFO, JPMsystime() + ' MEGS B image has accumulated too many pixels. Expected 2048x1024 = 2,097,152 pixels but received ' + JPMPrintNumber(megsBTotalPixelsFound)
    megsBPixelIndex = 0LL
    megsBTotalPixelsFound = 0L
    megsBImageIndex++
  ENDIF
ENDIF ELSE BEGIN ; End of numberOfFoundMegsBPixels NE 0
  
  ; Getting to this point implies that all data in the packet was 0 or 0x7e7e (filler), which only (should) happen when the image is finished being dumped and WSMR is filling
  ; the remaining bandwidth (10 Mbps) of the telemetry link with filler. 
  
  ; TASK 4.2: If totalPixels LE imageSize, issue warning. 
  IF megsBTotalPixelsFound LT 2048L * 1024L - 2L AND megsBTotalPixelsFound NE 0 THEN message, /INFO, JPMsystime() + $ ; -2 because we're expecting to lose to pixels due to including fiducials
    ' Some MEGS B data in previous image was lost. Expected 2048x1024 = 2,097,152 pixels but received ' + JPMPrintNumber(megsBTotalPixelsFound)
  
  ; Reset image pointers for a new image
  megsBPixelIndex = 0LL
  megsBTotalPixelsFound = 0L
  
  ; Increment the number of image read
  megsBImageIndex++  
ENDELSE

;
;
; -= INSTRUMENT: XRI =- ;
;
;

;;
;; TASK 2: Remove filler. For XRI this is 0x3FF (unless Greg changes it) and WSMR stuffs in 0x7E7E. End up with new variable, instrumentPacketData.
;;
;xriPacketDataGoodIndices = where(xriPacketDataWithFiller NE 0 AND xriPacketDataWithFiller NE '7E7E'X AND xriPacketDataWithFiller NE '3FF'X, numberOfFoundXriPixels)
;skipXri = 0
;IF numberOfFoundXriPixels NE 0 THEN xriPacketData = xriPacketDataWithFiller[xriPacketDataGoodIndices] ELSE skipXri = 1
;IF skipXri NE 1 THEN BEGIN 
;  ;
;  ; TASK 3: Concatenate: concatenatedInstrumentPacketData = [previousInstrumentPacketData, instrumentPacketData]. Slide data: previousInstrumentPacketData = instrumentPacketData.
;  ;
;  IF previousXriPacketData NE !NULL THEN $
;    concatenatedXriPacketData = [previousXriPacketData, xriPacketData] ELSE $
;    concatenatedXriPacketData = xriPacketData
;  startingIndex = n_elements(previousXriPacketData) - 1 ; Only need to look at last word of previousPacket
;  previousXriPacketData = xriPacketData
;  IF n_elements(concatenatedXriPacketData) LT 9 THEN GOTO, SKIP_XRI
;  
;  ;
;  ; TASK 4: Search for instrument-dependent fiducials. If found, set instrumentPixelIndex = 0. (Note: XRI will have xriRowIndex as well as pixelIndex).
;  ;
;  FOR i = startingIndex, n_elements(concatenatedXriPacketData) - 8 DO BEGIN ; - 8 because indexing up to i + 7 in loop
;    ; Frame start sync
;    IF concatenatedXriPacketData[i + 0] EQ xriFrameStartFiducialValue1 AND concatenatedXriPacketData[i + 1] EQ xriFrameStartFiducialValue2 AND concatenatedXriPacketData[i + 2] EQ xriFrameStartFiducialValue3 AND $
;      concatenatedXriPacketData[i + 3] EQ xriFrameStartFiducialValue4 AND concatenatedXriPacketData[i + 4] EQ xriFrameStartFiducialValue5 AND concatenatedXriPacketData[i + 5] EQ xriFrameStartFiducialValue6 THEN BEGIN
;      xriFrameNumberInStart = concatenatedXriPacketData[i + 6:i + 7]
;      xriFrameStartSyncFound = 1
;      IF keyword_set(DEBUG) THEN message, /INFO, 'Found XRI frame start fiducial at: ' + JPMsystime()
;      BREAK
;    ENDIF ELSE xriFrameStartSyncFound = 0
;  
;    ; Row start sync
;    IF concatenatedXriPacketData[i + 0] EQ xriRowStartFiducialValue1 AND concatenatedXriPacketData[i + 1] EQ xriRowStartFiducialValue2 AND concatenatedXriPacketData[i + 2] EQ xriRowStartFiducialValue3 AND $
;      concatenatedXriPacketData[i + 3] EQ xriRowStartFiducialValue4 AND concatenatedXriPacketData[i + 4] EQ xriRowStartFiducialValue5 THEN BEGIN
;      xriRowNumberInStart = concatenatedXriPacketData[i + 5:i + 7]
;      xriRowStartSyncFound = 1
;      xriDataStartIndex = i - startingIndex + 5 ; - startingIndex for referencing inside xriPacketData, not concatenatedXriPacketData
;      xriTotalPixelsFound = 0
;      IF keyword_set(DEBUG) THEN message, /INFO, 'Found XRI row start fiducial at: ' + JPMsystime()
;      BREAK
;    ENDIF ELSE xriRowStartSyncFound = 0
;  
;    ; Row end sync
;    IF concatenatedXriPacketData[i + 0] EQ xriRowEndFiducialValue1 AND concatenatedXriPacketData[i + 1] EQ xriRowEndFiducialValue2 AND concatenatedXriPacketData[i + 2] EQ xriRowEndFiducialValue3 AND $
;      concatenatedXriPacketData[i + 3] EQ xriRowEndFiducialValue4 AND concatenatedXriPacketData[i + 4] EQ xriRowEndFiducialValue5 THEN BEGIN
;      xriRowNumberInEnd = concatenatedXriPacketData[i + 5: i + 7]
;      xriRowEndSyncFound = 1
;      xriDataEndIndex = i - startingIndex - 1 ; - startingIndex for referencing inside xriPacketData, not concatenatedXriPacketData
;      IF keyword_set(DEBUG) THEN message, /INFO, 'Found XRI row end fiducial at: ' + JPMsystime()
;      BREAK
;    ENDIF ELSE xriRowEndSyncFound = 0
;  
;    ; Frame end sync
;    IF concatenatedXriPacketData[i + 0] EQ xriFrameEndFiducialValue1 AND concatenatedXriPacketData[i + 1] EQ xriFrameEndFiducialValue2 AND concatenatedXriPacketData[i + 2] EQ xriFrameEndFiducialValue3 AND $
;      concatenatedXriPacketData[i + 3] EQ xriFrameEndFiducialValue4 AND concatenatedXriPacketData[i + 4] EQ xriFrameEndFiducialValue5 AND concatenatedXriPacketData[i + 5] EQ xriFrameEndFiducialValue6 THEN BEGIN
;      xriFrameNumberInEnd = concatenatedXriPacketData[i + 6:i + 7]
;      xriFrameEndSyncFound = 1
;      IF keyword_set(DEBUG) THEN message, /INFO, 'Found XRI frame end fiducial at: ' + JPMsystime()
;      BREAK
;    ENDIF ELSE xriFrameEndSyncFound = 0
;  ENDFOR
;  
;  ; Responses based on whether fiducials were found or not
;  IF xriFrameStartSyncFound EQ !NULL THEN GOTO, SKIP_XRI
;  IF xriFrameStartSyncFound THEN BEGIN
;    xriImageIndex++
;    xriRowIndex = 0
;  ENDIF
;  IF xriRowIndex EQ !NULL THEN GOTO, SKIP_XRI
;  IF xriFrameEndSyncFound AND xriRowIndex LT 1023 THEN message, /INFO, 'Some XRI data in previous image was lost.'
;  IF xriRowStartSyncFound THEN BEGIN
;    xriColumnIndex = 0
;    xriRowBuffer = !NULL
;  ENDIF
;  IF xriRowEndSyncFound THEN BEGIN
;    IF xriColumnIndex LT 1023 THEN message, /INFO, 'Some XRI data in previous row was lost. Expected 1024 columns but received ' + JPMPrintNumber(xriColumnIndex)
;    IF xriRowNumberInEnd NE xriRowNumberInStart THEN message, /INFO, 'XRI row # mismatch between start and end syncs.'
;    IF xriRowNumberInEnd   NE xriRowIndex THEN message, /INFO, 'XRI row # mismatch between end sync and program counter.'
;    IF xriRowNumberInStart NE xriRowIndex THEN message, /INFO, 'XRI row # mismatch between start sync and program counter.'
;  ENDIF
;  IF ~xriRowStartSyncFound THEN xriDataStartIndex = 0
;  IF ~xriRowEndSyncFound THEN xriDataEndIndex = -1
;  
;  ;
;  ; TASK 5: Store pixels in common buffer. (Note: XRI will have to first fill a rowBuffer, then move that full row into the imageBuffer).
;  ;
;  xriRowBuffer = [xriRowBuffer, xriPacketData[xriDataStartIndex:xriDataEndIndex]]
;  xriColumnIndex += n_elements(xriPacketData[xriDataStartIndex:xriDataEndIndex])
;  IF xriRowEndSyncFound THEN BEGIN
;    xriImageBuffer[*, xriRowNumberInEnd] = xriRowBuffer
;    xriRowIndex++
;    xriTotalPixelsFound += n_elements(xriPacketData[xriDataStartIndex:xriDataEndIndex])
;  ENDIF ELSE IF n_elements(xriRowBuffer) EQ 1024 THEN xriImageBuffer[*, xriRowNumberInEnd] = xriRowBuffer
;  
;  ;
;  ;   TASK 6: Check limits:
;  ;      6.1: If totalPixels GT imageSize, issue warning.
;  ;      6.2: If totalPixels LE imageSize then instrumentPixelindex += numberOfNewPixels.
;  ;
;  IF xriTotalPixelsFound GT 1024L * 1024L THEN message, /INFO, 'XRI image has accumulated too many pixels. Expected 1024x1024 = 1,048,576 pixels but received ' + JPMPrintNumber(xriTotalPixelsFound)
;  IF xriFrameEndSyncFound AND xriTotalPixelsFound LT 1024L * 1024L THEN message, /INFO, 'Some XRI data in previous image was lost. Expected 1024x1024 = 1,048,576 pixels but received ' + JPMPrintNumber(xriTotalPixelsFound)
;ENDIF ; XRI data found
;SKIP_XRI:
END