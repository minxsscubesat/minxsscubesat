;
;	picosim_read_file.pro
;
;	Read picoSIM-SPS text data file
;
;	INPUT:
;		filename	File name of text file  (e.g., HYDRA telemetry file)
;
;	OUTPUT:
;		data		Data array
;
;	History:
;		11/1/2017	Tom Woods: original code
;		3/30/2017	Tom Woods: updated for latest packet format with HYDRA
;
function picosim_read_file, filename, verbose=verbose, debug=debug

data = -1L
if (n_params() lt 1) then begin
	print, 'USAGE: data = picosim_read_file( filename )'
	return, data
endif

if (not file_test(filename)) then begin
	print, 'ERROR: filename is not a valid file !'
	return, data
endif

if keyword_set(debug) then verbose=1
if keyword_set(verbose) then print, 'PICOSIM_READ_FILE: reading ', filename, ' ...'

data_num = 0L
data_bad = 0L
data_incomplete = 0L
gotTMP = 0
gotVISNIR = 0
gotSPS = 0
dstr = ' '
openr,lun,filename,/get_lun
finfo = fstat(lun)
data_max = long(finfo.size / 80. / 3.) + 10L
;  create the data array
data1 = { jd: 0.0D0, year: 0, month: 0, day: 0, hour: 0, minute: 0, second: 0, $
	sequence_count: 0L, eps_temperature: 0.0, $
	picosim_type: 0, picosim_integ_time: 0.0, picosim_num_avg: 0, $
	picosim_data: fltarr(6), picosim_temperature: 0.0, $
	sps_temperature: 0.0, sps_num_avg: 0, sps_data: fltarr(4), $
	sps_quad_sum: 0.0, sps_quad_x: 0.0, sps_quad_y: 0.0  }
data = replicate(data1, data_max )

; STRSPLIT pattern with Space, comma, slash, colon, Tab (0x09)
pattern = ' ,/:' + string(byte(9))

;
;	DATA lines (packets) have fixed format of 80 characters per line
; 	PACKETS have SYNC of "PS." and ID of "TMP", "NIR", "VIS", "SPS"
;
while (not eof(lun)) do begin
	readf,lun,dstr
	darray = strsplit( dstr, pattern, /extract, count=nstr )
	; if keyword_set(debug) then stop, 'DEBUG parse of file string...'
	if (nstr ge 9) then begin
		if (darray[0] eq 'PS.TMP') then begin
			; parse PS.TMP line
			data[data_num].sequence_count = long(darray[1])
			data[data_num].year = fix(darray[2])
			data[data_num].month = fix(darray[3])
			data[data_num].day = fix(darray[4])
			data[data_num].hour = fix(darray[5])
			data[data_num].minute = fix(darray[6])
			data[data_num].second = fix(darray[7])
			data[data_num].jd = julday( data[data_num].month, data[data_num].day, $
									data[data_num].year, data[data_num].hour, $
									data[data_num].minute, data[data_num].second )
			data[data_num].sps_temperature = float(darray[8])
			data[data_num].eps_temperature = float(darray[9])
			gotTMP = 1
			gotVISNIR = 0  ; reset the other "got" flags for a new sequence of packets
			gotSPS = 0
		endif
		if (darray[0] eq 'PS.VIS') OR (darray[0] eq 'PS.NIR') then begin
			; parse PS.VIS / PS.NIR picoSIM data line
			; configure picosim_type based on sensor name
			data.picosim_type = (darray[0] eq 'PS.NIR'? 3 : 2)
			data[data_num].picosim_integ_time = float(darray[1]) * 0.0028 ; convert to seconds
			data[data_num].picosim_num_avg = float(darray[2])
			for i=0,5 do data[data_num].picosim_data[i] = float(darray[i+3])
			data[data_num].picosim_temperature = float(darray[9])
			gotVISNIR = 1
		endif
		if (darray[0] eq 'PS.SPS') then begin
			data[data_num].sps_num_avg = float(darray[1])
			for i=0,3 do data[data_num].sps_data[i] = float(darray[i+2])
			data[data_num].sps_quad_sum = float(darray[6])
			data[data_num].sps_quad_x = float(darray[7])
			data[data_num].sps_quad_y = float(darray[8])
			gotSPS = 1
			;  increment packet count if got full set of TMP, VIS/NIR, and SPS packets
			if (gotTMP ne 0) AND (gotVISNIR ne 0) AND (gotSPS ne 0) then data_num += 1L $
			else data_incomplete += 1L
		endif
	endif else data_bad += 1L
endwhile

close, lun
free_lun, lun

; trim down to what was actually read
data = data[0:data_num-1]
if keyword_set(verbose) then begin
	print, 'PICOSIM_READ_FILE: read ', strtrim(data_num,2), ' records.'
	if (data_bad ne 0) then print, '                      ',strtrim(data_bad,2), ' bad records'
	if (data_incomplete ne 0) then print, '                      ',strtrim(data_incomplete,2), ' incomplete records'
endif

if keyword_set(debug) then stop, 'DEBUG at end of PICOSIM_READ_FILE ...'

return, data
end
