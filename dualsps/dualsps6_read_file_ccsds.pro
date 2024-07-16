;
;	dualsps6_read_file_ccsds.pro
;
;	Read Dual-SPS Version 6 (SunCET and CubIXSS) binary data file with CCSDS headers
;
;	INPUT:
;		filename	File name of text file  (e.g., HYDRA telemetry file)
;
;	OUTPUT:
;		data		Data array of structures
;
;	USAGE:
;		IDL>  data = dualsps6_read_file_ccsds( tlm_file, /verbose, messages=pmsg, $
;						dump_packets=pdump, time_packets=ptime )
;		where
;				tlm_file is  Hydra telemetry data file
;				data is the science and housekeeping combined telemetry Data packet
;				pmsg is the Message (LOG) packet output
;				pdump is the parameter table Dump packet output
;				ptime is the Time packet output
;				/verbose option prints information about the number of packets read
;
;	History:
;		10/16/2020	Tom Woods: original code based on dualsps_read_file.pro and for new FSW Ver 3.06
;					Limitation is that Dump Packets and X55 Packets in FSW do not exist yet.
;		03/10/2021	Tom Woods:  TTM-SPS data packet grew in size by 4 bytes, plus added NanoSIM packet.
;		06/02/2021	Tom Woods: Add option to read the TTM ADC packets
;		12/14/2023	Tom Woods: Updated for DualSPS FSW Version 6 for SunCET and CubIXSS
;

;
; helper function: hex2byte
;	converts two characters to byte - will make a byte array if hexstr is more than 2 characters
;
function hex2byte, hexstr
if n_params() lt 1 then return, 0
hexstr = strtrim(hexstr,2)
num_bytes = strlen(hexstr)/2L
if (num_bytes gt 1) then theBytes = bytarr(num_bytes) else theBytes = 0
for i=0L,num_bytes-1 do begin
	char1 = reform(byte(strupcase(strmid(hexstr,i*2,1))))
	num1 = (char1 ge byte('A')? char1-byte('A')+byte(10): char1-byte('0'))
	char2 = reform(byte(strupcase(strmid(hexstr,i*2+1,1))))
	num2 = (char2 ge byte('A')? char2-byte('A')+byte(10): char2-byte('0'))
	aNum = num1*byte(16)+num2
	if (num_bytes gt 1) then theBytes[i] = aNum else theBytes = aNum
endfor
return, theBytes
end

;
; ********************** dualsps6_read_file_ccsds  **********************
;
function dualsps6_read_file_ccsds, filename, verbose=verbose, debug=debug, messages=messages, $
							dump_packets=dump_packets, time_packets=time_packets, hexdump=hexdump

; check input parameters
data = -1L
if (n_params() lt 1) then begin
	print, 'USAGE: data = dualsps6_read_file_ccsds( filename )'
	return, data
endif

if (not file_test(filename)) then begin
	print, 'ERROR: filename is not a valid file !'
	return, data
endif

; Clear any values present in the output variables, needed since otherwise the input values get returned when these packet types are missing from the input file
junk = temporary(messages)
junk = temporary(dump_packets)
junk = temporary(time_packets)

debugLevel = 0
if keyword_set(debug) then begin
	verbose=1
	debugLevel = debug
endif

data_num = 0L
data_bad = 0L
msg_num = 0L
time_num = 0L
dump_num = 0L
dstr = ' '

;  ***** Updated 12/14/2023 for DualSPS FSW Ver 6
PACKET_LENGTH = 122L
MSG_PACKET_LENGTH = 100L
TIME_PACKET_LENGTH = 24L
DUMP_PACKET_LENGTH = 148L

PACKET_ID_TLM_SPS2 = 35		; this is for DualSPS with SPS1 and SPS2 included
PACKET_ID_TLM_SPS1 = 34		; this is for DualSPS with SPS1 only included
PACKET_ID_LOG = 23
PACKET_ID_DUMP = 25
PACKET_ID_TIME = 29

;
;  check on the filename input and read the file as a binary data file
;
IF size(filename[0], /TYPE) EQ 7 THEN if (strlen(filename) lt 2) then begin
	; find file to read
	filename = dialog_pickfile(/read, title='Select Hydra tlm_packet* file to read', filter='tlm_packet_*')
	if (strlen(filename) lt 2) then return, -1   ; user did not select file
endif

