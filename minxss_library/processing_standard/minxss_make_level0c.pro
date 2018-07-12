;+
; NAME:
;   minxss_make_level0c.pro
;
; PURPOSE:
;   Read all Level 0B data products and sort and save packets for individual day
;   Note that Level 0B files can have packets from any past day because of downlink playback.
;	  Level 0C files only have packets of a single day
;
; CATEGORY:
;    MinXSS Level 0C
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:    Flight Model number 1 or 2 (default is 1)
;   yyyydoy	[long]:  Optional input of yyyymmdd date to find telemetry files with that date
;						         If yyyydoy or yyyymmdd is not provided, then process for all days
;   yyyymmdd [long]: Optional input of yyyymmdd date to find telemetry files with that date, instead of yyyydoy. 
;   
; KEYWORD PARAMETERS:
;   VERBOSE:             Set this to print processing messages 
;   MAKE_MISSION_LENGTH: Set this to create a mission length file
;   MERGE_ONLY:          Set this to skip the reprocessing and go straight to merging the mission length file
;
; OUTPUTS:
;   IDL .sav files in getenv('minxss_data')/fmX/level0c
;
; OPTIONAL OUTPUTS:
;   playback    Optional output that provide playback stats
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
; 	Requires minxss_find_files.pro
;	  Requires minxss_filename_parts.pro
;   Requires minxss_sort_packets.pro
;	  Uses the MinXSS convenience_functions_generic routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Find all Level 0B files (minxss_find_files.pro)
;   2. Read all of the Level 0B files
;	  3. Sort the packets for flight number and date
;   4. Sort the selected packets by time of day
;	  5. Save the sorted packets (file per day)
;
; MODIFICATION HISTORY:
;	  2015/09/07: Tom Woods: Updated to provide playback stats
;   2015/10/23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;   2015/10/23: James Paul Mason: Updated formatting of this header and converted FM to a standard format optional input
;   2016/03/25: James Paul Mason: Added yyyymmdd optional input. 
;   2016/05/29: Amir Caspi: Look back one day from yyyydoy, since L0B is local time and L0C is UTC; for mission_length, look ahead one day
;   2016-11-21: James Paul Mason: Null out data variables before restoring another day's data -- otherwise can result in stale data propagation
;+
PRO minxss_make_level0c, fm = fm, yyyydoy = yyyydoy, yyyymmdd = yyyymmdd, $
                         VERBOSE = VERBOSE, MAKE_MISSION_LENGTH = MAKE_MISSION_LENGTH, MERGE_ONLY = MERGE_ONLY

;
;	check for valid input parameters
;
IF ~keyword_set(fm) THEN fm = 2
if (fm gt 3) or (fm lt 1) then begin
  print, "ERROR: minxss_make_level0c needs a valid 'fm' value. FM can be 1, 2, or 3."
  return
endif

IF yyyymmdd NE !NULL THEN yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)

if keyword_set(yyyydoy) then begin
	start_yd = long(yyyydoy[0])
	if n_elements(yyyydoy) gt 1 then stop_yd = long(yyyydoy[1]) else stop_yd = start_yd
endif else begin
	; process all possible dates
	start_yd = 2015001L
	stop_yd = long(jd2yd(systime(/julian))+0.5)
endelse

IF keyword_set(MERGE_ONLY) THEN BEGIN
  MAKE_MISSION_LENGTH = 1
ENDIF

IF keyword_set(MAKE_MISSION_LENGTH) THEN BEGIN
  CASE (fm) OF
    1: BEGIN
      start_yd = 2016137L
      stop_yd = long(JPMjd2yyyydoy(systime(/JULIAN)+1.5))
    END
    2: BEGIN
      start_yd = 2017001 ; FIXME: Replace these numbers once FM-2 launches
      stop_yd = long(jd2yd(systime(/julian))+0.5)
    END
    ELSE: BEGIN
    END
  ENDCASE
ENDIF

IF keyword_set(MERGE_ONLY) THEN BEGIN
  GOTO, MERGE_ONLY
ENDIF

;
;   1. Find all Level 0B files (minxss_find_files.pro)
;
fileNamesArray = minxss_find_files( 'L0B', fm=fm, numfiles=numfiles, VERBOSE = VERBOSE)


IF numfiles lt 1 THEN BEGIN
    print, 'ERROR: minxss_make_level0c can not find the Level 0B files'
    return
ENDIF

