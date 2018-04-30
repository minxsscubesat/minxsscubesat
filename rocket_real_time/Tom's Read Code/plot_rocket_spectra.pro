;
;	plot rocket_spectra.sav
;
restore, 'rocket_spectra.sav'   ;  spectra.  a1, a2, b

aslope = (30.4 - 17.0) / (413.-1190.)
a0 = 30.4 - aslope*413.
awv = a0 + findgen(2048) * aslope
awv2 = awv - 0.22
xr = [0,40]
; xr = [16,20]
plot_io, awv, spectra.a1, yr=[1E1,1E6], ys=1, xr=xr, xs=1, $
  xtitle='Wavelength (nm)', ytitle='Counts', title='MEGS-A'

oplot, awv2, spectra.a2, color=cc[0]

; write_jpeg_tv, 'megsa_spectrum.jpg'

ans = ' '
read, 'Next Plot ? ', ans

bslope = (102.6 - 58.4) / (1938 - 723.)
b0 = 58.4 - bslope*723.
bwv = b0 + findgen(2048) * bslope
xr = [30,110]
; xr = [90,98]
plot_io, bwv, spectra.b, yr=[1E1, 1E5], ys=1, xr=xr, xs=1, $
  xtitle='Wavelength (nm)', ytitle='Counts', title='MEGS-B'

; write_jpeg_tv, 'megsb_spectrum.jpg'

end
