; main_program xgps2jd.pro
;
; Exercise driver for functions gps2jd and jd2gps
;
; B. Knapp, 2000-02-29
;
  epoch = 1980006.0d0
;
; First, try a lot of random dates
  n = 10000L
  j0 = yd2jd( date2( epoch, randomu( seed, n )*40.d0*365.25d0 ) )
  g0 = jd2gps( j0 )
  j1 = gps2jd( g0 )
  g1 = jd2gps( j1 )
  dj = j1-j0
  dg = g1-g0
;  print, max( dj ), min( dj ), format="(2e24.16)"
;  print, max( dg ), min( dg ), format="(2e24.16)"
;
  if max( dj ) or min( dj ) ne 0 then begin
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
  
; Now, some targeted problem dates
  yd = 1989365.d0 + 86400.9d0/86401.d0
  j0 = yd2jd( yd )
  g0 = jd2gps( j0 )
  j1 = gps2jd( g0 )
  g1 = jd2gps( j1 )
  dj = j1-j0
  dg = g1-g0
;  print, max( dj ), min( dj ), format="(2e24.16)"
;  print, max( dg ), min( dg ), format="(2e24.16)"
  
  if max( dj ) or min( dj ) ne 0 then begin
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
;
  end


