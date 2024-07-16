  function ydhms_1990_secs, t
;
; Convert time string of form 'yyyy/ddd-hh:mm:ss' to the long integer
; number of seconds elapsed since midnight UT 1990-Jan-1, or vice versa.
;
; B. Knapp, 92.02.08
;           95.09.25 (change variable yd to yrday)
;           95.11.06 (Add 1995 Dec 31 leap second)
;           98.05.18 (Add 1997 Jun 30 leap second)
;           98.06.09 (IDL v. 5 compliance)
;           98.10.27 (Add 1998 Dec 31 leap second)
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
  z=size(t)
  case z[n_elements(z)-2] of
        7: begin
              ys=strtrim(t,2)
              yrday=long(strmid(ys, 0,4))*1000L+long(strmid(ys,5,3))
              h =long(strmid(ys, 9,2))
              m =long(strmid(ys,12,2))
              s =long(strmid(ys,15,2))
;
              return,days(1990001,yrday)*86400L + $
                 h*3600L + m*60L + s + $
                 long(total(leap_dates lt yrday))
           end; 7
;
        3: begin
              d=long(t/86400L)
              yrday=date2(1990001L,d)
              t1=t-long(total(leap_dates lt yrday))
              d=long(t1/86400L)
              yrday=date2(1990001L,d)
              s=t-long(total(leap_dates lt yrday))-d*86400L
              h=long(s/3600L)<23L
              s=s-h*3600L
              m=long(s/60L)<59L
              s=s-m*60L
              y=long(yrday/1000L)
              d=yrday mod 1000L
;
              return,string(y,d,h,m,s, $
                 "(I4,'/',I3.3,'-',I2.2,':',I2.2,':',I2.2)")
           end; 3
;
     else: begin
              print,' *** Improper arguments in YDHMS_1990_SECONDS ***'
              return, undefined
           end; else
     endcase
  end
