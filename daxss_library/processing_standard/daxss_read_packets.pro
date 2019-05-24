;+
; NAME:
;   daxss_read_packets
;
; PURPOSE:
;   Read, interpret, and store in IDL structures the packets from binary file from DAXSS CubeSat.
;   These can come from either ISIS or DataView.
;
; USAGE
;   daxss_read_packets, input, sci=sci, log=log, dump=dump, /hexdump, /verbose
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
;   EXPORT_RAW_ADCS_TLM: Option to export the ISIS telemetry file to a dedicated folder for BCT (daxss_data/fm*/xact_exported_data)
;   KISS:                Option to deal with KISS-formatted input
;   HAM_HEADER:          Set ths to allow for KISS headers but don't perform KISS decoding -- intended for use with the python beacon decoder software.
;                        Will automatically set this if the telemetry file path or name contains the string "ham".
;
; OUTPUTS:
;   sci [structure]:          Return array of science (X123, SPS, XPS data) packets
;                             **OR** -1 if science packet incomplete (for single-packet reader mode)
;   log [structure];          Return array of log messages
;   dump [structure]:    	  Return array of dump (param table) packets
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to DAXSS binary data and DAXSS code package
;
; MODIFICATION HISTORY:
;	2019-05-13	Tom Woods		Created daxss_read_packets from minsxss_read_packets
;								Removed ADCS, XACT_IMAGE, HK, and KISS.
;								Only have SCI, LOG, and dump packets.
;
;
;+
pro daxss_read_packets, input, sci=sci, log=log, dump=dump, hexdump=hexdump, fm=fm, VERBOSE=VERBOSE, $
                         DEBUG=DEBUG, _extra=_extra

  ; Clear any values present in the output variables, needed since otherwise the input values get returned when these packet types are missing from the input file
  junk = temporary(sci)
  junk = temporary(log)
  junk = temporary(dump)

  ; Define initial quantum of packet array length
  N_CHUNKS = 500

  if (n_params() lt 1) then begin
    print, 'USAGE: daxss_read_packets, input_file, sci=sci, log=log, dump=dump, $'
    print, '              				fm=fm, /hexdump, /verbose, /debug'
    input=' '
  endif
  IF size(input[0], /TYPE) EQ 7 THEN if (strlen(input) lt 2) then begin
    ; find file to read
    input = dialog_pickfile(/read, title='Select DAXSS dump file to read', filter='daxss_*')
    if (strlen(input) lt 2) then return   ; user did not select file
  endif

  ;  force VERBOSE if debug is provided
  if keyword_set(debug) then begin
  	verbose=1
  	doDebug = debug
  endif else doDebug = 0

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
  ; This is a kludge so the code below won't skip the first packet...
  IF ~(data[0] EQ SYNC_BYTE1 AND data[1] EQ SYNC_BYTE2) THEN data = [SYNC_BYTE1, SYNC_BYTE2, data]

  CCSDS_BYTE1 = byte('08'X)
  CCSDS_BYTE5 = byte('00'X)

 ; APIDs are defined for DAXSS by InspireSat-1 team
  PACKET_ID_LOG = 176	; 0xB0
  PACKET_ID_DUMP = 177	; 0xB1
  PACKET_ID_SCI = 178	; 0xB2

  ; DAXSS does NOT have Playback option at the instrument level
  ;PACKET_ID_LOG_PLAYBACK = PACKET_ID_LOG + '40'X
  ;PACKET_ID_DUMP_PLAYBACK = PACKET_ID_DUMP + '40'X
  ;PACKET_ID_SCI_PLAYBACK = PACKET_ID_SCI + '40'X

  ;  doPause allows interactive flow of printing for the Hex Dump option
  if keyword_set(hexdump) then doPause = 1 else doPause = 0

  ;
  ; Log Message (LOG) Packet Structure definition
  ;
  log_count = 0L
  log_struct1 = { apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0, $
    cdh_info: 0U, $
    cdh_state: 0B, spacecraft_mode: 0B, eclipse_state: 0B, $
    cmd_last_opcode: 0, cmd_last_status: 0, cmd_accept_count: 0L, cmd_reject_count: 0L, $
    param_set_header: 0,  cdh_enables: 0U, $
    enable_sps: 0B, enable_x123: 0B, enable_inst_heater: 0B, enable_sdcard: 0B, $
    cdh_temp: 0.0, sps_sum_rate: 0.D0, sps_x: 0.0, sps_y: 0.0, $
	X123_Fast_Count_Norm: 0L, X123_Slow_Count_Norm: 0L, X123_Accum_Time: 0L, X123_Det_Temp: 0, $
	log_spares: 0,  message: ' ', $
	checkbytes: 0L, SyncWord: 0.0, $
    checkbytes_calculated: 0L, checkbytes_valid: 1B  }


  ;
  ; Memory Dump / Parameter Table (DUMP) Packet Structure definition
  ;
  dump_count = 0L
  DUMP_ARRAY_NUM = 64
  dump_struct1 = { apid: 0, seq_flag: 0, seq_count: 0, data_length: 0L, time: 0.0D0, $
    cdh_info: 0U, $
    cdh_state: 0B, spacecraft_mode: 0B, eclipse_state: 0B, $
    cmd_last_opcode: 0, cmd_last_status: 0, cmd_accept_count: 0L, cmd_reject_count: 0L, $
    param_set_header: 0,  cdh_enables: 0U, $
    enable_sps: 0B, enable_x123: 0B, enable_inst_heater: 0B, enable_sdcard: 0B, $
	dump_spares: 0UL, dump_data: uintarr(DUMP_ARRAY_NUM), $
	checkbytes: 0L, SyncWord: 0.0, $
    checkbytes_calculated: 0L, checkbytes_valid: 1B  }

  ;
  ; Sci message (SCI) Packet Structure definition
  ;
  X123_SPECTRUM_BINS = 1024L
  X123_SPECTRUM_LENGTH = X123_SPECTRUM_BINS*3L
  X123_FIRST_LENGTH = 78L    ; was 168 for MinXSS
  X123_OTHER_LENGTH = 234L
  X123_HEADER_LENGTH = 256L
  X123_DATA_MAX = X123_SPECTRUM_LENGTH + X123_HEADER_LENGTH
  sci_count = 0L
  sci_struct1 = { apid: 0.0, seq_flag: 0B, seq_count: 0.0, data_length: 0L, time: 0.0D0,  $
    cdh_info: 0U, $
    cdh_state: 0B, spacecraft_mode: 0B, eclipse_state: 0B, $
    cmd_last_opcode: 0, cmd_last_status: 0, cmd_accept_count: 0L, cmd_reject_count: 0L, $
    param_set_header: 0,  cdh_enables: 0U, $
    enable_sps: 0B, enable_x123: 0B, enable_inst_heater: 0B, enable_sdcard: 0B, $
	fsw_major_minor: 0, fsw_patch_version: 0, flight_model: 0, $
	lockout_TimeoutCounter: 0L, instrument_HeaterSetpoint: 0, time_offset: 0L, $
	cdh_batt_v: 0.0, cdh_v2: 0.0, cdh_v2_sps_temp: 0.0, cdh_5v: 0.0, cdh_3v: 0.0, cdh_temp: 0.0, $
	cdh_i2c_err: 0L, cdh_rtc_err: 0L, cdh_spi_sd_err: 0L, $
    cdh_uart1_err: 0L, cdh_uart2_err: 0L, cdh_uart3_err: 0L, cdh_uart4_err: 0L, $
    mb_temp1: 0.0, mb_temp2: 0.0, $
    eps_temp1: 0.0, eps_temp2: 0.0, $
    eps_batt_cur: 0.0, eps_batt_volt: 0.0, $
    eps_3v_cur: 0.0, eps_3v_volt: 0.0, eps_5v_cur: 0.0, eps_5v_volt: 0.0, $
	picosim_temp: 0.0, sps_board_temp: 0.0, $
	sci_sps_sum: 0.0, sci_sps_x: 0.0, sci_sps_y: 0.0, $
	sci_spares: 0UL, $
	picosim_integ_time: 0L, picosim_data: fltarr(6), picosim_num_samples: intarr(6), $
	sps_data: fltarr(4), sps_num_samples: 0,  $
    x123_fast_count: 0.0D0, x123_slow_count: 0.0D0, x123_gp_count: 0.0D0, $
    x123_accum_time: 0.0D0, x123_live_time: 0.0D0, x123_real_time: 0.0D0, $
    x123_hv: 0.0, x123_det_temp: 0.0, x123_brd_temp: 0.0, x123_flags: 0UL, $
    x123_read_errors: 0, x123_radio_flag: 0,  x123_write_errors: 0, spare_errors: 0, $
    x123_cmp_info: 0L, x123_spect_len: 0, $
    x123_group_count: 0, x123_spectrum: lonarr(X123_SPECTRUM_BINS), $
    checkbytes: 0L, SyncWord: 0.0, $
    checkbytes_calculated: 0L, checkbytes_valid: 1B  }

  sciPacketIncomplete = 0
  sci_lastSeqCount = 0
  sci_PacketCounter = 0
  sci_numPacketsExpected = -1

  ;
  ; Isolate each packet as being between the SYNC words (0xA5A5)
  ;
  SpecIndex = 1
  index = 1L
  numlines = 0L
  steplines = 20
  ans = ' '

  inputSize = n_elements(data)  ; looking at the size of the data array

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
	  if (doDebug ge 2) then begin
	  	print, 'DEBUG: packet found between indices '+string(index-1)+' and '+string(index2)
	  	print, data[index-1:index2], format='(16Z4)'
	  endif
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
      ;  ????? is this += 18 needed for DAXSS ?????
      indexLast += 18

      if (indexLast gt (index2-8)) then indexLast = index2-8
      while (index3 lt indexLast) do begin
        if ((data[index3] eq CCSDS_BYTE1) and (data[index3+4] eq CCSDS_BYTE5)) then begin
          pindex = index3
          packet_ID_full = uint(data[pindex+1])
          packet_ID = uint(data[pindex+1]) ; AND '3f'X ; DON'T DO 'AND '3f'X' for DAXSS as it does not have playback
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
	  if (doDebug ge 2) then $
	  	stop, '*** DEBUG STOP: packet pindex='+strtrim(pindex,2)+'  packet_id='+strtrim(packet_id,2)+' ...'

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

