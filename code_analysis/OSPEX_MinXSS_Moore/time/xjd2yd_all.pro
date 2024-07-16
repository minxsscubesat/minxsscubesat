; main_program xjd2yd_all
;
; Unit tester for functions jd2yd and yd2jd
;
; B. Knapp, 2000-10-20
;
  for jd1=-1900000.0,+5000000.0,100.0 do begin
     yd1 = jd2yd(jd1)
     jd2 = yd2jd(yd1)
     doy = abs(yd1) mod 1000
     if doy lt 1 or 367 le doy or jd1 ne jd2 then begin
        print, jd1, yd1, doy, jd1-jd2, format="(2f16.4,f12.4,e16.8)"
     endif
  endfor
;
  end

