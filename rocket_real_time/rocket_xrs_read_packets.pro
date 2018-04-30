;+
; NAME:
;   rocket_xrs_read_packets
;
; PURPOSE:
;   Read real time data from EVE Rocket for the XRS. 
;
; INPUTS:
;   input [string]: Name of file to read (string) or a bytarr containing packet(s)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Option to print number of packets found
;
; OUTPUTS:
;   hk [structure]: Return array of housekeeping (monitors, status) packets
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; MODIFICATION HISTORY:
;   2016-05-03: James Paul Mason: Copied from current version of minxss_read_packets (FM-1 flight). Deleted everything but hk since that's all that's needed
;                                 for EVE Rocket XRS. 
;+
pro rocket_xrs_read_packets, input, hk=hk, $
                      VERBOSE = VERBOSE

; Define initial quantum of packet array length
N_CHUNKS = 500

if (n_params() lt 1) then begin
  print, 'USAGE: xrs_read_packets, input_file, hk=hk, /verbose'
  input=' '
endif
IF size(input[0], /TYPE) EQ 7 THEN if (strlen(input) lt 2) then begin
  ; find file to read
  input = dialog_pickfile(/read, title='Select XRS Hydra tlm file to read', filter='tlm_packets*')
  if (strlen(input) lt 2) then return   ; user did not select file
endif

inputType = ''
IF size(input, /TYPE) EQ 7 THEN BEGIN
  inputType = 'file'
  fileOpened = 0
  on_ioerror, exit_read
  finfo = file_info( input )
  if (finfo.exists ne 0) and (finfo.read ne 0) and (finfo.size gt 6) then begin
    if keyword_set(verbose) then print, 'READING ', strtrim(finfo.size,2), ' bytes from ', input
    openr, lun, input, /get_lun
    fileOpened = 1
    adata = assoc(lun, bytarr(finfo.size))
    data = adata[0]
    close, lun
    free_lun, lun
    fileOpened = 0
    on_ioerror, NULL
  endif else goto, exit_read
ENDIF ELSE BEGIN
  inputType = 'bytarr'
  data = input ; input provided was a file name else input was already bytarr
ENDELSE

SYNC_BYTE1 = byte('A5'X)
SYNC_BYTE2 = byte('A5'X)

; Add these sync bytes to the beginning since flight software adds them to the end of packets
IF ~(data[0] EQ SYNC_BYTE1 AND data[1] EQ SYNC_BYTE2) THEN data = [SYNC_BYTE1, SYNC_BYTE2, data]

CCSDS_BYTE1 = byte('08'X)
CCSDS_BYTE5 = byte('00'X)

PACKET_ID_HK = 25

PACKET_ID_HK_PLAYBACK = PACKET_ID_HK + '40'X

