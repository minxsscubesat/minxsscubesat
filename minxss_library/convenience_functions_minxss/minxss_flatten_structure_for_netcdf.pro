;+
; NAME:
;   minxss_flatten_structure_for_netcdf
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
;   minxss_data_structure [structure]: Returns a structure with only 2 levels of nesting rather than 3
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code suite and access to the filename
;
; EXAMPLE:
;   minxsslevel3 = minxss_flatten_structure_for_netcdf('/Users/minxss/Dropbox/minxss_dropbox/data/fm1/level3/minxss1_l3_1day_average_mission_length.sav')
;-
FUNCTION minxss_flatten_structure_for_netcdf, structure

x123 = structure.x123
x123 = JPMAddTagsToStructure(x123, 'time_tai', 'double')
x123.time_tai = structure.x123.time.tai
x123 = JPMAddTagsToStructure(x123, 'julian_date', 'double')
x123.julian_date = structure.x123.time.jd
x123 = rem_tag(x123, 'time')

x123_dark = structure.x123_dark
x123_dark = JPMAddTagsToStructure(x123_dark, 'time_tai', 'double')
x123_dark.time_tai = structure.x123_dark.time.tai
x123_dark = JPMAddTagsToStructure(x123_dark, 'julian_date', 'double')
x123_dark.julian_date = structure.x123_dark.time.jd
x123_dark = rem_tag(x123_dark, 'time')

xp = structure.xp
xp = JPMAddTagsToStructure(xp, 'time_tai', 'double')
xp.time_tai = structure.xp.time.tai
xp = JPMAddTagsToStructure(xp, 'julian_date', 'double')
xp.julian_date = structure.xp.time.jd
xp = rem_tag(xp, 'time')

xp_dark = structure.xp_dark
xp_dark = JPMAddTagsToStructure(xp_dark, 'time_tai', 'double')
xp_dark.time_tai = structure.xp_dark.time.tai
xp_dark = JPMAddTagsToStructure(xp_dark, 'julian_date', 'double')
xp_dark.julian_date = structure.xp_dark.time.jd
xp_dark = rem_tag(xp_dark, 'time')

return, create_struct('x123', x123, 'x123_dark', x123_dark, 'xp', xp, 'xp_dark', xp_dark)

END