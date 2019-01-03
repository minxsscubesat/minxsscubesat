;+
; NAME:
;	LLA_JD_TO_ECI
;
; PURPOSE:
;	Converts Lat/Lon/Alt into position vectors in ECI coordinates
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:
;	ECI_TO_LLA, julian_day, lla, eci
;
; INPUTS:
;	jd 		Julian Day for date and time (instead of Year, DOY, UTC seconds)
;	lla		latitude, longitude, altitude (degrees, degrees, km)
;
; OLD INPUTS:
;	year	Year, yyyy, longword integer
;	doy		Day of Year, ddd, longword integer
;	utc		Coordinated Universal Time of day in seconds, floating point
;
; OUTPUTS:
;       eci	ECI position vector, x, y, z, in km.
;
; KEYWORDS:
;	None
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	Transform geodetic latitude, longitude, and altitude above the surface
;	into Earth-Centered-Inertial position vector.
;	Uses SUNCOR to find Greenwich sidereal time (GST), the angle between
;	the Greenwich meridian and the vernal equinox.
;	Uses oblate spheroid approximation to shape of the Earth for altitude
;	and geodetic latitude calculation (ref.: W.J. Larson & J.R. Wertz,
;	Space Mission Analysis and Design, p. 809)
;	Arrays of vectors are OK!
;
; ROUTINES USED:
;	SUNCOR - calculates coordinates of sun and Greenwich sidereal time
;
; MODIFICATION HISTORY:
;       Stan Solomon, 3/00
;		Tom Woods, 12/2018   Code from lla_to_eci.pro but uses JD instead of Year, DOY, UTC
;-
pro lla_jd_to_eci, jd, lla, eci

; f = Earth oblateness flattening factor, re = equatorial radius:
f = 1./298.257D
re = 6378.14D

; Convert degrees into radians:
lat = lla[0,*] * !pi/180.
lon = lla[1,*] * !pi/180.
alt = lla[2,*]

; Get Greenwich sidereal time:
; yd=year*1000L+doy
yd = jd2yd(jd)
yd_long = long(yd)
utc = (yd - yd_long) * 24.*3600.D0
suncor, yd_long, utc, sdec, srasn, gst

; Calculate  right ascension:
ra = atan(sin(lon+gst),cos(lon+gst))

; Calculate declination:
dec = atan(tan(lat)*(1.-f)^2)

; Calculate normalized position vector:
rnx = cos(ra)*cos(dec)
rny = sin(ra)*cos(dec)
rnz = sin(dec)

; Calculate length of position vector:
rs = alt + re * (1-f)/(sqrt(1-f*(2-f)*(cos(dec))^2))

; Calculate position vector:
eci=lla
eci[0,*]=rnx*rs
eci[1,*]=rny*rs
eci[2,*]=rnz*rs

return
end
