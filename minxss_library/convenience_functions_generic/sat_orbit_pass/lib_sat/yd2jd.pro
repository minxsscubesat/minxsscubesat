  function yd2jd, yd
;
; Translates Gregorian calendar dates of the form yyyyddd.dd to Julian
; Day Number and fraction.  (Note: Gregorian year 0 is civil year 1 BC.)
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; Note: This function should not be used with dates for historical
; events prior to the adoption of the Gregorian calendar (1582 to 1918,
; depending on the country); instead, for such dates a *Julian* calendar-
; date-to-JD # service should be used.
;
; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2JD translates its argument of the form yyyyddd.dd to a    "
     print,"  double-precision Julian Day Number of the form ddddddd.dd,   "
     print,"  that is, the number of days elapsed since -4712 Jan 1.5.     "
     print,"  The argument may be a scalar or array of a 4-byte or 8-byte  "
     print,"  numerical type.                                              "
     print,"                                                               "
     print,"  jd = yd2jd( yd )                                             "
     return,''
  endif
  
; Extract year and day number
  ydabs = double(abs(yd))
  y = floor(ydabs/1000.d0)
  d = ydabs mod 1000.d0
;
; Add 10000 years (to handle negative years to -10000)
  z = where( yd lt 0, nz )
  if nz gt 0 then y[z] = -y[z]
  y = 1.d4+y
;
; Compute the Julian Day Number by adding the appropriate number of days
; for the elapsed years and leap-year days to the JD # for day 0.0, year 0,
; and removing the 10000-year offset
  return, 1721059.5d0 + 365.0d0*y - 3652425.0d0 + $
     floor((y-1)/4.d0)-floor((y-1)/100.d0)+floor((y-1)/400.d0) + d
;
  end
