;+
; NAME:
;   minxss_rename_level3_structure
;
; PURPOSE:
;   Rename the structures that minxss_make_level1_xminute.pro produces from minxsslevel1* to minxsslevel3*
;
; INPUTS:
;   filename [string]: The path and filename of the .sav file to change the structure names
;
; OPTIONAL INPUTS:
;   None
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
;   minxss_rename_level3_structure, '/Users/minxss/Dropbox/minxss_dropbox/data/fm1/level3/minxss1_l3_1day_average_mission_length.sav'
;-
PRO minxss_rename_level3_structure, filename

restore, filename

x123 = temporary(minxsslevel1_x123)
x123_dark = temporary(minxsslevel1_x123_dark)
x123_meta = temporary(minxsslevel1_x123_meta)

xp = temporary(minxsslevel1_xp)
xp_dark = temporary(minxsslevel1_xp_dark)
xp_meta = temporary(minxsslevel1_xp_meta)

minxsslevel3 = create_struct('x123', x123, 'x123_dark', x123_dark, 'x123_meta', x123_meta, $
                             'xp', xp, 'xp_dark', xp_dark, 'xp_meta', xp_meta)

save, minxsslevel3, filename = filename

END