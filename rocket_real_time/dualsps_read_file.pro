;
;	dualsps_read_file.pro
;
;	Read Dual-SPS text data file
;
;	INPUT:
;		filename	File name of text file  (e.g., HYDRA telemetry file)
;
;	OUTPUT:
;		data		Data array of structures
;
;	History:
;		8/27/2019	Tom Woods: original code based on picosim_read_file.pro
;		9/21/2019	Tom Woods: updated so TTM packets can be higher rate and separate return
;		1/4/2020	Tom Woods: updated for rocket channels nanoSIM, mechanism board, dual-UART, Amptek X55
;		3/4/2020	Tom Woods: updated for packet format changes in flight software version 3.03
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
function dualsps_read_file, filename, verbose=verbose, debug=debug, messages=messages, $
										ttm_packets=ttm_packets, x55_packets=x55_packets

data = -1L
if (n_params() lt 1) then begin
	print, 'USAGE: data = dualsps_read_file( filename )'
	return, data
endif

if (not file_test(filename)) then begin
	print, 'ERROR: filename is not a valid file !'
	return, data
endif

if keyword_set(debug) then verbose=1
if keyword_set(verbose) then print, 'DUALSPS_READ_FILE: reading ', filename, ' ...'

data_num = 0L
data_bad = 0L
msg_num = 0L
ttm_num = 0L
x55_num = 0L
dstr = ' '

data_num_last_hx55 = -1L
x55_num_last_hx55 = -1L
x55_spectrum_count = 0L

;  defines
X55_DATA_LENGTH_MAX = 1024*3L
X55_SPECTRA_LENGTH = 1024L
X55_ELEMENTS_PER_PACKET = 35
PACKET_LENGTH = 83L

openr,lun,filename,/get_lun
finfo = fstat(lun)

;  data array length is much less than one CDHA packet though
data_max = long(finfo.size / float(PACKET_LENGTH) ) + 10L

;  create the data array
;  updated to allow for TTM and MECH data line options (in addition to SPS, CDH data)
data1 = { jd: 0.0D0, $
	; variables in DS.RTC data line (convert JD in code)
	rtc_time_since_on: 0.0D0, $
	year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, $
	gps_seconds: 0.0D0, have_rtc: 0, $
	; variables in DS.CDHA data line
	time_since_on: 0.0D0, sps_2_5V: 0.0, power_5V: 0.0, power_battery: 0.0, $
	power_temperature: 0.0, cdh_version: 0.0, have_cdh: 0, $
	cdh_instr_name: '????', cdh_command_info: '????', cdh_command_index: 0, $
	; variables in DS.ASPS data line
	sps_time_since_on: 0.0D0, $
	sps1_error_count: 0L, sps1_power_mon: 0.0, sps1_ground_mon: 0.0, sps1_temperature: 0.0, $
	sps2_error_count: 0L, sps2_power_mon: 0.0, sps2_ground_mon: 0.0, sps2_temperature: 0.0, $
	have_spsA: 0, $
	; variables in DS.1SPS data line
	sps1_time_since_on: 0.0D0, $
	sps1_loop_count: 0L, sps1_data: fltarr(4), sps1_quad_sum: 0.0D0, $
	sps1_quad_x: 0.0, sps1_quad_y: 0.0, have_sps1: 0, $
	; variables in DS.2SPS data line
	sps2_time_since_on: 0.0D0, $
	sps2_loop_count: 0L, sps2_data: fltarr(4), sps2_quad_sum: 0.0D0, $
	sps2_quad_x: 0.0, sps2_quad_y: 0.0, have_sps2: 0, $
	;  variables for DS.TTMD data line
	ttm_time_since_on: 0.0D0, $
	ttm_software_enable: 0, ttm_hardware_enable: 0, ttm_state: "????", $
	ttm_x_control_asec: 0.0D0, ttm_y_control_asec: 0.0, $
	ttm_x_position_dn: 0, ttm_y_position_dn: 0, have_ttm: 0, $
	;  variables for DS.mech data line
	mech_time_since_on: 0.0D0, mech1_status: "????", mech2_status: "????", $
	mech1_current_dn: 0, mech1_volt_dn: 0, mech2_current_dn: 0, mech2_volt_dn: 0, $
	mech_discrete_open: 0, mech_discrete_close: 0, mech_battery_return_dn: 0, $
	mech_battery_power_dn: 0, have_mech: 0, $
	;  variables for DS.aSIM data line
	aSIM_time_since_on: 0.0D0, aSIM_integ_time: 0.0, aSIM_num_samples: 0, $
	aSIM_data: fltarr(6), aSIM_temperature: 0.0, have_aSIM: 0, $
	;  variables for DS.bSIM data line
	bSIM_time_since_on: 0.0D0, bSIM_integ_time: 0.0, bSIM_num_samples: 0, $
	bSIM_data: fltarr(6), bSIM_temperature: 0.0, have_bSIM: 0, $
	;  variables for DS.cSIM data line
	cSIM_time_since_on: 0.0D0, cSIM_integ_time: 0.0, cSIM_num_samples: 0, $
	cSIM_data: fltarr(6), cSIM_temperature: 0.0, have_cSIM: 0, $
	;  variables for DS.uart data lines
	uart_time_since_on: 0.0D0, uart_rx_status: 0, uart_rx_ring_length: 0, $
	uart_rx_count: 0L, uart_rx_fifo_length: 0, $
	uart_tx_count: 0L, uart_tx_fifo_length: 0, have_uart: 0, $
	;  variables for DS.HX55 and DS.SX55 data lines
	x55_time_since_on: 0.0D0, x55_fast_count: 0L, x55_slow_count: 0L, $
	x55_accum_time: 0.0, x55_live_time: 0.0, x55_real_time: 0.0, $
	x55_hv: 0.0, x55_det_temp: 0.0, x55_board_temp: 0.0, $
	x55_compress_flag: 0U, x55_data_length: 0U, have_x55: 0, $
	x55_packet_index: 0L	 }

