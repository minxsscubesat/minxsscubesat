;+
; NAME:
;   byte2uint
;
; PURPOSE:
;   Convert byte array into uint array very efficiently
;
; INPUTS:
;   bArray [bytarr]: An array of 8 bytes to be converted to uint's
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   BIG_ENDIAN: Set this to change to big endian interpretation. Default is little_endian.
;
; OUTPUTS:
;   uiArray [ulong64arr]: The input array converted to uints's
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   uints = byte2uint(arrayOfBytes)
;
; MODIFICATION HISTORY:
;   2015/04/23: Tom Woods: Wrote script
;-
function byte2uint, bArray, big_endian=big_endian

b_num = n_elements(bArray)
b_num2 = b_num/2L
if (b_num lt 2) then return, uint(bArray)

; make indices for even and odd bytes in array
ieven = ulindgen( b_num2 ) * 2UL
iodd = ieven + 1L

;  make uint Array
if keyword_set(big_endian) then begin
  uiArray = uint(bArray[iodd]) + ishft( uint(bArray[ieven]), 8 )
endif else begin
  uiArray = uint(bArray[ieven]) + ishft( uint(bArray[iodd]), 8 )
endelse

return, uiArray
end

