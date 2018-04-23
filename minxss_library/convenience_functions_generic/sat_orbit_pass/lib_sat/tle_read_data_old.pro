;6/23/2014
;Christina Wilson
;MinXSS
;
;This program gets the TLE data and stores it in an array to be called in the other program
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	Updated to allow for path and filename to be specified
;	otherwise it defaults to  $sat_pass/tle/TLE_latest.dat
;			T. Woods   11/1/2015
;
;	NOTES for downloading TLE values
;		space-track.org
;
;	Full Catalog of TLE and 3LE files:  https://www.space-track.org/#/recent
;	LEO-only Catalog 3LEs:
; https://www.space-track.org/basicspacedata/query/class/tle_latest/ ORDINAL/1/EPOCH/%3Enow-30/MEAN_MOTION/%3E11.25/ECCENTRICITY/%3C0.25/OBJECT_TYPE/payload/orderby/NORAD_CAT_ID/format/3le
;		For Catalog:  download the 3LE and search for satellite name
;
;	Search for single satellite: https://www.space-track.org/#/tle
;
;	Documentation on TLE definition
;		https://www.space-track.org/documentation#/tle
;
;	There are other sites for TLE lists
;		http://www.tle.info/joomla/index.php
;

pro tle_read_data, TLE, path=path, file=file

;  return value for TLE data
TLE = fltarr(2,15)

slash = '/'  ;  slash for Mac = '/', PC = '\'

if keyword_set(path) then begin
	path_name = path
endif else begin
	;  default is to use directory $sat_pass/tle/
    path_name = getenv('sat_pass')
    if strlen(path_name) gt 0 then path_name += slash + 'tle' + slash
    ; else path_name is empty string
endelse
if strlen(path_name) gt 0 then begin
	; check if need to add final back slash
	spos = strpos(path_name, slash, /reverse_search )
	if (spos ne (strlen(path_name)-1)) then path_name += slash
endif

if keyword_set(file) then begin
	file_name = file
endif else begin
	;  default is to use TLE_latest.dat in the default directory
    file_name = 'TLE_latest.dat'
endelse

TLE_filename = path_name + file_name

  ; OLD CODE 2014
  ; path_name = ['','']
  ;Change this for other computers (direct it to the google drive)
  ;This must be changed here AND below in the event procedure AND Sample_sgp4.pro AND TLE_data.pro
  ; path_name[0] = 'C:\Users\rocket\Google Drive\CubeSat'
  ; path_name[1] = '\MinXSS Server\8000 Ground Software\8030 MinXSS_Data_Vis_Software\ISS_TLE.txt'
  ; TLE_filename = strjoin(path_name)

;
;	OPEN and READ the TLE file
;
finfo = file_info(TLE_filename)
line1 = ''
line2 = ''
openr, lun, TLE_filename, /get_lun
readf, lun, line1, line2
close, lun

;
;	PARSE the TLE data from the 2 lines of text
;
line1_arr = strarr(10,1)
line2_arr = strarr(10,1)
line1_arr = STRSPLIT(line1, /EXTRACT)
line2_arr = STRSPLIT(line2, /EXTRACT)

;line 1 TLE Data
TLE[0,1] = line1_arr[0]
TLE[0,2] = STRMID(line1_arr[1], 0, 5)   ;Satellite number
TLE[0,3] = BYTE(STRMID(line1_arr[1], 5, 1))    ;classification (e.g U)
TLE[0,4] = STRMID(line1_arr[2], 0, 2)   ;Launch year (last two digits)
TLE[0,5] = STRMID(line1_arr[2], 2, 3)   ;Launch number during that year
TLE[0,6] = BYTE(STRMID(line1_arr[2], 5,1))    ;piece of the launch (e.g. A)
TLE[0,7] = STRMID(line1_arr[3], 0, 2)   ;Epoch year (last two digits)
TLE[0,8] = STRMID(line1_arr[3], 2, 12) ;Epoch day
TLE[0,9] = line1_arr[4]      ;First time derivative of the mean motion dvided by two
TLE[0,10] = STRMID(line1_arr[5], 0,5) ;second Time Derivative of mean motion divided by six
 Exp_loc = STRPOS(line1_arr[6], '-', 1)
 exponet = STRMID(line1_arr[6], (exp_loc + 1),1)
TLE[0,11] = STRMID(line1_arr[6], 0, exp_loc) * 1.0 * 10^(-exponet-exp_loc+1.0) ; BSTARR drag term
TLE[0,12] = line1_arr[7]	; Element Set Type
TLE[0,13] = STRMID(line1_arr[8], 0, 3) ; Element Number
TLE[0,14] = STRMID(line1_arr[8], 3, 1) ; Checksum

;Line2 TLE Data
TLE[1,1] = line2_arr[0]
TLE[1,2] = line2_arr[1]
TLE[1,3] = line2_arr[2]  ;inclination
TLE[1,4] = line2_arr[3]  ;Right Ascension of Ascending Node
TLE[1,5] = line2_arr[4] * 10^(-7.0) ; Eccentricity
TLE[1,6] = line2_arr[5]  ;Argument of Perigee (degrees)
TLE[1,7] = line2_arr[6]  ;Mean Anomaly (degrees)
TLE[1,8] = STRMID(line2_arr[7], 0,11)  ; mean motion (revs per day)
TLE[1,9] = STRMID(line2_arr[7], 11, 5)  ; Revolution Number at Epoch (rev)
TLE[1,10] = STRMID(line2_arr[7], 16, 1)  ; Checksum

RETURN
END
;end of satpass_tle_read_data.pro
