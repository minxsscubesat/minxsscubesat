;+
; NAME:
;   minxss_create_uniform_packet_times.pro
;
; PURPOSE:
;   Given MinXSS standard packets, generates an interpolated time array centered on science integration time midpoints, when possible.
;   Note that the purpose of Level 0D is for preparation for science Level 1.
;   However, this code may also useful for automation scripts and thus can handle cases where no sci packets are available.
;
; CATEGORY:
;   Level 0D
;
; CALLING SEQUENCE:
;   timeArray = minxss_create_uniform_packet_times(adcs1, adcs2, adcs3, adcs4, hk, sci, packetTimeEmphasis = packetTimeEmphasis, $
;                                                  outputInterpolatedUnifiedPacket = outputInterpolatedUnifiedPacket, $
;                                                  /VERBOSE)
;
; INPUTS:
;   adcs1 [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   adcs2 [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   adcs3 [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   adcs4 [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   hk    [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   sci   [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   Note: If all 6 of these are !NULL, there's obviously nothing to process so code will return -1.
;
; OPTIONAL INPUTS:
;   packetTimeEmphasis [string]: Set this to 'adcs1', 'adcs2', 'adcs3', 'adcs4', 'hk', or 'sci' to place strongest emphasis on
;                                that packet type for time inte rpolation.
;                                sci is the default.
;                                If sci is !NULL, the user must provide the desired packetTimeEmphasis.
;   fm [integer]:                Flight Model number 1 or 2 (default is 1)
;
; KEYWORD PARAMETERS:
;   DO_PACKET_UNIFICATION: Set this to interpolate and unify minxss packet types to common time. Outputs to outputInterpolatedUnifiedPacket.
;   VERBOSE:               Set this to print processing messages
;   DO_MULTITHREAD:        Set this to use multithreading - each packet type processed in parallel. Note: as of 2016/07/25 this is not yet working.
;                          When run sequentially on a Late 2015 27” 5K iMac with quad-core 3.3 GHz Intel Core i5 and 3 threads, it took 20 minutes to
;                          process ~2 months of data. Results will vary.
;   DEBUG:                 Set this to hit a STOP at the best place to debug multithread issues. Unforunately, multithreading prevents
;                          code halting, and any console prints inside the threads. So the code being run in the thread must be called
;                          separately from the command line to debug it.
;
; OUTPUTS:
;   timeArray [structure]: Dates and times interpolated according to packetTimeEmphasis. Structure contains tags:
;                          yyyymmdd [lonarr]: 4-digit year, 2-digit month, 2-digit day
;                          yyyydoy  [lonarr]: 4-digit year, 3-digit day of year
;                          hhmmss   [strarr]: 2-digit hour, 2-digit minute, 2-digit second
;                          sod      [lonarr]: second of day
;                          fod      [fltarr]: fraction of day
;                          jd       [dblarr]: julian date with fractional time as normal for jd
;
; OPTIONAL OUTPUTS:
;   outputInterpolatedUnifiedPacket [structure]: Standard structure but with all data points interpolated to the corresponding points in timeArray
;                                                and all telemetry encapsulated into a single structure
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;   All inputs must be provided, even if one or more are !NULL
;
; EXAMPLE:
;   timeArray = minxss_create_uniform_packet_times(adcs1, adcs2, adcs3, adcs4, hk, sci, outputInterpolatedUnifiedPacket = interpolatedUnifiedPacket, /DO_PACKET_UNIFICATION, /VERBOSE)
;
; PROCEDURE:
;   1. Set the packet for interpolation according to packetTimeEmphasis into an internal generic variable, chosenPacket
;   2. If chosenPacket is science, interpolate the timestamps to midpoints of science integrations, else use as-is spacecraft time; store in packetTimeStampsSpaceCraftTime
;   3. Convert packetTimeStampsSpaceCraftTime to all formats for timeArray output (yyyymmdd, yyyydoy, hhmmss, sod, fod, jd)
;   4. If outputInterpolatedUnifiedPacket optional output requested, interpolate all other packet types to the chosenPacket packetTimeStamps and unifies to single structure
;
; MODIFICATION HISTORY:
;   2015-11-02: James Paul Mason: Wrote program
;   2016-07-25: James Paul Mason: Added a new DO_MULTITHREAD keyword. The threads weren't working suddenly so just defaulted to new code that runs sequentially.
;                                 Also added a new DEBUG keyword to suggest the location for debugging of multithreading stuff.
;   2016-09-05: James Paul Mason: Replaced for loop that did timeArray creation with a 10,000x faster method: structure replicate
;   2016-12-27: James Paul Mason: Found that the time array was not including the computed yyyydoy input. It was initialized and computed but not populated. Fixed.
;+
FUNCTION minxss_create_uniform_packet_times, adcs1, adcs2, adcs3, adcs4, hk, sci, $
                                             fm = fm, packetTimeEmphasis = packetTimeEmphasis, outputInterpolatedUnifiedPacket = outputInterpolatedUnifiedPacket, $
                                             DO_PACKET_UNIFICATION = DO_PACKET_UNIFICATION, DO_MULTITHREAD = DO_MULTITHREAD, VERBOSE = VERBOSE, DEBUG = DEBUG
;;
; 0. Defaults and validity checks
;;

; Check that all parameters were passed in
IF n_params() LT 6 THEN BEGIN
  message, /INFO, 'USAGE: timeArray = minxss_create_uniform_packet_times(adcs1, adcs2, adcs3, adcs4, hk, sci, packetTimeEmphasis = packetTimeEmphasis, outputInterpolatedUnifiedPacket = unifiedMinXSSData, /DO_PACKET_UNIFICATION, /VERBOSE)'
  return, -1
ENDIF

; Check that at least one of the input parameters is not !NULL
IF adcs1 EQ !NULL AND adcs2 EQ !NULL AND adcs3 EQ !NULL AND adcs4 EQ !NULL AND hk EQ !NULL AND sci EQ !NULL THEN BEGIN
  message, /INFO, 'All 6 inputs were !NULL, i.e. nothing to process'
  return, -1
ENDIF

; Default for packetTimeEmphasis is science
IF ~keyword_set(packetTimeEmphasis) THEN packetTimeEmphasis = 'sci'

; Default flight model is 1
IF ~keyword_set(fm) THEN fm = 1

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished defining defaults and verify input parameters'

;;
; 1. Set the packet for interpolation according to packetTimeEmphasis into an internal generic variable, chosenPacket
;;

; SWITCH and CASE can't handle string comparisons so here's an ugly IF THEN ELSE IF... that gets the logical work done
IF packetTimeEmphasis EQ 'adcs1' THEN chosenPacket = adcs1 ELSE IF $
   packetTimeEmphasis EQ 'adcs2' THEN chosenPacket = adcs2 ELSE IF $
   packetTimeEmphasis EQ 'adcs3' THEN chosenPacket = adcs3 ELSE IF $
   packetTimeEmphasis EQ 'adcs4' THEN chosenPacket = adcs4 ELSE IF $
   packetTimeEmphasis EQ 'hk'    THEN chosenPacket = hk    ELSE IF $
   packetTimeEmphasis EQ 'sci'   THEN chosenPacket = sci

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished determination of packet to emphasize for time interpolation'

;;
; 2. If chosenPacket is science, interpolate the timestamps to midpoints of science integrations, else use as-is spacecraft time; store in packetTimeStampsSpaceCraftTime
;;

IF packetTimeEmphasis EQ 'sci' THEN BEGIN
  packetTimeStampsSpaceCraftTime = chosenPacket.time - ((chosenPacket.x123_real_time / 1000.) / 2.) ; x123_live_time in miliseconds, so must convert to seconds
ENDIF ELSE BEGIN ; if science packet, else any other packet type
  packetTimeStampsSpaceCraftTime = chosenPacket.time
ENDELSE

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished spacecraft time identification and interpolation to midpoint of science integration, if applicable'

;;
; 3. Convert packetTimeStampsSpaceCraftTime to all formats for timeArray output (yyyymmdd, yyyydoy, hhmmss, sod, fod, jd, spacecraft time)
;;

; Conversion of minxss packet time (GPS format) to all the wonderful ways to look at time
jd = gps2jd(chosenPacket.time)
packetTimeYYYYDOY_FOD = jd2yd(jd)
yyyydoy = long(packetTimeYYYYDOY_FOD)
fod = packetTimeYYYYDOY_FOD - yyyydoy
sod = long(round(fod * 24. * 3600.))
hhmmss = JPMsod2hhmmss(sod, /RETURN_STRING)
yyyymmdd = JPMjd2yyyymmdd(jd)
iso = JPMjd2iso(jd)
tai = anytim2tai(iso)
human = JPMjd2iso(jd, /NO_T_OR_Z)

; Store all those wonderful time formats into timeArray (array of structures)
tic
timeArray = {iso:iso[0], human:human[0], yyyymmdd:yyyymmdd[0], yyyydoy:yyyydoy[0], hhmmss:hhmmss[0], sod:sod[0], fod:fod[0], jd:jd[0], tai:tai[0], spacecraftGpsFormat:chosenPacket[0].time}
timeArray = replicate(timeArray, n_elements(sod))
timeArray.iso = iso
timeArray.human = human
timeArray.yyyymmdd = yyyymmdd
timeArray.yyyydoy = yyyydoy
timeArray.hhmmss = hhmmss
timeArray.sod = sod
timeArray.fod = fod
timeArray.jd = jd
timeArray.tai = tai
timeArray.spacecraftGpsFormat = chosenPacket.time

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished converting spacecraft time to various convenient time formats'

;;
; 4. If outputInterpolatedUnifiedPacket optional output requested, interpolate all other packet types to the chosenPacket packetTimeStamps and unifies to single structure
;;

IF keyword_set(DO_PACKET_UNIFICATION) THEN BEGIN

  ; Write packets to disk because with multithreading IDLBridge can't pass structures or use common blocks
  save, adcs1, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav'
  save, adcs2, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2Temporary.sav'
  save, adcs3, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3Temporary.sav'
  save, adcs4, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4Temporary.sav'
  save, hk, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
  save, sci, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'

  IF packetTimeEmphasis EQ 'sci' THEN BEGIN
    tic

    ; Create multi-thread object (IDLBridge) to use all but one of the system threads - results in 4x faster processing with 7 threads, SSD
    oBridge = objarr(!cpu.tpool_nthreads - 1 > 1)

    FOR threadIndex = 0, oBridge.length - 1 DO BEGIN
      oBridge[threadIndex] = obj_new('IDL_IDLBridge', callback = 'minxss_create_uniform_packet_time_mulithread_callback')
      oBridge[threadIndex].setProperty, userData = 0 ; 0 = free, 1 = busy, 2 = complete
      oBridge[threadIndex]->SetVar, 'timeToInterpolateTo', packetTimeStampsSpaceCraftTime
      oBridge[threadIndex]->SetVar, 'fm', fm
    ENDFOR

    ; Looping variables
    packetsProcessed = 0
    nextIndex = 0
    numberOfPacketTypes = 6 ; adcs1, adcs2, adcs3, adcs4, hk, sci

    ; Multi-threaded loop
    WHILE packetsProcessed LT numberOfPacketTypes DO BEGIN
      IF keyword_set(DO_MULTITHREAD) THEN BEGIN

        FOR threadIndex = 0, oBridge.length - 1 DO BEGIN
          oBridge[threadIndex].getProperty, userdata = threadStatus

          ; Check the status of thread
          SWITCH (threadStatus) OF
            0: BEGIN
              ; Assign thread work if there is work to be had
              IF nextIndex LT numberOfPacketTypes THEN BEGIN
                oBridge[threadIndex].setProperty, userData = 1 ; 0 = free, 1 = busy, 2 = complete
                IF nextIndex EQ 0 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 1 telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav'
                ENDIF
                IF nextIndex EQ 1 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 2 telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2Temporary.sav'
                ENDIF
                IF nextIndex EQ 2 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 3 telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3Temporary.sav'
                ENDIF
                IF nextIndex EQ 3 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 4 telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4Temporary.sav'
                ENDIF
                IF nextIndex EQ 4 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting HK telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
                ENDIF
                IF nextIndex EQ 5 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting science telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'
                ENDIF
                IF nextIndex LE 4 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Setting time threshold for interpolation'
                  oBridge[threadIndex]->SetVar, 'timeThresholdSeconds', 300.
                ENDIF ELSE oBridge[threadIndex]->SetVar, 'timeThresholdSeconds', 60.

                IF keyword_set(DEBUG) THEN BEGIN
                  message, /INFO, JPMsystime() + ' Stopping for debug. You should run:'
                  packetToProcessFilename = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav' ; change *temporary as appropriate
                  timeToInterpolateTo = packetTimeStampsSpaceCraftTime
                  timeThresholdSeconds = 300. ; Or 60 if not adcs
                  packetInterpolated = minxss_telemetry_interpolate(packetToProcessFilename, timeToInterpolateTo, timeThresholdSeconds, fm = fm)
                  STOP
                ENDIF

                oBridge[threadIndex]->Execute, "packetInterpolated = minxss_telemetry_interpolate(packetToProcessFilename, timeToInterpolateTo, timeThresholdSeconds, fm = fm)", /NOWAIT
                nextIndex++
              ENDIF
              BREAK
            END
            2: BEGIN
              ; Capture the results
              IF packetsProcessed EQ 0 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1InterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1InterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1InterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating adcs1 telemetry'
              ENDIF
              IF packetsProcessed EQ 1 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2InterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2InterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2InterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating adcs2 telemetry'
              ENDIF
              IF packetsProcessed EQ 2 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3InterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3InterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3InterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating adcs3 telemetry'
              ENDIF
              IF packetsProcessed EQ 3 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4InterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4InterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4InterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating adcs4 telemetry'
              ENDIF
              IF packetsProcessed EQ 4 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating hk telemetry'
              ENDIF
              IF packetsProcessed EQ 5 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciInterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciInterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciInterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating sci telemetry'
              ENDIF
              packetsProcessed++
              oBridge[threadIndex].setProperty, userData = 0 ; 0 = free, 1 = busy, 2 = complete
              BREAK
            END
            ELSE: BEGIN
              ; Nothing to do because thread is still busy
            END
          ENDSWITCH
        ENDFOR ; each thread
      ENDIF ELSE BEGIN ; end multithread, begin sequential
        timeToInterpolateTo = packetTimeStampsSpaceCraftTime

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 1 telemetry interpolation.'
        adcs1Interpolated = minxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav', timeToInterpolateTo, 300., fm = fm, /NO_SAVE)
        packetsProcessed++

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 2 telemetry interpolation.'
        adcs2Interpolated = minxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2Temporary.sav', timeToInterpolateTo, 300., fm = fm, /NO_SAVE)
        packetsProcessed++

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 3 telemetry interpolation.'
        adcs3Interpolated = minxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3Temporary.sav', timeToInterpolateTo, 300., fm = fm, /NO_SAVE)
        packetsProcessed++

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting ADCS 4 telemetry interpolation.'
        adcs4Interpolated = minxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4Temporary.sav', timeToInterpolateTo, 300., fm = fm, /NO_SAVE)
        packetsProcessed++

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting hk telemetry interpolation.'
        hkInterpolated = minxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav', timeToInterpolateTo, 60., fm = fm, /NO_SAVE)
        packetsProcessed++

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' sci telemetry interpolation unnecessary since all other packets interpolated to sci.'
        sciInterpolated = sci
        packetsProcessed++

      ENDELSE ; end sequential processing (not multithreaded)

    ENDWHILE ; still packets to process

    IF keyword_set(VERBOSE) THEN message, /INFO, 'Time to complete interpolation = ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'
  ENDIF ELSE BEGIN ; If packet emphasis is sci, else it's any other emphasis
    ; TODO: Implement interpolation for other packet types
  ENDELSE

  unifiedStructure = !NULL
  IF packetTimeEmphasis NE 'sci' THEN BEGIN
    FOR timeIndex = 0, n_elements(packetTimeStampsSpaceCraftTime) - 1 DO BEGIN

      ; Strip out redundant tags from all packet types
      adcs1StrippedOneTime = JPMRemoveTags(adcs1Interpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'CDH_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD', 'TAI_SECONDS', 'JULIAN_DATE_TAI', 'TIME_VALID', 'ORBIT_TIME'])
      adcs1StrippedOneTime = JPMRemoveTags(adcs1StrippedOneTime, 'ATTITUDE_FILTER_RESIDUAL1') ; TODO: This shouldn't be in this structure at all, check minxss_make_level0b.pro
      adcs1StrippedOneTime = JPMChangeTags(adcs1StrippedOneTime, 'SEQ_COUNT', 'ADCS1_SEQ_COUNT')
      adcs2StrippedOneTime = JPMRemoveTags(adcs2Interpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'CDH_INFO', 'ADCS_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD'])
      adcs2StrippedOneTime = JPMChangeTags(adcs2StrippedOneTime, 'SEQ_COUNT', 'ADCS2_SEQ_COUNT')
      adcs3StrippedOneTime = JPMRemoveTags(adcs3Interpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'CDH_INFO', 'ADCS_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD'])
      adcs3StrippedOneTime = JPMChangeTags(adcs3StrippedOneTime, 'SEQ_COUNT', 'ADCS3_SEQ_COUNT')
      adcs4StrippedOneTime = JPMRemoveTags(adcs4Interpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'CDH_INFO', 'ADCS_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD'])
      adcs4StrippedOneTime = JPMChangeTags(adcs4StrippedOneTime, 'SEQ_COUNT', 'ADCS4_SEQ_COUNT')
      hkStrippedOneTime    = JPMRemoveTags(hkInterpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'ADCS_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD'])
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'SEQ_COUNT', 'HK_SEQ_COUNT')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'XPS_DATA', 'XPS_DATA_HK')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'DARK_DATA', 'DARK_DATA_HK')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'X123_FAST_COUNT', 'X123_FAST_COUNT_HK')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'X123_SLOW_COUNT', 'X123_SLOW_COUNT_HK')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'X123_DET_TEMP', 'X123_DET_TEMP_HK')
      hkStrippedOneTime    = JPMChangeTags(hkStrippedOneTime, 'X123_BRD_TEMP', 'X123_BRD_TEMP_HK')
      sciStrippedOneTime   = JPMRemoveTags(sciInterpolated[timeIndex], ['APID', 'SEQ_FLAG', 'DATA_LENGTH', 'TIME', 'CDH_INFO', 'ADCS_INFO', 'ADCS_GROUP', 'SPAREBYTE', 'CHECKBYTES', 'SYNCWORD'])
      sciStrippedOneTime   = JPMChangeTags(sciStrippedOneTime, 'SEQ_COUNT', 'SCI_SEQ_COUNT')

      ; Merge structures
      time = timeArray
      unifiedStructureOneTime = create_struct(time[timeIndex], adcs1StrippedOneTime, adcs2StrippedOneTime, adcs3StrippedOneTime, adcs4StrippedOneTime, hkStrippedOneTime, sciStrippedOneTime)

      ; Add to array of structures
      unifiedStructure = [unifiedStructure, unifiedStructureOneTime]
    ENDFOR ; timeIndex loop
  ENDIF ELSE BEGIN ; If emphasis not science, else is science emphasis
    FOR timeIndex = 0, n_elements(packetTimeStampsSpaceCraftTime) - 1 DO BEGIN
      IF timeIndex EQ 0 THEN message, /INFO, JPMsystime() + ' There are ' + JPMPrintNumber(n_elements(packetTimeStampsSpaceCraftTime), /NO_DECIMALS) + ' points in time for Level 0D'

      ;
      ; Level 0D tag names in order to appear when doing: help, minxsslevel0d, /str
      ;

      time = timeArray

      ; State and power telemetry
      level0dTags = ['flight_model', 'spacecraft_mode', 'adcs_mode', 'eclipse', 'radio_transmitted', 'radio_received', $
                     'eps_5v_cur', 'eps_5v_volt', 'sps_xps_pwr_3v', 'sps_xps_pwr_a5v', 'sps_xps_pwr_d5v', $
                     'switch_sps', 'switch_adcs', 'switch_battery_heater']

      ; Attitude and orbit information
      level0dTags = [level0dTags, 'measured_attitude_valid', $
                     'xact_wheel1_measured_speed', 'xact_wheel2_measured_speed', 'xact_wheel3_measured_speed', $
                     'attitude_quaternion1', 'attitude_quaternion2', 'attitude_quaternion3', 'attitude_quaternion4', $
                     'xact_measured_sun_body_vector_x', 'xact_measured_sun_body_vector_y', 'xact_measured_sun_body_vector_z', $
                     'xact_sun_point_angle_error', $
                     'orbit_position_ECI1', 'orbit_position_ECI2', 'orbit_position_ECI3', $
                     'orbit_position_ECEF1', 'orbit_position_ECEF2', 'orbit_position_ECEF3']

      ; SPS and XP data
      level0dTags = [level0dTags, 'sps_xps_temperature', 'sps_dark_data_hk', 'sps_dark_data_sci', $
                     'sps_sum_hk', 'sps_xp_integration_time', 'sps_x_hk', 'sps_y_hk', 'sps_data_sci', $
                     'xps_data_hk', 'xps_data_sci']

      ; X123
      level0dTags = [level0dTags, 'x123_board_temperature', 'x123_detector_temperature', $
                     'x123_accum_time', 'x123_live_time', 'x123_real_time', $
                     'x123_cmp_info', 'x123_flags', 'x123_read_errors', 'x123_write_errors', $
                     'x123_gp_count', $
                     'x123_high_voltage', $
                     'x123_radio_flag', $
                     'x123_spect_len', $
                     'x123_fast_count', 'x123_slow_count', $
                     'x123_spectrum']

      ; Time
      level0dTags = [level0dTags, 'time']

      ; Create implicit eclipse flag based on SPS sum
      spsSumScience = total(sciInterpolated[timeIndex].sps_data, 1)
      IF spsSumScience LT 2E6 THEN eclipse_state = 1 ELSE eclipse_state = 0

      ; Do all of the corresponding values in the same order. Be very careful about order here
      level0dValues = list(hkInterpolated[timeIndex].flight_model, sciInterpolated[timeIndex].spacecraft_mode, sciInterpolated[timeIndex].adcs_mode, eclipse_state, hkInterpolated[timeIndex].radio_transmitted, hkInterpolated[timeIndex].radio_received, $
                           hkInterpolated[timeIndex].eps_5v_cur, hkInterpolated[timeIndex].cdh_5v, hkInterpolated[timeIndex].sps_xps_pwr_3v, hkInterpolated[timeIndex].sps_xps_pwr_a5v, hkInterpolated[timeIndex].sps_xps_pwr_d5v, $
                           hkInterpolated[timeIndex].enable_sps_xps, hkInterpolated[timeIndex].enable_adcs, hkInterpolated[timeIndex].enable_batt_heater, $
                           adcs2Interpolated[timeIndex].measured_attitude_valid, hkInterpolated[timeIndex].xact_wheel1measspeed, hkInterpolated[timeIndex].xact_wheel2measspeed, hkInterpolated[timeIndex].xact_wheel3measspeed, $
                           adcs1Interpolated[timeIndex].attitude_quaternion1, adcs1Interpolated[timeIndex].attitude_quaternion2, adcs1Interpolated[timeIndex].attitude_quaternion3, adcs1Interpolated[timeIndex].attitude_quaternion4, $
                           hkInterpolated[timeIndex].xact_meassunbodyvectorx, hkInterpolated[timeIndex].xact_meassunbodyvectory, hkInterpolated[timeIndex].xact_meassunbodyvectorz, $
                           adcs3Interpolated[timeIndex].sun_point_angle_error, $
                           adcs1Interpolated[timeIndex].orbit_position_ECI1, adcs1Interpolated[timeIndex].orbit_position_ECI2, adcs1Interpolated[timeIndex].orbit_position_ECI3, $
                           adcs1Interpolated[timeIndex].orbit_position_ECEF1, adcs1Interpolated[timeIndex].orbit_position_ECEF2, adcs1Interpolated[timeIndex].orbit_position_ECEF3, $
                           hkInterpolated[timeIndex].sps_xps_temp, hkInterpolated[timeIndex].dark_data, sciInterpolated[timeIndex].dark_data, $
                           hkInterpolated[timeIndex].sps_sum, sciInterpolated[timeIndex].sps_xp_integration_time, (hkInterpolated[timeIndex].sps_x / 1000. * 3.0), (hkInterpolated[timeIndex].sps_y / 1000. * 3.0), sciInterpolated[timeIndex].sps_data, $
                           hkInterpolated[timeIndex].xps_data, sciInterpolated[timeIndex].xps_data, $
                           sciInterpolated[timeIndex].x123_brd_temp, sciInterpolated[timeIndex].x123_det_temp, $
                           sciInterpolated[timeIndex].x123_accum_time, sciInterpolated[timeIndex].x123_live_time, sciInterpolated[timeIndex].x123_real_time, $
                           sciInterpolated[timeIndex].x123_cmp_info, sciInterpolated[timeIndex].x123_flags, sciInterpolated[timeIndex].x123_read_errors, sciInterpolated[timeIndex].x123_write_errors, $
                           sciInterpolated[timeIndex].x123_gp_count, $
                           sciInterpolated[timeIndex].x123_hv, $
                           sciInterpolated[timeIndex].x123_radio_flag - 1, $
                           sciInterpolated[timeIndex].x123_spect_len, $
                           sciInterpolated[timeIndex].x123_fast_count, sciInterpolated[timeIndex].x123_slow_count, $
                           sciInterpolated[timeIndex].x123_spectrum, $
                           time[timeIndex])

      ; Add to array of structures
      temphash = orderedhash(level0dTags, level0dValues)
      unifiedStructure = [unifiedStructure, temphash.ToStruct(MISSING = !VALUES.F_NAN)]
    ENDFOR ; timeIndex loop
  ENDELSE ; Emphasis on sci

  outputInterpolatedUnifiedPacket = unifiedStructure

  ; Clean up disk
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs2Temporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs3Temporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs4Temporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'

ENDIF ; outputInterpolatedUnifiedPacket set

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished merger of all telemetry to common/unified time'

return, timeArray

END
