;+
; NAME:
;   daxss_find_tlm_files.pro
;
; PURPOSE:
;   Find all DAXSS Hydra tlm (telemetry) files for given date
;   and return an array of strings of those file names with full path.
;   Assumes that $hydra_data_daxss_<location> variables are defined (setenv for Unix/Mac).
;
; INPUTS:
;   yyyydoy [long]: Date is in format of yyyydoy (Year and Day of Year)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORDS
;   NOHAM:    Set this to exclude data from ham operators
;   NOSDRLOG: Set this to exclude data from the SDR log
;   VERBOSE:  Option to print messages for the search results
;
; OUTPUTS:
;   file_list [strarr]: List of files as an array of strings.  Full path is included.
;                       Returns -1 if no files are found.
;
; OPTIONAL OUTPUTS:
;   numfiles: Optional return of the number of files found.
;
; COMMON BLOCKS:
;   None
;
; PROCEDURE:
;   1. Call IDL's file_search procedure with specified date in $daxss_data/
;   2. Set numfiles and return the file list
;+

function daxss_find_tlm_files, yyyydoy, numfiles=numfiles, $
                               NOHAM=NOHAM, NOSDRLOG=NOSDRLOG, VERBOSE=VERBOSE

  ; Defaults and input checks
  if n_params() lt 1 then begin
    message, /INFO, 'USAGE: file_list = daxss_find_tlm_files(yyyydoy, numfiles=numfiles, /verbose)'
    numfiles = 0L
    return, -1L
  endif

  ; check for valid input and then make YYYY_DOY string
  if (yyyydoy lt 2018001L) or (yyyydoy gt 2025001) then begin
    if keyword_set(verbose) then message, /ERROR, ' with input date !'
    numfiles = 0L
    return, -1L
  endif
  year = long(yyyydoy/1000L)
  doy = long(yyyydoy - year*1000L)
  doy_str = strtrim(doy,2)
  if strlen(doy_str) eq 1 then doy_str = '00' + doy_str $
  else if strlen(doy_str) eq 2 then doy_str = '0' + doy_str
  yd_str = strtrim(year,2) + '_' + doy_str

  ;
  ; 1. Call IDL's file_search procedure with specified date in $minxss_data/*
  ;
  search_name = 'tlm_packets_' + yd_str + '*'
  file_list = !NULL
  count = 0

  ; Add telemetry from Boulder if available
  IF getenv('hydra_data_boulder_daxss') NE '' THEN BEGIN
    filesTmp = file_search(getenv('hydra_data_boulder_daxss'), search_name, count = countTmp)
    IF countTmp NE 0 THEN BEGIN
      file_list = [file_list, filesTmp]
      count = count + countTmp
    ENDIF
  ENDIF

  ; Add telemetry from Fairbanks available
  IF getenv('hydra_data_daxss_fairbanks') NE '' THEN BEGIN
    filesTmp = file_search(getenv('hydra_data_daxss_fairbanks'), search_name, count = countTmp)
    IF countTmp NE 0 THEN BEGIN
      file_list = [file_list, filesTmp]
      count = count + countTmp
    ENDIF
  ENDIF

  IF NOT keyword_set(NOHAM) THEN BEGIN
    ; Add telemetry from HAM operators
    IF getenv('ham_data') NE '' THEN BEGIN
      hamFiles = file_search(getenv('ham_data'), JPMyyyydoy2yyyymmdd(yyyydoy, /RETURN_STRING) + '*.{dat,kss,kiss}', count = countHam)
      IF countHam NE 0 THEN BEGIN
        file_list = [file_list, hamFiles]
        count = count + countHam
      ENDIF
    ENDIF
  ENDIF

  IF NOT keyword_set(NOSDRLOG) THEN BEGIN
    ; Add raw SDR output
    IF getenv('sdr_data') NE '' THEN BEGIN
      sdrFiles = file_search(getenv('sdr_data'), '*' + JPMyyyydoy2yyyymmdd(yyyydoy, /RETURN_STRING) + '*.{bin,log}', count = countSDR)
      IF countSDR NE 0 THEN BEGIN
        file_list = [file_list, sdrFiles]
        count = count + countSDR
      ENDIF
    ENDIF
  ENDIF

  IF count EQ 0 THEN file_list = -1L

  ;
  ; 2. Set numfiles and return the file list
  ;
  numfiles = count
  if keyword_set(verbose) then begin
    message, /INFO, strtrim(numfiles,2) + ' files found for date = ' + yd_str
  endif

  return, file_list
end
