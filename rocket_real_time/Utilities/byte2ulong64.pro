;+
; NAME:
;   byte2ulong64
;
; PURPOSE:
;   Convert byte array into ulong64 array very efficiently
;
; INPUTS:
;   bArray [bytarr]: An array of 8 bytes to be converted to a ulong64
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   BIG_ENDIAN: Set this to change to big endian interpretation. Default is little_endian.
;
; OUTPUTS:
;   ulongArray [ulong64arr]: The input array converted to ulong64's
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
function byte2ulong64, bArray, big_endian=big_endian

b_num = n_elements(bArray)
b_num8 = b_num/8L
if (b_num lt 8) then return, ulong64(bArray)

; make indices for bytes in array
i0 = ulindgen( b_num8 ) * 8UL
i1 = i0 + 1L
i2 = i0 + 2L
i3 = i0 + 3L
i4 = i0 + 4L
i5 = i0 + 5L
i6 = i0 + 6L
i7 = i0 + 7L

;  make uint Array
if keyword_set(big_endian) then begin
  ulongArray = ulong64(bArray[i7]) + ishft( ulong64(bArray[i6]), 8 ) + $
  			ishft( ulong64(bArray[i5]), 16 ) + ishft( ulong64(bArray[i4]), 24 ) + $
  			ishft( ulong64(bArray[i3]), 32 ) + ishft( ulong64(bArray[i2]), 40 ) + $
  			ishft( ulong64(bArray[i1]), 48 ) + ishft( ulong64(bArray[i0]), 56 )
endif else begin
  ulongArray = ulong64(bArray[i0]) + ishft( ulong64(bArray[i1]), 8 ) + $
  			ishft( ulong64(bArray[i2]), 16 ) + ishft( ulong64(bArray[i3]), 24 ) + $
  			ishft( ulong64(bArray[i4]), 32 ) + ishft( ulong64(bArray[i5]), 40 ) + $
  			ishft( ulong64(bArray[i6]), 48 ) + ishft( ulong64(bArray[i7]), 56 )
endelse

return, ulongArray
end

