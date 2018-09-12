;+
; NAME:
;   minxss2_read_packets
;
; PURPOSE:
;   Read, interpret, and store in IDL structures the packets from binary file from MinXSS CubeSat.
;   These can come from either ISIS or DataView.
; 
;   Same as minxss_read_packets but this version is used for MinXSS-2 which has slightly different packet definitions.
;   Changes for FM-2 packets (Aug 2016)
;   hk.adcs_high_rate_run_count --> hk.sd_ephemeris_block_addr
;   hk.cdh_enables has new bit flag = enable_eclipse_use_css (0x0400 bit location)
;   sci Rd and Wr errors and radio_active changed to include 24-bit SD_sci_write_offset  
;   adcs4 has 5 new variables:  sd_adcs_write_offset (long), cruciform_scan_index (int), cruciform_scan_x_steps (int), 
;                               cruciform_scan_y_steps (int), cruciform_scan_dwell_period (int)
;
; INPUTS:
;   input [string]: Name of file to read (string) or a bytarr containing packet(s)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   HEXDUMP:             Option to print packets as hexadecimal sequence (useful for debugging)
;   VERBOSE:             Option to print number of packets found
;   EXPORT_RAW_ADCS_TLM: Option to export the ISIS telemetry file to a dedicated folder for BCT (minxss_data/fm*/xact_exported_data)
;   KISS:                Option to deal with KISS-formatted input
;
; OUTPUTS:
;   hk [structure]:        Return array of housekeeping (monitors, status) packets
;   sci [structure]:       Return array of science (X123, SPS, XPS data) packets
;                          **OR** -1 if science packet incomplete (for single-packet reader mode)
;   adcs [structure]:      Return array of ADCS (BCT XACT data) packets
;   log [structure];       Return array of log messages
;   diag [structure]:      Return array of Diagnostic (single monitor at 1000 Hz) packets
;   xactimage [structure]: Return array of XACT Star Tracker image packets
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS processing suite.
;+
pro minxss2_read_packets, input, hk=hk, sci=sci, log=log, diag=diag, xactimage=xactimage, $
                          adcs1=adcs1, adcs2=adcs2, adcs3=adcs3, adcs4=adcs4, fm=fm, _extra=_extra, $
                          HEXDUMP=HEXDUMP, EXPORT_RAW_ADCS_TLM = EXPORT_RAW_ADCS_TLM, VERBOSE=VERBOSE, KISS=KISS

; Clear any values present in the output variables, needed since otherwise the input values get returned when these packet types are missing from the input file
junk = temporary(hk)
junk = temporary(sci)
junk = temporary(log)
junk = temporary(diag)
junk = temporary(xactimage)
junk = temporary(adcs1)
junk = temporary(adcs2)
junk = temporary(adcs3)
junk = temporary(adcs4)

; Define initial quantum of packet array length
N_CHUNKS = 500

if (n_params() lt 1) then begin
  print, 'USAGE: minxss_read_packets, input_file, hk=hk, sci=sci, log=log, diag=diag, $'
  print, '              xactimage=xactimage, adcs1=adcs1, adcs2=adcs2, adcs3=adcs3, adcs4=adcs4, fm=fm, $'
  print, '              /hexdump, /verbose, /kiss'
  input=' '
endif
IF size(input[0], /TYPE) EQ 7 THEN if (strlen(input) lt 2) then begin
  ; find file to read
  input = dialog_pickfile(/read, title='Select MinXSS dump file to read', filter='MinXSS_*')
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
    IF ((strpos(input, '.kss', /reverse_search) NE -1) OR (strpos(input, '.kiss', /reverse_search) NE -1)) THEN BEGIN
      kiss = 1
      message, /info, "WARNING: .k[i]ss extension detected -- forcing KISS compatibility!"
    ENDIF
  endif else goto, exit_read
ENDIF ELSE BEGIN
  inputType = 'bytarr'
  data = input ; input provided was a file name else input was already bytarr
ENDELSE

IF keyword_set(kiss) THEN BEGIN
  IF keyword_set(verbose) THEN message, /info, "Converting KISS escape sequences..."
  data = minxss_unkiss(temporary(data), verbose=verbose)
ENDIF

; If "ham" shows up in the input filepath/name, then set the HAM_HEADER keyword
IF isA(input, 'string') THEN BEGIN
  IF strmatch(input, '*ham*') THEN BEGIN
    HAM_HEADER = 1
  ENDIF
ENDIF

SYNC_BYTE1 = byte('A5'X)
SYNC_BYTE2 = byte('A5'X)

; Add these sync bytes to the beginning since flight software adds them to the end of packets
; This is a kludge so the code below won't skip the first packet...
IF ~(data[0] EQ SYNC_BYTE1 AND data[1] EQ SYNC_BYTE2) THEN data = [SYNC_BYTE1, SYNC_BYTE2, data]

CCSDS_BYTE1 = byte('08'X)
CCSDS_BYTE5 = byte('00'X)

PACKET_ID_HK = 25
PACKET_ID_LOG = 29
PACKET_ID_DIAG = 35
PACKET_ID_IMAGE = 42
PACKET_ID_SPS = 43
PACKET_ID_SCI = 44

PACKET_ID_ADCS1 = 38
PACKET_ID_ADCS2 = 39
PACKET_ID_ADCS3 = 40
PACKET_ID_ADCS4 = 41

PACKET_ID_HK_PLAYBACK = PACKET_ID_HK + '40'X
PACKET_ID_LOG_PLAYBACK = PACKET_ID_LOG + '40'X
PACKET_ID_DIAG_PLAYBACK = PACKET_ID_DIAG + '40'X
PACKET_ID_IMAGE_PLAYBACK = PACKET_ID_IMAGE + '40'X
PACKET_ID_SPS_PLAYBACK = PACKET_ID_SPS + '40'X
PACKET_ID_SCI_PLAYBACK = PACKET_ID_SCI + '40'X
PACKET_ID_ADCS1_PLAYBACK = PACKET_ID_ADCS1 + '40'X
PACKET_ID_ADCS2_PLAYBACK = PACKET_ID_ADCS2 + '40'X
PACKET_ID_ADCS3_PLAYBACK = PACKET_ID_ADCS3 + '40'X
PACKET_ID_ADCS4_PLAYBACK = PACKET_ID_ADCS4 + '40'X

;  doPause allows interactive flow of printing for the Hex Dump option
if keyword_set(hexdump) then doPause = 1 else doPause = 0

;
;    HK Packet Structure definition  (only partially defined so can do quick check for battery cycle)
;       REMOVED for FM2:  adcs_HighRateRunCounter: 0, enable_spare: 0B,
;       ADDED for FM2:  sd_EphemerisBlockAdrr: 0, enable_eclipse_use_css: 0B,
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
  enable_ant_deploy: 0B, enable_sa_deploy: 0B, enable_inst_heater: 0B, enable_eclipse_use_css: 0B, enable_sdcard: 0B,  $
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
  XACT_P5VTrackerVoltage: 0.0, XACT_P12VBusVoltage: 0.0, XACT_TrackerDetectorTemp: 0.0, XACT_Wheel2Temp: 0.0,  $
  XACT_MeasSunBodyVectorX: 0.0, XACT_MeasSunBodyVectorY: 0.0, XACT_MeasSunBodyVectorZ: 0.0, $
  XACT_CommandStatus: 0B, XACT_CommandAcceptCount: 0B, XACT_CommandAcceptAPID: 0B, XACT_CommandAcceptOpCode: 0B, $
  XACT_CommandRejectCount: 0B, XACT_CommandRejectAPID: 0B, XACT_CommandRejectOpCode: 0B, XACT_Wheel1EstDrag: 0.0,  $
  XACT_Wheel2EstDrag: 0.0, XACT_Wheel3EstDrag: 0.0,  $
  XACT_Wheel1MeasSpeed: 0.0, XACT_Wheel2MeasSpeed: 0.0, XACT_Wheel3MeasSpeed: 0.0,  $
  XACT_BodyFrameRateX: 0.0,  XACT_BodyFrameRateY: 0.0, XACT_BodyFrameRateZ: 0.0,  $
  XACT_LVL0_Bitflags: 0B, XACT_LVL0_Counter: 0B, XACT_LVL0_CmdRejectCount: 0B,  $
  XACT_LVL0_CmdAcceptCount: 0B, $
  checkbytes: 0L, SyncWord: 0.0, $
  checkbytes_calculated: 0L, checkbytes_valid: 1B}

;
; Log Message (LOG) Packet Structure definition
;
log_count = 0L
log_struct1 = { apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0, $
  checkbytes: 0L, SyncWord: 0.0, $
  message: ' ' }

;
; Sci message (SCI) Packet Structure definition
;   ADDED for FM2:  sd_sci_write_offset: 0L, 
;
X123_SPECTRUM_BINS = 1024L
X123_SPECTRUM_LENGTH = X123_SPECTRUM_BINS*3L
X123_FIRST_LENGTH = 168L
X123_OTHER_LENGTH = 234L
X123_HEADER_LENGTH = 256L
X123_DATA_MAX = X123_SPECTRUM_LENGTH + X123_HEADER_LENGTH
sci_count = 0L
sci_struct1 = { apid: 0.0, seq_flag: 0B, seq_count: 0.0, data_length: 0L, time: 0.0D0,  $
  cdh_info: 0, $
  cdh_state: 0B, spacecraft_mode: 0B, eclipse_state: 0B, $
  adcs_info: 0, $
  adcs_state: 0B, adcs_attitude_valid: 0B, adcs_refs_valid: 0B, adcs_time_valid: 0B, $
  adcs_recommend_sun: 0B, adcs_mode: 0B, $
  xps_data: 0.0D0, dark_data: 0.0D0, sps_data: dblarr(4), $
  sps_xp_integration_time: 0.0D0, x123_fast_count: 0.0D0, $
  x123_slow_count: 0.0D0, x123_gp_count: 0.0D0, x123_accum_time: 0.0D0, x123_live_time: 0.0D0, $
  x123_real_time: 0.0D0, x123_hv: 0.0, x123_det_temp: 0.0, x123_brd_temp: 0.0, x123_flags: 0L, $
  x123_read_errors: 0, x123_radio_flag: 0,  x123_write_errors: 0, sd_sci_write_offset: 0L, $
  x123_cmp_info: 0L, x123_spect_len: 0, $
  x123_group_count: 0, x123_spectrum: lonarr(X123_SPECTRUM_BINS), $
  checkbytes: 0L, SyncWord: 0.0, $
  checkbytes_calculated: 0L, checkbytes_valid: 1B}

sciPacketIncomplete = 0
sci_lastSeqCount = 0
sci_PacketCounter = 0
sci_numPacketsExpected = -1

;
; EPS Diagnostic (DIAG) Packet Structure definition
;
diag_count = 0L
DIAG_DATA_LEN = 111
diag_struct1 =  {   apid: 0.0, seq_flag: 0.0, seq_count: 0.0, data_length: 0L, time: 0.0D0, $
  checkbytes: 0L, SyncWord: 0.0, cdh_info: 0, adcs_info: 0, monitor_index: 0.0, $
  min: 0.0, max: 0.0, sum: 0.0, peak_avg: 0.0, peak_num: 0.0, data: fltarr(DIAG_DATA_LEN) }


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Rev 31 + 32 Change ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

xactimage_count = 0L
xactimage_DATA_LEN = 128
xactimage_struct1 =  {  apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0,  $
  cdh_info: 0B, adcs_info: 0B, image_row: 0U, row_group: 0U, $
  image_data: bytarr(xactimage_DATA_LEN), checksum: 0U, SyncWord: 0U}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Rev 34 Change ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

adcs1_count = 0L
adcs1_DATA_LEN = 193
adcs1_struct1 =  {  apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0, $
  cdh_info: 0B, adcs_info: 0B, adcs_group: 0U, SpareByte: 0, checkbytes: 0U, SyncWord: 0U, $
  adcs_level: intarr(32), $
  command_status:0B, command_reject_status:0B, command_accept_count:0B, command_reject_count:0B, $
  last_accept_cmd_bytes1:0B, last_accept_cmd_bytes2:0B, last_accept_cmd_bytes3:0B, last_accept_cmd_bytes4:0B, $
  last_accept_cmd_bytes5:0B, last_accept_cmd_bytes6:0B, last_accept_cmd_bytes7:0B, last_accept_cmd_bytes8:0B, $
  last_reject_cmd_bytes1:0B, last_reject_cmd_bytes2:0B, last_reject_cmd_bytes3:0B, last_reject_cmd_bytes4:0B, $
  last_reject_cmd_bytes5:0B, last_reject_cmd_bytes6:0B, last_reject_cmd_bytes7:0B, last_reject_cmd_bytes8:0B, $
  tai_seconds:0UL, cycle_time:0UL, julian_date_tai:0UL, time_valid:0B, orbit_time:0UL, $
  q_ecef_wrt_eci1:0L, q_ecef_wrt_eci2:0L, q_ecef_wrt_eci3:0L, q_ecef_wrt_eci4:0L, $
  orbit_position_eci1:0L, orbit_position_eci2:0L, orbit_position_eci3:0L, $
  orbit_position_ecef1:0L, orbit_position_ecef2:0L, orbit_position_ecef3:0L, $
  orbit_velocity_eci1:0L,  orbit_velocity_eci2:0L,  orbit_velocity_eci3:0L, $
  orbit_velocity_ecef1:0L, orbit_velocity_ecef2:0L, orbit_velocity_ecef3:0L, $
  mag_model_vector_eci1:0.0, mag_model_vector_eci2:0.0, mag_model_vector_eci3:0.0, $
  mag_model_vector_body1:0.0, mag_model_vector_body2:0.0, mag_model_vector_body3:0.0, $
  sun_model_vector_eci1:0.0, sun_model_vector_eci2:0.0, sun_model_vector_eci3:0.0, $
  sun_model_vector_body1:0.0, sun_model_vector_body2:0.0, sun_model_vector_body3:0.0, $
  moon_model_vector_eci1:0.0, moon_model_vector_eci2:0.0, moon_model_vector_eci3:0.0, $
  moon_model_vector_body1:0.0, moon_model_vector_body2:0.0, moon_model_vector_body3:0.0, $
  atmospheric_density:0.0, refs_valid:0B, run_low_rate_task:0B, $
  attitude_quaternion1:0L, attitude_quaternion2:0L, attitude_quaternion3:0L, attitude_quaternion4:0L, $
  attitude_filter_residual1:0L}