; ***************************************************
;		PARSE DATA INTO PACKETS
; ***************************************************

      if (packet_id eq PACKET_ID_LOG) then begin
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

          log_struct1.cdh_info = (long(data[pindex+12])) ;None
          log_struct1.cdh_state = ISHFT(log_struct1.cdh_info AND 'F0'X, -4) ;extract the state from the MSN, returns one number
          log_struct1.spacecraft_mode = ISHFT(log_struct1.cdh_info AND '07'X, 0) ;extract the spacecraft mode from last three bits in the LSN, returns one number
          log_struct1.eclipse_state = ISHFT(log_struct1.cdh_info AND '08'X, -3) ;extract the eclipse state from the first bit in the LSN, BOOLEAN, either on(1) or off(0)

          log_struct1.cmd_last_opcode = (long(data[pindex+13]))   ; none
          log_struct1.cmd_last_status = long(data[pindex+14]) + ishft(long(data[pindex+15]),8) ; none
          log_struct1.cmd_accept_count =  long(data[pindex+16]) + ishft(long(data[pindex+17]),8) ; none
          log_struct1.cmd_reject_count =  long(data[pindex+18]) + ishft(long(data[pindex+19]),8) ; none
		  log_struct1.param_set_header =  long(data[pindex+20]) + ishft(long(data[pindex+21]),8) ; none

          log_struct1.cdh_enables = (long(data[pindex+22]) + ishft(long(data[pindex+23]),8))  ; none
          log_struct1.enable_sps = ISHFT(log_struct1.cdh_enables AND '0001'X, 0) ;extract the power state, BOOLEAN, either on(1) or off(0)
          log_struct1.enable_x123 = ISHFT(log_struct1.cdh_enables AND '0002'X, -1) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
          log_struct1.enable_sdcard = ISHFT(log_struct1.cdh_enables AND '0010'X, -4) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
          log_struct1.enable_inst_heater = ISHFT(log_struct1.cdh_enables AND '0200'X, -9) ;extract the power switch state, BOOLEAN, either on(1) or off(0)

          log_struct1.cdh_temp = ((FIX(data[pindex+24])) + ishft(FIX(data[pindex+25]),8)) /256.  ;deg C

		  log_struct1.sps_sum_rate =  long(data[pindex+26]) + ishft(long(data[pindex+27]),8) ; none
		  log_struct1.sps_x = (fix(data[pindex+28]) + ishft(fix(data[pindex+29]),8))   ; range from -10000 to 10000
          log_struct1.sps_y = (fix(data[pindex+30]) + ishft(fix(data[pindex+31]),8))   ; range from -10000 to 10000

          log_struct1.X123_Fast_Count_Norm = (long(data[pindex+32]) + ishft(long(data[pindex+33]),8))  ; cps
          log_struct1.X123_Slow_Count_Norm = (long(data[pindex+34]) + ishft(long(data[pindex+35]),8))  ; cps
          log_struct1.X123_Accum_Time = (long(data[pindex+36]) + ishft(long(data[pindex+37]),8) $
             	 + ishft(long(data[pindex+38]),16) + ishft(long(data[pindex+39]),24))  ; DN = msec
          log_struct1.X123_Det_Temp = (long(data[pindex+40]) + ishft(long(data[pindex+41]),8)) * 0.1 ; Kelvin

          log_struct1.log_spares =  long(data[pindex+42]) + ishft(long(data[pindex+43]),8) ; none

          log_struct1.message = string(data[pindex+44:pindex+123])

          pkt_expectedCheckbytes = fletcher_checkbytes(data[pindex:pindex+123])
          pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
          pkt_actualCheckbytes = long(data[pindex+124]) + ishft(long(data[pindex+125]),8)
          IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND (doDebug ge 1)) THEN message, /info, "CHECKSUM ERROR!  LOG seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)

          log_struct1.checkbytes = pkt_actualCheckbytes
          log_struct1.checkbytes_calculated = pkt_expectedCheckbytes
          log_struct1.checkbytes_valid = pkt_actualCheckbytes EQ pkt_expectedCheckbytes
          log_struct1.SyncWord = (long(data[pindex-2]) + ishft(long(data[pindex-1]),8))  ;none

          if (log_count eq 0) then log = replicate(log_struct1, N_CHUNKS) else $
            if log_count ge n_elements(log) then log = [log, replicate(log_struct1, N_CHUNKS)]
          log[log_count] = log_struct1
          log_count += 1
        endif

      endif else if (packet_id eq PACKET_ID_DUMP) then begin
        ;
        ;  ************************
        ;  Dump (memory, param table) Packet (if user asked for it)
        ;  ************************
        ;
        if arg_present(dump) then begin

          dump_struct1.apid = packet_id_full  ; keep Playback bit in structure
          dump_struct1.seq_flag = ishft(long(data[pindex+2] AND 'C0'X),-6)
          dump_struct1.seq_count = packet_seq_count
          dump_struct1.data_length = packet_length
          dump_struct1.time = packet_time   ; millisec (0.1 msec resolution)

          ; CDH State (MSN) and SC Mode Bitfields (LSN) (Secondary Header Userdata)
          dump_struct1.cdh_info = (long(data[pindex+12]))
          dump_struct1.cdh_state = ISHFT(dump_struct1.cdh_info AND 'F0'X, -4) ;extract the state from the MSN, returns one number
          dump_struct1.spacecraft_mode = ISHFT(dump_struct1.cdh_info AND '07'X, 0) ;extract the spacecraft mode from last three bits in the LSN, returns one number
          dump_struct1.eclipse_state = ISHFT(dump_struct1.cdh_info AND '08'X, -3) ;extract the eclipse state from the first bit in the LSN, BOOLEAN, either on(1) or off(0)

          dump_struct1.cmd_last_opcode = (long(data[pindex+13]))   ; none
          dump_struct1.cmd_last_status = long(data[pindex+14]) + ishft(long(data[pindex+15]),8) ; none
          dump_struct1.cmd_accept_count =  long(data[pindex+16]) + ishft(long(data[pindex+17]),8) ; none
          dump_struct1.cmd_reject_count =  long(data[pindex+18]) + ishft(long(data[pindex+19]),8) ; none
		  dump_struct1.param_set_header =  long(data[pindex+20]) + ishft(long(data[pindex+21]),8) ; none

          dump_struct1.cdh_enables = (long(data[pindex+22]) + ishft(long(data[pindex+23]),8))  ; none
          dump_struct1.enable_sps = ISHFT(dump_struct1.cdh_enables AND '0001'X, 0) ;extract the power state, BOOLEAN, either on(1) or off(0)
          dump_struct1.enable_x123 = ISHFT(dump_struct1.cdh_enables AND '0002'X, -1) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
          dump_struct1.enable_sdcard = ISHFT(dump_struct1.cdh_enables AND '0010'X, -4) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
          dump_struct1.enable_inst_heater = ISHFT(dump_struct1.cdh_enables AND '0200'X, -9) ;extract the power switch state, BOOLEAN, either on(1) or off(0)

          dump_struct1.dump_spares = (long(data[pindex+24]) + ishft(long(data[pindex+25]),8) $
             	 + ishft(long(data[pindex+26]),16) + ishft(long(data[pindex+27]),24))  ; DN = msec

 		  for ii=0,DUMP_ARRAY_NUM-1 do begin
 		    dump_struct1.dump_data[ii] = long(data[pindex+28+ii*2]) + ishft(long(data[pindex+29+ii*2]),8) ; none
 		  endfor

          pkt_expectedCheckbytes = fletcher_checkbytes(data[pindex:pindex+155])
          pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
          pkt_actualCheckbytes = long(data[pindex+156]) + ishft(long(data[pindex+157]),8)
          IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND (doDebug ge 1)) THEN message, /info, "CHECKSUM ERROR!  DUMP seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)

          dump_struct1.checkbytes = pkt_actualCheckbytes
          dump_struct1.checkbytes_calculated = pkt_expectedCheckbytes
          dump_struct1.checkbytes_valid = pkt_actualCheckbytes EQ pkt_expectedCheckbytes
          dump_struct1.SyncWord = (long(data[pindex-2]) + ishft(long(data[pindex-1]),8))  ;none

          if (dump_count eq 0) then dump = replicate(dump_struct1, N_CHUNKS) else $
            if dump_count ge n_elements(xactimage) then dump = [dump, replicate(dump_struct1, N_CHUNKS)]
          dump[dump_count] = dump_struct1
          dump_count += 1
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
          IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) and (doDebug ge 1)) THEN message, /info, "CHECKSUM ERROR!  SCI seq count = " + strtrim(packet_seq_count,2)

