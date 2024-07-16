  function udtf2jd, yd, ms

; Translates date(s) in the 'UARS Date/Time' format (long integer
; [yyddd,ms], epoch 1900 Jan 1.0) to double-precision Julian Day
; Number(s).

; B. Knapp, 97.11.14
;           98.06.09, IDL v. 5 compliance
;           98.08.31, Make 1900 Jan 1.0 the epoch for UDTF format

; Input must be two scalars or two 1-dimensional arrays of length n,
; or single 1-dimensional array of length 2, or a 2-dimensional array
; with dimensions [2,n].
  info1=size(yd)
  info2=size(ms)
  case n_params() of
       1:begin
            show_usage = info1[1] ne 2
            if not show_usage then begin
               ydloc = (yd[0,*])[*]
               msloc = (yd[1,*])[*]
            endif
         end
       2:begin
            show_usage = n_elements(yd) ne n_elements(ms)
            if not show_usage then begin
               ydloc = yd
               msloc = ms
            endif
         end
    else:show_usage = 1 eq 1
  endcase
;
  if show_usage then begin
     print,"                                                               "
     print,"  UDTF2JD translates dates in the 'UARS Date/Time' format      "
     print,"  ([yyddd,ms], epoch 1900 Jan 1.0) to double-precision Julian  "
     print,"  Day Numbers of the form ddddddd.dd.  The argument may be a   "
     print,"  single date (two scalars yd, ms, or a 1-dimensional array of "
     print,"  length 2) or multiple dates (two 1-dimensional arrays of the "
     print,"  same length n, or a 2-dimensional array with dimensions      "
     print,"  [2,n]).                                                      "
     print,"                                                               "
     print,"  jd = udtf2jd( udtf )                                         "
     return,''
  endif
;
  jd = yd2jd(double(ydloc+1900000l)+msloc/8.64d7)
;
; Return scalar or array?
  if n_elements(jd) eq 1 and n_params() eq 2 and $
     info1[0] eq 0 and info2[0] eq 0 or $
     n_params() eq 1 and info1[0] eq 1 and info1[1] eq 2 then $
     return, jd[0] $
  else $
     return, jd
;
  end
