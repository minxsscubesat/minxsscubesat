;+
; NAME:
;   goes_flare_events.pro
;
; PURPOSE:
;   Get a list of flare events for a given date
;
; INPUTS:
;   date_iso [string]: The date you want to look for flares in ISO format (yyyy-mm-dd), e.g., '2022-04-10'.
;	/verbose		Option to print debug messages
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Structure data array
;
; RESTRICTIONS:
;   Requires internet access to get to the GOES FTP
;
; EXAMPLE:
;   flare_list = goes_flare_events( '2022-10-02' )
;
; HISTORY:
;	10/11/2022		Tom Woods, Revision of James Mason's daxss_auto_generate_downlink_scripts.pro
;-
FUNCTION goes_flare_events, date_iso, class_min=class_min, verbose=verbose

; Check inputs
IF n_params() lt 1 THEN BEGIN
  date_iso = 'yesterday'
  filename = 'yesterday.txt'
ENDIF ELSE BEGIN
  filename = strmid(date_iso, 0, 4) + strmid(date_iso, 5, 2) + strmid(date_iso, 8, 2) + 'events.txt'
ENDELSE

if not keyword_set(class_min) then class_min='C1'

; make output data list
flare_list1 = { date: date_iso, time: ' ', class: ' ' }
flare_list = flare_list1
max_server_attempts = 10
num_server_errors = 0

; Get the events from yesterday
event_filename = 'ftp://ftp.swpc.noaa.gov/pub/indices/events/' + filename

catch, error_status

IF error_status NE 0 THEN BEGIN
  message, /INFO, '*** Error index: ' + strtrim(Error_status, 2)
  message, /INFO, 'Error message: ' + !ERROR_STATE.MSG
  num_server_errors++
  wait, 1
ENDIF

IF num_server_errors LT max_server_attempts THEN BEGIN
  events_filename = wget(event_filename)
ENDIF ELSE BEGIN
  if keyword_set(verbose) then begin
  	message, /INFO, '*** Attempted to read GOES events ' + strtrim(max_server_attempts, 2) + ' times and failed.'
  	stop, 'DEBUG error in reading GOES Events ...'
  endif
  return, flare_list
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
  if keyword_set(verbose) then message, /INFO, '*** No flares found for '
  return, flare_list
ENDIF
times = events.time_max[flare_indices]
class = strmid(events.particulars[flare_indices], 0, 4)

;  make flare_list to return
if keyword_set(verbose) then message, /INFO, '*** Number of flares = ',strtrim(nflares,2)
flare_list = replicate( flare_list1, nflares )

; Construct timestamp for each flare
FOR i = 0, nflares - 1 DO BEGIN
  IF (class[i] LT class_min) THEN CONTINUE
  time_iso = strmid(times[i], 0, 2) + ':' + strmid(times[i], 2, 2) + ':00Z'
  flare_list[i].time = time_iso
  flare_list[i].class=class[i]
ENDFOR

; return the flare_list as the OUTPUT
return, flare_list
END
