function calc_voronoi2,epoch
  ; more detailed approach with averaging epoch
  num_epoch = n_elements(epoch)
  if num_epoch lt 2 then begin
     return, [epoch[0], !Values.d_infinity]
  endif else if num_epoch lt 4 then begin
     return, [epoch[0:num_epoch-2], !Values.d_infinity]
  endif else begin
     ; epoch[0], then average epoch[1:num-2] and add infinity for extrapolation
     return,[epoch[0],(epoch[0:n_elements(epoch)-3]+epoch[2:n_elements(epoch)-1])/2,!Values.d_infinity]
  endelse
end
