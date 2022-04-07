;
;	minxss_cal4_from_cal1.pro
;
;	create MinXSS-4 (IS1 DQAXSS)  Calibration File from MinXSS-1 Calibration File
;
;	12/06/2021	Tom Woods:  See the WORD document "MinXSS_2_calibration_update_2021_12_06.docx"
;	12/20/2021  Tom Woods:  Update with new energy offset comparing FM2 QS to DAXSS-2018
;	2/20/2022	Tom Woods:  FM4 Ver1: Make IS-1 DAXSS (MinXSS-4) calibration file
;	3/24/2022	Tom Woods:  FM4 Ver2: Update with correct units for daxss_response_final.sav "response"
;
;	.run minxss_cal4_from_cal1.pro
;

;
;	Read MinXSS-1 Calibration Data File
;
cal1_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm1_response_structure_Ver4.sav'
print, 'Restoring MinXSS-1 Calibration data from ', cal1_file
restore, cal1_file
; save as reference for comparison plots
mdr1 = minxss_detector_response

;
;	Read DAXSS Response file
;
daxss_response_file='/Users/twoods/Dropbox/minxss_dropbox/data/calibration/daxss_response_final.sav'
restore, daxss_response_file   ; energy, response
dax_energy = energy
dax_response = response   ; 3/24/2022: units are cm^2 * keV  (effective_area_cm^2 * bin_size_keV)
dax_bin_size = 0.0199706
dax_effective_area = response / dax_bin_size

;
;	make comparison plots of DAXSS to MinXSS-1
;
setplot & cc=rainbow(7)
  ENERGY_EV = 1E3 * minxss_detector_response.PHOTON_ENERGY
  ENERGY_N = 6.45
  daxss_energy_res = 2.35 * 3.68E-3 * sqrt( 0.12 * ENERGY_EV / 3.68 + ENERGY_N^2. )
  ENERGY_N1 = 24.0
  minxss1_energy_res = 2.35 * 3.68E-3 * sqrt( 0.12 * (ENERGY_EV > 0.0) / 3.68 + ENERGY_N1^2. )
  ratio_energy_res = minxss1_energy_res / daxss_energy_res
wgd = where(energy_ev gt 300.)
plot, energy_ev[wgd]/1000., ratio_energy_res[wgd], $
		xrange=[0,10], xs=1, yrange=[1,3.5], ys=1, $
		xtitle='Energy (keV)', ytitle='MinXSS-1 / IS1-DAXSS Energy Resolution'
oplot, [1,1], !y.crange, line=2
temp = min(abs(ENERGY_EV-1000.),w1kev)
xyouts, 1.5, ratio_energy_res[w1kev], string(ratio_energy_res[w1kev],format='(F3.1)')+' @ 1keV', charsize=2.5
ans=' '
read, 'Next Plot ? ', ans

minxss1_response = minxss_detector_response.X123_EFFECTIVE_AREA
plot, energy_ev[wgd]/1000., minxss1_response[wgd], $
		xrange=[0,10], xs=1, yrange=[1E-5,max(dax_effective_area)], ys=1, /ylog, $
		xtitle='Energy (keV)', ytitle='Effective Area'
oplot, dax_energy, dax_effective_area, color=cc[3]
read, 'Next Plot ? ', ans

ratio_response = interpol( dax_effective_area, dax_energy, energy_ev/1000.) / minxss1_response
plot, energy_ev[wgd]/1000., ratio_response[wgd], $
		xrange=[0,10], xs=1, yrange=[0,80.]*10., ys=1, $
		xtitle='Energy (keV)', ytitle='IS1-DAXSS / MinXSS-1 Effective Area'
oplot, [4,4], !y.crange, line=2
temp = min(abs(ENERGY_EV-4000.),w4kev)
xyouts, 4.2, ratio_response[w4kev]+100., string(ratio_response[w4kev],format='(F5.1)')+' @ 4keV', charsize=2.5
read, 'Next Plot ? ', ans

; stop, 'DEBUG comparison plots...'

