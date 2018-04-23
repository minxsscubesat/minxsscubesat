pro select,ut=ut,multi=multi,outlen=outlen

;checkvar,multi,0
multi = (n_elements(multi) eq 0) ? 0 : multi
totlen = 0.

for i=0,(multi-1)>0 do begin
  cursor,x1,y1,/down
  cursor,x2,y2,/up

  if keyword_set(ut) then begin
print, "UT not supported."
;    common utcommon,utbase,utstart,utend
;    x1 = anytim(x1+utbase,/yoh)+' (+'+num2str(x1)+'s)'
;    x2 = anytim(x2+utbase,/yoh)+' (+'+num2str(x2)+'s)'
  endif

  print,'('+strtrim(x1,2)+', '+strtrim(y1,2)+')'
  if (x1 NE x2 or y1 ne y2) then begin
    print,'('+strtrim(x2,2)+', '+strtrim(y2,2)+')'
    len = sqrt((x2-x1)^2+(y2-y1)^2)
    totlen = totlen + len
    print,'length: '+strtrim(len,2)
  endif
end
print,'total length: '+strtrim(totlen,2)

outlen=totlen

end
