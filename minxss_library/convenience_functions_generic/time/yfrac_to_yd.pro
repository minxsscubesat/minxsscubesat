;+
; NAME:
;  yfrac_to_yd
;
; PURPOSE:
;  convert date in year fraction form to yyyydoy form
;
; CATEGORY:
;  LIB
;
; CALLING SEQUENCE:
;  result=yfrac_to_yd(yyyydoy)
;
; INPUTS:
;  yfrac = yyyy.ffff (double)
;
; OUTPUTS:
;  result = yyyydoy (long)
;
; COMMON BLOCKS:
;  none
;
; SIDE EFFECTS:
;  Possible rounding may occur due to limitation of double arithmetic.
;
; RESTRICTIONS:
;  Result is a double.
;
; PROCEDURE:
;  1) check parameters
;  2) is it a leap year?
;  3) convert to year fraction
;
; ROUTINED_USED:
;  LEAP_YEAR: returns 1 for leap year, 0 otherwise
;
; EXAMPLES and DESCRIPTION:
;  
;  IDL> help,yfrac_to_yd(2002.0027d)
;  <Expression>    DOUBLE    =        2002002.0
;
;  When used in conjunction with yd_to_yfrac, the user may choose to
;  ignore the 12 hour (noon) offset provided by yd_to_yfrac using the
;  /no_noon keyword. This changes the output data type to a long.
;
;  IDL> help,yfrac_to_yd(yd_to_yfrac(2002001))
;  <Expression>    DOUBLE    =        2002001.5
;
;  Above, yd_to_yfrac references the return value to noon.
;  Below, yd_to_yfrac references the return value to midnight.
;
;  IDL> help,yfrac_to_yd(yd_to_yfrac(2002001.d))
;  <Expression>    DOUBLE    =        2002001.0
;
;  IDL> help,yfrac_to_yd(yd_to_yfrac(2002001),/no_noon)
;  <Expression>    LONG      =      2002001
;
; MODIFICATION HISTORY:
;  2-20-03 Don Woodraska Original file creation.
;  2-25-03 Don Woodraska Added no_noon keyword. Returned value is a
;  long if no_noon is set, otherwise it's a double.
;
; $Id: yfrac_to_yd.pro,v 6.1 2003/03/13 01:48:00 dlwoodra Exp $
;-

function yfrac_to_yd, yfrac, silent=silent, no_noon=no_noon

;
; 1) check parameters
;
if n_params() ne 1 then goto, bailout
x=where(yfrac lt 1000L or yfrac gt 9999L,n_x)
if n_x gt 0 then begin
    print,' ERROR: YFRAC_TO_YD - bad yfrac '
    goto, bailout
endif
if (size(yfrac,/type) ne 5) and (not keyword_set(silent)) then begin
    print,'YFRAC_TO_YD: WARNING - probable loss of precision (up to 10 days)'
    print,'                    argument is not double precision'
endif

year   = floor(yfrac)       ; number left of decimal
isleap = leap_year(year)    ; get leap year vector
doy    = double(yfrac)-year ; fractional part

if keyword_set(no_noon) then begin
    result=year*1000L + round(doy * (365.d0 + isleap) - 0.5d0)+1L 
endif else begin
    result=year*1000L + (doy * (365.d0 + isleap))+1L 
endelse
;if yfrac is a float, then doy has only 2-3 digits that are valid

return,result
;possibly off by 10 days if yfrac is not a double

bailout:
print,'USAGE: result=yfrac_to_yd(yyyy.ffff)'
print,' result is seven-digit year day of year (can also indlude day fraction)'
print,' yyyy.ffff is year with fraction'
print,'  ffff=0 is always jan 1 at 0 UT'
return,-1

end
