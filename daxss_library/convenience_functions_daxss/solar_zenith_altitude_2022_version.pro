;
;	solar_zenith_altitude.pro
;
;	PURPOSE
;		Calculate solar zenith angle and tangent ray height for spacecraft location
;
;	INPUTS
;		date_yyyydoy					Date and time in fraction of day
;		longitude, latitude, altitude	Spacecraft location in degrees for Lat-Long and in km for Alt
;
;	OUTPUTS
;		sza_out		Solar Zenith Angle in degrees
;		trh_out		Tangent Ray Height in km
;
;	HISTORY
;		6/2/2022	T. Woods, code based on calc_sza.pro from XPS library
;		1/15/2023	T. Woods, added code to estimate longitude and latitude for TRH point
;						Reference:  Paul Hays 1974 NASA report for stellar occultation
;							https://ntrs.nasa.gov/api/citations/19740005455/downloads/19740005455.pdf
;
pro solar_zenith_altitude, date_yyyydoy, longitude, latitude, altitude,  sza_out, trh_out, $
			trh_longitude_out, trh_latitude_out, debug=debug

if n_params() lt 5 then begin
	print, 'USAGE: solar_zenith_altitude, date_yyyydoy, longitude, latitude, altitude, $ '
	print, '           sza_out, trh_out, trh_longitude_out, trh_latitude_out '
	return
endif

; Find solar declination and right ascension, and Greenwich sidereal time
;		RA and DEC are in radians
date = double(long(date_yyyydoy)) ; YYYYDOY as integer number
time = (date_yyyydoy - date)*24.*3600.D0  ; seconds of day in UT time
suncor, date, time, sun_dec, sun_ra, gst

; Calculate solar zenith angle:
sra = sun_ra ;  * !pi/180.  ; convert to radians
sra_deg = sra *180./!pi
sdec = sun_dec ; * !pi/180.
lat_rad = latitude * !pi/180.
long_rad = longitude * !pi/180.
time_long = (time/3600.)*15.  ; convert time (sec of day) to longitude (degrees)
long_fix = longitude
wneg = where(longitude lt 0, nneg)
if (nneg ge 1) then long_fix[wneg] += 360.
sra_fix = sra_deg
wneg = where(sra_deg lt 0, nneg)
if (nneg ge 1) then sra_fix[wneg] += 360.
; rotation_deg = (long_fix + time_long - sra_fix) mod 360.
; longitude rotation angle from noon
rotation_deg = (long_fix + time_long - 180.) mod 360.
rotation_rad = rotation_deg * !pi/180.
sza = acos(sin(sdec)*sin(lat_rad)+cos(sdec)*cos(lat_rad)*cos(rotation_rad))

; Calculate tangent altitude of sun:
;	Case 1:  if SZA is less than 90 degrees, then TRH is S/C  altitude and position
trh_out = altitude
trh_longitude_out = longitude
trh_latitude_out = latitude

;	Case 2:  if SZA is greater than 90, then TRH is calculated at lower altitude
rearth = 6371.  ; km - average radius of earth
wslant = where( sza gt !pi/2., numslant )

ENABLE_TRH_POINT = 0  ; set to non-zero to allow for TRH Point calculation

if (numslant ge 1) then begin
  ; calculate Tangent Ray Height (TRH) based on Solar Zenith Angle (SZA)
  ;		Reference:  Paul Hays 1974 NASA report for stellar occultation
  ;				https://ntrs.nasa.gov/api/citations/19740005455/downloads/19740005455.pdf
  trh_out[wslant]=sin(sza[wslant])*(rearth+altitude[wslant])-rearth
  if (ENABLE_TRH_POINT ne 0) then begin
	; estimate point for tangent ray height position
	trh_path_len = rearth * (sza[wslant] - !pi/2.)
	rotation_rad_adjust = rotation_rad
	; adjust rotation to east if negative and west if positive
	whi = where(rotation_rad gt !pi, numhi)
	if (numhi gt 0) then rotation_rad_adjust[whi] = rotation_rad[whi] - 2.*!pi
	; path_longitude = rearth * (abs(rotation_rad_adjust[wslant]) - !pi/2.) * cos(lat_rad[wslant])
	path_longitude = rearth * (!pi - abs(rotation_rad_adjust[wslant])) * cos(lat_rad[wslant])
	wneg1 = where(rotation_rad_adjust[wslant] lt 0., numneg1)
	if (numneg1 gt 0) then path_longitude[wneg1] = -1. * path_longitude[wneg1]
	w_too_long = where( abs(path_longitude) gt trh_path_len, num_long )
	if (num_long gt 0) then begin
		if keyword_set(debug) then stop, 'Line 68: Check out potential error for path_longitude...'
		path_longitude[w_too_long] = trh_path_len[w_too_long]
	endif
	path_latitude = sqrt(trh_path_len^2. - abs(path_longitude)^2.)
	wpos1 = where(lat_rad[wslant] gt 0, numpos1 )
	; correct latitude so it goes toward equator
	if (numpos1 gt 0) then path_latitude[wpos1] = -1. * path_latitude[wpos1]
	; convert path length into longitude and latitude changes
	trh_longitude_out[wslant] = (longitude[wslant] + $
							(path_longitude / (2.*!pi*rearth*cos(lat_rad[wslant]))) * 360.) mod 360.
	trh_latitude_out[wslant] = latitude[wslant] + (path_latitude / (2.*!pi*rearth)) * 360.
	wpos = where(trh_latitude_out gt 90., numpos)
	wneg = where(trh_latitude_out lt 90., numneg)
	if (numpos gt 0) then trh_latitude_out[wpos] = 180. - trh_latitude_out[wpos]
	if (numneg gt 0) then trh_latitude_out[wneg] = -180. - trh_latitude_out[wneg]
  endif
endif

; Convert radians into degrees:
sza_out = sza * 180./!pi

if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude ...'
return
end

