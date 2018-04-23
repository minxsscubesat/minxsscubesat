;
;	minxss_satellite_pass
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
;		date_range	Option to specify JD date range, default is to calculate passes for next 10 days
;		debug		Option to not download latest TLE while debugging this procedure
;		verbose		Option to print information while running
;		conflict	Option to NOT check if there is conflict for CADRE and MinXSS passes
;		add_nodes	Option to check pass conflict for NASA AMES NODeS-2x CubeSat
;		auto_pass	Option to generate AUTO pass scripts based on Pass Elevation
;
;	OUTPUT
;		IDL save set of passes in minxss_passes_latest.sav
;		IDL save set of passes in minxss_passes_DATE_TIME.sav
;		HTML table of passes in minxss_passes_latest.html
;		HTML table of passes in minxss_passes_DATE_TIME.html
;
;		pass_data		Optional return of "passes" data structure array
;		pass_conflict	Optional return of CADRE pass conflict information
;
;	PROCEDURE
;	1.  Download latest TLE for MinXSS
;	2.  Calculate passes for next 2 weeks
;	3.  Write pass information to IDL save set and HTML table
;
;	HISTORY
;		2015-Nov-23  T. Woods	Original Code
;		2016-Feb-05  T. Woods	Updated so "location" is saved in its own SaveSet file
;   2016-Feb-09  T. Woods Updated so call to tle_download_latest hss the /SatPC option
;		2016-Feb-21	 T. Woods Updated to add CADRE priority check (higher GS elevation) - new HTML table column
;		2016-Feb-27  T. Woods Updated to also create CSV text file with pass info and AMES NODeS-2x CubeSat
;		2016-Jun-22	T. Woods	Updated so Auto scripts are generated based on Elevation (/auto_pass)
;		2016-Aug-01  T. Woods  Updated so HTML table is also made with MST column
;   2016-Nov-02  T. Woods  Updated so set_ephemeris_latest.prc HYDRA Script is generated every time
;

pro minxss_satellite_pass, date_range, debug=debug, verbose=verbose, elevation_min=elevation_min, $
	conflict=conflict, add_nodes=add_nodes, pass_data=pass_data, pass_conflict=pass_conflict, $
	auto_pass=auto_pass

;
;	configure inputs
;
if (n_params() lt 1) or (n_elements(date_range) lt 2) then begin
	date1 = systime(/utc,/jul) ; julian date for the current time
	date1 = long(date1-0.5) + 0.5D0  ; force to day boundary
	date2 = date1 + 10
	date_range = [date1, date2]
endif else begin
	date1 = date_range[0]
	date2 = date_range[1]
