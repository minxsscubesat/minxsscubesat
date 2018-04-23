;
;	fletcher_checksum.pro
;
;	Calculate Fletcher Checksum
;	A=B=0 then sum:
;		A = (A + Data[i]) modulus 255
;		B = (B + A) modulus 255
;
function fletcher_checksum, array, modulus=modulus, debug=debug

	if keyword_set(modulus) then modnum = fix(modulus[0]) else modnum = 255

	A = 0
	B = 0
	kmax = n_elements(array)

	for k=0,kmax-1 do begin
	   A = (A + byte(array[k])) mod modnum
	   B = (B + A) mod modnum
	endfor

    if keyword_set(debug) then print, 'fletcher_checksum: (hex) ', A, B, format='(A18,2Z4)'

	return, byte([A, B])
end
