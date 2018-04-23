;+
; NAME:
;   minxss_convert_irradiance_units
;
; PURPOSE:
;   Convert irradiance units for MinXSS
;
; INPUTS:
;   irradiance [fltarr[1024, N]]: The irradiance to convert, where 1024 is the number of default bins and N is the number of spectra in time. 
;   energy [fltarr[1024, N]]:     The energy bins corresponding to irradiance. Assumes the default keV binning. 
;   
; OPTIONAL INPUTS:
;   unitsConvertingFrom [string]: The units of the minxssIrradiance input. Options are: 
;                                 (default) 'photons/s/cm2/keV'
;                                 No others at this time
;   unitsToConvertTo [string]:    The units you want to convert to. Options are: 
;                                 (default) 'W/m2/nm'
;                                 None others at this time
;                              
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   minxssIrradianceConverted [fltarr[1024, N]]: The irradiance array with converted units. Dimensions are the same as the minxssIrradiance input. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   minxssIrradiance = minxss_convert_irradiance_units(minxsslevel1.irradiance, minxsslevel1.energy)
;
; MODIFICATION HISTORY:
;   2016-12-10: James Paul Mason: Wrote script.
;-
FUNCTION minxss_convert_irradiance_units, irradiance, energy, $
                                          unitsConvertingFrom = unitsConvertingFrom, unitsToConvertTo = unitsToConvertTo

; Defaults
IF unitsConvertingFrom EQ !NULL THEN unitsConvertingFrom = 'photons/s/cm2/keV'
IF unitsToConvertTo EQ !NULL THEN unitsToConvertTo = 'W/m2/nm'

; Constants
h = 6.626070040d-34 ; [Js]
c = 299792458d ; [m/s]
h_kev = 4.14d-12
c_nm = c * 1d9

; Convert photons/s to W if relevant
IF strmatch(unitsConvertingFrom, '*photons/s*', /FOLD_CASE) AND strmatch(unitsToConvertTo, '*W*', /FOLD_CASE) THEN BEGIN
  
  ; W = J/s, E [J] = hc/lambda
  lamdaMeters = JPMkev2Angstrom(energy) / 1d10 ; [m]
  energyJoules = h * c / lamdaMeters
  
  ; Conversion
  irradiance *= energyJoules
  
ENDIF

; Convert per cm2 to per m2 if relevant
IF strmatch(unitsConvertingFrom, '*cm2*', /FOLD_CASE) AND strmatch(unitsToConvertTo, '*m2*', /FOLD_CASE) THEN BEGIN
  irradiance *= 100.d^2  
ENDIF

; Convert per keV to per nm if relevant
IF strmatch(unitsConvertingFrom, '*keV*', /FOLD_CASE) AND strmatch(unitsToConvertTo, '*nm*', /FOLD_CASE) THEN BEGIN
  
  ; de/dlambda = E^2 / hc
  dedlambda = energy^2 / (h_kev * c_nm)
  
  ; Conversion
  irradiance *= dedlambda
ENDIF

return, irradiance

END