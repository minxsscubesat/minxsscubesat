;
;	esp_raw2record.pro
;
;	Convert raw TM data for ESP into ESP record
;
;	Tom Woods
;	10/16/06
;
pro esp_raw2record, words, wcount, esprec, esplen

if (n_params() lt 4) then begin
  print, 'USAGE:  esp_raw2record, words, wcount, esprec, esplen'
  return
endif

;
;	check raw stream length
;
rawlen = 28L
recerror = wcount-rawlen
if (recerror gt 0) then recerror = 0
if (recerror lt 0) then begin
  print, 'WARNING: ', strtrim(recerror,2), ' too few words for ESP record @ ', strtrim(esprec.time,2)
  ; stop, 'Check out problem...'
endif
esprec.rec_error = recerror

;
;	extract data in raw stream
;
dmask = '00FF'X

if (wcount ge 8) then begin
  esprec.fpga_time = ( ishft(words[4] and dmask,24) + ishft(words[5] and dmask,16) + $
  					ishft(words[6] and dmask,8) + (words[7] and dmask) ) / 10.
endif else esprec.fpga_time = 0.0

if (wcount ge 10) then begin
  esprec.rec_count = ishft(words[8] and dmask,8) + (words[9] and dmask)
endif else esprec.rec_count = 0L

numesp = 9L
for k=0L,numesp-1L do begin
  if (wcount ge (12L+k*2L)) then begin
    esprec.cnt[k] = ishft(words[10L+k*2L] and dmask,8) + (words[11L+k*2L] and dmask)
  endif else esprec.cnt[k] = 0L
endfor

return
end
