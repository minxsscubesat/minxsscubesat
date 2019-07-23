;+
; NAME:
;   JPMRemoveTags.pro
;
; PURPOSE:
;   Removes tags from a structure or array of structures. Amazingly, IDL doesn't have a built in function for this and Exelis 
;   support said they have no plans to do so because structures are based on a low-level C library that doesn't support it. 
;   hashes and dictionaries are the replacement for structures to use in the future. They offer modern flexibility like removing
;   tags. 
;
; CATEGORY:
;   All (but developed originally for MinXSS Level 0D)
;
; CALLING SEQUENCE:
;   structure = JPMRemoveTags(structure, tagNamesArray)
;
; INPUTS:
;   structure [structure or array of structures]: The structure you want tag(s) removed from
;   tagNamesArray [strarr]:                       The tag name(s) you want removed e.g., ['TIME', 'APID', 'SEQ_FLAG']
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   outputStructure [same as structure input]: The same structure or array of structures as the input but with tags in tagNamesArray removed
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
;+
FUNCTION JPMRemoveTags, structure, tagNamesArray, $
                        VERBOSE = VERBOSE

;;
; Validity checks and defaults
;;

IF n_params() LT 2 THEN BEGIN
  message, /INFO, "USAGE: structure = JPMRemoveTags(structure, ['tag1', 'tag2', 'tag3']), etc with tags"
  return, -1
endif

;;
; Remove tags
;;

; Prepare outputStructure
outputStructure = !NULL

; Loop through array of structures (works even if it's only a single structure)
FOREACH structureArrayElement, structure DO BEGIN 
  hashTemporary = orderedhash(structureArrayElement, /EXTRACT)
  
  ; Loop through input tagNamesArray (works even if it's only a single tagName)
  FOREACH tagToRemove, tagNamesArray DO BEGIN
    IF hashTemporary.HasKey(tagToRemove) THEN BEGIN
      hashTemporary.Remove, tagToRemove 
    ENDIF
  ENDFOREACH
  outputStructure = [outputStructure, hashTemporary.ToStruct()]
  
ENDFOREACH ; array of structure loop

return, outputStructure
END