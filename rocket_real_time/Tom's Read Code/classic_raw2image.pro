;
;	classic_raw2image.pro
;
;	Convert Raw TM data for CLASSIC CCD into image
;
;	Tom Woods
;	10/16/06
;
function classic_raw2image, words, wcount, time, pixelerror=pixelerror

if (n_params() lt 2) then begin
  print, 'USAGE:  image = classic_raw2image( words, wcount, [time, pixelerror=pixelerror] )
  return, -1L
endif

if (n_params() lt 3) then time = 0.0

icol = 1066L
irow = 1064L
isize = icol*irow
tmsize = (icol*2L+1L)*irow

;
;	only use non-filled data  (there is no filled data in CLASSIC)
;
temp = words[0:wcount-1]
; wgd = where( (temp ne 0) and (temp ne '7E7E'X), numgd )  ; MEGS filter only
wgd = lindgen(wcount)  & numgd = wcount
pixelerror = (numgd - tmsize)/2L
if (numgd lt tmsize) then begin
  print, 'WARNING: ', strtrim(abs(pixelerror),2), ' too few pixels for CLASSIC image @ ', strtrim(time,2)
  ; stop, 'Check out problem...'
endif
if (numgd gt tmsize) then begin
  print, 'WARNING: ', strtrim(abs(pixelerror),2), ' too many pixels for CLASSIC image @ ', strtrim(time,2)
  ; stop, 'Check out problem...'
endif
temp = temp[wgd]
temp2 = uintarr(tmsize)
if (numgd le tmsize) then temp2[0:numgd-1] = temp else temp2[*] = temp[0:tmsize-1]

;
;	sort the data into image
;	checking for each row of data by header byte
;	and combining adjacent words into single pixel value
;
image = uintarr(icol,irow)
linemask = '03B8'X
linevalue = '01B8'X
linelen = icol*2L+1L
pixcnt = 0L
pixloss = 0L
imax = icol*4L
tcnt = 1L  ; ignore first line header that was already found

for j=0L,irow-1L do begin

  for i=0L,imax,2 do begin   ; look for 2 lines worth for next line fiducial
    ; check for line header word to start new row
    if ((temp[tcnt] and linemask) eq linevalue) then begin
      pixloss = pixloss + abs(icol-i/2L)
      ; if (pixelerror eq 2) and (abs(icol-i/2L) ne 0) then stop, 'Check out error1...'
      tcnt = tcnt + 1L
      goto, endline		; restart next row
    endif else begin
      ; check for out of sequence line header word
      if ((temp[tcnt+1] and linemask) eq linevalue) then begin
        pixloss = pixloss + abs(icol-i/2L)
        ; if (pixelerror eq 2) and (abs(icol-i/2L) ne 0) then stop, 'Check out error2...'
        tcnt = tcnt + 1L
        goto, endline    ; restart next row
      endif
      i2 = i/2L
      if (i2 ge icol) then begin
        pixloss = pixloss + 1L 
        ; if (pixelerror eq 2) then stop, 'Check out error3...'
      endif else begin
        image[i2,j] = ishft((temp[tcnt] and '003F'X),8) + (temp[tcnt+1] and '00FF'X)
        pixcnt = pixcnt + 1L
      endelse
      tcnt = tcnt + 2L
      if (tcnt ge (numgd-1)) then goto, endline
    endelse
  endfor
  
endline:
  if (tcnt ge (numgd-1)) then begin
    ; pixloss = pixloss + abs(isize-numgd/2L)
    goto, endnow
  endif
endfor

endnow:
if (j lt (irow-1)) then begin
  print, 'WARNING: ', strtrim(irow-j-1,2), ' rows missing for CLASSIC image.'
  ; stop, 'Debug loss of rows...'
endif
if (pixloss ne 0) then begin
  print, 'WARNING: ', strtrim(pixloss,2), ' pixels off for CLASSIC image.'
  print, '          with ', strtrim(isize-pixcnt,2), ' pixels missing.'
  ; stop, 'Debug loss of pixels...'
endif

return, image
end
