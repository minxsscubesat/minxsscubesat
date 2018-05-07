;+
; NAME:
;   eve_tm_simulator
;
; PURPOSE:
;   Reformat raw EVE binary data to emulate the White Sands Missile Range TM1 format and pipe it to a network port. 
;   This will enable testing of other code designed to interpret and display the data from TM1. 
;   Server code based on an exelis blog post because this functionality is not included in main IDL documentation 
;   http://harrisgeospatial.com/Learn/Blogs/Blog-Details/TabId/2716/ArtMID/10198/ArticleID/15743/Serializing-Objects-Between-IDL-Sessions-Using-TCPIP-for-Remote-Plot-Display.aspx
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   port [string]: The port to use for communication. Default changes because it gets used for testing/debugging workflow. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Sends responses through the IP socket port
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMPrintNumber
;
; EXAMPLE:
;   This code won't actually do anything other than wait for IP connections and then receive and respond to commands over the socket to do something specific. 
;   So, first run this code. 
;   Then run something else to connect to it, e.g., test_eve_tm_simulator. 
;
; MODIFICATION HISTORY:
;   2015-02-26: James Paul Mason: Wrote script.
;   2017-08-04: James Paul Mason: Updated to have a separate command and telemetry stream socket
;-
PRO eve_tm_simulator, port = port
  ; Defaults
  port = read_csv('~/Dropbox/minxss_dropbox/code/rocket_real_time/test_port.txt')
  port = swap_endian((uint(byte(port.field1[0]), 0, 2))[1], /SWAP_IF_BIG_ENDIAN) ; Just for testing
  IF ~keyword_set(port) THEN port = swap_endian((uint(byte('pony'), 0, 2))[1], /SWAP_IF_BIG_ENDIAN)

  ; Listen for initial connections to be established
  socket, connectionCheckLUN, port, /LISTEN, /GET_LUN, READ_TIMEOUT = 60., WRITE_TIMEOUT = 60., /RAWIO
  !NULL = timer.set(0.1, 'connectionEstablishedCallback', connectionCheckLUN)
END

PRO connectionEstablishedCallback, ID, connectionCheckLUN  
  ; Check for data on the line
  IF file_poll_input(connectionCheckLUN, timeout = 0.1) THEN BEGIN
    socket, commandSocketLUN, accept = connectionCheckLUN, /GET_LUN, /RAWIO, CONNECT_TIMEOUT = 30., READ_TIMEOUT = 30., WRITE_TIMEOUT = 30., /SWAP_IF_BIG_ENDIAN
    
    ; Emulate DEWESoft box by sending a welcome message - "+CONNECTED DEWESoft TCP/IP Server"
    messageSerialized = jp_serializer.serialize(byte('+CONNECTED DEWESoft TCP/IP Server'))
    writeu, commandSocketLUN, messageSerialized
    
    ; Start listening for commands
    !NULL = timer.set(0.1, 'listenForCommandsCallback', commandSocketLUN)
    
  ENDIF ELSE !NULL = timer.set(0.1, 'connectionEstablishedCallback', connectionCheckLUN)
END

PRO liveDataConnectionEstablishedCallback, ID, hashData
  COMMON SOCKETS, liveDataSocketLUN
  
  IF hashData NE !NULL THEN BEGIN
    commandSocketLUN = hashData['commandSocketLUN']
    liveDataCheckLUN = hashData['liveDataCheckLUN']
    port = hashData['port'] 
  
    IF file_poll_input(liveDataCheckLUN, timeout = 0.1) THEN BEGIN
      socket, liveDataSocketLUN, accept = liveDataCheckLUN, /GET_LUN, /RAWIO, CONNECT_TIMEOUT = 30., READ_TIMEOUT = 30., WRITE_TIMEOUT = 30., /SWAP_IF_BIG_ENDIAN
      
      !NULL = timer.set(0.1, 'streamLiveDataCallback', liveDataSocketLUN)
    ENDIF ELSE !NULL = timer.set(0.1, 'liveDataConnectionEstablishedCallback', hashData)
    
  ENDIF
  !NULL = timer.set(0.1, 'liveDataConnectionEstablishedCallback', hashData)
