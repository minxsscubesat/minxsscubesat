;
;	goes_xrs_class.pro
;
;	Convert between GOES XRS-B irradiance and Flare Class (both directions)
;
;	10/1/2022   T. Woods
;
function goes_xrs_class, xrs_in

xtype = size( xrs_in, /type )
num_in = n_elements(xrs_in)

if (xtype eq 7) then begin
	; convert from flare-class STRING to XRS irradiance value
	result = fltarr(num_in)
	for ii=0,num_in-1 do begin
		ltr = strupcase(strmid(xrs_in[ii],0,1))
		temp = strmid(xrs_in[ii],1,10)
		result[ii] = float(temp)
		case ltr of
			'A': result[ii] *= 1E-8
			'B': result[ii] *= 1E-7
			'C': result[ii] *= 1E-6
			'M': result[ii] *= 1E-5
			'X': result[ii] *= 1E-4
			else: result[ii] = 1E-8	;  don't know what value it should be; set to minimum value
		endcase
	endfor
endif else begin
	; convert from a number to flare-class STRING
	result = strarr(num_in)
	for ii=0,num_in-1 do begin
		xrsb = xrs_in[ii] > 1E-8	; force to be greater than minimum value
		if (xrsb lt 9.95E-8) then result[ii] = 'A' + string(xrsb/1E-8,format='(F3.1)') $
		else if (xrsb lt 9.95E-7) then result[ii] = 'B' + string(xrsb/1E-7,format='(F3.1)') $
		else if (xrsb lt 9.95E-6) then result[ii] = 'C' + string(xrsb/1E-6,format='(F3.1)') $
		else if (xrsb lt 9.95E-5) then result[ii] = 'M' + string(xrsb/1E-5,format='(F3.1)') $
		else if (xrsb lt 9.95E-4) then result[ii] = 'X' + string(xrsb/1E-4,format='(F3.1)') $
		else result[ii] = 'X' + string(xrsb/1E-4,format='(F4.1)')
	endfor
endelse

return, result
end
