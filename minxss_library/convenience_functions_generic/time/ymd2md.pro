  function ymd2md, y, m, d, epoch

; Given date(s) in the form of [yyyy, mm, dd.dd], returns
; double-precision mission day number(s).

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Input must be four scalars or four 1-dimensional arrays of length n,
; or single 1-dimensional array of length 3, or a 2-dimensional array
; with dimensions [3,n].
  info = size(y)
  case n_params() of
       1:begin
           show_usage = info[1] ne 4
           if not show_usage then begin
             yy = (y[0,*])[*]
             mm = (y[1,*])[*]
             dd = double((y[2,*])[*])
           endif
         end

       4:begin
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
     print,"  YMD2MD translates dates of the form [yyyy, mm, dd.dd] to     "
     print,"  double-precision mission day numbers, where the epoch date     "
     print,"  is specified.  The argument may be a     "
     print,"  single date (four scalars y, m, d, or a 1-dimensional array "
     print,"  of length 3) or multiple dates (four 1-dimensional arrays   "
     print,"  of the same length n, or a 2-dimensional  array with         "
     print,"  dimensions [3,n]).                                           "
     print,"                                                               "
     print,"  md = ymd2md( ymd, epoch )                                           "
     return,''
  endif
;
  return, jd2md( ymd2jd( yy, mm, dd ), epoch )
;
  end
