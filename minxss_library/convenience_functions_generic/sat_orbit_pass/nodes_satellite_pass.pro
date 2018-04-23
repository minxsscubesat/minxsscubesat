;
;	nodes_satellite_pass
;
;	This procedure will download the latest TLE, calculate passes over ground station,
;	and write HTML table to web page.
;
;	It also writes TLE file for SatPC32 using the SatPC option in call to tle_download_latest.pro
;
;	********************************
;	***                          ***
;	***   Run this once a day    ***
;	***                          ***
;	********************************
;
;	INPUT
;		date_range	Option to specify date range, default is to calculate passes for next 2 weeks
;		debug		Option to not download latest TLE while debugging this procedure
;		verbose		Option to print information while running
;
;	OUTPUT
;		IDL save set of passes in nodes_passes_latest.sav
;		IDL save set of passes in nodes_passes_DATE_TIME.sav
;		HTML table of passes in nodes_passes_latest.html
;		HTML table of passes in nodes_passes_DATE_TIME.html
;
;		pass_data		Optional return of "passes" data structure array
;		pass_conflict	Optional return of NODES pass conflict information
;
;	PROCEDURE
;	1.  Download latest TLE for NODES
;	2.  Calculate passes for next 2 weeks
;	3.  Write pass information to IDL save set and HTML table
;
;	HISTORY
;		2015-Nov-23  T. Woods	Original Code
;		2016-Feb-05  T. Woods	Updated so "location" is saved in its own SaveSet file
;   	2016-Feb-09  T. Woods Updated so call to tle_download_latest hss the /SatPC option
;		2016-Feb-21	 T. Woods Updated to add NODES priority check (higher GS elevation) - new HTML table column
;		2016-Feb-27  T. Woods Updated to also create CSV text file with pass information
;
pro nodes_satellite_pass, date_range, debug=debug, verbose=verbose, $
	no_conflict=no_conflict, pass_data=pass_data, pass_conflict=pass_conflict

;
;	configure inputs
;
if (n_params() lt 1) or (n_params(date_range) lt 2) then begin
	date1 = systime(/utc,/jul) ; julian date for the current time
	date1 = long(date1-0.5) + 0.5D0  ; force to day boundary
	date2 = date1 + 14
	date_range = [date1, date2]
endif else begin
	date1 = date_range[0]
	date2 = date_range[1]
