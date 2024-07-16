  function ymd2, ymd1, d
;
; Given a calendar date of the form [yyyy, mm, dd.dd] and an increment
; number of days (positive or negative), returns the calendar date offset
; by the given increment.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; If both inputs are arrays, they must be the same length.
  info1 = size(ymd1)
  info2 = size(d)
  if n_params() lt 2 or (info1[0] gt 1 and info2[0] gt 0 and $
     (info1[0]-1 ne info2[0] or $
     n_elements(ymd1)/3 ne n_elements(d))) then begin
     print,"                                                               "
     print,"  YMD2 applies a given offset (in days) to a given calendar    "
     print,"  date of the form [yyyy, mm, dd.dd].  The offset may be       "
     print,"  positive or negative, and either argument, or both, may be   "
     print,"  arrays.  (For a single date, the first argument will be a    "
     print,"  3-element array, for n dates, it will be a 3 x n array.  The "
     print,"  second dimension of the first argument must agree with the   "
     print,"  number of elements in the second argument.)                  "
     print,"                                                               "
     print,"  ymd_2 = ymd2( ymd1, offset )                                 "
     return,''
  endif
;
  return, jd2ymd( ymd2jd( ymd1 )+d )
;
  end