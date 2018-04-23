FUNCTION range, min, max, INC=inc, NPTS=npts, RECIPROCAL=reciprocal, INTEGER=integer

; RANGE.PRO
;	Chris Chronopoulos, 2009
; Generates an arithmetic sequence of numbers ranging from min to max with increment inc.
; Alternative keyword: npts, the number of points to be uniformly distributed between min and max.
; Example calling sequence:
;	x=range(1.,10.,inc=0.1)
;	x=range(1.,10.,npts=150)
; Modification History:
;	02-09-2010 Added npts keyword option
; 08-16-2011: James Paul Mason: added reciprocal scaling
; 05-29-2012: James Paul Mason: added integer option

; Check to make sure only one keyword is specified

;	IF (KEYWORD_SET(inc) && KEYWORD_SET(npts)) THEN BEGIN
;		PRINT, 'ERROR: Please specify only one of the keywords INC or NPTS' 
;		RETURN, 0
;		END
;	ENDIF

; Define the increment, based one the keyword

	IF (keyword_set(inc) && ~keyword_set(npts)) THEN inc=inc
	IF (keyword_set(npts) && ~keyword_set(inc)) THEN inc=(max-min)/(npts-1)
	IF (keyword_set(reciprocal)) THEN inc=0
	IF (~keyword_set(inc) && ~keyword_set(npts)) THEN inc=1.

; Compute the output array
  
	IF inc NE 0 THEN $
	output=inc*(max-min)*findgen(round((max-min)/inc+1))/(max-min)+min
	
	IF inc EQ 0 THEN BEGIN
	   arr = fltarr(npts)
     arr(0)=0
     FOR i=0,npts-1 DO IF i GT 0 THEN arr(i) = arr(i-1) + 1/(arr(i-1)+1)
     xtop = arr(npts-1)
     output = float(min + arr*(max-min)/xtop)
	ENDIF
	
IF KEYWORD_SET(integer) THEN output = fix(output)
RETURN, output
END
