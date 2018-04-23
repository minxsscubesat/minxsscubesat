;------------------------------------------------------------------------------
;+
; NAME:
; RADEC2AZEL
;
; PURPOSE:
; To convert from celestial coordinates (right ascension-declination)
; to horizon coordinates (azimuth-elevation)
;
; CALLING SEQUENCE:
; RADEC2AZEL, az, el, ra, dec, year, month, day, time, lat, lng
;
; INPUTS:
; ra: Right Ascension (hours)
; dec:  declination (degrees)
; jd: julain date
; lat:  geographical latitude (degrees)
; lng:  geographical longitude (degrees)
;
; OUTPUTS:
; az: azimuth (degrees)
; el: elevation (degrees)
;
; NOTES:
; The azimuth of the North Celestial Pole is 180 degrees
;
; EXAMPLE:
; Find the az-el coordinates corresponding to ra=0 hours, dec=90 degs
; on 1998 August 2, 04h 00s 00s UT, in Palestine (Texas), lat=31.8 degs,
; lng=264.3 degs
;
; IDL> radec2azel,az,el,0.,90.,1998,8,2,4.,31.8,264.3
; IDL> print,az,el
;              180.00000       31.800002
;
; PROCEDURES USED:
; CT2LST - Convert from Civil Time to Local Sidereal Time
;
; MODIFICATION HISTORY:
;      Created, Amedeo Balbi, August 1998 (based partly on material by
;      Pedro Gil Ferreira)
;      Modified, Amedeo Balbi, October 1998, to accept vectors as input
;      2017-01-12: James Paul Mason: Changed input to use jd instead of separte year, month, day, time (hours.fraction)
;-
;------------------------------------------------------------------------------
pro RADEC2AZEL,az,el,ra,dec,jd,lat,lng

; converting from Universal Time to Greenwich Sidereal Time - this is done
; by calling CT2LST with longitude=0 and time zone=0
; (the reason why I don't use CT2LST to obtain Local Sidereal Time directly
; is because I want to work with UT as input in the main procedure and I don't
; want to use the time zone as an additional input parameter)
CT2LST, gst, 0., 0., jd

; converting from Greenwich Sidereal Time to Local Sidereal Time
; the formula is LST = GST + long
lst=float(gst)+lng/15.  ; the long. has a "+" because is measured towards East

; converting to radians
rlat=lat*!dtor
rra=ra*15.*!dtor
rdec=dec*!dtor

lst=lst*2.*!pi/24.
ha=lst-rra

; working out elevation
rel=asin( sin(rdec)*sin(rlat)+cos(rdec)*cos(ha)*cos(rlat) )
el=rel*!radeg

; working out azimuth
az=atan(cos(rdec)*sin(ha),-sin(rdec)*cos(rlat)+cos(rdec)*cos(ha)*sin(rlat))
az=az*!radeg

return
end