END

PRO listenForCommandsCallback, ID, commandSocketLUN
  IF (file_poll_input(commandSocketLUN, timeout = 0.1)) THEN BEGIN
    ; Read data on the socket and store command
    socketData = bytarr((fstat(commandSocketLUN)).size)
    readu, commandSocketLUN, socketData, TRANSFER_COUNT = transferCount
    command = string(jp_serializer.deserialize(string(socketData), TYPECODE = 1))
    
    ; Respond to commands 
    !NULL = timer.set(0.1, 'respondToCommandsCallback', hash('commandSocketLUN', commandSocketLUN, 'command', command))
    
  ENDIF ELSE !NULL = timer.set(0.1, 'listenForCommandsCallback', commandSocketLUN)
END

PRO respondToCommandsCallback, ID, hashData
  COMMON SOCKETS, liveDataSocketLUN
  
  commandSocketLUN = hashData['commandSocketLUN']
  command = hashData['command']
  
  IF command EQ 'getversion' THEN BEGIN
    print, 'Received command: getversion. Responding...'
    responseToSend = '+OK 6.6 b12'
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend
  ENDIF
  
  IF command EQ 'listusedchs' THEN BEGIN
    print, 'Received command: listusedchs. (List Used Channels). Responding...'
    responseToSend = ['+STX listing channels', $ ; Note this is just an example response from the screenshot in DEWESoft NET interface V2 June2014.pdf
                      'CH 0 AI 0  - 1 0 2 200000  1 0 0.000152587890625 0 AI  0 Direct () -5  5 0 -4.10187  4.23813 0.0601337', $
                      'CH 1 AI  1 - 1 - 2 200000  1 0 0.000152587890625 0 AI  1 Direct () -5  5 0 -4.81873  4.9379  0.062616', $
                      '+ETX end list'] 
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend
  ENDIF
  
  ; NOTE: This is not a command actually accepted by DEWESoft. The corresponding command would be: 
  ; /stx preparetransfer
  ; ch # 
  ; ch #2
  ; ... 
  ; /etx
  IF strmatch(command, 'tm') THEN BEGIN
    tmToStream = fix(strmid(command, 2, 1))
    print, 'Received command: ' + command + ' to choose which telemetry stream to use'
    responseToSend = 'NON-DEWESoft COMMAND, but setting telemetry stream to ' + strtrim(tmToStream, 2) + '. DEWESoft /stx preparetransfer is the equivalent of this.'
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend
  ENDIF
  
  IF command EQ 'setmode 1' THEN BEGIN
    print, 'Received command: ' + command + ' to take remote control of DEWESoft'
    responseToSend = '+OK Mode 1 (control) selected'
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend
  ENDIF
  
  IF strmatch(command, 'starttransfer*') THEN BEGIN
    print, 'Received command: ' + command + ' to establish a live data stream over a new port. Processing and responding...'
    newPort = long(strmid(command, 14, 4))
    print, 'New port opening on: ' + strtrim(newPort, 2)

    responseToSend = '+OK Transfer started'
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend

    ; Listen for initial connections to be established
    socket, liveDataCheckLUN, newPort, /LISTEN, /GET_LUN, READ_TIMEOUT = 60., WRITE_TIMEOUT = 60., /RAWIO
    socketsHash = hash('liveDataCheckLUN', liveDataCheckLUN, 'commandSocketLUN', commandSocketLUN, 'port', newPort)
    IF isA(socketsHash, 'long') THEN STOP
    !NULL = timer.set(0.1, 'liveDataConnectionEstablishedCallback', socketsHash)
  ENDIF
  
  IF command EQ 'startacq' THEN BEGIN
    print, 'Received command: ' + command + ' to start acquiring data over the socket'
    responseToSend = '+OK Acquiring'
    messageSerialized = jp_serializer.serialize(byte(responseToSend))
    writeu, commandSocketLUN, messageSerialized
    print, 'Response sent: ' + responseToSend
    print, 'Starting data stream over socket'
    !NULL = timer.set(0.01, 'streamLiveDataCallback', liveDataSocketLUN)
  ENDIF
  
