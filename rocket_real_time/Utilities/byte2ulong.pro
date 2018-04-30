;+
; NAME:
;   byte2ulong
;
; PURPOSE:
;   Convert byte array into ulong array very efficiently
;
; INPUTS:
;   bArray [bytarr]: An array of 8 bytes to be converted to a ulong
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   BIG_ENDIAN: Set this to change to big endian interpretation. Default is little_endian.
;
; OUTPUTS:
;   ulongArray [ulongarr]: The input array converted to ulong's
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   ulongs = byte2ulong64(arrayOfBytes)
;
; MODIFICATION HISTORY:
;   2015/04/23: Tom Woods: Wrote script
;-
function byte2ulong, bArray, big_endian=big_endian

b_num = n_elements(bArray)
b_num4 = b_num/4L
if (b_num lt 4) then return, ulong(bArray)

; make indices for bytes in array
i0 = ulindgen( b_num4 ) * 4UL
i1 = i0 + 1L
i2 = i0 + 2L
i3 = i0 + 3L

;  make uint Array
if keyword_set(big_endian) then begin
  ulongArray = ulong(bArray[i3]) + ishft( ulong(bArray[i2]), 8 ) + $
  			ishft( ulong(bArray[i1]), 16 ) + ishft( ulong(bArray[i0]), 24 )
endif else begin
  ulongArray = ulong(bArray[i0]) + ishft( ulong(bArray[i1]), 8 ) + $
  			ishft( ulong(bArray[i2]), 16 ) + ishft( ulong(bArray[i3]), 24 )
endelse

return, ulongArray
end

