;
;	modify to not extrapolate to infinity, T. Woods, 11/21/18
;		Change !Values.d_infinity to be epoch[num_epoch-1]+extra_days
;
function calc_voronoi2,epoch
  ; more detailed approach with averaging epoch
  num_epoch = n_elements(epoch)
  extra_days = 90.  ; 3-month extrapolation
  if num_epoch lt 2 then begin
  	 new_epoch =[epoch[0], epoch[0]+extra_days]
  endif else if num_epoch lt 3 then begin
     new_epoch = [epoch[0:num_epoch-2], epoch[num_epoch-1]+extra_days]
  endif else begin
     ; epoch[0], then average epoch[1:num-2] and add infinity for extrapolation
	new_epoch = [epoch[0],(epoch[0:num_epoch-3]+epoch[2:num_epoch-1])/2.,$
		 epoch[num_epoch-1]+extra_days]
	;  no averaging, just report the epoch directly except for last day
	new_epoch = [epoch[0:num_epoch-2], epoch[num_epoch-1]+extra_days]
  endelse
  ; stop, 'DEBUG new_epoch...'
  return, new_epoch
end
