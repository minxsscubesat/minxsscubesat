;+
; NAME:
;   rocket_csol_convert_temperatures
;
; PURPOSE:
;   Convert temperatures from the sensors in the CSOL instrument.
;
; INPUTS:
;   dataNumber [uint]: The raw temperature in data numbers and uint format.
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   COEFF_SET_0: Set this to use coefficients for thermistor NTCG163JX103DTDS
;   COEFF_SET_1: Set this to use coefficietns for thermistor 10K3A1I
;
; OUTPUTS:
;   temperatureCelcius [double]: The converted temperature in celcius units.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   temperature = rocket_csol_convert_temperatures(dataNumber, /COEFF_SET_0)
;
; MODIFICATION HISTORY:
;   2018-05-26: James Paul Mason: Wrote script.
;-
FUNCTION rocket_csol_convert_temperatures, dataNumber, COEFF_SET_0 = COEFF_SET_0, COEFF_SET_1 = COEFF_SET_1

; Define coefficients for 5th order polynomial for these specific temperature sensors
IF keyword_set(COEFF_SET_0) THEN BEGIN
  a = 171.95
  b = -0.22974
  c = 1.7836d-4
  d = -7.8392d-8
  e = 1.7269d-11
  f = -1.5245d-15
ENDIF ELSE IF keyword_set(COEFF_SET_1) THEN BEGIN
  a = 150.78
  b = -0.19499
  c = 1.5025d-4
  d = -6.5759d-8
  e = 1.4449d-11
  f = -1.2734d-15
ENDIF ELSE BEGIN
  message, /INFO, JPMsystime() + ' Please specify a coefficient set to use for CSOL housekeeping temperatures'
ENDELSE

; Do the conversion
return, a + (b * dataNumber) + (c * dataNumber^2.d) + (d * dataNumber^3.d) + (e * dataNumber^4.d) + (f * dataNumber^5.d) ; [ºC]

END