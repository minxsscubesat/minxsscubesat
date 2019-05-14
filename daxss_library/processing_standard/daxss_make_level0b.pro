;+
; NAME:
;   daxss_make_level0b.pro
;
; PURPOSE:
;   Reads multiple the stored data files, sorts the data in those files by time, stitches them together and saves them
;   in the standard DAXSS data structures based on MinXSS (i.e. science, log, and dump). Intended for use
;   to create daily files, and as such saves as an IDL save set with a yyyy_doy name.
;
; INPUTS:
;   Must provide one of the optional inputs. They aren't listed as regular inputs because any one isn't more "required" than the other.
;
; OPTIONAL INPUTS:
;   You MUST specifiy one and only one of these inputs:
;     telemetryFileNamesArray [strarr]: A string array containing the paths/filenames of the telemetry files to be sorted and stitched.
;     yyyydoy [long]:                   The date in yyyydoy format that you want to process.
;     yyyymmdd [long]:                  The date in yyyymmdd format that you want to process.
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print out processing messages while running.
;
; OUTPUTS:
;   None.
;
; OPTIONAL OUTPUTS:
;   None.
;
; COMMON BLOCKS:
;   None.
;
; RESTRICTIONS:
;   Requires DAXSS processing suite.
;
; PROCEDURE:
;   1. Task 1: Concatenate data for all telemetry files.
;   2. Task 2: Now that all data has been concatenated, sort it by time.
;   3. Write MinXSS data structures to disk as IDL save file
;
;+
PRO daxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, _extra = _extra, $
                        VERBOSE = VERBOSE

  ; Input checks
  IF telemetryFileNamesArray EQ !NULL AND yyyydoy EQ !NULL AND yyyymmdd EQ !NULL THEN BEGIN
    message, /INFO, 'You specified no inputs. Need to provide one of them.'
    message, /INFO, 'USAGE: daxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd'
    return
  ENDIF
  IF telemetryFileNamesArray NE !NULL THEN numfiles = n_elements(telemetryFileNamesArray)
  IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)
  IF yyyydoy NE !NULL THEN telemetryFileNamesArray = daxss_find_tlm_files(yyyydoy, numfiles=numfiles, verbose=verbose)
  IF numfiles LT 1 THEN BEGIN
    message, /INFO, 'No files found for specified input.'
    return
  ENDIF

  ; Loop through each telemetry file
  FOR i = 0, n_elements(telemetryFileNamesArray) - 1 DO BEGIN
    filename = telemetryFileNamesArray[i]
    parsedFilename = ParsePathAndFilename(filename)
    if not parsedFilename.absolute then filename = getenv('isis_data') + filename

    IF keyword_set(verbose) THEN BEGIN
      message, /INFO, 'Reading telemetry file ' + JPMPrintNumber(i + 1) + '/' + $
        JPMPrintNumber(n_elements(telemetryFileNamesArray)) + ': ' +  parsedFilename.Filename
    ENDIF

    daxss_read_packets, filename, sci=sciTmp, log=logTmp, dump=dumpTmp, VERBOSE=VERBOSE

    ; Continue loop if no data in telemetry file
    IF sciTmp EQ !NULL AND logTmp EQ !NULL AND dumpTmp EQ !NULL THEN CONTINUE

    ;
    ; 1. Task 1: Concatenate data for all telemetry files.
    ;

    ; If the flight model is the desired one, save data
    IF sciTmp NE !NULL AND sci EQ !NULL THEN sci = sciTmp $
    ELSE IF sciTmp NE !NULL AND sci NE !NULL THEN sci = [sci, sciTmp]

    IF logTmp NE !NULL AND log EQ !NULL THEN log = logTmp $
    ELSE IF logTmp NE !NULL AND log NE !NULL THEN log = [log, logTmp]

    IF dumpTmp NE !NULL AND dump EQ !NULL THEN dump = dumpTmp $
    ELSE IF dumpTmp NE !NULL AND dump NE !NULL THEN dump = [dump, dumpTmp]
  ENDFOR ; loop through telemetry files

  ;
  ; 2. Task 2: Now that all data has been concatenated, sort it by time.
  ;
  
  IF sci NE !NULL THEN minxss_sort_telemetry, sci, fm=fm, verbose=verbose, _extra=_extra
  IF log NE !NULL THEN minxss_sort_telemetry, log, fm=fm, verbose=verbose, _extra=_extra
  IF dump NE !NULL THEN minxss_sort_telemetry, dump, fm=fm, verbose=verbose, _extra=_extra

  ; If no YYYYDOY, grab one from the HK packet
  ; TODO: Make this more robust if someone uses a random filename
  IF yyyydoy EQ !NULL THEN BEGIN
    filenameParsed = ParsePathAndFilename(filename)
    yyyy = strmid(filenameParsed.filename, 12, 4)
    doy = strmid(filenameParsed.filename, 17, 3)
    yyyydoy = yyyy + doy
  ENDIF ELSE yyyydoy = strtrim(yyyydoy, 2)

  ;
  ; 3. Write DAXSS data structures to disk as IDL save file
  ;

  ; Figure out the directory name to make
  outputFilename = 'daxss_l0b_' + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3)
  fullFilename = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() + 'level0b' + path_sep() + outputFilename + '.sav'

  IF keyword_set(verbose) THEN message, /INFO, 'Saving MinXSS sorted packets into ' + fullFilename
  save, sci, log, dump, FILENAME = fullFilename, /COMPRESS, $
        description = 'DAXSS Level 0B data ' + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+ JPMsystime()

END
