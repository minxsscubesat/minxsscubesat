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
			trh_longitude_out, trh_latitude_out, sun_ra_out, sun_dec_out, debug=debug

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
	gst_deg = gst * 180./!pi

; convert LLA to RA-DEC
; year = long(date_yyyydoy)/1000L  & doy = long(date_yyyydoy - year*1000.D0)
; lla_in = [ latitude, longitude, altitude ]
; lla_to_eci, year, doy, time, lla_in, eci_out, ra_dec=sc_ra_dec
; if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude: sun_ra, sc_ra_dec ... '

; Calculate solar zenith angle:
sra_rad = sun_ra ;  * !pi/180.  ; convert to radians
sra_deg = sra_rad *180./!pi
sun_ra_out = sra_deg
sdec_rad = sun_dec ; * !pi/180.
sdec_deg = sdec_rad * 180./!pi
sun_dec_out = sdec_deg
lat_rad = latitude * !pi/180.
long_rad = longitude * !pi/180.
time_long = (time/3600.)*15.  ; convert time (sec of day) to longitude (degrees)
time_long_rad = time_long * !pi/180.
long_fix = longitude
wneg = where(longitude lt 0, nneg)
if (nneg ge 1) then long_fix[wneg] += 360.
long_fix_rad = long_fix * !pi/180.
sra_fix = sra_deg
wneg = where(sra_deg lt 0, nneg)
if (nneg ge 1) then sra_fix[wneg] += 360.
sra_fix_rad = sra_fix * !pi/180.
; longitude rotation angle (hour angle) relative to 12 noon and adjusted for GMT Sideral Time (GST)
; hour angle definition from https://svn.ssec.wisc.edu/repos/cloud_team_cr/trunk/viewing_geometry_module.f90
; rotation_deg = (long_fix + time_long + gst_deg - 180.) mod 360.
; rotation_deg without the GST correction
rotation_deg = (long_fix + time_long - 180.) mod 360.
; longitude rotation angle from noon
; rotation_deg = (long_fix + time_long - 180.) mod 360.
rotation_rad = rotation_deg * !pi/180.
sza = acos(sin(sdec_rad)*sin(lat_rad)+cos(sdec_rad)*cos(lat_rad)*cos(rotation_rad))
sza_org = sza   ; 2022 code for SZA

; now calculate SZA using Hays 1974 equation
;		Reference:  Paul Hays 1974 NASA report for stellar occultation
;				https://ntrs.nasa.gov/api/citations/19740005455/downloads/19740005455.pdf
;
;		alpha = sra_fix_rad & delta = sdec_rad & lambda = long_fix_rad & phi = lat_rad
;		lambda_g = time_long_rad (time)
;
; if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude: time_long, long_fix, rotation_deg ...'
time_rad = time_long_rad  ; GST time in radians = time_long_rad
long_rad = long_fix_rad   ;  long_rad default is long_fix_rad
Ah = cos(long_rad)*cos(lat_rad)*cos(time_rad) - sin(long_rad)*cos(lat_rad)*sin(time_rad)
Bh = sin(long_rad)*cos(lat_rad)*cos(time_rad) + cos(long_rad)*cos(lat_rad)*sin(time_rad)
Ch = sin(lat_rad)
Lh = cos(sra_fix_rad) * cos(sdec_rad)
Mh = sin(sra_fix_rad) * cos(sdec_rad)
Nh = sin(sdec_rad)
sza_hays = acos( Ah * Lh + Bh * Mh + Ch * Nh )

;  sza_org is the correct calculation for SZA and is the one consistent with the DAXSS data
sza = sza_org
beta = !pi - sza

; if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude: sza_org, sza_hays ... '

; Calculate tangent altitude of sun:
;	Case 1:  if SZA is less than 90 degrees, then TRH is S/C  altitude and position
trh_out = altitude
trh_longitude_out = longitude
trh_latitude_out = latitude

;	Case 2:  if SZA is greater than 90, then TRH is calculated at lower altitude
rearth_avg = 6371.  ; km - average radius of earth
; For polar satellites, need to use oblate Earth radius based on latitude
rearth_major = 6378.137D0
rearth_minor = 6356.752D0
f_minor = rearth_minor / rearth_major
rearth_sc = rearth_major * sqrt( (1+(f_minor^4-1.)*(sin(lat_rad))^2) / (1.+(f_minor^2-1)*(sin(lat_rad))^2) )
wslant = where( sza gt !pi/2., numslant )
rsatellite = rearth_sc+altitude

