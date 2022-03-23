;+
; **************
;
;	2022:  DO NOT USE FOR DAXSS PROCESSING BECAUSE DAXSS Level 0B is already merged and sorted
;
; **************
; NAME:
;   daxss_make_level0c.pro
;
; PURPOSE:
;   Read all Level 0B data products, sort by time, and save packets for individual day.
;   Note that Level 0B files can have packets from any past day because of downlink playback.
;   Level 0C files only have packets of a single day.
;   Optionally creates a single file for the whole mission as well.
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   yyyydoy [long]:  Optional input of yyyymmdd date to find telemetry files with that date
;   yyyymmdd [long]: Optional input of yyyymmdd date to find telemetry files with that date, instead of yyyydoy.
;
; KEYWORD PARAMETERS:
;   VERBOSE:             Set this to print processing messages
;   MAKE_MISSION_LENGTH: Set this to create a mission length file
;   MERGE_ONLY:          Set this to skip the reprocessing and go straight to merging the mission length file
;
; OUTPUTS:
;   IDL .sav files in getenv('minxss_data')/fm4/level0c
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires DAXSS processing suite
;
; PROCEDURE:
;   1. Find all Level 0B files
;   2. Read all of the Level 0B files
;   3. Sort the selected packets by time
;   4. Save the sorted packets (file per day)
;
;+
PRO daxss_make_level0c, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, $
                        VERBOSE = VERBOSE, MAKE_MISSION_LENGTH = MAKE_MISSION_LENGTH, MERGE_ONLY = MERGE_ONLY

  ;
  ; check for valid input parameters
  ;
  IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)

  IF keyword_set(yyyydoy) THEN BEGIN
    start_yd = long(yyyydoy[0])
    IF n_elements(yyyydoy) GT 1 THEN BEGIN
      stop_yd = long(yyyydoy[1])
    ENDIF ELSE BEGIN
      stop_yd = start_yd
    ENDELSE
  ENDIF ELSE BEGIN
    ; process all possible dates
    start_yd = 2019001L
    stop_yd = long(jd2yd(systime(/julian))+0.5)
    yyyydoy = [start_yd, stop_yd]
  endelse
  if n_elements(yyyydoy) GT 1 THEN stop_yd = long(yyyydoy[1]) ELSE stop_yd = start_yd

  IF keyword_set(MERGE_ONLY) THEN BEGIN
    MAKE_MISSION_LENGTH = 1
  ENDIF

  IF keyword_set(MAKE_MISSION_LENGTH) THEN BEGIN
    start_yd = 2019001 ; FIXME: Update this to the actual launch date
    stop_yd = long(JPMjd2yyyydoy(systime(/JULIAN)+1.5))
  ENDIF

  IF keyword_set(MERGE_ONLY) THEN BEGIN
    GOTO, MERGE_ONLY
  ENDIF

  ;
  ; 1. Find all Level 0B files
  ;
  fileNamesArray = daxss_find_files('L0B', numfiles=numfiles, VERBOSE = VERBOSE)


  IF numfiles lt 1 THEN BEGIN
    message, /ERROR, ' can not find the Level 0B files'
    return
  ENDIF

  ; Identify which file can first be used: all files with date > start_yd
  start_index = 0L
  first_file = daxss_filename_parts(fileNamesArray[0])
  start_yd = first_file.yyyydoy

  ; Make array of yd and jd
  jd1 = yd2jd(start_yd)
  jd2 = yd2jd(stop_yd)
  numDays = long(jd2 - jd1) + 1 & numDays = numDays[0]
  ydArray = long(jd2yd(findgen(numDays) + jd1))

  ;
  ; Loop through each date that needs processing
  ;
  for k = 0L, numDays - 1 do begin
    yd = ydArray[k]
    fileCnt = 0L

    ;
    ;   2. Read all of the appropriate Level 0B files: all files with date >= YYYYDOY
    ;      minus one day, since L0B is based on local (Mountain) time, but L0C is based on UTC
    ;

    for iFile = start_index, numfiles-1 do begin
      ; identify which file can first be read
      fn_parts = daxss_filename_parts(fileNamesArray[iFile])
      IF (fn_parts.yyyydoy LE (yd - 1)) THEN CONTINUE ELSE BEGIN

        ; Null out all variables before reading new ones in to avoid stale data propagation
        sci = !NULL
        log = !NULL
        dump = !NULL

        ; Restore data
        restore, fileNamesArray[iFile]
        fileCnt += 1

        ; combine packets with previous file records
        if sci NE !NULL then if all_sci NE !NULL then all_sci = [all_sci, sci] else all_sci = sci
        if log NE !NULL then if all_log NE !NULL then all_log = [all_log, log] else all_log = log
        if dump NE !NULL then if all_dump NE !NULL then all_dump = [all_dump, dump] else all_dump = dump
      endelse
    endfor ; loop through telemetry files (iFile)

    if keyword_set(verbose) then begin
      message, /INFO, 'Number of files processed is ', strtrim(fileCnt,2), ' for date ', strtrim(yd,2)
    endif

    ;
    ; 4. Sort the found packets by time
    ;
    IF all_sci NE !NULL THEN minxss_sort_packets, all_sci
    IF all_log NE !NULL THEN minxss_sort_packets, all_log
    IF all_dump NE !NULL THEN minxss_sort_packets, all_dump

    ;
    ; 5. Save the sorted packets (file per day)
    ;

    ; Figure out the directory name to make
    year = long(yd / 1000L)
    doy = long(yd - year * 1000L)
    doy_str = strtrim(doy, 2)
    if strlen(doy_str) eq 1 then doy_str = '00' + doy_str $
    else if strlen(doy_str) eq 2 then doy_str = '0' + doy_str
    str_yd = strtrim(year, 2) + '_' + doy_str
    outputFilename = 'daxss' + '_l0c_' + str_yd
    full_Filename = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level0c' + path_sep() + outputFilename + '.sav'

    ;  rename variables to be like Level 0B names
    if all_sci NE !NULL then sci = all_sci else sci = !NULL & all_sci = !NULL
    if all_log NE !NULL then log = all_log else log = !NULL & all_log = !NULL
    if all_dump NE !NULL then dump = all_dump else dump = !NULL & all_dump = !NULL

    ; Add all the times you can think of, including human readable, to each packet type
    IF sci NE !NULL THEN BEGIN
      sci = JPMAddTagsToStructure(sci, 'time_jd') & sci.time_jd = gps2jd(sci.time)
      sci = JPMAddTagsToStructure(sci, 'time_iso', 'string') & sci.time_iso = JPMjd2iso(sci.time_jd)
      sci = JPMAddTagsToStructure(sci, 'time_human', 'string') & sci.time_human = JPMjd2iso(sci.time_jd, /NO_T_OR_Z)
    ENDIF
    IF log NE !NULL THEN BEGIN
      log = JPMAddTagsToStructure(log, 'time_jd') & log.time_jd = gps2jd(log.time)
      log = JPMAddTagsToStructure(log, 'time_iso', 'string') & log.time_iso = JPMjd2iso(log.time_jd)
      log = JPMAddTagsToStructure(log, 'time_human', 'string') & log.time_human = JPMjd2iso(gps2jd(log.time), /NO_T_OR_Z)
    ENDIF
    IF dump NE !NULL THEN BEGIN
      dump = JPMAddTagsToStructure(dump, 'time_jd') & dump.time_jd = gps2jd(dump.time)
      dump = JPMAddTagsToStructure(dump, 'time_iso', 'string') & dump.time_iso = JPMjd2iso(dump.time_jd)
      dump = JPMAddTagsToStructure(dump, 'time_human', 'string') & dump.time_human = JPMjd2iso(dump.time_jd, /NO_T_OR_Z)
    ENDIF

    ; save the packets now
    total_packets = n_elements(hk) + n_elements(sci) + n_elements(log)

    if (total_packets gt 0) then begin
      save, sci, log, dump, FILENAME = full_Filename, /COMPRESS, description = 'DAXSS Level 0C data; Year = ' + strtrim(year, 2) + '; DOY = ' + strtrim(doy, 2) + ' ... FILE GENERATED: ' + JPMsystime()
      wait, 0.5 ; let the filesystem catch up so files are saved in proper time-order

      if keyword_set(verbose) then begin
        message, /INFO, 'Saving DAXSS Level 0C sorted packets into ' + outputFilename
        if sci NE !NULL then   print, '    Number of SCI   packets = ' + string(n_elements(sci))
        if log NE !NULL then   print, '    Number of LOG   packets = ' + string(n_elements(log))
        if dump NE !NULL then  print, '    Number of dump  packets = ' + string(n_elements(dump))
      endif
    endif else begin
      if keyword_set(verbose) then begin
        message, /INFO, 'No Level 0C data for ', outputFilename
      endif
    endelse
  endfor ; loop through each day that needs processing

  ; Compile into mission length saveset for each type of data
  MERGE_ONLY:
  IF keyword_set(MAKE_MISSION_LENGTH) THEN BEGIN
    dataPath = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level0c' + path_sep()

    ; Prepare for concatenation
    sciTemp = !NULL
    logTemp = !NULL
    dumpTemp = !NULL

    ; Loop through all the data files and concatenate data
    FOR yyyyDoy = start_yd, stop_yd DO BEGIN
      yyyyDoyString = strmid(strtrim(yyyyDoy, 2), 0, 4) + '_' + strmid(strtrim(yyyyDoy, 2), 4, 3)
      dataFile = 'daxss' + '_l0c_' + yyyyDoyString + '.sav'

      IF ~file_test(dataPath + dataFile) THEN CONTINUE

      ; Kill any old variables because we don't want them to persist
      sci = !NULL
      log = !NULL
      dump = !NULL

      restore, dataPath + dataFile
      IF keyword_set(verbose) THEN message, /INFO, "Restoring file " + dataFile
      sciTemp = [sciTemp, sci]
      logTemp = [logTemp, log]
      dumpTemp = [dumpTemp, dump]
    ENDFOR

    ; Transfer concatenated data to normal names
    sci = temporary(sciTemp)
    log = temporary(logTemp)
    dump = temporary(dumpTemp)

    ; Save mission length file
    save, sci, log, dump, FILENAME = dataPath + 'daxss_l0c_all_mission_length.sav', /COMPRESS, description = 'DAXSS Level 0C data ... All ...; FULL MISSION (' + strmid(strtrim(start_yd, 2), 0, 4) + '/' + strmid(strtrim(start_yd, 2), 4, 3) + ' - ' + strmid(strtrim(stop_yd, 2), 0, 4) + '/' + strmid(strtrim(stop_yd, 2), 4, 3) + ') ... FILE GENERATED: ' + JPMsystime()

    ; Export to netCDF
    IF sci NE !NULL THEN BEGIN
      ; minxss_make_netcdf, '0c', fm = fm ; TODO: Update for DAXSS
    ENDIF
  ENDIF ; MAKE_MISSION_LENGTH

END