;
;    HK Packet Structure definition  (only partially defined so can do quick check for battery cycle)
;
hk_count = 0L
hk_struct1 = { apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0,  $
  cdh_info: 0U, $
  cdh_state: 0B, spacecraft_mode: 0B, eclipse_state: 0B, $
  adcs_info: 0, $
  adcs_state: 0B, adcs_attitude_valid: 0B, adcs_refs_valid: 0B, adcs_time_valid: 0B, $
  adcs_recommend_sun: 0B, adcs_mode: 0B, $
  time_offset: 0L, $
  cmd_last_opcode: 0, cmd_last_status: 0, cmd_accept_count: 0L, cmd_reject_count: 0L, $
  sd_hk_routing: 0, sd_log_routing: 0, sd_diag_routing: 0, $
  sd_adcs_routing: 0, sd_ximg_routing: 0, sd_sci_routing: 0, $
  sd_hk_write_offset: 0L, sd_log_write_offset: 0L, sd_diag_write_offset: 0L, $
  sd_adcs_write_offset: 0L, sd_ximg_write_offset: 0L, sd_sci_write_offset: 0L, $
  sd_hk_read_offset: 0L, sd_log_read_offset: 0L, sd_diag_read_offset: 0L,  $
  sd_adcs_read_offset: 0L, sd_ximg_read_offset: 0L, sd_sci_read_offset: 0L, $
  fsw_major_minor: 0, fsw_patch_version: 0, flight_model: 0, adcs_gain_detuned: 0, adcs_using_sps: 0, $
  paramSetHdrByte1: 0, paramSetHdrByte2: 0, $
  sd_WriteCtrlBlockAddr: 0, sd_EphemerisBlockAddr: 0, $
  lockout_TimeoutCounter: 0L, contactTx_TimeoutCounter: 0L, $
  battery_HeaterSetpoint: 0, instrument_HeaterSetpoint: 0, $
  cdh_batt_v: 0.0, cdh_batt_v2: 0.0, cdh_5v: 0.0, cdh_3v: 0.0, cdh_temp: 0.0, $
  cdh_enables: 0U, $
  enable_comm: 0B, enable_adcs: 0B, enable_sps_xps: 0B, enable_x123: 0B, enable_batt_heater: 0B, $
  enable_ant_deploy: 0B, enable_sa_deploy: 0B, enable_inst_heater: 0B, enable_spare: 0B, enable_comm_ext: 0B,  $
  cdh_i2c_err: 0L, cdh_rtc_err: 0L, cdh_spi_sd_err: 0L, $
  cdh_uart1_err: 0L, cdh_uart2_err: 0L, cdh_uart3_err: 0L, cdh_uart4_err: 0L, $
  radio_counter: 0L, radio_temp: 0.0, radio_time: 0.0D0, radio_rssi: 0,  $
  radio_received: 0L, radio_transmitted: 0L, $
  comm_last_cmd: 0, comm_last_status: 0, comm_temp: 0.0, $
  mb_temp1: 0.0, mb_temp2: 0.0, $
  eps_temp1: 0.0, eps_temp2: 0.0, $
  eps_fg_volt: 0.0, eps_fg_soc: 0.0, $
  eps_sa1_cur: 0.0, eps_sa1_volt: 0.0, eps_sa2_cur: 0.0, eps_sa2_volt: 0.0, $
  eps_sa3_cur: 0.0, eps_sa3_volt: 0.0, $
  eps_batt_cur: 0.0, eps_batt_volt: 0.0, $
  eps_3v_cur: 0.0, eps_3v_volt: 0.0, eps_5v_cur: 0.0, eps_5v_volt: 0.0, $
  eps_sa1_temp: 0.0, eps_sa2_temp: 0.0, eps_sa3_temp: 0.0, $
  eps_batt_volt2: 0.0, eps_batt_charge: 0.0, eps_batt_temp1: 0.0, $
  eps_batt_discharge: 0.0, eps_batt_temp2: 0.0, $
  sps_xps_pwr_3v: 0.0, sps_xps_pwr_temp: 0.0, sps_xps_pwr_d5v: 0.0, sps_xps_pwr_a5v: 0.0, $
  sps_xps_temp: 0.0, xps_xps_temp: 0.0, x123_brd_temp: 0.0, XACT_CommandRejectStatus: 0.0,$
  sps_xps_dac1: 0.0, $
  xps_data: 0.D0, dark_data: 0.D0, $
  sps_sum: 0.D0, sps_x: 0.0, sps_y: 0.0, $
  X123_Fast_Count: 0L, X123_Slow_Count: 0L, X123_Det_Temp: 0L, $
  
  ; 2016/05/03: James Paul Mason: NOTE: The XACT telemetry points from MinXSS have been replaced with GOES/XRS data for the EVE sounding rocket
;  XACT_P5VTrackerVoltage: 0.0, XACT_P12VBusVoltage: 0.0, XACT_TrackerDetectorTemp: 0.0, XACT_Wheel2Temp: 0,  $
;  XACT_MeasSunBodyVectorX: 0.0, XACT_MeasSunBodyVectorY: 0.0, XACT_MeasSunBodyVectorZ: 0.0, $
;  XACT_CommandStatus: 0B, XACT_CommandAcceptCount: 0B, XACT_CommandAcceptAPID: 0B, XACT_CommandAcceptOpCode: 0B, $
;  XACT_CommandRejectCount: 0B, XACT_CommandRejectAPID: 0B, XACT_CommandRejectOpCode: 0B, XACT_Wheel1EstDrag: 0.0,  $
;  XACT_Wheel2EstDrag: 0.0, XACT_Wheel3EstDrag: 0.0,  $
;  XACT_Wheel1MeasSpeed: 0.0, XACT_Wheel2MeasSpeed: 0.0, XACT_Wheel3MeasSpeed: 0.0,  $
;  XACT_BodyFrameRateX: 0.0,  XACT_BodyFrameRateY: 0.0, XACT_BodyFrameRateZ: 0.0,  $
;  XACT_LVL0_Bitflags: 0B, XACT_LVL0_Counter: 0B, XACT_LVL0_CmdRejectCount: 0B,  $
;  XACT_LVL0_CmdAcceptCount: 0B, $
  xps_data2: 0.D0, dark_data2: 0.D0, $
  sps_sum2: 0.D0, sps_x2: 0.0, sps_y2: 0.0, $
  motor_pos_flag_xrs_a: 0B, motor_pos_flag_xrs_b: 0B, motor_pos_flag_esp: 0B, motor_pos_flag_spare: 0B, $
  rkt_spares: bytarr(16), $  
  checkbytes: 0L, SyncWord: 0.0 }

;
; Isolate each packet as being between the SYNC words (0xA5A5)
;
SpecIndex = 1
index = 1L
numlines = 0L
steplines = 20
ans = ' '

