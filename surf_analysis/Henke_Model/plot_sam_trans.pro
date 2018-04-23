;
;	.run plot_sam_trans.pro
;
;	PLOT SAM Model 4 transmission
;
;	Read results from filter, w, tx
;
;	Version 4 (gain = 2 * 1.2)
;		x = C for 700 Angstrom
;			Al for 2450 Angstrom
;			Ti for 3000 Angstrom
;			Si is for SiO 70 Angstrom and (1 - Transmission 5 micron Si)
;		ttotal = all multiplied together
;		wnm = w / 10.  converted to nm
;
;	Version 4 (gain = 2 * 1.32)
;		x = C for 600 Angstrom
;			Al for 2400 Angstrom
;			Ti for 2850 Angstrom
;			Si is for SiO 100 Angstrom and (1 - Transmission 5 micron Si)
;		ttotal = all multiplied together
;		wnm = w / 10.  converted to nm
;
;	Version 6 (gain ~ 2 )
;		x = C for 600 Angstrom
;			Al for 2400 Angstrom
;			Ti for 3400 Angstrom
;			Si is for SiO 70 Angstrom and (1 - Transmission 5 micron Si)
;		ttotal = all multiplied together
;		wnm = w / 10.  converted to nm
;
;	Version 8 (gain = 2.47 )
;		x = C for 600 Angstrom
;			Al for 2000 Angstrom
;			Ti for 3200 Angstrom
;			Si is for SiO 70 Angstrom and (1 - Transmission 5 micron Si)
;		ttotal = all multiplied together
;		wnm = w / 10.  converted to nm
;
restore, 'sam_transmission9.sav'

doEPS = 0
doColor = 0

if doEPS ne 0 then begin
  efile = 'sam_transmission_v9'
  if (doColor ne 0) then efile = efile + '_color'
  efile = efile + '.eps'
  print, 'Saving plot to ', efile
  eps2_p, efile
endif

setplot
cs = 1.8
ct = 1.5
!mtitle=' '

if (doColor ne 0) then begin
  cc = rainbow(7)
endif

plot, wnm, ttotal, /nodata, xrange=[0,10], xs=1, yrange=[0,1], ys=1, $
   xtitle='Wavelength (nm)', ytitle = 'Transmission'
oplot, wnm, ttotal, thick=3

xx = 5.
dx = 1.5
dx2 = 1.8
yy = 0.75
dy = 0.1

oplot, [xx,xx+dx], (yy-dy*4)*[1,1], thick=3
xyouts, xx+dx2, yy-dy*4.2, 'Total', charsize=cs, charthick=ct

xyouts, xx+dx2, yy-dy*0.2, 'C 80nm', charsize=cs, charthick=ct
xyouts, xx+dx2, yy-dy*1.2, 'Al 200nm', charsize=cs, charthick=ct
xyouts, xx+dx2, yy-dy*2.2, 'Ti 320nm', charsize=cs, charthick=ct
xyouts, xx+dx2, yy-dy*3.2, '(1 - Si 5microns)', charsize=cs, charthick=ct

if (doColor ne 0) then begin
  cc = rainbow(7)
  oplot, wnm, tc, color=cc[4]
  oplot, wnm, tal, color=cc[3]
  oplot, wnm, tti, color=cc[5]
  oplot, wnm, tsi, color=cc[0]

  oplot, [xx,xx+dx], (yy-dy*0)*[1,1], color=cc[4]
  oplot, [xx,xx+dx], (yy-dy*1)*[1,1], color=cc[3]
  oplot, [xx,xx+dx], (yy-dy*2)*[1,1], color=cc[5]
  oplot, [xx,xx+dx], (yy-dy*3)*[1,1], color=cc[0]
endif else begin
  oplot, wnm, tc, line=4
  oplot, wnm, tal, line=2
  oplot, wnm, tti, line=3
  oplot, wnm, tsi, line=1

  oplot, [xx,xx+dx], (yy-dy*0)*[1,1], line=4
  oplot, [xx,xx+dx], (yy-dy*1)*[1,1], line=2
  oplot, [xx,xx+dx], (yy-dy*2)*[1,1], line=3
  oplot, [xx,xx+dx], (yy-dy*3)*[1,1], line=1
endelse

if doEPS ne 0 then begin
  send2
endif

end

 