filenameType = ''
IF size(filename, /TYPE) EQ 7 THEN BEGIN
	filenameType = 'file'
	fileOpened = 0
	on_ioerror, exit_read
	finfo = file_info( filename )
	data_size = finfo.size
	if (finfo.exists ne 0) and (finfo.read ne 0) and (finfo.size gt 6) then begin
	  if keyword_set(verbose) then print, 'READING ', strtrim(finfo.size,2), ' bytes from ', filename
	  openr, lun, filename, /get_lun
	  fileOpened = 1
	  adata = assoc(lun, bytarr(finfo.size))
	  filedata = adata[0]
	  close, lun
	  free_lun, lun
	  fileOpened = 0
	  on_ioerror, NULL
	endif else goto, exit_read
ENDIF ELSE BEGIN
	filenameType = 'bytarr'
	filedata = filename ; filename provided was not a file name so assume it is already bytarr
	data_size = n_elements(filedata)
ENDELSE

;  create the telemetry data array
;  data array length is an estimate for just one type of packet
data_max = long(data_size / float(PACKET_LENGTH) ) + 10L
data1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, $
	tlm_integ_time: 0L, packet_checksum: 0L, $
	; variables for CDH data
	cdh_version: 0.0, cdh_cmd_opcode: 0, cdh_cmd_status: 0, $
	cdh_cmd_accept_count: 0L, cdh_cmd_reject_count: 0L, $
	cdh_mode_flags: 0L, cdh_instrument_flags: 0L, $
	power_3_3V: 0.0, current_3_3V: 0.0, power_5V: 0.0, current_5V: 0.0, $
	power_Vbat: 0.0, current_Vbat: 0.0, $
	cdh_analog1: 0.0, cdh_5V: 0.0, cdh_3_3V: 0.0, cdh_2_5V: 0.0, cdh_1_8V: 0.0, $
	cdh_temp_ARM: 0.0, cdh_Vbat: 0.0, cdh_temp_ADC: 0.0, $
	; variables for SPS data
	sps_temp_diode1: 0.0, sps_temp_diode2: 0.0, sps_temp_board: 0.0, $
	sps1_loop_count: 0L, sps1_error_count: 0L, $
	sps1_diode_data: ulonarr(4), sps1_quad_sum: 0UL, $
	sps1_quad_x: 0.0, sps1_quad_y: 0.0, $

	sps2_loop_count: 0L, sps2_error_count: 0L, $
	sps2_diode_data: ulonarr(4), sps2_quad_sum: 0UL, $
	sps2_quad_x: 0.0, sps2_quad_y: 0.0, $
	flare_magnitude: 0.0, flare_mode: 0 $
	}
data = replicate(data1, data_max )

;  create the messages packet array
msg_max = long(data_size / float(PACKET_LENGTH)) + 10L
msg1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, $
	packet_checksum: 0L, $
	; variables for message data
	message: "..." $
	}
messages = replicate(msg1, msg_max )

;  create the Time packet array
time_max = long(data_size / float(TIME_PACKET_LENGTH)) + 10L
time1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, $
	packet_checksum: 0L, $
	; variables for Time data
	time_msec_since_turnon: 0L $
	}
time_packets = replicate(time1, time_max )

;  create the dump_packets array
PARAMETER_MAX = 32L
dump_max = long(data_size / float(DUMP_PACKET_LENGTH)) + 10L
dump1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, $
	packet_checksum: 0L, $
	; variables for Dump packet
	table_set_num: 0, table_parameters: ulonarr(PARAMETER_MAX) $
	}
dump_packets = replicate(dump1, dump_max )

; Defines
; STRSPLIT pattern with Space, comma, slash, colon, Tab (0x09)
pattern = ' ,/:' + string(byte(9))

sync_pattern = '5AA5A55A'X
SYNC_BYTE1 = byte('5A'X)
SYNC_BYTE2 = byte('A5'X)
SYNC_BYTE3 = byte('A5'X)
SYNC_BYTE4 = byte('5A'X)

CCSDS_BYTE1 = byte('08'X)
CCSDS_BYTE5 = byte('00'X)

; assumes the latest version
; updated to 3.07 on 3/10/2021
; updated to 3.08 on 6/2/2021
; updated to 6.00 on 12/14/2023
theCDHversion = 6.00

;
;	DATA lines (packets) have SYNC 32-bit word, CCSDS header with time,
;	packet data, and checksum
;
SpecIndex = 1
index = 0L
numlines = 0L
steplines = 20
ans = ' '

if (debugLevel ne 0) then stop, 'DEBUG filedata before While search loop...'

