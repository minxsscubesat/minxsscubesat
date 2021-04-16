  function dyd, yd1, yd2
;
; Given two calendar dates of the form yyyyddd.dd, returns the difference
; in days yd2-yd1.  Either or both arguments may be arrays; if both are
; arrays, they must agree in length.
;
; B. Knapp, 97.11.14
;           98.06.08, IDL v. 5 compliance
;
; If both inputs are arrays, they must be the same length.
  info1 = size(yd1)
  info2 = size(yd2)
  if n_params() lt 2 or (info1[0] gt 0 and info2[0] gt 0 and $
     (info1[0] ne info2[0] or n_elements(yd1) ne n_elements(yd2))) then begin
     print,"                                                               "
     print,"  DYD returns the difference in days between two calendar dates"
     print,"  of the form yyyyddd.dd; that is, it returns the increment in "
     print,"  days from the first argument to the second argument, yd2-yd1."
     print,"  Either or both arguments may be arrays; if both are arrays,  "
     print,"  they must have the same dimensions.                          "
     print,"                                                               "
     print,"  diff = dyd( yd1, yd2 )                                       "
     return,''
  endif
;
  return, yd2jd(yd2)-yd2jd(yd1)
;
  end