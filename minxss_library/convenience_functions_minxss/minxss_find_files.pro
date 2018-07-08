;+
; NAME:
;	  minxss_find_files.pro
;
; PURPOSE:
;	  Find MinXSS files for given flight model, level, and date
;	  and return an array of strings of those file names with full path.
;	  Assumes that $minxss_data is defined (setenv for Unix/Mac) and
;	  that MinXSS files are located in $minxss_data/fmX/levelYY/ directory.
;
; CATEGORY:
; 	MinXSS Level 0C - Level 4
;
; CALLING SEQUENCE:'
;	  file_list = minxss_find_files( fm, level, yyyydoy, numfiles=numfiles, /verbose )
;
; INPUTS:
;	  level [string]: Data product level string: '0', '0B', '0C', '1', '2', '3', '4'
;					          this defaults Level 0 to Level 0C
;	  
;	OPTIONAL INPUTS:
;   fm [integer]:           Flight model number 1 or 2 (default is 1)
;   yyyydoy [long/lonarr]:  Date or date range to search in format of yyyydoy (Year and Day of Year). 
;                           If specifying a range of dates then should take form [yyyydoy1, yyyydoy2] where
;                           yyyydoy2 > yyyydoy1
;                           If not provided, will search all dates
;	  yyyymmdd [long/lonarr]: Alternative input to yyydoy. Can be single date or range e.g., [20160113, 20161231]
;	  
; KEYWORDS:
;   VERBOSE:  Set this to print messages for the search results
;
; OUTPUTS:
;	  file_list [string array]:	List of files as an array of strings. Full path is included.
;				                      Returns -1 if no files are found.
;
; OPTIONAL OUTPUTS: 
;   numfiles [long]: Number of files found
;   
; COMMON BLOCKS:
;	  None
;
; PROCEDURE:
;   1. Call IDL's file_search procedure with specified level and date in $minxss_data/fmX/levelYY/
;	  2. Set numfiles and Return the file list
;
; MODIFICATION HISTORY:
;   2015-09-08: Tom Woods:        Original code based on minxss_find_tlm_files.pro
;   2015-10-23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;   2015-10-23: James Paul Mason: Updated formatting of this header and made fm and yyyydoy properly formatted optional inputs
;   2015-11-16: James Paul Mason: Made yyyydoy optional input capable of handling a 2-element array with a range of dates. 
;                                 Also added the yyyymmdd optional input. 
;   2016-03-25: James Paul Mason: Updated to work with directory structure for level0b (should include fm1 folder)
;+
FUNCTION minxss_find_files, level, fm = fm, yyyydoy = yyyydoy, yyyymmdd = yyymmdd, numfiles=numfiles, verbose=verbose

;;
;  0. Validty checks and defaults
;;
if n_params() lt 1 then begin
  print, 'USAGE: file_list = minxss_find_files(level, fm=fm, yyyydoy=yyyydoy, numfiles=numfiles, /VERBOSE)'
  return, -1L
endif
IF ~keyword_set(fm) THEN fm = 2
if (fm lt 1) or (fm gt 3) then fm = 2
IF keyword_set(yyyymmdd) THEN BEGIN
  yyyydoy = lonarr(0)
  yearDoy1 = JPMDate2DOY(double(yyyymmdd[0]))
  IF yearDoy1.doy LT 100 THEN doyString = '0' + strtrim(yearDoy1.doy, 2) ELSE doyString = strtrim(yearDoy1.doy, 2)
  yyyydoy[0] = long(strtrim(yearDoy1.year, 2) + doyString)
  
  IF n_elements(yyyymmdd) EQ 2 THEN BEGIN
    yearDoy2 = JPMDate2DOY(double(yyyymmdd[1]))
    IF yearDoy2.doy LT 100 THEN doyString = '0' + strtrim(yearDoy2.doy, 2) ELSE doyString = strtrim(yearDoy2.doy, 2)
    yyyydoy[1] = long(strtrim(yearDoy2.year, 2) + doyString)
  ENDIF
ENDIF

leveltype = size(level,/type)
if ((leveltype ge 1) and (leveltype le 6)) or ((leveltype ge 12) and (leveltype le 14)) then begin
	level=strtrim(long(level),2)
