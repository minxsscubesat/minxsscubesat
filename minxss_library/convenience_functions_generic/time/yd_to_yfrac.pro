;+
; NAME:
;  yd_to_yfrac
;
; PURPOSE:
;  convert yyyydoy to a year with fraction
;
; CATEGORY:
;  LIB
;
; CALLING SEQUENCE:
;  result=yd_to_yfrac(yyyydoy)
;
; INPUTS:
;  yyyydoy = year and day of year (could include day fraction)
;
; OUTPUTS:
;  result = yyyy.ffff
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
; ROUTINES_USED:
;  LEAP_YEAR: returns 1 for leap year, 0 otherwise
;
; EXAMPLES:
;
;  If argument is any of the LONG integer types, the year fraction at noon
;  UT for that day is returned. (Daily averages correspond to noon,
;  not midnight.)
;
;  IDL> x=yd_to_yfrac(2002001L)  & print,x,form='(f15.9)'  
;   2002.001369863
;
;
;  If the argument type is a DOUBLE, nothing is added to the
;  result. It is assumed that the user is specifying the proper day fraction.
;
;  IDL> x=yd_to_yfrac(2002001.d) & print,x,form='(f15.9)'
;   2002.000000000
;
; MODIFICATION HISTORY:
;  2-20-03 Don Woodraska Original file creation.
;
; $Id: yd_to_yfrac.pro,v 6.1 2003/03/13 01:47:59 dlwoodra Exp $
;-

function yd_to_yfrac, yyyydoy

;
; 1) check parameters
;
if n_params() ne 1 then goto, bailout
x=where(yyyydoy lt 1000001L or yyyydoy gt 9999365L,n_x)
if n_x gt 0 then begin
    print,' ERROR: YD_TO_YFRAC - bad yyyydoy '
    goto, bailout
endif

year = long(yyyydoy) / 1000L
doy  = (yyyydoy-1) mod 1000L

; if user doesn't supply a yyyydoy fraction, then use noon time
if size(doy,/type) eq 3 or $ ;long, ulong, long64, or ulong64
  (size(doy,/type) ge 13 and size(doy,/type) le 15) $
  then doy=doy+0.5d

isleap=leap_year(year)

;frac=1.d0/(365.d0+isleap)

return,year + (doy / (365.d0 + isleap))

bailout:
print,''
print,'USAGE: yyyy.ffff = yd_to_yfrac( yyyydoy )'
print,' yyyydoy is seven-digit year day of year (can also include day fraction)'
print,' yyyy.ffff is year with fraction'
print,'  ffff=0 for jan 1 at 0 UT'
print,''
print,' Note: leap and non-leap years have a different year fraction for one day.'
print,'   Users are cautioned to not perform fits, or any math that requires'
print,'   taking date differences.'
print,'   For calculating differences, consider using julian days or'
print,'   use the DAYS_SINCE_EPOCH function.'
print,''
return,-1

end
