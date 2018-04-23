;+
; NAME:
;   JPMScientificNotation
;
; PURPOSE:
;   Convert a big number to normal looking scientific notation e.g., 3.2e42 -> 3.2 x 10^42 (where the ^42 is actually a superscript)
;   for plots. Compatible with all IDL plot() and related functions.
;
; INPUTS:
;   bigNumber: A number of any type (float, string, double) to be converted
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Returns a string that can be used in IDL plotting functions (e.g., plot() and text()) to get expected beahvior. 
;   Viewing the actual string outside of a plotting function, it will have the form e.g., '$3.2 \times 10^{42}$'. 
;   IDL plot() and related functions interpret the above LaTeX style math and displays it as expected. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   scientificNumber = JPMScientificNotation(3.2e42)
;
; MODIFICATION HISTORY:
;   2016/01/25: James Paul Mason: Wrote script.
;-
FUNCTION JPMScientificNotation, bigNumber

; Get bigNumber into a string if not already
IF ~isA(bigNumber, /STRING) THEN bigNumber = strtrim(bigNumber, 2)

; Make sure bigNumber is in the 'e' string format
bigNumber = strtrim(string(bigNumber, format = '(e)'), 2)

; Determine base
base = strmid(bigNumber, 0, 5)
base = strmid(strtrim(round(float(base) * 100d) / 100d, 2), 0, 4) ; rounded to 2 decimals

; Determine exponent
ePosition = strpos(bigNumber, 'e')
fullExponent = strmid(bigNumber, ePosition + 1, (strlen(bigNumber) - 1) - (ePosition - 1))

; Don't include a + in the exponent but do include a - if applicable
IF strmid(fullExponent, 0, 1) EQ '-' THEN BEGIN
  ; Don't include a leading 0 if exponent < 10
  IF strmid(fullExponent, 1, 1) EQ '0' THEN exponent = strmid(fullExponent, 0, 1) + strmid(fullExponent, 2, strlen(fullExponent) - 1) ELSE $
                                            exponent = fullExponent
ENDIF ELSE BEGIN
  exponent = strmid(fullExponent, 1, strlen(fullExponent) -1)
  
  ; Don't include a leading 0 if exponent < 10
  IF strmid(fullExponent, 1, 1) EQ '0' THEN exponent = strmid(exponent, 1, strlen(exponent) - 1)
ENDELSE

return,  '$' + base + ' \times 10^{' + exponent + '}$'

END