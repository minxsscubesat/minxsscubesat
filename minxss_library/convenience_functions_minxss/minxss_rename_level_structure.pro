;+
; NAME:
;   minxss_rename_level_structure
;
; PURPOSE:
;   Rename the structures that minxss_make_level1_xminute.pro produces from minxsslevel1* to minxsslevel3*
;
; INPUTS:
;   filename [string]: The path and filename of the .sav file to change the structure names
;
; OPTIONAL INPUTS:
;   newlevel [integer]: It was called now minxsslevel1. Now it should be called minxsslevel#. What is #? Default is 2.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Replaces the filename .sav array with a new one where the structures inside have been renamed
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code suite and access to the filename
;
; EXAMPLE:
;   minxss_rename_level_structure, '/Users/minxss/Dropbox/minxss_dropbox/data/fm1/level3/minxss1_l3_1day_average_mission_length.sav', newlevel = 3
;-
PRO minxss_rename_level_structure, filename, newlevel=newlevel

; Defaults
IF newlevel EQ !NULL THEN BEGIN
  newlevel = 2
ENDIF

restore, filename

x123 = temporary(minxsslevel1_x123)
x123_dark = temporary(minxsslevel1_x123_dark)
x123_meta = temporary(minxsslevel1_x123_meta)

xp = temporary(minxsslevel1_xp)
xp_dark = temporary(minxsslevel1_xp_dark)
xp_meta = temporary(minxsslevel1_xp_meta)

newstruct = create_struct('x123', x123, 'x123_dark', x123_dark, 'x123_meta', x123_meta, $
                          'xp', xp, 'xp_dark', xp_dark, 'xp_meta', xp_meta)

IF newlevel EQ 2 THEN BEGIN
  minxsslevel2 = temporary(newstruct)
  save, minxsslevel2, filename = filename
ENDIF ELSE IF newlevel EQ 3 THEN BEGIN
  minxsslevel3 = temporary(newstruct)
  save, minxsslevel3, filename = filename
ENDIF ELSE BEGIN
  message, /INFO, JPMsystime() + ' You provided a new level of ' + strtrim(newlevel, 2) + ' but only values of 2 or 3 are supported.'
ENDELSE

END