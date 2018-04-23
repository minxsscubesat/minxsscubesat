function rgb_to_dec, ri, gi, bi

if (n_params() gt 1) then $
  rgb_in = transpose([[ri], [gi], [bi]]) $
else $
  rgb_in = ri

return, reform(rgb_in[0,*] + 256UL * (rgb_in[1,*] + 256UL * rgb_in[2,*]))

end


function dec_to_rgb, di

ro = di mod 256UL
go = ((di - ro) / 256UL) mod 256UL
bo = ((di - go*256UL - ro) / 256UL^2) mod 256UL
  
return, transpose([[ro], [go], [bo]])

end


pro color_complement, ri, gi, bi, ro, go, bo

if (n_params() gt 2) then $
  rgb_in = transpose([[ri], [gi], [bi]]) $
else begin
  if (n_elements(size(ri, /dim)) eq 1) then begin
    dec_in = 1
    rgb_in = dec_to_rgb(ri)
  endif else $
    rgb_in = ri
endelse

color_convert, rgb_in, hls_in, /rgb_hls, interleave=0
hls_in += rebin([180, 0, 0], size(hls_in, /dim))
color_convert, hls_in, rgb_out, /hls_rgb, interleave=0

if (n_params() gt 2) then begin
  ro = rgb_out[0,*]
  go = rgb_out[1,*]
  bo = rgb_out[2,*]
endif else begin
  if dec_in then $
    gi = rgb_to_dec(rgb_out) $
  else $
    gi = rgb_out
endelse

end
