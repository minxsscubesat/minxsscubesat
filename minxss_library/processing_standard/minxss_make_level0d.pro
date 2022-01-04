;+
; NAME:
;   minxss_make_level0d.pro
;
; PURPOSE:
;   Read all Level 0C data products, extract only telemetry points relevant for science, and package with anscillary data
;   in preparation for Level 1 science product 
;
; CATEGORY:
;    MinXSS Level 0D
;
; CALLING SEQUENCE:
;   minxss_make_level0d
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:       Flight Model number 1 or 2 (default is 2)
;   dateRange [dblarr]: Date range to process. Can be single date or date range, e.g., [2016001] or [2016001, 2016030].
;                       If single date input, then that full day will be processed. If two dates input, processing will be inclusive of the full range. 
;                       Date formats can be either yyyydoy or yyyymmdd, e.g., [2016152] or [20160601]. 
;                       Time within a day is ignored here i.e., yyyydoy.fod or yyyymmdd.hhmmmss can be input but time information
;                       will be ignored. Code always starts from day start, i.e., fod = 0.0. 
;                       If timeRange is not provided, then code will process all Level0C data.
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
;   Requires full minxss code package
;   Requires minxss level0c data in getenv('minxss_data')/level0c
; 
; EXAMPLE: 
;   To process whole mission, just run it with no optional inputs. 
;   If you want only a specific day: minxss_make_level0d, dateRange = [20160724]
;   
; PROCEDURE:
;   1. Restore the Level 0C mission lenghth file
;   2. Interpolate time to have single timestamp for all data
;   3. Retrieve and package relevant ancillary data with MinXSS data
;   4. Save interpolated, unified array of structures to disk
;+
PRO minxss_make_level0d, fm=fm, dateRange=dateRange, version=version, $ 
                         DO_NOT_OVERWRITE_FM=DO_NOT_OVERWRITE_FM, VERBOSE=VERBOSE

;;
; 0. Defaults and validity checks 
;;

; Defaults and validity checks - FM
IF ~keyword_set(fm) THEN fm = 2
IF (fm GT 2) OR (fm LT 1) THEN BEGIN
  print, "ERROR: minxss_make_level0d needs a valid 'fm' value. FM can be 1 or 2."
  return
ENDIF
IF version EQ !NULL THEN version = '2.0.0'

; Defaults and validity checks - dateRange
dateRangeYYYYDOY = lonarr(2)
IF dateRange NE !NULL THEN BEGIN
  
  ; Determine if using normal date formatting (i.e., yyyymmdd) and convert to yyyydoy
  IF strlen(strtrim(dateRange[0], 2)) GT 7 THEN BEGIN
    yearDoy1 = JPMyyyymmdd2yyyydoy(double(dateRange[0]))
    IF yearDoy1.doy LT 100 THEN doyString = '0' + strtrim(yearDoy1.doy, 2) ELSE doyString = strtrim(yearDoy1.doy, 2)
    dateRangeYYYYDOY[0] = long(strtrim(yearDoy1.year, 2) + doyString)
    
    IF n_elements(dateRange) EQ 2 THEN BEGIN
      yearDoy2 = JPMyyyymmdd2yyyydoy(double(dateRange[1]))
      IF yearDoy2.doy LT 100 THEN doyString = '0' + strtrim(yearDoy2.doy, 2) ELSE doyString = strtrim(yearDoy2.doy, 2)
      dateRangeYYYYDOY[1] = long(strtrim(yearDoy2.year, 2) + doyString)
    ENDIF
  ENDIF ELSE BEGIN
    dateRangeYYYYDOY[0] = dateRange[0]
    IF n_elements(dateRange) EQ 2 THEN dateRangeYYYYDOY[1] = dateRange[1]
  ENDELSE
  
  
  ; If single dateRange input then process that whole day
  IF dateRangeYYYYDOY[1] EQ 0 THEN dateRangeYYYYDOY[1] = dateRangeYYYYDOY[0] + 1L
  
ENDIF ELSE BEGIN ; endif dateRange ≠ NULL else dateRange not set
  ; If no dateRange input then process mission length
  IF fm EQ 1 THEN BEGIN
    dateRangeYYYYDOY = [JPMyyyymmdd2yyyydoy(20160516), JPMyyyymmdd2yyyydoy(20170506)]
  ENDIF ELSE IF fm EQ 2 THEN BEGIN
    dateRangeYYYYDOY = [JPMyyyymmdd2yyyydoy(20181203), long(jd2yd(systime(/julian) + 0.5))]
  ENDIF
ENDELSE

; Defaults and validity checks - output filename
outputPath = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/'
IF dateRange EQ !NULL THEN outputFilename = outputPath + 'minxss' + strtrim(fm, 2) + '_l0d_mission_length_v' + version + '.sav' ELSE $
  outputFilename = outputPath + 'minxss' + strtrim(fm, 2) + '_l0d_' + strtrim(JPMyyyydoy2yyyymmdd(dateRangeYYYYDOY[0]), 2) + '-' + strtrim(JPMyyyydoy2yyyymmdd(dateRangeYYYYDOY[1]), 2) + '_v ' + version + '.sav'

;;
; 1. Restore the Level 0C mission lenghth file
;;
level0cFile = getenv('minxss_data') + path_sep() + 'fm' + strtrim(fm, 2) + path_sep() + 'level0c' + path_sep() + 'minxss' + strtrim(fm, 2) + '_l0c_all_mission_length.sav'
IF file_test(level0cFile) THEN restore, level0cFile

;;
; 2. Interpolate time to have single timestamp for all data
;;

timeArray = minxss_create_uniform_packet_times(adcs1, adcs2, adcs3, adcs4, hk, sci, fm = fm, packetTimeEmphasis = 'sci', $ 
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
IF fm EQ 1 THEN id_satellite = 41474L ELSE $ 
                id_satellite = 43758
spacecraft_location, interpolatedUnifiedPacket.time.jd, spacecraftLocation, sunlightFlag, id_satellite = id_satellite, tle_path = getenv('TLE_dir'), /KEEPNAN

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
unifiedArrayofStructuresWithNewTags.x123_detector_temperature-= 273.15


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
minxss_make_netcdf, '0d', fm = fm, verbose = verbose

IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Finished processing Level 0D for dates ' + strtrim(dateRangeYYYYDOY[0], 2) + ' - ' + strtrim(dateRangeYYYYDOY[1], 2)
END