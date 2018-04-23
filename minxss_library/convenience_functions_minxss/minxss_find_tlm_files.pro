;+
; NAME:
;	  minxss_find_tlm_files.pro
;
; PURPOSE:
;	  Find all MinXSS ISIS tlm (telemetry) files for given date
;	  and return an array of strings of those file names with full path.
;	  Assumes that $minxss_data is defined (setenv for Unix/Mac) and
;	  that ISIS tlm files are located in $minxss_data/isis_tlm/ directory.
;
; CATEGORY:
;	  MinXSS Level 0B
;
; CALLING SEQUENCE:
;	  file_list = minxss_find_tlm_files( yyyydoy, numfiles=numfiles, /verbose )
;
; INPUTS:
;	  yyyydoy [long]: Date is in format of yyyydoy (Year and Day of Year)
;	
;	OPTIONAL INPUTS:
;	  None
;	
;	KEYWORDS
;	  VERBOSE: Option to print messages for the search results
;
; OUTPUTS:
;	  file_list [strarr]: List of files as an array of strings.  Full path is included.
;				                Returns -1 if no files are found.
;	
;	OPTIONAL OUTPUTS:
;	  numfiles: Optional return of the number of files found.
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;   1. Call IDL's file_search procedure with specified date in $minxss_data/isis_tlm/
;	  2. Set numfiles and Return the file list
;
; MODIFICATION HISTORY:
;   2015-08-30: Tom Woods:        ISIS changed tlm_packets files to NOT have the *.out extension
;   2015-10-23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;   2016-03-25: James Paul Mason: Updated to reflect changes to the ISIS rundirs location in minxss_dropbox
;   2016-09-08: James Paul Mason: Added telemetry from Jim White's ground station to be concatenated with LASP's
;   2017-01-09: James Paul Maosn: Fixed bug in case where Jim's ground station didn't have any data for a whole day
;+

function minxss_find_tlm_files, yyyydoy, numfiles=numfiles, verbose=verbose

if n_params() lt 1 then begin
  print, 'USAGE: file_list = minxss_find_tlm_files( yyyydoy, numfiles=numfiles, /verbose )'
  numfiles = 0L
  return, -1L
endif

; check for valid input and then make YYYY_DOY string
if (yyyydoy lt 2014001L) or (yyyydoy gt 2025001) then begin
  if keyword_set(verbose) then print, 'minxss_find_tlm_files: ERROR with input date !'
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
; 1. Call IDL's file_search procedure with specified date in $minxss_data/isis_tlm/
;
search_dir = getenv('isis_data')
search_name = 'tlm_packets_' + yd_str + '*'
file_list = file_search( search_dir, search_name, count=count )
IF count EQ 0 THEN file_list = !NULL

; Add telemetry from Jim if available
IF ~strmatch(getenv('isis_data_jim_white'), '*nowhere*') THEN BEGIN
  jimFiles = file_search(getenv('isis_data_jim_white'), search_name, count = countJim)
  IF countJim NE 0 THEN BEGIN
    file_list = [file_list, jimFiles]
    count = count + countJim
  ENDIF
ENDIF

; Add telemetry from Fairbanks for FM-2 if available
IF getenv('isis_data_fairbanks_minxss2') NE '' THEN BEGIN
  fairBanksMinxss2Files = file_search(getenv('isis_data_fairbanks_minxss2'), search_name, count = countFairbanksMinxss2)
  IF countFairbanksMinxss2 NE 0 THEN BEGIN
    file_list = [file_list, fairBanksMinxss2Files]
    count = count + countFairbanksMinxss2
  ENDIF
ENDIF

; Add telemetry from Boulder for FM-2 if available
IF getenv('isis_data_boulder_minxss2') NE '' THEN BEGIN
  boulderMinxss2Files = file_search(getenv('isis_data_boulder_minxss2'), search_name, count = countBoulderMinxss2)
  IF countBoulderMinxss2 NE 0 THEN BEGIN
    file_list = [file_list, boulderMinxss2Files]
    count = count + countBoulderMinxss2
  ENDIF
ENDIF

; Add telemetry from HAM operators
IF getenv('ham_data') NE '' THEN BEGIN
  hamFiles = file_search(getenv('ham_data'), JPMyyyydoy2yyyymmdd(yyyydoy, /RETURN_STRING) + '*.dat', count = countHam)
  IF countHam NE 0 THEN BEGIN
    file_list = [file_list, hamFiles]
    count = count + countHam
  ENDIF
ENDIF

IF count EQ 0 THEN file_list = -1L

;
;	2. Set numfiles and Return the file list
;
numfiles = count
if keyword_set(verbose) then begin
  print, 'minxss_find_tlm_files: ', strtrim(numfiles,2), ' files found for date = ', yd_str
  ; stop, 'DEBUG ...'
endif

return, file_list
end
