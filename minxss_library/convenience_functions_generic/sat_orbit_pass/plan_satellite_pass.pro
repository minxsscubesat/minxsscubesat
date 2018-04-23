;
;	plan_satellite_pass
;
;	This procedure will download the latest TLE, calculate passes over ground station,
;	and write HTML table to web page.
;
;	It also writes TLE file for SatPC32 using the SatPC option in call to tle_download_latest.pro
;
;	This is similar to minxss_satellite_pass.pro with the addition of the Fairbanks ground station
;	and also addition of 2 more satllites: QB50 and MinXSS-2
;
;	********************************
;	***                          ***
;	***   Run this once a day    ***
;	***                          ***
;	********************************
;
;	INPUT
;		station		Required input to specify which Ground Station by name ("Boulder", "Fairbanks")
;		date_range	Option to specify JD date range, default is to calculate passes for next 10 days
;		debug		Option to not download latest TLE while debugging this procedure
;		verbose		Option to print information while running
;		auto_pass	Option to generate AUTO pass scripts based on Pass Elevation
;		no_orbit_number  Option to not generate Satellite Orbit Number
;
;	OUTPUT
;		IDL save set of passes in minxss_passes_latest.sav
;		IDL save set of passes in minxss_passes_DATE_TIME.sav
;		HTML table of passes in minxss_passes_latest.html
;		HTML table of passes in minxss_passes_DATE_TIME.html
;
;		pass_data		Optional return of "passes" data structure array
;
;	PROCEDURE
;	1.  Download latest TLE for MinXSS
;	2.  Calculate passes for next 2 weeks
;	3.  Write pass information to IDL save set and HTML table
;
;	HISTORY
;		2015-Nov-23  T. Woods	Original Code
;		2016-Feb-05  T. Woods	Updated so "location" is saved in its own SaveSet file
;   	2016-Feb-09  T. Woods Updated so call to tle_download_latest hss the /SatPC option
;		2016-Feb-21	 T. Woods Updated to add CADRE priority check (higher GS elevation) - new HTML table column
;		2016-Feb-27  T. Woods Updated to also create CSV text file with pass info and AMES NODeS-2x CubeSat
;		2016-Jun-22	T. Woods	Updated so Auto scripts are generated based on Elevation (/auto_pass)
;		2016-Aug-01  T. Woods  Updated so HTML table is also made with MST column
;   	2016-Nov-02  T. Woods  Updated so set_ephemeris_latest.prc HYDRA Script is generated every time
;		2017-Mar-26	 T. Woods  Updated for tracking multiple satellites: MinXSS-1, QB50 and MinXSS-2
;								and addition of Fairbanks Ground Station
;		2017-Mar-27  T. Woods  Updated to be generic pass planning tool with Ground Station definition file
;								and list of satellites for that ground station in a definition file too
;
;   Space-Track.org names
;	-------------------
;	MinXSS-1 =  MINXSS
;	QB50 = ISS (ZARYA)   		 (for initial testing)
;	MinXSS-2 = IRIS (ESRO 2B)	 (for initial testing)
;

pro plan_satellite_pass, station, date_range, debug=debug, verbose=verbose, elevation_min=elevation_min, $
	pass_data=pass_data, pass_conflict=pass_conflict, auto_pass=auto_pass, no_orbit_number=no_orbit_number

;
;	configure inputs
;
if (n_params() lt 1) then begin
	print, 'WARNING: input the station name "Boulder" or "Fairbanks" to run plan_satellite_pass.pro !'
	station = 'Boulder'
	print, 'WARNING: default station ', station, ' is being used.'
endif
station_caps = strupcase(station)
if (strlen(station_caps) lt 1) then begin
	print, 'ERROR: valid station name is needed to run plan_satellite_pass.pro !'
	pass_data = -1L
	return
endif

if (n_params() lt 2) or (n_elements(date_range) lt 2) then begin
	date1 = systime(/utc,/jul) ; julian date for the current time
	date1 = long(date1-0.5) + 0.5D0  ; force to day boundary
	date2 = date1 + 10   ; add 10 days for planning
	date_range = [date1, date2]
endif else begin
	date1 = date_range[0]
	date2 = date_range[1]
