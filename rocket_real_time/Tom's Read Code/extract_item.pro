;
;	extract_item.pro
;
;	Extract TM item's data from a TM packet
;
;   Used for rocket telemetry (TM) - 36.233
;
;	INPUT
;		packet		uintarr( ncol, nrow ) array for TM packet
;		item		[X, Y, dX, dY, maxX, maxY] item definition - only X, Y must be given
;		/analog		do analog conversion from 10-bit DN to 0-5 Volts
;
;	Tom Woods
;	10/15/06
;
function extract_item, packet, item, analog=analog

if n_params() lt 2 then begin
  print, 'USAGE:  item_data_array = extract_item( packet, item )
  return, -1
endif

psize = size( packet )
if (psize[0] lt 1) then ncol = 1L else ncol = psize[1]
if (psize[0] lt 2) then nrow = 1L else nrow = psize[2]

;
;	get / check item definition
;
sx = long(item[0])
if (sx lt 0) then sx = 0L
if (sx ge ncol) then sx = ncol-1L
sy = long(item[1])
if (sy lt 0) then sy = 0L
if (sy ge nrow) then sy = nrow-1L
if (sx ne item[0]) or (sy ne item[1]) then begin
	print, 'WARNING: item X, Y is not valid'
	print, '         X range is 0 - ',strtrim(ncol-1,2)
	print, '         Y range is 0 - ',strtrim(nrow-1,2)
endif
if n_elements(item) ge 3 then sdx = long(item[2]) else sdx = ncol
if (sdx le 0) then sdx = ncol
if n_elements(item) ge 4 then sdy = long(item[3]) else sdy = nrow
if (sdy le 0) then sdy = nrow
if n_elements(item) ge 5 then smx = long(item[4]) else smx = 0L
if (smx lt 0) then smx = 0L
if n_elements(item) ge 6 then smy = long(item[5]) else smy = 0L
if (smy lt 0) then smy = 0L
snumx = 1L + (ncol - sx - 1L) / sdx
if (smx gt 0) and (snumx gt smx) then snumx = smx
snumy = 1L + (nrow - sy - 1L) / sdy
if (smy gt 0) and (snumy gt smy) then snumy = smy
numitem = snumx * snumy

;
;	extract out the data for the TM item
;
data = uintarr( numitem )
dcnt = 0L
for j=0,snumy-1 do begin
  y = sy + j*sdy
  for i=0,snumx-1 do begin
    x = sx + i*sdx
    data[dcnt] = packet[x,y]
    dcnt = dcnt + 1L
  endfor
endfor

if keyword_set(analog) then begin
   data = 0.00 + 5.0 * data / 1023.   ; 10-bit A/D converter
endif

return, data
end