END

PRO streamLiveDataCallback, ID, liveDataSocketLUN
  IF tmToStream EQ !NULL THEN BEGIN
    tmToStream = 1 ; Default the telemetry stream to TM1 if not defined by 'tm' command already
  ENDIF

  ; Configure for TM1 or TM2
  IF tmToStream EQ 1 THEN BEGIN
    filename = '/Users/jama6159/Dropbox/Research/Postdoc_LASP/Rocket/TM1_Raw_Data_05_06_16_16-57_SequenceAllFire-2_DataViewTimeStampRemoved.dat'
    syncBytes = 1003
  ENDIF ELSE IF tmToStream EQ 2 THEN BEGIN
    filename = '/Volumes/projects/Phase_Development/Rocket_Woods/Flights/36.290/Flight_Data/binary/36290_Flight_TM2.log'
    syncBytes = [256, 819, 1003]
  ENDIF
  
  ; Read binary data from file
  binaryAllPackets = read_binary(filename, DATA_TYPE = 12) ; data_type 12 is uint
  
  ; Search for the sync bytes in the binary data and grab just the first packet
  syncIndices = where(binaryAllPackets EQ syncBytes[0])
  responseToSend = binaryAllPackets[syncIndices[0] : syncIndices[1] - 1]
  
  ; Feed the single packet to the socket
  messageSerialized = jp_serializer.serialize(byte(responseToSend))
  writeu, liveDataSocketLUN, messageSerialized
  print, 'Sending data packet (byte format):'
  print, byte(responseToSend)
  
END

PRO justSendTm1PacketOverPort
  ; File to read from
  filename = '/Users/jama6159/Dropbox/Research/Postdoc_LASP/Rocket/TM1_Raw_Data_05_06_16_16-57_SequenceAllFire-2_DataViewTimeStampRemoved.dat'
  syncBytes = 1003

  ; Read binary data from file
  binaryAllPackets = read_binary(filename, DATA_TYPE = 12) ; data_type 12 is uint

  ; Search for the sync bytes in the binary data and grab just the first packet
  syncIndices = where(binaryAllPackets EQ syncBytes[0])
  responseToSend = binaryAllPackets[syncIndices[0] : syncIndices[1] - 1]

  ; Set up the socket
  port = read_csv('~/Dropbox/minxss_dropbox/code/real_time_rocket/test_port.txt')
  port = (uint(byte(port.field1[0]), 0, 2))[1] ; Just for testing
  socket, connectionCheckLUN, '10.201.203.136', port, /GET_LUN, CONNECT_TIMEOUT = 10., READ_TIMEOUT = 10., WRITE_TIMEOUT = 10., /RAWIO, /SWAP_IF_BIG_ENDIAN ; That IP is James's laptop at the moment
  
  WHILE 1 DO BEGIN
  
    IF file_poll_input(connectionCheckLUN, timeout = 0.1) THEN BEGIN
      socket, connectedSocketLun, accept = connectionCheckLUN, /GET_LUN, /RAWIO, CONNECT_TIMEOUT = 30., READ_TIMEOUT = 30., WRITE_TIMEOUT = 30., /SWAP_IF_BIG_ENDIAN
  
      ; Emulate DEWESoft box by sending a welcome message - "+CONNECTED DEWESoft TCP/IP Server"
      messageSerialized = jp_serializer.serialize(byte('+CONNECTED DEWESoft TCP/IP Server'))
      writeu, connectedSocketLun, messageSerialized
    
      ; Feed the single packet to the socket
      messageSerialized = jp_serializer.serialize(byte(responseToSend))
      writeu, connectedSocketLun, messageSerialized
      print, 'Sending data packet (byte format):'
      print, byte(responseToSend)
      
      BREAK
    ENDIF
    
    message, /INFO, 'Did not see a connection'
  ENDWHILE
END