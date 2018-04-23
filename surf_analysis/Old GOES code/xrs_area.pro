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
;	1/19/10		Tom Woods	 - Original file creation
; 3/10/13   Amir Caspi - add rounded corners to all apertures, update A2/B2 areas
; 10/28/13  Amir Caspi - update areas to reflect design, allow FM1-specific areas for A2/B2
;+

function xrs_area, channel, fm=fm
;
;	1.  Check input parameters
;
if n_params() lt 1 then begin
  print, 'USAGE: slit_area_cm2 = xrs_area( channel )'
  return, -1
endif

ch = strmid(strupcase(channel),0,2)
if not keyword_set(fm) then fm=0

;
;	2.	Return "area"
;		first specified in mm^2 then converted to cm^2
;
if (ch eq 'B1') or (ch eq 'A1') then begin
  ; 9 mm per side with 0.2 mm radius corners
  area = 8.999 * 8.999 - (0.2032^2 * (4 - !dpi))
endif else if (ch eq 'A2') then begin
  ; Approx 2.12 mm per side, but remove 0.105 mm dead space between pixels, plus 0.2 mm radius corners
  area = ((fm eq 1 ? 2.114 : 2.121) - 0.105) * ((fm eq 1 ? 2.129 : 2.121) - 0.105) - (0.2032^2 * (4 - !dpi))
endif else if (ch eq 'B2') then begin
  ; Approx 2.12 mm per side, but remove 0.105 mm dead space between pixels, plus 0.2 mm radius corners
  area = ((fm eq 1 ? 2.102 : 2.121) - 0.105) * ((fm eq 1 ? 2.127 : 2.121) - 0.105) - (0.2032^2 * (4 - !dpi))
endif else begin
  print, 'ERROR xrs_area(): Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return, -1
endelse

area = area / 100.		; mm^2 --> cm^2
return, area

end
