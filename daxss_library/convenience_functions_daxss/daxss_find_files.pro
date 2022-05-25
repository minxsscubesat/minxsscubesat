;+
; NAME:
;   daxss_find_files.pro
;
; PURPOSE:
;   Find DAXSS files for given level and date,
;   then return an array of strings of those file names with full path.
;   Assumes that $minxss_data is defined (setenv for Unix/Mac).
;
; INPUTS:
;   level [string]: Data product level string: '0', '0B', '0C', '1', '2', '3', '4'
;                   this defaults Level 0 to Level 0C
;
; OPTIONAL INPUTS:
;   yyyydoy [long/lonarr]:  Date or date range to search in format of yyyydoy (Year and Day of Year).
;                           If specifying a range of dates then should take form [yyyydoy1, yyyydoy2] where
;                           yyyydoy2 > yyyydoy1
;                           If not provided, will search all dates
;   yyyymmdd [long/lonarr]: Alternative input to yyydoy. Can be single date or range e.g., [20160113, 20161231]
;
; KEYWORDS:
;   VERBOSE:  Set this to print messages for the search results
;
; OUTPUTS:
;   file_list [string array]: List of files as an array of strings. Full path is included.
;                             Returns -1 if no files are found.
;
; OPTIONAL OUTPUTS:
;   numfiles [long]: Number of files found
;
; COMMON BLOCKS:
;   None
;
; PROCEDURE:
;   1. Call IDL's file_search procedure with specified level and date in $minxss_data/fmX/levelYY/
;   2. Set numfiles and Return the file list
;
;+
FUNCTION daxss_find_files, level, yyyydoy = yyyydoy, yyyymmdd = yyymmdd, $
                           VERBOSE=VERBOSE, $
                           numfiles=numfiles

  ;;
  ;  0. Validty checks and defaults
  ;;
  if n_params() lt 1 then begin
    message, /INFO, 'USAGE: file_list = daxss_find_files(level, yyyydoy=yyyydoy, numfiles=numfiles, /VERBOSE)'
    return, -1L
  endif
  IF keyword_set(yyyymmdd) THEN BEGIN
    yyyydoy = lonarr(0)
    yearDoy1 = JPMyyyymmdd2yyyydoy(double(yyyymmdd[0]))
    IF yearDoy1.doy LT 100 THEN doyString = '0' + strtrim(yearDoy1.doy, 2) ELSE doyString = strtrim(yearDoy1.doy, 2)
    yyyydoy[0] = long(strtrim(yearDoy1.year, 2) + doyString)

    IF n_elements(yyyymmdd) EQ 2 THEN BEGIN
      yearDoy2 = JPMyyyymmdd2yyyydoy(double(yyyymmdd[1]))
      IF yearDoy2.doy LT 100 THEN doyString = '0' + strtrim(yearDoy2.doy, 2) ELSE doyString = strtrim(yearDoy2.doy, 2)
      yyyydoy[1] = long(strtrim(yearDoy2.year, 2) + doyString)
    ENDIF
  ENDIF

  leveltype = size(level,/type)
  if ((leveltype ge 1) and (leveltype le 6)) or ((leveltype ge 12) and (leveltype le 14)) then begin
    level=strtrim(long(level),2)
  endif else if (leveltype ne 7) then begin
    if keyword_set(verbose) then message, /ERROR, " input 'level' needs to be '0B', '0C', 1, 2, 3, or 4"
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
        message, /ERROR, "'level' needs to be '0B', '0C', 1, 2, 3, or 4"
      return, -1L
    end
  endcase

  if ~keyword_set(yyyydoy) then yyyydoy = -1L ; allow to search for all dates

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
      if keyword_set(verbose) then message, /ERROR, "'yyyydoy' is invalid date"
      return, -1L
    endelse

    ;
    ; 1. Call IDL's file_search procedure with specified level and date in $minxss_data/fm3/levelYY/
    ;			Changed from fm4 to fm3 on 5/24/2022, TW
    ;
    search_dir = getenv('minxss_data') + path_sep() + 'fm3'
    search_dir += path_sep() + 'leve' + strlevel + path_sep()
    search_name = 'daxss' + '_' + strlevel + '_' + strdate + '.*'
    if keyword_set(verbose) then begin
      message, /INFO, 'Search for ' + search_name + ' files in directory ' + search_dir
    endif

    ; Do recursive search in for files with the specified fm, level, and date
    file_list_yyyydoy = file_search(search_dir, search_name, count=count)
    IF count GT 0 THEN file_list = [file_list, file_list_yyyydoy]

    ;
    ; 2. Set numfiles and return the file list
    ;

    numfiles += count
    if keyword_set(verbose) then begin
      message, /INFO, count + ' files found for date = ' + strdate
    endif

  ENDFOREACH ; loop through yyyydoysArray

  if keyword_set(verbose) then begin
    message, /INFO, ' total number of files found is ', n_elements(file_list)
  endif

  return, file_list
END
