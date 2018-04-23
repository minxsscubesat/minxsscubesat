;+
; NAME:
;   rocket_eve_tm1_read_packets
;
; PURPOSE:
;   Stripped down code with similar purpose as read_tm1_cd.pro, designed to return the data via a common buffer rather than save to disk as a .dat.
;   Designed to work in conjunction with eve_tm1_real_time_socket_read_wrapper.pro, which shares the COMMON blocks. That code is responsible for 
;   initializing many of the variables in the common blocks.
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
;   monitorsBuffer [uintarr] [input/output]: A 112???? array to be filled in. This program updates the buffer with the current socketData. TODO: How many bytes/elements are there of analog data?
;   sampleSizeDeweSoft [integer] [input]:    This is =2 if using synchronous data in DeweSoft for instrument channels, or =10 if using asynchronous. The additional bytes
;                                            are from timestamps on every sample.
;   offsetP1 [long] [input]:                 How far into the DEWESoftPacket to get to the "Data Samples" bytes of the DEWESoft channel definitions according to the binary
;                                            data format documentation. P1 corresponds to MEGS-A. Note that another 4 bytes need to be skipped to get to the actual data.
;                                            The bytes of instrument samples range from [offsetP1 + 4, (offsetP1 + 4) + (numberOfDataSamplesP1 * sampleSizeDeweSoft)]
;   numberOfDataSamplesP1 [ulong] [input]:   The number of instrument samples contained in the complete DEWESoft packet for the P1 (MEGS-A for EVE) defined stream.
; 
; OUTPUTS:
;   No direct outputs. See common buffer variables above. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMPrintNumber.
;   Requires StripDeweSoftHeaderAndTrailer.
;
; PROCEDURE:
;   TASK 1: Strip DEWESoft headers and trailers to get raw instrument data. Should end up with xriPacketDataWithFiller, megsAPacketDataWithFiller, megsBPacketDataWithFiller.
;           The rest of the code should be repeated for each instrument separately. “instrument” variable names below would be replaced with the relevant instrument int the code.
;   TASK 2: Remove filler. WSMR stuffs in 0x7E7E.
;   TASK 3: Decode analog monitors and stuff into structure to return. 
;      
; EXAMPLE:
;   rocket_eve_tm1_read_packets, socketData
;
; MODIFICATION HISTORY:
;   2017-07-27: James Paul Mason: Wrote script based on rocket_eve_tm2_read_packets.
;-
FUNCTION rocket_eve_tm1_read_packets, socketData, $
                                      VERBOSE = VERBOSE, DEBUG = DEBUG

; COMMON blocks for use with rocket_eve_tm1_real_time_display. The blocks are defined here and there to allow them to be called independently.
COMMON MONITORS_PERSISTENT_DATA, monitorsBuffer
COMMON DEWESOFT_PERSISTENT_DATA, sampleSizeDeweSoft, offsetP1, numberOfDataSamplesP1, offsetP2, numberOfDataSamplesP2, offsetP3, numberOfDataSamplesP3 ; Note P1 = MEGS-A, P2 = MEGS-B, P3 = XRI

; Telemetry stream packet structure
telemetryStreamPacketNumberOfWords = 82L ; 85L if reading a binary file, because WSMR includes 3 words of time information
telemetryStreamPacketNumberOfRows = 8L
nbytes = telemetryStreamPacketNumberOfWords * 2L * telemetryStreamPacketNumberOfRows ; sync_1 + 3 words of time + sfid + mid + 78 words of data + sync_2
nint = nbytes / 2L

; WSMR telemetry packet sync words
wordMask = 'FFFF'X      ; Tom: don't need to mask
sync1Value = '03EB'X
sync1Offset = nint - 1L ; 0L if reading binary file, because WSMR moves this syncbyte to the beginning of the packet
sync2Value = '0333'X
sync2Offset = nint - 2L ; 1L if reading binary file, because WSMR moves sync1 to beginning of packet, making sync2 the end of the packet
sync3Value = '0100'X
sync3Offset = nint - 3L ; 2L if reading binary file, because WSMR moves sync1 to beginning of packet, making sync3... where? 

; Instrument packet fiducial values (sync words)
espFiducialValue1 = '037E'X
espFiducialValue2 = '0045'X
megsPFiducialValue1 = '037E'X
megsPFiducialValue2 = '004D'X
xpsFiducialValue1 = '037E'X
xpsFiducialValue2 = '0058'X

; Define the packet structure
; Definition for flight 36.318
numAnalogs = 24
analogMonitorsStructure = {timeWhatFormat: 0.0D0, $
                           tm_28v_bus_voltage: 0.0, tm_28v_bus_current: 0.0, exp_28v_bus_voltage: 0.0, $
                           camera_12v_voltage: 0.0, $
                           fpga_5v_voltage: 0.0, $
                           solar_section_pressure: 0.0, gate_valve_position: 0.0, cryo_hot_temp: 0.0, $
                           xps_tempb: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
                           megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
                           megsb_ccd_temp: 0.0, megsb_heater: 0.0, $
                           xps_28v_voltage: 0.0, $
                           xps_filter_position: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
                           xrs_tempa: 0.0, xps_tempb: 0.0, xrs_5v_voltage: 0.0, $
                           shutter_door_position: 0.0}

