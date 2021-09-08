;
;	dualsps_read_file_ccsds.pro
;
;	Read Dual-SPS binary data file with CCSDS headers
;
;	INPUT:
;		filename	File name of text file  (e.g., HYDRA telemetry file)
;
;	OUTPUT:
;		data		Data array of structures
;
;	History:
;		10/16/2020	Tom Woods: original code based on dualsps_read_file.pro and for new FSW Ver 3.06
;					Limitation is that Dump Packets and X55 Packets in FSW do not exist yet.
;

; helper function: hex2byte
;		converts two characters to byte - will make a byte array if hexstr is more than 2 characters
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
; ********************** dualsps_read_file  **********************
;
function dualsps_read_file_ccsds, filename, verbose=verbose, debug=debug, messages=messages, $
							dump_packets=dump_packets, hexdump=hexdump

data = -1L
if (n_params() lt 1) then begin
	print, 'USAGE: data = dualsps_read_file_ccsds( filename )'
	return, data
endif

if (not file_test(filename)) then begin
	print, 'ERROR: filename is not a valid file !'
	return, data
endif

; Clear any values present in the output variables, needed since otherwise the input values get returned when these packet types are missing from the input file
junk = temporary(messages)
junk = temporary(x55_packets)
junk = temporary(dump_packets)

if keyword_set(debug) then verbose=1

data_num = 0L
data_bad = 0L
msg_num = 0L
x55_num = 0L
dump_num = 0L
dstr = ' '

data_num_last_hx55 = -1L
x55_num_last_hx55 = -1L
x55_spectrum_count = 0L

;  defines
X55_DATA_LENGTH_MAX = 1024*3L
X55_SPECTRA_LENGTH = 1024L
X55_ELEMENTS_PER_PACKET = 35
PACKET_LENGTH = 84L

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

;  data array length is an estimate for just one type of packet
data_max = long(data_size / float(PACKET_LENGTH) ) + 10L

;  create the telemetry data array
data1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, rtc_sync: 0, $
	tlm_integ_time: 0L, packet_checksum: 0L, $
	; variables for CDH data
	cdh_version: 0.0, cdh_cmd_opcode: 0, cdh_cmd_status: 0, $
	cdh_cmd_accept_count: 0L, cdh_cmd_reject_count: 0L, $
	cdh_power_flags: 0L, cdh_instrument_flags: 0L, $
	sps_2_5V: 0.0, power_5V: 0.0, power_battery: 0.0, $
	power_temperature: 0.0, cdh_analog5: 0.0, cdh_analog6: 0.0, $
	; variables for SPS data
	sps_gain: 0, sps_config: 0, $
	sps_power_mon: 0.0, sps_ground_mon: 0.0, sps_temperature: 0.0, $
	sps_loop_count: 0L, sps_error_count: 0L, $
	sps_diode_data: fltarr(4), sps_quad_sum: 0.0D0, $
	sps_quad_x: 0.0, sps_quad_y: 0.0, $
	;  variables for TTM data
	ttm_software_enable: 0, ttm_hardware_enable: 0, ttm_state: 0, $
	ttm_x_control_asec: 0.0D0, ttm_y_control_asec: 0.0D0, $
	ttm_x_position_dn: 0, ttm_y_position_dn: 0 $
	}

data = replicate(data1, data_max )

;  create the messages array
msg_max = long(data_size / float(PACKET_LENGTH)) + 10L
msg1 = { jd: 0.0D0, $
	; variables in CCSDS header / footer (convert JD in code)
	ccsds_apid: 0, ccsds_seq_count: 0, ccsds_length: 0, $
	ccsds_sync_word: 0L, gps_seconds: 0.0D0, rtc_sync: 0, $
	packet_checksum: 0L, $
	; variables for message data
	message: "..." $
	}

messages = replicate(msg1, msg_max )

; STRSPLIT pattern with Space, comma, slash, colon, Tab (0x09)
pattern = ' ,/:' + string(byte(9))

