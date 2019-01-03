;+
; NAME:
;	SUNCOR
;
; PURPOSE:
;	Generates solar coordinates
;
; CATEGORY:
;	Utility
;
; CALLING SEQUENCE:
;	SUNCOR, IDATE, UT, SDEC, SRASN, GST
;
; INPUTS:
;	idate	Date in yyyyddd, longword integer
;	ut	Time of day in seconds, UTC, floating point
;
; OUTPUTS:
;	sdec	solar declination, radians, floating point
;	srasn	solar right ascension, radians, floating point
;	gst	Greenwich sidereal time, radians, floating point
;
; COMMON BLOCKS:
;	None.
;
; PROCEDURE:
;	For a date and time or array of dates and times, the spherical
;	coordinates of the sun in the Earth-Centered Inertial (ECI) system
;	are returned as right ascension and declination.  Greenwich sidereal
;	time (the angle between the Greenwich meridian and the vernal equinox)
;	is also returned.
;	Dates prior to 2000 in yyddd are also accepted for backward
;	compatibility but all dates in an array must be in the same format.
;	Will not work properly after year 2100 due to lack of leap year.
;
; REFERENCE:
;	C.T. Russell, Geophysical Coordinate Transforms.
;
; MODIFICATION HISTORY:
;	~1983	Version F.1	Stan Solomon	Coded in Fortran
;	11/97	Version F.2	John Fulmer	Accept dates in yyyyddd format
;	3/98	Version 1.0	Stan Solomon	Made into an IDL procedure
;	2/00	Version 1.1	Stan Solomon	Made double precision
;
;+

PRO SUNCOR, IDATE, UT, SDEC, SRASN, GST

FDAY=UT/86400.D
IYR=LONG(IDATE)/1000
IDAY=LONG(IDATE)-IYR*1000
IF IYR(0) GE 100 THEN IYR(*) = IYR(*) - 1900
DJ=365*IYR+(IYR-1)/4+IDAY+FDAY-0.5
T=DJ/36525.
VL=(279.696678+.9856473354*DJ) MOD 360.
GST=(279.696678+.9856473354*DJ+360.*FDAY+180.) MOD 360. * !PI/180.
G=(358.475845+.985600267*DJ) MOD 360. * !PI/180.
SLONG=VL+(1.91946-.004789*T)*SIN(G)+.020094*SIN(2.*G)
OBLIQ=(23.45229-0.0130125*T) *!PI/180.
SLP=(SLONG-.005686) * !PI/180.
SIND=SIN(OBLIQ)*SIN(SLP)
COSD=SQRT(1.-SIND^2)
SDEC=ATAN(SIND/COSD)
SRASN=!PI-ATAN(1./TAN(OBLIQ)*SIND/COSD,-COS(SLP)/COSD)

RETURN
END
