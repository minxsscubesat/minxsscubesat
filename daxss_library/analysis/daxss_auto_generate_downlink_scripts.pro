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
;   date_iso [string]: The date you want to look for flares in ISO format (yyyy-mm-dd), e.g., '2022-04-10'.
;                      If no value is provided, assume yesterday.
;   saveloc [string]:  The path to save the scripts to. Default is "~/" (home). 
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
PRO daxss_auto_generate_downlink_scripts, date_iso=date_iso, saveloc=saveloc
  
; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = '~/'
ENDIF
IF date_iso EQ !NULL THEN BEGIN
  filename = 'yesterday.txt'
ENDIF ELSE BEGIN
  filename = strmid(date_iso, 0, 4) + strmid(date_iso, 5, 2) + strmid(date_iso, 8, 2) + 'events.txt'
ENDELSE
max_server_attempts = 10
num_server_errors = 0

; Get the events from yesterday
event_filename = 'ftp://ftp.swpc.noaa.gov/pub/indices/events/' + filename

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

; Construct timestamp for each flare, generate downlink script, and add to a CSV log
FOR i = 0, nflares - 1 DO BEGIN
  time_iso = events_date + 'T' + strmid(times[i], 0, 2) + ':' + strmid(times[i], 2, 2) + ':00Z'
  daxss_downlink_script, time_iso=time_iso, saveloc=saveloc, class=class[i]
  openu, lun, saveloc + 'daxss_flare_list.txt', /GET_LUN, /APPEND 
  printf, lun, time_iso + ',' + class[i]
  free_lun, lun
ENDFOR

; Sort the flare list in case it gets out of order
restore, getenv('minxss_code') + '/daxss_library/analysis/flare_list_csv_template.sav'
flare_list = read_ascii(saveloc + 'daxss_flare_list.txt', template=flare_list_template)
sort_indices = sort(flare_list.peak_flare_time_iso)
flare_list.peak_flare_time_iso = flare_list.peak_flare_time_iso[sort_indices]
flare_list.flare_class = flare_list.flare_class[sort_indices]
write_csv_pp, saveloc + 'daxss_flare_list.txt', flare_list, /TITLESFROMFIELDS, /NOQUOTE

file_delete, events_filename
END
