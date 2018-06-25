;	read_csol_hex.pro
;
;	Read CSOL Hex image from its SD-Card
;		1504 x 2000 image per hex file
;
;	Tom Woods
;	6/22/2018
;
function read_csol_hex, file_hex, fuv=fuv, muv=muv, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE:  image = read_csol_hex( file_hex ) '
	return, -1L
endif

if file_test(file_hex) le 0 then begin
	print, 'ERROR: CSOL Hex File does not exist for ', file_hex
	return, -1L
endif

finfo = file_info( file_hex )
if (finfo.size lt (1504L*2000L*2L)) then begin
	print, 'ERROR: File size is not large enough for CSOL image: ', file_hex
	return, -1L
endif

image = uintarr(2000, 1504)

openr, lun, file_hex, /get_lun
ahex = assoc(lun, bytarr(1504*2L))

for i=0L,1999L do begin
	; process one column at a time
	raw = ahex[i]
	for j=0L,1503L do begin
		char1 = raw[j*2] & char2 = raw[j*2+1]
		image[i,j] = uint(char1) + ishft(uint(char2),8)
	endfor
endfor

close, lun
free_lun, lun

;	make FUV spectrum
fuv_dark = smooth(reform((float(image[*,370]) + float(image[*,720]))/2.),21,/edge_trun)
fuv = fltarr(2,2000)
fuv[0,*] = 111.42 + 0.0655 * findgen(2000)
fuv_sp = fltarr(2000)
for k=380,710 do begin
	fuv_sp = fuv_sp + float(reform(image[*,k])) - fuv_dark
endfor
fuv[1,*] = fuv_sp

;	make MUV spectrum
muv_dark = smooth(reform((float(image[*,790]) + float(image[*,1140]))/2.),21,/edge_trun)
muv = fltarr(2,2000)
muv[0,*] = 177.33 + 0.0620 * findgen(2000)
muv_sp = fltarr(2000)
for k=800,1130 do begin
	muv_sp = muv_sp + float(reform(image[*,k])) - muv_dark
endfor
muv[1,*] = muv_sp

if keyword_set(debug) then stop, 'DEBUG read_csol_hex...'
return, image
end
