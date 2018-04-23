;+
; NAME:
;   ParsePathAndFilename
;
; PURPOSE:
;   Function to parse a path/filename into a structure containing the path and the filename
;
; INPUTS:
;   combined [string]: The string with the path and filename combined
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Returns structure with parameters: 
;     path [string]: Just the path to the file
;     filename [string]: Just the filename
;     absolute [integer]: A flag, 0: a relative path, 1: an absolute path
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   parsedFilename = ParsePathAndFilename('/Users/jama6159/Dropbox/Development/IDLWorkspace85/minxss_trunk/src/convenience_functions_generic/utilities/parsepathandfilename.pro')
;
; MODIFICATION HISTORY:
;   2012-03-01: James Paul Mason: Wrote script.
;   2016-05-27: Amir Caspi:       Added absolute tag to return structure
;-
FUNCTION ParsePathAndFilename, combined

; Get the position of the / separater
position = strpos(combined, '/', /reverse_search)

filename = strmid(combined, position+1)
path = strmid(combined, 0, position+1)
absolute = strpos(combined, '/') EQ 0

return, create_struct('path', path, 'filename', filename, 'absolute', absolute)

END