IF inputType EQ 'file' THEN inputSize = finfo.size ELSE inputSize = size(input, /N_ELEMENTS)
while (index lt (inputSize-1)) do begin
  if (data[index-1] eq SYNC_BYTE1) and (data[index] eq SYNC_BYTE2) then begin
    ; first search for next Sync word
    index2 = index + 2
    while (index2 lt inputSize) do begin
      if ((data[index2-1] ne SYNC_BYTE1) or (data[index2] ne SYNC_BYTE2)) then index2 += 1 $
      else break   ;  stop as found next Sync Word
    endwhile
    if (index2 ge inputSize) then index2 = inputSize-1

    ;  extract out CCSDS packet header information
    ;  this assumes ID is only 8-bits (instead of full 11-bits)
    ;  this assumes Length has been reduced already by Radio to be less than 256 bytes
    ;  A radio CDI header can exist with this search (CDI header is ignored though)
    index3 = index + 1
    pindex = -1L
    pindex_end = index2
    packet_ID = 0     ; APID unique identifier for each packet type
    packet_seq_count = 0  ; 14-bit counter for each packet type
    packet_length = 0   ; 16-bit data length - 1
    packet_time = 0.0D0
    ;indexLast = index3 + 24  ; maximum header length with CDI and CCSDS headers
    indexLast = index3 + 14  ; JPM 2014/10/08: If there is no CDI header, maximum header length with CCSDS headers.
                ; 2014/10/17: ISIS now strips all CDI headers, so reduce offset by 10 bytes.
    if (indexLast gt (index2-8)) then indexLast = index2-8
    while (index3 lt indexLast) do begin
      if ((data[index3] eq CCSDS_BYTE1) and (data[index3+4] eq CCSDS_BYTE5)) then begin
        pindex = index3
        packet_ID_full = uint(data[pindex+1])
        packet_ID = uint(data[pindex+1]) AND '3f'X ;Added 'AND '3f'X' for playback data on (10/14/2014)
        packet_seq_count = uint(data[pindex+2] AND '3F'X) * 256 + uint(data[pindex+3])
        packet_length = uint(data[pindex+4])*256L + uint(data[pindex+5]) + 1L
        packet_time1 = ulong(data[pindex+6]) + ishft(ulong(data[pindex+7]),8) + $
          ishft(ulong(data[pindex+8]),16) + ishft(ulong(data[pindex+9]),24)
        packet_time2 = uint(data[pindex+10]) + ishft(uint(data[pindex+11]),8)
        packet_time = double(packet_time1) + packet_time2 / 1000.D0
        break
      endif
      index3 += 1
    endwhile

    ;
    ;  parse packet data based on packet_id value
    ;
    ; NOTE that only LOG packet is fully parsed
    ; The housekeeping (HK) packet is partially parsed
    ;
    if (packet_id eq PACKET_ID_HK) then begin
      ;
      ;  ************************
      ;  HOUSEKEEPING (HK) Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(hk) then begin
        hk_struct1.apid = packet_id_full  ; keep Playback bit in structure
        hk_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        hk_struct1.seq_count = packet_seq_count
        hk_struct1.data_length = packet_length
        hk_struct1.time = packet_time   ; millisec (0.1 msec resolution)

        hk_struct1.cdh_info = (long(data[pindex+12])) ;None
        hk_struct1.cdh_state = ISHFT(hk_struct1.cdh_info AND 'F0'X, -4) ;extract the state from the MSN, returns one number
        hk_struct1.spacecraft_mode = ISHFT(hk_struct1.cdh_info AND '07'X, 0) ;extract the spacecraft mode from last three bits in the LSN, returns one number
        hk_struct1.eclipse_state = ISHFT(hk_struct1.cdh_info AND '08'X, -3) ;extract the eclipse state from the first bit in the LSN, BOOLEAN, either on(1) or off(0)

        hk_struct1.adcs_info = (long(data[pindex+13])) ;None
        hk_struct1.adcs_state = ISHFT(hk_struct1.adcs_info AND 'E0'X, -5) ; extract 3-bit State value
        hk_struct1.adcs_attitude_valid = ISHFT(hk_struct1.adcs_info AND '10'X, -4) ; extract 1-bit flag
        hk_struct1.adcs_refs_valid = ISHFT(hk_struct1.adcs_info AND '08'X, -3) ; extract 1-bit flag
        hk_struct1.adcs_time_valid = ISHFT(hk_struct1.adcs_info AND '04'X, -2) ; extract 1-bit flag
        hk_struct1.adcs_recommend_sun = ISHFT(hk_struct1.adcs_info AND '02'X, -1) ; extract 1-bit flag
        hk_struct1.adcs_mode = ISHFT(hk_struct1.adcs_info AND '01'X, 0) ; extract 1-bit flag
          
        hk_struct1.checkbytes = long(data[pindex+250]) + ishft(long(data[pindex+251]),8)
        hk_struct1.SyncWord = (long(data[pindex+252]) + ishft(long(data[pindex+253]),8))  ;none

        hk_struct1.cmd_last_opcode = (long(data[pindex+14]))   ; none
        hk_struct1.cmd_last_status = (long(data[pindex+15]))   ; none
        hk_struct1.cmd_accept_count =  long(data[pindex+16]) + ishft(long(data[pindex+17]),8) ; none
        hk_struct1.cmd_reject_count =  long(data[pindex+18]) + ishft(long(data[pindex+19]),8) ; none

        hk_struct1.sd_hk_write_offset = (long(data[pindex+20]) + ishft(long(data[pindex+21]),8) $
          + ishft(long(data[pindex+22]),16))  ; none
        hk_struct1.sd_hk_routing = (long(data[pindex+23]))   ; none
        hk_struct1.sd_log_write_offset = (long(data[pindex+24]) + ishft(long(data[pindex+25]),8) $
          + ishft(long(data[pindex+26]),16))  ; none
        hk_struct1.sd_log_routing = (long(data[pindex+27]))   ; none
        hk_struct1.sd_diag_write_offset = (long(data[pindex+28]) + ishft(long(data[pindex+29]),8) $
          + ishft(long(data[pindex+30]),16))
        hk_struct1.sd_diag_routing = (long(data[pindex+31]))
        hk_struct1.sd_adcs_write_offset = (long(data[pindex+32]) + ishft(long(data[pindex+33]),8) $
          + ishft(long(data[pindex+34]),16))  ; none
        hk_struct1.sd_adcs_routing = (long(data[pindex+35]))  ; none
        hk_struct1.sd_ximg_write_offset = (long(data[pindex+36]) + ishft(long(data[pindex+37]),8) $
          + ishft(long(data[pindex+38]),16))  ; none
        hk_struct1.sd_ximg_routing = (long(data[pindex+39]))  ; none
        hk_struct1.sd_sci_write_offset = (long(data[pindex+40]) + ishft(long(data[pindex+41]),8) $
          + ishft(long(data[pindex+42]),16))  ; none
        hk_struct1.sd_sci_routing = (long(data[pindex+43]))  ; none

        hk_struct1.sd_hk_read_offset = (long(data[pindex+44]) + ishft(long(data[pindex+45]),8) $
          + ishft(long(data[pindex+46]),16))  ; none
        hk_struct1.fsw_major_minor = (long(data[pindex+47]))
        hk_struct1.sd_log_read_offset = (long(data[pindex+48]) + ishft(long(data[pindex+49]),8) $
          + ishft(long(data[pindex+50]),16))  ; none
        hk_struct1.fsw_patch_version = (long(data[pindex+51]))

        ;  2015/9/7: TW  Extract out extra flags from "fsw_patch_version"
        hk_struct1.flight_model = ishft( hk_struct1.fsw_patch_version AND '0030'X, -4 )
        hk_struct1.adcs_gain_detuned = ishft( hk_struct1.fsw_patch_version AND '0040'X, -6 )
        hk_struct1.adcs_using_sps = ishft( hk_struct1.fsw_patch_version AND '0080'X, -7 )
        hk_struct1.fsw_patch_version = hk_struct1.fsw_patch_version AND '000F'X

        hk_struct1.sd_diag_read_offset = (long(data[pindex+52]) + ishft(long(data[pindex+53]),8) $
          + ishft(long(data[pindex+54]),16))  ; none
        hk_struct1.ParamSetHdrByte1 = (long(data[pindex+55]))  ; none
        hk_struct1.sd_ADCS_read_offset = (long(data[pindex+56]) + ishft(long(data[pindex+57]),8) $
          + ishft(long(data[pindex+58]),16))  ; none
        hk_struct1.ParamSetHdrByte2 = (long(data[pindex+59]))  ; none
        hk_struct1.sd_ximg_read_offset = (long(data[pindex+60]) + ishft(long(data[pindex+61]),8) $
          + ishft(long(data[pindex+62]),16))
        hk_struct1.sd_writectrlblockaddr = (long(data[pindex+63]))  ; 1 - 255 valid range
        hk_struct1.sd_sci_read_offset = (long(data[pindex+64]) + ishft(long(data[pindex+65]),8) $
          + ishft(long(data[pindex+66]),16))
        hk_struct1.sd_ephemerisblockaddr = (long(data[pindex+67]))  ; none

        hk_struct1.lockout_timeoutcounter = (long(data[pindex+68]) + ishft(long(data[pindex+69]),8)) ; seconds
        hk_struct1.contactTx_timeoutcounter = (long(data[pindex+70]) + ishft(long(data[pindex+71]),8)) ; Seconds
        hk_struct1.time_offset = (long(data[pindex+72]) + ishft(long(data[pindex+73]),8) $
          + ishft(long(data[pindex+74]),16) + ishft(long(data[pindex+75]),24))  ; milliseconds

        hk_struct1.Battery_HeaterSetpoint = (long(data[pindex+76])) ; -128 to 127 C (singed byte)
        hk_struct1.Instrument_HeaterSetpoint = (long(data[pindex+77])) ;  -128 to 127 C (singed byte)

        hk_struct1.cdh_batt_v = (long(data[pindex+78]) + ishft(long(data[pindex+79]),8)) *67.1/4096.  ;Volts
        hk_struct1.cdh_batt_v2 = (long(data[pindex+80]) + ishft(long(data[pindex+81]),8)) *33.55/4096.  ;Volts
        hk_struct1.cdh_5v = (long(data[pindex+82]) + ishft(long(data[pindex+83]),8)) *6.71/4096.  ;Volts
        hk_struct1.cdh_3v = (long(data[pindex+84]) + ishft(long(data[pindex+85]),8)) *6.71/4096.  ;Volts
        hk_struct1.cdh_temp = ((FIX(data[pindex+86])) + ishft(FIX(data[pindex+87]),8)) /256.  ;deg C
        hk_struct1.cdh_enables = (long(data[pindex+88]) + ishft(long(data[pindex+89]),8))  ; none
        hk_struct1.enable_comm = ISHFT(hk_struct1.cdh_enables AND '0001'X, 0) ;extract the power state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_adcs = ISHFT(hk_struct1.cdh_enables AND '0002'X, -1) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_sps_xps = ISHFT(hk_struct1.cdh_enables AND '0004'X, -2) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_x123 = ISHFT(hk_struct1.cdh_enables AND '0008'X, -3) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_batt_heater = ISHFT(hk_struct1.cdh_enables AND '0010'X, -4) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_ant_deploy = ISHFT(hk_struct1.cdh_enables AND '0020'X, -5) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_sa_deploy = ISHFT(hk_struct1.cdh_enables AND '0040'X, -6) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_inst_heater = ISHFT(hk_struct1.cdh_enables AND '0080'X, -7) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_spare = ISHFT(hk_struct1.cdh_enables AND '0100'X, -8) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_comm_ext = ISHFT(hk_struct1.cdh_enables AND '0200'X, -9) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        
        
        hk_struct1.cdh_i2c_err = (long(data[pindex+90]) + ishft(long(data[pindex+91]),8))  ;none
        hk_struct1.cdh_rtc_err = (long(data[pindex+92]) + ishft(long(data[pindex+93]),8))  ;none
        hk_struct1.cdh_spi_sd_err = (long(data[pindex+94]) + ishft(long(data[pindex+95]),8))   ;none

        hk_struct1.cdh_uart1_err = (long(data[pindex+96]) + ishft(long(data[pindex+97]),8))  ;none
        hk_struct1.cdh_uart2_err = (long(data[pindex+98]) + ishft(long(data[pindex+99]),8))  ;none
        hk_struct1.cdh_uart3_err = (long(data[pindex+100]) + ishft(long(data[pindex+101]),8))  ;none
        hk_struct1.cdh_uart4_err = (long(data[pindex+102]) + ishft(long(data[pindex+103]),8))  ;none

        hk_struct1.Radio_Counter = (long(data[pindex+104]) + ishft(long(data[pindex+105]),8))  ;none
        hk_struct1.Radio_Temp = (long(data[pindex+106]) + ishft(long(data[pindex+107]),8))  ;deg C
        hk_struct1.Radio_Time = (long(data[pindex+108]) + ishft(long(data[pindex+109]),8) $
          + ishft(long(data[pindex+110]),16)) ; TBD
        hk_struct1.radio_rssi = (long(data[pindex+111]))  ;TBD
        hk_struct1.radio_received = (long(data[pindex+112]) + ishft(long(data[pindex+113]),8) $
          + ishft(long(data[pindex+114]),16) + ishft(long(data[pindex+115]),24))  ; bytes
        hk_struct1.radio_transmitted = (long(data[pindex+116]) + ishft(long(data[pindex+117]),8) $
          + ishft(long(data[pindex+118]),16) + ishft(long(data[pindex+119]),24))  ; bytes

        hk_struct1.COMM_last_Cmd = (long(data[pindex+120])) ;none range: (1 - 32)
        hk_struct1.COMM_last_Status = (long(data[pindex+121])) ;none

        hk_struct1.comm_temp = (FIX(data[pindex+122]) + ishft(FIX(data[pindex+123]),8))/256.0  ;deg C
        hk_struct1.mb_temp1 = (FIX(data[pindex+124]) + ishft(FIX(data[pindex+125]),8))/256.0  ;deg C
        hk_struct1.mb_temp2 = (FIX(data[pindex+126]) + ishft(FIX(data[pindex+127]),8))/256.0  ;deg C

        hk_struct1.eps_temp1 = (FIX(data[pindex+128]) + ishft(FIX(data[pindex+129]),8)) / 256.0 ; deg C
        hk_struct1.eps_temp2 = (FIX(data[pindex+130]) + ishft(FIX(data[pindex+131]),8)) / 256.0 ; deg C
        hk_struct1.eps_fg_volt = (long(data[pindex+132]) + ishft(long(data[pindex+133]),8)) / 6415.0 ; Volts
        hk_struct1.eps_fg_soc = (long(data[pindex+134]) + ishft(long(data[pindex+135]),8)) / 256.0 ; % SOC

        hk_struct1.eps_sa1_cur = (long(data[pindex+136]) + ishft(long(data[pindex+137]),8)) * 163.8 / 327.68 ; milliAmp
        hk_struct1.eps_sa1_volt = (long(data[pindex+138]) + ishft(long(data[pindex+139]),8)) * 32.76 / 32768.0 ; Volts
        hk_struct1.eps_sa2_cur = (long(data[pindex+140]) + ishft(long(data[pindex+141]),8)) * 163.8 / 327.68 ; milliAmp
        hk_struct1.eps_sa2_volt = (long(data[pindex+142]) + ishft(long(data[pindex+143]),8)) * 32.76 / 32768.0 ; Volts
        hk_struct1.eps_sa3_cur = (long(data[pindex+144]) + ishft(long(data[pindex+145]),8)) * 163.8 / 327.68 ; milliAmp
        hk_struct1.eps_sa3_volt = (long(data[pindex+146]) + ishft(long(data[pindex+147]),8)) * 32.76 / 32768.0 ; Volts

        hk_struct1.eps_batt_cur = (long(data[pindex+148]) + ishft(long(data[pindex+149]),8)) * 163.8 / 1638.4 ; milliAmp
        hk_struct1.eps_batt_volt = (long(data[pindex+150]) + ishft(long(data[pindex+151]),8)) * 32.76 / 32768.0 ; Volts
        hk_struct1.eps_3v_cur = (long(data[pindex+152]) + ishft(long(data[pindex+153]),8)) * 163.8 / 327.68 ; milliAmp
        hk_struct1.eps_3v_volt = (long(data[pindex+154]) + ishft(long(data[pindex+155]),8)) * 32.76 / 32768.0 ; Volts
        hk_struct1.eps_5v_cur = (long(data[pindex+156]) + ishft(long(data[pindex+157]),8)) * 163.8 / 327.68 ; milliAmp
        hk_struct1.eps_5v_volt = (long(data[pindex+158]) + ishft(long(data[pindex+159]),8)) * 32.76 / 32768.0 ; Volts

        hk_struct1.eps_sa1_temp = (long(data[pindex+160]) + ishft(long(data[pindex+161]),8)) * 0.1744 - 216. ; = deg C
        hk_struct1.eps_sa2_temp = (long(data[pindex+162]) + ishft(long(data[pindex+163]),8)) * 0.1744 - 216. ; = deg C
        hk_struct1.eps_sa3_temp = (long(data[pindex+164]) + ishft(long(data[pindex+165]),8)) * 0.1744 - 216. ; = deg C

        hk_struct1.eps_batt_volt2 = (long(data[pindex+166]) + ishft(long(data[pindex+167]),8)) * 14.1 / 4096. ; Volts
        hk_struct1.eps_batt_charge = (long(data[pindex+168]) + ishft(long(data[pindex+169]),8)) * 3.5568 - 61.6 ; milliAmp
        hk_struct1.eps_batt_temp1 = (long(data[pindex+170]) + ishft(long(data[pindex+171]),8)) * 0.18766 - 250.2 ; deg C
        hk_struct1.eps_batt_discharge = (long(data[pindex+172]) + ishft(long(data[pindex+173]),8)) * 3.5568 - 61.6 ; milliAmp
        hk_struct1.eps_batt_temp2 = (long(data[pindex+174]) + ishft(long(data[pindex+175]),8)) * 0.18766 - 250.2 ; deg C

        hk_struct1.sps_xps_pwr_3v = (long(data[pindex+176]) + ishft(long(data[pindex+177]),8)) * 7.0 / 1024. ; Volts
        ;; is the two's compliment formulation correct for this variable ??
        hk_struct1.sps_xps_pwr_temp = ((ISHFT(FIX(data[pindex+178]), 6)) + ishft(FIX(data[pindex+179]),14)) / 256. ; deg C (signed)
        ;Because the value can be positive or negative we have to calculate the two's compliment
        ;          IF sci_struct1.sps_xps_pwr_temp GE (2L^(7)) THEN sci_struct1.sps_xps_pwr_temp -=  (2L^(8))
        ;;
        hk_struct1.sps_xps_pwr_d5v = (long(data[pindex+180]) + ishft(long(data[pindex+181]),8)) * 8.79 / 1024. ; Volts
        hk_struct1.sps_xps_pwr_a5v = (long(data[pindex+182]) + ishft(long(data[pindex+183]),8)) * 8.79 / 1024. ; Volts
        hk_struct1.sps_xps_temp = (long(data[pindex+184]) + ishft(long(data[pindex+185]),8)) * 0.8064 - 250.0
        hk_struct1.xps_xps_temp = (long(data[pindex+186]) + ishft(long(data[pindex+187]),8)) * 0.8064 - 250.0

        hk_struct1.sps_xps_dac1 = (long(data[pindex+188]) + ishft(long(data[pindex+189]),8)) * 2.28 / 4096.  ; Volts

        hk_struct1.x123_brd_temp = (long(data[pindex+190]))    ; deg C (signed)
        ;Because the value can be positive or negative we have to calculate the two's compliment
        if hk_struct1.x123_brd_temp GE (2L^(7)) then hk_struct1.x123_brd_temp -=  (2L^(8))

        hk_struct1.XACT_CommandRejectStatus = (long(data[pindex+191])) ;
        hk_struct1.xps_data = (long(data[pindex+192]) + ishft(long(data[pindex+193]),8) $
          + ishft(long(data[pindex+194]),16) + ishft(long(data[pindex+195]),24))  ; Data numbers
        hk_struct1.dark_data = (long(data[pindex+196]) + ishft(long(data[pindex+197]),8) $
          + ishft(long(data[pindex+198]),16) + ishft(long(data[pindex+199]),24))  ; Data numbers
        hk_struct1.sps_sum = (long(data[pindex+200]) + ishft(long(data[pindex+201]),8) $
          + ishft(long(data[pindex+202]),16) + ishft(long(data[pindex+203]),24))  ; 1.0e-3 fA
        hk_struct1.sps_x = (fix(data[pindex+204]) + ishft(fix(data[pindex+205]),8))   ; range from -10000 to 10000
        hk_struct1.sps_y = (fix(data[pindex+206]) + ishft(fix(data[pindex+207]),8))   ; range from -10000 to 1000

        hk_struct1.X123_Fast_Count = (long(data[pindex+208]) + ishft(long(data[pindex+209]),8))  ; Data numbers, counts

        hk_struct1.X123_Slow_Count = (long(data[pindex+210]) + ishft(long(data[pindex+211]),8))  ; Data numbers, counts
        hk_struct1.X123_Det_Temp = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8)) * 0.1 ; Kelvin

        ; 2016/05/03: James Paul Mason: NOTE: The XACT telemetry points from MinXSS have been replaced with GOES/XRS data for the EVE sounding rocket
        ;Add XACT monitors to HK for the TLM Rev D.25 changes