;print, "SEQ = " + string(fix(sci_struct1.seq_flag))
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
            sci_struct1.SyncWord = (long(data[pindex-2]) + ishft(long(data[pindex-1]),8))  ;none

            sci_struct1.cdh_info = (long(data[pindex+12])) ;None
            sci_struct1.cdh_state = ISHFT(sci_struct1.cdh_info AND 'F0'X, -4) ;extract the state from the MSN, returns one number
            sci_struct1.spacecraft_mode = ISHFT(sci_struct1.cdh_info AND '07'X, 0) ;extract the spacecraft mode from last three bits in the LSN, returns one number
            sci_struct1.eclipse_state = ISHFT(sci_struct1.cdh_info AND '08'X, -3) ;extract the eclipse state from the first bit in the LSN, BOOLEAN, either on(1) or off(0)

			sci_struct1.cmd_last_opcode = (long(data[pindex+13]))   ; none
			sci_struct1.cmd_last_status = long(data[pindex+14]) + ishft(long(data[pindex+15]),8) ; none
			sci_struct1.cmd_accept_count =  long(data[pindex+16]) + ishft(long(data[pindex+17]),8) ; none
			sci_struct1.cmd_reject_count =  long(data[pindex+18]) + ishft(long(data[pindex+19]),8) ; none
			sci_struct1.param_set_header =  long(data[pindex+20]) + ishft(long(data[pindex+21]),8) ; none

			sci_struct1.cdh_enables = (long(data[pindex+22]) + ishft(long(data[pindex+23]),8))  ; none
			sci_struct1.enable_sps = ISHFT(sci_struct1.cdh_enables AND '0001'X, 0) ;extract the power state, BOOLEAN, either on(1) or off(0)
			sci_struct1.enable_x123 = ISHFT(sci_struct1.cdh_enables AND '0002'X, -1) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
			sci_struct1.enable_sdcard = ISHFT(sci_struct1.cdh_enables AND '0010'X, -4) ;extract the power switch state, BOOLEAN, either on(1) or off(0)
			sci_struct1.enable_inst_heater = ISHFT(sci_struct1.cdh_enables AND '0200'X, -9) ;extract the power switch state, BOOLEAN, either on(1) or off(0)

			sci_struct1.fsw_major_minor = (long(data[pindex+24]))
            sci_struct1.fsw_patch_version = (long(data[pindex+25]))
            ;  2015/9/7: TW  Extract out extra flags from "fsw_patch_version"
            sci_struct1.flight_model = ishft( sci_struct1.fsw_patch_version AND '00F0'X, -4 )
            sci_struct1.fsw_patch_version = sci_struct1.fsw_patch_version AND '000F'X

            sci_struct1.lockout_timeoutcounter = (long(data[pindex+26]) + ishft(long(data[pindex+27]),8)) ; seconds
            sci_struct1.Instrument_HeaterSetpoint = (fix(data[pindex+28]) + ishft(fix(data[pindex+29]),8)) ;  -128 to 127 C
            sci_struct1.time_offset = (long(data[pindex+30]) + ishft(long(data[pindex+31]),8) $
            		+ ishft(long(data[pindex+32]),16) + ishft(long(data[pindex+33]),24))  ; milliseconds

			sci_struct1.cdh_batt_v = (long(data[pindex+34]) + ishft(long(data[pindex+35]),8)) *67.1/4096.  ;Volts
          	sci_struct1.cdh_v2 = (long(data[pindex+36]) + ishft(long(data[pindex+37]),8)) *33.55/4096.  ;Volts
          	sci_struct1.cdh_v2_sps_temp = (sci_struct1.cdh_v2 - 0.5) * 100.  ; deg. C from TMP36 inside SPS
          	sci_struct1.cdh_5v = (long(data[pindex+38]) + ishft(long(data[pindex+39]),8)) *6.71/4096.  ;Volts
          	sci_struct1.cdh_3v = (long(data[pindex+40]) + ishft(long(data[pindex+41]),8)) *6.71/4096.  ;Volts
          	sci_struct1.cdh_temp = ((FIX(data[pindex+42])) + ishft(FIX(data[pindex+43]),8)) /256.  ;deg C

          	sci_struct1.cdh_i2c_err = (long(data[pindex+44]) + ishft(long(data[pindex+45]),8))  ;none
          	sci_struct1.cdh_rtc_err = (long(data[pindex+46]) + ishft(long(data[pindex+47]),8))  ;none
          	sci_struct1.cdh_spi_sd_err = (long(data[pindex+48]) + ishft(long(data[pindex+49]),8))   ;none

          	sci_struct1.cdh_uart1_err = (long(data[pindex+50]) + ishft(long(data[pindex+51]),8))  ;none
          	sci_struct1.cdh_uart2_err = (long(data[pindex+52]) + ishft(long(data[pindex+53]),8))  ;none
          	sci_struct1.cdh_uart3_err = (long(data[pindex+54]) + ishft(long(data[pindex+55]),8))  ;none
          	sci_struct1.cdh_uart4_err = (long(data[pindex+56]) + ishft(long(data[pindex+57]),8))  ;none

          	sci_struct1.mb_temp1 = (FIX(data[pindex+58]) + ishft(FIX(data[pindex+59]),8))/256.0  ;deg C
          	sci_struct1.mb_temp2 = (FIX(data[pindex+60]) + ishft(FIX(data[pindex+61]),8))/256.0  ;deg C
          	sci_struct1.eps_temp1 = (FIX(data[pindex+62]) + ishft(FIX(data[pindex+63]),8)) / 256.0 ; deg C
          	sci_struct1.eps_temp2 = (FIX(data[pindex+64]) + ishft(FIX(data[pindex+65]),8)) / 256.0 ; deg C

          	sci_struct1.eps_batt_cur = (long(data[pindex+66]) + ishft(long(data[pindex+67]),8)) * 163.8 / 1638.4 ; milliAmp
          	sci_struct1.eps_batt_volt = (long(data[pindex+68]) + ishft(long(data[pindex+69]),8)) * 32.76 / 32768.0 ; Volts
          	sci_struct1.eps_3v_cur = (long(data[pindex+70]) + ishft(long(data[pindex+71]),8)) * 163.8 / 327.68 ; milliAmp
          	sci_struct1.eps_3v_volt = (long(data[pindex+72]) + ishft(long(data[pindex+73]),8)) * 32.76 / 32768.0 ; Volts
          	sci_struct1.eps_5v_cur = (long(data[pindex+74]) + ishft(long(data[pindex+75]),8)) * 163.8 / 327.68 ; milliAmp
          	sci_struct1.eps_5v_volt = (long(data[pindex+76]) + ishft(long(data[pindex+77]),8)) * 32.76 / 32768.0 ; Volts
            ; updated picosim_temp to be signed 8-bits (instead of 16-bits)
            ; sci_struct1.picosim_temp = (FIX(data[pindex+78]) + ishft(FIX(data[pindex+79]),8))  ;deg C
            sci_struct1.picosim_temp = FIX(data[pindex+78])  ;deg C
            if (sci_struct1.picosim_temp gt 127.) then begin
								sci_struct1.picosim_temp = sci_struct1.picosim_temp-256
            endif
            sci_struct1.sps_board_temp = (FIX(data[pindex+80]) + ishft(FIX(data[pindex+81]),8))/256.  ;deg C

			      sci_struct1.sci_sps_sum = (long(data[pindex+82]) + ishft(long(data[pindex+83]),8) $
               + ishft(long(data[pindex+84]),16) + ishft(long(data[pindex+85]),24))  ; counts
            sci_struct1.sci_sps_x = (fix(data[pindex+86]) + ishft(fix(data[pindex+87]),8))   ; range from -10000 to 10000
          	sci_struct1.sci_sps_y = (fix(data[pindex+88]) + ishft(fix(data[pindex+89]),8))   ; range from -10000 to 10000
          	sci_struct1.sci_spares = (long(data[pindex+90]) + ishft(long(data[pindex+91]),8) $
             	 + ishft(long(data[pindex+92]),16) + ishft(long(data[pindex+93]),24))  ; DN = msec

          	sci_struct1.picosim_integ_time = (long(data[pindex+94]) + ishft(long(data[pindex+95]),8))  ;none
            for ii=0,5 do begin
              ; 24-bits for PicoSIM signal integration and 8-bits for number of samples
              sci_struct1.picosim_data[ii] = (long(data[pindex+96+(ii*4)]) + ishft(long(data[pindex+97+(ii*4)]),8) $
                		+ ishft(long(data[pindex+98+(ii*4)]),16)) ; counts
              sci_struct1.picosim_num_samples[ii] =   fix(data[pindex+99+(ii*4)])  ; number
            endfor

            for ii=0,3 do begin
              sci_struct1.sps_data[ii] = long(data[pindex+120+(ii*2)]) + ishft(long(data[pindex+121+(ii*2)]),8)   ; counts
            endfor
			sci_struct1.sps_num_samples = (long(data[pindex+128]) + ishft(long(data[pindex+129]),8)) ; number samples
            sci_struct1.x123_fast_count = (long(data[pindex+130]) + ishft(long(data[pindex+131]),8) $
              + ishft(long(data[pindex+132]),16) + ishft(long(data[pindex+133]),24))  ; counts
            sci_struct1.x123_slow_count = (long(data[pindex+134]) + ishft(long(data[pindex+135]),8) $
              + ishft(long(data[pindex+136]),16) + ishft(long(data[pindex+137]),24))  ; counts
            sci_struct1.x123_gp_count = (long(data[pindex+138]) + ishft(long(data[pindex+139]),8) $
              + ishft(long(data[pindex+140]),16) + ishft(long(data[pindex+141]),24))  ; counts
            sci_struct1.x123_accum_time = (long(data[pindex+142]) + ishft(long(data[pindex+143]),8) $
              + ishft(long(data[pindex+144]),16) + ishft(long(data[pindex+145]),24))  ; DN = msec
            sci_struct1.x123_live_time = (long(data[pindex+146]) + ishft(long(data[pindex+147]),8) $
              + ishft(long(data[pindex+148]),16) + ishft(long(data[pindex+149]),24))  ; DN = msec
            sci_struct1.x123_real_time = (long(data[pindex+150]) + ishft(long(data[pindex+151]),8) $
              + ishft(long(data[pindex+152]),16) + ishft(long(data[pindex+153]),24))  ; DN = msec

            sci_struct1.x123_hv = (long(data[pindex+154]) + ishft(long(data[pindex+155]),8))   ; volt (signed)
            ;Because the value can be positive or negative we have to calculate the two's compliment
            if sci_struct1.x123_hv GE (2L^(15)) then sci_struct1.x123_hv -=  (2L^(16))
            sci_struct1.x123_hv *= .5

            sci_struct1.x123_det_temp = (long(data[pindex+156]) + ishft(long(data[pindex+157]),8)) * 0.1 ; Deg K

            sci_struct1.x123_brd_temp = (long(data[pindex+158]))    ; deg C (signed)
            ;Because the value can be positive or negative we have to calculate the two's compliment
            if sci_struct1.x123_brd_temp GE (2L^(7)) then sci_struct1.x123_brd_temp -=  (2L^(8))

            sci_struct1.x123_flags = (long(data[pindex+159]) + ishft(long(data[pindex+160]),8) $
              + ishft(long(data[pindex+161]),16))  ; none

            ; count (0=no errors)
            sci_struct1.x123_read_errors = (long(data[pindex+162]))
            sci_struct1.x123_radio_flag = (long(data[pindex+163]))
            sci_struct1.x123_write_errors = (long(data[pindex+164]))
            sci_struct1.spare_errors = (long(data[pindex+165]))

            sci_struct1.x123_cmp_info = (long(data[pindex+166]) + ishft(long(data[pindex+167]),8))  ; bytes
            sci_struct1.x123_spect_len = (long(data[pindex+168]) + ishft(long(data[pindex+169]),8))   ;bytes
            sci_struct1.x123_group_count = (long(data[pindex+170]) + ishft(long(data[pindex+171]),8))  ;none

            ; for ii=0,55,1 do begin
            ;  sci_struct1.x123_spectrum[ii] = (long(data[pindex+(82+(ii*3))])  $
            ;     + ishft(long(data[pindex+(83+(ii*3))]),8) $
            ;         + ishft(long(data[pindex+(84+(ii*3))]),16))
            ; endfor
            ;
            ; Store Raw Spectrum Data and see if need to decompress it after last packet
            ;
            sci_numPacketsExpected = ceil((sci_struct1.x123_spect_len - X123_FIRST_LENGTH * 1d0) / X123_OTHER_LENGTH) + 1
            sci_packetCounter = 1

            sci_raw_count = 0L
            sci_raw_data = bytarr(X123_DATA_MAX)
            for ii=0,X123_FIRST_LENGTH-1 do sci_raw_data[ii] = data[pindex+172+ii]
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
            ;
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

          ; If we are here and science packet is still incomplete, and sci_count = 0, set sci = -1 as a flag
          ; @TODO: If at least one science packet has been read, try to save partial packet
          ;   that we're dumping for bytarr input
		  ;          if (sciPacketIncomplete and (sci_count eq 0)) then sci = -1

      endif   ; endif for packet decoding

      ; increment index to start next packet search
      index = index2
    endif else begin
      ;  increment index and keep looking for Sync word
      index += 1
    endelse
  endwhile


  ;print, data[0:*], format = '(16Z3)'

  ; Eliminate excess length in packets
  if arg_present(log) and n_elements(log) ne 0 then log = log[0:log_count-1]
  if arg_present(sci) and n_elements(sci) ne 0 then sci = sci[0:sci_count-1]
  if arg_present(dump) and n_elements(dump) ne 0 then dump = dump[0:dump_count-1]

  ; Determine flight model from SCI data, or -1 if no SCI data found
  fm = 0 & timeIndex = 0
  WHILE fm EQ 0 DO BEGIN
    fm = (sci_count gt 0) ? sci[timeIndex].flight_model : -1
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
        ; Handle edge case where fm = -1 (no hk packets) but still have adcs packets
        IF fm EQ -1 THEN fmString = '1' ELSE fmString = strtrim(fm, 2) ; Assume flight model 1 for now: JPM: 2016-11-09
        IF fm NE 0 THEN file_copy, input, getenv('daxss_data') + '/fm' + fmString + '/xact_tlm_exported/' + inputStringParsed.Filename, /OVERWRITE
      ENDIF
    ENDIF
    ;            adcsRaw = [adcs1Raw, adcs2Raw, adcs3Raw, adcs4Raw]
    ;            openw, lun, xactExportFilename, /GET_LUN, /APPEND
    ;            writeu, lun, adcsRaw
    ;            close, lun
    ;            free_lun, lun
    ;            xactFrameNumber++
  ENDIF

  if keyword_set(verbose) then begin
    print, '*** daxss_read_packets finished:'
    if (log_count gt 0) then print, 'Number of LOG  Packets = ', log_count
    if (sci_count gt 0) then print, 'Number of SCI  Packets = ', sci_count
    if (dump_count gt 0) then print, 'Number of DUMP  Packets = ', dump_count
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
