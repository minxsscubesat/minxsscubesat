;+
; NAME:
;   minxss_make_level0b.pro
;
; PURPOSE:
;   Accepts any list of telemetry files, reads the stored data, sorts the packets in time, stitches them together and saves them
;   in the standard MinXSS data structures (i.e. housekeeping, science, ADCS, log, diagnostic, and XACT image). Intended for use
;   to create daily files, and as such saves as an IDL save set with a yyyy_doy name.
;
; CATEGORY:
;    MinXSS Level 0B
;
; CALLING SEQUENCE:
;   minxss_make_level0b, telemetryFileNamesArray
;
; INPUTS:
;   Must provide one of the optional inputs. They aren't listed as regular inputs because any one isn't more "required" than the other.
;
; OPTIONAL INPUTS:
;   FM [int]: Flight model designation; defaults to 1.
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
;   Requires MinXSS processing suite.
;
; PROCEDURE:
;   1. Task 1: Concatenate data for all telemetry files.
;   2. Task 2: Now that all data has been concatenated, sort it by time.
;   3. Write MinXSS data structures to disk as IDL save file
;
; EXAMPLE USAGE
;	IDL> myPath = getenv('minxss_data')+'/fm3/hydra_tlm/flight'
;	IDL> myFiles = file_search( myPath, 'ccsds_*', count=filesCount )
;	IDL> print, 'Number of files found = ', filesCount
;	IDL> minxss_make_level0b, telemetryFileNamesArray=myFiles, fm=3, /verbose
;
; HISTORY
;	2016 		Original code for MinXSS-1
;	2022-02-18	Update for IS-1 DAXSS (FM3) (*** but really need to use daxss_make_level0b.pro ***)
;
;+
PRO minxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, $
						yyyymmdd = yyyymmdd, fm = fm, _extra = _extra, $
                         VERBOSE = VERBOSE

; TODO: implement date limit checking to prevent accidental ingestion of lab data outside of mission operation times

; Input checks
IF telemetryFileNamesArray EQ !NULL AND yyyydoy EQ !NULL AND yyyymmdd EQ !NULL THEN BEGIN
  message, /INFO, 'You specified no inputs. Need to provide one of them.'
  message, /INFO, 'USAGE: minxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, FM = FM'
  return
ENDIF
IF fm EQ !NULL THEN BEGIN
  fm = 2
ENDIF
IF isa(fm, /STRING) THEN BEGIN
  fm = fix(fm)
ENDIF
IF keyword_set(verbose) THEN message, /INFO, "Using flight model FM = " + strtrim(FM, 2)
IF telemetryFileNamesArray NE !NULL THEN BEGIN
	numfiles = n_elements(telemetryFileNamesArray)
	merged = 1
ENDIF ELSE merged = 0
IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)
IF yyyydoy NE !NULL THEN telemetryFileNamesArray = minxss_find_tlm_files(yyyydoy, fm=fm, numfiles=numfiles, verbose=verbose)
IF numfiles LT 1 THEN BEGIN
  message, /INFO, 'No files found for specified input.'
  return
ENDIF