;        hk_struct1.XACT_P5VTrackerVoltage = (uint(data[pindex+214])) * 0.025  ; DN * 0.025 = V
;        hk_struct1.XACT_P12VBusVoltage = (uint(data[pindex+215])) * 0.256 ; DN * 0.256 = V
;        hk_struct1.XACT_TrackerDetectorTemp = (FIX(data[pindex+216])) * 0.8 ; DN * 0.8 = C deg.
;        hk_struct1.XACT_Wheel2Temp = (FIX(data[pindex+217])) * 1.28 ;  DN * 1.28 = C deg.
;        hk_struct1.XACT_MeasSunBodyVectorX = (fix(data[pindex+218])) * 0.0256
;        hk_struct1.XACT_MeasSunBodyVectorY = (fix(data[pindex+219])) * 0.0256
;        hk_struct1.XACT_MeasSunBodyVectorZ = (fix(data[pindex+220])) * 0.0256
;
;        hk_struct1.XACT_CommandStatus = data[pindex+221] ; 0 - 255
;        hk_struct1.XACT_CommandAcceptCount = data[pindex+222] ; 0 - 255
;        hk_struct1.XACT_CommandAcceptAPID = data[pindex+223] ; 0 - 255
;        hk_struct1.XACT_CommandAcceptOpCode = data[pindex+224] ; 0 - 255
;
;        hk_struct1.XACT_CommandRejectCount = data[pindex+225] ; 0 - 255
;        hk_struct1.XACT_CommandRejectAPID = data[pindex+226] ; 0 - 255
;        hk_struct1.XACT_CommandRejectOpCode = data[pindex+227] ; 0 - 255
;
;        ; DN * 0.01 = rad/s/s
;        hk_struct1.XACT_Wheel1EstDrag = (fix(data[pindex+228]) + ishft(fix(data[pindex+229]),8)) * 0.01
;        hk_struct1.XACT_Wheel2EstDrag = (fix(data[pindex+230]) + ishft(fix(data[pindex+231]),8)) * 0.01
;        hk_struct1.XACT_Wheel3EstDrag = (fix(data[pindex+232]) + ishft(fix(data[pindex+233]),8)) * 0.01
;
;        ; DN * 0.025 = rad/sec based on version Rev 9.02 -FINAL-
;        hk_struct1.XACT_Wheel1MeasSpeed = (fix(data[pindex+234]) + ishft(fix(data[pindex+235]),8)) * 0.025
;        hk_struct1.XACT_Wheel2MeasSpeed = (fix(data[pindex+236]) + ishft(fix(data[pindex+237]),8)) * 0.025
;        hk_struct1.XACT_Wheel3MeasSpeed = (fix(data[pindex+238]) + ishft(fix(data[pindex+239]),8)) * 0.025
;
;        ; DN * 0.00016384 = rad/sec based on version Rev 9.02 -FINAL-
;        hk_struct1.XACT_BodyFrameRateX = (fix(data[pindex+240]) + ishft(fix(data[pindex+241]),8)) * 0.00016384
;        hk_struct1.XACT_BodyFrameRateY = (fix(data[pindex+242]) + ishft(fix(data[pindex+243]),8)) * 0.00016384
;        hk_struct1.XACT_BodyFrameRateZ = (fix(data[pindex+244]) + ishft(fix(data[pindex+245]),8)) * 0.00016384
;
;        ; bits 0,1 - Boot Relay Status, bits 2 - Watchdog Enable, bit 3 - Watchdog Event
;        hk_struct1.XACT_LVL0_Bitflags = data[pindex+246]
;        hk_struct1.XACT_LVL0_Counter = data[pindex+247] ;
;        hk_struct1.XACT_LVL0_CmdRejectCount = data[pindex+248] ;
;        hk_struct1.XACT_LVL0_CmdAcceptCount = data[pindex+249] ;

        hk_struct1.xps_data2 = (long(data[pindex+214]) + ishft(long(data[pindex+215]),8) $
                                + ishft(long(data[pindex+216]),16) + ishft(long(data[pindex+217]),24))  ; Data numbers
        hk_struct1.dark_data2 = (long(data[pindex+218]) + ishft(long(data[pindex+219]),8) $
                                + ishft(long(data[pindex+220]),16) + ishft(long(data[pindex+221]),24))  ; Data numbers
        hk_struct1.sps_sum2 = (long(data[pindex+222]) + ishft(long(data[pindex+223]),8) $
                                + ishft(long(data[pindex+224]),16) + ishft(long(data[pindex+225]),24))  ; 1.0e-3 fA
        hk_struct1.sps_x2 = (fix(data[pindex+226]) + ishft(fix(data[pindex+227]),8))   ; range from -10000 to 10000
        hk_struct1.sps_y2 = (fix(data[pindex+228]) + ishft(fix(data[pindex+229]),8))   ; range from -10000 to 1000
        hk_struct1.motor_pos_flag_xrs_a = (long(data[pindex+230])) ;None
        hk_struct1.motor_pos_flag_xrs_b = (long(data[pindex+231])) ;None
        hk_struct1.motor_pos_flag_esp = (long(data[pindex+232])) ;None
        hk_struct1.motor_pos_flag_spare = (long(data[pindex+233])) ;None

        hk_struct1.checkbytes = uint(data[pindex+250]) + ishft(uint(data[pindex+251]),8)
        hk_struct1.SyncWord = (uint(data[pindex+252]) + ishft(uint(data[pindex+253]),8))  ;none

        if (hk_count eq 0) then hk = replicate(hk_struct1, N_CHUNKS) else $
          if hk_count ge n_elements(hk) then hk = [hk, replicate(hk_struct1, N_CHUNKS)]
        ;hk[hk_count] = hk_struct1
        hk = hk_struct1 ; 2018-03-26: JPM: Modifying for operation real time.. just return the structure
        hk_count += 1
        BREAK ; 2018-03-26: JPM: ditto
      endif
    endif else begin
      ;  increment index and keep looking for Sync word
      print, 'index: ' + strtrim(index, 2)
      index++
    endelse
  endif
endwhile

; Eliminate excess length in packets
if arg_present(hk) and n_elements(hk) ne 0 then hk = hk[0:hk_count-1]

if keyword_set(verbose) then begin
  if (hk_count gt 0) then  print, 'Number of HK   Packets = ', hk_count
endif

return    ; end of reading packets

exit_read:
; Exit Point on File Open or Read Error
if keyword_set(verbose) then print, 'ERROR reading file: ', input
if (fileOpened ne 0) then begin
  close, lun
  free_lun, lun
endif
on_ioerror, NULL

return
end