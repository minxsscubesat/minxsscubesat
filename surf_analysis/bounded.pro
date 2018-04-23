function bounded, x, lim1, lim2, exclusive = exclusive, inclusive = inclusive
; Returns: 1 if low <= x <= high, 0 otherwise
; ASSUMES /inclusive; set /exclusive or inclusive=0 for strict comparison
; x may be an array (output is then also array, of equal length)
; lim1 may be an array, whence lim2 is ignored

if (n_elements(lim1) gt 2) then begin
  message, "Can set only two boundary limits..."
endif else if (n_elements(lim1) eq 2) then begin
  if (n_elements(lim2) ne 0) then begin
    message, /info, "WARNING: lim1 is array; ignoring lim2 ..."
  endif
  limits = lim1
endif else begin
  if (n_elements(lim2) gt 1) then begin
    message, "Can only set two boundary limits..."
  endif else if (n_elements(lim2) eq 0) then begin
    message, "Need two limits!"
  endif
  limits = [lim1, lim2]
endelse
limits = limits[sort(limits)]

if keyword_set(exclusive) then begin
  if keyword_set(inclusive) then message, /info, "WARNING: Cannot set both /inclusive and /exclusive - ASSUMING /exclusive ..."
  return, ((x gt limits[0]) and (x lt limits[1]))
endif else begin
  return, ((x ge limits[0]) and (x le limits[1]))
endelse

end