data = replicate(data1, data_max )
data[data_num].have_cdh = 0		; configure to read first packet

;  create the messages array
msg_max = long(finfo.size / float(PACKET_LENGTH)) + 10L
msg1 = { $
	;  variables for DS.MSGC data line
	time_since_on: 0.0D0, $
	msg_command_status: "????????", msg_text: "--------", $
	have_msg: 0  }

messages = replicate(msg1, msg_max )
messages[msg_num].have_msg = 0		; configure to read first packet

;  create the ttm_packets array
ttm_max = long(finfo.size / float(PACKET_LENGTH)) + 10L
ttm1 = { $
	;  variables for DS.TTMD data line
	ttm_time_since_on: 0.0D0, $
	ttm_software_enable: 0, ttm_hardware_enable: 0, ttm_state: "????", $
	ttm_x_control_asec: 0.0D0, ttm_y_control_asec: 0.0, $
	ttm_x_position_dn: 0, ttm_y_position_dn: 0, $
	have_ttm: 0  }

ttm_packets = replicate(ttm1, ttm_max )
ttm_packets[ttm_num].have_ttm = 0		; configure to read first packet

;  create the x55_packets array
x55_max = long(finfo.size / float(PACKET_LENGTH) / 2.) + 10L
x55_1 = { $
	;  variables for DS.TTMD data line
	x55_time_since_on: 0.0D0, x55_fast_count: 0L, x55_slow_count: 0L, $
	x55_accum_time: 0.0, x55_live_time: 0.0, x55_real_time: 0.0, $
	x55_hv: 0.0, x55_det_temp: 0.0, x55_board_temp: 0.0, $
	x55_error_flag: 0, x55_compress_flag: 0U, x55_data_length: 0U, have_x55: 0, x55_uncompressed: 0, $
	x55_spectra: fltarr(X55_SPECTRA_LENGTH), x55_spectra_raw: bytarr(X55_DATA_LENGTH_MAX) }

x55_packets = replicate(x55_1, x55_max )
x55_packets[x55_num].have_x55 = 0		; configure to read first packet

; STRSPLIT pattern with Space, comma, slash, colon, Tab (0x09)
pattern = ' ,/:' + string(byte(9))

theCDHversion = 3.03	; assumes the latest version

