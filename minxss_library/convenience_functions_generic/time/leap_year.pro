;+
; NAME:
;  leap_year
;
; PURPOSE:
;  Return 1 (true) if year is a leap year, 0 (false) otherwise
;
; CATEGORY:
;  Library function
;
; CALLING SEQUENCE:  
;  result = leap_year( year )
;
; INPUTS:
;  year = 4 digit year
;  IF array input, then an array is returned
;
; OUTPUTS:
;  result = 1 (true) is leap year, 0 (false) if not
;           result is a long array if year is an array
;
; COMMON BLOCKS:
;  None
;
; PROCEDURE:
;  1.  Check input parameters
;  2.  Determine leap year
;  3.  Return result
;
; MODIFICATION HISTORY:
;  11/22/99 Tom Woods Original creation for Version 1.0.0
;  2/20/03 Don Woodraska Modified from ymd2yyyydoy.pro
;
;idver='$Id: leap_year.pro,v 6.1 2003/03/13 01:47:59 dlwoodra Exp $'
;-

function leap_year, yyyy, $
                    byte_r=byte_r, integer_r=integer_r, l64_r=l64_r, $
                    uint_r=uint_r, ulong_r=ulong_r,    ul64_r=ul64_r

;
;	1.  Check input parameters
;
if (n_params(0) lt 1) then begin
	print, 'USAGE:  result=leap_year( year )'
    print,'   result is a long by default'
    print,'   users can specify the return data type with an optional keyword:'
    print,'    /byte_r to return a byte data type'
    print,'    /integer_r for signed 16-bit integer'
    print,'    /l64_r     for signed 64-bit integer'
    print,'    /uint_r    for unsigned 16-bit integer'
    print,'    /ulong_r   for unsigned 32-bit integer'
    print,'    /ul64_r    for unsigned 64-bit integer'
	return, -1
endif

;
;	2.  Determine leap year
;
year=long(yyyy) ;truncate if non-integer data type

if n_elements(year) gt 1 then result=lonarr(n_elements(year)) else result=0L

; leap year is either (divisible by 4 and not divisible by 100) or
; divisible by 400

x=where( ( ((year mod 4) eq 0) and ((year mod 100) ne 0) ) or $
         ((year mod 400) eq 0), n_true)
if n_true gt 0 then begin
    if n_elements(year) gt 1 then result[x]=1L else result=1L
endif

case 1 of
    keyword_set(byte_r):    return, byte(result)
    keyword_set(integer_r): return, fix(result)
    keyword_set(l64_r):     return, long64(result)
    keyword_set(uint_r):    return, uint(result)
    keyword_set(ulong_r):   return, ulong(result)
    keyword_set(ul64_r):    return, ulong64(result)
    else: return, result ; default output type is long
end

end