; Loop through each telemetry file
hk_count = 0L
FOR i = 0, n_elements(telemetryFileNamesArray) - 1 DO BEGIN
  filename = telemetryFileNamesArray[i]
  parsedFilename = ParsePathAndFilename(filename)
  if not parsedFilename.absolute then filename = getenv('isis_data')+filename

  IF keyword_set(verbose) THEN BEGIN
    message, /INFO, 'Reading telemetry file ' + JPMPrintNumber(i + 1) + '/' + $
                    JPMPrintNumber(n_elements(telemetryFileNamesArray)) + ': ' +  parsedFilename.Filename
  ENDIF

  if (fm eq 1) then begin
    minxss_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, diag=diagTmp, xactImage=imageTmp, $
    					   /EXPORT_RAW_ADCS_TLM, $
  		                   adcs1=adcs1Tmp, adcs2=adcs2Tmp, adcs3=adcs3Tmp, adcs4=adcs4Tmp, fm=fmTmp, $
  		                   verbose=verbose, _extra=_extra

  endif else if (fm eq 2) then begin
    minxss2_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, diag=diagTmp, xactImage=imageTmp, $
    					  /EXPORT_RAW_ADCS_TLM, $
                          adcs1=adcs1Tmp, adcs2=adcs2Tmp, adcs3=adcs3Tmp, adcs4=adcs4Tmp, fm=fmTmp, $
                          verbose=verbose, _extra=_extra

  endif else if (fm eq 3) then begin
  	; IS1/DAXSS processing has its own reader code
  	;		use "diag" packets for the "dump" packets for FM3 so compatible with FM 1&2 code
    is1_daxss_beacon_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, dump=diagTmp, $
    	verbose=verbose, _extra=_extra
    fmTmp = 3
  endif

  ; Count number of HK packets
  IF hkTmp NE !NULL then hk_count += n_elements(hkTmp)

  ; Continue loop if no data in telemetry file
  IF hkTmp EQ !NULL AND sciTmp EQ !NULL AND logTmp EQ !NULL AND diagTmp EQ !NULL AND imageTmp EQ !NULL AND adcs1Tmp EQ !NULL AND adcs2Tmp EQ !NULL AND $
     adcs3Tmp EQ !NULL AND adcs4Tmp EQ !NULL AND fmTmp EQ !NULL THEN CONTINUE

  ; fm is the user specified input, fmTmp is what minxss(2)_read_packets found in the telemetry
  IF fm NE fmTmp AND hkTmp NE !NULL THEN BEGIN
    IF keyword_set(verbose) THEN BEGIN
      message, /INFO, JPMsystime() + ' Flight model in telemetry (' + strtrim(fmTmp,2) + ') does not match user specification (' + strtrim(fm,2) + '). This is likely due to erroneous flight software firmware burns. Overwriting with user specification.'
    ENDIF
    fmTmp = fm
    hkTmp.flight_model = fm
  ENDIF

  ;
  ; 1. Task 1: Concatenate data for all telemetry files.
  ;

  ; If the flight model is the desired one, save data
  IF (fmTmp eq FM) THEN BEGIN
    IF hkTmp NE !NULL AND hk EQ !NULL THEN hk = hkTmp $
    ELSE IF hkTmp NE !NULL AND hk NE !NULL THEN hk = [hk, hkTmp]

    IF sciTmp NE !NULL AND sci EQ !NULL THEN sci = sciTmp $
    ELSE IF sciTmp NE !NULL AND sci NE !NULL THEN sci = [sci, sciTmp]

    IF logTmp NE !NULL AND log EQ !NULL THEN log = logTmp $
    ELSE IF logTmp NE !NULL AND log NE !NULL THEN log = [log, logTmp]

    IF diagTmp NE !NULL AND diag EQ !NULL THEN diag = diagTmp $
    ELSE IF diagTmp NE !NULL AND diag NE !NULL THEN diag = [diag, diagTmp]

    IF imageTmp NE !NULL AND image EQ !NULL THEN image = imageTmp $
    ELSE IF imageTmp NE !NULL AND image NE !NULL THEN image = [image, imageTmp]

    IF adcs1Tmp NE !NULL AND adcs1 EQ !NULL THEN adcs1 = adcs1Tmp $
    ELSE IF adcs1Tmp NE !NULL AND adcs1 NE !NULL THEN adcs1 = [adcs1, adcs1Tmp]

    IF adcs2Tmp NE !NULL AND adcs2 EQ !NULL THEN adcs2 = adcs2Tmp $
    ELSE IF adcs2Tmp NE !NULL AND adcs2 NE !NULL THEN adcs2 = [adcs2, adcs2Tmp]

    IF adcs3Tmp NE !NULL AND adcs3 EQ !NULL THEN adcs3 = adcs3Tmp $
    ELSE IF adcs3Tmp NE !NULL AND adcs3 NE !NULL THEN adcs3 = [adcs3, adcs3Tmp]

    IF adcs4Tmp NE !NULL AND adcs4 EQ !NULL THEN adcs4 = adcs4Tmp $
    ELSE IF adcs4Tmp NE !NULL AND adcs4 NE !NULL THEN adcs4 = [adcs4, adcs4Tmp]
  ENDIF ELSE BEGIN
    ; If flight model is not correct (and/or not found AND not forced), then ignore it...
    IF keyword_set(verbose) THEN message, /INFO, "Incorrect flight model (FM = " + strtrim(fmTmp, 2) + ") in file " + parsedFilename.filename + " ... IGNORING!"
  ENDELSE
