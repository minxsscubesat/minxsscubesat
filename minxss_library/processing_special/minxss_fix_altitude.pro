;+
; NAME:
;   minxss_fix_altitude
;
; PURPOSE:
;   With too few TLEs downloaded from routine processing, the altitude calculation can go crazy. 
;   I've replaced the TLE file (00041474.tle) with all TLEs for MinXSS available on space-track.org. 
;   Routine processing may restore this file to its old style, however. 
;   Rather than run minxss_make_level0d again, I'll just recompute the orbital parameters and replace them in 
;   the 0d mission length file. 
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
;   Replaces the minxss_level0d file
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss level 0d mission length file
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2017-01-06: James Paul Mason: Wrote script.
;-
PRO minxss_fix_altitude

; Restore level 0d file
restore, getenv('minxss_data') + '/fm1/level0d/minxss1_l0d_mission_length.sav'

; Recompute the orbit info, and replace it in the level 0d file
spacecraft_location, minxsslevel0d.time.jd, spacecraftLocation, sunlightFlag, ID_SATELLITE = 41474L, TLE_PATH = getenv('TLE_dir')
longitude = float(reform(spacecraftLocation[0, *]))
latitude = reform(spacecraftLocation[1, *])
altitude = reform(spacecraftLocation[2, *]) - 6371. ; Subtract off Earth-radius to get altitude

numberMissingElements = n_elements(minxsslevel0d) - n_elements(spacecraftLocation[0, *])
IF numberMissingElements GT 0 THEN BEGIN
  filler = fltarr(numberMissingElements) & filler[*] = !VALUES.F_NAN
  longitude = [longitude, filler]
  latitude = [latitude, filler]
  altitude = [altitude, filler]
ENDIF

absurdIndices = where(altitude GT 500.) 
longitude[absurdIndices] = !VALUES.F_NAN
latitude[absurdIndices] = !VALUES.F_NAN
altitude[absurdIndices] = !VALUES.F_NAN

minxsslevel0d.longitude = longitude
minxsslevel0d.latitude = latitude
minxsslevel0d.altitude = altitude

; Save the minxss level 0d file
save, minxsslevel0d, FILENAME = getenv('minxss_data') + '/fm1/level0d/minxss1_l0d_mission_length_fixed_altitude.sav'

END