endelse
date_str = string( date1, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' ) + '_' + $
	string( date2, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' )
if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then print, 'NODES_SATELLITE_PASS is getting passes for ', date_str

;
;	Set TLE path
;  		default is to use directory $TLE_dir
;
;  slash for Mac = '/', PC = '\'
;  File Copy for Mac = 'cp', PC = 'copy'
if !version.os_family eq 'Windows' then begin
    slash = '\' 
    file_copy = 'copy '
endif else begin
    slash = '/'
    file_copy = 'cp '
endelse

path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then path_name += slash
; else path_name is empty string
if keyword_set(verbose) then print, '*** TLE path = ', path_name

;
;  *****  DEFINE NODES MISSION NAME FOR TLE SEARCH
;		For now, use ISS
;
mission = 'ISS (ZARYA)'
satid = 25544		; Satellite ID for ISS is 25544
gs_long_lat = [ -122.0619D0, 37.4272D0  ]  ; NODES (NASA AMES) longitude and latitude

;
;	1.  Download latest TLE for NODES
;
if not keyword_set(debug) then begin
	tle_download_latest, tle, mission=mission, path=path_name, /output, verbose=verbose
endif

;
;	2.  Calculate passes for next 2 weeks
;
spacecraft_pass, date_range, passes, number_passes, id_satellite=satid, $
	ground_station=gs_long_lat, tle_path=path_name, verbose=verbose, sc_location=location

pass_data = passes
if (number_passes lt 1) then begin
	print, 'ERROR finding any passes for ', date_str
	if keyword_set(debug) then stop, 'DEBUG this error ...'
	return
endif

;
;	Check pass conflicts between NODES in Michigan and MinXSS in Colorado
;	Highest Priority for overlapping passes is the one with largest maximum elevation
;
pass_conflict1 = { priority: ' ', reason: ' ', lost_flag: 0 }
pass_conflict = replicate( pass_conflict1, number_passes )
for i=0,number_passes-1 do begin
	pass_conflict[i].priority = 'NODES'
	pass_conflict[i].reason = 'N/A'
	pass_conflict[i].lost_flag = 0
endfor
if not keyword_set(no_conflict) then begin
	minxss_path = path_name + 'pass_saveset' + slash
	minxss_name = 'minxss_passes_latest.sav'
	nodes_passes = passes
	if keyword_set(verbose) then print, 'Reading MinXSS pass info from ', minxss_name, ' ...'
	restore, minxss_path+minxss_name
	minxss_passes = passes
	passes = nodes_passes
	;
	;  check each MinXSS pass for NODES pass conflict
	;		MinXSS pass has to have more than 2 minutes overlap and
	;		MinXSS has to have larger maximum elevation over its ground station (GS) than NODES GS
	;
	time_limit = 2.D0 / (24. * 60.D0)   ; 2 minutes in units of Julian Days
	lost_count = 0L
	for i=0,number_passes-1 do begin
		time1 = passes[i].start_jd + time_limit
		time2 = passes[i].end_jd - time_limit
		wbad = where( ((minxss_passes.start_jd gt time1) and (minxss_passes.start_jd lt time2)) $
			OR ((minxss_passes.end_jd gt time1) and (minxss_passes.end_jd lt time2)), num_bad )
		if (num_bad ge 1) then begin
			pass_conflict[i].reason = strtrim(string( minxss_passes[wbad[0]].max_elevation, format='(F6.1)' ), 2)
			if (minxss_passes[wbad[0]].max_elevation gt passes[i].max_elevation) then begin
				pass_conflict[i].priority = 'MinXSS'
				pass_conflict[i].lost_flag = 1
				lost_count += 1L
			endif
		endif
	endfor
	if keyword_set(debug) or keyword_set(verbose) then begin
		print, 'Number of NODES Passes lost to MinXSS = ', strtrim(lost_count, 2), ' (', $
				strtrim(string(lost_count*100./number_passes,format='(F7.1)'),2) + '%)'
	endif
endif

;
;	3.  Write pass information to IDL save set, HTML table, and CSV text file
;
save_path = path_name + 'pass_saveset' + slash
save_name1 = 'nodes_passes_latest.sav'
save_name2 = 'nodes_passes_' + date_str + '.sav'
save_name3 = 'nodes_location_latest.sav'

if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path+save_name1
save, passes, file=save_path+save_name1

; if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path+save_name2
; save, passes, file=save_path+save_name2

; if keyword_set(verbose) then print, 'Saving "location" data to ', save_path+save_name3
; save, location, file=save_path+save_name3

html_path = path_name + 'pass_html' + slash
html_name1 = 'nodes_passes_latest.html'
html_name2 = 'nodes_passes_' + date_str + '.html'

if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path+html_name1
openw, lun, html_path+html_name1, /get_lun
printf, lun, '<!DOCTYPE html>'
printf, lun, '<html>'
printf, lun, '<head>'
printf, lun, '<title>NODeS-2x CubeSat Passes for ' + date_str + '</title>'
printf, lun, '<style>'
printf, lun, 'table {'
printf, lun, '	border: 3px solid blue;'
printf, lun, '	border-collapse: collapse;'
printf, lun, '}'
printf, lun, 'th {'
printf, lun, '	border: 3px solid blue;'
printf, lun, '	text-align: center;'
printf, lun, '	padding: 3px;'
printf, lun, '	background-color: lightgrey;'
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
printf, lun, '<caption>NODeS-2x CubeSat Passes for ' + date_str + '</caption>'
printf, lun, '<thead>'
printf, lun, '    <th>Pass #</th>'
printf, lun, '    <th>Start Time</th>'
printf, lun, '    <th>End Time</th>'
printf, lun, '    <th>Duration Minutes</th>'
printf, lun, '    <th>Peak Elevation</th>'
printf, lun, '    <th>In Sunlight</th>'
if not keyword_set(no_conflict) then begin
	printf, lun, '    <th>Priority (MinXSS Elevation)</th>'
endif
printf, lun, '</thead>'
for k=0L, number_passes-1 do begin
	pass_num_str = string( k+1, format='(I5)')
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
	printf, lun, '<tr>'
	printf, lun, '    <td>' + pass_num_str + '</td>'
	printf, lun, '    <td>' + start_str + '</td>'
	printf, lun, '    <td>' + end_str + '</td>'
	printf, lun, '    <td>' + duration_str + '</td>'
	printf, lun, '    <td>' + elevation_str + '</td>'
	printf, lun, '    <td>' + sun_str + '</td>'
	if not keyword_set(no_conflict) then begin
		printf, lun, '    <td>' + pass_conflict[k].priority + ' (' + $
							pass_conflict[k].reason +') ' + '</td>'
	endif
	printf, lun, '</tr>'
endfor
printf, lun, '</table>'
printf, lun, '<P>'
printf, lun, 'This table was generated by nodes_satellite_pass.pro on ' + systime(/utc)
printf, lun, '<P>'
printf, lun, '</body>'
printf, lun, '<html>'
close, lun
free_lun, lun

; if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path+html_name2
; copy_cmd = file_copy+ html_path+html_name1 + ' ' + html_path+html_name2
; spawn, copy_cmd

csv_path = path_name + 'pass_csv' + slash
csv_name1 = 'nodes_passes_latest.csv'
csv_name2 = 'nodes_passes_' + date_str + '.csv'

if keyword_set(verbose) then print, 'Saving "passes" table to ', csv_path+csv_name1
openw, lun, csv_path+csv_name1, /get_lun
printf, lun, 'NODeS-2x CubeSat Passes for ' + date_str
csv_header = 'Pass #, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight'
if not keyword_set(no_conflict) then begin
	csv_header += ', Priority (MinXSS Elevation)'
endif
printf, lun, csv_header
for k=0L, number_passes-1 do begin
	pass_num_str = string( k+1, format='(I5)')
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
	pass_str = pass_num_str + ', ' + start_str + ', ' + end_str + ', ' + duration_str + ', ' + $
				elevation_str + ', ' + sun_str
	if not keyword_set(no_conflict) then begin
		pass_str += ', ' + pass_conflict[k].priority + ' (' + pass_conflict[k].reason +') '
	endif
	printf, lun, pass_str
endfor
printf, lun, ' '
printf, lun, 'This table was generated by nodes_satellite_pass.pro on ' + systime(/utc)
printf, lun, ' '
close, lun
free_lun, lun

; if keyword_set(verbose) then print, 'Saving "passes" table to ', csv_path+csv_name2
; copy_cmd = file_copy+ csv_path+csv_name1 + ' ' + csv_path+csv_name2
; spawn, copy_cmd

if keyword_set(debug) then stop, 'DEBUG nodes_satellite_pass() results ...'

return
end

