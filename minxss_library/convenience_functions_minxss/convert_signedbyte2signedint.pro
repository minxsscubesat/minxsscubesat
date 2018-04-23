;
;	convert_signedbyte2signedint
;
;	Purpose: convert signed byte to signed integer
;	Special conversion needed because IDL FIX() function doesn't work for Byte numbers
;
function convert_signedbyte2signedint, data

if n_params() lt 1 then return, 0

;  use FIX for most cases
idata = FIX( data )

if (size(data,/type) eq 1) then begin
  wneg = where( data ge 128, num_neg )
  if (num_neg gt 0) then begin
    idata[wneg] = data[wneg] - 256
  endif
endif

return, idata
end

