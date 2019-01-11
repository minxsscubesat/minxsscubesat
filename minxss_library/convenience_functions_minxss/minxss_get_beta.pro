;+
; NAME:
;   minxss_get_beta
;
; PURPOSE:
;   Get the beta angle for MinXSS-1 over the duration of the mission. Because of atmospheric drag, the orbit profile
;   is changing constantly and a single TLE can't be used to determine beta over the mission. 
;   Fortunately, Tom's spacecraft_orbit_number code already stores beta angle for every orbit with TLEs downloaded 3 times a day. 
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
;   jdBeta [structure]: A structure that has the julian date (tag: jd) and beta angle (tag: beta)
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires the minxss_dropbox/tle/orbit_number/minxss_orbit_number.dat file
;   and same folder minxss_orbit_number_ascii_read_template.sav file, created with the IDL function ascii_template()
;
; EXAMPLE:
;   jdBeta = minxss_get_beta()
;
; MODIFICATION HISTORY:
;   2017-03-24: James Paul Mason: Wrote script.
;-
FUNCTION minxss_get_beta

; Restore the ascii interpreter template generated beforehand with ascii_template 
restore, '/Users/' + getenv('username') + '/Dropbox/minxss_dropbox/tle/orbit_number/minxss_orbit_number_ascii_read_template.sav'

; Read the data
minxssOrbitData = read_ascii('/Users/' + getenv('username') + '/Dropbox/minxss_dropbox/tle/orbit_number/minxss_orbit_number.dat', TEMPLATE = minxssOrbitNumberTemplate)

; Convert time to jd
yyyymmdd = JPMyyyydoy2yyyymmdd(minxssOrbitData.yyyydoy, /RETURN_STRING)
hhmmss = JPMsod2hhmmss(minxssOrbitData.sod, /RETURN_STRING)
iso = yyyymmdd + 'T' + hhmmss + 'Z'
jd = JPMiso2jd(iso)

; Prepare output
jdBeta = {jd:jd, beta:minxssOrbitData.beta}

return, jdBeta

END