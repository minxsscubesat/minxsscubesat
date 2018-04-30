;+
; NAME:
;   read_surfer_data
;
; PURPOSE:
;   Read a SURFER text file and return an array of structures, with each element in the array a point in time and each column a tag in the structure.
;
; INPUTS:
;   filename [string]: The SURFER file to process
;
; OPTIONAL INPUTS:
;   template_filename [string]: The filename of the .sav file containing the template for reading SURFER files.
;                               Default is '~/Dropbox/minxss_dropbox/code/surf_analysis/surfer_read_template.sav'
;
; KEYWORD PARAMETERS:
;   GENERATE_NEW_TEMPLATE: Set this to generate a new template for reading the SURFER file. You'll need to do this if the format of the SURFER
;                          txt file changes.
;   DO_NOT_ADD_TIMES:      Set this to prevent additional time formats from being added to the structure. 
;   
; OUTPUTS:
;   surfer [arr of str]: Each element in the array is a point in time of the SURFER file (the rows) and each column is a tag in the structure.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   surfer = read_surfer_data(surfer_filename)
;
; MODIFICATION HISTORY:
;   2018-03-29: James Paul Mason: Initial script
;-
FUNCTION read_surfer_data, filename, $
                           template_filename=template_filename, $
                           GENERATE_NEW_TEMPLATE=GENERATE_NEW_TEMPLATE, DO_NOT_ADD_TIMES=DO_NOT_ADD_TIMES

; Defaults
IF template_filename EQ !NULL THEN BEGIN
  template_filename = '~/Dropbox/minxss_dropbox/code/surf_analysis/surfer_read_template.sav'
ENDIF

; Get the template for reading the SURFER file
IF keyword_set(GENERATE_NEW_TEMPLATE) THEN BEGIN
  surfer_template = ascii_template(filename)
  message, /INFO, 'WARNING: Make sure that all your negative signs were captured. James noticed that pitch_deg cut off the negative sign. Solution was to manually change surfer_template.fieldlocations[6] = 58 instead of 59 to recapture that negative sign.'
  save, surfer_template, FILENAME = template_filename
ENDIF ELSE BEGIN
  restore, template_filename
ENDELSE

; Read in the SURFER file
surfer_temp = read_ascii(filename, template=surfer_template, data_start=2)

; Convert from a structure of arrays to an array of structures
tnames = tag_names(surfer_temp)
surfer = create_struct(tnames[0], (surfer_temp.(0))[0])
FOR t = 1L, n_tags(surfer_temp) - 1L DO BEGIN
   surfer = create_struct(surfer, tnames[t], (surfer_temp.(t))[0])
ENDFOR
surfer = replicate(surfer, n_elements(surfer_temp.(0)))
FOR t = 0L, n_tags(surfer_temp) - 1L DO BEGIN
   surfer.(t) = surfer_temp.(t)
ENDFOR

IF NOT keyword_set(DO_NOT_ADD_TIMES) THEN BEGIN
  ; Format ISO time
  yyyy = '20' + strmid(surfer.date, 6, 2)
  mm = strmid(surfer.date, 0, 2)
  dd = strmid(surfer.date, 3, 2)
  hh = strmid(surfer.time, 0, 2)
  minute = strmid(surfer.time, 3, 2)
  ss = strmid(surfer.time, 6, 6)
  iso = yyyy + '-' + mm + '-' + dd + 'T' + hh + ':' + minute + ':' + ss + 'Z'
  iso_temp = iso ; Avoid losing iso when running through JPMiso2jd
  
  ; Format julian date
  jd = JPMiso2jd(iso_temp)
  
  ; Format human time
  human = yyyy + '-' + mm + '-' + dd + ' ' + hh + ':' + minute + ':' + strmid(surfer.time, 6, 2)
  
  ; Format second of day
  sod = JPMjd2sod(jd)
  
  ; Format time yyyydoy
  yyyydoy = jd2yd(jd)
  
  ; Add new times to surfer structure
  surfer = JPMAddTagsToStructure(surfer, 'sod', 'long')
  surfer.sod = sod
  surfer = JPMAddTagsToStructure(surfer, 'yyyydoy', 'long')
  surfer.yyyydoy = yyyydoy
  surfer = JPMAddTagsToStructure(surfer, 'jd', 'double')
  surfer.jd = jd
  surfer = JPMAddTagsToStructure(surfer, 'iso', 'string')
  surfer.iso = iso
  surfer = JPMAddTagsToStructure(surfer, 'human', 'string')
  surfer.human = human
ENDIF

return, surfer
END