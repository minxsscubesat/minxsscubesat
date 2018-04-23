;
;	surf_bc_correction.pro
;
;	Correct SURF Beam Current (BC) monitor with results from GOES-R EXIS FM1 calibrations (March 2013)
;
;	Usage:   
;	IDL>  new_bc = surf_correct_bc( old_bc )
;				where BC is in mA
;
;	History: 
;	3/25/13		T. Woods	Original Code based on EUVS-A,B,C1 and XRS-A1,A2,B2 data (3/13)
;	4/7/13		T. Woods	Updated as correction is intended for dividing into "signal/BC"
;
function surf_correct_bc, old_bc

if n_params() lt 1 then begin
  print, 'USAGE:  new_bc = surf_bc_correction( old_bc )'
  return, -1L
endif

;
;	5th order polynomial fit over 1 mA - 405 mA  (T. Woods, 3/25/13)
;
coeff = [ 0.99091212, 0.00017359097,  -1.3086574D-06, 6.1487730D-09, -1.3227685D-11, 1.0506390e-14]
ncoeff = n_elements(coeff)

;	Make correction factor
;		Note that coefficients are 1.000 for 100 mA, but assume here BC is accurate near 0 mA
;
correction = coeff[0]
for k=1L,ncoeff-1 do correction += (coeff[k] * (old_bc^k))
correction /= coeff[0]	; re-normalize for correction at 0 mA

;
;	apply correction
;	Updated 4/7/13 to be * instead of /  (correction is for dividing into "signal/BC")
;
new_bc = old_bc * correction

return, new_bc
end
