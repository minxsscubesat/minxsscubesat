;
;	plot_goes.pro
;
;	Plot GOES data and rocket XRS results
;
;	Tom Woods
;	11/4/06
;
pro plot_goes, short=short, long=long

common goescom, gtime, gshort, glong

if n_elements(gtime) lt 2 then begin
  goes = read_dat('goes12_xray_5min.dat')
  ghr = long(goes[3,*]/100.)
  gmin = long(goes[3,*] - ghr*100L)
  gtime = ghr + gmin/60.
  gshort = goes[6,*]
  glong = goes[7,*]
endif

rtime = 17. + 58./60.
aflux = 2.1E-9	; W/m^2 for rocket XRS-A 
aerr = 0.67
bflux = 6.8E-8	; W/m^2 for rocket XRS-B
berr = 0.06

aratio = 0.002125 / 0.0002627	; ratio of responsivity for Chianti / for Mewe
bratio = 0.02908 / 0.01653

afactor = 1. / 0.86		; Rodney's factor for real GOES XRS-A calibration
bfactor = 1. / 0.70		; Rodney's factor for real GOES XRS-B calibration

setplot
cc = rainbow(7)

if keyword_set(short) then begin
  print, 'GOES XRS-A at rocket time is ', interpol( gshort, gtime, rtime )
  plot, gtime, gshort, yrange=[0,1.5E-8], ys=1, $
      xtitle='Time (hr)', ytitle='0.05-0.4 nm Irradiance (W/m!U2!N)', title='GOES-12 XRS-A'
  oplot, gtime, gshort * afactor, color=cc[5]
  oplot, rtime*[1,1],aflux*[1,1],psym=4,color=cc[3]
  oplot, rtime*[1,1],aflux*[1-aerr,1+aerr],color=cc[3]
  ;  overplot Mewe spectral model result
  ; oplot, rtime*[1,1],aflux*aratio*[1,1],psym=5,color=cc[0]
  ; oplot, rtime*[1,1],aflux*aratio*[1-aerr,1+aerr],color=cc[0]
  xx = 8.
  yy = 1.35E-8
  dy = 0.1E-8
  csize= 2.0
  xyouts, xx, yy, 'GOES Reported', charsize=csize
  xyouts, xx, yy-dy, 'GOES True (R / 0.86)', color=cc[5], charsize=csize
  ; xyouts, xx, yy-dy*3, 'Rocket Mewe', color=cc[0], charsize=csize
  xyouts, xx, yy-dy*2, 'Rocket', color=cc[3], charsize=csize
endif

if keyword_set(long) then begin
  print, 'GOES XRS-B at rocket time is ', interpol( glong, gtime, rtime )
  plot, gtime, glong, $
      xtitle='Time (hr)', ytitle='0.1-0.8 nm Irradiance (W/m!U2!N)', title='GOES-12 XRS-B'
  oplot, gtime, glong * bfactor, color=cc[5]
  oplot, rtime*[1,1],bflux*[1,1],psym=4,color=cc[3]
  oplot, rtime*[1,1],bflux*[1-berr,1+berr],color=cc[3]
  ;  overplot Mewe spectral model result
  ; oplot, rtime*[1,1],bflux*bratio*[1,1],psym=5,color=cc[0]
  ; oplot, rtime*[1,1],bflux*bratio*[1-berr,1+berr],color=cc[0]
  xx = 8.
  yy = 1.35E-7
  dy = 0.1E-7
  csize= 2.0
  xyouts, xx, yy, 'GOES Reported', charsize=csize
  xyouts, xx, yy-dy, 'GOES True (R / 0.7)', color=cc[5], charsize=csize
  ; xyouts, xx, yy-dy*3, 'Rocket Mewe', color=cc[0], charsize=csize
  xyouts, xx, yy-dy*2, 'Rocket', color=cc[3], charsize=csize
endif

return
end
