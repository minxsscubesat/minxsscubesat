;+
; NAME:
;   kev2angstrom
;
; PURPOSE:
;   Convert photon energy in kiloelectronvolts (kev) to wavelength in angstroms (Å)
;
; INPUTS:
;   kev [float, fltarr]: The photon energy to convert in kev units
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   angstrom [float, fltarr]: The function returns the photon energy converted to wavelength in Å units
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   wavelength = kev2angstrom([1.04, 2.543, 5.49])
;
; MODIFICATION HISTORY:
;   2016-11-07: James Paul Mason: Wrote script.
;-
FUNCTION kev2angstrom, kev

return, kev * 12.39842

END