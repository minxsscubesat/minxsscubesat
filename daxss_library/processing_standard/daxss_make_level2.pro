;+
; NAME:
;   daxss_make_level2.pro
;
; PURPOSE:
;   Read Level 1 data product and make sub-day average data structure to produce Level 2.
;
; INPUTS:
;   None required
;
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 3 (default is 3)
;   version [string]: Set this to specify a particular level 1 file to restore for filtering.
;                     Defaults to '' (nothing), which is intended for situations where you've
;                     just processed level 1 but didn't specify `version` in your call to daxss_make_level1.
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   None
;
; OPTIONAL OUTPUTS
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires daxss_make_x123_average.pro
;   Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Call daxss_make_x123_average for each time average desired (1 minute, 1 hour)
;   2. Move the files it generates to the Level 2 folder
;+
PRO daxss_make_level2new, fm = fm, version = version, $
                        VERBOSE = VERBOSE

print, 'USE INSTEAD daxss_make_x123_average.pro directly to make L2 and L3 files!'
stop, 'IDL STOPPED...'

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 3
if (fm gt 3) or (fm lt 3) then begin
  message, /INFO, JPMsystime() + "WARNING: Changing 'fm' value to 3."
  fm = 3
endif
fm_str = strtrim(fm,2)

IF version EQ !NULL THEN version = '2.0.0'
IF ~isA(version, 'string') THEN BEGIN
  message, /INFO, JPMsystime() + " ERROR: version input must be a string"
  return
ENDIF

ddir1 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level1' + path_sep()
file1 = 'daxss' + '_l1_mission_length_v' + version + '.sav'
; restore, ddir1+file1

message, /INFO, JPMsystime() + " Creating Level 2 data for FM-" + strtrim(fm, 2) + ": time averages of level 1 for 1 minute and 1 hour"

daxss_make_x123_average, fm=fm, version=version, average_minutes=1, VERBOSE=VERBOSE

daxss_make_x123_average, fm=fm, version=version, average_minutes=60, VERBOSE=VERBOSE

; Move the generated files to the Level 2 folder
ddir2 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level2' + path_sep()

file_move, ddir1 + '*1_minute_mission_length_v' + version + '.sav', ddir2 + 'daxss' + '_l2_1minute_average_mission_length_v' + version + '.sav', /OVERWRITE
file_move, ddir1 + '*60_minute_mission_length_v' + version + '.sav', ddir2 + 'daxss' + '_l2_1hour_average_mission_length_v' + version + '.sav', /OVERWRITE

; Rename the structures in the files from daxsslevel1* to daxsslevel2*
daxss_rename_level_structure, ddir2 + 'daxss' + '_l2_1minute_average_mission_length_v' + version + '.sav', newlevel = 2
daxss_rename_level_structure, ddir2 + 'daxss' + '_l2_1hour_average_mission_length_v' + version + '.sav', newlevel = 2

message, /INFO, JPMsystime() + "Level 2 Processing is all done!"
END