ENDFOR

;
; 2. Task 2: Now that all data has been concatenated, sort it by time.
;
IF hk NE !NULL THEN BEGIN
	minxss_sort_telemetry, hk, fm=fm, verbose=verbose, _extra=_extra
	hk_count_sort = n_elements(hk)
	if keyword_set(VERBOSE) then message, /INFO, $
		'HK total = '+strtrim(hk_count,2)+', HK sorted = '+strtrim(hk_count_sort,2)
ENDIF
IF sci NE !NULL THEN minxss_sort_telemetry, sci, fm=fm, verbose=verbose, _extra=_extra
IF log NE !NULL THEN minxss_sort_telemetry, log, fm=fm, verbose=verbose, _extra=_extra
IF diag NE !NULL THEN minxss_sort_telemetry, diag, fm=fm, verbose=verbose, _extra=_extra
IF image NE !NULL THEN minxss_sort_telemetry, image, fm=fm, verbose=verbose, _extra=_extra
IF adcs1 NE !NULL THEN minxss_sort_telemetry, adcs1, fm=fm, verbose=verbose, _extra=_extra
IF adcs2 NE !NULL THEN minxss_sort_telemetry, adcs2, fm=fm, verbose=verbose, _extra=_extra
IF adcs3 NE !NULL THEN minxss_sort_telemetry, adcs3, fm=fm, verbose=verbose, _extra=_extra
IF adcs4 NE !NULL THEN minxss_sort_telemetry, adcs4, fm=fm, verbose=verbose, _extra=_extra

; If no YYYYDOY, grab one from the HK packet
; TODO: Make this more robust if someone uses a random filename
IF yyyydoy EQ !NULL THEN BEGIN
  filenameParsed = ParsePathAndFilename(filename)
  ypos = strpos( filenameParsed.filename, '_' ) + 1
  yyyy = strmid(filenameParsed.filename, ypos, 4)
  doy = strmid(filenameParsed.filename, ypos+5, 3)
  yyyydoy = yyyy + doy
ENDIF ELSE yyyydoy = strtrim(yyyydoy,2)

;
; 3. Write MinXSS data structures to disk as IDL save file
;

; Figure out the directory name to make
; Changed FS3 to FS0  as FM4 (IS1-DAXSS) changed to FM3, 5/24/2022, TW
IF FM EQ 0 THEN BEGIN
  flightModelString = 'fs' + strtrim(fm, 2)
ENDIF ELSE BEGIN
  flightModelString = 'fm' + strtrim(fm, 2)
ENDELSE
if (merged ne 0) then fileBase = 'minxss_l0b_merged_' else fileBase = 'minxss_l0b_'
outputFilename = fileBase + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3)
fullFilename = getenv('minxss_data') + '/' + flightModelString + '/level0b/' + outputFilename + '.sav'

IF keyword_set(verbose) THEN message, /INFO, 'Saving MinXSS sorted packets into '+fullFilename
if (fm ne 3) then begin
	save, hk, sci, log, adcs1, adcs2, adcs3, adcs4, diag, image, $
		FILENAME = fullFilename, /compress, $
      description = 'MinXSS Level 0B data ... FM = ' + strtrim(fm,2) + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+systime()
endif else begin
	; change "diag" to "dump" for FM4
	IF diag NE !NULL then dump = diag else dump = !NULL
	save, hk, sci, log, dump, FILENAME = fullFilename, /compress, $
      description = 'IS-1 DAXSS Level 0B data ... FM = ' + strtrim(fm,2) + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+systime()
ENDELSE

RETURN
END
