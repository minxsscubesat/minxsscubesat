;+
; NAME:
;	LLA_TO_ECF
;
; PURPOSE:
;	Converts Lat/Lon/Alt into position vectors in ECF coordinates
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:
;	LLA_TO_ECF, lla, ecf
;
; INPUTS:
;	lla		latitude, longitude, altitude (degrees, degrees, km)
;
; OUTPUTS:
;   ecf		ECF position vector, x, y, Z, in km.
;
; KEYWORDS:
;	None
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	Transform geodetic latitude, longitude, and altitude above the surface
;	into Earth-Centered-Fixed position vector.
;	Arrays of vectors are OK!
;
; ROUTINES USED:
;	SIN and COS
;
; MODIFICATION HISTORY:
;       Tom Woods, 12/30/2018
;
;-
pro lla_to_ecf, lla, ecf

; f = Earth oblateness flattening factor, re = equatorial radius:
f = 1./298.257D
re = 6378.14D

; Convert degrees into radians:
lat = lla[0,*] * !pi/180.
lon = lla[1,*] * !pi/180.
alt = lla[2,*]


; Calculate  right ascension:
ra = lon ;  atan(sin(lon),cos(lon)) == lon

; Calculate declination:
dec = atan(tan(lat)*(1.-f)^2)   ;  dec = lat if had spherical Earth

; Calculate normalized position vector:
rnx = cos(ra)*cos(dec)
rny = sin(ra)*cos(dec)
rnz = sin(dec)

; Calculate length of position vector:
rs = alt + re * (1-f)/(sqrt(1-f*(2-f)*(cos(dec))^2))

; Calculate position vector:
ecf=lla
ecf[0,*]=rnx*rs
ecf[1,*]=rny*rs
ecf[2,*]=rnz*rs

return
end
