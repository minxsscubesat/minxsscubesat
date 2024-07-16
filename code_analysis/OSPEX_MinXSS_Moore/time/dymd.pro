  function dymd, ymd1, ymd2
;
; Given two calendar dates of the form [yyyy, mm, dd.dd], returns the
; difference in days ymd2-ymd1.  Either or both arguments may be two-
; dimension arrays dimensioned [3,n]; if both are two-dimensional
; arrays, their second dimensions must agree.
;
; B. Knapp, 97.11.14
;           98.06.08, IDL v. 5 compliance
;
; If both inputs are arrays, they must be the same length.
  info1 = size(ymd1)
  info2 = size(ymd2)
  if n_params() lt 2 or (info1[0] gt 1 and info2[0] gt 1 and $
     (info1[1] ne info2[1] or n_elements(ymd1) ne n_elements(ymd2))) then begin
     print,"                                                               "
     print,"  DYMD returns the difference in days between two calendar     "
     print,"  dates of the form [yyyy, mm, dd.dd]; that is, it returns the "
     print,"  increment in days from the first argument to the second      "
     print,"  argument, ymd2-ymd1.  An array of n dates is represented as  "
     print,"  a two-dimensional array with dimensions [3,n]; if both argu- "
     print,"  ments are such arrays, they must have the same dimensions.   "
     print,"                                                               "
     print,"  diff = dymd( ymd1, ymd2 )                                    "
     return,''
  endif
;
  d = ymd2jd(ymd2)-ymd2jd(ymd1)
  if info1[0] eq 1 and info2[0] eq 1 then $
     return,d[0] $
  else $
     return,d
;
  end
