;+
; NAME:
;   JPMAddTagsToStructure
;
; PURPOSE:
;   Add tags to a structure
;
; INPUTS:
;   structure [structure]: The source structure to add tags to 
;   tagsToAdd [strarr]:    Names of tags to add as strings
;   valueType [string]:    The type for the value. Allowed values are: 
;                          'byte', 'bytarr'
;                          'int', 'intarr'
;                          'long', 'lonarr'
;                          'float', 'fltarr'
;                          'double', 'dblarr', 
;                          'string', 'strarr'. 
;                          If using any array type then MUST also provide numElements input. 
;
; OPTIONAL INPUTS:
;   insertIndex [integer]: Provide this to insert the new tag into the specified
;                          position rather than tacking it on at the end
;   numElements [integer]: The number of elements to use if valueType is an array. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Returns structure with new tags of values type added
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   hk = JPMAddTagsToStructure(hk, 'jd_time', 'double')
;
; MODIFICATION HISTORY:
;   2016-06-13: James Paul Mason: Wrote script.
;   2016-07-29: James Paul Mason: Added insertIndex optional input. Only works for single tag add for now. 
;   2016-12-01: James Paul Mason: Added array type input options and corresponding numElements input. 
;   2018-03-29: James Paul Mason: Added option for long and lonarr valueType
;-
FUNCTION JPMAddTagsToStructure, structure, tagsToAdd, valueType, $
                                numElements = numElements, insertIndex = insertIndex

; Defaults
IF valueType EQ !NULL THEN valueType = 0.0d ELSE $
IF valueType EQ 'byte' THEN valueType = byte(0) ELSE $
IF valueType EQ 'bytarr' THEN valueType = bytarr(numElements) ELSE $
IF valueType EQ 'int' THEN valueType = 0 ELSE $
IF valueType EQ 'intarr' THEN valueType = intarr(numElements) ELSE $
IF valueType EQ 'long' THEN valueType = 0L ELSE $
IF valueType EQ 'longarr' THEN valueType = lonarr(numElements) ELSE $
IF valueType EQ 'float' THEN valueType = 0.0 ELSE $ 
IF valueType EQ 'fltarr' THEN valueType = fltarr(numElements) ELSE $ 
IF valueType EQ 'double' THEN valueType = 0.0d ELSE $
IF valueType EQ 'dblarr' THEN valueType = dblarr(numElements) ELSE $
IF valueType EQ 'string' THEN valueType = '' ELSE $
IF valueType EQ 'strarr' THEN valueType = strarr(numElements)
IF insertIndex EQ !NULL THEN insertIndex = n_tags(structure)

; Get the names of all the tags
tagNames = tag_names(structure)

; Insert the new tag(s) at the insertIndex point
IF insertIndex EQ n_tags(structure)THEN tagNames = [tagNames, tagsToAdd] ELSE $
                                        tagNames = [tagNames[0:insertIndex - 1], tagsToAdd, tagNames[insertIndex:n_tags(structure)-1]]
newTags = {}

; Loop through all of the tags and add them to a new structure
FOR tagIndex = 0, n_elements(tagNames) - 1 DO BEGIN
  IF tagIndex LT insertIndex THEN newTags = create_struct(newTags, tagNames[tagIndex], structure[0].(tagIndex)) ELSE $
  IF tagIndex EQ insertIndex THEN newTags = create_struct(newTags, tagNames[tagIndex], valueType) ELSE $
  IF tagIndex GT insertIndex THEN newTags = create_struct(newTags, tagNames[tagIndex], structure[0].(tagIndex - n_elements(tagsToAdd)))
ENDFOR

; If input is an array of structures, make output one of equal number of array elements
structureArrayNewTags = replicate(create_struct(newTags), n_elements(structure))

; Can't do a direct =, so use struct_assign to get a relaxed copy of the input fields to output fields
struct_assign, structure, structureArrayNewTags

return, structureArrayNewTags

END