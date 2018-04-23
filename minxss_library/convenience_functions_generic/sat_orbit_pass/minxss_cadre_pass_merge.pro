;
;	minxss_cadre_pass_merge
;
;	This procedure will merge the MinXSS and CADRE pass info into single CSV file.
;		This is called by minxss_satellite_pass.pro so it will be updated daily.
;
;	INPUT
;		debug		Option to not download latest TLE while debugging this procedure
;		verbose		Option to print information while running
;
;	OUTPUT
;		CSV text file of merged passes in minxss_cadre_passes_latest.csv
;
;	PROCEDURE
;	1.  Read the MinXSS and CADRE pass latest data files
;	2.  Write merged pass information to CSV file
;
;	HISTORY
;		2016-May-14  T. Woods	Original Code
;
pro minxss_cadre_pass_merge, debug=debug, verbose=verbose

;
;	configure inputs
;
if keyword_set(debug) then verbose = 1
if keyword_set(verbose) then print, 'Merging MinXSS and CADRE passes...'

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
; if keyword_set(verbose) then print, '*** TLE path = ', path_name

;
; option to also copy latest pass files to dropbox folders too
;
dropbox_tle_dir = getenv('Dropbox_dir')
if strlen(dropbox_tle_dir) ne 0 then dropbox_tle_dir += slash + 'tle' + slash

;
;	1.  Read the MinXSS and CADRE pass latest data files
;
save_path = path_name + 'pass_saveset' + slash
save_name1 = 'minxss_passes_latest.sav'
save_name2 = 'cadre_passes_latest.sav'

restore, save_path+save_name2   ; passes
c_passes = passes
c_num = n_elements(c_passes)

restore, save_path+save_name1   ; passes, pass_orbit_number, pass_conflict
m_passes = passes
passes=0
m_num = n_elements(m_passes)

;
;	2.  Write merged pass information to CSV file
;
csv_path = path_name + 'pass_csv' + slash
csv_name_out = 'minxss_cadre_passes_latest.csv'
if keyword_set(verbose) then print, 'Saving MinXSS-CADRE merged passes to CSV file: ', csv_path+csv_name_out

openw, lun, csv_path+csv_name_out, /get_lun
printf, lun, 'MinXSS and CADRE CubeSat Passes Merged'
csv_header = 'MinXSS Orbit#, MinXSS Uplink / Script, MinXSS Downlink, MinXSS Start Time, MinXSS End Time'
csv_header += ', MinXSS Duration (min), MinXSS Peak Elev (deg), MinXSS In Sunlight'
csv_header += ', Priority (CADRE; NODeS Elevation), Pass Priority Time'
csv_header += ', CADRE Start Time, CADRE End Time, CADRE Duration (min), CADRE Peak Elev (deg)'
csv_header += ', CADRE in Sunlight, CADRE Uplink / Script, CADRE Downlink'
printf, lun, csv_header

max_num_passes = max( [c_num, m_num] )
c_ii = 0L
m_ii = 0L

