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
;   MAX_DAYS		Limit for number of days for gap to extrapolate (default is 3)
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
;
; HISTORY:
;	April 2022		James Mason, original code
;	10/2/2022		Tom Woods, Updated to exclude FLASH range and limit to +/- 3 days
;-
FUNCTION daxss_extrapolate_sd_offset, jds, sd_pointers, jds_to_extrapolate, max_days=max_days

; NEW 10/2/2022 TW:  add MAX_DAYS
if not keyword_set(max_days) then max_days = 3.0

; Linear fit the relationship of time and SD card offset since they do (nominally) increase together linearly
;fit_range_indices = where(hkjd GE JPMiso2jd('2022-03-01T00:00:00Z') AND hkjd LE JPMiso2jd('2022-03-10T23:59:59Z')) ; Fixed time for extrapolation method

; NEW 10/2/2022 TW: erroneous points are just for FLASH offsets which are always less than 1E4
; NEW 10/2/2022 TW: so have new filter and linear interpolation method
useWoodsFilter = 1

if (useWoodsFilter ne 0) then begin
	;
	;	Simplified Woods Filter / Interpolation method
	;
	FLASH_MAX = 1E4
	wPtrGood = where( (sd_pointers gt FLASH_MAX) AND (jds ge (min(jds_to_extrapolate)-max_days)) $
					AND (jds le (max(jds_to_extrapolate)+max_days)), numPtrGood )
	if (numPtrGood gt 1) then begin
		; do simple interpolation instead of linear fit
		theOffsets = interpol( sd_pointers[wPtrGood], jds[wPtrGood], jds_to_extrapolate )
	endif else begin
		; error finding any SD_POINTERS data to do interpolation
		message, /INFO, 'No Valid SD offsets found for this time. Skipping this event.'
	  	return, !VALUES.F_NAN
	endelse
endif else begin
	;
	; Using original Mason filter
	;
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

	; Handle cases where the prediction just can't be made because the SD offset is all over the place
	derivative = deriv(float(sd_pointers[fit_range_indices]))
	downward_indices = where(derivative LT 0, count)
	IF count GT 2 THEN BEGIN ; GT 2 to avoid end-point issues for derivative
	  message, /INFO, 'The SD offsets appear to be fluctuating randomly with ' + JPMPrintNumber(count, /NO_DECIMALS) + ' decreases in the data. Skipping this event.'
	  return, !VALUES.F_NAN
	ENDIF

	;scid_range = interpol( hk.sd_write_scid, hkjd, theJD ) ; Original interpolation method

	theOffsets = long(fit_params[0] + fit_params[1] * jds_to_extrapolate)
endelse

return, theOffsets
END
