;+
; NAME:
;   JPMmon2mm
;
; PURPOSE:
;   Convert a month name to a month number e.g., jan -> 01, or nov -> 11
;
; INPUTS:
;   mon [string]: The month name in standard 3 letter abbreviation: 
;                 jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec. 
;                 Case does not matter.  
;                 mon input can be an array of strings
;                 
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   mm [string]: The month converted to its numeric representation with filler zeros
;                If input was an array of strings, mm output will be an array of strings of the same length
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;   
; EXAMPLE:
;   mm = JPMmon2mm('jan')
;
; MODIFICATION HISTORY:
;   2016/02/05: James Paul Mason: Wrote script.
;-
FUNCTION JPMmon2mm, mon

mm = !NULL
FOR i = 0, n_elements(mon) - 1 DO BEGIN
  IF strcmp(mon[i], 'jan', /FOLD_CASE) THEN mm = [mm, '01']
  IF strcmp(mon[i], 'feb', /FOLD_CASE) THEN mm = [mm, '02']
  IF strcmp(mon[i], 'mar', /FOLD_CASE) THEN mm = [mm, '03']
  IF strcmp(mon[i], 'apr', /FOLD_CASE) THEN mm = [mm, '04']
  IF strcmp(mon[i], 'may', /FOLD_CASE) THEN mm = [mm, '05']
  IF strcmp(mon[i], 'jun', /FOLD_CASE) THEN mm = [mm, '06']
  IF strcmp(mon[i], 'jul', /FOLD_CASE) THEN mm = [mm, '07']
  IF strcmp(mon[i], 'aug', /FOLD_CASE) THEN mm = [mm, '08']
  IF strcmp(mon[i], 'sep', /FOLD_CASE) THEN mm = [mm, '09']
  IF strcmp(mon[i], 'oct', /FOLD_CASE) THEN mm = [mm, '10']
  IF strcmp(mon[i], 'nov', /FOLD_CASE) THEN mm = [mm, '11']
  IF strcmp(mon[i], 'dec', /FOLD_CASE) THEN mm = [mm, '12']
ENDFOR

return, mm

END