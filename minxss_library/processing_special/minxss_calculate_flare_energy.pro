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

version_number = '4.0.0'

; Constants
h = 6.62607015d-34 ; [m2 kg / s]
c = 299792458d ; [m/s]
kev2J = 1.60218e-16 


restore, getenv('minxss_data') + 'fm1/level1/minxss1_l1_mission_length_v' + version_number + '.sav'
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


FOR i = 0, n_elements(indices_time) - 1 DO BEGIN
  ; Convert photons to Joules
  energy_j = energy_bins_kev * kev2J
  mean_energy = mean(energy_j)
  spectral_irradiance_this_time = spectral_irradiance[*, i] * energy_j ; [J/sec/cm2/keV]
  
  ; Integrate spectrally
  tmp = int_tabulated(energy_bins_kev, spectral_irradiance_this_time)
  irradiance = (n_elements(irradiance) EQ 0) ? tmp : [irradiance, tmp] ; [J/sec/cm2]
ENDFOR

; Convert cm2 to m2
irradiance *= 1e2^2 ; [W/m2]

print, jpmprintnumber(max(irradiance), /EXPONENT_FORM)

p = plot(energy_bins_kev, spectral_irradiance[*, 0], thick=2, $ 
         title='2016-07-24 06:20:00 M2 Flare (v' + version_number + ') | peak irradiance = ' + jpmprintnumber(max(irradiance), /SCIENTIFIC_NOTATION) + 'W/m$^2$', $
         xtitle='energy [keV]', xrange=[1,8], $
         /YLOG, ytitle='spectral irradiance [photons/sec/cm$^2$/keV]', yrange=[1e3, 1e8])
FOR i = 1, n_elements(irradiance) - 1 DO BEGIN
  p2 = plot(energy_bins_kev, spectral_irradiance[*, i], /OVERPLOT, thick=2, color=JPMColors(i, totalPointsForGradient=n_elements(irradiance)))
ENDFOR

STOP
END