
; Author: Chris Pankratz
; Date:   2 Jan 2001
; Purpose:
;   Convert the raw sybase datetime format into vms time
;
; Parameters:
;   sybaseTime - an array or scalar of strings that contain timetags
;                like 'Aug  1 2002  1:59:49:500AM'

function sybase2vms, sybaseTime

n = n_elements(sybaseTime)
firstIdx = 0
if (n gt 1024) then begin
   lastIdx = 1023
endif else begin
   lastIdx = n - 1
endelse

vms = strarr(n)
while (firstIdx le n-1) do begin
;   print, firstIdx, lastIdx

   tmptime = sybaseTime[firstIdx:lastIdx]

   ; first, extract each field
   month = strmid(tmpTime, 0, 3)
   day = string(strmid(tmpTime, 4, 2), format='(i2.2)')
   year = strmid(tmpTime, 7, 4)

   hours = fix(strmid(tmpTime, 12, 2))
   min = string(strmid(tmpTime, 15, 2), format='(i2.2)')
   sec = string(strmid(tmpTime, 18, 2), format='(i2.2)')
   frac = fix(strmid(tmpTime, 21, 3))
   ampm = strupcase(strmid(tmpTime, 24, 2))

   ; adjust the hours for 24-hour time
   pick = where (ampm eq 'PM' and hours ne 12, npick)
   if (npick gt 0) then begin
     hours[pick] = hours[pick] + 12
   endif
   ; now correct for 12AM, converting to 00 hours
   pick = where (ampm eq 'AM' and hours eq 12, npick)
   if (npick gt 0) then begin
     hours[pick] = hours[pick] - 12
   endif

   ; construct the vms time format
   vms[firstIdx:lastIdx] = day + '-' + month + '-' + year + ' ' + $
      string(hours, format='(i2.2)') + ':' + min + ':' + sec + $
      strmid(string(frac/1000.0, format='(f4.2)'),1,3)
   ;stop

   firstIdx = lastIdx + 1
   lastIdx = lastIdx + 1024 < n-1
 endwhile

return, vms
end
