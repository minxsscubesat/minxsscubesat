;+
; NAME:
;   minxss_merge_tvac_telemetry
;
; PURPOSE:
;   Merge the level 0C daily data into a single file for TVAC
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   fm [integer]: The flight model of MinXSS to process, either 1 or 2. Default is 2. 
;
; KEYWORD PARAMETERS:
;   PROCESS_RAW_TO_LEVEL0C: Set this to process the raw HYDRA telemetry binaries to level 0b then level 0c
;   VERBOSE:                Set this to print processing messages to console
;
; OUTPUTS:
;   IDL saveset in level0c folder with merged data
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS IDL code package
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016/08/21: James Paul Mason: Wrote script.
;-
PRO minxss_merge_tvac_telemetry, fm = fm, $ 
                                 PROCESS_RAW_TO_LEVEL0C = PROCESS_RAW_TO_LEVEL0C, VERBOSE = VERBOSE

; Defaults
IF fm EQ !NULL THEN fm = 2

; Set time range
IF fm EQ 1 THEN BEGIN
  ; MinXSS-1 TVAC-2
  startyyyymmdd = 20150318L
  endyyyymmdd = 20150322L
ENDIF ELSE $ 
IF fm EQ 2 THEN BEGIN
  startyyyymmdd = 20160819L ; doy 232
  endyyyymmdd = 20160826L   ; doy 239
ENDIF
IF keyword_set(VERBOSE) THEN BEGIN
  message, /INFO, systime() + ' Setting TVAC start date to ' + strtrim(startyyyymmdd, 2)
  message, /INFO, systime() + ' Setting TVAC end date to ' + strtrim(endyyyymmdd, 2)
ENDIF

; Loop through each day to concatenate data
hkTemp = !NULL
sciTemp = !NULL
logTemp = !NULL
adcs1Temp = !NULL
adcs2Temp = !NULL
adcs3Temp = !NULL
adcs4Temp = !NULL
FOR yyyymmdd = startyyyymmdd, endyyyymmdd DO BEGIN ; FIXME: Will break across month/year boundaries, but actual test periods don't do this
  yyyydoy = JPMyyyymmdd2yyyydoy(yyyymmdd, /RETURN_STRING)
  yyyydoyString = strmid(yyyydoy, 0, 4) + '_' + strmid(yyyydoy, 4, 3)
  
  ; Optionally process HYDRA binary telemetry up to level 0c
  IF keyword_set(PROCESS_RAW_TO_LEVEL0C) THEN BEGIN
    minxss_make_level0b, fm = fm, yyyydoy = long(yyyydoy), VERBOSE = VERBOSE
    minxss_make_level0c, fm = fm, yyyydoy = long(yyyydoy), VERBOSE = VERBOSE
  ENDIF
  
  ; Restore the daily data
  savesetFilename = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss' + strtrim(fm, 2) + '_l0c_' + yyyydoyString + '.sav'
  IF file_test(savesetFilename) THEN restore, savesetFilename ELSE CONTINUE
  
  IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Restoring file: ' + savesetFilename
  
  ; Concatenate the daily data
  IF hk NE !NULL THEN hkTemp = [hkTemp, hk]
  IF sci NE !NULL THEN sciTemp = [sciTemp, sci]
  IF log NE !NULL THEN logTemp = [logTemp, log]
  IF adcs1 NE !NULL THEN adcs1Temp = [adcs1Temp, adcs1]
  IF adcs2 NE !NULL THEN adcs2Temp = [adcs2Temp, adcs2]
  IF adcs3 NE !NULL THEN adcs3Temp = [adcs3Temp, adcs3]
  IF adcs4 NE !NULL THEN adcs4Temp = [adcs4Temp, adcs4]
ENDFOR

; Rename variables
hk = temporary(hkTemp)
sci = temporary(sciTemp)
log = temporary(logTemp)
adcs1 = temporary(adcs1Temp)
adcs2 = temporary(adcs2Temp)
adcs3 = temporary(adcs3Temp)
adcs4 = temporary(adcs4Temp)

; Write to disk
save, hk, sci, log, adcs1, adcs2, adcs3, adcs4, FILENAME = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss' + strtrim(fm, 2) + '_l0c_all_tvac.sav'
IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Saved to file: ' + getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0c/minxss' + strtrim(fm, 2) + '_l0c_all_tvac.sav'

END