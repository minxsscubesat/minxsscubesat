;
;	minxss_cal2_from_cal1.pro
;
;	create MinXSS-2 Calibration File from MinXSS-1 Calibration File
;
;	12/06/2021	Tom Woods:  See the WORD document "MinXSS_2_calibration_update_2021_12_06.docx"
;
;	.run minxss_cal2_from_cal1.pro
;

;
;	Read MinXSS-1 Calibration Data File
;
cal1_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm1_response_structure.sav'
print, 'Restoring MinXSS-1 Calibration data from ', cal1_file
restore, cal1_file
; save as reference for comparison plots
mdr1 = minxss_detector_response

;
;  Updates for MinXSS-2 calibration response information
;
;  Version number
minxss_detector_response.VERSION = 'V2'
;  Version date
minxss_detector_response.VERSION_DATE = '2021-12-06'
;  Flight Model number
minxss_detector_response.FLIGHT_MODEL = 'FM2'
;  Energy Offset for Ground Calibrations
minxss_detector_response.X123_ENERGY_OFFSET_KEV = -0.265
;  Energy Offset for on-orbit solar spectra
minxss_detector_response.X123_ENERGY_OFFSET_KEV_ORBIT = -0.2108  ; **** flare spectrum compared to FM1 *****
;  Be filter thickness in microns
minxss_detector_response.X123_BE_FIT_THICKNESS_UM = 11.2
;  Photoelectron Efficiency based on Be thickness = exp(-thickness/tau) where tau=20.93 microns
minxss_detector_response.X123_PHOTOELECTRON_EFFICIENCY_YIELD = exp(-11.2/20.93)
;  Recalculate Be Photoelectron Efficiency based on new Photoelectron Yield
minxss_detector_response.X123_PHOTOELECTRON_SPECTRAL_DETECTION_EFFICIENCY =   $
	minxss_detector_response.X123_PHOTOELECTRON_WINDOW_YIELD_SPECTRAL_DETECTION_EFFICIENCY $
	* minxss_detector_response.X123_PHOTOELECTRON_EFFICIENCY_YIELD
;  Different X123 has better energy resolution
minxss_detector_response.X123_NOMINAL_SPECTRAL_RESOLUTION = 0.168
;  Recalculate energy resolution with N=13.6 for FM2 (versus N=24 for FM1)
;		FWHM = 2.35 * w * sqrt( Fano * E / w + N^2 )     also convert from eV to keV (1E-3)
		ENERGY_EV = 1E3 * minxss_detector_response.PHOTON_ENERGY
		ENERGY_N = 13.6
minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY = 2.35 * 3.68E-3 * $
	sqrt( 0.12 * ENERGY_EV / 3.68 + ENERGY_N^2. )
;  FM2 X123 has slow count peaking time of 1.2 microsec
minxss_detector_response.X123_4_8_US_PEAKING_TIME = 1.20E-6
;  FM2 X123 has improved linearity performance due to shorter peaking time of 1.2 microsec
minxss_detector_response.X123_4_8_US_DEADTIME = 3.45E-6
;  X123 Geometric Aperture area:   ASSUMES 178 micron diameter like FM1  ***** TO CHECK *****
minxss_detector_response.X123_APERTURE_GEOMETRIC_AREA = !pi * (0.0178/2.)^2
;  FM2 response based on Si response (same as FM1) * Be filter transmission
;		FM2 Be thickness = 11.2 microns (versus 24 microns for FM1) + Zn contamination
;		Be filter transmission is calculated using Henke model and stored in special cal file (nm vs transmission)
	be_filter_cal_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm2_be_zn_filter_transmission.dat'
	be_trans = read_dat( be_filter_cal_file )  ;  [0,*] = nm, [1,*] = transmission
	be_trans_energy = interpol( reform(be_trans[1,*]), reform(be_trans[0,*]), minxss_detector_response.PHOTON_WAVELENGTH )
minxss_detector_response.X123_SPECTRAL_EFFICIENCY = $
	minxss_detector_response.X123_SI_SPECTRAL_DETECTION_EFFICIENCY $
	* be_trans_energy
; X123_BE_FIT_SPECTRAL_EFFICIENCY is same thing as X123_SPECTRAL_EFFICIENCY
minxss_detector_response.X123_BE_FIT_SPECTRAL_EFFICIENCY = minxss_detector_response.X123_SPECTRAL_EFFICIENCY
; X123 Recalculate effective area based on different Be filter thickness and different aperture area
minxss_detector_response.X123_EFFECTIVE_AREA = $
	minxss_detector_response.X123_SPECTRAL_EFFICIENCY * minxss_detector_response.X123_APERTURE_GEOMETRIC_AREA

;
;	Save new (Version 2) FM2 calibration data results
;
cal2_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm2_response_structure_Ver2.sav'
print, ' '
print, 'Saving MinXSS-2 Calibration file into ', cal2_file
print, ' '
print, '*****  AFTER validating the new MinXSS-2 calibration data, you can rename *_Ver2.sav to just *.sav'
print, ' '
save, minxss_detector_response, file=cal2_file

end


