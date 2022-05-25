;+
; NAME:
;   daxss_flatten_structure_for_netcdf
;
; PURPOSE:
;   netCDF (or at least our implementation of it) can't handle 3 nested structures so we must flatten it to 2
;
; INPUTS:
;   filename [string]: The path and filename of the .sav file to change the structure names
;
; OPTIONAL INPUTS:
;   level [integer]: The data product level. Can be either 1 or 3. Default is 1.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   daxss_data_structure [structure]: Returns a structure with only 2 levels of nesting rather than 3
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires daxss code suite and access to the filename
;
; EXAMPLE:
;   daxsslevel3 = daxss_flatten_structure_for_netcdf('/Users/daxss/Dropbox/daxss_dropbox/data/fm1/level3/daxss1_l3_1day_average_mission_length.sav')
;-
FUNCTION daxss_flatten_structure_for_netcdf, structure

x123_time = structure.x123.time
x123 = rem_tag(structure.x123, 'time')

x123_dark_time = structure.x123_dark.time
x123_dark = rem_tag(structure.x123_dark, 'time')

xp_time = structure.xp.time
xp = rem_tag(structure.xp, 'time')

xp_dark_time = structure.xp_dark.time
xp_dark = rem_tag(structure.xp_dark, 'time')

return, create_struct('x123', x123, 'x123_time', x123_time, $
  'x123_dark', x123_dark, 'x123_dark_time', x123_dark_time, $
  'xp', xp, 'xp_time', xp_time, $
  'xp_dark', xp_dark, 'xp_dark_time', xp_dark_time)

END