;+
; NAME:
;   test_dewesoft_packet_processing_speed
;
; PURPOSE:
;   DeweSoft's current setup on ALTAIR-0167 includes an 8 byte timestamp on every sample. This could be too much overhead 
;   for processing to keep up, so this code will print sizes and process as fast as possible to see if we could keep
;   up in the best case scenario. 
;
; INPUTS:
;   None: Note that port is provided as an optional input because it has a hard coded default, but it is really a necessary
;         parameter to specify for the code to work properly. 
;
; OPTIONAL INPUTS:
;   port [integer]: A port number to use for communicating between the DeweSoft Altair box and this machine. 
;
; KEYWORD PARAMETERS:
;   DEBUG: Set to print debugging information, such as the sizes of and listed in the packets. 
;
; OUTPUTS:
;   None: Though the main objective here is to get socketDataBuffer filled with interpretable data, which would be an output
;         in code intended for flight use. This code is only intended to debug the interface. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires byte2ulong.pro written by Tom Woods on 2015/04/23. 
;   
; PROCEDURE: 
;   print size(socket)
;   Open socket
;   print packet size
;   print number of samples in each channel, which requires computing the word offset
;
; EXAMPLE:
;   None, just run it! 
;
; MODIFICATION HISTORY:
;   2015/04/23: James Paul Mason: Wrote script.
;-
PRO test_dewesoft_packet_processing_speed, port = port, DEBUG = DEBUG

IF ~keyword_set(port) THEN port = 8002
IF ~keyword_set(DEBUG) THEN debug = 1
sampleSizeVar = 2

IF connectionCheckLUN EQ !NULL THEN BEGIN
  socket, connectionCheckLUN, port, /LISTEN, /GET_LUN, READ_TIMEOUT = 60., WRITE_TIMEOUT = 60., /RAWIO
  message, /INFO, 'Wait until DEWESoft is set to startacq. Then click go.'
  STOP
ENDIF
get_lun, socketLun

; This only grabs the very first packet, after this read, all data is read on the socketLun. 
noDatayet = 1
WHILE noDataYet EQ 1 DO BEGIN
  IF file_poll_input(connectionCheckLUN, timeout = 1.0) THEN BEGIN
    socket, socketLun, accept = connectionCheckLUN, /RAWIO, CONNECT_TIMEOUT = 30., READ_TIMEOUT = 30., WRITE_TIMEOUT = 30., /SWAP_IF_BIG_ENDIAN
    noDataYet = 0
  ENDIF ELSE message, /INFO, 'No data found on connection.'
ENDWHILE

socketDataBuffer = !NULL

WHILE 1 DO BEGIN

  ; Read data on the socket
  socketDataSize = (fstat(socketLun)).size
  
  IF socketDataSize GT 0 THEN BEGIN
    socketData = bytarr(socketDataSize)
    readu, socketLun, socketData
    
    syncFound = 0
    FOR i = 0UL, socketDataSize - 8 DO BEGIN
      IF socketData[i] EQ 0 AND socketData[i + 1] EQ 1 AND socketData[i + 2] EQ 2 AND socketData[i + 3] EQ 3 AND socketData[i + 4] EQ 4 $
      AND socketData[i + 5] EQ 5 AND socketData[i + 6] EQ 6 AND socketData[i + 7] EQ 7 THEN BEGIN
        syncFound = 1
        
        ; Process old data
        IF socketDataBuffer NE !NULL THEN BEGIN
          
          IF i GT 0 THEN socketDataBuffer = [socketDataBuffer, socketData[0:i-1]]
          
          ; Grab packet samples for all 3 instrument packets
          offsetP1 = 36
          dataSamplesP1 = byte2ulong(socketDataBuffer[offsetP1:offsetP1 + 3])
          offsetP2 = offsetP1 + 4 + sampleSizeVar * dataSamplesP1
          dataSamplesP2 = byte2ulong(socketDataBuffer[offsetP2:offsetP2 + 3])
          offsetP3 = offsetP2 + 4 + sampleSizeVar * dataSamplesP2
          dataSamplesP3 = byte2ulong(socketDataBuffer[offsetP3:offsetP3 + 3])
          
          IF keyword_set(DEBUG) THEN $
          
           print, 'Socket:', socketDataSize, byte2ulong(socketDataBuffer[8:11]), dataSamplesP1, $ 
                             byte2uint(socketDataBuffer[offsetP1 + 4: offsetP1 + 5]), $
                             dataSamplesP2, byte2uint(socketDataBuffer[offsetP2 + 4: offsetP2 + 5]), $
                             dataSamplesP3, byte2uint(socketDataBuffer[offsetP3 + 4: offsetP3 + 5]), $
                             format = '(a8, 3i12, z5, i12, z5, i12, z5)'
          
        ENDIF
        socketDataBuffer = socketData[i:-1]
      ENDIF
    ENDFOR
    
    IF ~syncFound THEN BEGIN
      socketDataBuffer = [socketDataBuffer, socketData]
    ENDIF
  ENDIF; ELSE message, /INFO, 'No data found on socket.'
ENDWHILE
END