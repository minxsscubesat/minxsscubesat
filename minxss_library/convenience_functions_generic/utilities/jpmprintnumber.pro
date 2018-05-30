;+
; NAME:
;   JPMPrintNumber
;
; PURPOSE:
;   IDL likes to print numbers with tons of white space and an absurd number of decimals. This function deals with that. 
;
; INPUTS:
;   numberToFormat [float, double, fltarr, dblarr]: The number(s) you want converted to a string
;
; OPTIONAL INPUTS:
;   NUMBER_OF_DECIMALS [integer]: The number of decimal places to output. Default is 2. 
;
; KEYWORD PARAMETERS:
;   NO_DECIMALS: Set this to return a string number with no decimals
;   EXPONENT_FORM: Set this to return string in the form e.g., 2.42e-04
;   SCIENTIFIC_NOTATION: Set this to return string in the form $2.42 \times 10^{04}$ for use in IDL plotting (which uses LaTeX styles)
;
; OUTPUTS:
;   formattedNumber [string]: The number converted to a string and formatted to be reasonable
;
; OPTIONAL OUTPUTS:
;   NONE
;
; RESTRICTIONS:
;   NONE
;
; EXAMPLE:
;   sin45String = JPMPrintNumber(sin(45), NUMBER_OF_DECIMALS = 3)
;
; MODIFICATION HISTORY:
;   2012-07-05: James Paul Mason: Wrote procedure
;   2012-07-06: James Paul Mason: Added peanut butter and jelly
;   2015-04-24: James Paul Mason: If not a floating point number, then don't use a decimal value at all
;   2015-05-29: James Paul Mason: Added NO_DECIMALS keyword since setting NUMBER_OF_DECIMALS to 0 get interpreted as it being not set. 
;   2016-03-28: James Paul Mason: Implemented proper rounding of decimals
;   2016-04-27: James Paul Mason: Added EXPONENT_FORM and SCIENTIFIC_NOTATION keywords
;   2017-03-02: James Paul Mason: Can now handle array input for numbersToFormat
;   2018-04-25: James Paul Mason: Properly handle integer rounding when /NO_DECIMALS is set
;   2018-05-30: James Paul Mason: Fixed formatting for big numbers. 
;-
FUNCTION JPMPrintNumber, numbersToFormat, NUMBER_OF_DECIMALS = number_of_decimals, $
                         NO_DECIMALS = NO_DECIMALS, EXPONENT_FORM = EXPONENT_FORM, SCIENTIFIC_NOTATION = SCIENTIFIC_NOTATION

; Defaults
IF ~keyword_set(NUMBER_OF_DECIMALS) THEN number_of_decimals = 2

; Handle array input
formattedNumbers = !NULL
FOREACH numberToFormat, numbersToFormat DO BEGIN

  ; Do proper rounding
  numberToFormatRounded = round(numberToFormat * 10.^number_of_decimals) / 10.^number_of_decimals
  
  trimmed = strtrim(string(numberToFormat, format='(F20.10)'), 2)
  pos = strpos(trimmed, '.')
  IF pos NE [-1] THEN BEGIN
    IF ~keyword_set(NO_DECIMALS) THEN trimmed = strjoin(strmid(trimmed, 0, pos) + strmid(trimmed, pos, number_of_decimals + 1)) ELSE $
                                      trimmed = strtrim(long(round(float(trimmed))), 2)
  ENDIF
  
  IF keyword_set(EXPONENT_FORM) THEN BEGIN
    trimmed = string(numberToFormat, format = '(e9.2)')
  ENDIF
  
  ; Assumes exponent < 100
  IF keyword_set(SCIENTIFIC_NOTATION) THEN BEGIN
    exponentForm = string(numberToFormat, format = '(e11.2)')
    pos_e = strpos(exponentForm, 'e')
    exponent = strmid(exponentForm, pos_e + 1, strlen(exponentForm) - pos_e - 1)
    pos_plus = strpos(exponent, '+')
    IF pos_plus NE -1 THEN exponent = strmid(exponent, pos_plus + 1, strlen(exponent) - pos_plus - 1)
    pos_0 = strpos(exponent, '0')
    IF pos_0 NE -1 THEN exponent = strjoin(strmid(exponent, 0, pos_0) + strmid(exponent, pos_0 + 1, strlen(exponent) - pos_0 - 1))
    trimmed = strjoin('$' + strtrim(strmid(exponentForm, 0, pos_e) + ' \times 10^{' + exponent + '}', 2) + '$')
  ENDIF
  
  formattedNumbers = [formattedNumbers, trimmed]
ENDFOREACH ; Handle array input

return, formattedNumbers

END