endelse
date_str = string( date1, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' ) + '_' + $
	string( date2, format = '(C(CYI, "-", CMOI2.2, "-", CDI2.2))' )
if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then print, 'MINXSS_SATELLITE_PASS is getting passes for ', date_str

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

mission = 'ISS (ZARYA)'
satid = 25544L		; Satellite ID for ISS is 25544
mission = 'MinXSS-1'
satid = 41474L   ; neighbor is 41475L = CADRE

gs_long_lat = [ -105.2705D0, 40.0150D0 ]  ; Boulder Longitude (West=negative), Latitude in degrees

;
;	1.  Download latest TLE for MinXSS
;
if not keyword_set(debug) then begin
	print, 'Loading TLE catalog and searching for satid = ', satid
	tle_download_latest, tle, satid=satid, path=path_name, /output, /satpc, verbose=verbose
endif

;
;	2.  Calculate passes for next 2 weeks
;
spacecraft_pass, date_range, passes, number_passes, id_satellite=satid, $
	ground_station=gs_long_lat, tle_path=path_name, verbose=verbose, sc_location=location, $
	elevation_min = pass_elevation_min

pass_data = passes
if (number_passes lt 1) then begin
	print, 'ERROR finding any passes for ', date_str
	if keyword_set(debug) then stop, 'DEBUG this error ...'
	return
endif

;
;	update orbit number file
;
spacecraft_orbit_number, location, 'minxss', data=orbit_num, verbose=verbose, debug=debug

;
;	determine orbit number for each pass
;
orbit_num_yd = reform(orbit_num[1,*] + orbit_num[2,*]/(24.D0*3600.))
pass_yd = jd2yd( passes.start_jd )
pass_orbit_number = long( interpol( reform(orbit_num[0,*]), orbit_num_yd, pass_yd ) )
if keyword_set(debug) then print, 'STOP for checking out pass_orbit_number ...'

;
;	Check pass conflicts between CADRE in Michigan and MinXSS in Colorado
;	Highest Priority for overlapping passes is the one with largest maximum elevation
;
if keyword_set(verbose) then print, 'Number of Passes = ', number_passes
pass_conflict1 = { priority: ' ', reason: ' ', lost_flag: 0 }
pass_conflict = replicate( pass_conflict1, number_passes )
for i=0,number_passes-1 do begin
	pass_conflict[i].priority = 'MinXSS'
	pass_conflict[i].reason = 'N/A'
	pass_conflict[i].lost_flag = 0
endfor
if keyword_set(conflict) then begin
	cadre_path = path_name + 'pass_saveset' + slash
	cadre_name = 'cadre_passes_latest.sav'
	minxss_passes = passes
	if keyword_set(verbose) then print, 'Reading CADRES pass info from ', cadre_name, ' ...'
	restore, cadre_path+cadre_name
	cadre_passes = passes
	passes = minxss_passes
	;
	;  check each MinXSS pass for CADRE pass conflict
	;		CADRE pass has to have more than 2 minutes overlap and
	;		CADRE has to have larger maximum elevation over its ground station (GS) than MinXSS GS
	;
	time_limit = 2.D0 / (24. * 60.D0)   ; 2 minutes in units of Julian Days
	lost_count = 0L
	for i=0,number_passes-1 do begin
		time1 = passes[i].start_jd + time_limit
		time2 = passes[i].end_jd - time_limit
		wbad = where( ((cadre_passes.start_jd gt time1) and (cadre_passes.start_jd lt time2)) $
			OR ((cadre_passes.end_jd gt time1) and (cadre_passes.end_jd lt time2)), num_bad )
		if (num_bad ge 1) then begin
			pass_conflict[i].reason = strtrim(string( cadre_passes[wbad[0]].max_elevation, format='(F6.1)' ), 2)
			if (cadre_passes[wbad[0]].max_elevation gt passes[i].max_elevation) then begin
				pass_conflict[i].priority = 'CADRE'
				pass_conflict[i].lost_flag = 1
				lost_count += 1L
			endif
		endif
	endfor
	if keyword_set(debug) or keyword_set(verbose) then begin
		print, 'Number of MinXSS Passes lost to CADRE = ', strtrim(lost_count, 2), ' (', $
				strtrim(string(lost_count*100./number_passes,format='(F7.1)'),2) + '%)'
	endif

	;
	;	Check pass conflicts between NODeS-2x at NASA AMES and MinXSS in Colorado
	;	Highest Priority for overlapping passes is the one with largest maximum elevation
	;
	if keyword_set(add_nodes) then begin
		nodes_path = path_name + 'pass_saveset' + slash
		nodes_name = 'nodes_passes_latest.sav'
		minxss_passes = passes
		if keyword_set(verbose) then print, 'Reading NODeS pass info from ', nodes_name, ' ...'
		restore, nodes_path+nodes_name
		nodes_passes = passes
		passes = minxss_passes
		;
		;  check each MinXSS pass for NODES pass conflict
		;		NODES pass has to have more than 2 minutes overlap and
		;		NODES has to have larger maximum elevation over its ground station (GS) than MinXSS GS
		;
		time_limit = 2.D0 / (24. * 60.D0)   ; 2 minutes in units of Julian Days
		lost_count = 0L
		for i=0,number_passes-1 do begin
			time1 = passes[i].start_jd + time_limit
			time2 = passes[i].end_jd - time_limit
			wbad = where( ((nodes_passes.start_jd gt time1) and (nodes_passes.start_jd lt time2)) $
				OR ((nodes_passes.end_jd gt time1) and (nodes_passes.end_jd lt time2)), num_bad )
			if (num_bad ge 1) and (pass_conflict[i].priority EQ 'MinXSS') then begin
				pass_conflict[i].reason += '; ' + $
					strtrim(string( nodes_passes[wbad[0]].max_elevation, format='(F6.1)' ), 2)
				if (nodes_passes[wbad[0]].max_elevation gt passes[i].max_elevation) then begin
					pass_conflict[i].priority = 'NODeS'
					pass_conflict[i].lost_flag = 1
					lost_count += 1L
				endif
			endif else begin
				pass_conflict[i].reason += '; N/A'
			endelse
		endfor
		if keyword_set(debug) or keyword_set(verbose) then begin
			print, 'Number of MinXSS Passes lost to NODeS = ', strtrim(lost_count, 2), ' (', $
					strtrim(string(lost_count*100./number_passes,format='(F7.1)'),2) + '%)'
		endif
	endif
endif

;
;	3.  Write pass information to IDL save set, HTML table, and CSV text file
;
save_path = path_name + 'pass_saveset' + slash
save_name1 = 'minxss_passes_latest.sav'
save_name2 = 'minxss_passes_' + date_str + '.sav'
save_name3 = 'minxss_location_latest.sav'

if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path+save_name1
save, passes, pass_orbit_number, pass_conflict, file=save_path+save_name1

if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path+save_name2
save, passes, pass_orbit_number, pass_conflict, file=save_path+save_name2

if keyword_set(verbose) then print, 'Saving "location" data to ', save_path+save_name3
save, location, file=save_path+save_name3

if strlen(dropbox_tle_dir) ne 0 then begin
  save_path2 = dropbox_tle_dir + 'pass_saveset' + slash
  if keyword_set(verbose) then print, 'Saving "passes" data to ', save_path2+save_name1
  save, passes, pass_orbit_number, file=save_path2+save_name1
  ;
  ;  also copy orbit_number data file to dropbox link
  ;
  orbit_dir = path_name + 'orbit_number' + slash
  dropbox_orbit_dir = dropbox_tle_dir + 'orbit_number' + slash
  orbit_number_file = 'minxss_orbit_number.dat'
  if keyword_set(verbose) then print, 'Saving Orbit Number file to ', dropbox_orbit_dir+orbit_number_file
  copy_cmd = file_copy + '"' + orbit_dir+orbit_number_file + '" "' + dropbox_orbit_dir+orbit_number_file + '"'
  spawn, copy_cmd
endif

;  updated 2016/08/01 so it makes MinXSS HTML table with MT and MST columns
table_id = 0   ; 0 = MDT as needed for OPS-1 PC and 1 = MST for human planners

html_path = path_name + 'pass_html' + slash
html_name1 = 'minxss_passes_latest.html'
html_name1_mst = 'minxss_passes_latest_mst.html'
html_name2 = 'minxss_passes_' + date_str + '.html'
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
  html_base = html_name1 
  html_mt_column = '    <th>Start Time (MDT)</th>'
  MT_DIFF = 6L
endif else begin
  html_base = html_name1_mst
  html_mt_column = '    <th>Start Time (MST)</th>'
  MT_DIFF = 7L
endelse

if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path+html_base
openw, lun, html_path+html_base, /get_lun
printf, lun, '<!DOCTYPE html>'
printf, lun, '<html>'
printf, lun, '<head>'
printf, lun, '<title>MinXSS CubeSat Passes for ' + date_str + '</title>'
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
printf, lun, '<caption>MinXSS CubeSat Passes for ' + date_str + '</caption>'
printf, lun, '<thead>'
printf, lun, '    <th>Orbit#</th>'
printf, lun, html_mt_column 
printf, lun, '    <th>Start Time (UT)</th>'
printf, lun, '    <th>End Time (UT)</th>'
printf, lun, '    <th>Duration Minutes</th>'
printf, lun, '    <th>Peak Elevation</th>'
printf, lun, '    <th>In Sunlight</th>'
if keyword_set(conflict) then begin
	if keyword_set(add_nodes) then begin
		printf, lun, '    <th>Priority (CADRE; NODeS Elevation)</th>'
	endif else begin
		printf, lun, '    <th>Priority (CADRE Elevation)</th>'
	endelse
endif
printf, lun, '</thead>'
; MT_DIFF = long(strmid(systime(/utc),10,3))-long(strmid(systime(),10,3))
; if (MT_DIFF lt 0) then MT_DIFF += 24L

;  generate and save Pass date-time string for use later by /auto_pass
pass_date_str = strarr(number_passes)

for k=0L, number_passes-1 do begin
	pass_num_str = string( pass_orbit_number[k], format='(I6)')
	caldat, passes[k].start_jd - MT_DIFF / 24.D0, month, day, year, hh, mm, ss
	start_MT_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'MT'
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
	  printf, lun, '    <td>' + pass_num_str + '</td>'
	  printf, lun, '    <td>' + start_MT_str + '</td>'
	  printf, lun, '    <td>' + start_str + '</td>'
	  printf, lun, '    <td>' + end_str + '</td>'
	  printf, lun, '    <td>' + duration_str + '</td>'
	  printf, lun, '    <td>' + elevation_str + '</td>'
	  printf, lun, '    <td>' + sun_str + '</td>'
	  if keyword_set(conflict) then begin
		printf, lun, '    <td>' + pass_conflict[k].priority + ' (' + $
							pass_conflict[k].reason +') ' + '</td>'
	  endif
	  printf, lun, '</tr>'
	endif
endfor
printf, lun, '</table>'
printf, lun, '<P>'
printf, lun, 'This table was generated by minxss_satellite_pass.pro on ' + systime(/utc)
printf, lun, '<P>'
printf, lun, '</body>'
printf, lun, '<html>'
close, lun
free_lun, lun

if (table_id eq 0) then begin
  if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path+html_name2
  copy_cmd = file_copy + '"' + html_path+html_base + '" "' + html_path+html_name2 + '"'
  spawn, copy_cmd

  if strlen(dropbox_tle_dir) ne 0 then begin
    html_path2 = dropbox_tle_dir + 'pass_html' + slash
    if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path2+html_base
    copy_cmd = file_copy + '"' + html_path+html_base + '" "' + html_path2+html_base + '"'
    spawn, copy_cmd
    ;  MinXSS Level 0D also needs TLE in this directory
    tle_name = string(long(satid),format='(I08)') + '.tle'
    if keyword_set(verbose) then print, 'Saving MinXSS TLE ' + tle_name + ' to ' + dropbox_tle_dir
    copy_cmd = file_copy + '"' + path_name+tle_name + '" "' + dropbox_tle_dir+tle_name
    spawn, copy_cmd
  endif
  ;  repeat the HTML table but for MST column
  table_id += 1
  goto, REPEAT_HTML_TABLE
endif else begin
  ;  MST Table copy to DropBox too
  if strlen(dropbox_tle_dir) ne 0 then begin
    html_path2 = dropbox_tle_dir + 'pass_html' + slash
    if keyword_set(verbose) then print, 'Saving "passes" table to ', html_path2+html_base
    copy_cmd = file_copy + '"' + html_path+html_base + '" "' + html_path2+html_base + '"'
    spawn, copy_cmd
  endif
  table_id += 1
endelse

csv_path = path_name + 'pass_csv' + slash
csv_name1 = 'minxss_passes_latest.csv'
csv_name2 = 'minxss_passes_' + date_str + '.csv'

if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', csv_path+csv_name1
openw, lun, csv_path+csv_name1, /get_lun
printf, lun, 'MinXSS CubeSat Passes for ' + date_str
csv_header = 'Orbit#, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight'
if keyword_set(conflict) then begin
	if keyword_set(add_nodes) then begin
		csv_header += ', Priority (CADRE; NODeS Elevation)'
	endif else begin
		csv_header += ', Priority (CADRE Elevation)'
	endelse

	csv_header += ', Priority (CADRE Elevation)'
endif
printf, lun, csv_header
for k=0L, number_passes-1 do begin
	pass_num_str = string( pass_orbit_number[k], format='(I6)')
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
	pass_str = pass_num_str + ', ' + start_str + ', ' + end_str + ', ' + duration_str + ', ' + $
				elevation_str + ', ' + sun_str
	if keyword_set(conflict) then begin
		pass_str += ', ' + pass_conflict[k].priority + ' (' + pass_conflict[k].reason +') '
	endif
	printf, lun, pass_str
endfor
printf, lun, ' '
printf, lun, 'This table was generated by minxss_satellite_pass.pro on ' + systime(/utc)
printf, lun, ' '
close, lun
free_lun, lun

if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', csv_path+csv_name2
copy_cmd = file_copy + '"' + csv_path+csv_name1 + '" "' + csv_path+csv_name2 + '"'
spawn, copy_cmd

if strlen(dropbox_tle_dir) ne 0 then begin
  csv_path2 = dropbox_tle_dir + 'pass_csv' + slash
  if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', csv_path2+csv_name1
  copy_cmd = file_copy + '"' + csv_path+csv_name1 + '" "' +csv_path2+csv_name1 + '"'
  spawn, copy_cmd, exit_status=status
endif

;
;	new addition in May 2016 is to merge MinXSS and CADRE pass spreadsheet info
;
minxss_cadre_pass_merge, verbose=verbose, debug=debug

;
;	new  addition in June 2016 is to generate Pass Auto scripts based on pass elevation
;
;  define Script Plans outside the AUTO_PASS if block so CSV Plan file can be written anyway
;
elev_ranges = [ [0.,15], [15, 30], [30, 90] ]
script_names = [ 'pass_do_nothing.prc', 'adcs_route_realtime.prc', 'playback_last_48_hours.prc' ]
script_plan_names = [ 'EL<15: Do Nothing', '15<EL<30: ADCS Data', 'Playback Last 48 Hours' ]
num_ranges = n_elements(script_names)
    
script_dir = getenv('ISIS_scripts_dir')
if keyword_set(auto_pass) then begin
  if strlen(script_dir) gt 1 then begin
    ;
    ;	first delete the files that overlap with these new passes
    ;
    scripts_template_dir = script_dir + slash + 'scripts_auto_template' + slash
    scripts_run_dir = script_dir + slash + 'scripts_to_run_automatically' + slash
	first_file = pass_date_str[0]
	last_file = pass_date_str[number_passes-1]
	search_name = '20*.prc'
	file_list = file_search( scripts_run_dir, search_name, count=count )
	del_count = 0L
	flare_count = 0L
	doy_count = 0L
	if (count gt 0) then begin
	  for k=0,count-1 do begin
	    pslash = strpos( file_list[k], slash, /reverse_search )
	    if (pslash gt 0) then file_date = strmid( file_list[k], pslash+1, 13 ) $
	    else file_date = strmid( file_list[k], 0, 13 )
	    ;  don't delete flare playback scripts though
	    upcasefile = strupcase(file_list[k])
	    pflare = strpos( upcasefile, 'FLARE' )
	    pdoy = strpos( upcasefile, 'DOY' )
	    if (pflare ge 0) then flare_count += 1
	    if (pdoy ge 0) then doy_count += 1
	  	if (file_date ge first_file) and (file_date le last_file) and (pflare lt 0) $
	  	        and (pdoy lt 0) then begin
	  		del_count += 1
	  		del_cmd = file_delete + '"' + file_list[k] + '"'
	  		spawn, del_cmd, exit_status=status
	  	endif
	  endfor
	endif
	print, '***** Script Auto files deleted: ' + strtrim(del_count,2)
	if (flare_count gt 0) then print, '***** Script FLARE files saved: ' + strtrim(flare_count,2)
  if (doy_count gt 0) then print, '***** Script DOY files saved: ' + strtrim(doy_count,2)
    if keyword_set(debug) then stop, 'DEBUG: verify old Scripts files have been deleted...'
    ;
    ;	then copy the template scripts into the AUTO script directory based on elevation
    ;		 0-12 deg EL =  pass_do_nothing.prc
    ;		12-24 deg EL =  adcs_route_realtime.prc
    ;		24-90 deg EL =  playback_last_48_hours.prc
    ;
    ; elev_ranges = [ [0.,12], [12, 24], [24, 90] ]
    ;  Updated ranges on 7/28/2016 T. Woods
    ;  NOTE: see the elev_ranges and script_names definitions ABOVE
    ; elev_ranges = [ [0.,15], [15, 30], [30, 90] ]
    ; script_names = [ 'pass_do_nothing.prc', 'adcs_route_realtime.prc', 'playback_last_48_hours.prc' ]
    ; num_ranges = n_elements(script_names)
    for k=0L, number_passes-1 do begin
    	ii = 0L
    	for jj=1,num_ranges-1 do begin
    		if (passes[k].max_elevation gt elev_ranges[0,jj]) and $
    			(passes[k].max_elevation le elev_ranges[1,jj]) then begin
    		  ii = jj
    		endif
    	endfor
    	; Note that pass_date_str[] was created above when making HTML file
    	new_file = pass_date_str[k] + 'UT_' + script_names[ii]
    	template_file = script_names[ii]
    	;  COPY template file TO NEW FILE
    	copy_cmd = file_copy + '"' + scripts_template_dir+template_file + '" "' + $
    				scripts_run_dir+new_file + '"'
  		spawn, copy_cmd, exit_status=status
    endfor
    print, '***** Auto Pass Scripts created for ' + strtrim(number_passes,2) + ' passes.'
    print, ' '
    if keyword_set(debug) then stop, 'DEBUG: Verify new scripts files in scripts_to_run_automatically/ ...'
  endif else begin
    print, 'ERROR generating AUTO Pass Scripts because $ISIS_scripts_dir environment is not defined!'
  endelse
endif

;
; New for Sept 2016 is to generate CSV file with Plan Name column
;
csv_name3 = 'minxss_passes_latest_plans.csv'  ; new 9/29/16 for having Plan Name column
if keyword_set(verbose) then print, 'Saving "pass plan" CSV file to ', csv_path+csv_name3
openw, lun, csv_path+csv_name3, /get_lun
printf, lun, 'MinXSS CubeSat Pass Default Plans for ' + date_str
csv_header = 'Orbit#, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight, Script Plan'
if keyword_set(conflict) then begin
  if keyword_set(add_nodes) then begin
    csv_header += ', Priority (CADRE; NODeS Elevation)'
  endif else begin
    csv_header += ', Priority (CADRE Elevation)'
  endelse
  csv_header += ', Priority (CADRE Elevation)'
endif
printf, lun, csv_header
for k=0L, number_passes-1 do begin
  pass_num_str = string( pass_orbit_number[k], format='(I6)')
  caldat, passes[k].start_jd, month, day, year, hh, mm, ss
  start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
  caldat, passes[k].end_jd, month, day, year, hh, mm, ss
  end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
  duration_str = string(passes[k].duration_minutes, format='(F8.2)')
  elevation_str = string( passes[k].max_elevation, format='(F8.2)')
  if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
  pass_str = pass_num_str + ', ' + start_str + ', ' + end_str + ', ' + duration_str + ', ' + $
        elevation_str + ', ' + sun_str
  ii = 0L
  for jj=1,num_ranges-1 do begin
    if (passes[k].max_elevation gt elev_ranges[0,jj]) and $
        (passes[k].max_elevation le elev_ranges[1,jj]) then begin
        ii = jj
    endif
  endfor
  ; Note that pass_date_str[] was created above when making HTML file
  pass_str = pass_str + ', ' + script_plan_names[ii]
  if keyword_set(conflict) then begin
    pass_str += ', ' + pass_conflict[k].priority + ' (' + pass_conflict[k].reason +') '
  endif
  printf, lun, pass_str
endfor
printf, lun, ' '
printf, lun, 'This table was generated by minxss_satellite_pass.pro on ' + systime(/utc)
printf, lun, ' '
close, lun
free_lun, lun

if strlen(dropbox_tle_dir) ne 0 then begin
  csv_path2 = dropbox_tle_dir + 'pass_csv' + slash
  if keyword_set(verbose) then print, 'Saving "pass plans" CSV file to ', csv_path2+csv_name3
  copy_cmd = file_copy + '"' + csv_path+csv_name3 + '" "' +csv_path2+csv_name3 + '"'
  spawn, copy_cmd, exit_status=status
endif

;
; NEW as of Nov 2, 2016:  generate set_ephemeris_latest.prc HYDRA script
;
make_set_ephemeris_script, /latest

if keyword_set(debug) then stop, 'DEBUG minxss_satellite_pass() results ...'

return
end

