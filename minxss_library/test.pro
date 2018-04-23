;+
; NAME:
;	  minxss_code_template.pro
;
; PURPOSE:
;	  Description of algorithm. Turns what input into what output, in broad terms. 
;
; INPUTS:
;	  variableName [data type (e.g., string)]: Description
;	  
;	OPTIONAL INPUTS: 
;	  variableName [data type]: Description
;	  
;	KEYWORD PARAMETERS: 
;	  KEYWORD1: Description
;
; OUTPUTS:
;	  variableName [data type]: Description
;	  
;	OPTIONAL OUTPUTS: 
;	  variableName [data type]: Description
;	  
;	RESTRICTIONS: 
;	  Custom dependencies e.g., minxss-specific IDL code, custom time libraries, and limitations of this code in its forseeable usage
;
; PROCEDURE:
;   1. Task 1
;	  2. Task 2,  etc.
;
; MODIFICATION HISTORY:
;   2015-01-25: Tom Woods: Wrote program.
;   2015-01-26: James Paul Mason: Modified header. 
;+

PRO minxss_code_template, verboseInputName

IF n_params() LT 1 THEN BEGIN
  print, 'USAGE: minxss_template, verboseInputName'
  return
endif

;;
; 1. Task 1
;;

;;
;	2. Task 2,  etc.
;;

; return, variable ; if this is converted from a procedure to a function
END