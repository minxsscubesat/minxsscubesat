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
;     yyyydoy [long]:       The date in yyyydoy format that you want to process.
;     yyyymmdd [long]:      The date in yyyymmdd format that you want to process.
;	  use_csv_file:			Use IIST data processing Level 0 product (CSV file format, merged)
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
;   3. Write DAXSS data structures to disk as IDL save file
;
; NOTE
;	minxss_make_level0b.pro works for IS-1 DAXSS as MinXSS FM=4
;
; EXAMPLE USAGE
;	IDL> myPath = getenv('minxss_data')+'/fm4/hydra_tlm/flight'
;	IDL> myFiles = file_search( myPath, 'ccsds_*', count=filesCount )
;	IDL> print, 'Number of files found = ', filesCount
;	IDL> daxss_make_level0b, telemetryFileNamesArray=myFiles, /verbose
;
;	IDL> ; restore the daxss_l0b_merged_YYYY_DOY.sav file
;	IDL> daxss_plots_trends, hk
;
; HISTORY
;	2022-02-27	T. Woods, updated for IS-1 paths
;	2022-03-16	T. Woods, updated with use_csv_file option to use IIST processed Level 0 CSV file
;
;+
PRO daxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, $
						yyyymmdd = yyyymmdd, use_csv_file=use_csv_file, _extra = _extra, $
                        VERBOSE = VERBOSE

  ; Set FM to 4
  fm = 4
  flightModelString = 'fm'+strtrim(fm,2)

  ; Input checks
  IF telemetryFileNamesArray EQ !NULL AND yyyydoy EQ !NULL AND yyyymmdd EQ !NULL THEN BEGIN
    ; Assume USE_CSV_FILE as default
    use_csv_file = 1
    ; message, /INFO, 'You specified no inputs. Need to provide one of them.'
    ; message, /INFO, 'USAGE: daxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd'
    ; return
  ENDIF
  if keyword_set(use_csv_file) then begin
  	  ; First Make Level 0A file using IIST processed Level 0 files
  	  ;	This only can be done on DAXSS Science Data Processing computer (due to GoogleDrive paths)
  	  spawn, 'hostname', hostname_output
  	  hostname = strupcase(hostname_output[n_elements(hostname_output)-1])
  	  if (hostname eq 'MACD3750') then begin
  	  	; run daxss_make_level0a.pro
  	  	daxss_make_level0a, verbose=VERBOSE
  	  endif else begin
  	  	message, /INFO, 'WARNING: DAXSS Level 0a file was not re-made !'
  	  endelse
  	  merged = 1
  	  path_L0A = getenv('minxss_data')+path_sep()+flightModelString+path_sep()+'csv_files'+path_sep()
  	  telemetryFileNamesArray = [ path_L0A + 'daxss_l0a_csv_merged.bin' ]
  	  numfiles = ( file_test(telemetryFileNamesArray[0]) ? 1 : 0)
  endif else begin
	  IF telemetryFileNamesArray NE !NULL THEN BEGIN
		numfiles = n_elements(telemetryFileNamesArray)
		merged = 1
	  ENDIF ELSE merged = 0
	  IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)
	  IF yyyydoy NE !NULL THEN telemetryFileNamesArray = daxss_find_tlm_files(yyyydoy, numfiles=numfiles, verbose=verbose)
  endelse
  IF numfiles LT 1 THEN BEGIN
	message, /INFO, 'No files found for specified input.'
	return
  ENDIF

  ; Loop through each telemetry file
  hk_count = 0L
  FOR i = 0, n_elements(telemetryFileNamesArray) - 1 DO BEGIN
    filename = telemetryFileNamesArray[i]
    parsedFilename = ParsePathAndFilename(filename)
    if not parsedFilename.absolute then filename = getenv('isis_data') + filename

    IF keyword_set(verbose) THEN BEGIN
      message, /INFO, 'Reading telemetry file ' + JPMPrintNumber(i + 1) + '/' + $
        JPMPrintNumber(n_elements(telemetryFileNamesArray)) + ': ' +  parsedFilename.Filename
    ENDIF

	; IS1/DAXSS processing has its own reader code
  	;		use "diag" packets for the "dump" packets for FM4 so compatible with FM 1&2 code
    is1_daxss_beacon_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, dump=dumpTmp, $
    	p1sci=p1sciTmp, verbose=verbose, _extra=_extra

	; Count number of HK packets
  	IF hkTmp NE !NULL then hk_count += n_elements(hkTmp)

    ; Continue loop if no data in telemetry file
    IF hkTmp EQ !NULL AND sciTmp EQ !NULL AND p1sciTmp EQ !NULL AND logTmp EQ !NULL AND dumpTmp EQ !NULL THEN CONTINUE

    ;
    ; 1. Task 1: Concatenate data for all telemetry files.
    ;

    ; If the flight model is the desired one, save data
    IF hkTmp NE !NULL AND hk EQ !NULL THEN hk = hkTmp $
    ELSE IF hkTmp NE !NULL AND hk NE !NULL THEN hk = [hk, hkTmp]

    IF sciTmp NE !NULL AND sci EQ !NULL THEN sci = sciTmp $
    ELSE IF sciTmp NE !NULL AND sci NE !NULL THEN sci = [sci, sciTmp]

    IF p1sciTmp NE !NULL AND p1sci EQ !NULL THEN p1sci = p1sciTmp $
    ELSE IF p1sciTmp NE !NULL AND p1sci NE !NULL THEN p1sci = [p1sci, p1sciTmp]

    IF logTmp NE !NULL AND log EQ !NULL THEN log = logTmp $
    ELSE IF logTmp NE !NULL AND log NE !NULL THEN log = [log, logTmp]

    IF dumpTmp NE !NULL AND dump EQ !NULL THEN dump = dumpTmp $
    ELSE IF dumpTmp NE !NULL AND dump NE !NULL THEN dump = [dump, dumpTmp]
  ENDFOR ; loop through telemetry files

  ;
  ; 2. Task 2: Now that all data has been concatenated, sort it by time.
  ;
  IF hk NE !NULL THEN BEGIN
		minxss_sort_telemetry, hk, fm=fm, verbose=verbose, _extra=_extra
		hk_count_sort = n_elements(hk)
		if keyword_set(VERBOSE) then message, /INFO, $
			'HK total = '+strtrim(hk_count,2)+', HK sorted = '+strtrim(hk_count_sort,2)
  ENDIF

  IF sci NE !NULL THEN BEGIN
  		minxss_sort_telemetry, sci, fm=fm, verbose=verbose, _extra=_extra
  		if keyword_set(VERBOSE) then message, /INFO, $
			'SCI sorted = '+strtrim(n_elements(sci),2)
  ENDIF
  IF log NE !NULL THEN minxss_sort_telemetry, log, fm=fm, verbose=verbose, _extra=_extra
  IF dump NE !NULL THEN minxss_sort_telemetry, dump, fm=fm, verbose=verbose, _extra=_extra
  IF p1sci NE !NULL THEN minxss_sort_telemetry, p1sci, fm=fm, verbose=verbose, _extra=_extra

  ; If no YYYYDOY, grab one from the HK packet
  IF yyyydoy EQ !NULL THEN BEGIN
      filenameParsed = ParsePathAndFilename(filename)
	  ; ypos = strpos( filenameParsed.filename, '_' ) + 1
	  ; yyyy = strmid(filenameParsed.filename, ypos, 4)
	  ; doy = strmid(filenameParsed.filename, ypos+5, 3)
	  ; yyyydoy = yyyy + doy  ; strings
	  jdmax = gps2jd(max(hk.daxss_time))
	  yyyydoy = long(jd2yd(jdmax))
  ENDIF
  yyyydoy = strtrim(yyyydoy, 2)

  ;
  ; 3. Write DAXSS data structures to disk as IDL save file
  ;
  if (merged ne 0) then fileBase = 'daxss_l0b_merged_' else fileBase = 'daxss_l0b_'
  outputFilename = fileBase + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3)
  fullFilename = getenv('minxss_data') + path_sep() + flightModelString + path_sep() + 'level0b' $
		+ path_sep() + outputFilename + '.sav'

  IF keyword_set(verbose) THEN message, /INFO, 'Saving DAXSS sorted packets into ' + fullFilename
  file_description = 'DAXSS Level 0B data ' + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + $
        strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+ JPMsystime()
  save, hk, sci, p1sci, log, dump, FILENAME = fullFilename, /COMPRESS, description = file_description

  ; if keyword_set(verbose) then stop, 'DEBUG at end of daxss_make_level0b...'
END
