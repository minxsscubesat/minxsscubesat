  function yd2, yd1, d
;
; Given a calendar date of the form yyyyddd.dd and an increment number
; of days (positive or negative), returns the calendar date offset by
; the given increment.
;
; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;
; If both inputs are arrays, they must be the same length.
  info1 = size(yd1)
  info2 = size(d)
  if n_params() lt 2 or (info1[0] gt 0 and info2[0] gt 0 and $
     (info1[0] ne info2[0] or n_elements(yd1) ne n_elements(d))) then begin
     print,"                                                               "
     print,"  YD2 applies a given offset (in days) to a given calendar     "
     print,"  date of the form yyyyddd.dd.  The offset may be positive or  "
     print,"  negative, and either argument, or both, may be arrays.  (If  "
     print,"  both are arrays, they must have the same dimensions.)        "
     print,"                                                               "
     print,"  yd_offset = yd2( yd1, offset )                               "
     return,''
  endif
;
  return, jd2yd( yd2jd( yd1 )+d )
;
  end