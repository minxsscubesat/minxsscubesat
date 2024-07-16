  function udtf_ms_add, udtf, ms
;
; Add millisecond increment(s) to given UARS date/time format time(s).
;
; B. Knapp, 98.08.31
;           98.09.25, add code to handle udtf structure type
;
; Add millisecond offset(s) to given date(s) in the UARS date/time format
; ([yyddd,ms], epoch 1900 Jan 1.0).  Input udtf must be a 1-dimensional
; array of length 2, or a 2-dimensional array with dimensions [2,n], and
; ms must be a scalar or a 1-dimensional array of length m compatible with
; the dimension of udtf (m=n or n=1).
;
; Note that a long integer ms value cannot be greater than 2^31-1 (about
; 25 days), so for increments larger than this, the ms value should be
; specified in double precision, which will accomodate integer values up
; to 2^53-1 (over 10^8 days).  However the resulting udtf time will always
; be returned as a longword integer pair, so the fractional part (if any)
; of the ms input will be ignored.
;
  show_usage = n_params() lt 2
  if show_usage then goto, USAGE
;
; If udtf input is a udtf-structure type, convert it to an array
  info0 = size( udtf )
  struct_type = info0[n_elements( info0 )-2] eq 8
  if struct_type then begin
     ludtf = udtf_convert_type( udtf, success )
     show_usage = not success
  endif else begin
     ludtf = udtf
     show_usage = 0 eq 1
  endelse
  if show_usage then goto, USAGE
;
  info1 = size( ludtf )
  info2 = size( ms )
  case info1[0] of
       1:show_usage = info1[1] ne 2 or info2[0] gt 1
       2:show_usage = info1[1] ne 2 or info2[0] gt 0 and info2[0] ne info1[2]
    else:show_usage = 1 eq 1
  endcase
;
  USAGE:
  if show_usage then begin
     print,"                                                               "
     print,"  UDTF_MS_ADD adds millisecond offset(s) to given date(s) in   "
     print,"  the UARS date/time format ([yyddd,ms], epoch 1900 Jan 1.0).  "
     print,"  Input argument udtf must be a 1-dimensional array of length  "
     print,"  2, or a 2-dimensional array with dimensions [2,n], or a      "
     print,"  structure (or array) of type udtf ({YEAR_DAY:long, MILLISEC: "
     print,"  long}) and ms must be a scalar or a 1-dimensional array of   "
     print,"  length m compatible with the dimension of udtf (m=n or n=1)  "
     print,"                                                               "
     print,"     udtf2 = udtf_ms_add( udtf, ms )                           "
     return,''
  endif
;
; Return same type as input udtf
  result = jd2udtf( udtf2jd( ludtf ) + ms/8.64d7 )
  if struct_type then $
     return, udtf_convert_type( result, success ) $
  else $
     return, result
  end