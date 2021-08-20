;
;	spacecraft_pass
;
;	Calculate satellite pass times for a given date range
;
;	INPUT
;		date			Julian Date range
;		/id_satellite	Option to specify the satellite ID, else use ISS ID of 25544
;		/ground_station Option to specify ground station longitude and latitude, default is LASP-Boulder
;		/tle_path		Option to specify path for TLE, else use $TLE_dir
;		/current_day	Option to use current day instead of input date array
;		/elevation_min	Option to specific minimum elevation acceptable for pass (default is 10 degrees)
;		/verbose		Option to print debug messages
;
;	OUTPUT
;		pass_array		3 x n_elements(time) Array of Longitude, Latitude, Altitude
;		number_passes	Number of elements in pass_array
;
;	ALGORITHM
;		Get spacecraft longitude and latitude using spacecraft_location.pro
;		Calculate distance of spacecraft ground track from ground station
;			See  http://www.movable-type.co.uk/scripts/latlong.html
;			dLat = Lat2 - Lat1 is latitude difference (calculations are all done in radians)
;			dLong = Long2 - Long1 is longitude difference
;			chord = (sin(dLat/2.))^2.   +   cos(Lat1) * cos(Lat2) * (sin(dLong/2.))^2.
;			arc = 2.0 * atan2( sqrt(chord), sqrt(1.0−chord) )
;			distance = R_earth * arc
;		Select times when spacecraft ground track is within the horizon radius and make pass_array
;				pass_array[].start_jd		Julian date
;				pass_array[].start_date		YYYYDOY
;				pass_array[].start_time		seconds of day (UT)
;				pass_array[].end_jd			Julian date
;				pass_array[].end_date   	YYYYDOY
;				pass_array[].end_time   	seconds of day (UT)
;				pass_array[].duration_minutes   End_time - Start_time
;				pass_array[].max_jd			Julian date
;				pass_array[].max_date   	YYYYDOY
;				pass_array[].max_time   	seconds of day (UT)
;				pass_array[].max_elevation  degrees
;				pass_array[].sunlight	  	Flag of 0 if in eclipse, 1 if in sunlight at Max Elevation
;
;	LIBRARY
;		This depends on the Astronomy Library SGP4 and MSGP4,
;		plus wrapper code by Barry Knapp and Chris Jeppesen
;
;	HISTORY
;		2015-11-02	T. Woods	Original code
;		2017-03-28  T. Woods	Added option for satellite_name and station_name
;
pro spacecraft_pass, date, pass_array, number_passes, id_satellite=id_satellite, $
					elevation_min=elevation_min, satellite_name=satellite_name, station_name=station_name, $
					tle_path=tle_path, current_day=current_day, ground_station=ground_station, $
					sc_location=sc_location, verbose=verbose, debug=debug
	;
	;	default return values if error
	;
	pass_array = -1L
	number_passes = 0L

	if n_params() lt 2 then begin
		print, 'USAGE: spacecraft_pass, date, pass_array, number_passes, id_satellite=id_satellite, '
		print, '                     ground_station=[GS_long,GS_Lat], tle_path=tle_path, '
		print, '                     satellite_name=satellite_name, station_name=station_name, '
		print, '                     /current_day, /verbose'
		print, 'date = INPUT range of dates in Julian Days'
		print, 'pass_array = OUTPUT of pass information for specified ground station'
		return
	endif

	;
	;	Set TLE path
	;
	;  slash for Mac = '/', PC = '\'
	if !version.os_family eq 'Windows' then slash = '\' else slash = '/'
	if keyword_set(tle_path) then begin
		path_name = tle_path
	endif else begin
		;  default is to use directory $TLE_dir
		path_name = getenv('TLE_dir')
		; else path_name is empty string
	endelse
	if strlen(path_name) gt 0 then begin
		; check if need to remove end of string back slash
		spos = strpos(path_name, slash, /reverse_search )
		slen = strlen(path_name)
		if (spos eq (slen-1)) then path_name = strmid( path_name, 0, slen-1 )
	endif
	if keyword_set(verbose) then print, '*** TLE path = ', path_name

	;
	;	Set Satellite ID
	;
	if keyword_set(id_satellite) then begin
		satid = id_satellite
	endif else begin
		satid = 43817		; Satellite ID for MinXSS-2
	endelse
	if not keyword_set(satellite_name) then satellite_name = strtrim(satid,2)

	;
	;	Set Ground Station Location
	;
	gs_lon_lat = [ -105.2705D0, 40.0150D0 ]  ; Boulder Longitude (West=negative), Latitude in degrees
	if keyword_set(ground_station) then begin
		if n_elements(ground_station) ge 2 then begin
			if (ground_station[0] ge -180.) and (ground_station[0] le 180.) and $
					(ground_station[1] ge -90.) and (ground_station[1] le 90.) then begin
				gs_lon_lat = [ ground_station[0], ground_station[1] ]
			endif
		endif
	endif
	if keyword_set(verbose) then begin
		print, '*** Ground Station lon, lat = ', gs_lon_lat[0], ',', gs_lon_lat[1]
	endif
	if not keyword_set(station_name) then begin
		station_name = 'GS Lon '+string(gs_lon_lat[0],format='(F6.1)')
		station_name += ' Lat '+string(gs_lon_lat[1],format='(F5.1)')
	endif

	;
	;	Set Pass Elevation Minimum
	;
	pass_elevation_min = 5.0  ; degrees
	if keyword_set(elevation_min) then begin
		if (elevation_min[0] gt 0) and (elevation_min[0] lt 90) then begin
			pass_elevation_min = elevation_min[0]
			if keyword_set(verbose) then print, '*** Pass Elevation Minimum (degrees) = ', pass_elevation_min
		endif
	endif

	;
	;	Set time (Julian date format assumed)
	;
	if keyword_set(current_day) then begin
		date1 = systime(/utc,/jul) ; julian date for the current time
		date1 = long(date1-0.5) + 0.5D0  ; force to day boundary
		date2 = date1 + 1.0	; add one day
		date = date1
	endif else begin
		date1 = date[0]
		if n_elements(date) lt 2 then date2 = date1 + 1.0 else date2 = date[1]
		if (date2 lt date1) then begin
			tmp = date2
			date2 = date1
			date1 = tmp
		endif
	endelse
	;  make array of time "t" that has one-second cadence
	num_time = long((date2-date1)*24.D0*3600.)
	;  limit to 30 days of calculations
	if (num_time gt (30L*24L*3600L)) then num_time = 30L*24L*3600L
	time = findgen( num_time ) / (24.D0*3600.) + date1


	;
	;	Get Spacecraft Location
	;		configure results for optional return for spacecraft_pass
	;
	spacecraft_location, time, location, sunlight, id_satellite=satid, tle_path=path_name, $
		verbose=verbose, sun_dot_pos=sun_dot_pos, eci_pv=eci_pv, debug=debug
	; stop, 'DEBUG time, location, sunlight ...'
	sc_locate1 = { time_jd: 0.0D0, longitude: 0.0, latitude: 0.0, altitude: 0.0, $
				sunlight: 0, sun_dot_pos: 0.0, doppler_vel: 0.0, pass_range: 0.0 }
	sc_location = replicate(sc_locate1,n_elements(time))
	sc_location.time_jd = time
	IF location NE [-1] THEN BEGIN
  	sc_location.longitude = reform(location[0,*])
  	sc_location.latitude = reform(location[1,*])
  	sc_location.altitude = reform(location[2,*])
  	sc_location.sunlight = sunlight
  	sc_location.sun_dot_pos = sun_dot_pos
 ENDIF ELSE BEGIN
  IF keyword_set(verbose) THEN message, /INFO, 'spacecraft_location returned null (-1) location data.'
 ENDELSE

  ;
  ;  Calculate Doppler Velocity
  ;    View_Vector = SC ECI Location -  Ground Station ECI location
  ;    Doppler_Velocity = rate of change of View_Distance
  ;
  pv_size = size(eci_pv)
  ; help, eci_pv
  ; print, pv_size
  ;   Can Process Doppler Velocity if have 2D array of PV
  if (pv_size[0] eq 2) then begin
  	  ; stop, 'spacecraft_pass:  DEBUG eci_pv ...'
	  gs_lla = fltarr(3,pv_size[2])
	  gs_lla[0,*] = gs_lon_lat[1]   ;  Latitude
	  gs_lla[1,*] = gs_lon_lat[0]	;  Longitude
	  gs_lla[2,*] = 1.0  ; in km, compromise of Boulder at 1.6 km and Fairbanks at 0.2 km
	  gs_jd = time
	  lla_jd_to_eci, gs_jd, gs_lla, gs_coord  ; convert from LLA to ECI in km units
	  view_vector = [eci_pv[0,*] - gs_coord[0,*], eci_pv[1,*] - gs_coord[1,*], eci_pv[2,*] - gs_coord[2,*]]
	  view_dist = reform(sqrt( view_vector[0,*]^2. + view_vector[1,*]^2. + view_vector[2,*]^2.))
	  time_step = ((shift(time,-1) - shift(time,1))/2.)*(24.*3600.) ; convert time_step to seconds
	  time_step[0] = time_step[1] & time_step[pv_size[2]-1] = time_step[pv_size[2]-2]
	  doppler = ((shift(view_dist,-1) - shift(view_dist,1))/2./time_step)
	  doppler[0] = doppler[1] & doppler[pv_size[2]-1] = doppler[pv_size[2]-2]
	  sc_location.doppler_vel = doppler   ; km/sec
	  sc_location.pass_range = view_dist  ; km
	  ; stop, 'spacecraft_pass:  DEBUG doppler and view_dist ...'
  endif

	;
	;	Find times when ground station can see spacecraft
	;
	dLat = (reform(location[1,*]) - gs_lon_lat[1]) / !radeg  ; convert to radians
	dLong = (reform(location[0,*]) - gs_lon_lat[0])
	wneg = where(dLong gt 180, numneg)
	if (numneg gt 0) then dLong[wneg] -= 360
	wpos = where(dLong lt -180, numpos)
	if (numpos gt 0) then dLong[wpos] += 360
	dLong /= !radeg
	Lat1 = gs_lon_lat[1] / !radeg
	Lat2 = reform(location[1,*]) / !radeg
	chord = (sin(dLat/2.))^2.   +   cos(Lat1) * cos(Lat2) * (sin(dLong/2.))^2.
	arc = abs( 2.0 * atan( sqrt(chord), sqrt(1.0 - chord) ) )
	R_earth = 6371.0D0  ; km
	distance = R_earth * arc
	; stop, 'spacecraft_pass:  DEBUG doppler, view_dist, and arc distance ...'

	pass_limit = R_earth * acos( R_earth / reform(location[2,*]) )
	wgood = where( (distance - pass_limit) lt 0.0, num_good )
	if (num_good lt 2) then begin
		if keyword_set(verbose) then begin
			print, 'No Passes found !!!'
			stop, 'DEBUG spacecraft_pass ...'
		endif
		return	; no passes found
	endif

	;
	;	sort into unique groupings of passes
	;
	tstep = wgood - shift(wgood,1)
	if (tstep[1] eq 1) then tstep[0] = 2 ; allow first group to start at index=0
	wpass = where( tstep ge 2, number_passes )

	if keyword_set(verbose) then begin
		print, '*** Number of potential passes found = ', number_passes
		setplot & cc=rainbow(7)
		jd_zero = long(time[0]-0.5)+0.5
		timezero = (time - jd_zero)*24.  ; convert JD to day boundary first
		plot, timezero, distance, yr=[0,5000.], ys=1, xs=1, $
				xtitle='Time (hour) [JD '+string(jd_zero,format='(F10.1)')+']', ytitle='Distance (km)'
		oplot, timezero, pass_limit, line=2
		; stop, 'DEBUG spacecraft_pass & plot ...'
	endif

	;
	;	store the pass results
	;				pass_array[].start_jd		Julian date
	;				pass_array[].start_date		YYYYDOY
	;				pass_array[].start_time		seconds of day (UT)
	;				pass_array[].end_jd			Julian date
	;				pass_array[].end_date   	YYYYDOY
	;				pass_array[].end_time   	seconds of day (UT)
	;				pass_array[].duration_minutes   End_time - Start_time
	;				pass_array[].max_jd			Julian date
	;				pass_array[].max_date   	YYYYDOY
	;				pass_array[].max_time   	seconds of day (UT)
	;				pass_array[].max_elevation  degrees
	;				pass_array[].sunlight	  	Flag of 0 if in eclipse, 1 if in sunlight at Max Elevation
	;				pass_array[].dir_EW			Flag of 0 if pass is East or 1 if pass West
	;				pass_array[].dir_NS			Flag of 0 if pass is North or 1 if pass South
	;				pass_array[].satellite_name Name of satellite (new in 2017)
	;				pass_array[].station_name	Name of ground station (new in 2017)
	;
	if (number_passes gt 0) then begin
		pass1 = { start_jd: 0.0D0, start_date: 0.D0, start_time: 0.D0, $
				end_jd: 0.0D0, end_date: 0.D0, end_time: 0.D0, $
				duration_minutes: 0.0, max_jd: 0.0D0, max_date: 0.D0, max_time: 0.D0, $
				max_elevation: 0.0, sunlight: 0, dir_EW: 0, dir_NS: 0, $
				satellite_name: satellite_name, station_name: station_name }
		pass_array = replicate( pass1, number_passes )
		pass_range1 = wgood[wpass]
		pass_range2 = [ wgood[wpass[1:*]-1], wgood[n_elements(wgood)-1] ]
		k_count = 0L
		for k=0L,number_passes-1 do begin
			i1 = pass_range1[k]
			i2 = pass_range2[k]
			; only allow if more than 30 seconds
			min_limit = 30.
			if (i2-i1) gt min_limit then begin
				tstart = jd2yd(time[i1])
				pass_array[k_count].start_jd = time[i1]
				pass_array[k_count].start_date = tstart		; keep fraction of day
				pass_array[k_count].start_time = (tstart-long(tstart))*24.D0*3600.
				tend = jd2yd(time[i2])
				pass_array[k_count].end_jd = time[i2]
				pass_array[k_count].end_date = tend		; keep fraction of day
				pass_array[k_count].end_time = (tend-long(tend))*24.D0*3600.
				pass_array[k_count].duration_minutes = (tend - tstart)*24.D0*60.
				;
				;	calculate maximum elevation
				;
				amin = min( arc[i1:i2], imid )
				imid += i1
				tmax = jd2yd(time[imid])
				pass_array[k_count].max_jd = time[imid]
				pass_array[k_count].max_date = tmax		; keep fraction of day
				pass_array[k_count].max_time = (tmax-long(tmax))*24.D0*3600.
				alpha = (!pi - amin)/2.
				cmin = location[2,imid] * 2. * sin(amin/2.)
				beta = atan( sin(alpha) * (location[2,imid]-R_earth) / (cmin - cos(alpha) * (location[2,imid]-R_earth)) )
				pass_array[k_count].max_elevation = (alpha + beta - !pi/2.) * !radeg
				pass_array[k_count].sunlight = sunlight[imid]

				; check if max elevation is West or East of GS
				pass_array[k_count].dir_EW = (location[0,imid] lt gs_lon_lat[0] ? 1 : 0)
				; check if max elevation is North or South of GS
				pass_array[k_count].dir_NS = (location[1,imid] lt gs_lon_lat[1] ? 1 : 0)

				if keyword_set(verbose) and (pass_array[k_count].max_elevation ge pass_elevation_min) then begin
					oplot, timezero[i1]*[1,1], [!y.crange[0],distance[i1]], color=cc[3]
					oplot, timezero[i2]*[1,1], [!y.crange[0],distance[i2]], color=cc[0]
					oplot, timezero[imid]*[1,1], [!y.crange[0],distance[imid]], color=cc[4]
				endif
				k_count += 1L
			endif
		endfor
		;	re-adjust pass info to actually used
		pass_array = pass_array[0:k_count-1]
		number_passes = k_count
		;   adjust so Elevation is high enough
		whigh = where( pass_array.max_elevation ge pass_elevation_min, numhigh )
		if (numhigh gt 0) then begin
			pass_array = pass_array[whigh]
			number_passes = numhigh
		endif else begin
			pass_array = -1L
			number_passes = 0L
		endelse
	endif

	if keyword_set(verbose) then begin
		print, '*** Number of good passes found = ', number_passes
		if (number_passes gt 0) then begin
			print, ' '
			print, '                                                  Duration  Max'
			print, ' Pass      Start_Time             End_Time          Min.   Elev. In_Sunlight'
			for k=0,number_passes-1 do begin
				caldat, pass_array[k].start_jd, month, day, year, hh, mm, ss
				start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
				caldat, pass_array[k].end_jd, month, day, year, hh, mm, ss
				end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
				print, k+1, start_str, end_str, pass_array[k].duration_minutes, $
					pass_array[k].max_elevation, pass_array[k].sunlight, format="(I4,' ',A21,' ',A21,2F8.2,I4)"
			endfor
		endif
		if keyword_set(debug) then stop, 'DEBUG spacecraft_pass ...'
	endif

	RETURN
END
; end of file
