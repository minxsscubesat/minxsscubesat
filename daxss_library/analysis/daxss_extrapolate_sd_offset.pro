;+
; NAME:
;   daxss_extrapolate_sd_offset
;
; PURPOSE:
;   Given some timestamped SD write offsets, estimate the write offsets for some specified times
;
; INPUTS:
;   jds [dblarr]:                The known times in julian date format
;   sd_pointers [lonarr]:        The known SD card write offsets. Could be for beacon, science, or whatever packet.
;   jds_to_extrapolate [dblarr]: The times to estimate the SD write offsets for. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   sd_pointers_out [lonarr]: The estimated SD write offset pointer values
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   scid = daxss_extrapolate_sd_offset(hk.time_jd, hk.sd_write_scid, [2459663.2387037035, 2459663.5587037035])
;-
FUNCTION daxss_extrapolate_sd_offset, jds, sd_pointers, jds_to_extrapolate

; Linear fit the relationship of time and SD card offset since they do (nominally) increase together linearly
;fit_range_indices = where(hkjd GE JPMiso2jd('2022-03-01T00:00:00Z') AND hkjd LE JPMiso2jd('2022-03-10T23:59:59Z')) ; Fixed time for extrapolation method

; There are erroneous points showing up in times that are way off; filter that junk out
shifted = shift(jds, -1) - jds
ind = where(shifted LT 2 AND shifted GT 0)
jds = jds[ind]
sd_pointers = sd_pointers[ind]

; TODO: handle SD pointer rollover (e.g., at ~2e6 for SCID)
fit_range_indices = where(jds GE jds_to_extrapolate[0]-1 AND jds LE jds_to_extrapolate[1]+1, n_indices) ; 2 days centered around the user inputted times to interpolate
IF n_indices EQ 0 THEN BEGIN 
  fit_range_indices = where(jds GE jds[-100] AND jds LE jds[-1]) ; Last 100 points extrapolation method
ENDIF 
fit_params = linfit(jds[fit_range_indices], sd_pointers[fit_range_indices])

;scid_range = interpol( hk.sd_write_scid, hkjd, theJD ) ; Original interpolation method

return, long(fit_params[0] + fit_params[1] * jds_to_extrapolate)

END