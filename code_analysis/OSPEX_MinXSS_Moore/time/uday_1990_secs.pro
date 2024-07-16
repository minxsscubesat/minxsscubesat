  function uday_1990_secs, t
;
; Convert a double precision uars date (or array) to the long integer
; number of seconds elapsed since midnight UT 1990-Jan-1, or vice versa.
;
; B. Knapp, 94.07.21
;           95.09.25 (changed variable yd to yrday)
;           98.06.09 (IDL v. 5 compliance)
;
; The following array of leap dates are those decreed by NIST/WWV to
; have had 86401 seconds.  This array must be updated every time
; NIST adds a leap second, always Dec 31 or Jun 30 (but not *every*
; Dec 31 and Jun 30!).
;
  leap_dates = $
     [ 1990365L, 1992182L, 1993181L, 1994181L, 1995365L, 1997181L, $
       1998365L ]
;
  if t[0] lt 100000 then begin  ;t is UARS days
 
     launch = days( 1990001L, 1991254L )
     yrday = long( date2( 1991254.d0, t ) )
     if n_elements( yrday ) eq 1 then begin
        leap_secs = long( total( leap_dates lt yrday[0] ) )
     endif else begin
        leap_secs = lonarr( n_elements( yrday ) )
        for j=0,n_elements( leap_dates )-1 do $
           leap_secs = temporary( leap_secs ) + ( leap_dates[j] lt yrday )
     endelse
     return, long( (launch+t)*86400.d0 + leap_secs )
     
  endif else begin              ;t is seconds since 1990
  
     d = long( t/86400L )
     yrday = date2( 1990001L, d )
     if n_elements( yrday ) eq 1 then begin
        leap_secs = long( total( leap_dates lt yrday[0] ) )
     endif else begin
        leap_secs = lonarr( n_elements( yrday ) )
        for j=0,n_elements( leap_dates )-1 do $
           leap_secs = temporary( leap_secs ) + ( leap_dates[j] lt yrday )
     endelse
     t1 = t-leap_secs
     
     d = long( t1/86400L )
     yrday = date2( 1990001L, d )
     if n_elements( yrday ) eq 1 then begin
        leap_secs = long( total( leap_dates lt yrday[0] ) )
     endif else begin
        leap_secs = lonarr( n_elements( yrday ) )
        for j=0,n_elements( leap_dates )-1 do $
           leap_secs = temporary( leap_secs ) + ( leap_dates[j] lt yrday )
     endelse
     s = t-leap_secs-d*86400L
     
     if n_elements( s ) eq 1 then begin
        w = where( yrday eq leap_dates )
        if w[0] ge 0 then day_len = 86401.d0 else day_len = 86400.d0
     endif else begin
        day_len = dblarr( n_elements( s ) )+86400.d0
        for j=0,n_elements( leap_dates )-1 do $
           day_len = temporary( day_len ) + ( yrday eq leap_dates[j] )
     endelse
     return, days( 1991254L, yrday )+s/day_len

  endelse
  end
