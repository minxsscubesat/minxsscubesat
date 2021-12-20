;
; x123_decompress
;
; Decompress the X123 raw data if cmp_info is not zero, else uncompressed data
;
; Must return lonarr(1024)
;
;	10/1/2021	T. Woods, Updated to have bin_limit return value option (issue for 36.353 9/9/21 flight)
;
function x123_decompress, raw_data, raw_count, cmp_info, spect_len, bin_limit=bin_limit, verbose=verbose

  X123_SPECTRUM_BINS = 1024L
  X123_SPECTRUM_LENGTH = X123_SPECTRUM_BINS * 3L
  spectrum = lonarr(X123_SPECTRUM_BINS)

  if (n_params() lt 4) then return, spectrum
  bin_limit = 0

  if (cmp_info eq 0) then begin
    ;
    ; uncompressed data, just transfer over the data (3 bytes per bin)
    ;
    imax = spect_len / 3L
    if (raw_count lt spect_len) then imax = raw_count / 3L
    if keyword_set(verbose) then print, 'X123_DECOMPRESS: no compression for ', $
      strtrim(imax,2), ' bins'
    for i=0L,imax-1 do spectrum[i] = (long(raw_data[i*3L]) $
      + ishft(long(raw_data[1+i*3L]),8) + ishft(long(raw_data[2+i*3L]),16))
    k_sp = imax
  endif else begin
    ;
    ; compressed data to unpack
    ; HEADER = bytarr(256) with every 2 bits signifying how many bytes are not zero in bin
    ; DATA = packed non-zero bytes
    ; cmp_info low nibble is first index in header with non-zero value
    ; cmp_info high nibble is last index in header with non-zero value
    ;
    if (raw_count lt spect_len) then begin
      ; ERROR in getting all the necessary science packets - abort with empty spectrum
      if keyword_set(verbose) then print, 'X123_DECOMPRESS: error for missing SCI packet'
      return, spectrum
    endif
    X123_HEADER_LEN = X123_SPECTRUM_BINS / 4L
    cmp_header = bytarr(X123_HEADER_LEN)
    istart = cmp_info AND '00FF'X
    iend = ishft(cmp_info AND 'FF00'X, -8)
    num = iend - istart + 1L
    if keyword_set(verbose) then print, 'X123_DECOMPRESS: compression of ', $
      string(spect_len*100./float(X123_SPECTRUM_LENGTH),format='(F5.2)'), ' % for header ', $
      strtrim(iStart,2), ' - ', strtrim(iEnd, 2)
    ; fill up cmp_header first
    iData = 0L
    for i=istart, iend do begin
      cmp_header[i] = raw_data[iData]
      iData += 1
    endfor
    ; now parse cmp_header for how many non-zero bytes to pull from raw_data
    k_sp = 0L
    for i=0,X123_HEADER_LEN-1 do begin
      ; there are four bins per header byte
      for j=0,3 do begin
        if j eq 0 then mask = '03'X else mask = ishft('03'X,j*2)
        good_bytes = cmp_header[i] AND mask
        if j gt 0 then good_bytes = ishft( good_bytes, -1L*(j*2))
        spectrum[k_sp] = 0L
        if (good_bytes eq 3) then begin
          if (iData lt (raw_count-2)) then $
            spectrum[k_sp] = long(raw_data[iData]) + ishft(long(raw_data[iData+1]),8) $
            + ishft(long(raw_data[iData+2]),16)
          iData += 3
        endif else if (good_bytes eq 2) then begin
          if (iData lt (raw_count-1)) then $
            spectrum[k_sp] = long(raw_data[iData]) + ishft(long(raw_data[iData+1]),8)
          iData += 2
        endif else if (good_bytes eq 1) then begin
          if (iData lt raw_count) then $
            spectrum[k_sp] = long(raw_data[iData])
          iData += 1
        endif ; else do nothing
        k_sp += 1
      endfor
    endfor
  endelse

  ; new 10/1/2021 - check on bin limit for decompression / non-zero data
  bin_limit = k_sp
  for i=X123_SPECTRUM_BINS-1,0,-1 do if (spectrum[i] ne 0) then BREAK
  bin_limit = i

  return, spectrum
end
;  end of x123_decompress()
