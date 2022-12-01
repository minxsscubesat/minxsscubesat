;+
; NAME:
;   minxss_calculate_flare_energy
;
; PURPOSE:
;
;
; INPUTS:
;
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
;
; RESTRICTIONS:
;
;
; EXAMPLE:
;
;-
PRO minxss_calculate_flare_energy

; Constants
h = 6.62607015d-34 ; [m2 kg / s]
c = 299792458d ; [m/s]
kev2J = 1.60218e-16 


restore, getenv('minxss_data') + 'fm1/level1/minxss1_l1_mission_length_v3.1.0.sav'
jd = minxsslevel1.x123.time.jd
energy_bins_kev = minxsslevel1.x123[0].energy
wave = h * c / (energy_bins_kev * kev2J) ; [m]
wave /= 1e-10 ; [Å]

;indices_time = where(jd GE jpmiso2jd('2016-07-24 05:50:00Z') AND jd LE jpmiso2jd('2016-07-24 07:15:00Z')) ; Flare 1 for CPHLARE
;indices_time = where(jd GE jpmiso2jd('2016-11-29 07:05:00Z') AND jd LE jpmiso2jd('2016-11-29 07:29:00Z')) ; Flare 2 for CPHLARE
indices_time = where(jd GE jpmiso2jd('2017-02-22 12:59:00Z') AND jd LE jpmiso2jd('2017-02-22 14:30:00Z')) ; Flare 3 for CPHLARE
indices_spectral = where(wave GE 1 AND wave LE 8)

spectral_irradiance = minxsslevel1.x123[indices_time].irradiance[indices_spectral] ; [photons/sec/cm2/keV]
energy_bins_kev = energy_bins_kev[indices_spectral]
jd = jd[indices_time]

; Integrate spectrally
FOR i = 0, n_elements(indices_time) - 1 DO BEGIN
  tmp = int_tabulated(energy_bins_kev, spectral_irradiance[*, i])
  irradiance = (n_elements(irradiance) EQ 0) ? tmp : [irradiance, tmp] ; [photons/sec/cm2]
ENDFOR

; Convert photons/s to W
energy_j = energy_bins_kev * kev2J
mean_energy = mean(energy_j)
irradiance *= mean_energy ; [W/cm2]

; Convert cm2 to m2
irradiance *= 1e2^2

print, jpmprintnumber(max(irradiance), /SCIENTIFIC_NOTATION)

STOP


END