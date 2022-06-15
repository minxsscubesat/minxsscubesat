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
;
pro solar_zenith_altitude, date_yyyydoy, longitude, latitude, altitude,  sza_out,trh_out, debug=debug

if n_params() lt 4 then begin
	print, 'USAGE: solar_zenith_altitude, date_yyyydoy, longitude, latitude, altitude,  sza_out,trh_out'
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
time_long = (time/3600.)*15.
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
trh_out = altitude
rearth = 6371.  ; km - average radius of earth
wslant = where( sza gt !pi/2., numslant )
if (numslant ge 1) then trh_out[wslant]=sin(sza[wslant])*(rearth+altitude[wslant])-rearth

; Convert radians into degrees:
sza_out = sza * 180./!pi

if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude ...'
return
end

