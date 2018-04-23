;+
; NAME:
;   JPMhhmmss2Fod
;
; PURPOSE:
;   Convert time in hhmmss format to a fraction of day    
;
; INPUTS:
;   hhmmss [string]: Time in hh:mm:ss format (colons expected, e.g., '11:24:50' NOT '112450')
;                    Fraction of second will be truncated, e.g., '11:24:50.842' -> '11:24:50' 
;                    but should have minimal impact on fraction of day anyway
;                    Can be an array of strings. 
;                    
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this keyword to return a string rather than the default float
;
; OUTPUTS:
;   fod [float or optionally string]: Fraction of day corresponding to the input hh:mm:ss time
;                                     Return an array if the input was an array
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   fod = JPMhhmmss2Fod('14:51:23')
;
; MODIFICATION HISTORY:
;   2016/02/05: James Paul Mason: Wrote script.
;-
FUNCTION JPMhhmmss2Fod, hhmmss

fod = !NULL
FOR i = 0, n_elements(hhmmss) - 1 DO BEGIN 
  
  ; Parse hhmmss into hh, mm, ss
  hh = strmid(hhmmss[i], 0, 2)
  mm = strmid(hhmmss[i], 3, 2)
  ss = strmid(hhmmss[i], 6, 2) 
  
  ; Convert times so everything's in seconds and float, then add 'em up!
  hhInSeconds = float(hh) * 3600. 
  mmInSeconds = float(mm) * 60.
  ssInSeconds = float(ss)
  timeInSeconds = hhInSeconds + mmInSeconds + ssInSeconds
  
  ; Compute fraction of day
  fod = [fod, timeInSeconds / 86400.]
ENDFOR 

IF keyword_set(RETURN_STRING) THEN return, strtrim(fod, 2) ELSE $
                                   return, fod

END