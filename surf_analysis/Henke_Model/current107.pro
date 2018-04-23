;
;	predict current for a diode using Hinterregger's model on Oct 4, 1993
;		this is 36.107 launch date
;
;	pass in wavelength (w) and sensivity (s) for diode
;		can be calibrated values or predicted values
;		(sensitivity is electrons per photon)
;
;	TNW   9/6/93
;
pro current107, w, s

common sundata, sun
;
;	read and calculate only once !
if n_elements(sun) le 1 then sun = euv81( 121.00, 98.14, 2 )	
					; w = Angstroms
					; flux = 10^9 photons/cm^2/s

;
; current unit is nA  (* 1.6E-19 for e- * 1.E9 for flux * 1.E9 for nA)
;
c = sun(1,*) * interpol( s, w, sun(0,*) ) * 1.6E-1

gd = where( sun(0,*) lt 1200. )

!ytitle = 'Current (nA)'
!xtitle = 'Wavelength (Angstrom)'

set_xy,0,1000,0,0
!p.multi=0

plot, sun(0,*), c

print, ' '
print, 'Assuming 1 cm^2 area...'
totalcur = total( c(gd) )
print, 'Total Current (nA) for Oct 4, 1993 is predicted to be ', totalcur
print, ' '
; print, '  Wavelength Bins     Current (nA)  Percentage'
wsun = sun(0,*)
form = '$(2I5, 2F8.3)'
cnt = 0
x1 = 500
ystep = (!cymax - !cymin) / 20.
y1 = !cymax - 3 * ystep
xyouts, 500, y1+ystep, 'Total Current = ' + strtrim(totalcur,2) + ' nA/cm!U2!N'

bins = [ 0, 60, 120, 170, 220, 270, 320, 370, 420, 600, 800, 1000 ]
nn = n_elements(bins) - 2
for k=0,nn do begin
  wg = where( (wsun ge bins(k)) and (wsun lt bins(k+1)) )
  temp = total( c(wg) )
  tempflux = total( sun(1,wg) ) * 1.E9	; integrated flux
  ratio= temp/totalcur*100.
;  print, form, k*50, (k+1)*50, temp, ratio
;  if ratio gt 1 then begin
	xyouts, x1, y1 - cnt * ystep, string(bins(k),'$(I4)') + ' -' + $
		string(bins(k+1),'$(I4)') + $
		string(ratio, '$(F7.2)') + '%' + $
		string(tempflux, '$(E12.3)')
	cnt = cnt + 1
;  endif  
endfor

return
end
