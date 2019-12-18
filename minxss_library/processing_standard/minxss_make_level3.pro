;+
; NAME:
;   minxss_make_level3.pro
;
; PURPOSE:
;   Read a data product and make daily average data structure
;
;	  This is intended for processing L2 irradiance results to get daily averaged irradiance values.
;	  But it also be used with any MinXSS data product (e.g. L0C, L0D, L1, L2) as the averaging
;	  routine is generic for a data structure array (assuming data are just during one day).
;
; INPUTS:
;   None required
;   
; OPTIONAL INPUTS:
;   dateRange [dblarr]:    Date range to process. Can be single date or date range, e.g., [2016001] or [2016001, 2016030].
;                          If single date input, then that full day will be processed. If two dates input, processing will be inclusive of the full range. 
;                          Date formats can be either yyyydoy or yyyymmdd, e.g., [2016152] or [20160601]. 
;                          Time within a day is ignored here i.e., yyyydoy.fod or yyyymmdd.hhmmmss can be input but time information
;                          will be ignored. Code always starts from day start, i.e., fod = 0.0. 
;                          If timeRange is not provided, then code will process all Level0C data. 
;   level [int or string]: 0C, 0D, 1, or 2 (default is 2). If 0 is the input number, it will default to 0D
;   fm [integer]:			     Flight Model number 1 or 2 (default is 1)
;
; OPTIONAL INPUTS:
;	  None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   None
;   
; OPTIONAL OUTPUTS
;   result: Provides the daily averaged result
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;	  Requires minxss_find_files.pro
;	  Requires minxss_filename_parts.pro
;   Requires minxss_average_packets.pro
;	  Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Read the MinXSS file for a day (minxss_find_files.pro)
;	  2. Select (filter) the data for good (valid) data (e.g. not in eclipse for irradiances)
;   3. Average the data over the day (minxss_average_packets.pro)
;	  4. Save the daily averaged result (file per day)
;
; MODIFICATION HISTORY:
;	  2015-11-29: Tom Woods: Original code
;	  2017-03-22: James Paul Mason: Made level and fm an optional inputs instead of a required ones.
;	                                Replaced yyyydoy input with dateRange, consistent with minxss_make_level0d. 
;+
PRO minxss_make_level3, dateRange = dateRange, level = level, fm = fm, result = result, $
                        VERBOSE = VERBOSE

; Default return value
result = -1L

;
;	check for valid input parameters
;

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  print, "ERROR: minxss_make_level3 needs a valid 'fm' value.  FM can be 1 or 2."
  return
endif

; Defaults and validty checks - level
IF level EQ !NULL THEN level = 2
levelstr = strupcase( strtrim(level,2) )
levelnum = long(strmid(levelstr,0,1))
if (levelnum gt 2) or (levelnum lt 0) then begin
  print, "ERROR: minxss_make_level3 needs a valid 'level' value: 0C, 0C, 1 or 2."
  return
endif
if (levelnum eq 0) and (strlen(levelstr) lt 2) then levelstr += 'D'

; Defaults and validity checks - dateRange
dateRangeYYYYDOY = lonarr(2)
IF dateRange NE !NULL THEN BEGIN

  ; Determine if using normal date formatting (i.e., yyyymmdd) and convert to yyyydoy
  IF strlen(strtrim(dateRange[0], 2)) GT 7 THEN BEGIN
    yearDoy1 = JPMyyyymmdd2yyyydoy(double(dateRange[0]))
    IF yearDoy1.doy LT 100 THEN doyString = '0' + strtrim(yearDoy1.doy, 2) ELSE doyString = strtrim(yearDoy1.doy, 2)
    dateRangeYYYYDOY[0] = long(strtrim(yearDoy1.year, 2) + doyString)

    IF n_elements(dateRange) EQ 2 THEN BEGIN
      yearDoy2 = JPMyyyymmdd2yyyydoy(double(dateRange[1]))
      IF yearDoy2.doy LT 100 THEN doyString = '0' + strtrim(yearDoy2.doy, 2) ELSE doyString = strtrim(yearDoy2.doy, 2)
      dateRangeYYYYDOY[1] = long(strtrim(yearDoy2.year, 2) + doyString)
    ENDIF
  ENDIF ELSE BEGIN
    dateRangeYYYYDOY[0] = dateRange[0]
    IF n_elements(dateRange) EQ 2 THEN dateRangeYYYYDOY[1] = dateRange[1]
  ENDELSE


  ; If single dateRange input then process that whole day
  IF dateRangeYYYYDOY[1] EQ 0 THEN dateRangeYYYYDOY[1] = dateRangeYYYYDOY[0] + 1L

