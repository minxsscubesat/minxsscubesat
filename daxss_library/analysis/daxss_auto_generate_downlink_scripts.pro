;+
; NAME:
;   daxss_auto_generate_downlink_scripts
;
; PURPOSE:
;   Look at the GOES event list for yesterday and generate downlink scripts by calling daxss_downlink_script for each flare
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the scripts to. Default is "~/" (home). 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   None directly, but puts scripts on disk in saveloc. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires internet access to get to the GOES FTP
;
; EXAMPLE:
;   Just run it! 
;-
PRO daxss_auto_generate_downlink_scripts, saveloc=saveloc
  
; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = '~/'
ENDIF
max_server_attempts = 10
num_server_errors = 0

; Get the events from yesterday
event_filename = 'ftp://ftp.swpc.noaa.gov/pub/indices/events/yesterday.txt'

catch, error_status

IF error_status NE 0 THEN BEGIN
  message, /INFO, JPMsystime() + ' Error index: ' + Error_status
  message, /INFO, 'Error message: ' + !ERROR_STATE.MSG
  num_server_errors++
  wait, 1
ENDIF

IF num_server_errors LT max_server_attempts THEN BEGIN
  events_filename = wget(event_filename)
ENDIF ELSE BEGIN
  message, /INFO, JPMsystime() + ' Attempted to read GOES events ' + JPMPrintNumber(max_server_attempts, /NO_DECIMALS) + ' times and failed. Skipping for today.'
  return
ENDELSE

restore, getenv('minxss_code') + '/daxss_library/analysis/goes_event_ascii_template.sav'
events = read_ascii(events_filename, template=goes_template)
openr, lun, events_filename, /GET_LUN
header = strarr(3)
readf, lun, header
close, lun
events_date = strmid(header[2], 7, 4) + '-' + strmid(header[2], 12, 2) + '-' + strmid(header[2], 15, 2)

; Filter for just flares
flare_indices = where(events.type EQ 'XRA', nflares)
IF nflares EQ 0 THEN BEGIN
  message, /INFO, 'No flares found for yestesrday. Come back tomorrow.'
  return
ENDIF
times = events.time_max[flare_indices]
class = strmid(events.particulars[flare_indices], 0, 4)

; Construct timestamp for each flare and generate downlink script
FOR i = 0, nflares - 1 DO BEGIN
  time_iso = events_date + 'T' + strmid(times[i], 0, 2) + ':' + strmid(times[i], 2, 2) + ':00Z'
  daxss_downlink_script, time_iso=time_iso, saveloc=saveloc, class=class[i]
ENDFOR

file_delete, events_filename
END
