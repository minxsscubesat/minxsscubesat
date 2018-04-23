;+
; PROJECT:
;       SDAC
; NAME:
;	F_DIV
;
; PURPOSE:
;	THIS FUNCTION RETURNS THE QUOTIENT WITH ZERO CHECKING.
;
; CATEGORY:
;	MATH, NUMERICAL ANALYSIS, UTILITY
;
; CALLING SEQUENCE:
;	Result = F_DIV( Numerator, Denominator)
;
; EXAMPLES:
;	count_sec = f_div( total(counts,1) , delta_t )
;	count_sec_prm = f_div( count_sec , 1.- f_div(dead_channel # counts,delta_t) )
;
; INPUTS:
;	NUMERATOR - dividend in a quotient
;	DENOMINATOR - divisor in a quotient
;
; KEYWORDS:
;	DEFAULT - if DENOMINATOR is zero, value is set to 0.0 or to DEFAULT. (INPUT)
;
; PROCEDURE:
;	The divisor is scanned for zeroes which are excluded from the quotient.
;	The value for those elements is 0.0 or the DEFAULT.
; RESTRICTIONS:
; 	Real numbers only.
;
; COMMON BLOCKS:
;	None.
; MODIFICATION HISTORY:
;
;	mod, 22-dec-93, ras, returns vector if numerator or denominator are vectors and other scalar
;	ras, 17-jun-94 renamed div to f_div
;	ras, 14-oct-94, liberal use of temporary
;	Version 4, richard.schwartz@gsfc.nasa.gov, 7-sep-1997, more documentation
;	Version 5, richard.schwartz@gsfc.nasa.gov, 26-jul-2002, made the division work like
;		IDL's division operator.  The size of the quotient follows the size of the normal
;		division operator.  Previously, the size of the quotient was the same as the size of
;		the denominator.
;	22-jan-2003, richard.schwartz@gsfc.nasa.gov, return DENOMINATOR to original values
;		if changed.
;	1-APR-2009, richard.schwartz@nasa.gov, modify copies of inputs to ensure that
;		these values are unchanged by the code as was possible before.
;-

FUNCTION F_DIV, NUMERATOR, DENOMINATOR, DEFAULT = DEFAULT

the_numerator = numerator
the_denominator = denominator
if (size(THE_NUMERATOR))(0) eq 0 then THE_NUMERATOR = THE_NUMERATOR + 0.0 * THE_DENOMINATOR
if (size(THE_DENOMINATOR))(0) eq 0 then THE_DENOMINATOR = THE_DENOMINATOR + 0.0 * THE_NUMERATOR
;
ZZERO = where( THE_DENOMINATOR eq 0.0, NZERO)
;
IF (NZERO GE 1) then begin
	NRESULT = N_ELEMENTS(THE_NUMERATOR)<N_ELEMENTS(THE_DENOMINATOR)
	WKEEP = WHERE( ZZERO LE (NRESULT-1), NKEEP)
	IF NKEEP GE 1 THEN BEGIN
		ZZERO = ZZERO(WKEEP)
		THE_DENOMINATOR(ZZERO) = 1
		ENDIF ELSE NZERO = 0

	ENDIF


RESULT      = THE_NUMERATOR / THE_DENOMINATOR

;
IF NZERO GE 1 THEN RESULT( ZZERO ) = Exist(Default) ? Default : 0.0
;
If (NZERO GE 1) THEN IF (NKEEP GE 1) THEN THE_DENOMINATOR(ZZERO) = 0.0
;
return, RESULT
end
