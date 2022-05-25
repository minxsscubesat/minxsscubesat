;+
; NAME:
;   daxss_create_uniform_packet_times.pro
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
;   timeArray = daxss_create_uniform_packet_times( hk, sci, packetTimeEmphasis = packetTimeEmphasis, $
;                                                  outputInterpolatedUnifiedPacket = outputInterpolatedUnifiedPacket, $
;                                                  /VERBOSE)
;
; INPUTS:
;   hk    [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   sci   [structure]: Standard MinXSS processing array with sorted time (e.g., Level 0C processed). Can be !NULL.
;   Note: If all 6 of these are !NULL, there's obviously nothing to process so code will return -1.
;
; OPTIONAL INPUTS:
;   packetTimeEmphasis [string]: Set this to 'adcs1', 'adcs2', 'adcs3', 'adcs4', 'hk', or 'sci' to place strongest emphasis on
;                                that packet type for time inte rpolation.
;                                sci is the default.
;                                If sci is !NULL, the user must provide the desired packetTimeEmphasis.
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
;   timeArray = daxss_create_uniform_packet_times(adcs1, adcs2, adcs3, adcs4, hk, sci, outputInterpolatedUnifiedPacket = interpolatedUnifiedPacket, /DO_PACKET_UNIFICATION, /VERBOSE)
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
;	2022-03-17:  Tom Woods: copy of minxss_create_uniform_packet_times.pro for DAXSS IS-1 mission
;
;+
FUNCTION daxss_create_uniform_packet_times,  hk, sci, $
                    packetTimeEmphasis = packetTimeEmphasis, $
                    outputInterpolatedUnifiedPacket = outputInterpolatedUnifiedPacket, $
                    DO_PACKET_UNIFICATION = DO_PACKET_UNIFICATION, $
                    DO_MULTITHREAD = DO_MULTITHREAD, VERBOSE = VERBOSE, DEBUG = DEBUG
;;
; 0. Defaults and validity checks
;;
fm = 3    ; only FM number for  DAXSS  (changed from 4 to 3 on 5/24/2022, TW)

; Check that all parameters were passed in
IF n_params() LT 2 THEN BEGIN
  message, /INFO, 'USAGE: timeArray = daxss_create_uniform_packet_times( hk, sci, packetTimeEmphasis = packetTimeEmphasis, outputInterpolatedUnifiedPacket = unifiedMinXSSData, /DO_PACKET_UNIFICATION, /VERBOSE)'
  return, -1
ENDIF

; Check that at least one of the input parameters is not !NULL
IF hk EQ !NULL AND sci EQ !NULL THEN BEGIN
  message, /INFO, 'Both packet inputs were !NULL, i.e. nothing to process'
  return, -1
ENDIF

; replace hk.time with hk.daxss_time so that "hk.time" will work properly in daxss_create_uniform_packet_times correclty
hk_time_saved = hk.time
hk.time = hk.daxss_time

; Default for packetTimeEmphasis is science
IF ~keyword_set(packetTimeEmphasis) THEN packetTimeEmphasis = 'sci'
packetTimeEmphasis = strlowcase(packetTimeEmphasis)
IF packetTimeEmphasis ne 'hk' AND packetTimeEmphasis ne 'sci' THEN packetTimeEmphasis = 'sci'

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished defining defaults and verify input parameters'

;;
; 1. Set the packet for interpolation according to packetTimeEmphasis into an internal generic variable, chosenPacket
;;

; SWITCH and CASE can't handle string comparisons so here's an ugly IF THEN ELSE IF... that gets the logical work done
IF packetTimeEmphasis EQ 'hk'    THEN chosenPacket = hk    ELSE IF $
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
; jd = gps2jd(chosenPacket.time)
jd = gps2jd(packetTimeStampsSpaceCraftTime)
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
  save, hk, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
  save, sci, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'

  IF packetTimeEmphasis EQ 'sci' THEN BEGIN
    tic

    ; Create multi-thread object (IDLBridge) to use all but one of the system threads - results in 4x faster processing with 7 threads, SSD
    oBridge = objarr(!cpu.tpool_nthreads - 1 > 1)

    FOR threadIndex = 0, oBridge.length - 1 DO BEGIN
      oBridge[threadIndex] = obj_new('IDL_IDLBridge', callback = 'daxss_create_uniform_packet_time_mulithread_callback')
      oBridge[threadIndex].setProperty, userData = 0 ; 0 = free, 1 = busy, 2 = complete
      oBridge[threadIndex]->SetVar, 'timeToInterpolateTo', packetTimeStampsSpaceCraftTime
      oBridge[threadIndex]->SetVar, 'fm', fm
    ENDFOR

    ; Looping variables
    packetsProcessed = 0
    nextIndex = 0
    numberOfPacketTypes = 2 ; hk, sci

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
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting HK telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
                ENDIF
                IF nextIndex EQ 1 THEN BEGIN
                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting science telemetry interpolation.'
                  oBridge[threadIndex]->SetVar, 'packetToProcessFilename', getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'
                ENDIF
;                IF nextIndex LE 4 THEN BEGIN
;                  IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Setting time threshold for interpolation'
;                  oBridge[threadIndex]->SetVar, 'timeThresholdSeconds', 300.
;                ENDIF ELSE oBridge[threadIndex]->SetVar, 'timeThresholdSeconds', 60.
				; +++++  60 sec is way too small for IS-1 mission (during commissioning)
				timeThresholdSeconds = 12*3600.  ; 12 hours  (versus 60 sec)
				oBridge[threadIndex]->SetVar, 'timeThresholdSeconds', timeThresholdSeconds

                IF keyword_set(DEBUG) THEN BEGIN
                  message, /INFO, JPMsystime() + ' Stopping for debug. You should run:'
                  packetToProcessFilename = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/adcs1Temporary.sav' ; change *temporary as appropriate
                  timeToInterpolateTo = packetTimeStampsSpaceCraftTime
                  timeThresholdSeconds = 300. ; Or 60 if not adcs
                  packetInterpolated = daxss_telemetry_interpolate(packetToProcessFilename, timeToInterpolateTo, timeThresholdSeconds)
                  STOP
                ENDIF

                oBridge[threadIndex]->Execute, "packetInterpolated = daxss_telemetry_interpolate(packetToProcessFilename, timeToInterpolateTo, timeThresholdSeconds)", /NOWAIT
                nextIndex++
              ENDIF
              BREAK
            END
            2: BEGIN
              ; Capture the results
              IF packetsProcessed EQ 0 THEN BEGIN
                WHILE file_test(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav') EQ 0 DO wait, 2
                restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav'
                file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkInterpolatedTemporary.sav'
                IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished interpolating hk telemetry'
              ENDIF
              IF packetsProcessed EQ 1 THEN BEGIN
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

        IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Starting hk telemetry interpolation.'
        hkInterpolated = daxss_telemetry_interpolate(getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav', timeToInterpolateTo, 60., /NO_SAVE)
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
    stop, 'ERROR: it should not ever get to here for DAXSS Processing.'

    FOR timeIndex = 0, n_elements(packetTimeStampsSpaceCraftTime) - 1 DO BEGIN

      ; Strip out redundant tags from all packet types
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
	;
	;	SCI packet emphasis **********************
	;
	message, /INFO, JPMsystime() + ' There are ' + JPMPrintNumber(n_elements(packetTimeStampsSpaceCraftTime), /NO_DECIMALS) + ' points in time for Level 0D'

      ;
      ; Level 0D tag names in order to appear when doing: help, minxsslevel0d, /str
      ;
      time = timeArray

      ; State and power telemetry
      ; 3/20/2022:  T Woods: See daxss_level0d_mapping_2022.xlsx for new definitions  from MinXSS
      ;
      level0dTags = ['flight_model', 'spacecraft_mode', 'adcs_mode', 'eclipse', $
                     'eps_5v_cur', 'eps_5v_volt', 'cdh_3v', 'cdh_5v', $
                     'switch_sps', 'switch_instrument_heater' ]

      ; Attitude and orbit information
      level0dTags = [level0dTags, $
                     'xact_wheel1_measured_speed', 'xact_wheel2_measured_speed', 'xact_wheel3_measured_speed', $
                     'xact_measured_sun_body_vector_x', 'xact_measured_sun_body_vector_y', 'xact_measured_sun_body_vector_z', $
                     'xact_sun_point_angle_error'  ]

      ; SPS and PicoSIM data
      level0dTags = [level0dTags, 'sps_temperature',  $
                     'sps_sum', 'sps_x', 'sps_y', 'sps_num_samples', 'sps_data', $
                     'picosim_temperature', 'picosim_integ_time', $
                     'picosim_num_samples', 'picosim_data' ]

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

	;
	;	FOR loop to add each data point to  structure
	;
    FOR timeIndex = 0, n_elements(packetTimeStampsSpaceCraftTime) - 1 DO BEGIN

      ; Create implicit eclipse flag based on SPS sum for MinXSS
      ; spsSumScience = total(sciInterpolated[timeIndex].sps_data, 1)
      ; IF spsSumScience LT 2E6 THEN eclipse_state = 1 ELSE eclipse_state = 0

      ; Create implicit eclipse flag based on X123 signal for DAXSS
      IF sciInterpolated[timeIndex].x123_slow_count LT 10 THEN eclipse_state = 1 ELSE eclipse_state = 0

	  ; Calculate the  Sun Point Angle from the Sun Vector
	  sun_point_angle_error = 0.0  ;  TBD as Sun Vector broken in IS Beacon Read

      ; Do all of the corresponding values in the same order. Be very careful about order here
      level0dValues = list(hkInterpolated[timeIndex].flight_model, sciInterpolated[timeIndex].spacecraft_mode, hkInterpolated[timeIndex].adcs_info, eclipse_state, $
                           sciInterpolated[timeIndex].eps_5v_cur, sciInterpolated[timeIndex].eps_5v_volt, sciInterpolated[timeIndex].cdh_3v, sciInterpolated[timeIndex].cdh_5v, $
                           sciInterpolated[timeIndex].enable_sps, sciInterpolated[timeIndex].enable_inst_heater, $
                        	hkInterpolated[timeIndex].adcs_wheel_sp1, hkInterpolated[timeIndex].adcs_wheel_sp2, hkInterpolated[timeIndex].adcs_wheel_sp3, $
                           hkInterpolated[timeIndex].adcs_sun_vec1, hkInterpolated[timeIndex].adcs_sun_vec2, hkInterpolated[timeIndex].adcs_sun_vec3, $
                           sun_point_angle_error, $
                           sciInterpolated[timeIndex].sps_board_temp, sciInterpolated[timeIndex].sci_sps_sum, $
                           (sciInterpolated[timeIndex].sci_sps_x / 10000. * 4.45), (sciInterpolated[timeIndex].sci_sps_y / 10000. * 4.45), $
                           sciInterpolated[timeIndex].sps_num_samples, sciInterpolated[timeIndex].sps_data, $
                           sciInterpolated[timeIndex].picosim_temp, sciInterpolated[timeIndex].picosim_integ_time, $
                           sciInterpolated[timeIndex].picosim_num_samples, sciInterpolated[timeIndex].picosim_data, $
                           sciInterpolated[timeIndex].x123_brd_temp, sciInterpolated[timeIndex].x123_det_temp, $
                           sciInterpolated[timeIndex].x123_accum_time/1000., sciInterpolated[timeIndex].x123_live_time/1000., sciInterpolated[timeIndex].x123_real_time/1000., $
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
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/hkTemporary.sav'
  file_delete, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0d/sciTemporary.sav'

ENDIF ; outputInterpolatedUnifiedPacket set

IF keyword_set(VERBOSE) THEN message, /INFO, JPMsystime() + ' Finished merger of all telemetry to common/unified time'

stop, 'DEBUG at end of daxss_create_uniform_packet_times.pro ...'

return, timeArray

END