;
;  Updates for MinXSS-4 calibration response information
;
;  Version number
minxss_detector_response.VERSION = 'V1'
;  Version date
minxss_detector_response.VERSION_DATE = '2022-03-05'
;  Flight Model number
minxss_detector_response.FLIGHT_MODEL = 'FM4'
;  Energy scale for Ground Calibrations
minxss_detector_response.X123_ENERGY_GAIN_KEV_PER_BIN  = dax_bin_size
;  Energy Offset for Ground Calibrations
minxss_detector_response.X123_ENERGY_OFFSET_KEV = -0.00579901
;  Energy Offset for on-orbit solar spectra
minxss_detector_response.X123_ENERGY_OFFSET_KEV_ORBIT = -0.00939901  ; **** flare spectrum compared to reference lines 0.81-1.85 keV
;  Be filter thickness in microns
minxss_detector_response.X123_BE_FIT_THICKNESS_UM = 14.2  ; but DAXSS also has Kapton filter 24.74 microns
;  Photoelectron Efficiency based on Be thickness = exp(-thickness/tau) where tau=20.93 microns
minxss_detector_response.X123_PHOTOELECTRON_EFFICIENCY_YIELD = exp(-14.2/20.93)
;  Recalculate Be Photoelectron Efficiency based on new Photoelectron Yield
minxss_detector_response.X123_PHOTOELECTRON_SPECTRAL_DETECTION_EFFICIENCY =   $
	minxss_detector_response.X123_PHOTOELECTRON_WINDOW_YIELD_SPECTRAL_DETECTION_EFFICIENCY $
	* minxss_detector_response.X123_PHOTOELECTRON_EFFICIENCY_YIELD
;  Different X123 has better energy resolution
minxss_detector_response.X123_NOMINAL_SPECTRAL_RESOLUTION = 0.132
;  Recalculate energy resolution with N=6.45 for FM4 (versus N=24 for FM1)
;  DAXSS energy resolution is improved with N=6.45
;		FWHM = 2.35 * w * sqrt( Fano * E / w + N^2 )     also convert from eV to keV (1E-3)
		ENERGY_EV = 1E3 * minxss_detector_response.PHOTON_ENERGY
		ENERGY_N = 6.45
minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY = 2.35 * 3.68E-3 * $
	sqrt( 0.12 * ENERGY_EV / 3.68 + ENERGY_N^2. )
;  FM2 X123 has slow count peaking time of 1.2 microsec
minxss_detector_response.X123_4_8_US_PEAKING_TIME = 1.20E-6
;  FM2 X123 has improved linearity performance due to shorter peaking time of 1.2 microsec
minxss_detector_response.X123_4_8_US_DEADTIME = 3.45E-6
;  X123 Geometric Aperture area:   ASSUMES 178 micron diameter like FM1
;  For DAXSS use 0.813 mm Diameter
minxss_detector_response.X123_APERTURE_GEOMETRIC_AREA = !pi * (0.0813/2.)^2
;  FM2 response based on Si response (same as FM1) * Be filter transmission
;		FM2 Be thickness = 11.2 microns (versus 24 microns for FM1) + Zn contamination
;		Be filter transmission is calculated using Henke model and stored in special cal file (nm vs transmission)
	be_filter_cal_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm4_be_filter_transmission.dat'
	be_trans = read_dat( be_filter_cal_file )  ;  [0,*] = nm, [1,*] = transmission
	be_trans_energy = interpol( reform(be_trans[1,*]), reform(be_trans[0,*]), minxss_detector_response.PHOTON_WAVELENGTH )
;  DAXSS has special dual-zone aperture so use DAXSS_RESPONSE function as:
;		x123_spectral_efficiency = DAXSS_RESPONSE / NOMINAL_AREA
;		3/24/2022: Changed in next line from using dax_response to dax_effective_area
	DAXSS_RESPONSE = interpol( dax_effective_area, dax_energy, minxss_detector_response.PHOTON_ENERGY )
minxss_detector_response.X123_SPECTRAL_EFFICIENCY = $
	DAXSS_RESPONSE / minxss_detector_response.X123_APERTURE_GEOMETRIC_AREA
; X123_BE_FIT_SPECTRAL_EFFICIENCY is same thing as X123_SPECTRAL_EFFICIENCY
minxss_detector_response.X123_BE_FIT_SPECTRAL_EFFICIENCY = minxss_detector_response.X123_SPECTRAL_EFFICIENCY
; X123 Effective Area is the DAXSS_RESPONSE
minxss_detector_response.X123_EFFECTIVE_AREA = DAXSS_RESPONSE

;
;	Save new (Version 1) FM4 calibration data results
;
cal4_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm4_response_structure_Ver2.sav'
print, ' '
print, 'Saving MinXSS-4 (DAXSS) Calibration file into ', cal4_file
print, ' '
print, '*****  AFTER validating the new MinXSS-4 calibration data, you can rename *_Ver2.sav to just *.sav'
print, ' '
save, minxss_detector_response, file=cal4_file

end


