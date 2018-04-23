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
;   Must provide one of the optional inputs. They aren't listed as regular inputs because any one isn't more "required"
;   than the other. 
;
; OPTIONAL INPUTS:
;   telemetryFileNamesArray [strarr]: A string array containing the paths/filenames of the telemetry files to be sorted and stitched.
;   yyyydoy [long]:                   The date in yyyydoy format that you want to process. 
;   yyyymmdd [long]:                  The date in yyyymmdd format that you want to process. 
;   FM [int]:                         Flight model designation; defaults to 1
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print out processing messages while running
;
; OUTPUTS:
;   None
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires minxss_read_packets.pro
;   Requires minxss_sort_telemetry.pro
;   Requires JPMPrintNumber.pro
;   Requires ParsePathAndFilename.pro
;
; PROCEDURE:
;   1. Task 1: Concatenate data for all telemetry files.
;   2. Task 2: Now that all data has been concatenated, sort it by time.
;   3. Write MinXSS data structures to disk as IDL save file
;
; MODIFICATION HISTORY:
;   2015-01-26: James Paul Mason: Wrote script.
;	  2015-01-31: Tom Woods: Updated for 4 different ADCS packets from minxss_read_packets.pro
;					                 and added option for passing YYYYDOY instead of file names
;   2015-04-13: James Paul Mason: Edited formatting for consistency and removed a STOP that was commented out anyway
;   2015-10-23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;   2016-03-25: James Paul Mason: Updated this header and changed telemetryFileNamesArray to an optional input
;                                 to make it clear that either it or yyyydoy or the also newly added yyyymmdd can be specified. 
;                                 Also got rid of KEYWORD call to minxss_read_packets EXPORT_RAW_ADCS_TLM since BCT can now read
;                                 raw ISIS telemetry themselves. 
;   2016-05-16: Amir Caspi: Updated to check for absolute file paths, added FM input (default = 1), added 2017 support,
;                           optimized and cleaned up code
;   2016-05-22: Amir Caspi: Changed calls to minxss_sort_telemetry to allow for time correction of early commissioning data
;   2016-06-06: Amir Caspi: Added option to force FM for files that don't have it
;   2016-06-22: James Paul Mason: Made the call to minxss_read_packets pass the new EXPORT_RAW_ADCS_TLM keyword by default. 
;   2016-08-21: Tom Woods:  Separated out FM1 and FM2 to call different minxss_read_packets() procedures
;   2016-10-31: James Paul Mason: Handled edge case of telemetry file with no data in it
;+
PRO minxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, $
                         VERBOSE=VERBOSE, FM=FM, forceFM = forceFM, _extra=_extra

; Input checks
IF telemetryFileNamesArray EQ !NULL AND yyyydoy EQ !NULL AND yyyymmdd EQ !NULL THEN BEGIN
  message, /INFO, 'You specified no inputs. Need to provide one of them.'
  message, /INFO, 'USAGE: minxss_make_level0b, telemetryFileNamesArray = telemetryFileNamesArray, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, FM = FM'
  return
ENDIF
IF FM EQ !NULL THEN BEGIN
  message, /INFO, "WARNING: No flight model specified; defaulting to FM = 1"
  FM = 1
ENDIF ELSE FM = fix(FM) ; Use fix() just in case someone passed in a string
IF keyword_set(verbose) THEN message, /INFO, "Using flight model FM = " + strtrim(FM, 2)
IF telemetryFileNamesArray NE !NULL THEN numfiles = n_elements(telemetryFileNamesArray)
IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)
IF yyyydoy NE !NULL THEN telemetryFileNamesArray = minxss_find_tlm_files(yyyydoy, numfiles=numfiles, verbose=verbose)
IF numfiles LT 1 THEN BEGIN
    message, /INFO, 'No files found for specified input.'
    return
ENDIF