;	identify which file can first be used:  all files with date > start_yd
start_index = 0L

;  make array of yd and jd
jd1 = yd2jd(start_yd)
jd2 = yd2jd(stop_yd)
numDays = long(jd2-jd1)+1 & numDays = numDays[0]
ydArray = long(jd2yd(findgen(numDays) + jd1))

;
;	Loop through each date that needs processing
;
for k=0L,numDays-1 do begin
  yd = ydArray[k]
  fileCnt = 0L
  ;
  ;   2. Read all of the appropriate Level 0B files: all files with date >= YYYYDOY
  ;   5/29/2016: AC - minus one day, since L0B is based on local (Mountain) time, but L0C is based on UTC
  ;
  for iFile = start_index, numfiles-1 do begin
	;	identify which file can first be read
	fn_parts = minxss_filename_parts( fileNamesArray[iFile], /L0B )

;    if (fn_parts.yyyydoy lt yd) then start_index = iFile + 1 else begin
    IF (fn_parts.yyyydoy LT (yd - 1)) THEN CONTINUE ELSE BEGIN
    	
    	; Null out all variables before reading new ones in to avoid stale data propagation
    	hk = !NULL
    	sci = !NULL
    	log = !NULL
    	diag = !NULL
    	image = !NULL
    	adcs1 = !NULL
    	adcs2 = !NULL
    	adcs3 = !NULL
    	adcs4 = !NULL
    	
    	; Restore data
    	restore, fileNamesArray[iFile]
    	fileCnt += 1

    	;
    	; 3. Sort the packets for flight number and date
    	;
    	;  ERROR:  some playbacks don't have HK packets (just SCI packets sometimes)
    	;  FIX:  just check that HK on any day has correct FM number
    	;    Tom Woods 9/3/2016
    	;    
    	; IF hk NE !NULL THEN minxss_sort_packets, hk, yd, fm   ;  ERROR Code
    	;
    	;    FIX starts here
    	;
    	IF (hk NE !NULL) THEN BEGIN
    	  wgood = where( hk.flight_model EQ fm, numgood )
    	  IF (numgood LE 0) THEN BEGIN
    	    hk = !NULL
    	    IF keyword_set(verbose) THEN print, 'No HK Packets for FM = ', strtrim(fm,2), ' in ', fileNamesArray[iFile]
    	  ENDIF 
    	ENDIF
    	;  end of FIX

    	if (hk NE !NULL) then begin
    	    ; this assumes that rest of the data is from same flight model as HK packets
    	  IF hk NE !NULL THEN minxss_sort_packets, hk, yd    ;  Extra Code for the FIX so HK is also sorted by YD value
  		  IF sci NE !NULL THEN minxss_sort_packets, sci, yd
  		  IF log NE !NULL THEN minxss_sort_packets, log, yd
  		  IF diag NE !NULL THEN minxss_sort_packets, diag, yd
  		  IF image NE !NULL THEN minxss_sort_packets, image, yd
  		  IF adcs1 NE !NULL THEN minxss_sort_packets, adcs1, yd
  		  IF adcs2 NE !NULL THEN minxss_sort_packets, adcs2, yd
  		  IF adcs3 NE !NULL THEN minxss_sort_packets, adcs3, yd
  		  IF adcs4 NE !NULL THEN minxss_sort_packets, adcs4, yd
  		endif else begin
  			; this dumps rest of the packets if HK packets are not found
  			sci = !NULL
  			log = !NULL
  			diag = !NULL
  			image = !NULL
  			adcs1 = !NULL
  			adcs2 = !NULL
  			adcs3 = !NULL
  			adcs4 = !NULL
  		endelse

    	;
    	; combine packets with previous file records
    	;
    	if hk NE !NULL then if all_hk NE !NULL then all_hk = [all_hk, hk] else all_hk = hk
    	if sci NE !NULL then if all_sci NE !NULL then all_sci = [all_sci, sci] else all_sci = sci
    	if log NE !NULL then if all_log NE !NULL then all_log = [all_log, log] else all_log = log
    	if diag NE !NULL then if all_diag NE !NULL then all_diag = [all_diag, diag] else all_diag = diag
    	if image NE !NULL then if all_image NE !NULL then all_image = [all_image, image] else all_image = image
    	if adcs1 NE !NULL then if all_adcs1 NE !NULL then all_adcs1 = [all_adcs1, adcs1] else all_adcs1 = adcs1
    	if adcs2 NE !NULL then if all_adcs2 NE !NULL then all_adcs2 = [all_adcs2, adcs2] else all_adcs2 = adcs2
    	if adcs3 NE !NULL then if all_adcs3 NE !NULL then all_adcs3 = [all_adcs3, adcs3] else all_adcs3 = adcs3
    	if adcs4 NE !NULL then if all_adcs4 NE !NULL then all_adcs4 = [all_adcs4, adcs4] else all_adcs4 = adcs4
    endelse
  
    IF sci NE !NULL THEN BEGIN
      tags = tag_names(sci)
      IF where(strmatch(tags, 'time_jd', /FOLD_CASE) EQ 1) NE -1 THEN STOP
    ENDIF
    
  endfor

  if keyword_set(verbose) then begin
  	print, ' '
  	print, 'Number of files processed is ', strtrim(fileCnt,2), ' for date ', strtrim(yd,2)
  endif

  ;
  ; 4. Sort the found packets by time of day
  ;
  IF all_hk NE !NULL THEN minxss_sort_packets, all_hk
  IF all_sci NE !NULL THEN minxss_sort_packets, all_sci
  IF all_log NE !NULL THEN minxss_sort_packets, all_log
  IF all_diag NE !NULL THEN minxss_sort_packets, all_diag
  IF all_image NE !NULL THEN minxss_sort_packets, all_image
  IF all_adcs1 NE !NULL THEN minxss_sort_packets, all_adcs1
  IF all_adcs2 NE !NULL THEN minxss_sort_packets, all_adcs2
  IF all_adcs3 NE !NULL THEN minxss_sort_packets, all_adcs3
  IF all_adcs4 NE !NULL THEN minxss_sort_packets, all_adcs4

  ;
  ; 5. Save the sorted packets (file per day)
  ;
  ; Figure out the directory name to make
  year = long(yd/1000L)
  doy = long(yd - year*1000L)
  doy_str = strtrim(doy,2)
  if strlen(doy_str) eq 1 then doy_str = '00' + doy_str $
  else if strlen(doy_str) eq 2 then doy_str = '0' + doy_str
  str_yd = strtrim(year,2) + '_' + doy_str
  outputFilename = 'minxss'+strtrim(fm,2)+'_l0c_'+str_yd
  IF FM EQ 3 THEN BEGIN
    flightModelString = 'fs' + strtrim(fm, 2)
  ENDIF ELSE BEGIN
    flightModelString = 'fm' + strtrim(fm, 2)
  ENDELSE
  full_Filename = getenv('minxss_data') + '/' + flightModelString + '/level0c/' + outputFilename + '.sav'

  ;  rename variables to be like Level 0B names
  if all_hk NE !NULL then hk = all_hk else hk = !NULL & all_hk = !NULL
  if all_sci NE !NULL then sci = all_sci else sci = !NULL & all_sci = !NULL
  if all_log NE !NULL then log = all_log else log = !NULL & all_log = !NULL
  if all_diag NE !NULL then diag = all_diag else diag = !NULL & all_diag = !NULL
  if all_image NE !NULL then image = all_image else image = !NULL & all_image = !NULL
  if all_adcs1 NE !NULL then adcs1 = all_adcs1 else adcs1 = !NULL & all_adcs1 = !NULL
  if all_adcs2 NE !NULL then adcs2 = all_adcs2 else adcs2 = !NULL & all_adcs2 = !NULL
  if all_adcs3 NE !NULL then adcs3 = all_adcs3 else adcs3 = !NULL & all_adcs3 = !NULL
  if all_adcs4 NE !NULL then adcs4 = all_adcs4 else adcs4 = !NULL & all_adcs4 = !NULL

  ; Add all the times you can think of, including human readable, to each packet type 
  IF hk NE !NULL THEN BEGIN
    hk = JPMAddTagsToStructure(hk, 'time_jd') & hk.time_jd = gps2jd(hk.time)
    hk = JPMAddTagsToStructure(hk, 'time_iso', 'string') & hk.time_iso = JPMjd2iso(hk.time_jd)
    hk = JPMAddTagsToStructure(hk, 'time_human', 'string') & hk.time_human = JPMjd2iso(hk.time_jd, /NO_T_OR_Z)
  ENDIF
  IF log NE !NULL THEN BEGIN
    log = JPMAddTagsToStructure(log, 'time_human', 'string') & log.time_human = JPMjd2iso(gps2jd(log.time), /NO_T_OR_Z)
  ENDIF
  IF sci NE !NULL THEN BEGIN
    sci = JPMAddTagsToStructure(sci, 'time_jd') & sci.time_jd = gps2jd(sci.time)
    sci = JPMAddTagsToStructure(sci, 'time_iso', 'string') & sci.time_iso = JPMjd2iso(sci.time_jd)
    sci = JPMAddTagsToStructure(sci, 'time_human', 'string') & sci.time_human = JPMjd2iso(sci.time_jd, /NO_T_OR_Z)
  ENDIF
  IF adcs1 NE !NULL THEN BEGIN
    adcs1 = JPMAddTagsToStructure(adcs1, 'time_jd') & adcs1.time_jd = gps2jd(adcs1.time)
    adcs1 = JPMAddTagsToStructure(adcs1, 'time_iso', 'string') & adcs1.time_iso = JPMjd2iso(adcs1.time_jd)
    adcs1 = JPMAddTagsToStructure(adcs1, 'time_human', 'string') & adcs1.time_human = JPMjd2iso(adcs1.time_jd, /NO_T_OR_Z)
  ENDIF
  IF adcs2 NE !NULL THEN BEGIN
    adcs2 = JPMAddTagsToStructure(adcs2, 'time_jd') & adcs2.time_jd = gps2jd(adcs2.time)
    adcs2 = JPMAddTagsToStructure(adcs2, 'time_iso', 'string') & adcs2.time_iso = JPMjd2iso(adcs2.time_jd)
    adcs2 = JPMAddTagsToStructure(adcs2, 'time_human', 'string') & adcs2.time_human = JPMjd2iso(adcs2.time_jd, /NO_T_OR_Z)
  ENDIF
  IF adcs3 NE !NULL THEN BEGIN
    adcs3 = JPMAddTagsToStructure(adcs3, 'time_jd') & adcs3.time_jd = gps2jd(adcs3.time)
    adcs3 = JPMAddTagsToStructure(adcs3, 'time_iso', 'string') & adcs3.time_iso = JPMjd2iso(adcs3.time_jd)
    adcs3 = JPMAddTagsToStructure(adcs3, 'time_human', 'string') & adcs3.time_human = JPMjd2iso(adcs3.time_jd, /NO_T_OR_Z)
  ENDIF
  IF adcs4 NE !NULL THEN BEGIN
    adcs4 = JPMAddTagsToStructure(adcs4, 'time_jd') & adcs4.time_jd = gps2jd(adcs4.time)
    adcs4 = JPMAddTagsToStructure(adcs4, 'time_iso', 'string') & adcs4.time_iso = JPMjd2iso(adcs4.time_jd)
    adcs4 = JPMAddTagsToStructure(adcs4, 'time_human', 'string') & adcs4.time_human = JPMjd2iso(adcs4.time_jd, /NO_T_OR_Z)
  ENDIF

  ;  save the packets now
  total_packets = n_elements(hk) + n_elements(sci) + n_elements(log)
  
  if (total_packets gt 0) then begin
	  save, hk, sci, log, adcs1, adcs2, adcs3, adcs4, diag, image, FILENAME = full_Filename, /compress, description = 'MinXSS Level 0C data ... FM = '+strtrim(fm,2)+'; Year = '+strtrim(year,2)+'; DOY = '+strtrim(doy,2)+' ... FILE GENERATED: '+systime()
	  wait, 0.5 ; let the filesystem catch up so files are saved in proper time-order
	if keyword_set(verbose) then begin
	  message, /info, 'Saving MinXSS Level 0C sorted packets into ' + outputFilename
	  if hk NE !NULL then    print, '    Number of HK    packets = ' + string(n_elements(hk))
	  if sci NE !NULL then   print, '    Number of SCI   packets = ' + string(n_elements(sci))
	  if log NE !NULL then   print, '    Number of LOG   packets = ' + string(n_elements(log))
	  if diag NE !NULL then  print, '    Number of DIAG  packets = ' + string(n_elements(diag))
	  if image NE !NULL then print, '    Number of IMAGE packets = ' + string(n_elements(image))
	  if adcs1 NE !NULL then print, '    Number of ADCS1 packets = ' + string(n_elements(adcs1))
	  if adcs2 NE !NULL then print, '    Number of ADCS2 packets = ' + string(n_elements(adcs2))
	  if adcs3 NE !NULL then print, '    Number of ADCS3 packets = ' + string(n_elements(adcs3))
	  if adcs4 NE !NULL then print, '    Number of ADCS4 packets = ' + string(n_elements(adcs4))
    endif
  endif else begin
  	if keyword_set(verbose) then begin
	  print, 'No Level 0C data for ', outputFilename
	endif
  endelse