;
;	big WHILE loop looking for the 4-byte SYNC word
;		if SYNC word is found then the CCSDS header is read first
;		then the CCSDS APID is checked for which type packet is next
;		and then a packet is filled with values based on the APID packet type
;
while (index lt (data_size-4)) do begin
	if (filedata[index] eq SYNC_BYTE1) and (filedata[index+1] eq SYNC_BYTE2) and $
		(filedata[index+2] eq SYNC_BYTE3) and (filedata[index+3] eq SYNC_BYTE4) then begin
		; first search for next Sync word
		index2 = index + 4
		while (index2 lt (data_size-4)) do begin
			if ((filedata[index2] ne SYNC_BYTE1) or (filedata[index2+1] ne SYNC_BYTE2) $
				and (filedata[index2+2] ne SYNC_BYTE3) or (filedata[index2+3] ne SYNC_BYTE4)) $
			then index2 += 1 $
			else break   ;  stop as found next Sync Word
		endwhile
		if (index2 ge data_size) then break  ; index2 = data_size-1

	if (debugLevel ge 2) then stop, 'DEBUG found SYNC WORD ...'

	;  extract out CCSDS packet header information
	;  this assumes APID is only 8-bits (instead of full 11-bits)
	;  this assumes Packet Length to be less than 256 bytes
	index3 = index + 4
	pindex = -1L
	pindex_end = index2
	packet_ID = 0     ; APID unique identifier for each packet type
	packet_seq_count = 0  ; 14-bit counter for each packet type
	packet_length = 0   ; 16-bit data length - 1
	packet_time = 0.0D0
	if ((filedata[index3] eq CCSDS_BYTE1) and (filedata[index3+4] eq CCSDS_BYTE5)) then begin
		pindex = index3
		pindex2 = index2
		packet_ID_full = uint(filedata[pindex+1])
		packet_ID = uint(filedata[pindex+1])
		packet_seq_count = uint(filedata[pindex+2] AND '3F'X) * 256 + uint(filedata[pindex+3])
		packet_length = uint(filedata[pindex+4])*256L + uint(filedata[pindex+5]) + 1L
		packet_time1 = ulong(filedata[pindex+8]) + ishft(ulong(filedata[pindex+9]),8) + $
				ishft(ulong(filedata[pindex+10]),16) + ishft(ulong(filedata[pindex+11]),24)
		packet_time2 = uint(filedata[pindex+6]) + uint(filedata[pindex+7] AND '03'X) * 256
		packet_time = double(packet_time1) + packet_time2 / 1000.D0		; gps_seconds
		; packet_rtc_sync = ((filedata[pindex+7] AND 'F8'X) ne 0 ? 1 : 0)
	endif else begin
		; didn't find CCSDS header so skip to next Sync Word
		goto, next_record
	endelse

	if (debugLevel ge 2) then stop, 'DEBUG found CCSDS Packet Header ...'

	; OPTION to print the packet data as a HEX dump to the screen (useful for debugging)
    if keyword_set(hexdump) then begin
        ; now print (hex dump) the packet info from pindex up to pindex_end
        ; only print if not just the Sync Word
        length = pindex2 - pindex + 4 - 1
        if (length gt 2) then begin
          k1 = pindex - 4  ; to include SYNC
          k2 = pindex2
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
            for j=k,kend do if (filedata[j] ge 33) and (filedata[j] le 122) then sdata[j-k]=filedata[j]
            extra = 2 + (kstep - (kend-k+1))*3
            aformat = '('+strtrim(kend-k+1,2)+'Z3,A'+strtrim(kend-k+1+extra,2)+')'
            print, filedata[k:kend], string(sdata), format=aformat
            numlines += 1
          endfor
          if (numlines ge steplines) then begin
            if (doPause ne 0) then begin
              read, '> Q=Quit, A=All listed, or Enter key for more ? ', ans
              ans1 = strupcase(strmid(ans,0,1))
              if (ans1 eq 'Q') then return, -1
              if (ans1 eq 'A') then doPause=0
            endif
            numlines = 0L
          endif
        endif
    endif  ; end of hexdump printing

    if ((packet_id eq PACKET_ID_TLM_SPS1) or (packet_id eq PACKET_ID_TLM_SPS2)) $
    		and ((index2-index) ge 110) then begin
        ;
        ;  ************************
        ;  Telemetry (TLM) Packet (default data to return)
        ;
        ;	pindex is +4 from beginnning of Sync Word
        ;
        ;	Updated 3/10/2021 with two extra Temperature monitors
        ;	Updated 12/14/2023 for DualSPS FSW Ver 6
        ;
        ;  ************************
        ;
		data1.packet_checksum = (long(filedata[pindex+118]) + ishft(long(filedata[pindex+119]),8))
		; pkt_expectedCheckbytes = fletcher_checkbytes(filedata[pindex:pindex+249])
		; pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
		; pkt_actualCheckbytes = long(filedata[pindex+250]) + ishft(long(filedata[pindex+251]),8)
		; IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  HK seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)
		data1.jd = gps2jd( packet_time )
		data1.ccsds_apid = packet_id
		data1.ccsds_seq_count = packet_seq_count
		data1.ccsds_length = packet_length
		data1.ccsds_sync_word = sync_pattern  ; static value
		data1.gps_seconds = packet_time
		data1.tlm_integ_time = (long(filedata[pindex+116]) + ishft(long(filedata[pindex+117]),8))
		; variables for CDH data
		data1.cdh_version = long(filedata[pindex+12]) + long(filedata[pindex+13])/100.
		data1.cdh_cmd_opcode = uint(filedata[pindex+14])
		data1.cdh_cmd_status = uint(filedata[pindex+15])
		data1.cdh_cmd_accept_count = (long(filedata[pindex+16]) + ishft(long(filedata[pindex+17]),8))
		data1.cdh_cmd_reject_count = (long(filedata[pindex+18]) + ishft(long(filedata[pindex+19]),8))
		data1.cdh_mode_flags = (long(filedata[pindex+20]) + ishft(long(filedata[pindex+21]),8))
		data1.cdh_instrument_flags = (long(filedata[pindex+22]) + ishft(long(filedata[pindex+23]),8))
		data1.power_3_3V = float(long(filedata[pindex+24]) + ishft(long(filedata[pindex+25]),8)) * 0.001 ; V
		data1.current_3_3V = float(long(filedata[pindex+26]) + ishft(long(filedata[pindex+27]),8)) * 1.0 ; mA
		data1.power_5V = float(long(filedata[pindex+28]) + ishft(long(filedata[pindex+29]),8)) * 0.001
		data1.current_5V = float(long(filedata[pindex+30]) + ishft(long(filedata[pindex+31]),8)) * 1.0
		data1.power_Vbat = float(long(filedata[pindex+32]) + ishft(long(filedata[pindex+33]),8)) * 0.001
		data1.current_Vbat = float(long(filedata[pindex+34]) + ishft(long(filedata[pindex+35]),8)) * 1.0
		; variables for CDH internal ADC analogs (divide by 1 factor is 0.00080566)
		data1.cdh_analog1 = float(long(filedata[pindex+36]) + ishft(long(filedata[pindex+37]),8)) * 0.00080566
		data1.cdh_5V = float(long(filedata[pindex+38]) + ishft(long(filedata[pindex+39]),8)) * 0.0016113
		data1.cdh_3_3V = float(long(filedata[pindex+40]) + ishft(long(filedata[pindex+41]),8)) * 0.0016113
		data1.cdh_2_5V = float(long(filedata[pindex+42]) + ishft(long(filedata[pindex+43]),8)) * 0.0016113
		data1.cdh_1_8V = float(long(filedata[pindex+44]) + ishft(long(filedata[pindex+45]),8)) * 0.00080566
		data1.cdh_temp_ARM = float(long(filedata[pindex+46]) + ishft(long(filedata[pindex+47]),8)) * 0.080566 - 50.
		data1.cdh_Vbat = float(long(filedata[pindex+48]) + ishft(long(filedata[pindex+49]),8)) * 0.0080566
		data1.cdh_temp_ADC = float(long(filedata[pindex+50]) + ishft(long(filedata[pindex+51]),8)) * 0.080566 - 50.
		; variables for Sensor Board temperature monitors
		data1.sps_temp_diode1 = float(long(filedata[pindex+52]) + ishft(long(filedata[pindex+53]),8)) * 0.01
		data1.sps_temp_diode2 = float(long(filedata[pindex+54]) + ishft(long(filedata[pindex+55]),8)) * 0.01
		data1.sps_temp_board = float(long(filedata[pindex+56]) + ishft(long(filedata[pindex+57]),8)) * 0.01
		; variables for Flare flags (also filler so sps1_diode[] array is on 4-byte boundary)
		data1.flare_magnitude = long(filedata[pindex+58]) * 0.1   ; flare_magnitude DN is LOG10 * 10
		data1.flare_mode = long(filedata[pindex+59])
		; variables for SPS-1 data
		data1.sps1_loop_count = (long(filedata[pindex+60]) + ishft(long(filedata[pindex+61]),8))
		data1.sps1_error_count = (long(filedata[pindex+62]) + ishft(long(filedata[pindex+63]),8))
		for i=0L,3L do begin
			data1.sps1_diode_data[i] = ulong(filedata[pindex+64+i*4]) $
					+ ishft(ulong(filedata[pindex+65+i*4]),8)  $
					+ ishft(ulong(filedata[pindex+66+i*4]),16) $
					+ ishft(ulong(filedata[pindex+67+i*4]),24)
		endfor
		data1.sps1_quad_sum = ulong(filedata[pindex+80]) + ishft(ulong(filedata[pindex+81]),8) + $
					ishft(ulong(filedata[pindex+82]),16) + ishft(ulong(filedata[pindex+83]),24)
		data1.sps1_quad_x = float(fix(filedata[pindex+84]) + ishft(fix(filedata[pindex+85]),8))/1.  ; arc-sec
		data1.sps1_quad_y = float(fix(filedata[pindex+86]) + ishft(fix(filedata[pindex+87]),8))/1.
		; variables for SPS-2 data
		data1.sps2_loop_count = (long(filedata[pindex+88]) + ishft(long(filedata[pindex+89]),8))
		data1.sps2_error_count = (long(filedata[pindex+90]) + ishft(long(filedata[pindex+91]),8))
		for i=0L,3L do begin
			data1.sps2_diode_data[i] = ulong(filedata[pindex+92+i*4]) $
					+ ishft(ulong(filedata[pindex+93+i*4]),8) $
					+ ishft(ulong(filedata[pindex+94+i*4]),16) $
					+ ishft(ulong(filedata[pindex+95+i*4]),24)
		endfor
		data1.sps2_quad_sum = ulong(filedata[pindex+108]) + ishft(ulong(filedata[pindex+109]),8) + $
					ishft(ulong(filedata[pindex+110]),16) + ishft(ulong(filedata[pindex+111]),24)
		data1.sps2_quad_x = float(fix(filedata[pindex+112]) + ishft(fix(filedata[pindex+113]),8))/1.  ; arc-sec
		data1.sps2_quad_y = float(fix(filedata[pindex+114]) + ishft(fix(filedata[pindex+115]),8))/1.
		;  save data1 and increment index
		data[data_num] = data1
		data_num += 1
	  ; end of reading TLM data packets

    endif else if (packet_id eq PACKET_ID_LOG) then begin
        ;
        ;  ************************
        ;  Log Message (MSG) Packet
        ;
        ;	pindex is +4 from beginnning of Sync Word
        ;
        ;  ************************
        ;
		msg1.packet_checksum = (long(filedata[pindex+94]) + ishft(long(filedata[pindex+95]),8))
		; pkt_expectedCheckbytes = fletcher_checkbytes(filedata[pindex:pindex+249])
		; pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
		; pkt_actualCheckbytes = long(filedata[pindex+250]) + ishft(long(filedata[pindex+251]),8)
		; IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  HK seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)
		msg1.jd = gps2jd( packet_time )
		msg1.ccsds_apid = packet_id
		msg1.ccsds_seq_count = packet_seq_count
		msg1.ccsds_length = packet_length
		msg1.ccsds_sync_word = sync_pattern  ; static value
		msg1.gps_seconds = packet_time
		msg1.message = string(filedata[pindex+12:pindex+91])
		;  save msg1 and increment index
		messages[msg_num] = msg1
		msg_num += 1
	  ; end of reading a MSG data packet

    endif else if (packet_id eq PACKET_ID_TIME) then begin
        ;
        ;  ************************
        ;  TIME Packet
        ;
        ;	pindex is +4 from beginnning of Sync Word
        ;
        ;  ************************
        ;
		time1.packet_checksum = (long(filedata[pindex+18]) + ishft(long(filedata[pindex+19]),8))
		; pkt_expectedCheckbytes = fletcher_checkbytes(filedata[pindex:pindex+249])
		; pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
		; pkt_actualCheckbytes = long(filedata[pindex+250]) + ishft(long(filedata[pindex+251]),8)
		; IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  HK seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)
		time1.jd = gps2jd( packet_time )
		time1.ccsds_apid = packet_id
		time1.ccsds_seq_count = packet_seq_count
		time1.ccsds_length = packet_length
		time1.ccsds_sync_word = sync_pattern  ; static value
		time1.gps_seconds = packet_time
		time1.time_msec_since_turnon = ulong(filedata[pindex+12]) + ishft(ulong(filedata[pindex+13]),8) + $
					ishft(ulong(filedata[pindex+14]),16) + ishft(ulong(filedata[pindex+15]),24)
		;  save time1 and increment index
		time_packets[time_num] = time1
		time_num += 1
	  ; end of reading a TIME packet

    endif else if (packet_id eq PACKET_ID_DUMP) then begin
        ;
        ;  ************************
        ;  Parameter Table Dump Packet
        ;
        ;	pindex is +4 from beginnning of Sync Word
        ;
        ;  ************************
        ;
		dump1.packet_checksum = (long(filedata[pindex+142]) + ishft(long(filedata[pindex+143]),8))
		; pkt_expectedCheckbytes = fletcher_checkbytes(filedata[pindex:pindex+249])
		; pkt_expectedCheckbytes = long(pkt_expectedCheckbytes[0]) + ishft(long(pkt_expectedCheckbytes[1]),8)
		; pkt_actualCheckbytes = long(filedata[pindex+250]) + ishft(long(filedata[pindex+251]),8)
		; IF ((pkt_expectedCheckbytes NE pkt_actualCheckbytes) AND keyword_set(verbose)) THEN message, /info, "CHECKSUM ERROR!  HK seq count = " + strtrim(packet_seq_count,2) + " ... expected " + strtrim(pkt_expectedCheckbytes,2) + ", saw " + strtrim(pkt_actualCheckbytes,2)
		dump1.jd = gps2jd( packet_time )
		dump1.ccsds_apid = packet_id
		dump1.ccsds_seq_count = packet_seq_count
		dump1.ccsds_length = packet_length
		dump1.ccsds_sync_word = sync_pattern  ; static value
		dump1.gps_seconds = packet_time
		; Parameter Table Dump data
		for i=0L,PARAMETER_MAX-1L do begin
			dump1.table_parameters[i] = ulong(filedata[pindex+12+i*4]) $
					+ ishft(ulong(filedata[pindex+13+i*4]),8) $
					+ ishft(ulong(filedata[pindex+14+i*4]),16) $
					+ ishft(ulong(filedata[pindex+15+i*4]),24)
		endfor
		dump1.table_set_num = fix(filedata[pindex+140]) + ishft(fix(filedata[pindex+141]),8)
		;  save dump1 and increment index
		dump_packets[dump_num] = dump1
		dump_num += 1
	  ; end of reading a Dump packet

	endif else begin ;  else if (packet_id eq OTHER_ID) then begin
		if (debugLevel ne 0) then print, 'WARNING that APID = '+strtrim(packet_id,2)+ ' is ignored.'
	endelse
