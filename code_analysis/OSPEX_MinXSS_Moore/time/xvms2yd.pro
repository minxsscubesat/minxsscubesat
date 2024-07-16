; main_program xvms2yd
;
; Unit tester for vms2yd.pro
;
; B. Knapp, 97.11.11
;           98.06.09, IDL v. 5 compliance
;
  dfmt = "(f20.8)"
;
; Single date
  arg = vmstime()
  out = vms2yd(arg)
  yd = yd2vms(out)
  result = strcmp(arg,yd)
  if result[0] ne 1 then begin
    print, "Test failed"
  endif else begin
    print, "Test passed"
  endelse
  
;  print,out,format=dfmt
;  print,' '
;
; Array of dates
  arg = replicate(vmstime(),5)
  out = vms2yd(arg)
  yd = yd2vms(out)
;  print,out,format=dfmt
  for i=0, n_elements(arg)-1 do begin
    result = strcmp(arg[i],yd[i])
    if result[0] ne 1 then begin
      print, "Test failed"
    endif else begin
      print, "Test passed"
    endelse
  endfor 
  end
