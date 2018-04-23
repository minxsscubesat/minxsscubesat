function ashift, in_array, shifts, fill=fill

; Shifts N-dimensional array arbitrarily (by integer amounts), with option for non-circular shift with fill values
; If fill undefined, shifts the usual IDL way (circular shifts)
; If fill is defined, shifts NON-circularly, using fill value in "empty" slots

if (n_params() lt 2) then begin
  message, /info, "USAGE: result = ashift(in_array, shifts [, fill=fill])
  message, /info, "shifts must have as many elements as dimensions of in_array."
  message, /info, "Set fill keyword to perform NON-circular shifting, using fill values in 'empty' slots."
  return, -1
endif

in_dims = size(in_array,/dim)
ndims = n_elements(in_dims)

if (n_elements(shifts) ne ndims) then begin
  message, /info, "ERROR: shifts must have same number of elements as dimensions of input array."
  return, -1
endif

; If we have no fill value, return the standard IDL circular shift
if (n_elements(fill) eq 0) then return, shift(in_array, shifts)

; If we're here, use fill values and shift non-circularly
out_array = replicate(fill, in_dims)
inds_in = (inds_out = replicate('',ndims))
for i=0,ndims-1 do begin
  if shifts[i] lt 0 then begin
    inds_out[i] = '0:in_dims['+strtrim(i,2)+']-1+shifts['+strtrim(i,2)+']'
    inds_in[i]  = '-shifts['+strtrim(i,2)+']:in_dims['+strtrim(i,2)+']-1'
  endif else begin
    inds_out[i] = 'shifts['+strtrim(i,2)+']:in_dims['+strtrim(i,2)+']-1'
    inds_in[i]  = '0:in_dims['+strtrim(i,2)+']-1-shifts['+strtrim(i,2)+']'
  endelse
endfor
inds_in = strjoin(inds_in,',')
inds_out = strjoin(inds_out,',')
junk = execute('out_array['+inds_out+'] = in_array['+inds_in+']')

return, out_array

end