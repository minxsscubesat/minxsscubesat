;+
; NAME:
;   JPMiso2jd
;
; PURPOSE:
;   Convert ISO-8601 standard of yyyy-mm-ddThh:mm:ssZ e.g, 2016-06-13T16:50:02Z to julian date (jd). 
;   This assumes that iso is already converted to UTC. 
;   Really this is just a wrapper for JPMyyyymmddhhmmss2jd to handle the T and Z
;
; INPUTS:
;   iso [string / strarr]: Standard ISO style time e.g, yyyy-mm-ddThh:mm:ssZ or human format yyyy-mm-dd hh:mm:ss
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   jd [double / dblarr]: Time in ISO-8601 standard of yyyy-mm-ddThh:mm:ssZ e.g, 2016-06-13T16:50:02Z
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires mjd2date from solarsoft, which probably itself requires other programs.
;   MinXSS standard package includes all necessary code for this to work.
;
; EXAMPLE:
;   timeJd = JPMiso2jd('2016-10-11T5:03Z')
;
; MODIFICATION HISTORY:
;   2016-10-11: James Paul Mason: Wrote script
;-
FUNCTION JPMiso2jd, iso

humanTime = iso

; Loop through all elements of iso (still works if iso is only one element) and remove the T and Z if they are there
IF strmatch(iso[0], 'T') THEN BEGIN
  FOR i = 0, n_elements(iso) - 1 DO BEGIN
    humanTime[i] = iso[i].replace('T', ' ') 
    humanTime[i] = iso[i].replace('Z', '')
  ENDFOR
ENDIF
humanTime = temporary(iso)

return, JPMyyyymmddhhmmss2jd(humanTime)

END