;
;	csol_raw2image.pro
;
;	Convert Raw TM data for CSOL into image
;
;	Tom Woods
;	6/16/18
;
;	INPUT:
;		words is array of unsigned integers extracted from TM
;		wcount is number of words between Row 0 Sync of two Images
;		csol_data is assumed to be:
;	csol_meta = { time_counter: 0L, temp_det0: 0.0, temp_det1: 0.0, temp_fpga: 0.0, mon_5v: 0.0, $
;  				mon_current: 0.0, tec_enable: 0, led_enable: 0, integ_period: 0.0, $
;  				sdcard_start: 0U, sdcard_address: 0U, error_code: 0U }
;   csol_data = { time: 0.0D0, pixelerror: 0L, frameid: 0U, image: uintarr(csnumx,csnumy), $
;  				metadata: csol_meta }
;
pro csol_raw2image, words, wcount, csol_data

if (n_params() lt 3) then begin
  print, 'USAGE:  csol_raw2image, words, wcount, csol_data
  return
endif

image_size = size(csol_data.image)
if (image_size[0] ne 2) then begin
	print, 'ERROR with csol_data.image not being a 2-D array !'
	return
endif
icol = long(image_size[1])
irow = long(image_size[2])
isize = icol*irow
tmsize = (icol+1L)*(irow+6L)

;
;	only use non-filled data
;
temp = words[0:wcount-1]
; temp1 = shift(temp,-1)   ; logic of adjacent filled words is  "and (temp1 ne '7E7E'X)"
wgd = where((temp ne '7E7E'X), numgd )  ; CSOL Filler
pixelerror = (numgd - tmsize)/2L
csol_data.pixelerror = pixelerror
if (numgd lt tmsize) then begin
  print, 'WARNING: ', strtrim(abs(pixelerror),2), ' too few pixels for CSOL image @ ', $
  		strtrim(csol_data.time,2)
  ; stop, 'Check out CSOL image problem...'
endif
if (numgd gt tmsize) then begin
  print, 'WARNING: ', strtrim(abs(pixelerror),2), ' too many pixels for CSOL image @ ', $
  		strtrim(csol_data.time,2)
  ; stop, 'Check out CSOL image problem...'
endif
temp = temp[wgd]
;temp2 = uintarr(tmsize)
;if (numgd le tmsize) then temp2[0:numgd-1] = temp else temp2[*] = temp[0:tmsize-1]

;
;	sort the row packets into image and Row 2000 into Meta Data
;	checking for each row of data by Row packet SYNC values
;
fidmask = 'FFFF'X
fidvalue1 = '5555'X
fidoffset1 = 0
fidvalue2 = 'A5A5'X
fidoffset2 = 1
pixcnt = 0L
metaOffset = 4L   ; metadata offset from sync value

;  find index into array for Row SYNC pattern
temp1 = shift(temp,-1)
wsync = where( (temp eq fidvalue1) and (temp1 eq fidvalue2), num_sync )
if (num_sync ne (icol+1)) then begin
  sync_diff = num_sync - (icol+1)
  print, 'WARNING that CSOL has incomplete number of Row packets (', strtrim(sync_diff,2), $
  			') at time = ', csol_data.time
  stop, 'DEBUG CSOL number of rows issue...'
  if (sync_diff gt 0) then num_sync = icol+1
endif

for j=0L,num_sync-1 do begin
	row_num = temp[wsync[j]+2]
	if (row_num lt 2000) then begin
		; normal Row packet
        csol_data.image[row_num,*] = temp[wsync[j]+4L:wsync[j]+4L+irow-1]
        pixcnt = pixcnt + irow
	endif else if (row_num eq 2000) then begin
		;  Meta Data packet
		moff = wsync[j] + metaOffset
		csol_data.metadata.time_counter = ishft( ulong(temp[moff+8]),16 ) + ulong(temp[moff+9])
		csol_data.metadata.temp_det0 =  rocket_csol_convert_temperatures(temp[moff+10],/COEFF_SET_0)
		csol_data.metadata.temp_det1 = rocket_csol_convert_temperatures(temp[moff+11],/COEFF_SET_1)
		csol_data.metadata.temp_fpga = rocket_csol_convert_temperatures(temp[moff+12],/COEFF_SET_0)
		csol_data.metadata.mon_5v = temp[moff+14] / 409.6  ; in V
		csol_data.metadata.mon_current = temp[moff+13] * 2500./8192.  ; in mA for 5V power
		csol_data.metadata.tec_enable = temp[moff+18]
		csol_data.metadata.led_enable = temp[moff+19]
		csol_data.metadata.integ_period = (temp[moff+16]+1.)*(temp[moff+17]+1.)*1E-6  ; in seconds
		csol_data.metadata.sdcard_start = temp[moff+21]
		csol_data.metadata.sdcard_address = temp[moff+22]
		csol_data.metadata.error_code = temp[moff+23]
	endif else begin
	  ;  ERROR for invalid row number !!!
	endelse
endfor

csol_data.pixelerror = isize - pixcnt
if (csol_data.pixelerror ne 0) then begin
  print, 'WARNING: ', strtrim(csol_data.pixelerror,2), ' pixels missing for CSOL image at time = ', $
  		csol_data.time
  ; stop, 'Debug loss of pixels...'
endif

return
end
