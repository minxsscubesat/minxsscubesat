;+
; NAME:
;   HeaderTemplate
;
; PURPOSE:
;   Pulled from www.idlcoyote.com/tips/centroid.html. Computes a center of mass centroid on any given 2D array. 
;
; INPUTS:
;   array [any type]: A 2D array on which the centroid will be computed. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   [xcm, ycm] [float, float]: The center of mass for x any y, respectively. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   centroidCoordinates = centroid(findgen(10, 10))
;
; MODIFICATION HISTORY:
;   2015/04/21: James Paul Mason: Copied script from IDL coyote, who got it from David Foster at UCSD. 
;-
FUNCTION Centroid, array
ndim = Size(array, /N_Dimensions)
  IF ndim NE 2 THEN BEGIN
    Message, 'Array must be two-dimensional. Returning...', /Informational
    RETURN, -1
  ENDIF

  s = Size(array, /Dimensions)
  totalMass = Total(array)

  xcm = Total( Total(array, 2) * Indgen(s[0]) ) / totalMass
  ycm = Total( Total(array, 1) * Indgen(s[1]) ) / totalMass

  RETURN, [xcm, ycm]
END