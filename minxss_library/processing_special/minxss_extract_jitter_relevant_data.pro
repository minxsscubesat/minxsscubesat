;+
; NAME:
;   minxss_extract_jitter_relevant_data
;
; PURPOSE:
;   Extract some data for analysis of jitter
;
; INPUTS:
;   None (hardcoded call to L0C data)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   CSV file with relevant data
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to L0C file
;
; EXAMPLE:
;   Just run it
;-
PRO minxss_extract_jitter_relevant_data

restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length_v2.sav'

time_iso = adcs3.time_iso
adcs_mode = ISHFT(adcs3.adcs_info AND '01'X, 0)
sun_point_angle_error = adcs3.sun_point_angle_error
attitude_error_x = adcs3.attitude_error2 * !RADEG
attitude_error_y = adcs3.attitude_error1 * !RADEG
attitude_error_z = adcs3.attitude_error3 * !RADEG

write_csv, 'MinXSS-1 Extracted Data for Jitter Analysis.csv', time_iso, adcs_mode, sun_point_angle_error, attitude_error_x, attitude_error_y, attitude_error_z, header = ['Time (ISO)', 'ADCS Mode (1 = Fine Reference, 0 = Coarse Sun Point)', 'Sun Point Angle Error [deg]', 'X Error [deg]', 'Y Error [deg]', 'Z Error [deg]']

STOP

END