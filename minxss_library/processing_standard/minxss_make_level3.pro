;+
; NAME:
;   minxss_make_level3.pro
;
; PURPOSE:
;   Read Level 1 data product and make time average data structure to produce Level 3.
;
; INPUTS:
;   None required
;   
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 1 or 2 (default is 1)
;
; OPTIONAL INPUTS:
;	  None
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
;	  Requires minxss_find_files.pro
;	  Requires minxss_filename_parts.pro
;   Requires minxss_average_packets.pro
;	  Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Call minxss_make_level_xminute for each time average desired (1 minute, 1 hour, 1 day)
;   2. Move the files it generates to the Level 3 folder
;+
PRO minxss_make_level3, fm = fm, $
                        VERBOSE = VERBOSE

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  message, /INFO, JPMsystime() + "ERROR: minxss_make_level3 needs a valid 'fm' value.  FM can be 1 or 2."
  return
endif

message, /INFO, JPMsystime() + " Creating Level 3 data for FM-" + strtrim(fm, 2) + ": time averages of level 1 for 1 minute, 1 hour, and 1 day"
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=1
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=60
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=1440

; Move the generated files to the Level 3 folder
level1Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level1/'
level3Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level3/'
file_move, level1Folder + '*1_minute_mission_length.sav', level3Folder + 'minxss1_l3_1minute_average_mission_length.sav'
file_move, level1Folder + '*60_minute_mission_length.sav', level3Folder + 'minxss1_l3_1hour_average_mission_length.sav'
file_move, level1Folder + '*1440_minute_mission_length.sav', level3Folder + 'minxss1_l3_1day_average_mission_length.sav'

; Rename the structures in the files from minxsslevel1* to minxsslevel3*
minxss_rename_level3_structure, level3Folder + 'minxss1_l3_1minute_average_mission_length.sav'
minxss_rename_level3_structure, level3Folder + 'minxss1_l3_1hour_average_mission_length.sav'
minxss_rename_level3_structure, level3Folder + 'minxss1_l3_1day_average_mission_length.sav'

message, /INFO, JPMsystime() + " All done!"
END
