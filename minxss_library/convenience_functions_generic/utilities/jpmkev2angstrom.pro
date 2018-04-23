;+
; NAME:
;   JPMkev2Angstrom
;
; PURPOSE:
;   Convert energy in keV to wavelength in Å
;
; INPUTS:
;   kev [fltarr]: An array (can be single value) of energies in keV units
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   angstrom [fltarr]: An array (can be single value if input was single value) of wavelengths in Å units
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   wavelengthAngstrom = JPMkev2Angstrom([1., 1.3, 3.])
;
; MODIFICATION HISTORY:
;   2016/06/01: James Paul Mason: Wrote script.
;-
FUNCTION JPMkev2Angstrom, keV

hc  = 12.39842 
return, hc / keV

END