; Loop through each telemetry file
FOR i = 0, n_elements(telemetryFileNamesArray) - 1 DO BEGIN
  filename = telemetryFileNamesArray[i]
  parsedFilename = ParsePathAndFilename(filename)
  if not parsedFilename.absolute then filename = getenv('isis_data')+filename
  
  IF keyword_set(verbose) THEN BEGIN
    message, /INFO, 'Reading telemetry file ' + JPMPrintNumber(i + 1) + '/' + $
                    JPMPrintNumber(n_elements(telemetryFileNamesArray)) + ': ' +  parsedFilename.Filename
  ENDIF
  
  if (fm eq 1) then begin
    minxss_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, diag=diagTmp, xactImage=imageTmp, /EXPORT_RAW_ADCS_TLM, $
  		                   adcs1=adcs1Tmp, adcs2=adcs2Tmp, adcs3=adcs3Tmp, adcs4=adcs4Tmp, fm=fmTmp, verbose=verbose, _extra=_extra
  endif else begin
    ; version of code for FM-2
    minxss2_read_packets, filename, hk=hkTmp, sci=sciTmp, log=logTmp, diag=diagTmp, xactImage=imageTmp, /EXPORT_RAW_ADCS_TLM, $
                          adcs1=adcs1Tmp, adcs2=adcs2Tmp, adcs3=adcs3Tmp, adcs4=adcs4Tmp, fm=fmTmp, verbose=verbose, _extra=_extra
  endelse
  
  ; Continue loop if no data in telemetry file
  IF hkTmp EQ !NULL AND sciTmp EQ !NULL AND logTmp EQ !NULL AND diagTmp EQ !NULL AND imageTmp EQ !NULL AND adcs1Tmp EQ !NULL AND adcs2Tmp EQ !NULL AND $
     adcs3Tmp EQ !NULL AND adcs4Tmp EQ !NULL AND fmTmp EQ !NULL THEN CONTINUE
  
  ;
  ; 1. Task 1: Concatenate data for all telemetry files.
  ;
  ; Only do this if flight model is the desired one!
  ; We need this since ISIS doesn't segregate flight models...

  ; Check if a flight model was found in the file, and if not, force it if keyword set
  IF (fmTmp EQ -1) THEN BEGIN
    message, /INFO, "No flight model found in file " + parsedFilename.filename + " ... CHECK THIS FILE MANUALLY!!!"
    IF keyword_set(forceFM) THEN BEGIN
      fmTmp = FM
      message, /info, "*** FORCING flight model (FM = " + strtrim(fmTmp,2) + ") for file " + parsedFilename.filename
    ENDIF
  ENDIF

  ; If the flight model is the desired one, save data
  ; (This will be called if flight model is forced, above)
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
IF hk NE !NULL THEN minxss_sort_telemetry, hk, fm=fm, verbose=verbose, _extra=_extra
IF sci NE !NULL THEN minxss_sort_telemetry, sci, fm=fm, verbose=verbose, _extra=_extra
IF log NE !NULL THEN minxss_sort_telemetry, log, fm=fm, verbose=verbose, _extra=_extra
IF diag NE !NULL THEN minxss_sort_telemetry, diag, fm=fm, verbose=verbose, _extra=_extra
IF image NE !NULL THEN minxss_sort_telemetry, image, fm=fm, verbose=verbose, _extra=_extra
IF adcs1 NE !NULL THEN minxss_sort_telemetry, adcs1, fm=fm, verbose=verbose, _extra=_extra
IF adcs2 NE !NULL THEN minxss_sort_telemetry, adcs2, fm=fm, verbose=verbose, _extra=_extra
IF adcs3 NE !NULL THEN minxss_sort_telemetry, adcs3, fm=fm, verbose=verbose, _extra=_extra
IF adcs4 NE !NULL THEN minxss_sort_telemetry, adcs4, fm=fm, verbose=verbose, _extra=_extra

; If no YYYYDOY, grab one from the HK packet
filenameParsed = ParsePathAndFilename(filename)
yyyy = strmid(filenameParsed.filename, 12, 4)
doy = strmid(filenameParsed.filename, 17, 3)
yyyydoy = yyyy + doy

;
; 3. Write MinXSS data structures to disk as IDL save file
;

; Figure out the directory name to make
;flightModelString = 'fm' + strtrim(hk[0].flight_model, 2)
flightModelString = 'fm' + strtrim(FM, 2)
outputFilename = 'minxss_l0b_' + strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3)
fullFilename = getenv('minxss_data') + '/' + flightModelString + '/level0b/' + outputFilename + '.sav'

IF keyword_set(verbose) THEN print, 'Saving MinXSS sorted packets into ', fullFilename
save, hk, sci, log, adcs1, adcs2, adcs3, adcs4, diag, image, FILENAME = fullFilename, /compress, $
      description = 'MinXSS Level 0B data ... FM = ' + strtrim(fm,2) + '; Year = '+strmid(yyyydoy, 0, 4) + '; DOY = ' + strmid(yyyydoy, 4, 3) + ' ... FILE GENERATED: '+systime()

END