next_record:
		index = index2 - 1	; jump to next SYNC word

	endif	; END of IF statement checking for SYNC word
	index += 1   ; check next byte for SYNC pattern

endwhile   ; END of big WHILE loop

; trim down the packets to what was actually read
if (data_num gt 0) then data = data[0:data_num-1] else data=-1L
if (msg_num gt 0) then messages = messages[0:msg_num-1] else messages=-1L
if (dump_num gt 0) then dump_packets = dump_packets[0:dump_num-1] else dump_packets=-1L
if (time_num gt 0) then time_packets = time_packets[0:time_num-1] else time_packets=-1L

if keyword_set(verbose) then begin
	print, 'DUALSPS6_READ_FILE_CCSDS: read ', strtrim(data_num,2), ' TLM Data records.'
	if (data_bad ne 0) then print, '                      ',strtrim(data_bad,2), ' bad records'
	print, 'DUALSPS6_READ_FILE_CCSDS: read ', strtrim(msg_num,2), ' LOG messages.'
	print, 'DUALSPS6_READ_FILE_CCSDS: read ', strtrim(dump_num,2), ' Dump packets.'
	print, 'DUALSPS6_READ_FILE_CCSDS: read ', strtrim(time_num,2), ' Time packets.'
endif

if (debugLevel ne 0) then stop, 'DEBUG at end of DUALSPS6_READ_FILE_CCSDS ...'

; normal exit with "data" being array of TLM data packets
return, data

exit_read:
  ; Exit Point on File Open or Read Error
  if keyword_set(verbose) then print, 'ERROR reading file: ', filename
  if (fileOpened ne 0) then begin
    close, lun
    free_lun, lun
  endif
  on_ioerror, NULL
  return, -1
end
