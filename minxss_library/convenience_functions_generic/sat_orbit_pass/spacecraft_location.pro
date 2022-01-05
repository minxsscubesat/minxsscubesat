;
;	spacecraft_location
;
;	Calculate satellite location using spacecraft_pv.pro with TLE input for a specific S/C ID
;
;	INPUT
;		time			Julian Date array of time
;		/id_satellite	Option to specify the satellite ID, else use ISS ID of 25544
;		/tle_path		Option to specify path for TLE, else use $TLE_dir
;		/current_time	Option to use current time instead of input time array
;		/j2000			Option to return ECI_PV data in J2000 epoch instead of current time epoch
;		/verbose		Option to print debug messages
;		/keepNAN    Option to keep NAN data values (else removes invalid location vectors)
;
;	OUTPUT
;		location	3 x n_elements(time) Array of Longitude, Latitude, Altitude
;		sunlight	Flag for if the satellite is in sunlight or not
;		eci_pv		ECI coordinates of the Position and Velocity (optional output)
;		sun_dot_pos	Sun_vector dot_product position_vector (optional output for Beta angle)
;
;	LIBRARY
;		This depends on the Astronomy Library SGP4 and MSGP4,
;		plus wrapper code by Barry Knapp and Chris Jeppesen
;
;	HISTORY
;		2015-11-01	T. Woods	Modified sample_sgp4.pro to be generic for use for ISS / MinXSS
;		2016-06-22  T. Woods	Updated to return sun dot-product pos for /sun_dot_pos for Beta angle
;		2017-01-07  T. Wooods Updated with optional input /keepNAN for data processing algorithm
;
pro spacecraft_location, time, location, sunlight, id_satellite=id_satellite, $
					tle_path=tle_path, current_time=current_time, eci_pv=eci_pv, $
					j2000=j2000, sun_dot_pos=sun_dot_pos, verbose=verbose, debug=debug, keepNAN=keepNAN

	;
	;	default return values if error
	;
	location = -1L
	sunlight = -1L

	if n_params() lt 2 then begin
		print, 'USAGE: spacecraft_location, time, location, sunlight, id_satellite=id_satellite, '
		print, '                     tle_path=tle_path, /current_time, /verbose'
		print, 'time = INPUT time array in Julian Days'
		print, 'location = OUTPUT of longitude, latitude, altitude for each input time value'
		print, 'sunlight = OUTPUT flag if in sunshine (1) or in eclipse (0)'
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
	if keyword_set(debug) then print, '*** TLE path = ', path_name

	;
	;	Set Satellite ID
	;
	if keyword_set(id_satellite) then begin
		satid = id_satellite
	endif else begin
		; satid = 25544		; Satellite ID for ISS
		satid = 41474L		; Satellite ID for MinXSS-1; id_satellite should be passed in if that's not what you want
	endelse

	;
	;	Set time (Julian date format assumed)
	;
	if keyword_set(current_time) then begin
		t = systime(/utc,/jul) ; julian date for the current time
		time = t
	endif else begin
		t = time
	endelse
	theta=gmst(t,/julian)  ; calculate Greenwich Mean Siderial Time, in degrees

	;
	;	Run MSGP4 library to calculate the position and velocity of the spacecraft at each point
	;	Return "pv" that is the Position and Velocity
	;		pv[0:2] is Position vector in Earth-centered Inertial, in km.
	;		pv[3:5] is velocity in same frame in km/s
	;
	spacecraft_pv,satid,t,pv, tle_path=path_name, /force_reload, debug=debug

	;stop, 'DEBUG spacecraft_location for satid, t, pv ...'

	;
	;	Calculate RA/Dec/Radius (inertial lon/lat/rad) of the state vectors
	;
	pv_size = size(pv)
	if (pv_size[0] eq 2) then begin
	  if not keyword_set(keepNAN) then begin
  		; exclude bad data points
  		wgood = where( finite(pv[0,*]) and finite(pv[1,*]) and finite(pv[2,*]), numgood )
  		if numgood gt 1 then begin
  			pv = pv[*,wgood]
  			t = t[wgood]
  			time = time[wgood]
  			theta = theta[wgood]
  			pv_size = size(pv)
  		endif else begin
  			return   ; all numbers are bad
  		endelse
  	endif
		location=dblarr(3,pv_size[2])
		location[0,*]=atan(pv[1,*],pv[0,*])*!radeg 		;RA (longitude) in degrees
		location[0,*]=mlmod(location[0,*]-theta,360d)	;Convert RA to longitude and
		w=where(location[0,*] gt 180d,count)			;  force to between -180deg
		if count gt 0 then location[0,w]-=360d		;  and +180deg
		rho=sqrt(pv[0,*]^2+pv[1,*]^2)
		location[1,*]=atan(pv[2,*],rho)*!radeg     		;Dec (latitude) in degrees
		location[2,*]=sqrt(rho^2+pv[2,*]^2)        		;Radius (altitude) in km
		;  define radius
		r=pv[0:2,*]
		sunlight = intarr(pv_size[2]) + 1
	endif else if (pv_size[0] eq 1) then begin
		location=dblarr(3)
		location[0]=atan(pv[1],pv[0])*!radeg 		;RA (longitude) in degrees
		location[0]=mlmod(location[0]-theta,360d)	;Convert RA to longitude and
		w=where(location[0] gt 180d,count)			;  force to between -180deg
		if count gt 0 then location[0,w]-=360d		;  and +180deg
		rho=sqrt(pv[0]^2+pv[1]^2)
		location[1]=atan(pv[2],rho)*!radeg     		;Dec (latitude) in degrees
		location[2]=sqrt(rho^2+pv[2]^2)        		;Radius (altitude) in km
		;  define radius
		r=pv[0:2]
		sunlight = 1
	endif else begin
		return		; invalid PV array
	endelse

	eci_pv = pv
	if keyword_set(j2000) then begin
		;
		; convert PV data from current time epoch to J2000 epoch
		;
		eci_pv = pv_to_j2000( t[0], eci_pv, verbose=verbose )
	endif

	if keyword_set(verbose) or keyword_set(debug) then begin
		print, 'longitude', location[0]   ;location[0] is longitude of subspacecraft point
		print, 'latitude', location[1]   ;location[1] is latitude
		print, 'distance', location[2]   ;location[2] is distance from center of Earth to spacecraft
	endif

	;
	;	Determine if spacecraft is in the sun or not
	;
	sun=sunvec(jd=t) ;unit vector from center of Earth to sun in Earth-centered Inertial
	if (pv_size[0] eq 2) then begin
		; tsun = transpose(sun)
		tsun = sun
		tr = transpose(r)
	endif else begin
		tsun = sun
		tr = r
	endelse

	; help, tsun, tr
	; stop, 'spacecraft_location: DEBUG tsun, tr ...'
	comp_r_sun=dotp(tsun,tr) ;component of spacecraft position in direction of sun
	sunlight_str = 'sunlight'
	wsun = where( comp_r_sun le 0, scount )
	if scount gt 0 then begin
		; proj_r_sun=tsun*comp_r_sun
		; perp_r_sun=r - proj_r_sun
		rlength = sqrt( r[0,*]^2. + r[1,*]^2. + r[2,*]^2. )
		proj_r_sun = comp_r_sun
		perp_r_sun = sqrt( rlength^2. - proj_r_sun^2. )
		r_e=6378.137 ; equatorial radius of Earth in km
		wdark = where( (comp_r_sun le 0) and (perp_r_sun lt r_e), dcount )
		if dcount gt 0 then begin
			;  print,"in shadow"
			sunlight_str = 'eclipse'
			sunlight[wdark] = 0
		endif
	endif
	if keyword_set(verbose) or keyword_set(debug) then begin
		print, 'Orbit is in ', sunlight_str
		if keyword_set(debug) then stop, 'DEBUG spacecraft_location ...'
	endif

	; save this result for use in Beta calculation in orbit number
	; but convert to unit vector
	if (n_elements(comp_r_sun) eq 1) then begin
	   tr_norm=sqrt(tr[0]^2+tr[1]^2+tr[2]^2)
	endif else begin
	   tr_norm=sqrt(tr[*,0]^2+tr[*,1]^2+tr[*,2]^2)
	endelse
	sun_dot_pos = comp_r_sun / tr_norm

  RETURN
end
