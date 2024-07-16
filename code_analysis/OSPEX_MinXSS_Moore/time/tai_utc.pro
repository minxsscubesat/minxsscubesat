  function tai_utc, jd
;
; Given a Julian Day Number & fraction (UTC time), returns the
; difference TAI-UTC, in microseconds.
;
; B. Knapp, 2001-05-14, 2001-08-15
;
  common tai_utc_save, n_leap, mjdarr, dtarr
;
  if n_elements(n_leap) eq 0 then begin
;
;    Read the file tai-utc.dat (fron USNO) and compute dt at each
;    of the tabulated dates.
;
;    Arrays to hold mjd, dt
     mjdarr = dblarr(128)
     dtarr = lonarr(128)
     n_leap = -1L
;
     mjd = 0.d0
     dt0 = 0.d0
     mjd0 = 0.d0
     df = 0.d0

     ; determine the location of this routine, which is also
     ; where the leap second file will be.  It is called tai-utc.dat
      info = routine_info('tai_utc', /functions, /source)
      file = info.path
      p = strpos(strlowcase(file), 'tai_utc.pro')
      strput, file, '-', p+3
      strput, file, '.dat', p+7

     openr, in, file, /get_lun
     in_fmt = "(19x,f5.0,14x,f10.7,12x,f5.0,5x,f9.7)"
     out_fmt = "(f8.0,f12.7,f7.0,f11.7,f12.7)"
     while not eof( in ) do begin
        readf, in, mjd, dt0, mjd0, df, format=in_fmt
        dt = dt0+(mjd-mjd0)*df
;       print, mjd, dt0, mjd0, df, dt, format=out_fmt
        n_leap = n_leap+1
        mjdarr[n_leap] = mjd
        dtarr[n_leap] = nint(dt*1.d6)  ;microseconds
     endwhile
     close,in
     free_lun,in
;
;    Truncate arrays
     mjdarr = mjdarr[0:n_leap]
     dtarr = dtarr[0:n_leap]
;
  endif
;
; Convert our argument to mjd
  mjd = jd-2400000.5d0
;
; Find the last table entry before argument date
  p = where(mjdarr le mjd, np)
  if np gt 0 then $
     return, dtarr[np-1] $
  else $
     return, 0L
;
  end
