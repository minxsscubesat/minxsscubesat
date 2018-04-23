function sign, x, nozero = nozero

; Returns: +1 if x > 0, -1 if x < 0, 0 if x = 0
; If /nozero set, returns +1 for x > 0
; x can be an array

return, (0 + (keyword_set(nozero) ? (x ge 0) : (x gt 0)) - (x lt 0))

end