;
;	Each line (row) has three options:
;		A)	MinXSS pass only
;		B)	CADRE pass only
;		C)  MinXSS and CADRE passes overlap
;
while (c_ii lt c_num) and (m_ii lt m_num) do begin
	if (m_passes[m_ii].end_jd lt c_passes[c_ii].start_jd) then begin
		;		A)	MinXSS pass only
		pass_num_str = string( pass_orbit_number[m_ii], format='(I6)')
		caldat, m_passes[m_ii].start_jd, month, day, year, hh, mm, ss
		m_start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		caldat, m_passes[m_ii].end_jd, month, day, year, hh, mm, ss
		m_end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		m_duration_str = strtrim(string(m_passes[m_ii].duration_minutes, format='(F8.2)'),2)
		m_elevation_str = strtrim(string( m_passes[m_ii].max_elevation, format='(F8.1)'),2)
		if (m_passes[m_ii].sunlight ne 0) then m_sun_str = 'YES' else m_sun_str='eclipse'

		c_start_str = '-'
		c_end_str = '-'
		c_duration_str = '-'
		c_elevation_str = '-'
		c_sun_str = '-'

		pass_conflict_str = pass_conflict[m_ii].priority + ' (' + pass_conflict[m_ii].reason +') '
		pass_plan_str = 'MinXSS: '+strmid(m_start_str, 11, 8)+' - '+strmid(m_end_str, 11, 8)
		; increment m_ii
		m_ii += 1
	endif else if (c_passes[c_ii].end_jd lt m_passes[m_ii].start_jd) then begin
		;		B)	CADRE pass only
		pass_num_str = '-'
		m_start_str = '-'
		m_end_str = '-'
		m_duration_str = '-'
		m_elevation_str = '-'
		m_sun_str = '-'

		caldat, c_passes[c_ii].start_jd, month, day, year, hh, mm, ss
		c_start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		caldat, c_passes[c_ii].end_jd, month, day, year, hh, mm, ss
		c_end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		c_duration_str = strtrim(string(c_passes[c_ii].duration_minutes, format='(F8.2)'),2)
		c_elevation_str = strtrim(string( c_passes[c_ii].max_elevation, format='(F8.1)'),2)
		if (c_passes[c_ii].sunlight ne 0) then c_sun_str = 'YES' else c_sun_str='eclipse'

		pass_conflict_str = 'CADRE (' + c_elevation_str + '; N/A)'
		pass_plan_str = 'CADRE: '+strmid(c_start_str, 11, 8)+' - '+strmid(c_end_str, 11, 8)
		; increment c_ii
		c_ii += 1
	endif else begin
		;		C)  MinXSS and CADRE passes overlap
		pass_num_str = string( pass_orbit_number[m_ii], format='(I6)')
		caldat, m_passes[m_ii].start_jd, month, day, year, hh, mm, ss
		m_start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		if (m_passes[m_ii].start_jd gt c_passes[c_ii].start_jd) and $
					(m_passes[m_ii].start_jd lt c_passes[c_ii].end_jd) then begin
			caldat, (m_passes[m_ii].start_jd+c_passes[c_ii].end_jd)/2., month, day, year, hh, mm, ss
			m_start_str2 = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		endif else m_start_str2 = m_start_str
		caldat, m_passes[m_ii].end_jd, month, day, year, hh, mm, ss
		m_end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		if (m_passes[m_ii].end_jd gt c_passes[c_ii].start_jd) and $
					(m_passes[m_ii].end_jd lt c_passes[c_ii].end_jd) then begin
			caldat, (m_passes[m_ii].end_jd+c_passes[c_ii].start_jd)/2., month, day, year, hh, mm, ss
			m_end_str2 = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		endif else m_end_str2 = m_end_str
		m_duration_str = strtrim(string(m_passes[m_ii].duration_minutes, format='(F8.2)'),2)
		m_elevation_str = strtrim(string( m_passes[m_ii].max_elevation, format='(F8.1)'),2)
		if (m_passes[m_ii].sunlight ne 0) then m_sun_str = 'YES' else m_sun_str='eclipse'

		caldat, c_passes[c_ii].start_jd, month, day, year, hh, mm, ss
		c_start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		if (c_passes[c_ii].start_jd gt m_passes[m_ii].start_jd) and $
					(c_passes[c_ii].start_jd lt m_passes[m_ii].end_jd) then begin
			c_start_str2 = m_end_str2
		endif else c_start_str2 = c_start_str
		caldat, c_passes[c_ii].end_jd, month, day, year, hh, mm, ss
		c_end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
		if (c_passes[c_ii].end_jd gt m_passes[m_ii].start_jd) and $
					(c_passes[c_ii].end_jd lt m_passes[m_ii].end_jd) then begin
			c_end_str2 = m_start_str2
		endif else c_end_str2 = c_end_str
		c_duration_str = strtrim(string(c_passes[c_ii].duration_minutes, format='(F8.2)'),2)
		c_elevation_str = strtrim(string( c_passes[c_ii].max_elevation, format='(F8.1)'),2)
		if (c_passes[c_ii].sunlight ne 0) then c_sun_str = 'YES' else c_sun_str='eclipse'

		pass_conflict_str = pass_conflict[m_ii].priority + ' (' + pass_conflict[m_ii].reason +') '
		pass_plan_str = 'MinXSS: '+strmid(m_start_str2, 11, 8)+' - '+strmid(m_end_str2, 11, 8)
		pass_plan_str += ' & CADRE: '+strmid(c_start_str2, 11, 8)+' - '+strmid(c_end_str2, 11, 8)
		; increment c_ii and m_ii
		c_ii += 1
		m_ii += 1
	endelse
	pass_str = pass_num_str + ', TBD, TBD, ' + m_start_str + ', ' + m_end_str + ', ' + $
				m_duration_str + ', ' + m_elevation_str + ', ' + m_sun_str + ', ' + pass_conflict_str + $
				', ' + pass_plan_str + ', ' + c_start_str + ', ' + c_end_str + ', ' + $
				c_duration_str + ', ' + c_elevation_str + ', ' + c_sun_str + ', TBD, TBD'
	printf, lun, pass_str
endwhile

printf, lun, ' '
printf, lun, 'This table was generated by minxss_cadre_pass_merge.pro on ' + systime(/utc)
printf, lun, ' '
close, lun
free_lun, lun

if strlen(dropbox_tle_dir) ne 0 then begin
  csv_path2 = dropbox_tle_dir + 'pass_csv' + slash
  if keyword_set(verbose) then print, 'Saving merged passes CSV file to ', csv_path2+csv_name_out
  copy_cmd = file_copy+ csv_path+csv_name_out + ' ' +csv_path2+csv_name_out
  spawn, copy_cmd, exit_status=status
endif

if keyword_set(debug) then stop, 'DEBUG minxss_cadre_pass_merge() results ...'

return
end