;
;	DATA lines (packets) have fixed format of 80 characters per line
; 	PACKETS have SYNC of "DS." and ID of "RTC", "CDHA", "TTMD", "ASPS", "1SPS", "2SPS", "MECH"
;
;	It uses DS.RTC packets to increment packet counter (data_num).
;	This will over-write packets if DS.RTC packets are not found.
;
while (not eof(lun)) do begin
	readf,lun,dstr
	darray = strsplit( dstr, pattern, /extract, count=nstr )
	; if keyword_set(debug) then stop, 'DEBUG parse of file string...'
	if (nstr ge 3) then begin
		;  PROCESS MESSAGE PACKETS
		if (darray[0] eq 'DS.MSGC') then begin
			; increment to next message
			if (messages[msg_num].have_msg eq 1) then msg_num += 1L
			; parse DS.MSGC data line
			messages[msg_num].have_msg = 1
			messages[msg_num].time_since_on = double(darray[1])
			messages[msg_num].msg_command_status = darray[2]
			messages[msg_num].msg_text = ""
			for i=3,nstr-2 do messages[msg_num].msg_text += (" " + darray[i])
			messages[msg_num].msg_text = strtrim(messages[msg_num].msg_text,2)
		endif
		; PROCESS LINKED DATA PACKETS:  DS.CDHA is first linked packet
		if (darray[0] eq 'DS.CDHA') then begin
			; increment to next record - that is, DS.CDHA packets are always first packet
			if (data[data_num].have_cdh eq 1) then begin
				data_num += 1L
				; clear all other packet "have" flags
				data[data_num].have_rtc = 0
				data[data_num].have_spsa = 0
				data[data_num].have_sps1 = 0
				data[data_num].have_sps2 = 0
				data[data_num].have_ttm = 0
				data[data_num].have_mech = 0
				data[data_num].have_mech = 0
				data[data_num].have_aSIM = 0
				data[data_num].have_bSIM = 0
				data[data_num].have_cSIM = 0
				data[data_num].have_uart = 0
				data[data_num].have_x55 = 0
			endif
			; parse DS.CDHA data line  (next line is example)
			; DS.CDHA         6.462  2.508  5.004 13.495   22.03 V3.04 OWLS C=0x0000 I=  0      .
			data[data_num].have_cdh = 1
			data[data_num].time_since_on = double(darray[1])
			data[data_num].sps_2_5V = double(darray[2])
			data[data_num].power_5V = double(darray[3])
			data[data_num].power_battery = double(darray[4])
			data[data_num].power_temperature = double(darray[5])
			if (theCDHversion le 0) then begin
				; force check for old packet format first
				data[data_num].cdh_version = double(strmid(darray[6],1,strlen(darray[6])-1))
				; stop, 'DEBUG cdh_version conversion !'
				if (data[data_num].cdh_version eq 0) then begin
					; try to get cdh_version as last element
					data[data_num].cdh_version = double(strmid(darray[10],1,strlen(darray[10])-1))
					; stop, 'DEBUG cdh_version conversion !'
				endif
				;  save first instance of cdh_version for use by TTM packets
				theCDHversion = data[data_num].cdh_version
			endif else data[data_num].cdh_version = theCDHversion  ; only read Version # once
			if (theCDHversion ge 3.03) then begin
				; also read Instrument Name and command info
				data[data_num].cdh_instr_name = darray[7]
				data[data_num].cdh_command_info = darray[8]
				if (n_elements(darray) gt 10) then data[data_num].cdh_command_index = fix(darray[10])
			endif
		endif
		if (darray[0] eq 'DS.RTC') then begin
			; parse DS.RTC line
			data[data_num].have_rtc = 1
			if (theCDHversion ge 3.03) then begin
				data[data_num].rtc_time_since_on = double(darray[1])
				ii=1
			endif else ii=0
			data[data_num].year = fix(darray[ii+1])
			data[data_num].month = fix(darray[ii+2])
			data[data_num].day = fix(darray[ii+3])
			data[data_num].hour = fix(darray[ii+4])
			data[data_num].minute = fix(darray[ii+5])
			data[data_num].second = fix(darray[ii+6])
			; skip the word "GPS"
			data[data_num].gps_seconds = double(darray[ii+8])
			data[data_num].jd = julday( data[data_num].month, data[data_num].day, $
									data[data_num].year, data[data_num].hour, $
									data[data_num].minute, data[data_num].second )
		endif
		if (darray[0] eq 'DS.ASPS') then begin
			; parse DS.ASPS data line: it can be SPS-1 and SPS-2, or just one of them
			data[data_num].have_spsa = 1
			data[data_num].sps_time_since_on = darray[1]  ; CHANGE for V3.03
			if (darray[2] eq '1') then begin
				data[data_num].sps1_error_count = fix(darray[3])
				data[data_num].sps1_power_mon = float(darray[4])
				data[data_num].sps1_ground_mon = float(darray[5])
				data[data_num].sps1_temperature = float(darray[6])
			endif else begin
				; it thus be SPS-2
				data[data_num].sps2_error_count = fix(darray[3])
				data[data_num].sps2_power_mon = float(darray[4])
				data[data_num].sps2_ground_mon = float(darray[5])
				data[data_num].sps2_temperature = float(darray[6])
			endelse
			if (darray[7] eq '2') then begin
				data[data_num].sps2_error_count = fix(darray[8])
				data[data_num].sps2_power_mon = float(darray[9])
				data[data_num].sps2_ground_mon = float(darray[10])
				data[data_num].sps2_temperature = float(darray[11])
			endif  ; else it is the DOT character and packet ASPS ends here
		endif
		if (darray[0] eq 'DS.1SPS') then begin
			; parse DS.1SPS data line
			data[data_num].have_sps1 = 1
			data[data_num].sps1_time_since_on = darray[1]  ; CHANGE for V3.03
			data[data_num].sps1_loop_count = long(darray[2])
			for i=0,3 do data[data_num].sps1_data[i] = float(darray[i+3])
			data[data_num].sps1_quad_sum = double(darray[7])
			data[data_num].sps1_quad_x = float(darray[8])
			data[data_num].sps1_quad_y = float(darray[9])
		endif
		if (darray[0] eq 'DS.2SPS') then begin
			; parse DS.2SPS data line
			data[data_num].have_sps2 = 1
			data[data_num].sps2_time_since_on = darray[1]  ; CHANGE for V3.03
			data[data_num].sps2_loop_count = long(darray[2])
			for i=0,3 do data[data_num].sps2_data[i] = float(darray[i+3])
			data[data_num].sps2_quad_sum = double(darray[7])
			data[data_num].sps2_quad_x = float(darray[8])
			data[data_num].sps2_quad_y = float(darray[9])
		endif
		if (darray[0] eq 'DS.TTMD') then begin
			if (theCDHversion gt 0) then begin
				; parse DS.TTMD data line - Option for Version 1.07 and older - doesn't have TIME_SINCE_ON
				if (theCDHversion lt 1.08) then begin
					data[data_num].have_ttm = 1
					data[data_num].ttm_time_since_on = data[data_num].time_since_on ; store same time here
					data[data_num].ttm_software_enable = fix(darray[1])
					data[data_num].ttm_hardware_enable = fix(darray[2])
					data[data_num].ttm_state = darray[3]
					data[data_num].ttm_x_control_asec = double(darray[4])
					data[data_num].ttm_y_control_asec = double(darray[5])
					data[data_num].ttm_x_position_dn = fix(darray[6])
					data[data_num].ttm_y_position_dn = fix(darray[7])
				endif else begin
					; parse DS.TTMD data line - Version 1.08 and newer has TIME_SINCE_ON
					data[data_num].have_ttm = 1
					data[data_num].ttm_time_since_on = double(darray[1])
					data[data_num].ttm_software_enable = fix(darray[2])
					data[data_num].ttm_hardware_enable = fix(darray[3])
					data[data_num].ttm_state = darray[4]
					data[data_num].ttm_x_control_asec = double(darray[5])
					data[data_num].ttm_y_control_asec = double(darray[6])
					data[data_num].ttm_x_position_dn = fix(darray[7])
					data[data_num].ttm_y_position_dn = fix(darray[8])
				endelse
				;  Version 1.08 and newer also has much faster TTM data rate
				;  store into ttm_packets[] regardless of which version
				ttm_packets[ttm_num].have_ttm = data[data_num].have_ttm
				ttm_packets[ttm_num].ttm_time_since_on = data[data_num].ttm_time_since_on
				ttm_packets[ttm_num].ttm_software_enable = data[data_num].ttm_software_enable
				ttm_packets[ttm_num].ttm_hardware_enable = data[data_num].ttm_hardware_enable
				ttm_packets[ttm_num].ttm_state = data[data_num].ttm_state
				ttm_packets[ttm_num].ttm_x_control_asec = data[data_num].ttm_x_control_asec
				ttm_packets[ttm_num].ttm_y_control_asec = data[data_num].ttm_y_control_asec
				ttm_packets[ttm_num].ttm_x_position_dn = data[data_num].ttm_x_position_dn
				ttm_packets[ttm_num].ttm_y_position_dn = data[data_num].ttm_y_position_dn
				ttm_num += 1
			endif
		endif
		if (darray[0] eq 'DS.mech') then begin
			; parse DS.mech data line
			data[data_num].have_mech = 1
			data[data_num].mech_time_since_on = double(darray[1])
			data[data_num].mech1_status = darray[2]
			data[data_num].mech2_status = darray[3]
			data[data_num].mech1_current_dn = fix(darray[4])
			data[data_num].mech1_volt_dn = fix(darray[5])
			data[data_num].mech2_current_dn = fix(darray[6])
			data[data_num].mech2_volt_dn = fix(darray[7])
			data[data_num].mech_discrete_open = fix(darray[8])
			data[data_num].mech_discrete_close = fix(darray[9])
			data[data_num].mech_battery_return_dn = fix(darray[10])
			data[data_num].mech_battery_power_dn = fix(darray[11])
		endif
		if (darray[0] eq 'DS.aSIM') then begin
			; parse DS.aSIM data line
			data[data_num].have_aSIM = 1
			data[data_num].aSIM_time_since_on = double(darray[1])
			data[data_num].aSIM_integ_time = fix(darray[2])
			data[data_num].aSIM_num_samples = fix(darray[3])
			for i=0,5 do data[data_num].aSIM_data[i] = float(darray[4+i])
			data[data_num].aSIM_temperature = float(darray[10])
		endif
		if (darray[0] eq 'DS.bSIM') then begin
			; parse DS.bSIM data line
			data[data_num].have_bSIM = 1
			data[data_num].bSIM_time_since_on = double(darray[1])
			data[data_num].bSIM_integ_time = fix(darray[2])
			data[data_num].bSIM_num_samples = fix(darray[3])
			for i=0,5 do data[data_num].bSIM_data[i] = float(darray[4+i])
			data[data_num].bSIM_temperature = float(darray[10])
		endif
		if (darray[0] eq 'DS.cSIM') then begin
			; parse DS.cSIM data line
			data[data_num].have_cSIM = 1
			data[data_num].cSIM_time_since_on = double(darray[1])
			data[data_num].cSIM_integ_time = fix(darray[2])
			data[data_num].cSIM_num_samples = fix(darray[3])
			for i=0,5 do data[data_num].cSIM_data[i] = float(darray[4+i])
			data[data_num].cSIM_temperature = float(darray[10])
		endif
		if (darray[0] eq 'DS.uart') then begin
			; parse DS.uart data line
			data[data_num].have_uart = 1
			data[data_num].uart_time_since_on = double(darray[1])
			data[data_num].uart_rx_status = hex2byte(strmid(darray[4],2,2))  ; skip U1 Rx headers
			data[data_num].uart_rx_ring_length = fix(darray[5])
			data[data_num].uart_rx_count = fix(darray[6])
			data[data_num].uart_rx_fifo_length = fix(darray[7])
			data[data_num].uart_tx_count = fix(darray[9])	; skip Tx header
			data[data_num].uart_tx_fifo_length = fix(darray[10])
		endif
		if ((darray[0] eq 'DS.HX55') and (n_elements(darray) gt 11 )) then begin
			; parse  DS.HX55 data line
			data[data_num].have_x55 = 1
			data[data_num].x55_time_since_on = double(darray[1])
			data[data_num].x55_fast_count = long(darray[2])
			data[data_num].x55_slow_count = long(darray[3])
			data[data_num].x55_accum_time = float(darray[4])/1000.
			data[data_num].x55_live_time = float(darray[5])/1000.
			data[data_num].x55_real_time = float(darray[6])/1000.
			data[data_num].x55_hv = float(darray[7])
			data[data_num].x55_det_temp = float(darray[8])/10.
			data[data_num].x55_board_temp = float(darray[9])
			data[data_num].x55_compress_flag = uint(darray[10])
			data[data_num].x55_data_length = uint(darray[11])
			data[data_num].x55_packet_index = x55_num
			data_num_last_hx55 = data_num   ; track where last HX55 header info was stored for SX55 packets
			x55_num_last_hx55 = x55_num
			x55_spectrum_count = 0L
			x55_data_error = 0
			;  also store this into x55_packets array
			x55_packets[x55_num].have_x55 = data[data_num].have_x55
			x55_packets[x55_num].x55_time_since_on  = data[data_num].x55_time_since_on
			x55_packets[x55_num].x55_fast_count  = data[data_num].x55_fast_count
			x55_packets[x55_num].x55_slow_count  = data[data_num].x55_slow_count
			x55_packets[x55_num].x55_accum_time  = data[data_num].x55_accum_time
			x55_packets[x55_num].x55_live_time  = data[data_num].x55_live_time
			x55_packets[x55_num].x55_real_time  = data[data_num].x55_real_time
			x55_packets[x55_num].x55_hv  = data[data_num].x55_hv
			x55_packets[x55_num].x55_det_temp  = data[data_num].x55_det_temp
			x55_packets[x55_num].x55_board_temp  = data[data_num].x55_board_temp
			x55_packets[x55_num].x55_compress_flag  = data[data_num].x55_compress_flag
			x55_packets[x55_num].x55_data_length  = data[data_num].x55_data_length
			x55_packets[x55_num].x55_uncompressed = 0;
			x55_num++;
		endif
		if (darray[0] eq 'DS.SX55') then begin
			; parse  DS.SX55 data line if HX55 already seen
			; x55_spectra: fltarr(X55_SPECTRA_LENGTH), x55_spectra_raw: bytarr(X55_DATA_LENGTH_MAX)
			if (x55_num_last_hx55 ge 0) then begin
				;  store raw X55 spectrum data until complete, then decompress
				x55_spectrum_count += X55_ELEMENTS_PER_PACKET
				x55_group_num = fix(darray[1]) - 1
				x55_data_raw = hex2byte(darray[2])
				raw_index = indgen(X55_ELEMENTS_PER_PACKET) + x55_group_num*X55_ELEMENTS_PER_PACKET
				if (n_elements(x55_data_raw) eq X55_ELEMENTS_PER_PACKET) then $
					x55_packets[x55_num_last_hx55].x55_spectra_raw[raw_index] = x55_data_raw $
				else begin
					x55_data_error = 1
					print, '***** ERROR: X55 Hex String Conversion did not have 35 bytes.'
				endelse
				;  check if X55 spectrum is ready to uncompress
				if (x55_spectrum_count ge data[data_num_last_hx55].x55_data_length) and (x55_data_error eq 0) then begin
					if keyword_set(debug) then stop, 'STOP: DEBUG x123_decompress INPUTS...'
					new_spectrum = x123_decompress( x55_packets[x55_num_last_hx55].x55_spectra_raw, $
								x55_spectrum_count, $
								x55_packets[x55_num_last_hx55].x55_compress_flag, $
								x55_packets[x55_num_last_hx55].x55_data_length, verbose=verbose )
					if keyword_set(debug) then stop, 'STOP: DEBUG x123 decompress OUTPUT...'
					if (n_elements(new_spectrum) eq X55_SPECTRA_LENGTH)	then begin
						x55_packets[x55_num_last_hx55].x55_spectra = new_spectrum
						x55_packets[x55_num_last_hx55].x55_uncompressed = 1
					endif else begin
						print, '***** ERROR: X55 Decompression failed.'
					endelse
				endif
			endif else begin
				print, '***** ERROR: SX55 packet did not have HX55 packet.'
			endelse
		endif

	endif else data_bad += 1L
endwhile

close, lun
free_lun, lun

; trim down to what was actually read
data = data[0:data_num-1]

; exclude bad data without valid time
wgood = where( data.have_rtc eq 1, numgood )
if (numgood gt 1) then data=data[wgood]

; trim down to what was actually read
messages = messages[0:msg_num-1]

; trim down to what was actually read
ttm_packets = ttm_packets[0:ttm_num-1]

; trim down to what was actually read
x55_packets = x55_packets[0:x55_num-1]

if keyword_set(verbose) then begin
	print, 'DUALSPS_READ_FILE: read ', strtrim(data_num,2), ' records.'
	if (data_bad ne 0) then print, '                      ',strtrim(data_bad,2), ' bad records'
	print, 'DUALSPS_READ_FILE: read ', strtrim(msg_num,2), ' messages.'
	print, 'DUALSPS_READ_FILE: read ', strtrim(ttm_num,2), ' TTM_Packets.'
	print, 'DUALSPS_READ_FILE: read ', strtrim(x55_num,2), ' X55_Packets.'
endif

if keyword_set(debug) then stop, 'DEBUG at end of DUALSPS_READ_FILE ...'

return, data
end
