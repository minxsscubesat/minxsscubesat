;
;	plan_scripts_minxss1
;
;	This procedure will generate HYDRA scripts using pass times created by plan_satellite_pass
;
;
;	********************************************************************
;	***                                                              ***
;	***   Run this after the plan_satellite_pass.pro has been run    ***
;	***                                                              ***
;	********************************************************************
;
;	INPUT
;		station 	Option to specify Station - defaults to BOULDER
;		debug		Option to not download latest TLE while debugging this procedure
;		verbose		Option to print information while running
;
;	OUTPUT
;		old scripts are deleted and new scripts are created
;		pass plan CSV file that can be imported into MinXSS-1 log worksheet
;
;	PROCEDURE
;	1.  Read passes info created by plan_satellite_pass.pro
;	2.  Delete old scripts
;	3.	Create new scripts
;	4.	Create CSV file of pass plans for use in MinXSS-1 Log Worksheet
;	5.  Generate set_ephemeris_latest.prc HYDRA script
;
;	HISTORY
;		2017-Apr-02  T. Woods	Original Code based on minxss_satellite_pass.pro
;

pro plan_scripts_minxss1, station, debug=debug, verbose=verbose

;
;	configure inputs
;
if (n_params() lt 1) then station = 'Boulder'
station_caps = strupcase(station)
if (strlen(station_caps) lt 1) then begin
	print, 'ERROR: valid station name is needed to run plan_scripts_minxss1.pro !'
	return
endif

if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then $
	print, 'MinXSS-1 scripts are being generated for ',station_caps,' station...'

;
;	Get TLE path
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
; option to also copy latest pass plan files to dropbox folders too
;
dropbox_tle_dir = getenv('Dropbox_dir')
if strlen(dropbox_tle_dir) ne 0 then dropbox_tle_dir += slash + 'tle' + slash

script_dir = getenv('MINXSS1_scripts_dir')
if strlen(script_dir) gt 1 then script_dir = script_dir + slash else begin
	print, 'ERROR: environment variable MINXSS1_scripts_dir is not defined !'
	return
endelse

;
;	1.  Read pass information for this station
;
save_path = path_name + station_caps + slash
save_name1 = 'passes_latest_'+station_caps+'.sav'
if keyword_set(verbose) then print, 'Restoring "passes" data from ', save_path+save_name1
restore, save_path+save_name1   ;  passes data structure restored (read)

;
;	generate support data for the passes data structure
;
number_passes = n_elements(passes)
if (number_passes lt 2) then begin
	print, 'ERROR: "passes" data structure is not valid !'
	return
endif

pass_date_str = strarr(number_passes)
for k=0,number_passes-1 do begin
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	; pass_date_str[] is needed for /auto_pass option below
	pass_date_str[k] = string(long(year),format='(I04)') + string(long(month),format='(I02)')+$
						string(long(day),format='(I02)') + '_' + $
						string(long(hh),format='(I02)') + string(long(mm),format='(I02)')
endfor

;
;	2.  Delete old scripts
;	3.	Create new scripts
;
elev_ranges = [ [0.,15], [15, 30], [30, 90] ]
script_names = [ 'pass_do_nothing.prc', 'adcs_route_realtime.prc', 'playback_last_48_hours.prc' ]
script_plan_names = [ 'EL<15: Do Nothing', '15<EL<30: ADCS Data', 'Playback Last 48 Hours' ]
num_ranges = n_elements(script_names)

;
;	first delete the files that overlap with these new passes
;
scripts_template_dir = script_dir + 'scripts_auto_template' + slash
scripts_run_dir = script_dir + 'scripts_to_run_automatically' + slash
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
	;  don't delete flare or DOY playback scripts though
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
print, '***** Script files deleted: ' + strtrim(del_count,2)
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
;
jd_now = systime( /julian ) + 6./24.D0  ; also convert MST to UT
num_create = 0L
start_date = '????'
match_name = 'MINXSS1'

for k=0L, number_passes-1 do begin
  ; only create pass scripts for the future
  if (passes[k].start_jd gt jd_now) and (passes[k].satellite_name eq match_name) then begin
	ii = 0L
	for jj=1,num_ranges-1 do begin
		if (passes[k].max_elevation gt elev_ranges[0,jj]) and $
			(passes[k].max_elevation le elev_ranges[1,jj]) then begin
		  ii = jj
		endif
	endfor
	; Note that pass_date_str[] was created above after reading the passes data
	new_file = pass_date_str[k] + 'UT_' + script_names[ii]
	template_file = script_names[ii]
	;  COPY template file TO NEW FILE
	copy_cmd = file_copy + '"' + scripts_template_dir+template_file + '" "' + $
				scripts_run_dir+new_file + '"'
	spawn, copy_cmd, exit_status=status
	if (num_create eq 0) then start_date = pass_date_str[k] + 'UT'
	num_create += 1L
  endif
endfor
print, '***** Auto Pass Scripts created for ' + strtrim(num_create,2) + ' passes.'
print, ' '
if keyword_set(debug) then $
	stop, 'DEBUG: Verify new scripts files in scripts_to_run_automatically/ ...'

;
;	4.	Create CSV file of pass plans for use in MinXSS-1 Log Worksheet
;
if (num_create gt 1) then begin
	csv_path = path_name + station_caps + slash
	csv_name3 = 'plans_latest_MINXSS1.csv'
	if keyword_set(verbose) then print, 'Saving "pass plan" CSV file to ', csv_path+csv_name3
	openw, lun, csv_path+csv_name3, /get_lun
	printf, lun, 'MinXSS-1 CubeSat Pass Default Plans that start at ' + start_date
	csv_header = 'Orbit#, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight, Script Plan'
	printf, lun, csv_header
	for k=0L, number_passes-1 do begin
	  ; only create pass scripts for the future
  	  if (passes[k].start_jd gt jd_now) and (passes[k].satellite_name eq match_name) then begin
  	  	  ; +++++ TO DO (fix)
		  ; pass_num_str = string( pass_orbit_number[k], format='(I6)')
		  pass_num_str = ' TBD '
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
		  pass_str = pass_str + ', ' + script_plan_names[ii]
		  printf, lun, pass_str
	  endif
	endfor
	printf, lun, ' '
	printf, lun, 'This table was generated by plan_scripts_minxss1.pro on ' + systime(/utc)
	printf, lun, ' '
	close, lun
	free_lun, lun

	if strlen(dropbox_tle_dir) ne 0 then begin
	  csv_path2 = dropbox_tle_dir + station_caps + slash
	  if keyword_set(verbose) then print, 'Saving "pass plans" CSV file to ', csv_path2+csv_name3
	  copy_cmd = file_copy + '"' + csv_path+csv_name3 + '" "' +csv_path2+csv_name3 + '"'
	  spawn, copy_cmd, exit_status=status
	endif
endif

;
; 5. generate set_ephemeris_latest.prc HYDRA script
;
; +++++ TO DO (fix)
; make_set_ephemeris_script, /latest

if keyword_set(debug) then stop, 'DEBUG plan_scripts_minxss1 results ...'

return
end

