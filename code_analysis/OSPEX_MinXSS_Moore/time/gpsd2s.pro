  function gpsd2s, d
;
; Convert double precision GPS Epoch Day Number(s) (and fraction(s))
; to TAI seconds since GPS Epoch (1980 Jan 6.0 UT).
;
; B. Knapp, 2000-02-29
;
  epoch = 1980006L
  leap_dates = long( days( epoch, $
     [ 1981181L, 1982181L, 1983181L, 1985181L, 1987365L, 1989365L, $
       1990365L, 1992182L, 1993181L, 1994181L, 1995365L, 1997181L, $
       1998365L ] ) )
;
  d0 = long( d )
  n = n_elements( d )
  if n eq 1 then begin
     leap_secs = long( total( leap_dates lt d0[0] ) )
  endif else begin
     leap_secs = lonarr( n )
     for j=0,n_elements( leap_dates )-1 do $
        leap_secs = temporary( leap_secs ) + ( leap_dates[j] lt d0 )
  endelse
;
; Day length(s)?
  if n eq 1 then begin
     w = where( d0 eq leap_dates, nw )
     if nw gt 0 then day_len = 86401.d0 else day_len = 86400.d0
  endif else begin
     day_len = dblarr( n )+86400.d0
     for j=0,n_elements( leap_dates )-1 do $
        day_len = temporary( day_len ) + ( d0 eq leap_dates[j] )
  endelse
  return, d0*86400.d0 + (d mod 1.d0)*day_len + leap_secs
;
  end
