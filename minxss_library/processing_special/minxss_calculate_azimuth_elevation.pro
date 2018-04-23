;+
; NAME:
;   minxss_calculate_azimuth_elevation
;
; PURPOSE:
;   Calculate the azimuth and elevation for every level 0c hk packet
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is a special folder on James's computer. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   None
;
; OPTIONAL OUTPUTS:
;   azimuthOut [fltarr]: All of the azimuth values corresponding to the points in time of the level 0c mission length file
;   elevationOut [fltarr]: Same as azimuth, but for elevation
; 
; RESTRICTIONS:
;   Requires MinXSS level 0C mission length file
;
; EXAMPLE:
;   minxss_calculate_azimuth_elevation, azimuthOut = azimuth, elevationOut = elevation
;
; MODIFICATION HISTORY:
;   2017-01-10: James Paul Mason: Wrote script.
;-
PRO minxss_calculate_azimuth_elevation, azimuthOut = azimuthOut, elevationOut = elevationOut, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = '/Users/' + getenv('username') + '/Dropbox/Research/Postdoc_LASP/Papers/20170701 CubeSat Pointing and Power On Orbit/Figures/'
ENDIF

; Setup
minxssNoradId = 41474L
boulderAltitudeMeters = 1655.   ; [m]
boulderLatitude = 40.014984     ; [º]
boulderLongitude = -105.270546  ; [º]
earthRadius = 6371.0D0          ; [km]

; Restore level 0c file
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Compute the orbital elements, extract right ascension and declination
spacecraft_pv, minxssNoradId, hk.time_jd, positionVelocity, tle_path = getenv('TLE_dir'), /FORCE_RELOAD, COORID = 1
rightAscension = positionVelocity[0, *]
declination = positionVelocity[1, *]
alt1 = positionVelocity[2, *]

; Compute the orbital elements again, this time get the longitude and latitude
spacecraft_location, hk.time_jd, location, id_satellite = minxssNoradId, eci_pv = eci_pv, /KEEPNAN
longitude = reform(location[0, *]) ; [º]
latitude = reform(location[1, *])  ; [º]
altitude = reform(location[2, *])  ; from center of earth [km]

; Find times when LASP ground station can see MinXSS
dLatitudeRadians = (latitude - boulderLatitude) / !radeg
dLongitude = (longitude - boulderLongitude)
negativeLongitudeIndices = where(dLongitude GT 180, numneg)
IF numneg GT 0 THEN dLongitude[negativeLongitudeIndices] -= 360
positiveLongitudeIndices = where(dLongitude LT -180, numpos)
IF numpos GT 0 THEN dLongitude[positiveLongitudeIndices] += 360
dLongitudeRadians = dLongitude / !radeg
boulderLatitudeRadians = boulderLatitude / !radeg
latitudeRadians = latitude / !radeg
chord = (sin(dLatitudeRadians / 2.))^2. + cos(boulderLatitudeRadians) * cos(latitudeRadians) * (sin(dLongitudeRadians / 2.))^2.
arc = abs(2.0 * atan(sqrt(chord), sqrt(1.0 - chord)))
distance = earthRadius * arc
pass_limit = earthRadius * acos(earthRadius / altitude)
visibleInBoulderIndices = where((distance - pass_limit) LT 0.0 AND altitude LT earthRadius + 450, num_good)

; Restrict data to just that when Boulder can see MinXSS
rightAscension = rightAscension[visibleInBoulderIndices]
declination = declination[visibleInBoulderIndices]
hk = hk[visibleInBoulderIndices]
longitudeVisible = longitude[visibleInBoulderIndices]
latitudeVisible = latitude[visibleInBoulderIndices]
alt1Visible = alt1[visibleInBoulderIndices]

; Export ECI position and segmented UTC date for MATLAB eci2aer function
eci = eci_pv[0:2, *] * 1e3 ; [m] I hope because that's what units MATLAB needs and Tom's code doesn't specify units but it calls Chris's code that does and that's in km
eci = eci[*, visibleInBoulderIndices]
yyyy = strmid(hk.time_iso, 0, 4)
mm = strmid(hk.time_iso, 5, 2)
dd = strmid(hk.time_iso, 8, 2)
hh = strmid(hk.time_iso, 11, 2)
minute = strmid(hk.time_iso, 14, 2)
ss = strmid(hk.time_iso, 17, 2)
write_csv, saveloc + 'eci dates.csv', yyyy, mm, dd, hh, minute, ss, HEADER = ['Year', 'Month', 'Day', 'Hour', 'Minute', 'Second']
write_csv, saveloc + 'eci.csv', reform(eci[0, *]), reform(eci[1, *]), reform(eci[2, *]), HEADER = ['X', 'Y', 'Z']

; Read in the output from MATLAB -- conversion of ECI to Az/El
azimuthElevationRange = read_csv(saveloc + 'AzElRange.csv')
azimuth = azimuthElevationRange.field1   ; [º]
elevation = azimuthElevationRange.field2 ; [º]
range = azimuthElevationRange.field3     ; [m]

p1 = plot(azimuth, elevation, LINESTYLE = 'none', SYMBOL = '*', COLOR = 'black', $ 
          TITLE = 'MinXSS-1 Az-El Map', $
          XTITLE = 'Azimuth [º]', XRANGE = [0, 360], $
          YTITLE = 'Elevation [º]')
p2 = plot(p1.xrange, [0, 0], '--', /OVERPLOT)
t1 = text(0.77, 0.83, 'N = ' + JPMPrintNumber(n_elements(azimuth), /NO_DECIMALS), COLOR = 'black')
p1.save, saveloc + 'LASP Ground Station Elevation vs Azimuth.png'

END