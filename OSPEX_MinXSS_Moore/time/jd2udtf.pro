  function jd2udtf, jd
;
; Translates Julian Day Number (and fraction) to long integer
; "UARS Date/Time" format ([yyddd,ms]).
;
; B. Knapp, 97.11.14
;           98.06.11, IDL v. 5 compliance
;           98.06.12, Use round instead of nint
;           98.08.31, Make 1900 Jan 1.0 the epoch for UDTF format
;
; Print usage?
  info = size(jd)
  type = info[info[0]+1]
  if type lt 1 or 5 lt type then begin
     print,"                                                               "
     print,"  JD2UDTF translates double-precision Julian Day Number        "
     print,"  (and fraction) to long integer 'UARS Date/Time' format       "
     print,"  ([yyddd,ms], epoch 1900 Jan 1.0).  If the input is an array  "
     print,"  of length n, the output will be an array dimensioned [2,n].  "
     print,"                                                               "
     print,"  udtf = jd2udtf( jd )                                         "
     return,''
  endif
;
  yd = jd2yd(jd)
  ms = round((yd mod 1.0d0)*8.64d7)
  z = where(ms eq 86400000L, nz)
  if nz gt 0 then begin  ;(where we rounded up)
     yd[z] = yd2(long(yd[z]),1.0d0)
     ms[z] = 0L
  endif
  return,transpose([[long(yd)-1900000l],[ms]])
;
  end

