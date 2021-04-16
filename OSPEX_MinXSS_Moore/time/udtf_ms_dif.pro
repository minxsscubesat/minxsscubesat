  function udtf_ms_dif, udtf1, udtf2
;
; Determines the difference in milliseconds between two UARS date/time
; format times.  The result is a double-precision integer.
;
; B. Knapp, 98.09.24
;
; Return ms = udtf1 - udtf2.  Input udtf times must be 1-dimensional
; arrays of length 2, or 2-dimensional arrays with dimensions [2,n1]
; and [2,n2] with either n1 = n2 or n1 = 1 or n2 = 1, or structures or
; arrays of structures (of compatible dimensions) of the udtf type
; ({YEAR_DAY:long, MILLISEC:long}).
;
; Note that while the input times are long integer pairs, the difference
; in ms cannot be expressed as a long integer (magnitude < 2^31-1) if it
; is greater than about 25 days.  For this reason, the result is returned
; as a double-precision "integer" (magnitude < 2^53-1).
;
  show_usage = n_params() lt 2
  if show_usage then goto, USAGE
;
; Convert input types?
  info1 = size( udtf1 )
  if info1[n_elements( info1 )-2] eq 8 then begin
     ludtf1 = udtf_convert_type( udtf1, success )
     show_usage = not success
  endif else begin
     ludtf1 = udtf1
     show_usage = 0 eq 1
  endelse
  if show_usage then goto, USAGE
;
  info2 = size( udtf2 )
  if info2[n_elements( info2 )-2] eq 8 then begin
     ludtf2 = udtf_convert_type( udtf2, success )
     show_usage = not success
  endif else begin
     ludtf2 = udtf2
     show_usage = 0 eq 1
  endelse
  if show_usage then goto, USAGE
;
  info1 = size( ludtf1 )
  info2 = size( ludtf2 )
  show_usage = info1[1] ne 2 or info2[1] ne 2
  if not show_usage then begin
     jd1 = udtf2jd( ludtf1 )
     jd2 = udtf2jd( ludtf2 )
     n1 = n_elements( jd1 )
     n2 = n_elements( jd2 )
     show_usage = n1 ne n2 and n1 ne 1 and n2 ne 1
  endif
;
  USAGE:
  if show_usage then begin
     print,"                                                               "
     print,"  UDTF_MS_DIF returns the millisecond difference between two   "
     print,"  times in the UARS date/time format ([yyddd,ms], epoch 1900   "
     print,"  Jan 1.0).  The input arguments udtf1 and udtf2 must be 1-    "
     print,"  dimensional arrays of length 2, or 2-dimensional arrays of   "
     print,"  dimension [2,n], or one must be 1-dimensional of length 2    "
     print,"  and the other 2-dimensional of dimension [2,n], or they may  "
     print,"  be structures or arrays of structures (of compatible dimen-  "
     print,"  sions) of the udtf type ({YEAR_DAY:long, MILLISEC:long}). The"
     print,"  difference is positive if udtf1 is larger (later) than udtf2."
     print,"                                                               "
     print,"  Usage:                                                       "
     print,"     ms = udtf_ms_dif( udtf1, udtf2 )                          "
     return,''
  endif
;
; Return the nearest double-precision integer ms difference
  return, dround( (jd1-jd2)*8.64d7 )
;
  end
