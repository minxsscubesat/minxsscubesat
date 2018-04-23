  function ymd2sd, y, m, d

; Given date(s) in the form of [yyyy, mm, dd.dd], returns
; double-precision SORCE day number(s).

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance

; Input must be three scalars or three 1-dimensional arrays of length n,
; or single 1-dimensional array of length 3, or a 2-dimensional array
; with dimensions [3,n].
  info = size(y)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                              "
     print," YMD2SD translates dates of the form [yyyy, mm, dd.dd] to     "
     print," double-precision SORCE mission day numbers, where SORCE day  "
     print," 0.0 = 2003/024.0 = 2003 Jan 24.0.  The argument may be a     "
     print," single date (three scalars y, m, d, or a 1-dimensional array "
     print," of length 4) or multiple dates (four 1-dimensional arrays    "
     print," of the same length n, or a 2-dimensional  array with         "
     print," dimensions [4,n]).                                           "
     print,"                                                              "
     print," sd = ymd2sd( ymd )                                           "
     return,''
  endif
;
  return, ymd2md(y,m,d,2003024.0d0)
;
  end