adcs2_count = 0L
adcs2_DATA_LEN = 193
adcs2_struct1 =  {  apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0,  $
  cdh_info: 0B, adcs_info: 0B, adcs_group: 0U, SpareByte: 0, checkbytes: 0U, SyncWord: 0U, $
   attitude_filter_residual2: 0L, attitude_filter_residual3: 0L, $
  body_frame_rate1: 0L, body_frame_rate2: 0L, body_frame_rate3: 0L, $
  estimated_gyro_bias1: 0.0, estimated_gyro_bias2: 0.0, estimated_gyro_bias3: 0.0, $
  attitude_filter_algorithm: 0B, good_attitude_rate_timer: 0UL, bad_attitude_timer: 0UL, bad_rate_timer: 0UL, $
  attitude_filter_reint_count: 0UL, attitude_valid: 0B, measured_attitude_valid: 0B, measured_rate_valid: 0B, $
  commanded_attitude_quat1: 0L, commanded_attitude_quat2: 0L, commanded_attitude_quat3: 0L, commanded_attitude_quat4: 0L, $
  commanded_rate1: 0L, commanded_rate2: 0L, commanded_rate3: 0L, $
  commanded_accel1: 0L, commanded_accel2: 0L, commanded_accel3: 0L, $
  desired_sun_vector1: 0.0, desired_sun_vector2: 0.0, desired_sun_vector3: 0.0, $
  desired_sun_rot_rate: 0.0, adcs_mode: 0B, recommended_sun_point: 0B, $
  wheel_est_drag1: 0.0, wheel_est_drag2: 0.0, wheel_est_drag3: 0.0, $
  wheel_angle_residual1: 0.0, wheel_angle_residual2: 0.0, wheel_angle_residual3: 0.0, $
  wheel_meas_speed1: 0.0, wheel_meas_speed2: 0.0, wheel_meas_speed3: 0.0, $
  wheel_commanded_speed1: 0.0, wheel_commanded_speed2: 0.0, wheel_commanded_speed3: 0.0, $
  wheel_commanded_torque1: 0.0, wheel_commanded_torque2: 0.0, wheel_commanded_torque3: 0.0, $
  coarse_wheel_current1: 0.0, coarse_wheel_current2: 0.0, coarse_wheel_current3: 0.0, wheel_time_tag: 0UL, $
  wheel_pwm_counts1: 0UL, wheel_pwm_counts2: 0UL, wheel_pwm_counts3: 0UL, $
  wheel_pwm_commanded_counts1: 0UL, wheel_pwm_commanded_counts2: 0UL, wheel_pwm_commanded_counts3: 0UL, $
  wheel_tach_counts1: 0.0, wheel_tach_counts2: 0.0, wheel_tach_counts3: 0.0, $
  cal_cycle_timer1: 0.0, cal_cycle_timer2: 0.0, cal_cycle_timer3: 0.0, $
  wheel_operating_mode1: 0B, wheel_operating_mode2: 0B, wheel_operating_mode3: 0B, $
  wheel_control_mode1: 0B, wheel_control_mode2: 0B, wheel_control_mode3: 0B, $
  wheel_motor_fault1: 0B, wheel_motor_fault2: 0B, wheel_motor_fault3: 0B, $
  motor_hall_state1: 0B, motor_hall_state2: 0B, motor_hall_state3: 0B, $
  wheel_pwm_enable1: 0B, wheel_pwm_enable2: 0B, wheel_pwm_enable3: 0B, $
  wheel_pwm_direction1: 0B, wheel_pwm_direction2: 0B, wheel_pwm_direction3: 0B, $
  wheel_pwm_commanded_direction1: 0B, wheel_pwm_commanded_direction2: 0B, wheel_pwm_commanded_direction3: 0B $
  }

adcs3_count = 0L
adcs3_DATA_LEN = 193
adcs3_struct1 =  {  apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0,  $
  cdh_info: 0B, adcs_info: 0B, adcs_group: 0U, SpareByte: 0, checkbytes: 0U, SyncWord: 0U, $
  tracker_attitude1: 0L, tracker_attitude2: 0L, tracker_attitude3: 0L, tracker_attitude4: 0.0, $
  tracker_rate1: 0.0, tracker_rate2: 0.0, tracker_rate3: 0.0, $
  tracker_RA: 0.0, tracker_declination: 0.0, tracker_roll: 0.0, tracker_detector_temp: 8B, $
  tracker_covariance_amp: 0L, $
  tracker_covariance_matrix1: 0L, tracker_covariance_matrix2: 0L, tracker_covariance_matrix3: 0L, $
  tracker_covariance_matrix4: 0L, tracker_covariance_matrix5: 0L, tracker_covariance_matrix6: 0L, $
  tracker_covariance_matrix7: 0L, tracker_covariance_matrix8: 0L, tracker_covariance_matrix9: 0L, $
  tracker_max_residual: 0B, tracker_max_residual_first_pass: 0B, tracker_analog_gain: 0B, $
  tracker_magnitude_correction: 0B, detector_temp_command: 8B, $
  tracker_bright_magnitude_limit: 0B, tracker_dim_magnitude_limit: 0B, tracker_tec_duty_cycle: 0B, $
  tracker_peak_3sigma_noise: 0B, tracker_peak_mean_background: 0B, tracker_median_3sigma_noise: 0B, $
  tracker_median_mean_background: 0B, tracker_operating_mode: 0B, $
  tracker_star_id_step: 0B, tracker_star_id_status: 0B, tracker_star_id_status_saved: 0B, $
  tracker_attitude_status: 0B, tracker_rate_estimated_status: 0B, $
  tracker_rate_aid_status: 0B, tracker_velocity_aid_status: 0B, tracker_attitude_aid_status: 0B, $
  tracker_vector_aid_status: 0B, tracker_time_tag: 0UL, tracker_num_id_patterns_tried: 0UL, $
  tracker_pixel_amplitude_threshold: 0B, tracker_amplitude_offset: 0B, tracker_current_tint: 0UL, $
  tracker_maximum_residual_id: 0.0, tracker_max_residual_id_first_pass: 0.0, tracker_max_background_level: 0.0, $
  tracker_num_pixel_groups: 0B, tracker_star_id_tolerance: 0B, tracker_num_attitude_loops: 0B, $
  num_stars_used_in_attitude: 0B, num_stars_high_residual: 0B, tracker_auto_black_enable: 0B, $
  tracker_black_level: 0B, num_stars_on_fov: 0B, tracker_num_track_blocks_issued: 0B, num_tracked_stars: 0B, $
  num_id_stars: 0B, tracker_fsw_counter: 0B, auto_track_from_star_id: 0B, $
  tracker_auto_integration_adjust: 0B, tracker_auto_gain_adjust: 0B, tracker_test_mode: 0B, $
  tracker_fpga_detector_timeout: 0B, tracker_tec_enabled: 0B, tracker_store_sequential_images: 0B, $
  tracker_track_ref_available: 0B, num_bright_stars: 0B, $
  attitude_error1: 0L, attitude_error2: 0L, attitude_error3: 0L, $
  rate_error1: 0L, rate_error2: 0L, rate_error3: 0L, $
  integral_error1: 0.0, integral_error2: 0.0, integral_error3: 0.0, $
  commanded_rate_lim1: 0.0, commanded_rate_lim2: 0.0, commanded_rate_lim3: 0.0, $
  commanded_accel_lim1: 0.0, commanded_accel_lim2: 0.0, commanded_accel_lim3: 0.0, $
  feedback_control_torque1: 0.0, feedback_control_torque2: 0.0, feedback_control_torque3: 0.0, $
  total_torque_command1: 0.0, total_torque_command2: 0.0, total_torque_command3: 0.0, $
  time_into_sun_search: 0.0, sun_search_wait_timer: 0.0, sun_point_angle_error: 0.0, $
  sun_point_state: 0B, attitude_control_gain_index: 0B, $
  system_momentum1: 0.0, system_momentum2: 0.0, system_momentum3: 0.0, $
  wheel1_momentum_in_body: 0.0, wheel2_momentum_in_body: 0.0, wheel3_momentum_in_body: 0.0, $
  body_only_momentum_in_body1: 0.0, body_only_momentum_in_body2: 0.0, body_only_momentum_in_body3: 0.0, $
  tr1_duty_cycle: 0B $
   }

adcs4_count = 0L
adcs4_struct1 =  {  apid: 0U, seq_flag: 0U, seq_count: 0U, data_length: 0L, time: 0.0D0, $
 cdh_info: 0B, adcs_info: 0B, adcs_group: 0U, checkbytes: 0U, SyncWord: 0U, $
tr2_duty_cycle: 8B, tr3_duty_cycle: 8B, tr_torqueX: 0.0, tr_torqueY: 0.0, tr_torqueZ: 0.0, $
tr1_ctrlmode: 0B, tr2_ctrlmode: 0B, tr3_ctrlmode: 0B, $
mag_sourcesetting: 0B, mag_source: 0B, mom_vectorvalid: 0B, mom_vectorenabled: 0B, $
tr1_enable: 0B, tr2_enable: 0B, tr3_enable: 0B, tr1_dir: 0B, tr2_dir: 0B, tr3_dir: 0B, $
sunbody_X: 0.0, sunbody_Y: 0.0, sunbody_Z: 0.0, sunbody_status: 0B, $
sunsensor_used: 0, sunsensor_data1: 0U, sunsensor_data2: 0U, sunsensor_data3: 0U, sunsensor_data4: 0U, $
sunvector_enabled: 0B, mag_bodyX: 0.0, mag_bodyY: 0.0, mag_bodyZ: 0.0,  mag_compTemp: 0.0, $
mag_data1: 0, mag_data2: 0, mag_data3: 0, mag_valid: 0B, temp_used: 0, $
imu_rate1: 0.0, imu_rate2: 0.0, imu_rate3: 0.0, $
imu_body_rate1: 0.0, imu_body_rate2: 0.0, imu_body_rate3: 0.0, $
imu_body_time: 0UL, imu_first_rate1: 0, imu_first_rate2: 0, imu_first_rate3: 0, $
imu_pkt_count: 0B, imu_first_id: 0B, imu_rate_valid: 0B, $
counts_per_sec: 0UL, high_run_cnt: 0UL, high_time: 0UL, high_cycle_num: 0UL, vhigh_cycle_num: 0UL, $
high_1msec: 0B, high_2msec: 0B, high_3msec: 0B, high_4msec: 0B, high_5msec: 0B, $
pay_sun_bodyX: 0.0, pay_sun_bodyY: 0.0, pay_sun_bodyZ: 0.0, $
pay_cmd_data1: 0, pay_cmd_data2: 0, pay_sun_valid: 0B, tlm_map_id: 0B, $
volt_5p0: 0.0, volt_3p3: 0.0, volt_2p5: 0.0, volt_1p8: 0.0, volt_1p0: 0.0, $
rw1_temp: 0.0, rw2_temp: 0.0, rw3_temp: 0.0, volt_12v_bus: 0.0, $
data_checksum: 0U, table_length: 0U, table_offset: 0U, table_upload_status: 0B, which_table: 0B, $
st_valid: 0B, st_use_enable: 0B, st_exceed_max_background: 0B, st_exceed_max_rotation: 0B, $
st_exceed_min_sun: 0B, st_exceed_min_earth: 0B, st_exceed_min_moon: 0B, $
sd_adcs_write_offset: 0L, cruciform_scan_index: 0, cruciform_scan_x_steps: 0, $
cruciform_scan_y_steps: 0, cruciform_scan_dwell_period: 0 $
 }

;
; Isolate each packet as being between the SYNC words (0xA5A5)
;
SpecIndex = 1
index = 1L
numlines = 0L
steplines = 20
ans = ' '

