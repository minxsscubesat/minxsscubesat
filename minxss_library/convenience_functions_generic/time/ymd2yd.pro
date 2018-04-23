  function ymd2yd, y, m, d

; Given date(s) in the form of [yyyy, mm, dd.dd], returns
; double-precision date(s) of the form yyyyddd.dd

; B. G. Knapp, 97.11.14
;              98.06.09, IDL v. 5 compliance

; Input must be three scalars or three 1-dimensional arrays of length n,
; or single 1-dimensional array of length 3, or a 2-dimensional array
; with dimensions [3,n].
  info = size(y)
  case n_params() of
       1:begin
           show_usage = info[1] ne 3
           if not show_usage then begin
             yy = (y[0,*])[*]
             mm = (y[1,*])[*]
             dd = double((y[2,*])[*])
           endif
         end

       3:begin
           ny = n_elements(y)
           nm = n_elements(m)
           nd = n_elements(d)
           show_usage = ny ne nm or ny ne nd
           if not show_usage then begin
             yy = y
             mm = m
             dd = double(d)
           endif
         end

    else:show_usage = 1 eq 1
  endcase
  
  if show_usage then begin
     print,"                                                               "
     print,"  YMD2YD translates dates of the form [yyyy, mm, dd.dd] to     "
     print,"  double-precision dates of the form yyyyddd.dd.  The argument "
     print,"  may be a single date (three scalars y, m, d, or a            "
     print,"  1-dimensional array of length 3) or multiple dates (three    "
     print,"  1-dimensional arrays of the same length n, or a 2-dimensional"
     print,"  array with dimensions [3,n]).                                "
     print,"                                                               "
     print,"  yd = ymd2yd( ymd )                                           "
     return,''
  endif
;
  month_days  = [ [  0, 31, 59, 90,120,151,181,212,243,273,304,334 ], $
                  [  0, 31, 60, 91,121,152,182,213,244,274,305,335 ] ]
;
  yp = abs(yy)
  leap = ((yp mod 4 eq 0) and (yp mod 100 ne 0)) or (yp mod 400 eq 0)
  yd = yp*1000.d0 + month_days[mm-1,leap] + dd
;
; Any negative years?
  z = where(yy lt 0,nz)
  if nz gt 0 then yd[z] = -yd[z]
;
; Return scalar or array?
  if n_params() eq 3 and info[0] eq 0 then $
     return, yd[0] $
  else $
     return, yd
;
  end
