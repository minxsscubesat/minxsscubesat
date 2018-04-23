function sigfig,thenumber,digits
;+
; NAME:
;	STRNSIGNIF
; PURPOSE:
;	Convert a number to a string with a fixed number of significant digits.
; EXPLANATION:
;	Similar to strn(), this function converts a number to a string, but,
;	unlike strn(), with a fixed number of significant digits.
;
; CALLING SEQEUNCE:
;	tmp = STRNSIGNIF( number, digits )
;
; INPUT:
;	NUMBER   This is the input number to be converted to a string.
;
; OUTPUT:
;	tmp       The formatted string
;
; EXAMPLES:
;	IDL> print,strnsignif(12345.6789,3)  
;	12300
;	IDL> print,strnsignif(1.23456789,3)
;	1.23
;	IDL> print,strnsignif(.00123456789,3)
;	0.00123
;
; HISTORY:
;	1999-03-29 Version 1 written by Eric W. Deutsch & Brooke Skelton
;-


  if (n_params(0) lt 2) then begin
    print,'Call> str=strnsignif(number,digits)'
    print,'e.g.> str=strnsignif(33486.22,3)'
    return,'***'
    endif

out = replicate('',n_elements(thenumber))

for i=0,n_elements(thenumber)-1 do begin
number = thenumber[i]

  expon=fix(alog10(number))
  if (number lt 1) then expon=expon-1

  c=round(number/10.0^(expon-(digits-1)))*10.0^(expon-(digits-1))

  if (c gt 10^(digits-1)) then d = strn(round(c)) $
  else d = strn(string(c,format='(f20.'+strn(digits-1-expon)+')'))

;  return,d
out[i] = d
endfor

return,out

end
