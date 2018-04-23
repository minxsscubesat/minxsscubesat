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
;   end_date [long or string]:   Same as start_date but for the end date to process. 
;                                Defaults to today. 
;   fm [integer]: Set this to either 1 or 2 to indicate the flight model of MinXSS. Default is 1. 
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
; MODIFICATION HISTORY:
;   2016-07-16: Tom Woods:        Original code
;   2016-08-01: Tom Woods:        Updated for Level 0D and Level 1 processing
;   2016-10-31: James Paul Mason: Updated start_date and end_date to handle more than yyyydoy format automatically. 
;                                 Made those inputs actually optional as they were functionally already.  
;                                 Updated header for consistency and completeness. 
;                                 Changed FULL keyword to TO_0C_ONLY and reversed logic. 
;   2017-03-09: James Paul Mason: Added COPY_GOES keyword to copy GOES/XRS data on the Data Processing machine from /timed to Dropbox
;-
pro minxss_processing, start_date = start_date, end_date = end_date, fm=fm, $
                       DEBUG = DEBUG, TO_0C_ONLY = TO_0C_ONLY, COPY_GOES = COPY_GOES

TIC

; Defaults
IF start_date EQ !NULL THEN start_date = jd2yd(systime(/julian) - 5.)
IF end_date EQ !NULL THEN end_date = jd2yd(systime(/julian))
IF fm EQ !NULL THEN fm = 1
IF fm GT 2 THEN BEGIN
  message, /INFO, JPMsystime() + ' There are only two flight models of MinXSS. You have some wishful thinking.' 
  return
ENDIF

; Deal with time input 
IF isa(start_date, 'string') THEN start_date = JPMyyyymmdd2yyyydoy(start_date)
IF isa(end_date, 'string') THEN end_date = JPMyyyymmdd2yyyydoy(end_date)
start_jd = yd2jd(start_date)
end_jd = yd2jd(end_date)

MinXSS_name = 'MinXSS-'+strtrim(fm,2)

print, '***************************************************************'
print, ' '
print, 'Processing '+MinXSS_name+' L0B + L0C from ', start_date, ' to ', end_date
if keyword_set(full) then print, '        also processing L0D and L1'
print, ' '
print, '***************************************************************'
print, ' '
if keyword_set(debug) then stop, 'DEBUG minxss_processing at start...'

for jd=start_jd,end_jd,1.0 do begin
    yd = long(jd2yd(jd))
    minxss_make_level0b,yyyydoy=yd,fm=fm,/verbose,/force
    wait,1
endfor

print, ' '
if keyword_set(debug) THEN stop, 'DEBUG minxss_processing after L0B processing...'

print, '***************************************************************'
print, ' '
print, 'Processing '+MinXSS_name+' L0C and LOG for full mission'
print, ' '
print, '***************************************************************'

minxss_make_level0c,fm=fm,/verbose,/make_mission_length

minxss_make_mission_log,fm=fm,/verbose

IF ~keyword_set(TO_0C_ONLY) THEN BEGIN
  print, '***************************************************************'
  print, ' '
  print, 'Processing '+MinXSS_name+' L0D for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level0d, fm=fm, /verbose
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing '+MinXSS_name+' L1 for full mission'
  print, ' '
  print, '***************************************************************'
  minxss_make_level1, fm=fm, /verbose
  
  print, ' '
  print, '***************************************************************'
  print, ' '
  print, 'Processing '+MinXSS_name+' L3 for full mission'
  print, ' '
  print, '***************************************************************'
  IF keyword_set(COPY_GOES) THEN BEGIN
    file_copy, '/timed/analysis/goes/goes_1mdata_widx_20*.sav', getenv('minxss_data') + 'ancillary/goes/', /OVERWRITE
  ENDIF
  minxss_merge_level3, fm = fm, /VERBOSE ; TOOD: This should really be minxss_make_level3 but that can't yet handle the mission_length level1 file
ENDIF

if keyword_set(debug) THEN stop, 'DEBUG minxss_processing at end...'

message, /INFO, JPMsystime() + ' Processing completed in ' + JPMPrintNumber(toc(), /NO_DECIMALS) + ' seconds'

end

