;+
; NAME:
;   daxss_make_level0c.pro
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
;   version [string]: Software/data product version to store in filename and internal anonymous structure.
;					Default is '1.0.0'.
;
;   You MUST specifiy one and only one of these inputs:
;
;     telemetryFileNamesArray [strarr]: A string array containing the paths/filenames of the
;									telemetry files to be sorted and stitched.
;     yyyydoy [long]:       The date in yyyydoy format that you want to process.
;     yyyymmdd [long]:      The date in yyyymmdd format that you want to process.
;	  use_csv_file:			Use IIST data processing Level 0 product (CSV file format, merged)
;	  merged_raw:    		Option to use 2024 merged Level 0 packet file instead of daily-produced files
;								This is used with the use_csv_file option.
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print out processing messages while running.
;   DEBUG: Set this to stop at end of processing.
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
;	minxss_make_level0c.pro works for IS-1 DAXSS as MinXSS FM=3
;
; EXAMPLE USAGE
;	IDL> myPath = getenv('minxss_data')+'/fm3/hydra_tlm/flight'
;	IDL> myFiles = file_search( myPath, 'ccsds_*', count=filesCount )
;	IDL> print, 'Number of files found = ', filesCount
;	IDL> daxss_make_level0c, telemetryFileNamesArray=myFiles, /verbose
;
;	IDL> ; restore the daxss_l0c_merged_YYYY_DOY_v1.0.0.sav file
;	IDL> daxss_plots_trends, hk
;
; HISTORY
;	2022-02-27	T. Woods, updated for IS-1 paths
;	2022-03-16	T. Woods, updated with use_csv_file option to use IIST processed Level 0 CSV file
;	2022-10-05  T. Woods, updated with including ADCS_CSS packets into DAXSS L0C files
;	2023-02-18  T. Woods, updated with including SD_HK packets into DAXSS L0C files
;	2023-10-06	T. Woods, updated to use Aug-28-2023 IS-1 Level 0 CSV file to recover the missing data
;					(issue is that daxss_sci_level_0.csv dropped from 307MB to 114MB on Aug-29-2023)
;					(this update is actually in daxss_make_level0b.pro)
;	2024-02-02	T. Woods, added /merged_raw option to use the Indian new merged Level 0 packet file
;
;+
PRO daxss_make_level0c, telemetryFileNamesArray = telemetryFileNamesArray, $
					merged_raw=merged_raw, yyyydoy = yyyydoy, $
					yyyymmdd = yyyymmdd, use_csv_file=use_csv_file, version=version, $
                    VERBOSE=VERBOSE, DEBUG=DEBUG, extra = _extra

  ; Defaults
  fm = 3	; changed from FM4 to FM3 on 5/24/2022, TW
  flightModelString = 'fm'+strtrim(fm,2)
  IF version EQ !NULL THEN version = '1.0.0'
  IF keyword_set(DEBUG) then VERBOSE = 1

  ; This offset was discovered when comparing DAXSS data to GOES peaks and rising edges
  ;     time_offset_sec = -250.D0
  ; Updated TIME_OFFSET_SEC based on GOES comparison to flare edges: 6/16/2022  T. Woods
  ;       No time drift was noted but accuracy for this offset is only about 2 seconds
  time_offset_sec = -201.D0

  ; Input checks
  IF telemetryFileNamesArray EQ !NULL AND yyyydoy EQ !NULL AND yyyymmdd EQ !NULL THEN BEGIN
    ; Assume USE_CSV_FILE as default
    use_csv_file = 1
    ; message, /INFO, 'You specified no inputs. Need to provide one of them.'
    ; message, /INFO, 'USAGE: daxss_make_level0c, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd'
    ; return
  ENDIF
  if keyword_set(use_csv_file) then begin
  	  ; First Make Level 0b file using IIST processed Level 0 files
  	  ;	This only can be done on DAXSS Science Data Processing computer (due to GoogleDrive paths)
  	  spawn, 'hostname', hostname_output
  	  hostname = strupcase(hostname_output[n_elements(hostname_output)-1])
  	  if (hostname eq 'MACD3750') then begin
  	  	; run daxss_make_level0b.pro
  	  	daxss_make_level0b, verbose=VERBOSE, merged_raw=merged_raw
  	  	;;; if keyword_set(verbose) then stop, 'STOPPED: DEBUG DAXSS Level 0B file...'
  	  endif else begin
  	  	message, /INFO, 'WARNING: DAXSS Level 0b file was not re-made !'
  	  endelse
  	  merged = 1
  	  path_L0b = getenv('minxss_data')+path_sep()+flightModelString+path_sep()+'level0b'+path_sep()
  	  telemetryFileNamesArray = [ path_L0b + 'daxss_l0b_csv_merged.bin' ]
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
  	;		use "diag" packets for the "dump" packets for FM3 so compatible with FM 1&2 code
  	; NEW 5/11/2022:  add DIR_LOG option to log the SCI packet issues
  	; NEW 10/5/2022:  add ADCS_CSS packets
  	; NEW 2/18/2023:  add SD_HK packets
  	if keyword_set(verbose) then DIR_LOG = getenv('minxss_data') + path_sep() + $
  			flightModelString + path_sep() + 'log' + path_sep() + 'daxss_read' + path_sep()
    is1_daxss_beacon_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, dump=dumpTmp, $
    	css=cssTmp, sd=sdTmp, p1sci=p1sciTmp, p2sci=p2sciTmp, verbose=verbose, $
    	dir_log=DIR_LOG, _extra=_extra

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

    IF p2sciTmp NE !NULL AND p2sci EQ !NULL THEN p2sci = p2sciTmp $
    ELSE IF p2sciTmp NE !NULL AND p2sci NE !NULL THEN p2sci = [p2sci, p2sciTmp]

    IF logTmp NE !NULL AND log EQ !NULL THEN log = logTmp $
    ELSE IF logTmp NE !NULL AND log NE !NULL THEN log = [log, logTmp]

    IF dumpTmp NE !NULL AND dump EQ !NULL THEN dump = dumpTmp $
    ELSE IF dumpTmp NE !NULL AND dump NE !NULL THEN dump = [dump, dumpTmp]

	; NEW 10/5/2022: CSS packets
    IF cssTmp NE !NULL AND css EQ !NULL THEN css = cssTmp $
    ELSE IF cssTmp NE !NULL AND css NE !NULL THEN css = [css, cssTmp]

	; NEW 2/18/2023: SD packets
    IF sdTmp NE !NULL AND sd EQ !NULL THEN sd = sdTmp $
    ELSE IF sdTmp NE !NULL AND sd NE !NULL THEN sd = [sd, sdTmp]

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

  ; Don't SORT CSS packets as  "time" is just seconds since Reset
  ; IF css NE !NULL THEN minxss_sort_telemetry, css, fm=fm, verbose=verbose, _extra=_extra

  ; Don't SORT SD packets as  "time" is just seconds since Reset
  ; IF sd NE !NULL THEN minxss_sort_telemetry, sd, fm=fm, verbose=verbose, _extra=_extra

  ; 2022-04-22 T. Woods:  don't sort p1sci and p2sci packets as only using them to debug the SCI packet extraction issues
  ;  Allow same time values in the p1sci packets, so use the /no_unique option
  ; IF p1sci NE !NULL THEN minxss_sort_telemetry, p1sci, fm=fm, verbose=verbose, /no_unique, _extra=_extra
  ; IF p2sci NE !NULL THEN minxss_sort_telemetry, p2sci, fm=fm, verbose=verbose, /no_unique, _extra=_extra

  ; Handle time offset in data
  hk = JPMAddTagsToStructure(hk, 'time_gps', 'double')
  hk = JPMAddTagsToStructure(hk, 'time_jd', 'double')
  hk = JPMAddTagsToStructure(hk, 'time_iso', 'string')
  hk = JPMAddTagsToStructure(hk, 'time_human', 'string')
  sci = JPMAddTagsToStructure(sci, 'time_jd', 'double')
  sci = JPMAddTagsToStructure(sci, 'time_gps', 'double')
  sci = JPMAddTagsToStructure(sci, 'time_iso', 'string')
  sci = JPMAddTagsToStructure(sci, 'time_human', 'string')

  ; stop, 'DEBUG hk.time and time_offset_sec...'
  hk.time_gps = hk.time + time_offset_sec
  hk.time_jd = gps2jd(hk.time_gps)
  hk.time_iso = jpmjd2iso(hk.time_jd)
  hk.time_human = jpmjd2iso(hk.time_jd, /NO_T_OR_Z)
  sci.time_gps = sci.time + time_offset_sec
  sci.time_jd = gps2jd(sci.time_gps)
  sci.time_iso = jpmjd2iso(sci.time_jd)
  sci.time_human = jpmjd2iso(sci.time_jd, /NO_T_OR_Z)

  IF dump NE !NULL THEN BEGIN
    dump = JPMAddTagsToStructure(dump, 'time_gps', 'double')
    dump = JPMAddTagsToStructure(dump, 'time_jd', 'double')
    dump = JPMAddTagsToStructure(dump, 'time_iso', 'string')
    dump = JPMAddTagsToStructure(dump, 'time_human', 'string')
    dump.time_gps = dump.time + time_offset_sec
    dump.time_jd = gps2jd(dump.time_gps)
    dump.time_iso = jpmjd2iso(dump.time_jd)
    dump.time_human = jpmjd2iso(dump.time_jd, /NO_T_OR_Z)
  ENDIF

  ; Don't add more Time Variables to CSS packet
  ; Because CSS packets "time" is just seconds since Reset
  ;IF css NE !NULL THEN BEGIN
  ;  css = JPMAddTagsToStructure(css, 'time_gps', 'double')
  ;  css = JPMAddTagsToStructure(css, 'time_jd', 'double')
  ;  css = JPMAddTagsToStructure(css, 'time_iso', 'string')
  ;  css = JPMAddTagsToStructure(css, 'time_human', 'string')
  ;  css.time_gps = css.time + time_offset_sec
  ;  css.time_jd = gps2jd(css.time_gps)
  ;  css.time_iso = jpmjd2iso(css.time_jd)
  ;  css.time_human = jpmjd2iso(css.time_jd, /NO_T_OR_Z)
  ;ENDIF

  ; Don't add more Time Variables to SD packet
  ; Because SD packets "time" is just seconds since Reset

  ; If no YYYYDOY, grab one from the HK packet
  IF yyyydoy EQ !NULL THEN BEGIN
	  jdmax = gps2jd(max(hk.daxss_time)) < systime(/julian)
	  yyyydoy = long(jd2yd(jdmax))
  ENDIF
  yyyydoy = strtrim(yyyydoy, 2)

  ;
  ; 3. Write DAXSS data structures to disk as IDL save file and netcdf
  ;
  if keyword_set(use_csv_file) then begin
  	outputFilename = 'daxss_l0c_all_mission_length_v' + version
  endif else if (merged ne 0) then begin
  	outputFilename = 'daxss_l0c_merged_' + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3) + '_v'+version
  endif else begin
  	outputFilename = 'daxss_l0c_' + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3) + '_v'+version
  endelse

  fullFilename = getenv('minxss_data') + path_sep() + flightModelString + path_sep() + 'level0c' $
		+ path_sep() + outputFilename + '.sav'

  IF keyword_set(verbose) THEN message, /INFO, 'Saving DAXSS sorted packets into ' + fullFilename
  file_description = 'DAXSS Level 0c data ' + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + $
        strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+ JPMsystime()
  save, hk, sci, p1sci, p2sci, log, dump, css, sd, FILENAME = fullFilename, /COMPRESS, description = file_description

  daxss_make_netcdf, '0c', version=version, verbose=verbose

  if keyword_set(DEBUG) then stop, 'DEBUG at end of daxss_make_level0c...'
END
