;
;	hex_to_bin.pro
;
;	Convert SDR packets in Hex to Binary file
;	Line Format expected:   AAAA: XX XX ... XX
;		where AAAA is address in Hex and XX are data in Hex
;
pro minxss_hex_to_bin, hex_file

openr,lun,hex_file,/get_lun
print,'Writing BIN file to ', hex_file+'.bin'
openw,lun2,hex_file+'.bin',/get_lun
a = ' '
addr=0L
abytes=uintarr(16)
zformat='(Z4,A2,16Z3)'
while not eof(lun) do begin
	; readf,lun,addr,abytes,format=zformat
	readf,lun,a
	arr = strsplit(a,extract)
	if (n_elements(arr) gt 1) then begin
		for k=1,n_elements(arr) do begin
			aStr = strupcase(arr[k])
			aChar1 = byte(strmid(aStr,0,1))
			if (aChar1 ge 65 and aChar1 le 70) then abyte = (aChar1-55)*16 else abyte = (aChar1-48)*16
			aChar2 = byte(strmid(aStr,1,1))
			if (aChar2 ge 65 and aChar2 le 70) then abyte = (aChar2-55)*16 else abyte = (aChar2-48)*16
	  		writef,lun2,abyte
	  	endfor
	endif
endwhile

close,lun
close,lun2
free_lun,lun
free_lun,lun2
end
