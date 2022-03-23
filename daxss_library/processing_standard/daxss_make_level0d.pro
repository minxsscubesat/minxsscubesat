;+
; NAME:
;   daxss_make_level0d.pro
;
; PURPOSE:
;   Read the Merged Level 0B data product, extract only telemetry points relevant for science, and package with anscillary data
;   in preparation for Level 1 science product
;
;	This is modified version of minxss_make_level0d.pro with changes in telemetry names
;	and also changed to read the Merged Level 0B data product, instead of daily Level 0C files.
;
; CATEGORY:
;    DAXSS Level 0D
;
; CALLING SEQUENCE:
;   daxss_make_level0d
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   version [string]: Software/data product version to store in filename and internal anonymous structure. Default is '1.0.0'.
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
;   Requires daxss merged level0b data in getenv('minxss_data')/fm4/level0b
;
; EXAMPLE:
;   To process whole mission, just run it with no optional inputs.
;	IDL>  daxss_make_level0d, /verbose
;
; PROCEDURE:
;   1. Restore the Level 0C mission lenghth file
;   2. Interpolate time to have single timestamp for all data
;   3. Retrieve and package relevant ancillary data with MinXSS data
;   4. Save interpolated, unified array of structures to disk
;+
PRO daxss_make_level0d, version=version, $
                        DO_NOT_OVERWRITE_FM=DO_NOT_OVERWRITE_FM, VERBOSE=VERBOSE

;;
; 0. Defaults and validity checks
;;

fm = 4

; Defaults and validity checks - FM
IF version EQ !NULL THEN version = '1.0.0'

; Defaults and validity checks - output filename
outputPath = getenv('minxss_data') +path_sep()+ 'fm' + strtrim(fm, 2) +path_sep()+ 'level0d' +path_sep()
outputFilename = outputPath + 'minxss' + strtrim(fm, 2) + '_l0d_mission_length_v' + version + '.sav'

;;
; 1. Restore the Level 0B mission length file
;;
level0bFile = getenv('minxss_data') + path_sep() + 'fm' + strtrim(fm, 2) + path_sep() + 'level0b' + path_sep() $
	+ 'daxss_l0b_merged_*.sav'
allFiles = file_search( level0bFile, count=num_files)
if (num_files gt 0) then level0bFile = allFiles[num_files-1]
IF file_test(level0bFile) THEN BEGIN
	message, /INFO, 'Restoring Level0B file '+level0bFile
	; stop, 'DEBUG Level0B file selected...'
	restore, level0bFile
ENDIF ELSE BEGIN
	message, /INFO, 'ERROR finding DAXSS Level0B merged file.'
	return
ENDELSE

;;
; 2. Interpolate time to have single timestamp for all data
;;

timeArray = daxss_create_uniform_packet_times(hk, sci, packetTimeEmphasis = 'sci', $
        outputInterpolatedUnifiedPacket = interpolatedUnifiedPacket, /DO_PACKET_UNIFICATION, $
        VERBOSE = VERBOSE)

;;
; 3. Retrieve and package relevant ancillary data with MinXSS data
;;

; Prepare to add new tags to interpolatedUnifiedPacket for sps computed position in science packet
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(interpolatedUnifiedPacket, 'LONGITUDE', 'float', insertIndex = 32)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'LATITUDE', 'float', insertIndex = 33)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'ALTITUDE', 'float', insertIndex = 34)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'SUN_RIGHT_ASCENSION', 'float', insertIndex = 35)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'SUN_DECLINATION', 'float', insertIndex = 36)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'EARTH_SUN_DISTANCE', 'float', insertIndex = 37)
unifiedArrayofStructuresWithNewTags = JPMAddTagsToStructure(unifiedArrayofStructuresWithNewTags, 'SPACECRAFT_IN_SAA', 'float', insertIndex = 38)

; Get spacecraft location (lon, lat, alt)
id_satellite = 51657L
spacecraft_location, interpolatedUnifiedPacket.time.jd, spacecraftLocation, sunlightFlag, id_satellite=id_satellite, tle_path=getenv('TLE_dir'), /KEEPNAN

; FIXME: 2016-09-05: JPM: Temporary fix for something wrong with spacecraft_location returning too few values
longitude = reform(spacecraftLocation[0, *])
latitude = reform(spacecraftLocation[1, *])
altitude = reform(spacecraftLocation[2, *]) - 6371. ; Subtract off Earth-radius to get altitude
numberMissingElements = n_elements(interpolatedUnifiedPacket) - n_elements(spacecraftLocation[0, *])
IF numberMissingElements GT 0 THEN BEGIN
  filler = fltarr(numberMissingElements) & filler[*] = !VALUES.F_NAN
  longitude = [longitude, filler]
  latitude = [latitude, filler]
  altitude = [altitude, filler]
ENDIF

unifiedArrayofStructuresWithNewTags.longitude = longitude
unifiedArrayofStructuresWithNewTags.latitude = latitude
unifiedArrayofStructuresWithNewTags.altitude = altitude

; Determine if spacecraft is in the south atlantic anamoly and set flag accordingly
saaBoundaryLatLon = get_saa_boundary()
unifiedArrayofStructuresWithNewTags.spacecraft_in_saa = inside(unifiedArrayofStructuresWithNewTags.longitude, unifiedArrayofStructuresWithNewTags.latitude, saaBoundaryLatLon.lon, saaBoundaryLatLon.lat)

; Get sun angle and distance
sunVector = sunvec(jd = interpolatedUnifiedPacket.time.jd, r = earth_sun_distance, alpha = right_ascension, delta = declination)
unifiedArrayofStructuresWithNewTags.earth_sun_distance = earth_sun_distance ; [AU]
unifiedArrayofStructuresWithNewTags.sun_right_ascension = right_ascension   ; [º]
unifiedArrayofStructuresWithNewTags.sun_declination = declination           ; [º]

; Convert X123 detector temperature from K to ºC
unifiedArrayofStructuresWithNewTags.x123_detector_temperature -= 273.15


; Overwrite flight model number by default.
; Why? Level 0d interpolates the hk.flight_model to the sci packet. If hk and sci are too far apart in time, it fills with NaN.
; We know what level it is though, so just overwrite it unless user does not want this.
IF NOT keyword_set(DO_NOT_OVERWRITE_FM) THEN BEGIN
  unifiedArrayofStructuresWithNewTags.flight_model = fm
ENDIF

;;
; 4. Save interpolated, unified array of structures to disk
;;

minxssLevel0D = unifiedArrayofStructuresWithNewTags
save, minxssLevel0D, filename=outputFilename

; Export to netCDF
; +++++ TODO later
; minxss_make_netcdf, '0d', fm=fm, verbose=verbose, version=version

IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Finished processing Level 0D for dates ' + strtrim(dateRangeYYYYDOY[0], 2) + ' - ' + strtrim(dateRangeYYYYDOY[1], 2)
END
