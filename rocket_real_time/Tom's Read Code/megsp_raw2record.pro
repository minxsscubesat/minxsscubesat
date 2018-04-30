;
;	megsp_raw2record.pro
;
;	Convert raw TM data for MEGS-P into MEGS-P record
;
;	Tom Woods
;	10/16/06
;
pro megsp_raw2record, words, wcount, pmegsrec, pmegslen

if (n_params() lt 4) then begin
  print, 'USAGE:  megsp_raw2record, words, wcount, pmegsrec, pmegslen'
  return
endif

;
;	check raw stream length
;
rawlen = 212L
recerror = wcount-rawlen
if (recerror gt 0) then recerror = 0
if (recerror lt 0) then begin
  print, 'WARNING: ', strtrim(recerror,2), ' too few words for MEGS-P record @ ', strtrim(pmegsrec.time,2)
  ; stop, 'Check out problem...'
endif
pmegsrec.rec_error = recerror

;
;	extract data in raw stream
;
dmask = '00FF'X

if (wcount ge 8) then begin
  pmegsrec.fpga_time = ( ishft(words[4] and dmask,24) + ishft(words[5] and dmask,16) + $
  					ishft(words[6] and dmask,8) + (words[7] and dmask) ) / 10.
endif else pmegsrec.fpga_time = 0.0

numpcnt = 2L
for k=0L,numpcnt-1L do begin
  if (wcount ge (10L+k*2L)) then begin
    pmegsrec.cnt[k] = ishft(words[8L+k*2L] and dmask,8) + (words[9L+k*2L] and dmask)
  endif else pmegsrec.cnt[k] = 0L
endfor

numpanalog = 64L
adbase = -10.0		; assume +/- 10 V range for 16-bit A/D converter
adslope = 20. / ((2.^16) - 1.)
for k=0L,numpanalog-1L do begin
  if (wcount ge (16L+k*4L)) then begin
    dn = ishft(words[12L+k*4L] and dmask,24) + ishft(words[13L+k*4L] and dmask,16) + $
         ishft(words[14L+k*4L] and dmask,8) + (words[15L+k*4L] and dmask)
    pmegsrec.monitor[k] = dn   ;  adbase + adslope * dn  ; don't convert to Volts as not all are volts
  endif else pmegsrec.monitor[k] = 0L
endfor

return
end
