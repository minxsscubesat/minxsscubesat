; Plot of Flare class vs Temperature Fits
; Carrie Leaman - 07/26/2016

x=[1e-6, 6e-6, 1e-6, 4e-7, 4e-7, 3.7e-7, 5.1e-6, 2.7e-6, 4.7e-6, 1.3e-5, 7.3e-6, 1.2e-5]
sf=[3.75e-6, 5.14e-6, 5.07e-6, 3.29e-6, 7.45e-6, 8.27e-6, 9.17e-6, 5.32e-6, 9.23e-6, 1.78e-5, 1.10e-5, 1.46e-5]
temp=[7.0, 7.0, 7.0, 6.8, 6.6, 6.6, 6.8, 7.0, 7.0, 7.0, 7.0, 7.0]

p1=plot(x, temp, /xlog, xrange=[1e-7, 1e-4], yrange=[6, 7.2], title= 'Flare Class vs Temperature, R = 0.51', xtitle='Flare Class', ytitle='LOGtemp', symbol=4, linestyle=' ')
ct=poly_fit(x, temp, 1)
x2=findgen(1001)*1e-7 + 1e-7
y2=ct[0]+ct[1]*x2
p4=plot(x2, y2, linestyle=2, /overplot)

p2=plot(x, sf, /xlog, xrange=[1e-7, 1e-4], yrange=[9e-7, 2e-5], title= 'Flare Class vs Scale Factor, R = 0.87', xtitle='Flare Class', ytitle='Scale Factor', symbol=4, linestyle=' ')
csf=poly_fit(x, sf, 1)
x1=findgen(1001)*1e-7 + 1e-7
y1=csf[0]+csf[1]*x1
p3=plot(x1, y1, linestyle=2, /overplot)
end