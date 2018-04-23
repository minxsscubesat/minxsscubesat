;
;	plot_surftemp.pro
;
;	Plot results from XRS_GAINSURF.PRO as function of temperature
;
;	.run plot_surftemp.pro
;

names = [ 'A1', 'A2-Q1', 'A2-Q2', 'A2-Q3', 'A2-Q4', $
		  'B1', 'B2-Q1', 'B2-Q2', 'B2-Q3', 'B2-Q4' ]
nch = n_elements(names)

temps = [ 10., 20, 25, 30 ]
ireftemp = 1

surfcal = [ [ 4.2211, 4.2170, 4.2190, 4.2215 ], $
	 		[ 19.394, 19.709, 20.780, 22.997 ], $
			[ 21.609, 22.030, 22.929, 24.477 ], $
			[ 23.030, 23.528, 24.470, 26.658 ], $
			[ 20.027, 20.322, 20.870, 22.699 ], $
			[ 1.5022, 1.4985, 1.4956, 1.4946 ], $
			[ 2.5215, 2.5098, 2.5190, 2.5197 ], $
			[ 2.6854, 2.6902, 2.7066, 2.7013 ], $
			[ 3.2507, 3.2869, 3.2841, 3.2846 ], $
			[ 2.6964, 2.7020, 2.6925, 2.6943 ] ]
		
setplot
cc=rainbow(nch+1)
cs = 1.8
ct = 1.5

plot, temps, surfcal[*,0], /nodata, xrange=[0,40], xs=1, yrange=[0.95, 1.20], ys=1, $
		xtitle='Temperature (C)', ytitle='Relative Gain', title='R-XRS SURF Jan 2010'

;  draw 1.0 solid line and also 1% dotted lines and 2% dashed lines
oplot, !x.crange, [1,1]
oplot, !x.crange, 0.99*[1,1], line=1
oplot, !x.crange, 1.01*[1,1], line=1
oplot, !x.crange, 0.98*[1,1], line=2
oplot, !x.crange, 1.02*[1,1], line=2

;  draw each SURF gain result trend
xx = 5.
dy = (!y.crange[1]-!y.crange[0])/15.
yy = !y.crange[1] - dy
for k=0,nch-1 do begin
  oplot, temps, surfcal[*,k]/surfcal[ireftemp,k], psym=-4, color=cc[k]
  xyouts, xx, yy-k*dy, names[k], color=cc[k], charsize=cs, charthick=ct
endfor


jfile = 'surftemp.jpg'
print, 'Writing JPEG file: ', jfile
write_jpeg_tv, 'surftemp.jpg'

end
