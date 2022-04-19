;+
; NAME:
;   daxss_make_level0d_limited.pro
;
; PURPOSE:
;   Read the Merged Level 0B data product, extract only telemetry points relevant
;   for science, and package with LIMITED ancillary data
;   in preparation for Level 1 science product
;
;	This is modified version of minxss_make_level0d.pro with changes in telemetry names
;	and also changed to read the Merged Level 0B data product, instead of daily Level 0C files.
;
; CATEGORY:
;    DAXSS Level 0D
;
; CALLING SEQUENCE:
;   daxss_make_level0d_limited
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   version [string]:   Software/data product version to store in filename and internal anonymous structure. Default is '2.0.0'.
;
; KEYWORD PARAMETERS:
;   DO_NOT_OVERWRITE_FM: Set this to prevent the overwriting of the flight model number in the data product with the fm optional input
;   VERBOSE:             Set this to print processing messages
;
; OUTPUTS:
;   IDL .sav files in getenv('minxss_data')/level0d/idlsavesets/
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires full daxss code package
;   Requires daxss merged level0c data in getenv('minxss_data')/fm4/level0c
;
; EXAMPLE:
;   To process whole mission, just run it with no optional inputs.
;	IDL>  daxss_make_level0d, /verbose
;
; PROCEDURE:
;   1. Restore the Level 0B mission lenghth file
;   2. Interpolate time to have single timestamp for all data
;   3. Retrieve and package relevant ancillary data with DAXSS data
;   4. Save interpolated, unified array of structures to disk
;
; HISTORY:
;   2022-02-16   Tom Woods   Original Code to make a limited version of L0D
;							as IS1 doesn't have ADCS / HK packets very often
;	2022-04-11	Tom Woods	Fixed the L0C file name for reading for processing
;
;+
PRO daxss_make_level0d_limited, version=version, VERBOSE=VERBOSE

;;
; 0. Defaults and validity checks
;;
fm = 4
time_offset_sec = -250.D0

; Defaults and validity checks - FM
IF version EQ !NULL THEN version = '1.0.0'

; Defaults and validity checks - output filename
outputPath = getenv('minxss_data') +path_sep()+ 'fm' + strtrim(fm, 2) +path_sep()+ 'level0d' +path_sep()
outputFilename = outputPath + 'minxss' + strtrim(fm, 2) + '_l0d_mission_length_v' + version + '.sav'

;;
; 1. Restore the Level 0B mission length file
;;
level0cFile = getenv('minxss_data') + path_sep() + 'fm' + strtrim(fm, 2) + path_sep() + 'level0c' + path_sep() $
	+ 'daxss_l0c_all_mission_length_v' + version + '.sav'
allFiles = file_search( level0cFile, count=num_files)
if (num_files gt 0) then level0cFile = allFiles[num_files-1]
IF file_test(level0cFile) THEN BEGIN
	IF keyword_set(VERBOSE) THEN message, /INFO, 'Restoring Level0c file '+level0cFile
	; stop, 'DEBUG Level0c file selected...'
	restore, level0cFile
ENDIF ELSE BEGIN
	message, /INFO, 'ERROR finding DAXSS Level0c merged file.'
	return
ENDELSE

;;
; 2. Make new daxss_level0d structure
;;
daxss_level0d_one = CREATE_STRUCT( sci[0], 'time_yd', 0.0D0, $
					'adcs_mode', 0.0, 'eclipse', 0, $
					'longitude', 0.0, 'latitude', 0.0, 'altitude', 0.0, $
					'sun_right_ascension', 0.0, 'sun_declination', 0.0, $
					'earth_sun_distance', 0.0, 'spacecraft_in_saa', 0.0  )

; make an array for the Level 0D data
num_sci = n_elements(sci)
daxss_level0d = replicate( daxss_level0d_one, num_sci )
IF keyword_set(VERBOSE) THEN message, /INFO, 'Processing DAXSS SCI packets: '+strtrim(num_sci,2)
; copy over SCI packet data
num_sci_tags = N_TAGS(sci[0])
for ii=0L,num_sci_tags-1 do daxss_level0d.(ii) = sci.(ii)

; calculate the JD and YD time conversions
daxss_level0d.time_gps = sci.time_gps
daxss_level0d.time_jd = sci.time_jd
daxss_level0d.time_yd = jd2yd(daxss_level0d.time_jd)
daxss_level0d.time_iso = sci.time_iso
daxss_level0d.time_human = sci.time_human

; interpolate the HK ADCS_INFO result
;  +++++ Quick Test with linear interpolation: really need to pick closest point value (????)
; daxss_level0d.adcs_mode = daxss_interpolate_flags( hk.adcs_info, hk.daxss_time, sci.time )
daxss_level0d.adcs_mode = interpol( hk.adcs_info, hk.daxss_time, sci.time )

; estimate elcipse state based on X123 slow count rate
slow_rate = sci.x123_slow_count / (sci.x123_accum_time/1000.)
weclipse = where(slow_rate lt 50, num_eclipse)
if (num_eclipse gt 0) then daxss_level0d[weclipse].eclipse = 1

; Get spacecraft location (lon, lat, alt)
id_satellite = 51657L
spacecraft_location, daxss_level0d.time_jd, spacecraftLocation, sunlightFlag, id_satellite=id_satellite, tle_path=getenv('TLE_dir'), /KEEPNAN

; FIXME: 2016-09-05: JPM: Temporary fix for something wrong with spacecraft_location returning too few values
longitude = reform(spacecraftLocation[0, *])
latitude = reform(spacecraftLocation[1, *])
altitude = reform(spacecraftLocation[2, *]) - 6371. ; Subtract off Earth-radius to get altitude
numberMissingElements = n_elements(daxss_level0d) - n_elements(spacecraftLocation[0, *])
IF numberMissingElements GT 0 THEN BEGIN
  filler = fltarr(numberMissingElements) & filler[*] = !VALUES.F_NAN
  longitude = [longitude, filler]
  latitude = [latitude, filler]
  altitude = [altitude, filler]
ENDIF
daxss_level0d.longitude = longitude
daxss_level0d.latitude = latitude
daxss_level0d.altitude = altitude

; Determine if spacecraft is in the south atlantic anamoly and set flag accordingly
saaBoundaryLatLon = get_saa_boundary()
daxss_level0d.spacecraft_in_saa = inside(longitude, latitude, saaBoundaryLatLon.lon, saaBoundaryLatLon.lat)

; Get sun angle and distance
sunVector = sunvec(jd = daxss_level0d.time_jd, r = earth_sun_distance, alpha = right_ascension, delta = declination)
daxss_level0d.earth_sun_distance = earth_sun_distance ; [AU]
daxss_level0d.sun_right_ascension = right_ascension   ; [º]
daxss_level0d.sun_declination = declination           ; [º]

;;
; 4. Save DAXSS Level 0D array of structures to disk
;;
IF keyword_set(VERBOSE) THEN message, /INFO, 'Saving DAXSS Level 0D data into '+outputFilename
save, daxss_Level0D, filename=outputFilename

; Export to netCDF
; +++++ TODO later
; minxss_make_netcdf, '0d', fm=fm, verbose=verbose, version=version

IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Finished processing Level 0D Limited'
END
