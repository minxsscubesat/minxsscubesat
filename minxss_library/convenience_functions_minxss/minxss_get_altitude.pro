;+
; NAME:
;   minxss_get_altitude
;
; PURPOSE:
;   Get the altitude corresponding to a specific time(s)
;
; INPUTS:
;   None -- but need to specify at least one of the optional inputs
;
; OPTIONAL INPUTS:
;   timeJd [dblarr]: Time(s) in Julian date format
;   timeIso [strarr]: Time(s) in ISO format
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   altitude [fltarr]: Altitude(s) for MinXSS-1 corresponding to the input time(s)
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS software package
;
; EXAMPLE:
;   altitudes = minxss_get_altitude(hk.time_jd) ; To get all altitudes corresponding to your MinXSS housekeeping data
;
; MODIFICATION HISTORY:
;   2017-04-07: James Paul Mason: Wrote script.
;-
FUNCTION minxss_get_altitude, timeJd = timeJd, timeiso = timeIso

; Input check
IF timeIso NE !NULL THEN BEGIN
  timeJd = JPMiso2jd(timeIso)
ENDIF

; Defaults
noradId = 41474L ; MinXSS-1

spacecraft_location, timeJd, spacecraftLocation, sunlightFlag, id_satellite = noradId, tle_path = getenv('TLE_dir'), /KEEPNAN

longitude = reform(spacecraftLocation[0, *])
latitude = reform(spacecraftLocation[1, *])
altitude = reform(spacecraftLocation[2, *]) - 6371. ; Subtract off Earth-radius to get altitude

altitude[where(altitude GT 450 OR altitude LT 100)] = !VALUES.F_NAN

return, altitude
END

