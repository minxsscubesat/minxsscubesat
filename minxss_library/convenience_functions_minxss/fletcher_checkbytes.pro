;
;	fletcher_checkbytes.pro
;
;	Calculate Fletcher CheckBytes
;		Calculate Fletcher Checksum first then
;			A_cb = 255 - (A+B) modulus 255
;           B_cb = 255 - (A+A_cb) modulus 255
;
;	Advantage of CheckBytes is if included in Array then new checksum on it = 0x0000
;
function fletcher_checkbytes, array, modulus=modulus

	if keyword_set(modulus) then modnum = fix(modulus[0]) else modnum = 255

	csum = fix(fletcher_checksum(array, modulus=modnum))
	a_cb = 255 - (csum[0]+csum[1]) mod modnum
	b_cb = 255 - (csum[0]+a_cb) mod modnum

	return, byte([a_cb, b_cb])
end
