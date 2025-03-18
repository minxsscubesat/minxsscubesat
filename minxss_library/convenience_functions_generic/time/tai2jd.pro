;
;	tai2jd.pro
;
;	Convert TAI seconds to Julian Day
;
; Example usage
;	tai_time = 373782345.0  ; Sample TAI time in seconds
;	jd_result = tai_to_jd(tai_time)
;	print, "Julian Day:", jd_result
;

function tai2jd, tai_seconds

  if (n_params() lt 1) then return, 0.0D0

  ; Constants
  ;  - Seconds per day: 86400
  ;  - Julian epoch (JD 2436204.5) in TAI seconds
  ;  - Leap Seconds from UTC to TAI for > 2016 is +37 sec
  ;  - Seconds per 365.25-day year:  31557600.
  ;	 - 2017/001 TAI seconds = 1861920000.D0

  jd_epoch = 2436204.5D0  ;

  ; estimate leap seconds since 1958 at rate of 0.6136 leap-sec per year
  leap_seconds = (tai_seconds / 31557600.D0) * 0.6136
  w2017 = where(tai_seconds gt 1861920000.D, num2017 )
  if (num2017 ge 1) then leap_seconds[w2017] = 37.0  ; force to be correct value

  ; Calculate Julian Day
  jd = ((tai_seconds - leap_seconds) / 86400.0D0) + jd_epoch

  return, jd
end


