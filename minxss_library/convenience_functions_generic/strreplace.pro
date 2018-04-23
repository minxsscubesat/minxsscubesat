FUNCTION strreplace, str, find, replace

;+
; NAME:
;	STRREPLACE
; PURPOSE:
;	Replace one or more parts of a string or array of strings.
;	(Note: ALL occurrences of searched-for substrings are replaced.)
; CALLING SEQUENCE:
;	new_string = strreplace, input_string, string(s)_to_find, string(s)_to_insert
;   Example:
;	file_template = 'data_<date>_<time>.txt'
;	filename = strreplace(file_template, ['<date>','<time>'], ['20110802','230143'])
; INPUTS:
;	STR      - input string, or array of strings, on which to perform search/replace
;	FIND     - string, or array of strings, to search for within STR
;	REPLACE  - string, or array of strings, to insert as replacements within STR
;		(NOTE: if FIND and REPLACE are arrays, they must have same length!)
; OPTIONAL INPUT PARAMETERS:
;	None.
; KEYWORD Parameters:
;	None.
; OUTPUTS:
;	Processed string (or array) is RETURNED; no input variables are modified.
; COMMON BLOCKS:
;	None.
; SIDE EFFECTS:
;	None.
; RESTRICTIONS:
;	If find/replace inputs are arrays, they must have same length.
;
; MODIFICATION HISTORY:
; 	08/2011 - Created (A.Caspi, LASP)
;-


if n_elements(find) ne n_elements(replace) then message, "ERROR - search and replacement arrays must be of equal length!"

; Copy input string -- end tag needed as kludge for replacement at end of str
uniq_tag = '<END_TAG_XYZABC>'
out = str + uniq_tag
; For each input string...
for i=0,n_elements(str)-1 do begin
   ; For each find/replace pair...
   for j=0,n_elements(find)-1 do begin
      ; Find all occurences of find[j] and replace with replace[j]
      out[i] = strjoin(strsplit(out[i], find[j], /reg, /ext), replace[j])
   endfor
   ; Remove end tag kludge
   out[i] = strsplit(out[i], uniq_tag, /reg, /ext)
endfor

return, out

END
