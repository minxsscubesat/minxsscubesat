;+
; NAME:
;   daxss_dead_time_slow_only.pro
;
; PURPOSE:
;   Calculate the Dead Time fraction based on slow count rates only
;
;   This is for daxss_make_level1new.pro
;
; CATEGORY:
;    MinXSS Level 1
;
; CALLING SEQUENCE:
;   dead_time_factor = daxss_dead_time_slow_only( slow_count_rate, verbose=verbose )
;
; INPUTS:
;   fast_count_rate		X123 Fast Count / accum_time (rate in cps)
;   slow_count_rate		X123 Slow Count / accum_time (rate in cps)
;
; OPTIONAL INPUTS:
;	SLOW_DEAD_TIME		Option to change the default tau_dead_time for the Slow Counter
;	FAST_DEAD_TIME		Option to change the default tau_fast_resolve_time for the Fast Counter
;
; KEYWORD PARAMETERS:
;	RECALCULATE			Option to recalculate the dead-time look-up tables stored in the Common Block
;   VERBOSE             Set this to print processing messages
;
; OUTPUTS:
;   Returns the dead time factor
;
; OPTIONAL OUTPUTS:
;   flag_invalid	Output flag is set if dead time factor is not really known because fast rate is too large
;	uncertainty		Output uncertainty as relative amount of the dead time factor
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   This is for daxss_make_level1new.pro
;
; PROCEDURE:
;   1. Calculate the dead time factor
;   2. Set the flag_invalid variable
;   3. Return the dead time factor
;
; HISTORY:
;	6/27/2022	T. Woods, daxss_dead_time.pro created for daxss_make_level1new.pro
;	5/7/2024	T. Woods, updated to be daxss_dead_time_slow_only.pro and REMOVE the divide by 2
;
;+
function daxss_dead_time_slow_only, slow_count_rate, $
				flag_valid=flag_valid, uncertainty=uncertainty, $
				slow_dead_time=slow_dead_time, verbose=verbose

	if (n_params() lt 1) then stop, 'daxss_dead_time_slow_only: ERROR for not having any parameters!!!'
	dead_time_factor = 1.0		; default value for low count rates

	; Constants from Schwab & Sewell et al. 2020 paper about DAXSS calibration
	tau_fast_peak_time = 0.100D-6		; seconds - X123 parameter
	tau_fast_resolve_time = 0.120E-6	; seconds - X123 parameter
	tau_slow_peak_time = 1.200E-6		; seconds - X123 parameter
	; tau_dead_time = 2.875E-6			; seconds - pre-flight SURF calibration
	; tau_dead_time = 1.95E-6   ; seconds - on-orbit calibration to remove no-beacon spikes
	; 5/7/2024 - switch back to the pre-flight calibration result (T. Woods)
	tau_dead_time = 2.875E-6

	DEAD_TIME_RELATIVE_UNCERTAINTY = 0.05	; estimated uncertainty is 5% based on testing in-flight data
	DEAD_TIME_CORRECTION_LIMIT = 2.0		; set dead time correction valid if factor is less than 2.0
	SLOW_COUNT_RATE_LIMIT = 100000.D0		; Require Slow Limit for new algorithm (T. Woods, 5/7/2024)

	do_table_calculation = 0
	if keyword_set(SLOW_DEAD_TIME) then begin
		do_table_calculation = 1
		tau_dead_time = SLOW_DEAD_TIME
	endif

	; Use look-up table for converting between C_meas and C_in
	COMMON daxss_dead_time_slow_common, c_in, c_meas_slow, c_dead_time_uncertainty
	if (n_elements(c_in) le 1) or (do_table_calculation ne 0) then begin
		;; OLD CODE ;; c_in = findgen(100000L)*100.D0 + 1.   ; original range was 1 to 10M in steps of 100
		c_in = findgen(100000L)*10.D0 + 1.   ; new range is 1 to 1M in steps of 10 (T. Woods, 5/7/2024)
		;; OLD CODE ;; c_meas_slow = c_in * exp(-c_in*tau_dead_time/2.)
		c_meas_slow = c_in * exp(-c_in*tau_dead_time)   ; remove the divide by 2 (T. Woods, 5/7/2024)
		; calculate uncertainty as difference for the c_meas_slow with different tau_dead_time values
		c_meas_slow_low = c_in * exp(-c_in*tau_dead_time*(1.-DEAD_TIME_RELATIVE_UNCERTAINTY)/2.)
		c_meas_slow_high = c_in * exp(-c_in*tau_dead_time*(1.+DEAD_TIME_RELATIVE_UNCERTAINTY)/2.)
		c_dead_time_uncertainty = abs(c_meas_slow_low - c_meas_slow_high)/2./c_meas_slow
		if keyword_set(VERBOSE) then $
			print, 'DEAD_TIME correction is good up to ', $
				min(c_in[where(c_dead_time_uncertainty gt DEAD_TIME_CORRECTION_LIMIT)]), ' cps'
	endif

	; Total Signal predicted by fast_count_rate - Amptek X123 application note about dead time
	; total_count_rate1 = (fast_count_rate / (1. - fast_count_rate * tau_fast_resolve_time)) > 1.0
	; better total is using the look-up table for higher rates
	;; OLD CODE ;; total_count_rate = interpol( c_in, c_meas_fast, fast_count_rate )
	;; OLD CODE ;; slow_meas_predict = interpol( c_meas_slow, c_in, total_count_rate )
	;; OLD CODE ;; dead_time_factor = total_count_rate / slow_meas_predict

	;  Changed to not to use Fast Count rate - 5/7/2024 T. Woods
	;  So calculate total_count_rate by interpolating across look-up table of C_in and C_slow
	;  This algorithm requires a limit for the Slow Count Rate
	adjusted_slow_count_rate = slow_count_rate < SLOW_COUNT_RATE_LIMIT
	total_count_rate = interpol( c_in, c_meas_slow, adjusted_slow_count_rate )
	dead_time_factor = total_count_rate / adjusted_slow_count_rate

	; calculate optional outputs
	uncertainty = interpol( c_dead_time_uncertainty, c_in, total_count_rate )
	flag_valid = (dead_time_factor lt DEAD_TIME_CORRECTION_LIMIT) AND  $
				((slow_count_rate -adjusted_slow_count_rate) le 0)

	;   Amptek "Dead_Time" is not accurate calculation
	;   Dead Time fraction based on fast and slow counts - Amptek X123 application note about dead time
	;     adjusted to use total_count_rate instead of fast_count_rate and prevent slow count being zero
	; dead_time_fraction = (total_count_rate - (slow_count_rate > 1.0)) / total_count_rate
	;   convert dead time fraction into a factor to multiple
	; dead_time_factor = 1. / (1. - dead_time_fraction)

	; if keyword_set(VERBOSE) then stop, 'Debug dead_time_factor ...'
return, dead_time_factor
end