;+
; NAME:
;   minxss_make_level3.pro
;
; PURPOSE:
;   Read Level 1 data product and make daily average data structure to produce Level 3.
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
;   1. Call minxss_make_level_xminute for each daily average
;   2. Move the files it generates to the Level 3 folder
;+
PRO minxss_make_level3, fm = fm, $
                        VERBOSE = VERBOSE

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  message, /INFO, JPMsystime() + "ERROR: need a valid 'fm' value.  FM can be 1 or 2."
  return
endif

restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level1/minxss1_l1_mission_length_v2.sav'

message, /INFO, JPMsystime() + " Creating Level 3 data for FM-" + strtrim(fm, 2) + ": daily average of level 1"
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=1440, $
                            minxsslevel1_x123_time_structure=minxsslevel1.x123.time, minxsslevel1_x123_dark_time_structure=minxsslevel1.x123_dark.time, $
                            minxsslevel1_xp_time_structure=minxsslevel1.xp.time, minxsslevel1_xp_dark_time_structure=minxsslevel1.xp_dark.time

; Move the generated files to the Level 3 folder
level1Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level1/'
level3Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level3/'
file_move, level1Folder + '*1440_minute_mission_length.sav', level3Folder + 'minxss1_l3_1day_average_mission_length.sav', /OVERWRITE

; Rename the structures in the files from minxsslevel1* to minxsslevel3*
minxss_rename_level_structure, level3Folder + 'minxss1_l3_1day_average_mission_length.sav', newlevel = 3

message, /INFO, JPMsystime() + " All done!"
END
