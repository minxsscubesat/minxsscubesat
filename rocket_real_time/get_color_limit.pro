;+
; NAME:
;   get_color_limit
;
; PURPOSE:
;   Limit checking: take a value and decide if it should be red or green
;
; INPUTS:
;   text_obj [IDL text object]: From any call like t = text()
;   value [number]:             The value to check against the limits
;   rl [number]:                Red low limit (not strictly required by IDL but will not work if not defined)
;   rh [number]:                Red high limit (not strictly required by IDL but will not work if not defined)
;
; OPTIONAL INPUTS:
;   green_string [string]: What you want optional return_string to be if limit check is green
;   red_string [string]:   What you want optional return_string to be if limit check is red
;
; KEYWORD PARAMETERS:
;   None
;   
; OUTPUTS:
;   Red or green color for use in display
;
; OPTIONAL OUTPUTS:
;   return_string [string]: Either green_string or red_string depending on the result of the limit check
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   color = get_color_limit(100, rl=50, rh=101) ; Should return green
;-
PRO get_color_limit, text_obj, value, rl=rl, rh=rh, $ 
                     green_string=green_string, red_string=red_string

  ; Defaults
  redColor = 'tomato'
  greenColor='lime green'
  t_string = ''
  
  ; Checks
  IF ~isA(text_obj, 'Objref') THEN BEGIN
    message, /INFO, 'You did not pass in a proper text object.'
    return
  ENDIF
  IF isA(value, 'string') THEN BEGIN
    message, /INFO, 'Cannot process string data'
  ENDIF
  IF rl EQ !NULL OR rh EQ !NULL THEN BEGIN
    message, /INFO, 'Need to pass in red low and red high limits'
    return
  ENDIF
  
  ; If user passed in a non-string for red_ or green_string then force them to be strings
  IF green_string NE !NULL AND ~isA(green_string, 'string') THEN BEGIN
    green_string = JPMPrintNumber(green_string)
  ENDIF
  IF red_string NE !NULL AND ~isA(red_string, 'string') THEN BEGIN
    red_string = JPMPrintNumber(red_string)
  ENDIF
  
  ; Limit check
  IF value LE rl OR value GE rh THEN BEGIN
    text_obj.font_color = redColor
    IF red_string NE !NULL THEN BEGIN
      t_string = red_string
    ENDIF
  ENDIF ELSE BEGIN
    text_obj.font_color = greenColor
    IF green_string NE !NULL THEN BEGIN
      t_string = green_string
    ENDIF
  ENDELSE
  
  ; Build the string to put on the display
  IF strcmp(t_string, '') THEN BEGIN
    t_string = JPMPrintNumber(value)
  ENDIF ELSE BEGIN
    t_string += ' (' + JPMPrintNumber(value) + ')'
  ENDELSE
  text_obj.string = t_string

END