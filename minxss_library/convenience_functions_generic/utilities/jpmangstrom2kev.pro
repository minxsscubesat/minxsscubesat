;+
; NAME:
;   JPMAngstrom2keV
;
; PURPOSE:
;   Convert wavelength in Å to energy in keV
;
; INPUTS:
;   angstrom [fltarr]: An array (can be single value) of wavelengths in Angstrom units
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   keV [fltarr]: An array (can be single value if input was single value) of energies in keV units
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   energyKeV = JPMAngstrom2keV([1., 1.3, 3.])
;
; MODIFICATION HISTORY:
;   2016/06/11: Amir Caspi: Wrote script.
;-
FUNCTION JPMAngstrom2keV, angstrom

hc  = 12.39842 
return, hc / angstrom

END