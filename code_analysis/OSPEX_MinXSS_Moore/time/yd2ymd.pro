  function yd2ymd, yd

; Given 'longdate' argument of form yyyyddd.dd (scalar or array of
; length n), returns array with dimensions [3,n], holding the
; corresponding [year, month, day] triples.
; 
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Print usage?
  info = size(yd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  YD2YMD translates longdate arguments of the form yyyyddd.dd  "
     print,"  to double-precision vectors of length three giving the       "
     print,"  corresponding year, month, and day, respectively.  If the    "
     print,"  input argument is an array of length n, the result will be   "
     print,"  a 2-dimensional array with dimensions [3,n].                 "
     print,"                                                               "
     print,"  ymd = yd2ymd( yyyyddd.dd )                                   "
     return,''
  endif
;
  month_days  = [ [  0, 31, 59, 90,120,151,181,212,243,273,304,334 ], $
                  [  0, 31, 60, 91,121,152,182,213,244,274,305,335 ] ]
;  
  doy = abs(yd) mod 1000.d0
  y = long(abs(yd)/1000)
  leap = ((y mod 4 eq 0) and (y mod 100 ne 0)) or (y mod 400 eq 0)
  m = replicate(-1,info[info[0]+2])
  for j=11,0,-1 do begin
     mhave = where(m lt 0 and doy/(month_days[j,leap]+1) ge 1.d0, nm)
     if nm gt 0 then m[mhave] = j
  endfor
  d = doy-month_days[m,leap]
;
; Any negative years?
  z = where(yd lt 0,nz)
  if nz gt 0 then y[z] = -y[z]
;
  return, transpose( [ [y], [m+1] ,[d] ] )
;
  end
