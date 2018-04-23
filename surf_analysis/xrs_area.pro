;+
; NAME:
;	xrs_area
;
; PURPOSE:
;	Return area of aperture for specified GOES XRS channel
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:  
;	area = xrs_area( channel )
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
;
; OUTPUTS:  
;	area		area in cm^2
;				-1 if error in parameters
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Return "area"
;
; MODIFICATION HISTORY:
;	1/19/10		Tom Woods	Original file creation
;
;+

function xrs_area, channel
;
;	1.  Check input parameters
;
if n_params() lt 1 then begin
  print, 'USAGE: slit_area_cm2 = xrs_area( channel )'
  return, -1
endif

ch = strmid(strupcase(channel),0,2)

;
;	2.	Return "area"
;		first specified in mm^2 then converted to cm^2
;
if (ch eq 'B1') then begin
  area = 9. * 9.
endif else if (ch eq 'B2') then begin
  area = 2.15 * 2.15
endif else if (ch eq 'A1') then begin
  area = 9. * 9.
endif else if (ch eq 'A2') then begin
  area = 2.15 * 2.15
endif else begin
  print, 'ERROR xrs_area(): Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return, -1
endelse

area = area / 100.		; mm^2 --> cm^2
return, area

end
