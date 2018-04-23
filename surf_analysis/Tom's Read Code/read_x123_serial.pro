;
;	extract out X123 status info from XRS MCU RS422 Serial Data Stream
;
;	T. Woods
;	6/28/12
;

;
;	OPEN the XRS Raw Dump file
;
file = 'XRS_Raw_Dump_06_23_12_13-13_FLIGHT'
dir = '$projects/Rocket_Folder/Data_36286/WSMR_dataview/Flight_36286/'

openr,lun,dir+file, /get_lun

;
;	prepare for X123 status data array
;
file_out = 'X123_Serial_Dump_36286.sav'
dir_out = '$projects/Rocket_Folder/Data_36286/WMSR/data_saveset/'
; >SP record has packet_id (33025), sp_len (768), packet_len (776), rec_num (16)
; >SS record has 6 numbers: packet_len (72), num_parameters (6), rec_num (2), fast_count, slow_count, GPC_count, integ_time, det_temp_10K, brd_temp_C
;		- not many of these survive into the serial stream
x123temp = { time_gps: 0L, time: 0.0, sp_num: 0L, sp_len: 0, packet_len: 0, rec_count: 0, $
		count_total: 0L, count_fast: 0L, temp_det: 0.0, temp_brd: 0.0 }
x123_data = replicate( x123temp, 5000 )
x123_count = 0L
gps_tzero = 630720019L

strin = ' '
while (not eof(lun)) do begin
	readf,lun, strin
	isync = strstr(strin,"SS")
	isync2 = strstr(strin,"SP")
	;
	;	code to parse data and put into x123_data structure
	;		 +++++++++++++++
	;
endwhile

close, lun
free_lun, lun

;
;	save the X123 data
;
if (x123_count gt 0) then begin
  print, 'Saving X123 Data (', strtrim(x123_count,2), ' records) in ', dir_out, file_out
  x123_data = x123_data[0:x123_count-1]
  save, x123_data, file=dir_out+file_out
endif else print, 'WARNING: No X123 Data was found.'

end
