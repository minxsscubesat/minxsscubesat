;+
; NAME:
;   minxss_processing
;
; PURPOSE:
;   Process MinXSS-1 Level 0B, 0C, merged log, and optional level 0D and 1
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   start_date [long or string]: First date of data to process in either yyyydoy long format (e.g., 2016137L) or yyyymmdd string format (e.g., '20160516'). 
;                                Defaults to 5 days ago. 
;   end_date [long or string]:   Same as start_date but for the end date to process (e.g., 20170507). 
;                                Defaults to today. 
;   fm [integer]:                Set this to either 1 or 2 to indicate the flight model of MinXSS. Default is 1. 
;
; KEYWORD PARAMETERS:
;   DEBUG:      Set this to trigger stop statements in the code in good locations for debugging
;   TO_0C_ONLY: Set this to process up to level 0C only. Defaults to processing all the way to level 1. 
;
; OUTPUTS:
;   None directly, but each level of processing generates IDL savesets on disk
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code package
;
; EXAMPLE:
;   Just run it! 
;
;-
PRO minxss_processing, start_date = start_date, end_date = end_date, fm = fm, $
                       DEBUG = DEBUG, TO_0C_ONLY = TO_0C_ONLY, COPY_GOES = COPY_GOES

TIC

; Defaults
IF start_date EQ !NULL THEN start_date = jd2yd(systime(/JULIAN) - 5.)
IF end_date EQ !NULL THEN end_date = jd2yd(systime(/JULIAN) + 1.)
IF fm EQ !NULL THEN fm = 2
IF fm GT 3 THEN BEGIN
  message, /INFO, JPMsystime() + ' There are only two flight models of MinXSS. You have some wishful thinking.' 
  return
ENDIF

; Deal with time input 
IF isa(start_date, 'string') THEN start_date = JPMyyyymmdd2yyyydoy(start_date)
IF isa(end_date, 'string') THEN end_date = JPMyyyymmdd2yyyydoy(end_date)
start_jd = yd2jd(start_date)
end_jd = yd2jd(end_date)

MinXSS_name = 'MinXSS-' + strtrim(fm, 2)

print, '***************************************************************'
print, ' '
print, 'Processing ' + MinXSS_name + ' L0B + L0C from ', start_date, ' to ', end_date
if keyword_set(full) then print, '        also processing L0D and L1'
print, ' '
print, '***************************************************************'
print, ' '
if keyword_set(debug) then stop, 'DEBUG minxss_processing at start...'

for jd=start_jd, end_jd, 1.0 do begin
    yd = long(jd2yd(jd))
    minxss_make_level0b, fm=fm, yyyydoy=yd, /VERBOSE
    wait, 1
endfor

print, ' '
if keyword_set(debug) THEN stop, 'DEBUG minxss_processing after L0B processing...'

print, '***************************************************************'
print, ' '
print, 'Processing ' + MinXSS_name + ' L0C and LOG for full mission'
print, ' '
print, '***************************************************************'

minxss_make_level0c, fm=fm, /VERBOSE, /MAKE_MISSION_LENGTH

minxss_make_mission_log, fm=fm, /VERBOSE

IF ~keyword_set(TO_0C_ONLY) THEN BEGIN
  print, '***************************************************************'
  print, ' '
  print, 'Processing ' + MinXSS_name + ' L0D for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level0d, fm=fm, /VERBOSE
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing ' + MinXSS_name + ' L1 for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level1, fm=fm, /VERBOSE
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing ' + MinXSS_name + ' L2 for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level2, fm=fm, /VERBOSE
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing ' + MinXSS_name + ' L3 for full mission'
  print, ' '
  print, '***************************************************************'
  IF keyword_set(COPY_GOES) THEN BEGIN
    file_copy, '/timed/analysis/goes/goes_1mdata_widx_20*.sav', getenv('minxss_data') + 'ancillary/goes/', /OVERWRITE
  ENDIF
  minxss_make_level3, fm=fm, /VERBOSE
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing ' + MinXSS_name + ' L4 for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level4, fm=fm, /VERBOSE
ENDIF

if keyword_set(debug) THEN stop, 'DEBUG minxss_processing at end...'

message, /INFO, JPMsystime() + ' Processing completed in ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'

END