sync_pattern = '5AA5A55A'X
SYNC_BYTE1 = byte('5A'X)
SYNC_BYTE2 = byte('A5'X)
SYNC_BYTE3 = byte('A5'X)
SYNC_BYTE4 = byte('5A'X)

CCSDS_BYTE1 = byte('08'X)
CCSDS_BYTE5 = byte('00'X)

PACKET_ID_TLM_CDM = 133		; this is only for single SPS + TTM option (CMAG / CDM)
PACKET_ID_TLM_CDM_ALT = 134
PACKET_ID_LOG = 29
PACKET_ID_DUMP = 26
PACKET_ID_X55 = 44

theCDHversion = 3.06	; assumes the latest version

;
;	DATA lines (packets) have SYNC 32-bit word, CCSDS header with time,
;	packet data, and checksum
;
SpecIndex = 1
index = 0L
numlines = 0L
steplines = 20
ans = ' '

if keyword_set(debug) then stop, 'DEBUG filedata before While search loop...'

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

	if keyword_set(debug) then stop, 'DEBUG found SYNC WORD ...'

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
		packet_rtc_sync = ((filedata[pindex+7] AND 'F8'X) ne 0 ? 1 : 0)
	endif else begin
		; didn't find CCSDS header so skip to next Sync Word
		goto, next_record
	endelse

	if keyword_set(debug) then stop, 'DEBUG found CCSDS Packet Header ...'

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

    if ((packet_id eq PACKET_ID_TLM_CDM) or (packet_id eq PACKET_ID_TLM_CDM_ALT)) $
    		and ((index2-index) ge 80) then begin
        ;
        ;  ************************
        ;  Telemetry (TLM) Packet (default data to return)
        ;
        ;	pindex is +4 from beginnning of Sync Word
        ;
        ;  ************************
        ;
	  ;if arg_present(data) then begin

		data1.packet_checksum = (long(filedata[pindex+78]) + ishft(long(filedata[pindex+79]),8))
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
		data1.rtc_sync = packet_rtc_sync
		data1.tlm_integ_time = (long(filedata[pindex+76]) + ishft(long(filedata[pindex+77]),8))
		; variables for CDH data
		data1.cdh_version = long(filedata[pindex+12]) + long(filedata[pindex+13])/100.
		data1.cdh_cmd_opcode = uint(filedata[pindex+14])
		data1.cdh_cmd_status = uint(filedata[pindex+15])
		data1.cdh_cmd_accept_count = (long(filedata[pindex+16]) + ishft(long(filedata[pindex+17]),8))
		data1.cdh_cmd_reject_count = (long(filedata[pindex+18]) + ishft(long(filedata[pindex+19]),8))
		data1.cdh_power_flags = (long(filedata[pindex+20]) + ishft(long(filedata[pindex+21]),8))
		data1.cdh_instrument_flags = (long(filedata[pindex+22]) + ishft(long(filedata[pindex+23]),8))
		data1.sps_2_5V = float(fix(filedata[pindex+24]) + ishft(fix(filedata[pindex+25]),8)) * 0.00080566405
		data1.power_5V = float(fix(filedata[pindex+26]) + ishft(fix(filedata[pindex+27]),8)) * 0.0016113281
		data1.power_battery = float(fix(filedata[pindex+28]) + ishft(fix(filedata[pindex+29]),8)) * 0.0080566405
		data1.power_temperature = float(fix(filedata[pindex+30]) + ishft(fix(filedata[pindex+31]),8)) * 0.080566 - 50.
		data1.cdh_analog5 = float(fix(filedata[pindex+32]) + ishft(fix(filedata[pindex+33]),8)) * 0.00080566405
		data1.cdh_analog6 = float(fix(filedata[pindex+34]) + ishft(fix(filedata[pindex+35]),8)) * 0.00080566405
		; variables for SPS data
		data1.sps_gain = uint(filedata[pindex+36])
		data1.sps_config = uint(filedata[pindex+37])
		data1.sps_power_mon = float(fix(filedata[pindex+38]) + ishft(fix(filedata[pindex+39]),8)) * 7.629E-5
		data1.sps_ground_mon = float(fix(filedata[pindex+40]) + ishft(fix(filedata[pindex+41]),8)) * 7.629E-5
		data1.sps_temperature = float(fix(filedata[pindex+42]) + ishft(fix(filedata[pindex+43]),8)) * 0.0078125
		data1.sps_loop_count = (long(filedata[pindex+44]) + ishft(long(filedata[pindex+45]),8))
		data1.sps_error_count = (long(filedata[pindex+46]) + ishft(long(filedata[pindex+47]),8))
		data1.sps_diode_data[0] = float(fix(filedata[pindex+48]) + ishft(fix(filedata[pindex+49]),8))
		data1.sps_diode_data[1] = float(fix(filedata[pindex+50]) + ishft(fix(filedata[pindex+51]),8))
		data1.sps_diode_data[2] = float(fix(filedata[pindex+52]) + ishft(fix(filedata[pindex+53]),8))
		data1.sps_diode_data[3] = float(fix(filedata[pindex+54]) + ishft(fix(filedata[pindex+55]),8))
		data1.sps_quad_sum = long(filedata[pindex+56]) + ishft(long(filedata[pindex+57]),8) + $
					ishft(long(filedata[pindex+58]),16) + ishft(long(filedata[pindex+59]),24)
		data1.sps_quad_x = float(fix(filedata[pindex+60]) + ishft(fix(filedata[pindex+61]),8))/10000.
		data1.sps_quad_y = float(fix(filedata[pindex+62]) + ishft(fix(filedata[pindex+63]),8))/10000.
		;  variables for TTM data
		data1.ttm_software_enable = uint(filedata[pindex+64]) and '01'X
		data1.ttm_hardware_enable = uint(filedata[pindex+64]) and '02'X
		data1.ttm_state = (long(filedata[pindex+66]) + ishft(long(filedata[pindex+67]),8))
		data1.ttm_x_control_asec = float(fix(filedata[pindex+68]) + ishft(fix(filedata[pindex+69]),8)) * 0.1
		data1.ttm_y_control_asec = float(fix(filedata[pindex+70]) + ishft(fix(filedata[pindex+71]),8)) * 0.1
		data1.ttm_x_position_dn = (long(filedata[pindex+72]) + ishft(long(filedata[pindex+73]),8))
		data1.ttm_y_position_dn = (long(filedata[pindex+74]) + ishft(long(filedata[pindex+75]),8))

		;  save data1 and increment index
		data[data_num] = data1
		data_num += 1
      ; endif
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
	  ;if arg_present(messages) then begin

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
		msg1.rtc_sync = packet_rtc_sync
		msg1.message = string(filedata[pindex+12:pindex+91])

		;  save msg1 and increment index
		messages[msg_num] = msg1
		msg_num += 1
	  ; endif
	  ; end of reading MSG data packets

	endif ;  else if (packet_id eq OTHER_ID) then begin
next_record:
		index = index2 - 1	; jump to next SYNC word
	endif
	index += 1   ; check next byte for SYNC pattern
endwhile

; trim down to what was actually read
data = data[0:data_num-1]

; exclude bad data without valid time
;wgood = where( data.have_rtc eq 1, numgood )
;if (numgood gt 1) then data=data[wgood]

; trim down to what was actually read
messages = messages[0:msg_num-1]

; trim down to what was actually read
; dump_packets = dump_packets[0:dump_num-1]

if keyword_set(verbose) then begin
	print, 'DUALSPS_READ_FILE_CCSDS: read ', strtrim(data_num,2), ' TLM records.'
	if (data_bad ne 0) then print, '                      ',strtrim(data_bad,2), ' bad records'
	print, 'DUALSPS_READ_FILE_CCSDS: read ', strtrim(msg_num,2), ' LOG messages.'
	print, 'DUALSPS_READ_FILE_CCSDS: read ', strtrim(dump_num,2), ' Dump Packets.'
endif

if keyword_set(debug) then stop, 'DEBUG at end of DUALSPS_READ_FILE_CCSDS ...'

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