ENDIF ELSE BEGIN ; endif dateRange ≠ NULL else dateRange not set
  ; If no dateRange input then process all possible flight dates to present
  IF fm EQ 1 THEN dateRangeYYYYDOY = [2016136L, long(jd2yd(systime(/julian) + 0.5))] ELSE $
    dateRangeYYYYDOY = [2016300L, long(jd2yd(systime(/julian) + 0.5))]
ENDELSE

; Loop through all of the dates
FOREACH yyyydoy, dateRangeYYYYDOY DO BEGIN
  
  yyyy = long(yyyydoy/1000.)
  doy = long(yyyydoy) mod 1000L
  date_str = '*' + string(yyyy,format='(I04)') + '_' + string(doy,format='(I03)') + '*.*'
  
  ;
  ;   1. Read the MinXSS file for a day (minxss_find_files.pro)
  ;
  levelname = 'L' + levelstr
  fileNamesArray = minxss_find_files(levelname, fm = fm, yyyydoy = yyyydoy, numfiles=numfiles, VERBOSE = VERBOSE)
  
  IF numfiles lt 1 THEN BEGIN
      print, 'ERROR: minxss_make_level3 can not find any Level ' + levelstr + ' files.'
      return
  ENDIF
  ;
  ; Select the last file in the list (if version numbers are used so get the latest)
  ;	then read the file
  ;
  theFile = fileNamesArray[ numfiles-1 ]
  if keyword_set(verbose) then print, 'minxss_make_level3: Reading input file ', theFile
  restore, theFile
  
  ; STOP, 'DEBUG the theFile data ...'
  
  ;
  ;	2. Select (filter) the data for good (valid) data (e.g. not in eclipse for irradiances)
  ; 3. Average the data over the day (minxss_average_packets.pro)
  ;	4. Save the daily averaged result (file per day)
  ;		Make file & directory name and then save the "data" as "average" for Levels 0D, 1, 2
  ;		For level 0C, save hk, sci, adcs1, adcs2, adcs3, adcs4 packet averages
  ;
  str_yd = strmid(date_str,1,8)
  outputFilename = 'minxss'+strtrim(fm,2)+'_l3'
  if (levelnum ne 2) then outputFilename += '-l' + strlowcase(levelstr)
  outputFilename += '_' + str_yd
  dirName = getenv('minxss_processing') + '/data/fm' + strtrim(fm,2) + '/level'
  if (levelnum eq 2) then begin
  dirName += '3/'
  endif else begin
  dirName += strlowcase(levelstr) + '/daily/'
  endelse
  full_Filename = dirName + outputFilename + '.sav'
  if keyword_set(verbose) then print, 'minxss_make_level3: Writing L3 file to ', full_Filename
  
  ;
  ;	Process the data differently based on Level
  ;
  case levelstr of
  	'0C':  begin
  		; ignoring LOG, DIAG, and IMAGE packets for the daily average
  		if hk NE !NULL then    hk_avg = minxss_average_packets( hk )
  		if sci NE !NULL then   sci_avg = minxss_average_packets( sci )
  		if adcs1 NE !NULL then adcs1_avg = minxss_average_packets( adcs1 )
  		if adcs2 NE !NULL then adcs2_avg = minxss_average_packets( adcs2 )
  		if adcs3 NE !NULL then adcs3_avg = minxss_average_packets( adcs3 )
  		if adcs4 NE !NULL then adcs4_avg = minxss_average_packets( adcs4 )
  		save, hk_avg, sci_avg, adcs1_avg, adcs2_avg, adcs3_avg, adcs4_avg, file=full_Filename
  		; return the hk_avg as the result
  		result = hk_avg
  		end
  	'0D':  begin
  		; filter the data (none for L0D)
  		;	data = LEVEL_0D_ARRAY_NAME
  		result = minxss_average_packets( data )
  		average = result
  		save, average, file=full_Filename
  		end
  	'1':  begin
  		; filter the data (e.g. only daylight data allowed)
  		;	TO DO:  add Level 1 filtering
  		;	data = LEVEL_1_ARRAY_NAME
  		;	data = data[ where(data.XXX is GOOD) ]
  		result = minxss_average_packets( data )
  		average = result
  		save, average, file=full_Filename
  		end
  	'2':  begin
  		; filter the data (e.g. only daylight data allowed)
  		;	TO DO:  add Level 2 filtering
  		;	data = LEVEL_2_ARRAY_NAME
  		;	data = data[ where(data.XXX is GOOD) ]
  		result = minxss_average_packets( data )
  		average = result
  		save, average, file=full_Filename
  		end
  	else:  begin
  		print, 'ERROR: minxss_make_level3 had invalid level of ', levelstr
      	return
  		end
  endcase

ENDFOREACH ; loop through each date

; STOP, 'DEBUG at end of minxss_make_level3.pro ...'

RETURN
END