;
; End of loop through each day that needs processing
;
endfor

; Compile into mission length saveset for each type of data
MERGE_ONLY:
IF keyword_set(MAKE_MISSION_LENGTH) THEN BEGIN
  if fm eq 3 then begin
    dataPath = getenv('minxss_data') + '/fs' + strtrim(fm, 2) + '/level0c/'
  endif else begin
    dataPath = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/'
  endelse
  
  ; Prepare for concatenation 
  hkTemp = !NULL
  sciTemp = !NULL
  logTemp = !NULL
  diagTemp = !NULL
  imageTemp = !NULL
  adcs1Temp = !NULL
  adcs2Temp = !NULL
  adcs3Temp = !NULL
  adcs4Temp = !NULL
  
  ; Loop through all the data files and concatenate data
  FOR yyyyDoy = start_yd, stop_yd DO BEGIN
    yyyyDoyString = strmid(strtrim(yyyyDoy, 2), 0, 4) + '_' + strmid(strtrim(yyyyDoy, 2), 4, 3)
    dataFile = 'minxss' + strtrim(fm, 2) + '_l0c_' + yyyyDoyString + '.sav'
    
    IF ~file_test(dataPath + dataFile) THEN CONTINUE

    ; Kill any old variables because we don't want them to persist!
    hk = !NULL
    sci = !NULL
    log = !NULL
    diag = !NULL
    image = !NULL
    adcs1 = !NULL
    adcs2 = !NULL
    adcs3 = !NULL
    adcs4 = !NULL

    restore, dataPath + dataFile
    IF keyword_set(verbose) THEN message, /info, "Restoring file " + dataFile + " ..."
    hkTemp = [hkTemp, hk]
    sciTemp = [sciTemp, sci]
    logTemp = [logTemp, log]
    diagTemp = [diagTemp, diag]
    imageTemp = [imageTemp, image]
    adcs1Temp = [adcs1Temp, adcs1]
    adcs2Temp = [adcs2Temp, adcs2]
    adcs3Temp = [adcs3Temp, adcs3]
    adcs4Temp = [adcs4Temp, adcs4]
  ENDFOR
  
  ; Transfer concatenated data to normal names
  hk = temporary(hkTemp)
  sci = temporary(sciTemp)
  log = temporary(logTemp)
  diag = temporary(diagTemp)
  image = temporary(imageTemp)
  adcs1 = temporary(adcs1Temp)
  adcs2 = temporary(adcs2Temp)
  adcs3 = temporary(adcs3Temp)
  adcs4 = temporary(adcs4Temp)
  
  ; Save mission length file
  save, hk, sci, log, diag, image, adcs1, adcs2, adcs3, adcs4, FILENAME = dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'all_mission_length.sav', /COMPRESS, description = 'MinXSS Level 0C data ... All ... FM = '+strtrim(fm,2)+'; FULL MISSION ('+strmid(strtrim(start_yd, 2), 0, 4) + '/' + strmid(strtrim(start_yd, 2), 4, 3)+' - '+strmid(strtrim(stop_yd, 2), 0, 4) + '/' + strmid(strtrim(stop_yd, 2), 4, 3)+') ... FILE GENERATED: '+systime()

  ; Export to CSV as well (mainly for use with LASP WebTCAD
  write_csv, dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'hk_latest.csv', hk, HEADER = tag_names(hk)
  adcs1 = JPMRemoveTags(adcs1, 'ADCS_LEVEL')
  if (adcs1 NE !NULL) then write_csv, dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'adcs1_latest.csv', adcs1, HEADER = tag_names(adcs1)
  if (adcs2 NE !NULL) then write_csv, dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'adcs2_latest.csv', adcs2, HEADER = tag_names(adcs2)
  if (adcs3 NE !NULL) then write_csv, dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'adcs3_latest.csv', adcs3, HEADER = tag_names(adcs3)
  if (adcs4 NE !NULL) then write_csv, dataPath + 'minxss' + strtrim(fm, 2) + '_l0c_' + 'adcs4_latest.csv', adcs4, HEADER = tag_names(adcs4)
  
ENDIF ; MAKE_MISSION_LENGTH

END
