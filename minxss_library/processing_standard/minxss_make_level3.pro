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
;   fm [integer]:     Flight Model number 1 or 2 (default is 1)
;   version [string]: Set this to specify a particular level 1 file to restore for filtering. 
;                     Defaults to '' (nothing), which is intended for situations where you've 
;                     just processed level 1 but haven't yet appended a version number to the filename. 
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
PRO minxss_make_level3, fm=fm, version=version, $
                        VERBOSE=VERBOSE

; Defaults and validity checks - fm
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  message, /INFO, JPMsystime() + " ERROR: need a valid 'fm' value. FM can be 1 or 2."
  return
endif
IF version EQ !NULL THEN version = ''
IF ~isA(version, 'string') THEN BEGIN
  message, /INFO, JPMsystime() + " ERROR: version input must be a string"
  return
ENDIF

restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level1/minxss' + strtrim(fm, 2) + '_l1_mission_length_v' + version + '.sav'

message, /INFO, JPMsystime() + " Creating Level 3 data for FM-" + strtrim(fm, 2) + ": daily average of level 1"
minxss_make_level1_xminute, fm=fm, VERBOSE=VERBOSE, x_minute_average=1440, version=version, cal_version=cal_version, $
                            minxsslevel1_x123_time_structure=minxsslevel1.x123.time, minxsslevel1_x123_dark_time_structure=minxsslevel1.x123_dark.time, $
                            minxsslevel1_xp_time_structure=minxsslevel1.xp.time, minxsslevel1_xp_dark_time_structure=minxsslevel1.xp_dark.time

; Move the generated files to the Level 3 folder
level1Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level1/'
level3Folder = getenv('minxss_data') + 'fm' + strtrim(fm, 2) + '/level3/'
file_move, level1Folder + '*1440_minute_mission_length_v' + version + '.sav', level3Folder + 'minxss'+ strtrim(fm, 2) +'_l3_1day_average_mission_length_v' + version + '.sav', /OVERWRITE

; Rename the structures in the files from minxsslevel1* to minxsslevel3*
minxss_rename_level_structure, level3Folder + 'minxss' + strtrim(fm, 2) + '_l3_1day_average_mission_length_v' + version + '.sav', newlevel = 3

message, /INFO, JPMsystime() + " All done!"
END
