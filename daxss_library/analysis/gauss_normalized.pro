;
;	gauss_normalized.pro
;
;	Calculate Gaussian profile normalized to unity for the integration
;	Note that is normalization has the step-size included for probability normalization (integration)
;
;	INPUT
;		x		Input variable for the calculation
;		params	Input parameters - 2 element array = [ FWHM, x_center ]
;		limit	Optional input to specify where gaussian values are forced to zero
;
;	OUTPUT
;		gauss	output Gaussian profile with same number of elements as "x" Input
;
;	HISTORY
;		6/9/2022	T. Woods
;
function gauss_normalized, x, params, limit=limit, debug=debug

if n_params() lt 2 then begin
	print, 'USAGE:  gauss_profile = gauss_normalized( x_array, params_FWHM_X-center)
	return, -1L
endif

if n_elements(params) lt 2 then begin
	print, 'ERROR: gauss_normalized() parameters need to be array with FWHM and X-center values.'
	return, -1L
endif

; get step-size as part of the normalization
xstep = abs(shift(x,1) - shift(x,-1))/2.
xstep[0] = xstep[1] & xstep[-1] = xstep[-2]

;  Calculate Gaussian with normalization to 1.0 for integration over the Gaussian
sigma = abs(params[0]) / 2.354820    ;  factor = 2.*sqrt(2.*alog(2.))
Amplitude = 1. / sigma / sqrt(2.*!pi)
e_term = ((x - params[1])^2. / sigma^2. / 2.) < 50.
result = Amplitude * exp( -1. * e_term ) * xstep

if keyword_set(limit) then begin
	if (limit gt (max(result)/10.)) then limit = max(result)/10.
	wlow = where( result lt limit, num_low )
	if (num_low gt 0) then result[wlow] = 0.0
endif

if keyword_set(debug) then stop, 'DEBUG at end of gauss_normalized()...'
return, result
end
