;
;	minxss_time_to_sd_offsets
;
;	Interpolate SD write offsets for given JD time
;
;	INPUT
;	hk			MinXSS HK Packet array
;	date		JD time
;	/verbose	Option to print results to screen
;
;	OUTPUT
;	offsets		SD card offsets for HK, SCI, ADCS, LOG
;
;	HISTORY
;	6/15/2016	Tom Woods, original code
;
pro minxss_time_to_sd_offset, hk, date, offsets, verbose=verbose

offsets = -1L
if n_params() lt 2 then begin
   print, 'USAGE: minxss_time_to_sd_offsets, hk, date, offsets, /verbose'
   return
endif

if n_params() lt 3 then verbose=1

; check that date is within range of HK data, else return error
if (min(date) lt min(hk.time_jd)) or (max(date) gt max(hk.time_jd)) then begin
  if keyword_set(verbose) then print, 'ERROR with JD time being within HK data range !'
  return
endif

offsets = lonarr(4,n_elements(date))
offsets[0,*] = interpol( hk.sd_hk_write_offset, hk.time_jd, date )
offsets[1,*] = interpol( hk.sd_sci_write_offset, hk.time_jd, date )
offsets[2,*] = interpol( hk.sd_adcs_write_offset, hk.time_jd, date )
offsets[3,*] = interpol( hk.sd_log_write_offset, hk.time_jd, date )

if keyword_set(verbose) then begin
  print, 'HK   Write Offset = ', reform(offsets[0,*])
  print, 'SCI  Write Offset = ', reform(offsets[1,*])
  print, 'ADCS Write Offset = ', reform(offsets[2,*])
  print, 'LOG  Write Offset = ', reform(offsets[3,*])
endif

return
end
