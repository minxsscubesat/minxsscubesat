  function jd2gps, jd
;
; Convert double precision Julian Day Number and fraction (UT) to
; GPS (TAI) seconds since 1980 Jan 6.0 UT.
;
; B. Knapp, 2001-08-14
;
; Show usage?
  if n_params() eq 0 then begin
     print,' '
     print,' jd2gps usage: '
     print,' '
     print,'     gps = jd2gps(jd)'
     return,' '
  endif
;
  epoch = 1980006.d0
  return, utc2gps((jd-yd2jd(epoch))*8.64d4)
;
  end
