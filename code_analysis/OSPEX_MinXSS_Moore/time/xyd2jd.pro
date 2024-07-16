; main_program xyd2jd
;
; End-to-end test of functions yd2jd and jd2yd
;
; B. Knapp, 95.09.22
;

     yd1 = 1997001.12345d0+dindgen(60)
     
     jd1 = yd2jd(yd1)
     yd2 = jd2yd(jd1)
                                ;print,yd1,jd1,yd2,format="(3f18.6)"
    for i=0,59 do begin 
     if (yd1[i]-yd2[i]) gt 0.000000001 then begin
       print, "Test failed"
     endif else begin
       print, "Test passed"
     endelse
     endfor
  
  
  end
  
