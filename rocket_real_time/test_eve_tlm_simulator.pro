;+
; NAME:
;   test_eve_tlm_simulator
;
; PURPOSE:
;   Act as client side for eve_tlm_simulator.pro for debugging purposes. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   server [string]:  The IP address or name of the machine on the network that is running eve_tlm_simulator.
;                     Defaults to 'rocket9'
;   command [string]: The command to send to the eve_tlm_simulator. Options are: 
;                     'getversion', which will simulate getting the version of DEWESoft that is running
;                     'startacq', which will simulate the steps to start receiving data from rocket EVE via DEWESoft. This is the default.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   None
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires eve_tlm_simulator to already be running on server (see optional input)
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2015-02-28: James Paul Mason: Wrote script.
;   2017-08-04: James Paul Massosn: Updated to use separate command and telemetry stream ports
;-

PRO test_eve_tlm_simulator, server = server, command = command
 
  ; Defaults
  IF server EQ !NULL THEN server = 'rocket9'
  IF command EQ !NULL THEN command = 'startacq'
  
  ; Establish connection to server
  port = read_csv('/Users/jmason86/Dropbox/Development/IDLWorkspace/Rocket/test_port.txt')
  port = (uint(byte(port.field1[0]), 0, 2))[1] ; Just for testing
  socket, serverLUN, server, port, /GET_LUN, CONNECT_TIMEOUT = 10., READ_TIMEOUT = 10., WRITE_TIMEOUT = 10., /RAWIO, /SWAP_IF_BIG_ENDIAN
  
  ; Verify connection to server
  IF file_poll_input(serverLUN, TIMEOUT = 1.0) THEN BEGIN
    ; Read data on the socket and print response
    socketData = bytarr((fstat(serverLUN)).size)
    readu, serverLUN, socketData
    simulatedResponse = string(jp_serializer.deserialize(string(socketData), DIM = 33, TYPECODE = 1))
    print, simulatedResponse
    
    ; If connected, then try commanding
    IF simulatedResponse EQ '+CONNECTED DEWESoft TCP/IP Server' THEN BEGIN
      IF command EQ 'getversion' THEN BEGIN
        !NULL = timer.set(0.001, 'testCommandSendCallback', serverLUN)
      ENDIF ELSE IF command EQ 'startacq' THEN BEGIN
        !NULL = timer.set(0.001, 'startTelemetryStreamCallback', serverLUN)
      ENDIF
    ENDIF
  ENDIF
END

PRO testCommandSendCallback, ID, serverLUN
  command = 'getversion'
  print, 'Sending command: ' + command
  message = byte(command)
  messageSerialized = jp_serializer.serialize(message)
  writeu, serverLUN, messageSerialized
  
  !NULL = timer.set(.01, 'listenForCommandResponseCallback', serverLUN)
END
  
PRO listenForCommandResponseCallback, ID, serverLUN
  IF file_poll_input(serverLUN, TIMEOUT = 1.0) THEN BEGIN
    ; Read data on the socket and print response
    socketData = bytarr((fstat(serverLUN)).size)
    readu, serverLUN, socketData, TRANSFER_COUNT = transferCount
    simulatedResponse = string(jp_serializer.deserialize(string(socketData), TYPECODE = 1))
    print, 'Command response: ' + simulatedResponse
  ENDIF
  
  !NULL = timer.set(0.1, 'listenForCommandResponseCallback', serverLUN)
END  

PRO startTelemetryStreamCallback, ID, serverLUN
  telemetryPort = fix(randomu(seed) * 10000)
  command = 'starttransfer ' + strtrim(telemetryPort, 2)
  print, 'Sending command: ' + command
  message = byte(command)
  messageSerialized = jp_serializer.serialize(message)
  writeu, serverLUN, messageSerialized

  !NULL = timer.set(.01, 'listenForCommandResponseCallback', serverLUN)
  
  ; Open the new port
  wait, 1
  socket, telemetryLun, '10.247.21.83', telemetryPort, /GET_LUN, CONNECT_TIMEOUT = 10., READ_TIMEOUT = 10., WRITE_TIMEOUT = 10., /RAWIO, /SWAP_IF_BIG_ENDIAN
  
  command = 'startacq'
  print, 'Sending command: ' + command
  message = byte(command)
  messageSerialized = jp_serializer.serialize(message)
  writeu, serverLUN, messageSerialized

  !NULL = timer.set(.01, 'listenForTelemetryResponseCallback', telemetryLun)
END

PRO listenForTelemetryResponseCallback, ID, telemetryLun
  IF file_poll_input(telemetryLun, TIMEOUT = 1.0) THEN BEGIN
    ; Read data on the socket and print response
    socketData = bytarr((fstat(telemetryLun)).size)
    readu, telemetryLun, socketData, TRANSFER_COUNT = transferCount
    simulatedResponse = jp_serializer.deserialize(string(socketData), TYPECODE = 1)
    print, 'Telemetry received:'
    print, simulatedResponse
  ENDIF

  !NULL = timer.set(0.1, 'listenForTelemetryResponseCallback', telemetryLun)
END
