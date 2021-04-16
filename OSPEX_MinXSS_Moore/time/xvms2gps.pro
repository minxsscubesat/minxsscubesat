; main_program xvms2gps
;
; Unit tester for vms2gps.pro and gps2vms.pro
;
; N. Kungsakawin 2002-02-07
;
; Generate an array of random gps dates
  n = 1000L
  ud = randomu( seed, n )*100
;
  vms = ud2vms(ud)
  gps = ud2gps(ud)
  vms1 = gps2vms(gps)
  gps1 = vms2gps(vms1)
;
  du= where( abs((gps-gps1)) gt 0.01, nd ) 
  
; since vms time is only accurate to 1/100 of a second, the result of gps
; and gps1 is off by 0.01
  
  du1= where( vms ne vms1, nd1 )
   if nd gt 0 or nd1 gt 0 then begin
     print, 'Test failed!'
   endif else begin  
     print, 'Test passed.'
  endelse
;
  end