ENABLE_TRH_POINT = 1  ; set to non-zero to allow for TRH Point calculation

if (numslant ge 1) then begin
  ; calculate Tangent Ray Height (TRH) based on Solar Zenith Angle (SZA)
  ; Original 2022 code
  ; trh_out[wslant]=sin(sza[wslant])*(rsatellite[wslant])-rearth
  ;   trh_org = trh_out
  ; Hays equation is the same equation as 2022 original code because sin(!pi-sza) == sin(sza)
  trh_out[wslant]=sin(beta(wslant))*(rsatellite[wslant])-rearth_sc[wslant]

  if (ENABLE_TRH_POINT ne 0) then begin
	xobj = rsatellite*(Ah + Lh * cos(beta))
	yobj = rsatellite*(Bh + Mh * cos(beta))
	zobj = rsatellite*(Ch + Nh * cos(beta))
	xy_obj = sqrt( abs(xobj)^2. + abs(yobj)^2. )
	temp_latitude = atan( zobj[wslant] / xy_obj[wslant] )
	trh_latitude_out[wslant] = temp_latitude * 180./!pi
	temp_longitude_out = acos( xobj[wslant] / xy_obj[wslant] )
	; fix Yobj negative values - this fixes the switch-back issue of earlier versions of this code
	wpos = where( (yobj[wslant] ge 0) and (temp_longitude_out lt 0), numpos)
	if (numpos gt 0) then temp_longitude_out[wpos] *= (-1.)
	wneg = where( (yobj[wslant] lt 0) and (temp_longitude_out gt 0), numneg)
	if (numneg gt 0) then temp_longitude_out[wneg] *= (-1.)
	if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude: yobj[wslant] and temp_longitude_out ...'
	; correct for time offset
	temp_longitude_out -= time_long_rad[wslant]

	temp_fix = temp_longitude_out
	trh_longitude_out[wslant] = temp_fix * 180./!pi
	trh_longitude_org = trh_longitude_out
	; if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude: trh_latitude_out and temp_fix ...'
	; wneg = where( temp_fix lt 0, numneg )
	; if (numneg gt 0) then temp_fix[wneg] = 2.*!pi + temp_fix[wneg]
	; wfix1 = where( (yobj[wslant] ge 0) AND (temp_fix ge !pi), numfix1 )
	; wfix2 = where( (yobj[wslant] lt 0) AND (temp_fix lt !pi), numfix2 )
	; if (numfix1 gt 0) then temp_fix[wfix1] = temp_fix[wfix1] - !pi
	; if (numfix2 gt 0) then temp_fix[wfix2] = temp_fix[wfix2] + !pi
	wfix1 = where( (temp_fix ge !pi), numfix1 )
	wfix2 = where( (temp_fix lt (-1.*!pi)), numfix2 )
	if (numfix1 gt 0) then temp_fix[wfix1] = temp_fix[wfix1] - 2.*!pi
	if (numfix2 gt 0) then temp_fix[wfix2] = temp_fix[wfix2] + 2.*!pi
	trh_longitude_out[wslant] = temp_fix * 180./!pi

	; adjust TRH point altitude for its Latitude
	trh_latitude_rad = trh_latitude_out * !pi/180.
	rearth_trh = rearth_major * sqrt( (1+(f_minor^4-1.)*(sin(trh_latitude_rad))^2) $
										/ (1.+(f_minor^2-1)*(sin(trh_latitude_rad))^2) )
	trh_out[wslant] = trh_out[wslant] + rearth_sc[wslant] - rearth_trh[wslant]
  endif
endif

; Convert radians into degrees:
sza_out = sza * 180./!pi
sza_alt_1 = sza_org * 180./!pi  ;  original calculation
sza_alt_2 = sza_hays * 180./!pi  ;  Hays calculation

if keyword_set(debug) then stop, 'DEBUG solar_zenith_altitude:  sza_alt_1, sza_alt_2 and sza_out ...'
return
end

