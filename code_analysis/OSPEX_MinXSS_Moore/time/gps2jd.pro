  function gps2jd, gps
;
; Convert double precision GPS (TAI) seconds since 1980 Jan 6.0 to
; double precision UT Julian Day Number and fraction.
;
; B. Knapp, 2001-08-14
;
; Show usage?
  if n_params() eq 0 then begin
     print,' '
     print,' gps2jd usage: '
     print,' '
     print,'     jd = gps2jd(gps)'
     return,' '
  endif
;
  epoch = 1980006.d0
  return, yd2jd(epoch)+gps2utc(gps)/8.64d4
  end

