;
;	minxss_cal1_update.pro
;
;	Update MinXSS-1 Calibration File to fix X123 Energy Resolution Array
;
;	12/07/2021	Tom Woods:  See also the WORD document "MinXSS_2_calibration_update_2021_12_06.docx"
;
;	.run minxss_cal1_update.pro
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
;  Updates for MinXSS-1 calibration response information for X123 Energy Resolution Array
;
;  Version number
minxss_detector_response.VERSION = 'V5'
;  Version date
minxss_detector_response.VERSION_DATE = '2021-12-07'

;  Fix the X123 energy resolution array calculation
;  Recalculate energy resolution with N=24 for FM1
;		FWHM = 2.35 * w * sqrt( Fano * E / w + N^2 )     also convert from eV to keV (1E-3)
		ENERGY_EV = 1E3 * minxss_detector_response.PHOTON_ENERGY
		ENERGY_N = 24.0
minxss_detector_response.X123_SPECTRAL_RESOLUTION_ARRAY = 2.35 * 3.68E-3 * $
	sqrt( 0.12 * ENERGY_EV / 3.68 + ENERGY_N^2. )

;
;	Save new (Version 5) FM1 calibration data results
;
cal1b_file = '/Users/twoods/Dropbox/minxss_dropbox/data/calibration/minxss_fm1_response_structure_Ver5.sav'
print, ' '
print, 'Saving Revised MinXSS-1 Calibration file into ', cal1b_file
print, ' '
print, '*****  AFTER validating the new MinXSS-1 calibration data, you can rename *_Ver5.sav to just *.sav'
print, ' '
save, minxss_detector_response, file=cal1b_file

end


