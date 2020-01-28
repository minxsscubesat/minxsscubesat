;+
; NAME:
;   minxss_make_level2.pro
;
; PURPOSE:
;   Read Level 1 data product and make sub-day average data structure to produce Level 2.
;
; INPUTS:
;   None required
;
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 1 or 2 (default is 1)
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
;   Requires minxss_find_files.pro
;   Requires minxss_filename_parts.pro
;   Requires minxss_average_packets.pro
;   Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Call minxss_make_level_xminute for each time average desired (1 minute, 1 hour)
;   2. Move the files it generates to the Level 2 folder
;+
PRO minxss_make_level2, fm = fm, $
                        VERBOSE = VERBOSE

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  message, /INFO, JPMsystime() + "ERROR: need a valid 'fm' value. FM can be 1 or 2."
  return
endif

message, /INFO, JPMsystime() + " Creating Level 2 data for FM-" + strtrim(fm, 2) + ": time averages of level 1 for 1 minute and 1 hour"
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=1
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=60

; Move the generated files to the Level 3 folder
level1Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level1/'
level2Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level2/'
file_move, level1Folder + '*1_minute_mission_length.sav', level2Folder + 'minxss1_l2_1minute_average_mission_length.sav', /OVERWRITE
file_move, level1Folder + '*60_minute_mission_length.sav', level2Folder + 'minxss1_l2_1hour_average_mission_length.sav', /OVERWRITE

; Rename the structures in the files from minxsslevel1* to minxsslevel3*
minxss_rename_level_structure, level2Folder + 'minxss1_l2_1minute_average_mission_length.sav', newlevel = 2
minxss_rename_level_structure, level2Folder + 'minxss1_l2_1hour_average_mission_length.sav', newlevel = 2

message, /INFO, JPMsystime() + " All done!"
END
