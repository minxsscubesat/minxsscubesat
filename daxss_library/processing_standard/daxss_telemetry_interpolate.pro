;+
; NAME:
;   daxss_telemetry_interpolate.pro
;
; PURPOSE:
;   Linearly interpolate data across time but with a timeThreshold for the maximum allowable time between
;   a datapoint being interpolated to and the two datapoints being interpolated from. For example, if a
;   a science packet time is 12:00 UT, and the nearest hk packet times are 3:00 UT and 18:00 UT, interpolation
;   of hk to 12:00 will be untrustworthy.
;
; CATEGORY:
;   Level 0D
;
; CALLING SEQUENCE:
;   Example: outputY = daxss_telemetry_interpolate(adcs2.tag_name, adcs2.time, packetTimeStampsSpaceCraftTime, timeThresholdSeconds = 300)
;
; INPUTS:
;   packetToProcessFilename [string]: Path/filename of a IDL saveset containing one of the standard MinXSS packet types:
;                                     e.g., getenv('minxss_data') + '/fm1/level0d/adcs1Temporary.sav'. Disk IO is necessary for multithreaded variable passing.
;   timeToInterpolateTo [dblarr]:     The time values being interpolated to, corresponding also to the .time MinXSS telemetry.
;                                     Same as IDL interpol's XOUT input. Can be any number of elements, including 1.
;   timeThresholdSeconds [float]:     The time threshold to apply - if the inputTimes surrounding timeToInterpolateTo[i] are ≥ timeThresholdSeconds,
;                                     then !NAN will be output for the corresponding element in the output array.
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 1 or 2 (default is 1)
;
; KEYWORD PARAMETERS:
;   NO_SAVE: Set this to prevent saving temporary files to disk, which is only needed for multithreading
;   (verbose won't work inside a thread)
;
; OUTPUTS:
;   packetInterpolated [array of structure]: The linearly interpolated data to the timeToInterpolateTo points, with
;                                            timeThresholdSeconds applied to return !NAN for any element not satisfying the conditions described above.
;                                            Note that integer (int, uint, long, ulong) are converted to float so that NAN can be inserted where appropriate.
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS software package, but only closest.pro in particular
;
; EXAMPLE:
;   packetInterpolated = daxss_telemetry_interpolate(getenv('minxss_data') + '/fm1/level0d/hkTemporary.sav', sci.time, 60.)
;
; PROCEDURE:
;   1. Linearly interpolate with the timeThresholdSeconds restriction according to the description in header
;
; MODIFICATION HISTORY:
;   2015/11/04: James Paul Mason: Wrote program.
;   2015/11/11: James Paul Mason: Multi-threaded code to decrease processing time. Followed example here:
;                                 http://www.exelisvis.com/Company/PressRoom/Blogs/IDLDataPointDetail/TabId/902/ArtMID/2926/ArticleID/13977/Threaded-Processing-In-IDL.aspx
;+
FUNCTION daxss_telemetry_interpolate, packetToProcessFilename, timeToInterpolateTo, timeThresholdSeconds, NO_SAVE = NO_SAVE

;;
; 0. Defaults and validity checks
;;
fm=3    ; changed from FM4 to FM3 on 5/24/2022, TW

IF n_params() LT 3 THEN BEGIN
  print, 'USAGE: outputY = daxss_telemetry_interpolate(inputY, inputTime, timeToInterpolateTo, timeThresholdSeconds = timeThresholdSeconds'
  return, -1
ENDIF

; Load data
restore, packetToProcessFilename
IF strmatch(packetToProcessFilename, '*hkTemporary.sav') THEN packetToProcess = hk
IF strmatch(packetToProcessFilename, '*sciTemporary.sav') THEN packetToProcess = sci

;;
; 1. Linearly interpolate with the timeThresholdSeconds restriction according to the description in header
;;

; Grab packet time
packetTimes = packetToProcess.time

; Convert integer datatypes to float so that NAN can be used
tagNames = tag_names(packetToProcess)
packetConverted = {}
FOR tagIndex = 0, n_tags(packetToProcess[0]) - 1 DO IF isa(packetToProcess[0].(tagIndex), /INTEGER) AND ~isa(packetToProcess[0].(tagIndex), 'Byte') THEN $
  packetConverted = create_struct(packetConverted, tagNames[tagIndex], 0.0) ELSE $
  packetConverted = create_struct(packetConverted, tagNames[tagIndex], packetToProcess[0].(tagIndex))

; Create new array of structures with n_elements = the n_elements of the array to interpolate to
packetInterpolated = replicate(create_struct(packetConverted), n_elements(timeToInterpolateTo))

FOR tagIndex = 0, n_tags(packetToProcess) - 1 DO BEGIN
  ; Don't process X123 spectrum since for Level 0D, other packets are interpolated to the center point of these data
  IF tagNames[tagIndex] EQ 'X123_SPECTRUM' THEN CONTINUE
  ; IF tagNames[tagIndex] EQ 'ADCS_LEVEL' THEN CONTINUE ; TODO: This is ADCS_LEVEL0 data - packetInterpolated needs to be recurssive to deal with this [32, time] array. Just skipping for now

  ; Can't interpolate the strings in time_iso or time_human so just recompute them
  IF tagNames[tagIndex] EQ 'TIME_ISO' THEN BEGIN
    FOR timeIndex = 0, n_elements(timeToInterpolateTo) - 1 DO BEGIN
      IF finite(packetInterpolated[timeIndex].time) THEN packetInterpolated[timeIndex].time_iso = JPMjd2iso(packetInterpolated[timeIndex].time_jd) $
      ELSE packetInterpolated[timeIndex].time_iso = ''
    ENDFOR
    CONTINUE ; Don't need to do other interpolation so skip the rest of the loop
  ENDIF
  IF tagNames[tagIndex] EQ 'TIME_HUMAN' THEN BEGIN
    FOR timeIndex = 0, n_elements(timeToInterpolateTo) - 1 DO BEGIN
      IF finite(packetInterpolated[timeIndex].time) THEN packetInterpolated[timeIndex].time_human = JPMjd2iso(packetInterpolated[timeIndex].time_jd, /NO_T_OR_Z) $
      ELSE packetInterpolated[timeIndex].time_human = ''
    ENDFOR
    CONTINUE ; Don't need to do other interpolation so skip the rest of the loop
  ENDIF

  packetSingleTag = packetToProcess.(tagIndex)

  ; Determine datatype of inputY, and convert any integer types to float so that NAN's can be used
  inputYDataType = size(packetSingleTag[0], /TYPE)
  IF inputYDataType EQ 2 OR inputYDataType EQ 3 OR inputYDataType EQ 12 OR inputYDataType EQ 13 THEN inputYDataType = 4

  interpolatedPacketSingleTag = make_array(n_elements(timeToInterpolateTo), TYPE = inputYDataType)

  FOR timeIndex = 0, n_elements(timeToInterpolateTo) - 1 DO BEGIN

    ; Determine nearest neighbor data points in time
    nearestInputTimeUpperIndex = closest(timeToInterpolateTo[timeIndex], packetTimes, /UPPER)
    nearestInputTimeLowerIndex = closest(timeToInterpolateTo[timeIndex], packetTimes, /LOWER)
    nearestInputTimeUpper = packetTimes[nearestInputTimeUpperIndex]
    nearestInputTimeLower = packetTimes[nearestInputTimeLowerIndex]

    ; Compute absolute time difference between nearest neighbors
    t1 = abs(timeToInterpolateTo[timeIndex] - nearestInputTimeLower)
    t2 = abs(timeToInterpolateTo[timeIndex] - nearestInputTimeUpper)

    IF size(packetSingleTag, /N_DIMENSIONS) GT 1 THEN BEGIN
      FOR otherIndexOfArray = 0, n_elements(packetSingleTag[*, 0]) - 1 DO BEGIN

        IF isa(interpolatedPacketSingleTag, 'byte') THEN badDataFlag = byte(-1) ELSE badDataFlag = !VALUES.F_NAN

        ; Check conditions and store appropriate data into array
        IF nearestInputTimeUpperIndex EQ -1 OR nearestInputTimeLowerIndex EQ -1 THEN interpolatedPacketSingleTag[timeIndex] = badDataFlag ELSE $
        IF t1 GT timeThresholdSeconds OR t2 GT timeThresholdSeconds             THEN interpolatedPacketSingleTag[timeIndex] = badDataFlag ELSE $
          interpolatedPacketSingleTag[timeIndex] = interpol([packetSingleTag[otherIndexOfArray, nearestInputTimeLowerIndex], packetSingleTag[otherIndexOfArray, nearestInputTimeUpperIndex]], $
                                                            [nearestInputTimeLower, nearestInputTimeUpper], $
                                                            timeToInterpolateTo[timeIndex])
        packetInterpolated.(tagIndex)[otherIndexOfArray] = interpolatedPacketSingleTag

      ENDFOR ; otherIndexOfArray
    ENDIF ELSE BEGIN ; If the tag is a 2D array, else it's a 1D array (i.e. telemetry across time)

      IF isa(interpolatedPacketSingleTag, 'byte') THEN badDataFlag = byte(-1) ELSE badDataFlag = !VALUES.F_NAN

      ; Check conditions and store appropriate data into array
      IF strmatch(tagNames[tagIndex], 'switch*', /FOLD_CASE) THEN interpolatedPacketSingleTag[timeIndex] = packetSingleTag[nearestInputTimeLowerIndex] ELSE $
      IF nearestInputTimeUpperIndex EQ -1 OR nearestInputTimeLowerIndex EQ -1 THEN interpolatedPacketSingleTag[timeIndex] = badDataFlag ELSE $
      IF t1 GT timeThresholdSeconds OR t2 GT timeThresholdSeconds             THEN interpolatedPacketSingleTag[timeIndex] = badDataFlag ELSE $
        interpolatedPacketSingleTag[timeIndex] = interpol([packetSingleTag[nearestInputTimeLowerIndex], packetSingleTag[nearestInputTimeUpperIndex]], $
                                                          [nearestInputTimeLower, nearestInputTimeUpper], $
                                                          timeToInterpolateTo[timeIndex])
      packetInterpolated.(tagIndex) = interpolatedPacketSingleTag
    ENDELSE
  ENDFOR ; timeIndex
ENDFOR ; tagIndex

; Export data - has to use disk to get out of multithread
IF ~keyword_set(NO_SAVE) THEN BEGIN
  IF strmatch(packetToProcessFilename, '*hkTemporary.sav') THEN BEGIN
    hkInterpolated = temporary(packetInterpolated)
    save, hkInterpolated, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav'
    return, hkInterpolated
  ENDIF
  IF strmatch(packetToProcessFilename, '*sciTemporary.sav') THEN BEGIN
    sciInterpolated = temporary(packetInterpolated)
    save, sciInterpolated, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciInterpolatedTemporary.sav'
    return, sciInterpolated
  ENDIF
ENDIF

return, packetInterpolated
END
