; main_program xymd2vms
;
; Unit tester for ymd2vms.pro
;
; B. Knapp, 97.11.12
;           98.06.09, IDL v. 5 compliance
;
; Generate an array of random Julian Day Numbers
  n = 1000L
  jd1 = 1721059.5d0+randomu( seed, n )*1000000.d0
;
; Add a few that will test day-boundary cases
  m = 100L
  jd2 = floor( 1721059.5d0+randomu( seed, m )*1000000.d0 )+ $
     (randomu( seed, m )*4.d0-2.d0)/8.64d6
  jd3 = floor( 1721059.5d0+randomu( seed, m )*1000000.d0 )+ $
     0.5d0+(randomu( seed, m )*4.d0-2.d0)/8.64d6
  jd = [jd1,jd2,jd3]
;
; Convert these to VMS, then back to ymd, to use as input
  vms1 = ymd2vms( jd2ymd( jd ) )
  ymd1 = vms2ymd( vms1 )
  vms2 = ymd2vms( ymd1 )
  ymd2 = vms2ymd( vms2 )
;
; Any differences?
  dy = where(ymd1[2,*] ne ymd2[2,*], ndy)
  if ndy gt 0 then begin
    for j=0,ndy-1 do begin
      print, "Test failed" 
      print, ymd1[*,dy[j]],ymd2[*,dy[j]], $
        format="(f8.1,f6.1,f10.6,f10.1,f6.1,f11.6)"
    endfor
  endif else begin
    print, "Test passed"
  endelse
  
  
  dv = where(vms1 ne vms2, ndv)
  if ndv gt 0 then begin
    for j=0,ndv-1 do begin
      print, "Test Failed"
      print, vms1[dv[j]], vms2[dv[j]], $
        format="(2a25)"
    endfor
  endif else begin
    print, "Test passed"
  endelse
  
  
;
  end
