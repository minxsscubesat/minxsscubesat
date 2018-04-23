;
;	xrs_qt.pro
;
;	Calculate XRS Quantum Throughput (QT) - units of (electrons/photon) * cm^2
;
;	Tom Woods
;	1/8/05
;
;	QT = (1 - transmission = 1 - exp(-(tau1 + tau2))) * T_Be * area_aperture
;	
;	where	tau1 = sigma1 * rho1 * CELL_LENGTH
;			tau2 = sigma2 * rho2 * CELL_LENGTH
;
;	and		sigma1 and sigma2 are cross sections from henke_phi.pro
;			rho1 and rho2 are gas densities using Ideal Gas Law
;				rho = Pressure / R / Temperature
;
;	and 	T_Be = transmission of Be filter
;			area_aperture = area of aperture
;
pro  xrs_qt, wavelength, qt, channel

if n_params() lt 3 then begin
  print, ' '
  print, 'USAGE:  xrs_qt, wavelength, qt, channel'
  print, '  '
  print, '         wavelength = wavelength output in Angstroms'
  print, '         qt = Quantum Throughput (QT) output in (electrons/photon) * cm^2'
  print, '         channel = "A" or "B" as input for which XRS channel to model'
  print, ' '
  print, 'NOTE 1: The Be filter and aperture area is part of the QT value returned.'
  print, 'NOTE 2: A correction for electron pair production is NOT included (yet).'
  print, ' '
  return
endif

DEBUG = 1

cell_length = 1.570 * 2.54		; 1.570 inches --> cm
R = 8.314						; gas constant units are J/deg mole
AN = 6.0222D23					; Avogardo's number (molecules/mole)
R_factor = 1D6 / AN				; convert mole/m^3 to molecules per cm^3 for "R"
temperature = 293.0				; Room temperature in K (STP is at 273 K though)
pressure_factor	= 133.3224		; convert "mm Hg" to Pascal
sigma_factor = 1D-24			; convert cross section in Barn to cm^2

channel = strupcase(strmid(channel,0,1))
if (channel ne 'A') and (channel ne 'B') then print, 'WARNING: assuming channel XRS-B...'

if (channel eq 'A') then begin
	; XRS-A has 180 mm Hg pressure of Xe and 0.9 mm Hg pressure of He
	gas1 = 'Xe'
	pressure1 = 180.
	gas2 = 'He'
	pressure2 = 0.9
	; XRS-A has Be window with thickness of 0.020"
	filter = 'Be'
	thickness = 0.020 * 2.54E8		; convert to Angstroms
	; XRS-A has area of 5.88 cm^2
	area = 5.88
endif else begin
	; XRS-B has 800 mm Hg pressure of Ar and 4.0 mm Hg pressure of He
	gas1 = 'Ar'
	pressure1 = 800.	
	gas2 = 'He'
	pressure2 = 4.0
	; XRS-B has Be window with thickness of 0.002"
	filter = 'Be'
	thickness = 0.002 * 2.54E8		; convert to Angstroms
	; XRS-B has area of 1.96 cm^2
	area = 1.96
endelse

henke_phi, gas1, wave1, sigma1
rho1 = pressure1 * pressure_factor / (R * R_factor) / temperature
tau1 = sigma1 * sigma_factor * rho1 * cell_length

henke_phi, gas2, wave2, sigma2
rho2 = pressure2 * pressure_factor / (R * R_factor) / temperature
tau2 = sigma2 * sigma_factor * rho2 * cell_length

filter, fwave, ftrans, element=filter, thickness=thickness

wavelength = wave1 			; assumes wave1 = wave2 = fwave
tausum = (tau1 + tau2) < 100.  ; limit tau so don't get overflow in exp()
qt = (1. - exp( -1. * tausum)) * ftrans * area

if (DEBUG ne 0) then begin
  !fancy = 4
  plot, wavelength, qt, xrange=[0,20], xtitle='Wavelength (Angstrom)', $
  		ytitle='QT (e!U-!N/photon/cm!U2!N)', title='XRS-'+channel
  ; stop, 'At end of xrs_qt.pro for debugging...'
endif

return
end