endif else if (leveltype ne 7) then begin
  if keyword_set(verbose) then print, "ERROR: minxss_find_files input 'level' needs to be '0B', '0C', 1, 2, 3, or 4"
  return, -1L
endif
strlevel = strlowcase(strtrim(level,2))
case strlevel of
	'l0':  strlevel = strlevel + 'c'
  'l0b':  ;
	'l0c':  ;
	'l1':   ;
	'l2':   ;
	'l3':   ;
	'l4':   ;
	'0':   strlevel = 'l' + strlevel + 'c'
	'0b':  strlevel = 'l' + strlevel
	'0c':  strlevel = 'l' + strlevel
	'1':   strlevel = 'l' + strlevel
	'2':   strlevel = 'l' + strlevel
	'3':   strlevel = 'l' + strlevel
	'4':   strlevel = 'l' + strlevel
	else: begin
			if keyword_set(verbose) then $
				print, "ERROR: minxss_find_files 'level' needs to be '0B', '0C', 1, 2, 3, or 4"
			return, -1L
		end
endcase

if ~keyword_set(yyyydoy) then yyyydoy = -1L    ; allow to search for all dates

; Handle yyyydoy input as a date range
IF n_elements(yyyydoy) EQ 2 THEN yyyydoysArray = long(JPMRange(yyyydoy[0], yyyydoy[1])) ELSE yyyydoysArray = yyyydoy
 
; Loop through all of the date in the date range and add found files to the list
file_list = !NULL
numFiles = 0L
FOREACH yyyydoy, yyyydoysArray DO BEGIN

  if (yyyydoy lt 0) then begin
  	strdate = '*'
  endif else if (yyyydoy ge 2014001L) and (yyyydoy lt 2025000L) then begin
  	year = long(yyyydoy/1000L)
  	doy = long(yyyydoy - year*1000L)
  	doy_str = strtrim(doy,2)
  	if strlen(doy_str) eq 1 then doy_str = '00' + doy_str $
  	else if strlen(doy_str) eq 2 then doy_str = '0' + doy_str
  	strdate = strtrim(year,2) + '_' + doy_str
  endif else begin
  	if keyword_set(verbose) then print, "ERROR:  minxss_find_files 'yyyydoy' is invalid date"
  	return, -1L
  endelse
  
  ;
  ;   1. Call IDL's file_search procedure with specified level and date in $minxss_data/fmX/levelYY/
  ;
  IF fm EQ 3 THEN BEGIN
    flightModelString = 'fs' + strtrim(fm, 2)
  ENDIF ELSE BEGIN
    flightModelString = 'fm' + strtrim(fm, 2)
  ENDELSE
  search_dir = getenv('minxss_data') + '/'
  if strlevel ne 'l0b' then begin
  	;  ../data/fmA/levelBB/minxssA_lBB_YYYY_DOY.*
  	search_dir += flightModelString + '/' + 'leve' + strlevel + '/'
  	search_name = 'minxss' + strtrim(fm, 2) + '_' + strlevel + '_' + strdate + '.*'
  endif else begin
  	; special case for Level 0B files: ;  ../data/level0b/minxss_l0b_YYYY_DOY.*
  	search_dir += flightModelString + '/' + 'leve' + strlevel + '/'
  	search_name = 'minxss' + '_' + strlevel + '_' + strdate + '.*'
  endelse
  if keyword_set(verbose) then begin
    print, 'minxss_find_files: Search for ' + search_name + ' files'
    print, '    in directory ' + search_dir
  endif
  
  ; do recursive search in for files with the specified fm, level, and date
  file_list_yyyydoy = file_search( search_dir, search_name, count=count )
  IF count GT 0 THEN file_list = [file_list, file_list_yyyydoy]
  
  ;
  ;	2. Set numfiles and Return the file list
  ;
  
  numfiles+= count
  if keyword_set(verbose) then begin
    print, 'minxss_find_files: ', count, ' files found for date = ', strdate
    ; stop, 'DEBUG ...'
  endif

ENDFOREACH ; loop through yyyydoysArray

if keyword_set(verbose) then begin
  print, 'minxss_find_files: total number of files found is ', n_elements(file_list)
  ;stop, 'DEBUG minxss_find_files...'
endif

return, file_list
END