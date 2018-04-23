;
;	predict current for a diode
;
;	pass in wavelength (w) and sensivity (s) for diode
;		can be calibrated values or predicted values
;		(sensitivity is electrons per photon)
;
;	TNW   9/6/93
;
;	same as current.pro except check out to 1250 Angstroms
;
pro current_all, w, s, nolabel=nolabel

if n_params(0) lt 2 then diode,w,s

common euvflux, sunlow, sunhigh

if n_elements(sunlow) le 1 then begin
  sunlow = euv81( 100, 100, 2 )		; w = Angstroms
  sunhigh = euv81( 300, 300, 2 )	; flux = 10^9 photons/cm^2/s
endif

wv = sunlow(0,*)
;
; current unit is nA  (* 1.6E-19 for e- * 1.E9 for flux * 1.E9 for nA)
;
clow = sunlow(1,*) * interpol( s, w, sunlow(0,*) ) * 1.6E-1

chigh = sunhigh(1,*) * interpol( s, w, sunhigh(0,*) ) * 1.6E-1

gd = where( sunlow(0,*) lt 1250. )

!ytitle = 'Current (nA)'
!xtitle = 'Wavelength (Angstrom)'

!grid = 0

wvhigh = sunhigh(0,*)
wvlow = sunlow(0,*)

if keyword_set(nolabel) then begin
	wvhigh = wvhigh/10.
	wvlow = wvlow/10.
	!xtitle = 'Wavelength (nm)'
;	set_xy,0,125,0,0
	nolabel = 1
endif else begin
	nolabel = 0
	set_xy,0,1250,0,0
endelse

plot, wvhigh, chigh

if (nolabel eq 0) then begin

oplot, wvlow, clow, color=2

cnt = 0
ystep = (!cymax-!cymin)/20.
ystart = !cymax - 3*ystep
x1 = 475
x2 = 725
x3 = 850
xyouts, x1, ystart, 'Wavelength'
xyouts, x2, ystart+ystep, 'Solar'
xyouts, x2, ystart, 'Min %'
xyouts, x3, ystart+ystep, 'Solar'
xyouts, x3, ystart, 'Max %'
hightot = total(chigh(gd))
lowtot = total(clow(gd))
limit = 5.

for k=0,1200,50 do begin
  wgd = where( (wv ge k) and (wv lt (k+50.) ) )
  if wgd(0) ne -1 then begin
    plow = total(clow(wgd)) / lowtot * 100.
    phigh = total(chigh(wgd)) / hightot * 100.
    if (plow gt limit) or (phigh gt limit) then begin
	cnt = cnt + 1
	xyouts, x1, ystart-cnt*ystep, string(k,'(I4)')+'-'+string(k+50,'(I4)')
	xyouts, x2, ystart-cnt*ystep, string( fix(plow+0.5), '(I3)')
	xyouts, x3, ystart-cnt*ystep, string( fix(phigh+0.5), '(I3)')
    endif
  endif
endfor

cnt = cnt + 2
xyouts, x1-50, ystart-cnt*ystep, 'Total Current'
xyouts, x2, ystart-cnt*ystep, strtrim(fix(lowtot+0.5),2)
xyouts, x3, ystart-cnt*ystep, strtrim(fix(hightot+0.5),2) + ' nA'

print, 'Assuming 1 cm^2 area...'
print, 'Current (nA) low solar activity is ', lowtot
print, 'Current (nA) high solar activity is ', hightot
print, ' '
; stop, 'Check clow and chigh...'


endif		; for nolabel

return
end