;IF inputType EQ 'file' THEN inputSize = finfo.size ELSE inputSize = size(input, /N_ELEMENTS)
inputSize = n_elements(data)  ; 05/25/2016: AC -- We really should just be looking at the size of the data array, not the size of the file...
                              ; Especially since data may now be preprocessed (unKISSed)
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
    indexLast = index3 + 12  ; JPM 2014/10/08: If there is no CDI header, maximum header length with CCSDS headers.
                ; 2014/10/17: ISIS now strips all CDI headers, so reduce offset by 10 bytes.
                ; 2016/05/25: Sync word moved to end of frame a long time ago... so remove another 2 bytes (=12 total)
    IF keyword_set(KISS) OR keyword_set(HAM_HEADER) THEN indexLast += 18 ; Additional header length from KISS+AX25
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

    if keyword_set(hexdump) then begin
      ; now print (hex dump) the packet info from index+1 up to index2
      ; only print if not just the Sync Word
      length = index2 - (index+1) + 1
      if (length gt 2) then begin
        k1 = index+1L
        k2 = index2
        kstep = 20L
        if (pindex gt 0) then begin
          print, '*** Packet Length=',strtrim(length,2), '.', $
            ', APID=',strtrim(packet_ID,2),', Seq_Count=',strtrim(packet_seq_count,2), $
            ', Data_Length=',strtrim(packet_length,2), $
            ', GPS_sec=',string(packet_time,format='(F14.3)')
        endif else print, '*** Packet Length=', strtrim(length,2), '.'
        numlines += 1
        for k=k1,k2,kstep do begin
          kend = k + kstep - 1
          if (kend gt k2) then kend = k2
          sdata = bytarr(kend-k+1) + (byte('.'))[0]
          for j=k,kend do if (data[j] ge 33) and (data[j] le 122) then sdata[j-k]=data[j]
          extra = 2 + (kstep - (kend-k+1))*3
          aformat = '('+strtrim(kend-k+1,2)+'Z3,A'+strtrim(kend-k+1+extra,2)+')'
          print, data[k:kend], string(sdata), format=aformat
          numlines += 1
        endfor
        if (numlines ge steplines) then begin
          if (doPause ne 0) then begin
            read, '> Q=Quit, A=All listed, or Enter key for more ? ', ans
            ans1 = strupcase(strmid(ans,0,1))
            if (ans1 eq 'Q') then return
            if (ans1 eq 'A') then doPause=0
          endif
          numlines = 0L
        endif
      endif
    endif  ; end of hexdump printing

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
        ; Deal with strange offset that sometimes appears in HAM data
        IF keyword_set(HAM_HEADER) THEN BEGIN
          IF (pindex + 253) GE n_elements(data) THEN BEGIN
            pindex = pindex - ((pindex + 253) - (n_elements(data) - 1))
          ENDIF
        ENDIF
        
        pkt_expectedCheckbytes = fletcher_checkbytes(data[pindex:pindex+249])
        pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
        pkt_actualCheckbytes = long(data[pindex+250]) + ishft(long(data[pindex+251]),8)
        IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  HK seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)

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
          
        hk_struct1.checkbytes = pkt_actualCheckbytes
        hk_struct1.checkbytes_calculated = pkt_expectedCheckbytes
        hk_struct1.checkbytes_valid = pkt_actualCheckbytes EQ pkt_expectedCheckbytes
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
        hk_struct1.sd_writectrlblockaddr = (long(data[pindex+63]))  ; 1 - 127 valid range
        hk_struct1.sd_sci_read_offset = (long(data[pindex+64]) + ishft(long(data[pindex+65]),8) $
          + ishft(long(data[pindex+66]),16))

        ; REMOVE for FM2 hk_struct1.adcs_HighRateRunCounter = (long(data[pindex+67]))  ; none
        ; ADD for FM2
        hk_struct1.sd_EphemerisBlockAddr = (long(data[pindex+67]))  ; 128-255 valid range
        
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
        hk_struct1.enable_sps_xps = ISHFT(hk_struct1.cdh_enables AND '0001'X, 0) ;extract the power state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_x123 = ISHFT(hk_struct1.cdh_enables AND '0002'X, -1) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_adcs = ISHFT(hk_struct1.cdh_enables AND '0004'X, -2) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_comm = ISHFT(hk_struct1.cdh_enables AND '0008'X, -3) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_sdcard = ISHFT(hk_struct1.cdh_enables AND '0010'X, -4) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_ant_deploy = ISHFT(hk_struct1.cdh_enables AND '0020'X, -5) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_sa_deploy = ISHFT(hk_struct1.cdh_enables AND '0040'X, -6) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_batt_heater = ISHFT(hk_struct1.cdh_enables AND '0080'X, -7) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        hk_struct1.enable_inst_heater = ISHFT(hk_struct1.cdh_enables AND '0200'X, -9) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        ; REMOVE for FM2: hk_struct1.enable_spare = ISHFT(hk_struct1.cdh_enables AND '0100'X, -8) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
        ; ADD for FM2
        hk_struct1.enable_eclipse_use_css = ISHFT(hk_struct1.cdh_enables AND '0400'X, -10) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
       
        
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
        hk_struct1.sps_y = (fix(data[pindex+206]) + ishft(fix(data[pindex+207]),8))   ; range from -10000 to 10000

        hk_struct1.X123_Fast_Count = (long(data[pindex+208]) + ishft(long(data[pindex+209]),8))  ; Data numbers, counts

        hk_struct1.X123_Slow_Count = (long(data[pindex+210]) + ishft(long(data[pindex+211]),8))  ; Data numbers, counts
        hk_struct1.X123_Det_Temp = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8)) * 0.1 ; Kelvin

        ;Add XACT monitors to HK for the TLM Rev D.25 changes
        hk_struct1.XACT_P5VTrackerVoltage = (uint(data[pindex+214])) * 0.025  ; DN * 0.025 = V
        hk_struct1.XACT_P12VBusVoltage = (uint(data[pindex+215])) * 0.256 ; DN * 0.256 = V
        hk_struct1.XACT_TrackerDetectorTemp = (FIX(data[pindex+216])) * 0.8 ; DN * 0.8 = C deg.
        hk_struct1.XACT_Wheel2Temp = (convert_signedbyte2signedint(data[pindex+217])) * 1.28 ;  DN * 1.28 = C deg.
        hk_struct1.XACT_MeasSunBodyVectorX = (data[pindex+218] ge 128 ? fix(data[pindex+218]) - 256 : fix(data[pindex+218]) ) * 0.0256
        hk_struct1.XACT_MeasSunBodyVectorY = (data[pindex+219] ge 128 ? fix(data[pindex+219]) - 256 : fix(data[pindex+219]) ) * 0.0256
        hk_struct1.XACT_MeasSunBodyVectorZ = (data[pindex+220] ge 128 ? fix(data[pindex+220]) - 256 : fix(data[pindex+220]) ) * 0.0256

        hk_struct1.XACT_CommandStatus = data[pindex+221] ; 0 - 255
        hk_struct1.XACT_CommandAcceptCount = data[pindex+222] ; 0 - 255
        hk_struct1.XACT_CommandAcceptAPID = data[pindex+223] ; 0 - 255
        hk_struct1.XACT_CommandAcceptOpCode = data[pindex+224] ; 0 - 255

        hk_struct1.XACT_CommandRejectCount = data[pindex+225] ; 0 - 255
        hk_struct1.XACT_CommandRejectAPID = data[pindex+226] ; 0 - 255
        hk_struct1.XACT_CommandRejectOpCode = data[pindex+227] ; 0 - 255

        ; DN * 0.01 = rad/s/s
        hk_struct1.XACT_Wheel1EstDrag = (fix(data[pindex+228]) + ishft(fix(data[pindex+229]),8)) * 0.01
        hk_struct1.XACT_Wheel2EstDrag = (fix(data[pindex+230]) + ishft(fix(data[pindex+231]),8)) * 0.01
        hk_struct1.XACT_Wheel3EstDrag = (fix(data[pindex+232]) + ishft(fix(data[pindex+233]),8)) * 0.01

        ; DN * 0.025 = rad/sec based on version Rev 9.02 -FINAL-
        hk_struct1.XACT_Wheel1MeasSpeed = (fix(data[pindex+234]) + ishft(fix(data[pindex+235]),8)) * 0.025
        hk_struct1.XACT_Wheel2MeasSpeed = (fix(data[pindex+236]) + ishft(fix(data[pindex+237]),8)) * 0.025
        hk_struct1.XACT_Wheel3MeasSpeed = (fix(data[pindex+238]) + ishft(fix(data[pindex+239]),8)) * 0.025

        ; DN * 0.00016384 = rad/sec based on version Rev 9.02 -FINAL-
        hk_struct1.XACT_BodyFrameRateX = (fix(data[pindex+240]) + ishft(fix(data[pindex+241]),8)) * 0.00016384
        hk_struct1.XACT_BodyFrameRateY = (fix(data[pindex+242]) + ishft(fix(data[pindex+243]),8)) * 0.00016384
        hk_struct1.XACT_BodyFrameRateZ = (fix(data[pindex+244]) + ishft(fix(data[pindex+245]),8)) * 0.00016384

        ; bits 0,1 - Boot Relay Status, bits 2 - Watchdog Enable, bit 3 - Watchdog Event
        hk_struct1.XACT_LVL0_Bitflags = data[pindex+246]
        hk_struct1.XACT_LVL0_Counter = data[pindex+247] ;
        hk_struct1.XACT_LVL0_CmdRejectCount = data[pindex+248] ;
        hk_struct1.XACT_LVL0_CmdAcceptCount = data[pindex+249] ;
        hk_struct1.checkbytes = uint(data[pindex+250]) + ishft(uint(data[pindex+251]),8)
        hk_struct1.SyncWord = (uint(data[pindex+252]) + ishft(uint(data[pindex+253]),8))  ;none

        if (hk_count eq 0) then hk = replicate(hk_struct1, N_CHUNKS) else $
          if hk_count ge n_elements(hk) then hk = [hk, replicate(hk_struct1, N_CHUNKS)]
        hk[hk_count] = hk_struct1
        hk_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_LOG) then begin
      ;
      ;  ************************
      ;  Log Message (LOG) Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(log) then begin
        log_struct1.apid = packet_id_full  ; keep Playback bit in structure
        log_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        log_struct1.seq_count = packet_seq_count
        log_struct1.data_length = packet_length
        log_struct1.time = packet_time
        log_struct1.checkbytes = long(data[pindex+60]) + ishft(long(data[pindex+61]),8)
        log_struct1.SyncWord = (long(data[pindex+62]) + ishft(long(data[pindex+63]),8))  ;none

        log_struct1.message = string(data[pindex+14:pindex+59])

        if (log_count eq 0) then log = replicate(log_struct1, N_CHUNKS) else $
          if log_count ge n_elements(log) then log = [log, replicate(log_struct1, N_CHUNKS)]
        log[log_count] = log_struct1
        log_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_DIAG) then begin
      ;
      ;  ************************
      ;  Diagnostic (Diag) Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(diag) then begin

        diag_struct1.apid = packet_id_full  ; keep Playback bit in structure
        diag_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        diag_struct1.seq_count = packet_seq_count
        diag_struct1.data_length = packet_length
        diag_struct1.time = packet_time
        diag_struct1.checkbytes = long(data[pindex+250]) + ishft(long(data[pindex+251]),8)
        diag_struct1.SyncWord = (long(data[pindex+252]) + ishft(long(data[pindex+253]),8))  ;none

        diag_struct1.cdh_info = (long(data[pindex+12]))  ;None
        diag_struct1.adcs_info = (long(data[pindex+13]))  ;None
        diag_struct1.monitor_index = (long(data[pindex+14]) + ishft(long(data[pindex+15]),8))   ; none
        diag_struct1.min = (long(data[pindex+16]) + ishft(long(data[pindex+17]),8))   ;
        diag_struct1.max = (long(data[pindex+18]) + ishft(long(data[pindex+19]),8))   ;
        diag_struct1.sum = (long(data[pindex+20]) + ishft(long(data[pindex+21]),8) + ishft(long(data[pindex+22]),16) $
          + ishft(long(data[pindex+23]),24))  ;
        diag_struct1.peak_avg = (long(data[pindex+24]) + ishft(long(data[pindex+25]),8))   ;
        diag_struct1.peak_num = (long(data[pindex+26]) + ishft(long(data[pindex+27]),8))   ;


        for ii=0,DIAG_DATA_LEN-1 do diag_struct1.data[ii] = long(data[pindex+28+ii*2]) + ishft(long(data[pindex+23+ii*2]),8)

        if (diag_count eq 0) then diag = replicate(diag_struct1, N_CHUNKS) else $
          if diag_count ge n_elements(diag) then diag = [diag, replicate(diag_struct1, N_CHUNKS)]
        diag[diag_count] = diag_struct1
        diag_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_SCI) then begin
      ;
      ;  ************************
      ;  Science (Sci) Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(sci) then begin

        sci_struct1.apid = packet_id_full  ; keep Playback bit in structure
        sci_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        sci_struct1.data_length = packet_length

        pkt_expectedCheckbytes = fletcher_checkbytes(data[pindex:pindex+249])
        pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
        pkt_actualCheckbytes = long(data[pindex+250]) + ishft(long(data[pindex+251]),8)
        IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) and keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  Science seq count = " + strtrim(packet_seq_count,2)

        if ((sci_struct1.seq_flag AND '01'X) eq 1) then begin
          IF (sciPacketIncomplete) AND keyword_set(verbose) THEN message, /info, "Missed end of last packet (seqCount = "+strtrim(sci_lastSeqCount,2)+")"

          ;  this is the first science packet (can be up to 14 packets)

          ; Set a "busy" flag so we know we're in the middle of reading a science packet,
          ; which could be more than one transmittal packet
          sciPacketIncomplete = 1

          sci_struct1.time = packet_time
          sci_struct1.seq_count = packet_seq_count
          sci_lastSeqCount = packet_seq_count
          
          sci_struct1.checkbytes = pkt_actualCheckbytes
          sci_struct1.checkbytes_calculated = pkt_expectedCheckbytes
          sci_struct1.SyncWord = (long(data[pindex+252]) + ishft(long(data[pindex+253]),8))  ;none

          sci_struct1.cdh_info = (long(data[pindex+12])) ;None
          sci_struct1.cdh_state = ISHFT(sci_struct1.cdh_info AND 'F0'X, -4) ;extract the state from the MSN, returns one number
          sci_struct1.spacecraft_mode = ISHFT(sci_struct1.cdh_info AND '07'X, 0) ;extract the spacecraft mode from last three bits in the LSN, returns one number
          sci_struct1.eclipse_state = ISHFT(sci_struct1.cdh_info AND '08'X, -3) ;extract the eclipse state from the first bit in the LSN, BOOLEAN, either on(1) or off(0)

          sci_struct1.adcs_info = (long(data[pindex+13])) ;None
          sci_struct1.adcs_state = ISHFT(sci_struct1.adcs_info AND 'E0'X, -5) ; extract 3-bit State value
          sci_struct1.adcs_attitude_valid = ISHFT(sci_struct1.adcs_info AND '10'X, -4) ; extract 1-bit flag
          sci_struct1.adcs_refs_valid = ISHFT(sci_struct1.adcs_info AND '08'X, -3) ; extract 1-bit flag
          sci_struct1.adcs_time_valid = ISHFT(sci_struct1.adcs_info AND '04'X, -2) ; extract 1-bit flag
          sci_struct1.adcs_recommend_sun = ISHFT(sci_struct1.adcs_info AND '02'X, -1) ; extract 1-bit flag
          sci_struct1.adcs_mode = ISHFT(sci_struct1.adcs_info AND '01'X, 0) ; extract 1-bit flag

          sci_struct1.xps_data = (long(data[pindex+14]) + ishft(long(data[pindex+15]),8) $
            + ishft(long(data[pindex+16]),16) + ishft(long(data[pindex+17]),24))  ; counts
          sci_struct1.dark_data = (long(data[pindex+18]) + ishft(long(data[pindex+19]),8) $
            + ishft(long(data[pindex+20]),16) + ishft(long(data[pindex+21]),24))  ; counts

          for ii=0,3,1 do begin
            sci_struct1.sps_data[ii] =  (long(data[pindex+22+(ii*4)]) + ishft(long(data[pindex+23+(ii*4)]),8) $
              + ishft(long(data[pindex+24+(ii*4)]),16) + ishft(long(data[pindex+25+(ii*4)]),24))  ; counts
          endfor

          sci_struct1.sps_xp_integration_time = (long(data[pindex+38]) + ishft(long(data[pindex+39]),8))   ; seconds

          sci_struct1.x123_fast_count = (long(data[pindex+40]) + ishft(long(data[pindex+41]),8) $
            + ishft(long(data[pindex+42]),16) + ishft(long(data[pindex+43]),24))  ; counts
          sci_struct1.x123_slow_count = (long(data[pindex+44]) + ishft(long(data[pindex+45]),8) $
            + ishft(long(data[pindex+46]),16) + ishft(long(data[pindex+47]),24))  ; counts
          sci_struct1.x123_gp_count = (long(data[pindex+48]) + ishft(long(data[pindex+49]),8) $
            + ishft(long(data[pindex+50]),16) + ishft(long(data[pindex+51]),24))  ; counts
          sci_struct1.x123_accum_time = (long(data[pindex+52]) + ishft(long(data[pindex+53]),8) $
            + ishft(long(data[pindex+54]),16) + ishft(long(data[pindex+55]),24))  ; DN = msec
          sci_struct1.x123_live_time = (long(data[pindex+56]) + ishft(long(data[pindex+57]),8) $
            + ishft(long(data[pindex+58]),16) + ishft(long(data[pindex+59]),24))  ; DN = msec
          sci_struct1.x123_real_time = (long(data[pindex+60]) + ishft(long(data[pindex+61]),8) $
            + ishft(long(data[pindex+62]),16) + ishft(long(data[pindex+63]),24))  ; DN = msec

          sci_struct1.x123_hv = (long(data[pindex+64]) + ishft(long(data[pindex+65]),8))   ; volt (signed)
          ;Because the value can be positive or negative we have to calculate the two's compliment
          if sci_struct1.x123_hv GE (2L^(15)) then sci_struct1.x123_hv -=  (2L^(16))
          sci_struct1.x123_hv *= .5

          sci_struct1.x123_det_temp = (long(data[pindex+66]) + ishft(long(data[pindex+67]),8)) * 0.1 ; Deg K

          sci_struct1.x123_brd_temp = (long(data[pindex+68]))    ; deg C (signed)
          ;Because the value can be positive or negative we have to calculate the two's compliment
          if sci_struct1.x123_brd_temp GE (2L^(7)) then sci_struct1.x123_brd_temp -=  (2L^(8))

          sci_struct1.x123_flags = (long(data[pindex+69]) + ishft(long(data[pindex+70]),8) $
            + ishft(long(data[pindex+71]),16))  ; none

          tempErr = long(data[pindex+75])
          sci_struct1.x123_read_errors = ishft( tempErr AND '0080'X, -7 )
          sci_struct1.x123_radio_flag = tempErr AND '003F'X
          sci_struct1.x123_write_errors = ishft( tempErr AND '0040'X, -6 )
          sci_struct1.sd_sci_write_offset = long(data[pindex+72]) + ishft(long(data[pindex+73]),8) + ishft(long(data[pindex+74]),16)
          
          sci_struct1.x123_cmp_info = (long(data[pindex+76]) + ishft(long(data[pindex+77]),8))  ; bytes
          sci_struct1.x123_spect_len = (long(data[pindex+78]) + ishft(long(data[pindex+79]),8))   ;bytes
          sci_struct1.x123_group_count = (long(data[pindex+80]) + ishft(long(data[pindex+81]),8))  ;none

          ; Store Raw Spectrum Data and see if need to decompress it after last packet
          sci_numPacketsExpected = ceil((sci_struct1.x123_spect_len - X123_FIRST_LENGTH * 1d0) / X123_OTHER_LENGTH) + 1
          sci_packetCounter = 1

          sci_raw_count = 0L
          sci_raw_data = bytarr(X123_DATA_MAX)
          for ii=0,X123_FIRST_LENGTH-1 do sci_raw_data[ii] = data[pindex+82+ii]
          sci_raw_count = X123_FIRST_LENGTH

        endif else begin
          ;  this is other (not first) science packet (can be up to 14 packets)

          ; Set a "busy" flag so we know we're in the middle of reading a science packet,
          ; which could be more than one transmittal packet
          sciPacketIncomplete = 1

          ;sci_struct1.time = packet_time
          ;sci_struct1.checksum = long(data[pindex+248]) + ishft(long(data[pindex+249]),8)
          sci_struct1.x123_group_count = (long(data[pindex+14]) + ishft(long(data[pindex+15]),8))  ;none
          sci_struct1.checkbytes += pkt_actualCheckbytes
          sci_struct1.checkbytes_calculated += pkt_expectedCheckbytes

          ; Store Raw Spectrum Data and see if need to decompress it after last packet
          IF (packet_seq_count EQ ((sci_lastSeqCount + 1) mod 2L^14)) THEN BEGIN
            sci_lastSeqCount = packet_seq_count
            sci_packetCounter += 1

            SpecIndex = (sci_struct1.x123_group_count-1)*X123_OTHER_LENGTH + X123_FIRST_LENGTH
            if n_elements(sci_raw_data) ne 0 then begin
              if pindex+16+X123_OTHER_LENGTH lt n_elements(data) then begin
                for ii=0,X123_OTHER_LENGTH-1 do begin
                  if ((SpecIndex+ii) lt X123_DATA_MAX) then sci_raw_data[SpecIndex+ii] = data[pindex+16+ii]
                endfor
                sci_raw_count += X123_OTHER_LENGTH
              endif else message, /info, "Science packet too short! WTF?"
            endif else sciPacketIncomplete = 0
          ENDIF ELSE BEGIN
            IF keyword_set(verbose) THEN message, /info, "Gap in science packet sequence counter (expected "+strtrim(sci_lastSeqCount + 1,2)+", saw "+strtrim(packet_seq_count,2)+") -- trashing current packet!"
          ENDELSE

        endelse

        ;
        ;   Check if it is last linked packet and if so, then decompress and store
        ;
        if ((sci_struct1.seq_flag AND '02'X) eq 2) then begin

          if (sci_packetCounter EQ sci_numPacketsExpected) then begin
            sci_struct1.x123_spectrum = x123_decompress( sci_raw_data, sci_raw_count, sci_struct1.x123_cmp_info, sci_struct1.x123_spect_len )
            ; Validate the checksum
            sci_struct1.checkbytes_valid = sci_struct1.checkbytes EQ sci_struct1.checkbytes_calculated
            if (sci_count eq 0) then sci = replicate(sci_struct1, N_CHUNKS) else $
              if sci_count ge n_elements(sci) then sci = [sci, replicate(sci_struct1, N_CHUNKS)]
            sci[sci_count] = sci_struct1
            sci_count += 1
            ; Done with this packet so reset the counters
            sci_packetCounter = 0
            sci_numPacketsExpected = -1
          endif else begin
            IF keyword_set(verbose) THEN message, /info, "Missing packet in group (saw "+strtrim(sci_packetCounter,2)+", expected "+strtrim(sci_numPacketsExpected,2)+") -- trashing packet!"
          endelse

          ; Unset "busy" flag since the science packet is now complete
          sciPacketIncomplete = 0

        endif
      endif

    endif else if (packet_id eq PACKET_ID_ADCS1) then begin
      ;
      ;  ************************
      ;  ADCS-1 Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(adcs1) then begin
        adcs1_struct1.apid = packet_id_full  ; keep Playback bit in structure
        adcs1_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        adcs1_struct1.seq_count = packet_seq_count
        adcs1_struct1.data_length = packet_length
        adcs1_struct1.time = packet_time   ; millisec (0.1 msec resolution)
        adcs1_struct1.SpareByte = (long(data[pindex+209])) ;None
        adcs1_struct1.checkbytes = long(data[pindex+210]) + ishft(long(data[pindex+211]),8)
        adcs1_struct1.SyncWord = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8))  ;none
        adcs1_struct1.cdh_info = (long(data[pindex+12])) ;None
        adcs1_struct1.adcs_info = (long(data[pindex+13])) ;None
        adcs1_struct1.adcs_group = long(data[pindex+14]) + ishft(long(data[pindex+15]),8) ;Increments for each packet group (0, 1, 2, 3)

        IF keyword_set(EXPORT_RAW_ADCS_TLM) THEN adcs1Raw = data[pindex + 16:pindex + 208]

        FOR i = 0, 31 DO  adcs1_struct1.adcs_level[i] = ((data[pindex+16+i]))
        adcs1_struct1.command_status = data[pindex+48]          ; 0=OK, 1=BAD_APID, 2=BAD_OPCODE, 3=BAD_DATA, 8=CMD_SRVC_OVERRUN, 9=CMD_APID_OVERRUN
        adcs1_struct1.command_reject_status = data[pindex+49]   ; 0=OK, 1=BAD_APID, 2=BAD_OPCODE, 3=BAD_DATA, 8=CMD_SRVC_OVERRUN, 9=CMD_APID_OVERRUN
        adcs1_struct1.command_accept_count = data[pindex+50]    ; [none]
        adcs1_struct1.command_reject_count = data[pindex+51]    ; [none]
        adcs1_struct1.last_accept_cmd_bytes1 = data[pindex+52]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes2 = data[pindex+53]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes3 = data[pindex+54]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes4 = data[pindex+55]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes5 = data[pindex+56]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes6 = data[pindex+57]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes7 = data[pindex+58]  ; [none]
        adcs1_struct1.last_accept_cmd_bytes8 = data[pindex+59]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes1 = data[pindex+60]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes2 = data[pindex+61]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes3 = data[pindex+62]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes4 = data[pindex+63]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes5 = data[pindex+64]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes6 = data[pindex+65]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes7 = data[pindex+66]  ; [none]
        adcs1_struct1.last_reject_cmd_bytes8 = data[pindex+67]  ; [none]
        adcs1_struct1.tai_seconds = (ishft(ulong(data[pindex+36]),68) + ishft(ulong(data[pindex+69]),16) $
                                  +  ishft(ulong(data[pindex+70]),8)  +       ulong(data[pindex+71])) * 0.2              ; [s]
        adcs1_struct1.cycle_time = (ishft(ulong(data[pindex+72]),24) + ishft(ulong(data[pindex+73]),16) $
                                 +  ishft(ulong(data[pindex+74]),8)  +       ulong(data[pindex+75])) * 0.2               ; [s]
        adcs1_struct1.julian_date_tai = ishft(ulong(data[pindex+76]),24) + ishft(ulong(data[pindex+77]),16) $
                                     +  ishft(ulong(data[pindex+78]),8)  +       ulong(data[pindex+79])                  ; [day]
        adcs1_struct1.time_valid = data[pindex+80]                                                                       ; 1=YES, 0=NO
        adcs1_struct1.orbit_time = (ishft(ulong(data[pindex+81]),24) + ishft(ulong(data[pindex+82]),16) $
                                 +  ishft(ulong(data[pindex+83]),8)  +       ulong(data[pindex+84])) * 0.2               ; [s]
        adcs1_struct1.q_ecef_wrt_eci1 = (ishft(long(data[pindex+85]),24) + ishft(long(data[pindex+86]),16) $
                                      +  ishft(long(data[pindex+87]),8)  +       long(data[pindex+88])) * 1.0E-9         ; [none]
        adcs1_struct1.q_ecef_wrt_eci2 = (ishft(long(data[pindex+89]),24) + ishft(long(data[pindex+90]),16) $
                                      +  ishft(long(data[pindex+91]),8)  +       long(data[pindex+92])) * 1.0E-9         ; [none]
        adcs1_struct1.q_ecef_wrt_eci3 = (ishft(long(data[pindex+93]),24) + ishft(long(data[pindex+94]),16) $
                                      +  ishft(long(data[pindex+95]),8)  +       long(data[pindex+96])) * 1.0E-9         ; [none]
        adcs1_struct1.q_ecef_wrt_eci4 = (ishft(long(data[pindex+97]),24) + ishft(long(data[pindex+98]),16) $
                                      +  ishft(long(data[pindex+99]),8)  +       long(data[pindex+100])) * 1.0E-9         ; [none]
        adcs1_struct1.orbit_position_eci1 = (ishft(long(data[pindex+101]),24) + ishft(long(data[pindex+102]),16) $
                                          +  ishft(long(data[pindex+103]),8)  +       long(data[pindex+104])) * 2.0E-5     ; [km]
        adcs1_struct1.orbit_position_eci2 = (ishft(long(data[pindex+105]),24) + ishft(long(data[pindex+106]),16) $
                                          +  ishft(long(data[pindex+107]),8)  +       long(data[pindex+108])) * 2.0E-5     ; [km]
        adcs1_struct1.orbit_position_eci3 = (ishft(long(data[pindex+109]),24) + ishft(long(data[pindex+110]),16) $
                                          +  ishft(long(data[pindex+111]),8)  +       long(data[pindex+112])) * 2.0E-5     ; [km]
        adcs1_struct1.orbit_position_ecef1 = (ishft(long(data[pindex+113]),24) + ishft(long(data[pindex+114]),16) $
                                           +  ishft(long(data[pindex+115]),8)  +       long(data[pindex+116])) * 2.0E-5    ; [km]
        adcs1_struct1.orbit_position_ecef2 = (ishft(long(data[pindex+117]),24) + ishft(long(data[pindex+118]),16) $
                                           +  ishft(long(data[pindex+119]),8)  +       long(data[pindex+120])) * 2.0E-5    ; [km]
        adcs1_struct1.orbit_position_ecef3 = (ishft(long(data[pindex+121]),24) + ishft(long(data[pindex+122]),16) $
                                           +  ishft(long(data[pindex+123]),8)  +       long(data[pindex+124])) * 2.0E-5    ; [km]
        adcs1_struct1.orbit_velocity_eci1 = (ishft(long(data[pindex+125]),24) + ishft(long(data[pindex+126]),16) $
                                          +  ishft(long(data[pindex+127]),8)  +       long(data[pindex+128])) * 5.0E-9     ; [km/s]
        adcs1_struct1.orbit_velocity_eci2 = (ishft(long(data[pindex+129]),24) + ishft(long(data[pindex+130]),16) $
                                          +  ishft(long(data[pindex+131]),8)  +       long(data[pindex+132])) * 5.0E-9   ; [km/s]
        adcs1_struct1.orbit_velocity_eci3 = (ishft(long(data[pindex+133]),24) + ishft(long(data[pindex+134]),16) $
                                          +  ishft(long(data[pindex+135]),8)  +       long(data[pindex+136])) * 5.0E-9   ; [km/s]
        adcs1_struct1.orbit_velocity_ecef1 = (ishft(long(data[pindex+137]),24) + ishft(long(data[pindex+138]),16) $
                                           +  ishft(long(data[pindex+139]),8)  +       long(data[pindex+140])) * 5.0E-9  ; [km/s]
        adcs1_struct1.orbit_velocity_ecef2 = (ishft(long(data[pindex+141]),24) + ishft(long(data[pindex+142]),16) $
                                           +  ishft(long(data[pindex+143]),8)  +       long(data[pindex+144])) * 5.0E-9  ; [km/s]
        adcs1_struct1.orbit_velocity_ecef3 = (ishft(long(data[pindex+145]),24) + ishft(long(data[pindex+146]),16) $
                                           +  ishft(long(data[pindex+147]),8)  +       long(data[pindex+148])) * 5.0E-9  ; [km/s]
        adcs1_struct1.mag_model_vector_eci1 = (ishft(fix(data[pindex+149]),8) + fix(data[pindex+150])) * 5.0E-9          ; [T]
        ;  ERROR in offset is only 2 instead of 4 bytes for int16 variables (TW 8/26/15); adjust all offsets below
        adcs1_struct1.mag_model_vector_eci2 = (ishft(fix(data[pindex+151]),8) + fix(data[pindex+152]))* 5.0E-9           ; [T]
        adcs1_struct1.mag_model_vector_eci3 = (ishft(fix(data[pindex+153]),8) + fix(data[pindex+154])) * 5.0E-9          ; [T]
        adcs1_struct1.mag_model_vector_body1 = (ishft(fix(data[pindex+155]),8) + fix(data[pindex+156])) * 5.0E-9         ; [T]
        adcs1_struct1.mag_model_vector_body2 = (ishft(fix(data[pindex+157]),8) + fix(data[pindex+158])) * 5.0E-9         ; [T]
        adcs1_struct1.mag_model_vector_body3 = (ishft(fix(data[pindex+159]),8) + fix(data[pindex+160])) * 5.0E-9         ; [T]
        adcs1_struct1.sun_model_vector_eci1 = (ishft(fix(data[pindex+161]),8) + fix(data[pindex+162])) * 4.0E-5          ; [none]
        adcs1_struct1.sun_model_vector_eci2 = (ishft(fix(data[pindex+163]),8) + fix(data[pindex+164])) * 4.0E-5          ; [none]
        adcs1_struct1.sun_model_vector_eci3 = (ishft(fix(data[pindex+165]),8) + fix(data[pindex+166]))* 4.0E-5           ; [none]
        adcs1_struct1.sun_model_vector_body1 = (ishft(fix(data[pindex+167]),8) + fix(data[pindex+168])) * 4.0E-5         ; [none]
        adcs1_struct1.sun_model_vector_body2 = (ishft(fix(data[pindex+169]),8) + fix(data[pindex+170])) * 4.0E-5         ; [none]
        adcs1_struct1.sun_model_vector_body3 = (ishft(fix(data[pindex+171]),8) + fix(data[pindex+172])) * 4.0E-5         ; [none]
        adcs1_struct1.moon_model_vector_eci1 = (ishft(fix(data[pindex+173]),8) + fix(data[pindex+174])) * 4.0E-5         ; [none]
        adcs1_struct1.moon_model_vector_eci2 = (ishft(fix(data[pindex+175]),8) + fix(data[pindex+176])) * 4.0E-5         ; [none]
        adcs1_struct1.moon_model_vector_eci3 = (ishft(fix(data[pindex+177]),8) + fix(data[pindex+178])) * 4.0E-5         ; [none]
        adcs1_struct1.moon_model_vector_body1 = (ishft(fix(data[pindex+179]),8) + fix(data[pindex+180])) * 4.0E-5        ; [none]
        adcs1_struct1.moon_model_vector_body2 = (ishft(fix(data[pindex+181]),8) + fix(data[pindex+182])) * 4.0E-5        ; [none]
        adcs1_struct1.moon_model_vector_body3 = (ishft(fix(data[pindex+183]),8) + fix(data[pindex+184])) * 4.0E-5        ; [none]
        adcs1_struct1.atmospheric_density = ishft(fix(data[pindex+185]),8) + fix(data[pindex+186])                       ; [kg/m^3]
        adcs1_struct1.refs_valid = data[pindex+187]                                                                      ; [none]
        adcs1_struct1.run_low_rate_task = data[pindex+188]                                                               ; [none]
        adcs1_struct1.attitude_quaternion1 = (ishft(long(data[pindex+189]),24) + ishft(long(data[pindex+190]),16) $
                                           +  ishft(long(data[pindex+191]),8)  +       long(data[pindex+192])) * 5.0E-10 ; [none]
        adcs1_struct1.attitude_quaternion2 = (ishft(long(data[pindex+193]),24) + ishft(long(data[pindex+194]),16) $
                                           +  ishft(long(data[pindex+195]),8)  +       long(data[pindex+196])) * 5.0E-10 ; [none]
        adcs1_struct1.attitude_quaternion3 = (ishft(long(data[pindex+197]),24) + ishft(long(data[pindex+198]),16) $
                                           +  ishft(long(data[pindex+199]),8)  +       long(data[pindex+200])) * 5.0E-10 ; [none]
        adcs1_struct1.attitude_quaternion4 = (ishft(long(data[pindex+201]),24) + ishft(long(data[pindex+202]),16) $
                                           +  ishft(long(data[pindex+203]),8)  +       long(data[pindex+204])) * 5.0E-10 ; [none]
        adcs1_struct1.attitude_filter_residual1 = (ishft(long(data[pindex+205]),24) + ishft(long(data[pindex+206]),16) $
                                                +  ishft(long(data[pindex+207]),8)  +       long(data[pindex+208])) * 5.0E-10 ; [rad]

        ;adcs1_data Notes:
        ;ALL XACT TLM Data Available
        ;- 723 bytes + 49 bytes spares from XACT
        ;- see XACT ICD revJ ADDENDUM 6
        ;- each pkt = 193 bytes from XACT
        ;- each pkt = 1 byte spare from MinXSS FSW
        ;First/Last XACT TM Point refs:
        ;Group 0 - APID 38:
        ;- first: LEVEL_00
        ;- last: Attitude_Filter_Residual_X

        if (adcs1_count eq 0) then adcs1 = replicate(adcs1_struct1, N_CHUNKS) else $
          if adcs1_count ge n_elements(adcs1) then adcs1 = [adcs1, replicate(adcs1_struct1, N_CHUNKS)]
        adcs1[adcs1_count] = adcs1_struct1
        adcs1_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_ADCS2) then begin
      ;
      ;  ************************
      ;  ADCS-2 Packet (if user asked for it)
      ;
      ; Note that (BCT XACT Offset - 177) is the value to use with pindex for the ADCS3 variables
      ;  ************************
      ;
      if arg_present(adcs2) then begin
        adcs2_struct1.apid = packet_id_full  ; keep Playback bit in structure
        adcs2_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        adcs2_struct1.seq_count = packet_seq_count
        adcs2_struct1.data_length = packet_length
        adcs2_struct1.time = packet_time   ; millisec (0.1 msec resolution)
        adcs2_struct1.SpareByte = (long(data[pindex+209])) ;None
        adcs2_struct1.checkbytes = long(data[pindex+210]) + ishft(long(data[pindex+211]),8)
        adcs2_struct1.SyncWord = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8))  ;none
        adcs2_struct1.cdh_info = (long(data[pindex+12])) ;None
        adcs2_struct1.adcs_info = (long(data[pindex+13])) ;None
        adcs2_struct1.adcs_group = long(data[pindex+14]) + ishft(long(data[pindex+15]),8)

        IF keyword_set(EXPORT_RAW_ADCS_TLM) THEN adcs2Raw = data[pindex + 16:pindex + 208]

        adcs2_struct1.attitude_filter_residual2 = (ishft(long(data[pindex+16]),24) + ishft(long(data[pindex+17]),16) $
                                                +  ishft(long(data[pindex+18]),8 ) +       long(data[pindex+19])) * 5.0E-10 ; [rad]
        adcs2_struct1.attitude_filter_residual3 = (ishft(long(data[pindex+20]),24) + ishft(long(data[pindex+21]),16) $
                                                +  ishft(long(data[pindex+22]),8 ) +       long(data[pindex+23])) * 5.0E-10 ; [rad]
        adcs2_struct1.body_frame_rate1 = (ishft(long(data[pindex+24]),24) + ishft(long(data[pindex+25]),16) $
                                       +  ishft(long(data[pindex+26]),8 ) +       long(data[pindex+27])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.body_frame_rate2 = (ishft(long(data[pindex+28]),24) + ishft(long(data[pindex+29]),16) $
                                       +  ishft(long(data[pindex+30]),8 ) +       long(data[pindex+31])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.body_frame_rate3 = (ishft(long(data[pindex+32]),24) + ishft(long(data[pindex+33]),16) $
                                       +  ishft(long(data[pindex+34]),8 ) +       long(data[pindex+35])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.estimated_gyro_bias1 = (ishft(fix(data[pindex+36]),8) + fix(data[pindex+37])) * 5.0E-7 ; [rad/s]
        adcs2_struct1.estimated_gyro_bias2 = (ishft(fix(data[pindex+38]),8) + fix(data[pindex+39])) * 5.0E-7 ; [rad/s]
        adcs2_struct1.estimated_gyro_bias3 = (ishft(fix(data[pindex+40]),8) + fix(data[pindex+41])) * 5.0E-7 ; [rad/s]
        adcs2_struct1.attitude_filter_algorithm = data[pindex+42] ; 1=raw, 2=fixed_gain_no_bias, 3=fixed_gain, 4=kalman
        adcs2_struct1.good_attitude_rate_timer = ishft(ulong(data[pindex+43]),24) + ishft(ulong(data[pindex+44]),16) $
                                               + ishft(ulong(data[pindex+45]),8 )  +       ulong(data[pindex+46]) ; [cycles]
        adcs2_struct1.bad_attitude_timer = ishft(ulong(data[pindex+47]),24) + ishft(ulong(data[pindex+48]),16) $
                                         + ishft(ulong(data[pindex+49]),8 )  +       ulong(data[pindex+50]) ; [cycles]
        adcs2_struct1.bad_rate_timer = ishft(ulong(data[pindex+51]),24) + ishft(ulong(data[pindex+52]),16) $
                                     + ishft(ulong(data[pindex+53]),8 )  +       ulong(data[pindex+54]) ; [cycles]
        adcs2_struct1.attitude_filter_reint_count = ishft(ulong(data[pindex+55]),24) + ishft(ulong(data[pindex+56]),16) $
                                                  + ishft(ulong(data[pindex+57]),8 )  +       ulong(data[pindex+58]) ; [none]
        adcs2_struct1.attitude_valid = data[pindex+59] ; 1=yes, 0=no
        adcs2_struct1.measured_attitude_valid = data[pindex+60] ; 1=yes, 0=no
        adcs2_struct1.measured_rate_valid = data[pindex+61] ; 1=yes, 0=no
        adcs2_struct1.commanded_attitude_quat1 = (ishft(long(data[pindex+62]),24) + ishft(long(data[pindex+63]),16) $
                                               +  ishft(long(data[pindex+64]),8 ) +       long(data[pindex+65])) * 5.0E-10 ; [none]
        adcs2_struct1.commanded_attitude_quat2 = (ishft(long(data[pindex+66]),24) + ishft(long(data[pindex+67]),16) $
                                               +  ishft(long(data[pindex+68]),8 ) +       long(data[pindex+69])) * 5.0E-10 ; [none]
        adcs2_struct1.commanded_attitude_quat3 = (ishft(long(data[pindex+70]),24) + ishft(long(data[pindex+71]),16) $
                                               +  ishft(long(data[pindex+72]),8 ) +       long(data[pindex+73])) * 5.0E-10 ; [none]
        adcs2_struct1.commanded_attitude_quat4 = (ishft(long(data[pindex+74]),24) + ishft(long(data[pindex+75]),16) $
                                               +  ishft(long(data[pindex+76]),8 ) +       long(data[pindex+77])) * 5.0E-10 ; [none]
        adcs2_struct1.commanded_rate1 = (ishft(long(data[pindex+78]),24) + ishft(long(data[pindex+79]),16) $
                                      +  ishft(long(data[pindex+80]),8 ) +       long(data[pindex+81])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.commanded_rate2 = (ishft(long(data[pindex+82]),24) + ishft(long(data[pindex+83]),16) $
                                      +  ishft(long(data[pindex+84]),8 ) +       long(data[pindex+85])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.commanded_rate3 = (ishft(long(data[pindex+86]),24) + ishft(long(data[pindex+87]),16) $
                                      +  ishft(long(data[pindex+88]),8 ) +       long(data[pindex+89])) * 5.0E-9 ; [rad/s]
        adcs2_struct1.commanded_accel1 = (ishft(long(data[pindex+90]),24) + ishft(long(data[pindex+91]),16) $
                                       +  ishft(long(data[pindex+92]),8 ) +       long(data[pindex+93])) * 5.0E-9 ; [rad/s/s]
        adcs2_struct1.commanded_accel2 = (ishft(long(data[pindex+94]),24) + ishft(long(data[pindex+95]),16) $
                                       +  ishft(long(data[pindex+96]),8 ) +       long(data[pindex+97])) * 5.0E-9 ; [rad/s/s]
        adcs2_struct1.commanded_accel3 = (ishft(long(data[pindex+ 98]),24) + ishft(long(data[pindex+ 99]),16) $
                                       +  ishft(long(data[pindex+100]),8 ) +       long(data[pindex+101])) * 5.0E-9 ; [rad/s/s]
        adcs2_struct1.desired_sun_vector1 = (ishft(fix(data[pindex+102]),8) + fix(data[pindex+103])) * 4.0E-5 ; [none]
        adcs2_struct1.desired_sun_vector2 = (ishft(fix(data[pindex+104]),8) + fix(data[pindex+105])) * 4.0E-5 ; [none]
        adcs2_struct1.desired_sun_vector3 = (ishft(fix(data[pindex+106]),8) + fix(data[pindex+107])) * 4.0E-5 ; [none]
        adcs2_struct1.desired_sun_rot_rate = (ishft(fix(data[pindex+108]),8) + fix(data[pindex+109])) * 4.0E-5 ; [rad/s]
        adcs2_struct1.adcs_mode = data[pindex+110] ; 0=sun_point, 1 = fine_point
        adcs2_struct1.recommended_sun_point = data[pindex+111] ; 1=yes, 0=no
        adcs2_struct1.wheel_est_drag1 = (ishft(fix(data[pindex+112]),8) + fix(data[pindex+113])) * 0.01 ; [rad/s/s]
        adcs2_struct1.wheel_est_drag2 = (ishft(fix(data[pindex+114]),8) + fix(data[pindex+115])) * 0.01 ; [rad/s/s]
        adcs2_struct1.wheel_est_drag3 = (ishft(fix(data[pindex+116]),8) + fix(data[pindex+117])) * 0.01 ; [rad/s/s]
        adcs2_struct1.wheel_angle_residual1 = (ishft(fix(data[pindex+118]),8) + fix(data[pindex+119])) * 0.00025 ; [rad]
        adcs2_struct1.wheel_angle_residual2 = (ishft(fix(data[pindex+120]),8) + fix(data[pindex+121])) * 0.00025 ; [rad]
        adcs2_struct1.wheel_angle_residual3 = (ishft(fix(data[pindex+122]),8) + fix(data[pindex+123])) * 0.00025 ; [rad]
        adcs2_struct1.wheel_meas_speed1 = (ishft(fix(data[pindex+124]),8) + fix(data[pindex+125])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_meas_speed2 = (ishft(fix(data[pindex+126]),8) + fix(data[pindex+127])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_meas_speed3 = (ishft(fix(data[pindex+128]),8) + fix(data[pindex+129])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_commanded_speed1 = (ishft(fix(data[pindex+130]),8) + fix(data[pindex+131])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_commanded_speed2 = (ishft(fix(data[pindex+132]),8) + fix(data[pindex+133])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_commanded_speed3 = (ishft(fix(data[pindex+134]),8) + fix(data[pindex+135])) * 0.025 ; [rad/s]
        adcs2_struct1.wheel_commanded_torque1 = (ishft(fix(data[pindex+136]),8) + fix(data[pindex+137])) * 1.0E-7 ; [Nm]
        adcs2_struct1.wheel_commanded_torque2 = (ishft(fix(data[pindex+138]),8) + fix(data[pindex+139])) * 1.0E-7 ; [Nm]
        adcs2_struct1.wheel_commanded_torque3 = (ishft(fix(data[pindex+140]),8) + fix(data[pindex+141])) * 1.0E-7 ; [Nm]
        adcs2_struct1.coarse_wheel_current1 = (ishft(fix(data[pindex+142]),8) + fix(data[pindex+143])) * 0.001 ; [A]
        adcs2_struct1.coarse_wheel_current2 = (ishft(fix(data[pindex+144]),8) + fix(data[pindex+145])) * 0.001 ; [A]
        adcs2_struct1.coarse_wheel_current3 = (ishft(fix(data[pindex+146]),8) + fix(data[pindex+147])) * 0.001 ; [A]
        adcs2_struct1.wheel_time_tag = ishft(ulong(data[pindex+148]),24) + ishft(ulong(data[pindex+149]),16) $
                                     + ishft(ulong(data[pindex+150]),8 ) +       ulong(data[pindex+151]) ; [µs]
        adcs2_struct1.wheel_pwm_counts1 = ishft(ulong(data[pindex+152]),24) + ishft(ulong(data[pindex+153]),16) $
                                        + ishft(ulong(data[pindex+154]),8 ) +       ulong(data[pindex+155]) ; [none]
        adcs2_struct1.wheel_pwm_counts2 = ishft(ulong(data[pindex+156]),24) + ishft(ulong(data[pindex+157]),16) $
                                        + ishft(ulong(data[pindex+158]),8 ) +       ulong(data[pindex+159]) ; [none]
        adcs2_struct1.wheel_pwm_counts3 = ishft(ulong(data[pindex+160]),24) + ishft(ulong(data[pindex+161]),16) $
                                        + ishft(ulong(data[pindex+162]),8 ) +       ulong(data[pindex+163]) ; [none]
        adcs2_struct1.wheel_pwm_commanded_counts1 = ishft(ulong(data[pindex+164]),24) + ishft(ulong(data[pindex+165]),16) $
                                                  + ishft(ulong(data[pindex+166]),8 ) +       ulong(data[pindex+167]) ; [none]
        adcs2_struct1.wheel_pwm_commanded_counts2 = ishft(ulong(data[pindex+168]),24) + ishft(ulong(data[pindex+169]),16) $
                                                  + ishft(ulong(data[pindex+170]),8 ) +       ulong(data[pindex+171]) ; [none]
        adcs2_struct1.wheel_pwm_commanded_counts3 = ishft(ulong(data[pindex+172]),24) + ishft(ulong(data[pindex+173]),16) $
                                                  + ishft(ulong(data[pindex+174]),8 ) +       ulong(data[pindex+175]) ; [none]
        adcs2_struct1.wheel_tach_counts1 = ishft(uint(data[pindex+176]),8) + uint(data[pindex+177]) ; [none]
        adcs2_struct1.wheel_tach_counts2 = ishft(uint(data[pindex+178]),8) + uint(data[pindex+179]) ; [none]
        adcs2_struct1.wheel_tach_counts3 = ishft(uint(data[pindex+180]),8) + uint(data[pindex+181]) ; [none]
        adcs2_struct1.cal_cycle_timer1 = ishft(uint(data[pindex+182]),8) + uint(data[pindex+183]) ; [RWcycles]
        adcs2_struct1.cal_cycle_timer2 = ishft(uint(data[pindex+184]),8) + uint(data[pindex+185]) ; [RWcycles]
        adcs2_struct1.cal_cycle_timer3 = ishft(uint(data[pindex+186]),8) + uint(data[pindex+187]) ; [RWcycles]
        ;  ERROR for Operation Mode 1 offset (TW 8/26/2015): offset all below by -3
        adcs2_struct1.wheel_operating_mode1 = data[pindex+188] ; 0=idle, 1=internal, 2=external
        adcs2_struct1.wheel_operating_mode2 = data[pindex+189] ; 0=idle, 1=internal, 2=external
        adcs2_struct1.wheel_operating_mode3 = data[pindex+190] ; 0=idle, 1=internal, 2=external
        adcs2_struct1.wheel_control_mode1 = data[pindex+191]   ; 0=torque, 1=spd, 2=pwm
        adcs2_struct1.wheel_control_mode2 = data[pindex+192]   ; 0=torque, 1=spd, 2=pwm
        adcs2_struct1.wheel_control_mode3 = data[pindex+193]   ; 0=torque, 1=spd, 2=pwm
        adcs2_struct1.wheel_motor_fault1 = data[pindex+194]    ; 0=fault, 1=ok
        adcs2_struct1.wheel_motor_fault2 = data[pindex+195]    ; 0=fault, 1=ok
        adcs2_struct1.wheel_motor_fault3 = data[pindex+196]    ; 0=fault, 1=ok
        adcs2_struct1.motor_hall_state1 =  data[pindex+197]     ; [none]
        adcs2_struct1.motor_hall_state2 =  data[pindex+198]     ; [none]
        adcs2_struct1.motor_hall_state3 =  data[pindex+199]     ; [none]
        adcs2_struct1.wheel_pwm_enable1 =  data[pindex+200]     ; 1=yes, 0=no
        adcs2_struct1.wheel_pwm_enable2 =  data[pindex+201]     ; 1=yes, 0=no
        adcs2_struct1.wheel_pwm_enable3 =  data[pindex+202]     ; 1=yes, 0=no
        adcs2_struct1.wheel_pwm_direction1 = data[pindex+203]  ; 0=pos, 1=neg
        adcs2_struct1.wheel_pwm_direction2 = data[pindex+204]  ; 0=pos, 1=neg
        adcs2_struct1.wheel_pwm_direction3 = data[pindex+205]  ; 0=pos, 1=neg
        adcs2_struct1.wheel_pwm_commanded_direction1 = data[pindex+206] ; 0=pos, 1=neg
        adcs2_struct1.wheel_pwm_commanded_direction2 = data[pindex+207] ; 0=pos, 1=neg
        adcs2_struct1.wheel_pwm_commanded_direction3 = data[pindex+208] ; 0=pos, 1=neg

        if (adcs2_count eq 0) then adcs2 = replicate(adcs2_struct1, N_CHUNKS) else $
          if adcs2_count ge n_elements(adcs2) then adcs2 = [adcs2, replicate(adcs2_struct1, N_CHUNKS)]
        adcs2[adcs2_count] = adcs2_struct1
        adcs2_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_ADCS3) then begin
      ;
      ;  ************************
      ;  ADCS-3 Packet (if user asked for it)
      ;
      ; Note that (BCT XACT Offset - 370) is the value to use with pindex for the ADCS3 variables
      ;  ************************
      ;
      if arg_present(adcs3) then begin
        adcs3_struct1.apid = packet_id_full  ; keep Playback bit in structure
        adcs3_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        adcs3_struct1.seq_count = packet_seq_count
        adcs3_struct1.data_length = packet_length
        adcs3_struct1.time = packet_time   ; millisec (0.1 msec resolution)
        adcs3_struct1.SpareByte = (long(data[pindex+209])) ;None
        adcs3_struct1.checkbytes = long(data[pindex+210]) + ishft(long(data[pindex+211]),8)
        adcs3_struct1.SyncWord = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8))  ; None
        adcs3_struct1.cdh_info = (long(data[pindex+12]))
        adcs3_struct1.adcs_info = (long(data[pindex+13]))
        adcs3_struct1.adcs_group = long(data[pindex+14]) + ishft(long(data[pindex+15]),8)

        IF keyword_set(EXPORT_RAW_ADCS_TLM) THEN adcs3Raw = data[pindex + 16:pindex + 208]

        adcs3_struct1.tracker_attitude1 = (ishft(long(data[pindex+16]),24) + ishft(long(data[pindex+17]),16) $
                                        +  ishft(long(data[pindex+18]),8 ) +       long(data[pindex+19])) * 4.88E-10
        adcs3_struct1.tracker_attitude2 = (ishft(long(data[pindex+20]),24) + ishft(long(data[pindex+21]),16) $
                                        +  ishft(long(data[pindex+22]),8 ) +       long(data[pindex+23])) * 4.88E-10
        adcs3_struct1.tracker_attitude3 = (ishft(long(data[pindex+24]),24) + ishft(long(data[pindex+25]),16) $
                                        +  ishft(long(data[pindex+26]),8 ) +       long(data[pindex+27])) * 4.88E-10
        adcs3_struct1.tracker_attitude4 = (ishft(long(data[pindex+28]),24) + ishft(long(data[pindex+29]),16) $
                                        +  ishft(long(data[pindex+30]),8 ) +       long(data[pindex+31])) * 4.88E-10
        adcs3_struct1.tracker_rate1 = (ishft(fix(data[pindex+32]),8) + fix(data[pindex+33])) * 2.5E-6
        adcs3_struct1.tracker_rate2 = (ishft(fix(data[pindex+34]),8) + fix(data[pindex+35])) * 2.5E-6
        adcs3_struct1.tracker_rate3 = (ishft(fix(data[pindex+36]),8) + fix(data[pindex+37])) * 2.5E-6
        adcs3_struct1.tracker_RA = (ishft(uint(data[pindex+38]),8) + uint(data[pindex+39])) * 0.0055
        adcs3_struct1.tracker_declination = (ishft(uint(data[pindex+40]),8) + uint(data[pindex+41])) * 0.0055
        adcs3_struct1.tracker_roll = (ishft(uint(data[pindex+42]),8) + uint(data[pindex+43])) * 0.0055
        adcs3_struct1.tracker_detector_temp = data[pindex+44] * 0.80000001
        adcs3_struct1.tracker_covariance_amp = (ishft(fix(data[pindex+45]), 8) + fix(data[pindex+46])) * 3.2E-10
        adcs3_struct1.tracker_covariance_matrix1 = (ishft(fix(data[pindex+47]), 8) + fix(data[pindex+48])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix2 = (ishft(fix(data[pindex+49]), 8) + fix(data[pindex+50])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix3 = (ishft(fix(data[pindex+51]), 8) + fix(data[pindex+52])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix4 = (ishft(fix(data[pindex+53]), 8) + fix(data[pindex+54])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix5 = (ishft(fix(data[pindex+55]), 8) + fix(data[pindex+56])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix6 = (ishft(fix(data[pindex+57]), 8) + fix(data[pindex+58])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix7 = (ishft(fix(data[pindex+59]), 8) + fix(data[pindex+60])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix8 = (ishft(fix(data[pindex+61]), 8) + fix(data[pindex+62])) * 3.2E-5
        adcs3_struct1.tracker_covariance_matrix9 = (ishft(fix(data[pindex+63]), 8) + fix(data[pindex+64])) * 3.2E-5
        adcs3_struct1.tracker_max_residual = data[pindex+65]
        adcs3_struct1.tracker_max_residual_first_pass = data[pindex+66]
        adcs3_struct1.tracker_analog_gain = data[pindex+67] * 0.5
        adcs3_struct1.tracker_magnitude_correction = data[pindex+68] * 0.01
        adcs3_struct1.detector_temp_command = data[pindex+69] * 0.80000001
        adcs3_struct1.tracker_bright_magnitude_limit = data[pindex+70] * 0.039999999
        adcs3_struct1.tracker_dim_magnitude_limit = data[pindex+71] * 0.039999999
        adcs3_struct1.tracker_tec_duty_cycle = data[pindex+72] * 0.004
        adcs3_struct1.tracker_peak_3sigma_noise = data[pindex+73] * 4
        adcs3_struct1.tracker_peak_mean_background = data[pindex+74] * 4
        adcs3_struct1.tracker_median_3sigma_noise = data[pindex+75] * 4
        adcs3_struct1.tracker_median_mean_background = data[pindex+76] * 4
        adcs3_struct1.tracker_operating_mode = data[pindex+77]
        adcs3_struct1.tracker_star_id_step = data[pindex+78]
        adcs3_struct1.tracker_star_id_status = data[pindex+79]
        adcs3_struct1.tracker_star_id_status_saved = data[pindex+80]
        adcs3_struct1.tracker_attitude_status = data[pindex+81]
        adcs3_struct1.tracker_rate_estimated_status = data[pindex+82]
        adcs3_struct1.tracker_rate_aid_status = data[pindex+83]
        adcs3_struct1.tracker_velocity_aid_status = data[pindex+84]
        adcs3_struct1.tracker_attitude_aid_status = data[pindex+85]
        adcs3_struct1.tracker_vector_aid_status = data[pindex+86]
        adcs3_struct1.tracker_time_tag = ishft(ulong(data[pindex+87]),24) + ishft(ulong(data[pindex+88]),16) $
                                      +  ishft(ulong(data[pindex+89]),8 ) +       ulong(data[pindex+90])
        adcs3_struct1.tracker_num_id_patterns_tried = ishft(ulong(data[pindex+91]),24) + ishft(ulong(data[pindex+92]),16) $
                                                   +  ishft(ulong(data[pindex+93]),8 ) +       ulong(data[pindex+94])
        adcs3_struct1.tracker_pixel_amplitude_threshold = data[pindex+95] * 4
        adcs3_struct1.tracker_amplitude_offset = data[pindex+96]
        adcs3_struct1.tracker_current_tint = ishft(ulong(data[pindex+97]),24) + ishft(ulong(data[pindex+98]),16) $
                                          + ishft(ulong(data[pindex+99]),8 ) +       ulong(data[pindex+100])
        adcs3_struct1.tracker_maximum_residual_id = ishft(uint(data[pindex+101]),8) + uint(data[pindex+102])
        adcs3_struct1.tracker_max_residual_id_first_pass = ishft(uint(data[pindex+103]),8) + uint(data[pindex+104])
        adcs3_struct1.tracker_max_background_level = ishft(uint(data[pindex+105]),8) + uint(data[pindex+106])
        adcs3_struct1.tracker_num_pixel_groups = data[pindex+107]
        adcs3_struct1.tracker_star_id_tolerance = data[pindex+108]
        adcs3_struct1.tracker_num_attitude_loops = data[pindex+109]
        adcs3_struct1.num_stars_used_in_attitude = data[pindex+110]
        adcs3_struct1.num_stars_high_residual = data[pindex+111]
        adcs3_struct1.tracker_auto_black_enable = data[pindex+112]
        adcs3_struct1.tracker_black_level = data[pindex+113]
        adcs3_struct1.num_stars_on_fov = data[pindex+114]
        adcs3_struct1.tracker_num_track_blocks_issued = data[pindex+115]
        adcs3_struct1.num_tracked_stars = data[pindex+116]
        adcs3_struct1.num_id_stars = data[pindex+117]
        adcs3_struct1.tracker_fsw_counter = data[pindex+118]
        adcs3_struct1.auto_track_from_star_id = data[pindex+119]
        adcs3_struct1.tracker_auto_integration_adjust = data[pindex+120]
        adcs3_struct1.tracker_auto_gain_adjust = data[pindex+121]
        adcs3_struct1.tracker_test_mode = data[pindex+122]
        adcs3_struct1.tracker_fpga_detector_timeout = data[pindex+123]
        adcs3_struct1.tracker_tec_enabled = data[pindex+124]
        adcs3_struct1.tracker_store_sequential_images = data[pindex+125]
        adcs3_struct1.tracker_track_ref_available = data[pindex+126]
        adcs3_struct1.num_bright_stars = data[pindex+127]
        adcs3_struct1.attitude_error1 = (ishft(long(data[pindex+128]),24) + ishft(long(data[pindex+129]),16) $
                                     +  ishft(long(data[pindex+130]),8 ) +       long(data[pindex+131])) * 2.0E-9
        adcs3_struct1.attitude_error2 = (ishft(long(data[pindex+132]),24) + ishft(long(data[pindex+133]),16) $
                                     +  ishft(long(data[pindex+134]),8 ) +       long(data[pindex+135])) * 2.0E-9
        adcs3_struct1.attitude_error3 = (ishft(long(data[pindex+136]),24) + ishft(long(data[pindex+137]),16) $
                                     +  ishft(long(data[pindex+138]),8 ) +       long(data[pindex+139])) * 2.0E-9
        adcs3_struct1.rate_error1 = (ishft(long(data[pindex+140]),24) + ishft(long(data[pindex+141]),16) $
                                 +  ishft(long(data[pindex+142]),8 ) +       long(data[pindex+143])) * 5.0E-9
        adcs3_struct1.rate_error2 = (ishft(long(data[pindex+144]),24) + ishft(long(data[pindex+145]),16) $
                                 +  ishft(long(data[pindex+146]),8 ) +       long(data[pindex+147])) * 5.0E-9
        adcs3_struct1.rate_error3 = (ishft(long(data[pindex+148]),24) + ishft(long(data[pindex+149]),16) $
                                 +  ishft(long(data[pindex+150]),8 ) +       long(data[pindex+151])) * 5.0E-9
        adcs3_struct1.integral_error1 = (ishft(fix(data[pindex+152]),8) + fix(data[pindex+153])) * 1.0E-5
        adcs3_struct1.integral_error2 = (ishft(fix(data[pindex+154]),8) + fix(data[pindex+155])) * 1.0E-5
        adcs3_struct1.integral_error3 = (ishft(fix(data[pindex+156]),8) + fix(data[pindex+157])) * 1.0E-5
        adcs3_struct1.commanded_rate_lim1 = (ishft(uint(data[pindex+158]),8) + uint(data[pindex+159])) * 0.0002
        adcs3_struct1.commanded_rate_lim2 = (ishft(uint(data[pindex+160]),8) + uint(data[pindex+161])) * 0.0002
        adcs3_struct1.commanded_rate_lim3 = (ishft(uint(data[pindex+162]),8) + uint(data[pindex+163])) * 0.0002
        adcs3_struct1.commanded_accel_lim1 = (ishft(uint(data[pindex+164]),8) + uint(data[pindex+165])) * 0.0002
        adcs3_struct1.commanded_accel_lim2 = (ishft(uint(data[pindex+166]),8) + uint(data[pindex+167])) * 0.0002
        adcs3_struct1.commanded_accel_lim3 = (ishft(uint(data[pindex+168]),8) + uint(data[pindex+169])) * 0.0002
        adcs3_struct1.feedback_control_torque1 = (ishft(fix(data[pindex+170]),8) + fix(data[pindex+171])) * 2.0E-7
        adcs3_struct1.feedback_control_torque2 = (ishft(fix(data[pindex+172]),8) + fix(data[pindex+173])) * 2.0E-7
        adcs3_struct1.feedback_control_torque3 = (ishft(fix(data[pindex+174]),8) + fix(data[pindex+175])) * 2.0E-7
        adcs3_struct1.total_torque_command1 = (ishft(fix(data[pindex+176]),8) + fix(data[pindex+177])) * 2.0E-7
        adcs3_struct1.total_torque_command2 = (ishft(fix(data[pindex+178]),8) + fix(data[pindex+179])) * 2.0E-7
        adcs3_struct1.total_torque_command3 = (ishft(fix(data[pindex+180]),8) + fix(data[pindex+181])) * 2.0E-7
        adcs3_struct1.time_into_sun_search = ishft(uint(data[pindex+182]),8) + uint(data[pindex+183])
        adcs3_struct1.sun_search_wait_timer = ishft(uint(data[pindex+184]),8) + uint(data[pindex+185])
        adcs3_struct1.sun_point_angle_error = (ishft(uint(data[pindex+186]),8) + uint(data[pindex+187])) * 0.003
        adcs3_struct1.sun_point_state = data[pindex+188]
        adcs3_struct1.attitude_control_gain_index = data[pindex+189]
        adcs3_struct1.system_momentum1 = (ishft(fix(data[pindex+190]),8) + fix(data[pindex+191])) * 0.0002
        adcs3_struct1.system_momentum2 = (ishft(fix(data[pindex+192]),8) + fix(data[pindex+193])) * 0.0002
        adcs3_struct1.system_momentum3 = (ishft(fix(data[pindex+194]),8) + fix(data[pindex+195])) * 0.0002
        adcs3_struct1.wheel1_momentum_in_body = (ishft(fix(data[pindex+196]),8) + fix(data[pindex+197])) * 0.0002
        adcs3_struct1.wheel2_momentum_in_body = (ishft(fix(data[pindex+198]),8) + fix(data[pindex+199])) * 0.0002
        adcs3_struct1.wheel3_momentum_in_body = (ishft(fix(data[pindex+200]),8) + fix(data[pindex+201])) * 0.0002
        adcs3_struct1.body_only_momentum_in_body1 = (ishft(fix(data[pindex+202]),8) + fix(data[pindex+202])) * 0.0002
        adcs3_struct1.body_only_momentum_in_body2 = (ishft(fix(data[pindex+204]),8) + fix(data[pindex+205])) * 0.0002
        adcs3_struct1.body_only_momentum_in_body3 = (ishft(fix(data[pindex+206]),8) + fix(data[pindex+207])) * 0.0002
        adcs3_struct1.tr1_duty_cycle = data[pindex+208]


        if (adcs3_count eq 0) then adcs3 = replicate(adcs3_struct1, N_CHUNKS) else $
          if adcs3_count ge n_elements(adcs3) then adcs3 = [adcs3, replicate(adcs3_struct1, N_CHUNKS)]
        adcs3[adcs3_count] = adcs3_struct1
        adcs3_count += 1
      endif

    endif else if (packet_id eq PACKET_ID_ADCS4) then begin
      ;
      ;  ************************
      ;  ADCS-4 Packet (if user asked for it)
      ;
      ; Note that (BCT XACT Offset - 563) is the value to use with pindex for the ADCS4 variables
      ;  ************************
      ;
      if arg_present(adcs4) then begin
        adcs4_struct1.apid = packet_id_full  ; keep Playback bit in structure
        adcs4_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        adcs4_struct1.seq_count = packet_seq_count
        adcs4_struct1.data_length = packet_length
        adcs4_struct1.time = packet_time   ; millisec (0.1 msec resolution)
        adcs4_struct1.checkbytes = long(data[pindex+210]) + ishft(long(data[pindex+211]),8)
        adcs4_struct1.SyncWord = (long(data[pindex+212]) + ishft(long(data[pindex+213]),8))
        adcs4_struct1.cdh_info = data[pindex+12]
        adcs4_struct1.adcs_info = data[pindex+13]
        adcs4_struct1.adcs_group = (uint(data[pindex+14]) + ishft(uint(data[pindex+15]),8))

        IF keyword_set(EXPORT_RAW_ADCS_TLM) THEN adcs4Raw = data[pindex + 16:pindex + 159]

        adcs4_struct1.tr2_duty_cycle = data[pindex+16]
        adcs4_struct1.tr3_duty_cycle = data[pindex+17]
        adcs4_struct1.tr_torqueX = ( ishft(fix(data[pindex+18]),8) + fix(data[pindex+19]) ) * 2.0E-8
        adcs4_struct1.tr_torqueY = ( ishft(fix(data[pindex+20]),8) + fix(data[pindex+21]) ) * 2.0E-8
        adcs4_struct1.tr_torqueZ = ( ishft(fix(data[pindex+22]),8) + fix(data[pindex+23]) ) * 2.0E-8
        adcs4_struct1.tr1_ctrlmode = data[pindex+24]
        adcs4_struct1.tr2_ctrlmode = data[pindex+25]
        adcs4_struct1.tr3_ctrlmode = data[pindex+26]
        adcs4_struct1.mag_sourcesetting = data[pindex+27]
        adcs4_struct1.mag_source = data[pindex+28]
        adcs4_struct1.mom_vectorvalid = data[pindex+29]
        adcs4_struct1.mom_vectorenabled = data[pindex+30]
        adcs4_struct1.tr1_enable = data[pindex+31]
        adcs4_struct1.tr2_enable = data[pindex+32]
        adcs4_struct1.tr3_enable = data[pindex+33]
        adcs4_struct1.tr1_dir = data[pindex+34]
        adcs4_struct1.tr2_dir = data[pindex+35]
        adcs4_struct1.tr3_dir = data[pindex+36]
        adcs4_struct1.sunbody_X = ( ishft(fix(data[pindex+37]),8) + fix(data[pindex+38]) ) * 1.0E-4
        adcs4_struct1.sunbody_Y = ( ishft(fix(data[pindex+39]),8) + fix(data[pindex+40]) ) * 1.0E-4
        adcs4_struct1.sunbody_Z = ( ishft(fix(data[pindex+41]),8) + fix(data[pindex+42]) ) * 1.0E-4
        adcs4_struct1.sunbody_status = data[pindex+43]
        adcs4_struct1.sunsensor_used = data[pindex+44]
        adcs4_struct1.sunsensor_data1 = ( ishft(uint(data[pindex+45]),8) + uint(data[pindex+46]) )
        adcs4_struct1.sunsensor_data2 = ( ishft(uint(data[pindex+47]),8) + uint(data[pindex+48]) )
        adcs4_struct1.sunsensor_data3 = ( ishft(uint(data[pindex+49]),8) + uint(data[pindex+50]) )
        adcs4_struct1.sunsensor_data4 = ( ishft(uint(data[pindex+51]),8) + uint(data[pindex+52]) )
        adcs4_struct1.sunvector_enabled = data[pindex+53]
        adcs4_struct1.mag_bodyX = ( ishft(fix(data[pindex+54]),8) + fix(data[pindex+55]) ) * 5.0E-9
        adcs4_struct1.mag_bodyY = ( ishft(fix(data[pindex+56]),8) + fix(data[pindex+57]) ) * 5.0E-9
        adcs4_struct1.mag_bodyZ = ( ishft(fix(data[pindex+58]),8) + fix(data[pindex+59]) ) * 5.0E-9
        adcs4_struct1.mag_compTemp = ( ishft(fix(data[pindex+60]),8) + fix(data[pindex+61]) ) * 0.005
        adcs4_struct1.mag_data1 = ( ishft(uint(data[pindex+62]),8) + uint(data[pindex+63]) )
        adcs4_struct1.mag_data2 = ( ishft(uint(data[pindex+64]),8) + uint(data[pindex+65]) )
        adcs4_struct1.mag_data3 = ( ishft(uint(data[pindex+66]),8) + uint(data[pindex+67]) )
        adcs4_struct1.mag_valid = data[pindex+68]
        adcs4_struct1.temp_used = data[pindex+69]
        adcs4_struct1.imu_rate1 = ( ishft(fix(data[pindex+70]),8) + fix(data[pindex+71]) ) * 1.0E-5
        adcs4_struct1.imu_rate2 = ( ishft(fix(data[pindex+72]),8) + fix(data[pindex+73]) ) * 1.0E-5
        adcs4_struct1.imu_rate3 = ( ishft(fix(data[pindex+74]),8) + fix(data[pindex+75]) ) * 1.0E-5
        adcs4_struct1.imu_body_rate1 = ( ishft(fix(data[pindex+76]),8) + fix(data[pindex+77]) ) * 1.0E-5
        adcs4_struct1.imu_body_rate2 = ( ishft(fix(data[pindex+78]),8) + fix(data[pindex+79]) ) * 1.0E-5
        adcs4_struct1.imu_body_rate3 = ( ishft(fix(data[pindex+80]),8) + fix(data[pindex+81]) ) * 1.0E-5
        adcs4_struct1.imu_body_time = ishft(ulong(data[pindex+82]),24) + ishft(ulong(data[pindex+83]),16) $
                                    + ishft(ulong(data[pindex+84]),8) + ulong(data[pindex+85])
        adcs4_struct1.imu_first_rate1 = ishft(fix(data[pindex+86]),8) + fix(data[pindex+87])
        adcs4_struct1.imu_first_rate2 = ishft(fix(data[pindex+88]),8) + fix(data[pindex+89])
        adcs4_struct1.imu_first_rate3 = ishft(fix(data[pindex+90]),8) + fix(data[pindex+91])
        adcs4_struct1.imu_pkt_count = data[pindex+92]
        adcs4_struct1.imu_first_id = data[pindex+93]
        adcs4_struct1.imu_rate_valid = data[pindex+94]
        adcs4_struct1.counts_per_sec = ishft(ulong(data[pindex+95]),24) + ishft(ulong(data[pindex+96]),16) $
                                      + ishft(ulong(data[pindex+97]),8) + ulong(data[pindex+98])
        adcs4_struct1.high_run_cnt = ishft(ulong(data[pindex+99]),24) + ishft(ulong(data[pindex+100]),16) $
                                   + ishft(ulong(data[pindex+101]),8) + ulong(data[pindex+102])
        adcs4_struct1.high_time = ishft(ulong(data[pindex+103]),24) + ishft(ulong(data[pindex+104]),16) $
                                + ishft(ulong(data[pindex+105]),8) + ulong(data[pindex+106])
        adcs4_struct1.high_cycle_num = ishft(ulong(data[pindex+107]),24) + ishft(ulong(data[pindex+108]),16) $
                                     + ishft(ulong(data[pindex+109]),8) + ulong(data[pindex+110])
        adcs4_struct1.vhigh_cycle_num = ishft(ulong(data[pindex+111]),24) + ishft(ulong(data[pindex+112]),16) $
                                      + ishft(ulong(data[pindex+113]),8) + ulong(data[pindex+114])
        adcs4_struct1.high_1msec = data[pindex+115]
        adcs4_struct1.high_2msec = data[pindex+116]
        adcs4_struct1.high_3msec = data[pindex+117]
        adcs4_struct1.high_4msec = data[pindex+118]
        adcs4_struct1.high_5msec = data[pindex+119]
        adcs4_struct1.pay_sun_bodyX = ( ishft(fix(data[pindex+120]),8) + fix(data[pindex+121]) ) * 1.0E-4
        adcs4_struct1.pay_sun_bodyY = ( ishft(fix(data[pindex+122]),8) + fix(data[pindex+123]) ) * 1.0E-4
        adcs4_struct1.pay_sun_bodyZ = ( ishft(fix(data[pindex+124]),8) + fix(data[pindex+125]) ) * 1.0E-4
        adcs4_struct1.pay_cmd_data1 = ( ishft(fix(data[pindex+126]),8) + fix(data[pindex+127]) )
        adcs4_struct1.pay_cmd_data2 = ( ishft(fix(data[pindex+128]),8) + fix(data[pindex+129]) )
        adcs4_struct1.pay_sun_valid = data[pindex+130]
        adcs4_struct1.tlm_map_id = data[pindex+131]
        adcs4_struct1.volt_5p0 = ( uint(data[pindex+132]) ) * 0.025
        adcs4_struct1.volt_3p3 = ( uint(data[pindex+133]) ) * 0.015
        adcs4_struct1.volt_2p5 = ( uint(data[pindex+134]) ) * 0.015
        adcs4_struct1.volt_1p8 = ( uint(data[pindex+135]) ) * 0.015
        adcs4_struct1.volt_1p0 = ( uint(data[pindex+136]) ) * 0.015
        adcs4_struct1.rw1_temp = ( ishft(fix(data[pindex+137]),8) + fix(data[pindex+138]) ) * 0.005
        adcs4_struct1.rw2_temp = ( ishft(fix(data[pindex+139]),8) + fix(data[pindex+140]) ) * 0.005
        adcs4_struct1.rw3_temp = ( ishft(fix(data[pindex+141]),8) + fix(data[pindex+142]) ) * 0.005
        adcs4_struct1.volt_12v_bus = ( ishft(uint(data[pindex+143]),8) + uint(data[pindex+144]) ) * 0.001
        adcs4_struct1.data_checksum = ishft(uint(data[pindex+145]),8) + uint(data[pindex+146])
        adcs4_struct1.table_length = ishft(uint(data[pindex+147]),8) + uint(data[pindex+148])
        adcs4_struct1.table_offset = ishft(uint(data[pindex+149]),8) + uint(data[pindex+150])
        adcs4_struct1.table_upload_status = data[pindex+151]
        adcs4_struct1.which_table = data[pindex+152]
        adcs4_struct1.st_valid = data[pindex+153]
        adcs4_struct1.st_use_enable = data[pindex+154]
        adcs4_struct1.st_exceed_max_background = data[pindex+155]
        adcs4_struct1.st_exceed_max_rotation = data[pindex+156]
        adcs4_struct1.st_exceed_min_sun = data[pindex+157]
        adcs4_struct1.st_exceed_min_earth = data[pindex+158]
        adcs4_struct1.st_exceed_min_moon = data[pindex+159]
        ; NEW for FM2 are five new variables added by CDH (so little-endian)
        adcs4_struct1.sd_adcs_write_offset = ( long(data[pindex+168]) + ishft(long(data[pindex+169]),8) + $
                            ishft(long(data[pindex+170]),16) + ishft(long(data[pindex+171]),24))
        adcs4_struct1.cruciform_scan_index = ( fix(data[pindex+172]) + ishft(fix(data[pindex+173]),8) )
        adcs4_struct1.cruciform_scan_x_steps = ( fix(data[pindex+174]) + ishft(fix(data[pindex+175]),8) )
        adcs4_struct1.cruciform_scan_y_steps = ( fix(data[pindex+176]) + ishft(fix(data[pindex+177]),8) )
        adcs4_struct1.cruciform_scan_dwell_period = ( fix(data[pindex+178]) + ishft(fix(data[pindex+179]),8) )

        if (adcs4_count eq 0) then adcs4 = replicate(adcs4_struct1, N_CHUNKS) else $
          if adcs4_count ge n_elements(adcs4) then adcs4 = [adcs4, replicate(adcs4_struct1, N_CHUNKS)]
          adcs4[adcs4_count] = adcs4_struct1
          adcs4_count += 1
      endif
    endif else if (packet_id eq PACKET_ID_IMAGE) then begin
      ;
      ;  ************************
      ;  XACT Image (Image) Packet (if user asked for it)
      ;  ************************
      ;
      if arg_present(xactimage) then begin

        xactimage_struct1.apid = packet_id_full  ; keep Playback bit in structure
        xactimage_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
        xactimage_struct1.seq_count = packet_seq_count
        xactimage_struct1.data_length = packet_length
        xactimage_struct1.time = packet_time   ; millisec (0.1 msec resolution)

        ; CDH State (MSN) and SC Mode Bitfields (LSN) (Secondary Header Userdata)
        xactimage_struct1.cdh_info = (long(data[pindex+12]))

        ; Sun Point Status (MSN) and ADCS Mode (LSN) (Secondary Header Userdata)
        xactimage_struct1.adcs_info = (long(data[pindex+13]))

        ; Increments for each Image Row (0x0000-0x03FF, 0-1023),
        ;  Note: upper nibble is 0 for Table, 1-15 for Image Number
        xactimage_struct1.image_row = long(data[pindex+14]) + ishft(long(data[pindex+15]),8)

        ; Increments for each Row group (0-13 Image, 0-31 over VLB for Table)
        xactimage_struct1.row_group =  long(data[pindex+16]) + ishft(long(data[pindex+17]),8)

        ;loop to store the XACT Image
        FOR i = 0, xactimage_DATA_LEN - 1 DO BEGIN
          ; XACT IMG - Data/VideoLine Buffer Contents - 128 bytes
          xactimage_struct1.image_data[i] = ((data[pindex+18+i]))
        ENDFOR

    ; Checksum for all of the data in the packet
        xactimage_struct1.checksum = long(data[pindex+146]) + ishft(long(data[pindex+147]),8)
        ; Sync word for the packet
        xactimage_struct1.SyncWord = (long(data[pindex+148]) + ishft(long(data[pindex+149]),8))

        if (xactimage_count eq 0) then xactimage = replicate(xactimage_struct1, N_CHUNKS) else $
          if xactimage_count ge n_elements(xactimage) then xactimage = [xactimage, replicate(xactimage_struct1, N_CHUNKS)]
        xactimage[xactimage_count] = xactimage_struct1
        xactimage_count += 1
      endif

    endif

    ; increment index to start next packet search
    index = index2
  endif else begin
    ;  increment index and keep looking for Sync word
    index += 1
  endelse
endwhile

; Eliminate excess length in packets
if arg_present(hk) and n_elements(hk) ne 0 then hk = hk[0:hk_count-1]
if arg_present(log) and n_elements(log) ne 0 then log = log[0:log_count-1]
if arg_present(diag) and n_elements(diag) ne 0 then diag = diag[0:diag_count-1]
if arg_present(sci) and n_elements(sci) ne 0 then sci = sci[0:sci_count-1]
if arg_present(xactimage) and n_elements(xactimage) ne 0 then xactimage = xactimage[0:xactimage_count-1]
if arg_present(adcs1) and n_elements(adcs1) ne 0 then adcs1 = adcs1[0:adcs1_count-1]
if arg_present(adcs2) and n_elements(adcs2) ne 0 then adcs2 = adcs2[0:adcs2_count-1]
if arg_present(adcs3) and n_elements(adcs3) ne 0 then adcs3 = adcs3[0:adcs3_count-1]
if arg_present(adcs4) and n_elements(adcs4) ne 0 then adcs4 = adcs4[0:adcs4_count-1]

; Determine flight model from HK data, or -1 if no HK data found
fm = 0 & timeIndex = 0
WHILE fm EQ 0 DO BEGIN
  fm = (hk_count gt 0) ? hk[timeIndex].flight_model : -1
  IF timeIndex EQ n_elements(hk) - 1 THEN BEGIN
    message, /INFO, systime() + ' Flight model for entire packet reads 0, that is weird.'
    BREAK
  ENDIF
  timeIndex++
ENDWHILE

IF keyword_set(EXPORT_RAW_ADCS_TLM) THEN BEGIN
  IF typename(input) EQ 'STRING' THEN BEGIN
    IF adcs1Raw NE !NULL OR adcs2Raw NE !NULL OR adcs3Raw NE !NULL OR adcs4Raw NE !NULL THEN BEGIN
      inputStringParsed = ParsePathAndFilename(input)
      file_copy, input, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/xact_tlm_exported/' + inputStringParsed.Filename, /overwrite
    ENDIF
  ENDIF
ENDIF

if keyword_set(verbose) then begin
  if (hk_count gt 0) then  print, 'Number of HK   Packets = ', hk_count
  if (log_count gt 0) then print, 'Number of LOG  Packets = ', log_count
  if (diag_count gt 0) then print,'Number of DIAG Packets = ', diag_count
  if (sci_count gt 0) then print, 'Number of SCI  Packets = ', sci_count
  if (xactimage_count gt 0) then print, 'Number of XACTIMAGE  Packets = ', xactimage_count
  if (adcs1_count gt 0) then     print, 'Number of ADCS-1     Packets = ', adcs1_count
  if (adcs2_count gt 0) then     print, 'Number of ADCS-2     Packets = ', adcs2_count
  if (adcs3_count gt 0) then     print, 'Number of ADCS-3     Packets = ', adcs3_count
  if (adcs4_count gt 0) then     print, 'Number of ADCS-4     Packets = ', adcs4_count
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