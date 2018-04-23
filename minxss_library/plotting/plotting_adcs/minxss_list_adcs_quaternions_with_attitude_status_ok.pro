;+
; NAME:
;   minxss_list_adcs_quaternions_with_attitude_status_ok
;
; PURPOSE:
;   Create a list of all quaternions with tracker attitude status = "OK"
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   csv file of all quaternions with tracker attitude status = "OK"
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-01-09: James Paul Mason: Wrote script.
;-
PRO minxss_list_adcs_quaternions_with_attitude_status_ok, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
smoothNumberOfPoints = 1000

; Restore the level 0c data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Find where tracker attitude status is OK
okTrackerStatusIndices = where(adcs3.tracker_attitude_status EQ 0)

; Loop through all the adcs3 packets with tracker status = ok and find where (if any) adcs1 packets are within 2 minutes
FOR i = 0, n_elements(okTrackerStatusIndices) - 1 DO BEGIN
  time3Jd = adcs3[okTrackerStatusIndices[i]].time_jd
  time1ClosestIndex = closest(time3Jd, adcs1.time_jd, /DECIDE)
  deltaTMinutes = abs(time3Jd - adcs1[time1ClosestIndex].time_jd) * 24. * 60.
  IF deltaTMinutes LT 2. THEN BEGIN

    ; Store quaternions
    quaternion1 = (quaternion1 NE !NULL) ? [quaternion1, adcs1[time1ClosestIndex].attitude_quaternion1] : adcs1[time1ClosestIndex].attitude_quaternion1
    quaternion2 = (quaternion2 NE !NULL) ? [quaternion2, adcs1[time1ClosestIndex].attitude_quaternion2] : adcs1[time1ClosestIndex].attitude_quaternion2
    quaternion3 = (quaternion3 NE !NULL) ? [quaternion3, adcs1[time1ClosestIndex].attitude_quaternion3] : adcs1[time1ClosestIndex].attitude_quaternion3
    quaternion4 = (quaternion4 NE !NULL) ? [quaternion4, adcs1[time1ClosestIndex].attitude_quaternion4] : adcs1[time1ClosestIndex].attitude_quaternion4

    ; Store time
    timeHuman = (timeHuman NE !NULL) ? [timeHuman, adcs3[okTrackerStatusIndices[i]].time_human] : adcs3[okTrackerStatusIndices[i]].time_human
    timeJd = (timeJd NE !NULL) ? [timeJd, adcs3[okTrackerStatusIndices[i]].time_jd] : adcs3[okTrackerStatusIndices[i]].time_jd
  ENDIF

ENDFOR

write_csv, saveloc + 'Quaternions With Good Attitude Status.csv', timeHuman, timeJd, quaternion1, quaternion2, quaternion3, quaternion4, $
           HEADER = ['Date/Time [ISO]', 'Date [Julian]', 'Quaternion1', 'Quaternion2', 'Quaternion3', 'Quaternion4']

END