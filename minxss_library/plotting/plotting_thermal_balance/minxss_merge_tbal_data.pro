;+
; NAME:
;   minxss_merge_tbal_data
;
; PURPOSE:
;   Merge the IDL level 0B savesets from thermal balance that spanned two days
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   IDL saveset with thermal balance data spanning 2 days into the path: minxss_data + /fm1/level0b/ with filename = TBAL March 2015.sav
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires that minxss_make_level0b was already run to generate the relevant level 0B files to be merged
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016/03/25: James Paul Mason: Wrote script. Also just reran minxss_make_level0b on the ISIS telemetry in order to extract more variables
;                                 like breaking out cdh_info into things like battery_heater_enable. 
;-
PRO minxss_merge_tbal_data

; Setup
dataloc = getenv('minxss_data') + '/fm1/level0b/'

; Restore the first day's data
restore, dataloc + 'minxss_l0b_2015_083.sav'

; Change variable names so that they aren't overwritten when restoring second days data
adcs1Day1 = temporary(adcs1)
adcs2Day1 = temporary(adcs2)
adcs3Day1 = temporary(adcs3)
adcs4Day1 = temporary(adcs4)
hkDay1 = temporary(hk)
logDay1 = temporary(log)
sciDay1 = temporary(sci)

; Restore second day's data
restore, dataloc + 'minxss_l0b_2015_084.sav'

; Merge data
adcs1Temp = [adcs1Day1, temporary(adcs1)]
adcs2Temp = [adcs2Day1, temporary(adcs2)]
adcs3Temp = [adcs3Day1, temporary(adcs3)]
adcs4Temp = [adcs4Day1, temporary(adcs4)]
hkTemp = [hkDay1, temporary(hk)]
logTemp = [logDay1, temporary(log)]
sciTemp = [sciDay1, temporary(sci)]

; For some reason, the data are doubled so fix it
adcs1 = !NULL
adcs2 = !NULL
adcs3 = !NULL
adcs4 = !NULL
hk = !NULL
log = !NULL
sci = !NULL
FOR i = 0, n_elements(adcs1Temp) - 1, 2 DO adcs1 = [adcs1, adcs1Temp[i]]
FOR i = 0, n_elements(adcs2Temp) - 1, 2 DO adcs2 = [adcs2, adcs2Temp[i]]
FOR i = 0, n_elements(adcs3Temp) - 1, 2 DO adcs3 = [adcs3, adcs3Temp[i]]
FOR i = 0, n_elements(adcs4Temp) - 1, 2 DO adcs4 = [adcs4, adcs4Temp[i]]
FOR i = 0, n_elements(hkTemp) - 1, 2 DO hk = [hk, hkTemp[i]]
FOR i = 0, n_elements(logTemp) - 1, 2 DO log = [log, logTemp[i]]
FOR i = 0, n_elements(sciTemp) - 1, 2 DO sci = [sci, sciTemp[i]]

; Save data
save, adcs1, adcs2, adcs3, adcs4, hk, log, sci, FILENAME = dataloc + 'TBAL March 2015.sav'

END