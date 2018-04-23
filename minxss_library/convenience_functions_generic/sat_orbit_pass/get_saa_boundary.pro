;+
; NAME:
;   get_saa_boundary
;
; PURPOSE:
;   Returns the boundary of the south atlantic anamoly in latitude and longitude. 
;   These values were determined with this map: http://www.aeronomie.be/multimedia/images/actueel/2013-ept-worldMap-electrons-800keV.png 
;   from ESA PROBA-V, and GraphClick was used to select the SAA points. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set to print processing messages
;
; OUTPUTS:
;   Returns a structure with latitude and longitude of the SAA boundary
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   saaBoundaryLatLon = get_saa_boundary()
;
; MODIFICATION HISTORY:
;   2016/07/25: James Paul Mason: Wrote script.
;-
FUNCTION get_saa_boundary, VERBOSE = VERBOSE

lat = [2.23, 4.397, 4.935, 4.397, -0.252, -4.546, -9.198, -11.701, -15.458, -19.192, -24.538, -28.093, -32.007, $
       -36.838, -36.701, -40.809, -45.817, -47.385, -51.141, -57.493, -60.67, -61.028, -61.028, -59.039, -59.755, $
       -50.369, -37.355, -25.791, -18.323, -11.188, -4.613, -1.458, 2.098]

lon = [-71.679, -59.046, -42.545, -24.567, -13.899, -6.477, 3.396, 13.303, 25.35, 31.701, 36.639, 39.949, 39.154, 38.359, $
       39.39, 31.039, 21.443, 12.43, 0.415, -10.949, -22.964, -37.84, -51.819, -68.387, -83.229, -96.434, -94.779, -96.434, $
       -97.54, -97.54, -93.431, -82.797, -70.539]

return, {lat:lat, lon:lon}

END