;
; TASK 1: Strip DEWESoft headers and trailers to get raw instrument data. Should end up with xriPacketDataWithFiller, megsAPacketDataWithFiller, megsBPacketDataWithFiller.
;
monitorsPacketDataWithFiller = strip_dewesoft_header_and_trailer(socketData, offsetP1, numberOfDataSamplesP1, sampleSizeDeweSoft) ; [uintarr] ; TODO: Update offset and number variable names

;
; TASK 2: Remove filler. WSMR stuffs in 0x7E7E.
; 
monitorsPacketDataGoodIndices = where(monitorsPacketDataWithFiller NE 0 AND monitorsPacketDataWithFiller NE '7E7E'X, numberOfFoundMonitorBytes)

IF numberOfFoundMonitorBytes NE 0 THEN BEGIN
  monitorsPacketData = monitorsPacketDataWithFiller[monitorsPacketDataGoodIndices]
  
  ; Reform data into 2D array to be compatible with spreadsheet definition and analogMonitorsTelemetryPositionInPacket
  IF n_elements(monitorsPacketData) LT 80 * 8 THEN BEGIN
    IF keyword_set(VERBOSE) THEN BEGIN
      message, /INFO, JPMsystime() + ' socket data had fewer than the expected number of bytes. Expected 80 * 8 = 640 but received ' + n_elements(monitorsPacketData)
      return, !NULL
    ENDIF
  ENDIF
  monitorsPacketData = reform(monitorsPacketData, 80, 8)
  
  ;
  ; TASK 3: Decode analog monitors and stuff into structure to return. 
  ;
  monitorsPacketDataVolts = 0.00 + 5.0 * monitorsPacketData / 1023. ; [V] 10-bit A/D converter
  
  analogMonitorsStructure.tm_28v_bus_voltage = monitorsPacketDataVolts[41, 0] * 0.00918   ; +21.7 just for first byte ; [V]
  analogMonitorsStructure.tm_28v_bus_current = monitorsPacketDataVolts[34, 0] * 0.005     ; [A]
  analogMonitorsStructure.exp_28v_bus_voltage = monitorsPacketDataVolts[18, 0] * 0.005    ; [V]
  analogMonitorsStructure.camera_12v_voltage = monitorsPacketDataVolts[68, 2] * 0.005     ; [V]
  analogMonitorsStructure.fpga_5v_voltage = monitorsPacketDataVolts[68, 1] * 0.055        ; [V]
  analogMonitorsStructure.solar_section_pressure = monitorsPacketDataVolts[56, 0] * 0.005 ; [?]
  analogMonitorsStructure.gate_valve_position = monitorsPacketDataVolts[67, 5] * 0.005    ; [?]
  analogMonitorsStructure.cryo_hot_temp = monitorsPacketDataVolts[57, 0] * 0.005          ; [?]
  analogMonitorsStructure.xps_tempb = monitorsPacketDataVolts[61, 0] * 0.005              ; [?]
  analogMonitorsStructure.megsa_ff = monitorsPacketDataVolts[68, 3] * 0.005               ; [V]
  analogMonitorsStructure.megsb_ff = monitorsPacketDataVolts[68, 4] * 0.005               ; [V]
  analogMonitorsStructure.megsa_ccd_temp = monitorsPacketDataVolts[62, 0] * 0.005         ; [?]
  analogMonitorsStructure.megsa_heater = monitorsPacketDataVolts[45, 0] * 0.005           ; [V]
  analogMonitorsStructure.megsp_temp = monitorsPacketDataVolts[43, 0] * 0.005             ; [?]
  analogMonitorsStructure.megsb_ccd_temp = monitorsPacketDataVolts[67, 2] * 0.005         ; [?]
  analogMonitorsStructure.megsb_heater = monitorsPacketDataVolts[58, 0] * 0.005           ; [V]
  analogMonitorsStructure.xps_28v_voltage = monitorsPacketDataVolts[50, 0] * 0.005        ; TODO: Resolve discrepancy between spreadsheet and DataView [V]
  analogMonitorsStructure.xps_filter_position = monitorsPacketDataVolts[46, 0] * 0.02     ; -3.6 just for first byte ; [V]
  analogMonitorsStructure.xps_cw = monitorsPacketDataVolts[55, 0] * 0.005                 ; [V]
  analogMonitorsStructure.xps_ccw = monitorsPacketDataVolts[54, 0] * 0.005                ; [V]
  analogMonitorsStructure.xrs_tempa = monitorsPacketDataVolts[59, 0] * 0.005              ; [?]
  analogMonitorsStructure.xps_tempb = monitorsPacketDataVolts[49, 0] * 0.005              ; [?]
  analogMonitorsStructure.xrs_5v_voltage = monitorsPacketDataVolts[51, 0] * 0.005         ; [V]
  analogMonitorsStructure.shutter_door_position = monitorsPacketDataVolts[74, 4] * 0.005  ; [?]
  
  return, analogMonitorsStructure
ENDIF ELSE BEGIN ; numberOfFoundMonitorBytes ≠ 0
  IF keyword_set(VERBOSE) THEN BEGIN
    message, /INFO, JPMsystime() + ' No non-filler bytes found in socket data'
  ENDIF
  
  return, !NULL
ENDELSE

END
