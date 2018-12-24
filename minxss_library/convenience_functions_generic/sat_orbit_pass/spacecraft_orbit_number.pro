;
;	spacecraft_orbit_number
;
;	This procedure will update the spacecraft orbit number file with latest "location" info
;
;	INPUT
;		location		Structure Array from spacecraft_pass.pro
;		sc_name			Name of Spacecraft
;		/verbose		Option to print debug messages
;
;	OUTPUT
;		data			Orbit Number data record (Orbit#, YYYYDOY, UT_sec) (optional output)
;
;	FILES
;		Orbit Number data file name has format of   SC_NAME_orbit_number.dat
;			and includes for each orbit number since launch (orbit=1):
;				 orbit_number, YYYYDOY, UT_sec, sunrise_UTsec, sunset_UTsec, beta_angle
;			where
;				sunrise and sunset time in UTsec can be outside day range (0-86400)
;
;		Directory for storage is $TLE_dir/orbit_number/
;
;	To start off with new spacecraft file, here is template for XXXX_orbit_number.dat
;	where the first two lines represent the launch time values for orbit 0 and 1 (redundant times)
;FORMAT = (F6.0,F10.0,F8.0,F8.0,F8.0,F6.1)
; 2 lines : File minxss_orbit_number.dat
; 6 columns : Orbit#, YYYYDOY, UT_sec, Sunrise_UTsec, Sunset_UTsec, Beta_Angle_deg
;    0.  2016137.  36000.  36000.  36000.   0.0
;    1.  2016137.  36000.  36000.  36000.   0.0
;
;then populate new file - example is for MinXSS spacecraft:
;   IDL>  satid = 41474L   ; MinXSS-1
;   IDL>  gs_long_lat = [ -105.2705D0, 40.0150D0 ]  ; Boulder Longitude (West=negative), Latitude in degrees
;   IDL>  date_range = [ ymd2jd(2016,5,16), ymd2jd(2017,1,5) ]  ; there is limitation of 28 days  !!! (use minxss_fresh_orbit_number.pro)
;   IDL>  path_name = getenv('TLE_dir') + '\'
;   IDL>  spacecraft_pass, date_range, passes, number_passes, id_satellite=satid, $
;             ground_station=gs_long_lat, tle_path=path_name, /verbose, sc_location=location
;   IDL>  spacecraft_orbit_number,  location, 'minxss', data=orbit_num, /verbose
;
;	PROCEDURE
;	1.  Check inputs
;	2.	Read previous Orbit Number data file (in $TLE_dir/orbit_number/ directory)
;	3.  Delete outdated (future) orbit numbers
;	4.  Add new orbit numbers based on ascending equator crossings
;	5.  Write new Orbit Number data file
;
;	HISTORY
;		2016-May-14  T. Woods	Original Code
;		2016-Jun-22  T. Woods	Updated to include sunrise time, sunset time, beta angle
;		2017-Jan-04  T. Woods Changed so backup file has date and stored in "backup" directory
;
pro spacecraft_orbit_number, location, sc_name, data=data, debug=debug, verbose=verbose

;
;	1.  Check inputs
;
data=-1L
if n_params() lt 2 then begin
	print, 'USAGE: satellite_orbit_number, location, sc_name [, data=data, /verbose, /debug]
	return
endif
if keyword_set(debug) then verbose = 1

;	check early that location is indeed structured array
;		of time_jd, longitude, latitude, altitude, sunlight
time_yd = jd2yd( location.time_jd )
min_yd = min(time_yd) + 3./24.  ; start at least 3 hours (2 orbits) into the location record

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
if strlen(path_name) gt 0 then begin
  if ((strpos(path_name,slash,/reverse_search)+1) lt strlen(path_name)) then path_name += slash
endif
; else path_name is empty string
if strlen(path_name) gt 0 then path_name += 'orbit_number' + slash
file_name = strlowcase( sc_name ) + '_orbit_number.dat'
if not file_test( path_name + file_name ) then begin
	print, 'ERROR finding Orbit Number File: ', path_name + file_name
	return
endif
if keyword_set(verbose) then print, '*** Orbit Number File = ', path_name+file_name

;
;	2.	Read previous Orbit Number data file (in $TLE_dir/orbit_number/ directory)
;			also make a backup file
;
data_old = read_dat( path_name+file_name )

path_name2 = path_name + 'backup' + slash
file_name2 = file_name + '.backup_' + strtrim(long(jd2yd(systime(/julian))),2)
copy_cmd = file_copy + path_name+file_name + ' ' + path_name2+file_name2
spawn, copy_cmd, exit_status=status

;
;	3.  Delete outdated (future) orbit numbers
;
orb_num_yd = reform(data_old[1,*] + data_old[2,*]/(24.D0*3600.))
wdel = where( orb_num_yd ge min_yd, num_delete )
if (num_delete gt 0) then begin
  if (wdel[0] eq 0) then idel = 0 else idel = wdel[0]-1
  data_old = data_old[*,0:idel]
  orb_num_yd = orb_num_yd[0:idel]
endif else begin
  num_gap_days = min_yd - max(orb_num_yd )
  print, '*****'
  print, '*****  WARNING: There is a gap of ' + strtrim(num_gap_days,2) + ' days for Orbit Number !'
  print, '*****'
endelse
data = data_old

;
;	4.  Add new orbit numbers based on ascending equator crossings
;			location = 3 x n_elements(time_jd) Array of Longitude, Latitude, Altitude
;
lat_slope = location.latitude - shift(location.latitude,1)
lat_slope[0] = lat_slope[1]
time_step = location.time_jd - shift(location.time_jd,1)
time_step[0] = time_step[1]

wgd = where( lat_slope gt 0 and time_yd gt orb_num_yd[0], num_good )
if (num_good le 0) then begin
	; no future data to use for orbit numbers
	if keyword_set(verbose) then $
		print, 'WARNING spacecraft_orbit_number(): not enough LOCATION data to add more orbit numbers'
	return
endif
pos_time_jd = location[wgd].time_jd
pos_time_step = pos_time_jd - shift(pos_time_jd,1)
pos_time_step[0] = pos_time_step[1]
pos_latitude = location[wgd].latitude
org_time_step = time_step[wgd]

gap_min = 10./(24.D0*60.)  ; 10 min gap required to signal ascending phase transition
wnew = where( (pos_time_step-org_time_step) gt gap_min, num_new_orbits )
if keyword_set(verbose) then print, '*** Adding ', strtrim(num_new_orbits+1,2), ' new orbits...'

data = [ [data_old], [fltarr(6,num_new_orbits)] ]
kstart = n_elements(data_old[0,*])
kcnt = -1L

for k=0L,num_new_orbits-1 do begin
	if (k eq 0) then begin
		i1 = 0L
		i2 = wnew[0]
	endif else if (k eq num_new_orbits) then begin
		i1 = wnew[k-1]
		i2 = n_elements(pos_latitude)-1
	endif else begin
		i1 = wnew[k-1]
		i2 = wnew[k]
	endelse
	temp = min( abs(pos_latitude[i1:i2]), wmin )  ; find equator crossing
	orbit_jd = pos_time_jd[i1+wmin]
	orbit_yd = jd2yd(orbit_jd)
	orbit_yd_long = long(orbit_yd)
	orbit_ut_sec = (orbit_yd - orbit_yd_long) * (24.D0*3600.)
	if (orbit_yd ge min_yd) then begin
		kcnt += 1L
		data[0,kstart+kcnt] = data[0,kstart+kcnt-1] + 1  ; orbit number (just increment from last one)
		data[1,kstart+kcnt] = orbit_yd_long
		data[2,kstart+kcnt] = orbit_ut_sec
		; find sunrise and sunset
		org_i1 = wgd[i1]
		org_i2 = wgd[i2]
		in_sun = location[org_i1:org_i2].sunlight
		in_sun_yd = time_yd[org_i1:org_i2]
		weclipse=where(in_sun lt 0.5, numeclipse)
		if (numeclipse lt 1) then begin
			; special case where there is no sunset or sunrise
			data[3,kstart+kcnt] = -1
			data[4,kstart+kcnt] = -1
		endif else begin
			sun_change = in_sun - shift(in_sun,1)
			nsun = n_elements(sun_change)
			sun_change[0] = sun_change[1]
			sun_change[nsun-1] = sun_change[nsun-2]
			wrise = where( sun_change gt 0, numrise )
			if (numrise lt 1) then wrise = weclipse[numeclipse-1]
			wrise = wrise[0]
			; check year boundary
			if (abs(in_sun_yd[wrise] - orbit_yd_long) ge 600L) then begin
			  sunrise_ut_sec = (in_sun_yd[wrise] - long(in_sun_yd[wrise])) * (24.D0*3600.)
			  if ((in_sun_yd[wrise] - orbit_yd_long) gt 0) then sunrise_ut_sec += (24.D0*3600.) $ ; next day
			  else sunrise_ut_sec -= (24.D0*3600.)  ; previous day
			  ; stop, 'DEBUG sunrise year boundary...'
			endif else sunrise_ut_sec = (in_sun_yd[wrise] - orbit_yd_long) * (24.D0*3600.)
			data[3,kstart+kcnt] = sunrise_ut_sec
			wset = where( sun_change lt 0, numset )
			if (numset lt 1) then wset = weclipse[0]
			wset = wset[0]
			; check year boundary
			if (abs(in_sun_yd[wset] - orbit_yd_long) ge 600L) then begin
			  sunset_ut_sec = (in_sun_yd[wset] - long(in_sun_yd[wset])) * (24.D0*3600.)
			  if ((in_sun_yd[wset] - orbit_yd_long) gt 0) then sunset_ut_sec += (24.D0*3600.) $ ; next day
			  else sunset_ut_sec -= (24.D0*3600.)  ; previous day
			  ; stop, 'DEBUG sunset year boundary...'
			endif else sunset_ut_sec = (in_sun_yd[wset] - orbit_yd_long) * (24.D0*3600.)
			data[4,kstart+kcnt] = sunset_ut_sec
		endelse
		; get beta as smallest position-sun angle vector
		sun_angle = location[org_i1:org_i2].sun_dot_pos
		wpos = where( sun_angle gt 0, numpos )
		if (numpos gt 0) then beta = acos(  max(sun_angle[wpos] ) ) * 180. / !pi else beta=0.0
		; stop, 'DEBUG beta angle ...'
		data[5,kstart+kcnt] = beta
	endif
endfor

;  remove unused data points
data = data[*,0:kstart+kcnt]

;
;	5.  Write new Orbit Number data file
;
if keyword_set(verbose) then print, '*** Writing back to Orbit Number File'
write_dat, data, file=path_name+file_name, format='(F6.0,F10.0,F8.0,F8.0,F8.0,F6.1)', $
				lintext='File '+file_name, $
				coltext='Orbit#, YYYYDOY, UT_sec Sunrise_UTsec Sunset_UTsec Beta_Angle'

if keyword_set(debug) then stop, 'DEBUG satellite_orbit_number() results ...'

return
end