endelse
date_str = string( date1, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' ) + '_' + $
	string( date2, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' )
if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then $
		print, 'PLAN_SATELLITE_PASS is getting passes for ',station,' station for ', date_str

;
;	Set Pass Elevation Minimum
;
pass_elevation_min = 3.0  ; degrees
if keyword_set(elevation_min) then begin
	if (elevation_min[0] gt 0) and (elevation_min[0] lt 90) then begin
		pass_elevation_min = elevation_min[0]
		if keyword_set(verbose) then $
			print, '*** Pass Elevation Minimum (degrees) = ', pass_elevation_min
	endif
endif

;
;	set flag to update orbit number file
;
if keyword_set(no_orbit_number) then do_orbit_number = 0 else do_orbit_number = 1

;
;	Set TLE path
;  		default is to use directory $TLE_dir
;
;  slash for Mac = '/', PC = '\'
;  File Copy for Mac = 'cp', PC = 'copy'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then path_name += slash
; else path_name is empty string
if keyword_set(verbose) then print, '*** TLE path = ', path_name

;
; option to also copy latest pass files to dropbox folders too
;
dropbox_tle_dir = getenv('Dropbox_dir')
if strlen(dropbox_tle_dir) ne 0 then dropbox_tle_dir += slash + 'tle' + slash

;
;	for the STATION input, read the station_location_STATION.txt definition file
;			comment line
;			longitude value
;			latitude value
;			hours from UT, time zone name (standard)
;
gs_locate_file = station_caps + slash + 'station_location_' + station_caps + '.txt'
longitude = 0.0D0
latitude = 0.0D0
zone_hours = -7L
zone_name = 'MST'
ON_IOERROR, ExitBadFile1

; Use the GET_LUN keyword to allocate a logical file unit.
OPENR, UNIT1, path_name + gs_locate_file, /GET_LUN

inStr = ' '
READF, UNIT1, inStr		; read comment line
READF, UNIT1, inStr		; read longitude
longitude = double(strtrim(inStr,2))
READF, UNIT1, inStr		; read latitude
latitude = double(strtrim(inStr,2))
READF, UNIT1, inStr		; read hours from UT and Zone name
str2 = strsplit( inStr, ',', /extract )
if (n_elements(str2) ne 2) then goto, DoneFile1
zone_hours = long(strtrim(str2[0],2))
zone_name = strupcase(strtrim(str2[1],2))

; Clean up file reading
GOTO, DoneFile1
; Exception label. Print the error message.
ExitBadFile1: PRINT, !ERR_STRING
 ; Close and free the input/output unit.
DoneFile1: FREE_LUN, UNIT1
ON_IOERROR, NULL

if (longitude eq 0.0) and (latitude eq 0.0) then begin
	print, 'ERROR: unable to read the file ', path_name + gs_locate_file, ' !'
	pass_data = -1L
	if keyword_set(debug) then stop, 'DEBUG file issue ...'
	return
endif

if (longitude lt -180.) or (longitude gt 180.) or (latitude lt -90.) or (latitude gt 90.) then begin
	print, 'ERROR: station longitude and latitude are invalid values !'
	print, '       Longitude range is -180 to 180 degrees.'
	print, '       Latitude range is -90 to 90 degrees.'
	pass_data = -1L
	if keyword_set(debug) then stop, 'DEBUG file issue ...'
	return
endif
gs_location = [ longitude, latitude ]

;
;	for the STATION input, read the satellites_track_STATION.txt definition file
;			comment line
;			satellite_ID, name_in_SpaceTrack, name_for_output_file
;			... for more satellites
;
sat_list_file = station_caps + slash + 'satellites_track_' + station_caps + '.txt'
MAX_SATELLITES = 20L
num_satellites = 0
satid = lonarr(MAX_SATELLITES)
mission_in = strarr(MAX_SATELLITES)
mission_out = strarr(MAX_SATELLITES)
ON_IOERROR, ExitBadFile2

; Use the GET_LUN keyword to allocate a logical file unit.
OPENR, UNIT2, path_name + sat_list_file, /GET_LUN

READF, UNIT2, inStr		; read comment line
while NOT EOF(UNIT2) do begin
  READF, UNIT2, inStr		; read satellite string
  inStr = strtrim(inStr,2)
  if (strlen(inStr) lt 1) then goto, DoneFile2
  str3=strsplit( inStr, ',', /extract )
  if (n_elements(str3) ne 3) then goto, DoneFile2
  satid[num_satellites] = long(strtrim(str3[0],2))
  mission_in[num_satellites] = strtrim(str3[1],2)
  mission_out[num_satellites] = strtrim(str3[2],2)
  num_satellites += 1
endwhile

; Clean up file reading
GOTO, DoneFile2
; Exception label. Print the error message.
ExitBadFile2: PRINT, !ERR_STRING
 ; Close and free the input/output unit.
DoneFile2: FREE_LUN, UNIT1
ON_IOERROR, NULL

if (num_satellites lt 1) then begin
	print, 'ERROR: unable to read the file ', path_name + sat_list_file, ' !'
	pass_data = -1L
	if keyword_set(debug) then stop, 'DEBUG file issue ...'
	return
endif

if keyword_set(verbose) then begin
	print, station_caps + ' Ground Station location is at ', longitude, latitude
	print, 'Number of satellites tracking = ', num_satellites
	for k=0,num_satellites-1 do print, '      ', mission_out[k], '   sat_id = ', satid[k]
endif

;
;	1.  Download latest TLE for the satellites in the list
;				configure SatPC32 file with those TLEs
;
if not keyword_set(debug) then begin
	print, 'Loading TLE catalog and searching for satellites...'
	tle_download_latest, tle, satid=satid[0], path=path_name, /output, verbose=verbose
	if n_elements(tle) lt 3 then begin
		print, 'ERROR: could not find TLE for satellite ', mission_in[0]
		if keyword_set(debug) then stop, 'DEBUG TLE issue...'
		return
	endif
	;
    ;  Write SatPC32 file
    ;
    satpc_dir = getenv('SATPC_TLE_dir')
    if strlen(satpc_dir) ne 0 then satpc_dir += slash
    satpc_file = 'satellites_'+station_caps+'.tle'
    satpc_full = satpc_dir + satpc_file
    if keyword_set(verbose) then print, 'SATPC file written to ', satpc_full
    openw, lun, satpc_full, /get_lun
    printf,lun,mission_out[0]
    printf,lun,tle[1]
    printf,lun,tle[2]

	for k=1,num_satellites-1 do begin
		tle_download_latest, tle, satid=satid[k], path=path_name, /output, verbose=verbose, /nodownload
		if n_elements(tle) ge 3 then begin
		    printf,lun,mission_out[k]
    		printf,lun,tle[1]
    		printf,lun,tle[2]
		endif
	endfor
	close, lun
    free_lun, lun
    ;
    ;  Copy this SatPC file to Dropbox too and also copy over TLE files for Level 0D processing
    ;
    if (strlen(dropbox_tle_dir) gt 0) then begin
    	dropbox_dir2 = dropbox_tle_dir + station_caps + slash
    	if keyword_set(verbose) then print, 'Copying SatPC file to ', dropbox_dir2+satpc_file
    	copy_cmd = file_copy + '"' + satpc_full + '" "' + dropbox_dir2+satpc_file + '"'
    	spawn, copy_cmd

    	for k=0,num_satellites-1 do begin
    		tle_name = string(long(satid[k]),format='(I08)') + '.tle'
    		if keyword_set(verbose) then print, 'Saving '+mission_out[k]+' TLE ' + tle_name $
    										+ ' to ' + dropbox_tle_dir
    		copy_cmd = file_copy + '"' + path_name+tle_name + '" "' + dropbox_tle_dir+tle_name
    		spawn, copy_cmd
		endfor
    endif
 endif

;
;	2.  Calculate passes for next 10 days for each satellite
;
number_passes_total = 0L
save_path = path_name + station_caps + slash
save_name3_base = 'location_latest_'
pass_orbit_number = -1L

for k=0,num_satellites-1 do begin
  spacecraft_pass, date_range, passes1, number_passes1, id_satellite=satid[k], $
  	satellite_name=mission_out[k], station_name=station_caps, ground_station=gs_location, $
  	tle_path=path_name, verbose=verbose, sc_location=location, elevation_min = pass_elevation_min
  if (number_passes1 lt 1) then begin
	print, 'WARNING: no passes found for the satellite ', mission_out[k]
	if keyword_set(debug) then stop, 'DEBUG this error ...'
  endif else begin
  	if keyword_set(verbose) then print, 'Number of Passes for ', mission_out[k],'  = ', number_passes1
  	if (number_passes_total eq 0) then passes = passes1 else passes = [ passes, passes1 ]
  	number_passes_total += number_passes1
  	;  save the location information as IDL save set
  	save_name3 = save_name3_base + mission_out[k] + '.sav'
	if keyword_set(verbose) then print, 'Saving "location" data to ', save_path+save_name3
	save, location, file=save_path+save_name3
	;
	;	update orbit number file
	;
	if (do_orbit_number ne 0) then begin
	  spacecraft_orbit_number, location, mission_out[k], data=orbit_num, verbose=verbose, debug=debug
	  ;
	  ;	determine orbit number for each pass
	  ;
	  orbit_num_yd = reform(orbit_num[1,*] + orbit_num[2,*]/(24.D0*3600.))
	  pass_yd = jd2yd( passes1.start_jd )
	  pass_orbit_number1 = long( interpol( reform(orbit_num[0,*]), orbit_num_yd, pass_yd ) )
	  if (number_passes_total eq 1) then pass_orbit_number = pass_orbit_number1 $
	  		else pass_orbit_number = [pass_orbit_number, pass_orbit_number1]
	  if keyword_set(debug) then print, 'STOP for checking out '+mission_out[k]+' pass_orbit_number ...'
	  if strlen(dropbox_tle_dir) ne 0 then begin
		;  also copy orbit_number data file to dropbox link
		orbit_dir = path_name + 'orbit_number' + slash
		dropbox_orbit_dir = dropbox_tle_dir + 'orbit_number' + slash
		orbit_number_file = mission_out[k]+'_orbit_number.dat'
		if keyword_set(verbose) then print, 'Saving Orbit Number file to ', dropbox_orbit_dir+orbit_number_file
		copy_cmd = file_copy + '"' + orbit_dir+orbit_number_file + '" "' + dropbox_orbit_dir+orbit_number_file + '"'
		spawn, copy_cmd
	  endif
	endif
  endelse
endfor

;
;	time sort the pass data array
;
isort = sort( passes.start_jd )
passes = passes[isort]
if (do_orbit_number ne 0) then pass_orbit_number = pass_orbit_number[isort]

if keyword_set(debug) then stop, 'DEBUG sorting of passes ...'

if keyword_set(verbose) then print, 'Total Number of Passes = ', number_passes_total

;
;	3.  Write pass information to IDL save set, HTML table, and CSV text file
;
save_path = path_name + station_caps + slash
save_name1 = 'passes_latest_'+station_caps+'.sav'
if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path+save_name1
save, passes, pass_orbit_number, file=save_path+save_name1

archive_path = save_path + 'archive' + slash
save_name2 = 'passes_' + date_str + '_' + station_caps+'.sav'
if keyword_set(verbose) then print, 'Saving "passes" data to ', archive_path+save_name2
save, passes, pass_orbit_number, file=archive_path+save_name2

if strlen(dropbox_tle_dir) ne 0 then begin
  save_path2 = dropbox_tle_dir + station_caps + slash
  if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path2+save_name1
  save, passes, pass_orbit_number, file=save_path2+save_name1
endif

;
;	Make HTML files now
;
;  updated 2016/08/01 so it makes  HTML table with MDT and MST columns
;
table_id = 0   ; 0 = MDT as needed for OPS-1 PC and 1 = MST for human planners

zone_name2 = zone_name   ; make daylight name
strput, zone_name2, 'D', strlen(zone_name2)-2

html_name1_dt = 'passes_latest_' + zone_name2 + '_' + station_caps + '.html'
html_name1_st = 'passes_latest_' + zone_name + '_' + station_caps + '.html'
html_name2 = 'passes_' + date_str + '_' + station_caps + '.html'
; elev_range = [ [0., 12.], [12., 24.], [24., 36.], [36., 90] ]
;  updated 7/29/2016 T. Woods
elev_range = [ [0., 15.], [15., 30.], [30., 45.], [45., 90] ]
; old HTML code
elev_color = [ ' bgcolor="#C0C0C0"', ' bgcolor="#80C080"', ' bgcolor="#80F080"' ]
elev_color = [ ' bgcolor="#808080"', ' bgcolor="#C0C0C0"', ' bgcolor="#80F080"' ]
; new HTML5 CSS style
elev_color = [ ' style="background-color:grey"', ' style="background-color:lightgrey"', $
						' style="background-color:lightgreen"', ' style="background-color:lime"' ]
num_elev = n_elements(elev_color)

REPEAT_HTML_TABLE:
if (table_id eq 0) then begin
  html_base = html_name1_dt
  html_zt_column = '    <th>Start Time ('+zone_name2+')</th>'
  ZT_DIFF = zone_hours + 1
  ZT_NAME = zone_name2
endif else begin
  html_base = html_name1_st
  html_zt_column = '    <th>Start Time ('+zone_name+')</th>'
  ZT_DIFF = zone_hours
  ZT_NAME = zone_name
endelse

if keyword_set(verbose) then print, 'Saving "passes" table to ', save_path+html_base
openw, lun, save_path+html_base, /get_lun
printf, lun, '<!DOCTYPE html>'
printf, lun, '<html>'
printf, lun, '<head>'
printf, lun, '<title>Satellite Passes at ' + station_caps + ' for ' + date_str + '</title>'
printf, lun, '<style>'
printf, lun, 'table {'
printf, lun, '	border: 3px solid blue;'
printf, lun, '	border-collapse: collapse;'
printf, lun, '}'
printf, lun, 'th {'
printf, lun, '	border: 3px solid blue;'
printf, lun, '	text-align: center;'
printf, lun, '	padding: 3px;'
printf, lun, '	background-color: lightblue;'
printf, lun, '}'
printf, lun, 'td {'
printf, lun, '	border: 2px solid black;'
printf, lun, '	text-align: center;'
printf, lun, '	padding: 3px;'
printf, lun, '}'
printf, lun, 'caption {'
printf, lun, '	font-size: 150%;'
printf, lun, '	font-weight: bold;'
printf, lun, '	padding: 6px;'
printf, lun, '}'
printf, lun, '</style>'
printf, lun, '</head>'
printf, lun, '<body>'
printf, lun, '<table>'
printf, lun, '<caption>Satellite Passes at ' + station_caps + ' for ' + date_str + '</caption>'
printf, lun, '<thead>'
printf, lun, '    <th>Satellite</th>'
printf, lun, html_zt_column
printf, lun, '    <th>Start Time (UT)</th>'
printf, lun, '    <th>End Time (UT)</th>'
printf, lun, '    <th>Duration Minutes</th>'
printf, lun, '    <th>Peak Elevation</th>'
printf, lun, '    <th>In Sunlight</th>'
printf, lun, '</thead>'

;  generate and save Pass date-time string for use later by /auto_pass
pass_date_str = strarr(number_passes_total)

for k=0L, number_passes_total-1 do begin
	; pass_num_str = string( pass_orbit_number[k], format='(I6)')
	sat_name = passes[k].satellite_name
	caldat, passes[k].start_jd + ZT_DIFF / 24.D0, month, day, year, hh, mm, ss
	start_ZT_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+ZT_NAME
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	; pass_date_str[] is needed for /auto_pass option below
	pass_date_str[k] = string(long(year),format='(I04)') + string(long(month),format='(I02)')+$
						string(long(day),format='(I02)') + '_' + $
						string(long(hh),format='(I02)') + string(long(mm),format='(I02)')
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	elevation_str += ' ' + (passes[k].dir_NS eq 0 ? 'N' : 'S' )
	elevation_str += ' ' + (passes[k].dir_EW eq 0 ? 'E' : 'W' )
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
	tr_color= elev_color[0]
	doPrint = 0
	;  only Print Passes with Elevation > 20 deg (ii ge 1)
	;  with repaired antenna (6/16/16) include all passes again (ii eq 0)
	for ii=0,num_elev-1 do begin
		if (passes[k].max_elevation ge elev_range[0,ii]) and $
				(passes[k].max_elevation lt elev_range[1,ii]) then begin
			tr_color = elev_color[ii]
			doPrint = 1
		endif
	endfor
	if (doPrint ne 0) then begin
	  printf, lun, '<tr' + tr_color + '>'
	  ; printf, lun, '    <td>' + pass_num_str + '</td>'    ; Minxss-1 option
	  printf, lun, '    <td>' + sat_name + '</td>'		; new in 2017
	  printf, lun, '    <td>' + start_ZT_str + '</td>'
	  printf, lun, '    <td>' + start_str + '</td>'
	  printf, lun, '    <td>' + end_str + '</td>'
	  printf, lun, '    <td>' + duration_str + '</td>'
	  printf, lun, '    <td>' + elevation_str + '</td>'
	  printf, lun, '    <td>' + sun_str + '</td>'
	  printf, lun, '</tr>'
	endif
endfor
printf, lun, '</table>'
printf, lun, '<P>'
printf, lun, 'This table was generated by plan_satellite_pass.pro on '+systime(/utc)+' for ' $
				+strtrim(number_passes_total,2)+' passes.'
printf, lun, '<P>'
printf, lun, '</body>'
printf, lun, '<html>'
close, lun
free_lun, lun

if strlen(dropbox_tle_dir) ne 0 then begin
    save_path2 = dropbox_tle_dir + station_caps + slash
    if keyword_set(verbose) then print, 'Saving "passes" table to ', save_path2+html_base
    copy_cmd = file_copy + '"' + save_path+html_base + '" "' + save_path2+html_base + '"'
    spawn, copy_cmd
endif

if (table_id eq 0) then begin
  if keyword_set(verbose) then print, 'Saving "passes" table to ', archive_path+html_name2
  copy_cmd = file_copy + '"' + save_path+html_base + '" "' + archive_path+html_name2 + '"'
  spawn, copy_cmd
  ;  repeat the HTML table but for MST column
  table_id += 1
  goto, REPEAT_HTML_TABLE
endif else begin
  table_id += 1
endelse

;
;  make CSV files now
;
csv_name1 = 'passes_latest_' + station_caps + '.csv'
csv_name2 = 'passes_' + date_str + '_' + station_caps + '.csv'

if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', save_path+csv_name1
openw, lun, save_path+csv_name1, /get_lun
printf, lun, 'Satellite Passes at ' + station_caps + ' for ' + date_str
csv_header = 'Satellite, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight'
printf, lun, csv_header
for k=0L, number_passes_total-1 do begin
	; pass_num_str = string( pass_orbit_number[k], format='(I6)')
	sat_name = passes[k].satellite_name
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
	; MinXSS-1 option used pass_num_str  instead of pass_name
	pass_str = sat_name + ', ' + start_str + ', ' + end_str + ', ' + duration_str + ', ' + $
				elevation_str + ', ' + sun_str
	printf, lun, pass_str
endfor
printf, lun, ' '
printf, lun, 'This table was generated by plan_satellite_pass.pro on ' + systime(/utc)+' for ' $
				+strtrim(number_passes_total,2)+' passes.'
printf, lun, ' '
close, lun
free_lun, lun

if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', archive_path+csv_name2
copy_cmd = file_copy + '"' + save_path+csv_name1 + '" "' + archive_path+csv_name2 + '"'
spawn, copy_cmd

if strlen(dropbox_tle_dir) ne 0 then begin
  csv_path2 = dropbox_tle_dir + station_caps + slash
  if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', csv_path2+csv_name1
  copy_cmd = file_copy + '"' + save_path+csv_name1 + '" "' +csv_path2+csv_name1 + '"'
  spawn, copy_cmd, exit_status=status
endif

;
;	SCRIPT planning has moved to plan_scripts_SATELLITE.pro
;	Creating Ephemeris for a satellite has also moved to plan_scripts_SATELLITE.pro
;

if keyword_set(verbose) then print, 'Total Number of Passes planned is ', number_passes_total

if keyword_set(debug) then stop, 'DEBUG plan_satellite_pass() results ...'

return
end

