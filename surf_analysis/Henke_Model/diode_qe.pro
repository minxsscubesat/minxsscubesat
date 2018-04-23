;
;	diode_qe.pro
;
;	Convert Diode Sensivity into QE
;	Tom Woods
;	11/07/03
;
;	INPUTS:
;		w = wavelength in Angstroms
;		s = sensitivity in electrons/photon
;
;	OUTPUT:
;		qe = quantum efficiency (unitless, 1=100%)
;
function diode_qe, w, s

eVfactor = (6.6261D-34 * 2.9979E8 * 1.E10) / 1.6022E-19
electrons = (eVfactor/w) / 3.65
qe = (s / electrons) < 1.

return, qe
end
