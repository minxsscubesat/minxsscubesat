;
;	x123_energy_array
;
;	Make X123 energy array
;
;	INPUT
;		FM		flight model number: 1, 2, or 3 for rocket
;
;	OUTPUT
;		energy	array of bin energy values
;
;	FM-1 Calibration:
;		MinXSS-1 Flight Calibration: Chris Moore
;
;	FM-2 Calibration:
;
;	FM-3 Calibration:
;		June 18, 2018 Solar Rocket Flight:  Bennet Schwab
;
function x123_energy_scale, fm

if (n_params() lt 1) then fm=3   ; default value
if (fm lt 1) then fm=1
if (fm gt 3) then fm=3

if fm eq 1 then begin
	;  FM=1
	b=0.0297500	; slope (0-30 keV range)
    a=-0.054308856
	energy=findgen(1024)*b+a
endif else if fm eq 2 then begin
	;  FM=2
	b=0.03	; slope (0-30 keV range)
    a=-0.01
	energy=findgen(1024)*b+a
endif else begin
	;  FM=3
	b=0.019942302	; slope (0-20 keV range)
    a=-0.0096026827
	energy=findgen(1024)*b+a
endelse

return, energy
end
