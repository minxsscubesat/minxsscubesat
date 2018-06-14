;
;	megs_raw2image.pro
;
;	Convert Raw TM data for MEGS CCD into image
;
;	/raw option does not do the parity conversion
;
;	Tom Woods
;	10/16/06
;
function megs_raw2image, words, wcount, time, pixelerror=pixelerror, raw=raw

if (n_params() lt 2) then begin
  print, 'USAGE:  image = megs_raw2image( words, wcount, [time, pixelerror=pixelerror] )
  return, -1L
endif

if (n_params() lt 3) then time = 0.0

tmcol = 4096L
tmrow = 512L
icol = 2048L
irow = 1024L
isize = icol*irow

;
;	only use non-filled data ; JPM: 7E7E means "filled". MEGS doesn't fill up the whole tm2 10 mbps so the rest gets filled with 7E7E
;
temp = words[0:wcount-1]
wgd = where( (temp ne 0) and (temp ne '7E7E'X), numgd ) ; JPM 7E7E tells you that the FPGA didn't have data there yet
pixelerror = numgd - isize
if (numgd lt (isize-2L)) then begin
  print, 'WARNING: ', strtrim(isize-numgd,2), ' too few pixels for MEGS CCD image @ ', strtrim(time,2)
  ; stop, 'Check out problem...'
endif
if (numgd gt isize) then begin
  print, 'WARNING: ', strtrim(numgd-isize,2), ' too many pixels for MEGS CCD image @ ', strtrim(time,2)
  ; stop, 'Check out problem...'
endif
;
;	convert data with 2's complement ;JPM: allows more bits for low counts
;
temp = temp[wgd]
if not keyword_set(raw) then begin ; JPM: Ignore this if statement since we're always raw
  temp = (temp + '2000'X) and '3FFF'X
endif
temp2 = uintarr(isize)
if (numgd le isize) then temp2[0:numgd-1] = temp else temp2[*] = temp[0:isize-1]

;
;	sort the data into image  (assumes TL-BR order)
;
image = uintarr(icol,irow)
beven = indgen(2048)*2L
bodd = beven + 1L
for j=0L,511L do begin
      image[*,j] = temp2[beven+j*tmcol]
      image[*,1023-j] = reverse(temp2[bodd+j*tmcol])
endfor

return, image
end
