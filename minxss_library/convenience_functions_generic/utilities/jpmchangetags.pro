;+
; NAME:
;   JPMChangeTags.pro
;
; PURPOSE:
;   Changes tags in a structure or array of structures. Amazingly, IDL doesn't have a built in function for this and Exelis
;   support said they have no plans to do so because structures are based on a low-level C library that doesn't support it.
;   hashes and dictionaries are the replacement for structures to use in the future. They offer modern flexibility like removing
;   tags.
;
; CATEGORY:
;   All (but developed originally for MinXSS Level 0D)
;
; CALLING SEQUENCE:
;   structure = JPMChangeTags(structure, tagsTohange, newTagNames)
;
; INPUTS:
;   structure [structure or array of structures]: The structure you want tag(s) changed in
;   tagsToChange [strarr]:                        The tag name(s) you want changed e.g., ['TIME', 'APID', 'SEQ_FLAG']
;   newTagNames [strarr]:                         What you want the tag name(s) changed to e.g., 'UTC_TIME', 'APPLICATION_ID', 'SEQUENCE_FLAG']
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   outputStructure [same as structure input]: The same structure or array of structures as the input but with tags changed accordingly
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires IDL 8.3 or later
;
; MODIFICATION HISTORY:
;   2015/11/13: James Paul Mason: Write program.
;+
FUNCTION JPMChangeTags, structure, tagsToChange, newTagNames

;;
; Validity checks and defaults
;;

; Number of inputs needs to be at least 3
IF n_params() LT 3 THEN BEGIN
  message, /INFO, "USAGE: structure = JPMRemoveTags(structure, ['tag1', 'tag2', 'tag3']), etc with tags"
  return, -1
endif

; Need to have same number of tagsToChange as newTagNames
IF n_elements(tagsToChange) NE n_elements(newTagNames) THEN BEGIN
  message, /INFO, 'Input tagsToChange must have same number of elements as newTagNames'
  return, -1
ENDIF

;;
; Change tags
;;

; Prepare outputStructure
outputStructure = !NULL

; Loop through array of structures (works even if it's only a single structure)
ticObject = tic()
FOREACH structureArrayElement, structure DO BEGIN
  hashTemporary = orderedhash(structureArrayElement, /EXTRACT)
  hashNewNamesTemporary = orderedhash()
  
  ; Loop through input tag names (works even if it's only a single tagName)
  FOR tagsToChangeIndex = 0, n_elements(tagsToChange) - 1 DO BEGIN
    tagToChange = tagsToChange[tagsToChangeIndex] & newTagName = newTagNames[tagsToChangeIndex]
    IF hashTemporary.HasKey(strupcase(tagToChange)) THEN BEGIN
      FOREACH keyInHash, hashTemporary.keys() DO BEGIN
        IF keyInHash EQ tagToChange THEN BEGIN  
          hashNewNamesTemporary[newTagName] = hashTemporary[tagToChange]
          hashTemporary.Remove, tagToChange
        ENDIF ELSE BEGIN                         
          hashNewNamesTemporary[keyInHash]  = hashTemporary[keyInHash]
        ENDELSE
      ENDFOREACH
    ENDIF ELSE message, /INFO, systime() + 'Structure tag "' + tagToChange + '" does not exist in structure'    
  ENDFOR ; tagsToChange loop
  
  outputStructure = [outputStructure, hashNewNamesTemporary.ToStruct()]

ENDFOREACH ; array of structure loop

return, outputStructure

END