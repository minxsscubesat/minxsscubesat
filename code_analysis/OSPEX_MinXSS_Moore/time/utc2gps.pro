  function utc2gps, utc
;
; Returns the GPS time (elapsed TAI seconds since 1980 Jan 6.0)
; given the UTC clock time (elapsed seconds since 1980 Jan 6.0).
;
; B. Knapp, 2001-08-14
;
; GPS epoch
  jd0 = yd2jd(1980006.d0)
;
  jd = jd0+utc/8.64d4
  return, utc+(tai_utc(jd)-tai_utc(jd0))/1.d6
  end

