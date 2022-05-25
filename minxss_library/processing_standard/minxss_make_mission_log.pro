;+
; NAME:
;   minxss_make_mission_log.pro
;
; PURPOSE:
;   Read all Level 0C data products and save the LOG packet messages in text file
;
; CATEGORY:
;    MinXSS Level 0C
;
; CALLING SEQUENCE:
;   minxss_make_mission_log, fm = fm
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]:           Flight Model number 1 or 2 (default is 1)
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages 
;
; OUTPUTS:
;   IDL .sav files in getenv('minxss_data')/fmX/log
;
; OPTIONAL OUTPUTS:
;   num_log    Optional output that provide number of log messages
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
; 	Requires minxss_find_files.pro
;	  Requires minxss_filename_parts.pro
;	  Uses the MinXSS convenience_functions_generic routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Find all Level 0C files (minxss_find_files.pro)
;   2. Read all of the Level 0C files
;	  5. Save the log messages into text file
;
; MODIFICATION HISTORY:
;	2016/02/29: Tom Woods: Original Code
;
;;+
PRO minxss_make_mission_log, fm=fm, VERBOSE=VERBOSE

;
;	check for valid input parameters
;
IF ~keyword_set(fm) THEN BEGIN
  fm = 1
ENDIF

start_year = 2016
if (fm eq 2) then start_year = 2017

;
;   1. Find all Level 0C files (minxss_find_files.pro)
;
fileNamesArray = minxss_find_files( 'L0C', fm=fm, numfiles=numfiles, verbose=verbose )
IF numfiles lt 1 THEN BEGIN
    message, /info, 'ERROR: minxss_make_mission_log can not find the Level 0C files'
    return
ENDIF
; Isolate the mission-length log file
k = where(strpos(fileNamesArray, 'all_mission_length') NE -1, numfiles)
fileNamesArray = fileNamesArray[k]

;
; open the Mission-long LOG file
;
log_dir = getenv('minxss_data') + '/fm'+strtrim(fm,2)+'/log/'
log_file = 'minxss' + strtrim(fm,2) + '_mission_log.txt'
if keyword_set(verbose) then begin
   message, /info, 'minxss_make_mission_log: LOG file = ' + log_dir+log_file
   message, /info, '                         Processing ' + strtrim(numfiles,2) + ' files...'
endif
openw, lun, log_dir + log_file, /get_lun
printf,lun, 'YYYY-MM-DD DOY hh:mm:ss ---------------- LOG MESSAGE ------------------'
log_cnt = 0L

;
;	BIG LOOP for each file that needs processing
;
; TODO FIXME
; TODO FIXME: Clean up this code, above and below -- there's only one file we're processing now!!!
; TODO FIXME
for k=0L,numfiles-1 do begin
  ;
  ;   Get the HK packets from each file and extract the LOG messages
  ;
  restore, fileNamesArray[k]
  IF keyword_set(verbose) THEN message, /info, "Restoring file " + fileNamesArray[k] + " ..."

  num_log = n_elements(log)
  for i=0,num_log-1 do begin
    timejd = gps2jd(log[i].time)
    timeyd = jd2yd(timejd)
    caldat, timejd, Month, Day, Year, Hour, Minute, Second
    DOY = long(timeyd) mod 1000L
    if year ge start_year then begin
      timestr = string(long(Year),format='(I04)') + '-' + string(long(Month),format='(I02)') + $
              '-' + string(long(Day),format='(I02)') + ' ' + string(DOY,format='(I03)') + $
              ' ' + string(long(Hour),format='(I02)') + ':' + string(long(Minute),format='(I02)') + $
              ':' + string(long(Second),format='(I02)')
      printf,lun, timestr + ' ' + log[i].message
      log_cnt += 1
    endif
  endfor
  ; Kill the log variable, we don't want it to persist to the next file...
  log = !NULL
;
;	END of BIG LOOP
;
endfor

;
;  close the LOG file
; 
close, lun
free_lun, lun

if keyword_set(verbose) then begin
  print, '                         Number of LOG msg = ', strtrim(log_cnt,2)
endif

;STOP

END
