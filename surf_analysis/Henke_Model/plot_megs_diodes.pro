;
;	plot_megs_diodes.pro
;
;	Plot SDO EVE MEGS diodes (photometer) signals
;	Tom Woods  10/27/03
;
;	Main procedure:   .run plot_megs_diodes.pro
;

;  read just once
if (n_elements(data) lt 2) then begin
  data1 = read_dat('megs_diodes_signal_v2.dat')
  wv = data1[0,*] / 10.	; convert to nm
  names = [ 'Wavelength', 'MEGS-A with Zr/C', 'MEGS-A with Zr/Si/C', $
  		'MEGS-A with Al/Ge/C', 'MEGS-A with Al/Mg/C', 'MEGS-A with Al/Sn/C', $
  		'MEGS-B (no filter)', 'MEGS-B with Al/Mg/C', 'MEGS-B with Al/Sn/C', $
  		'MEGS-B (Al diode)', 'MEGS-B (Al) + Al/Mg/C', 'MEGS-B-1 Lyman-alpha' ]
  ; manually add Lyman-alpha diode with single Acton Lyman-alpha filter
  sz = size(data1)
  data = fltarr( sz[1]+1, sz[2] )
  data[0:sz[1]-1,*] = data1
  trans_lya = 0.07
  data[sz[1],*] = data1[6,*] * trans_lya
endif

skipbare = 1		; set to 0 to plot MEGS-B bare diode options

cc = rainbow(21)
if (skipbare eq 0) then yr = [1E-10,1] else yr = [1E-8,0.1]
dy = 0.2

plot_oo, [10,10], [yr[0],yr[0]], xr=[5,1000], xs=1, yr=yr, ys=1, $
  xtitle='Wavelength (nm)', ytitle='Signal (nA)', title='SDO EVE MEGS Diodes'

for k=1,10 do begin
  col = cc[k*2-1]
  if (k le 4) or (skipbare eq 0) or (k ge 9) then begin
    oplot, wv, data[k,*], color=col
    if (k le 4) or (skipbare eq 0) then offset = dy^k else offset = dy^(k-2)
    xyouts, 100, yr[1]*offset, names[k], color=col
  endif
endfor

print, ' '
for k=1,11 do print, '  ', strtrim(k,2), '     ', names[k]
print, ' '
type = 1
read, 'Enter type (1-11) : ', type

wrange=[0,0.]
factor = 1000.	; convert to pA

dorepeat:
print, ' '
print, 'For ', names[type]
print, ' '
read, 'Enter wavelength range [Min, Max] in nm (-1 to exit): ', wrange
if (wrange[0] lt 0) or (wrange[1] lt 0) then goto, exitnow
wcenter = (wrange[0] + wrange[1])/2.

print, ' '
print, names[type]
wgd = where( (wv ge wrange[0]) and (wv le wrange[1]))
if (wgd[0] ne -1) then begin
  print, '    1st Order Signal = ', total(data[type,wgd])*factor, ' pA', $
  	' at ', strtrim(wcenter,2), ' Angstroms'
endif
wgd = where( (wv ge wrange[0]/2) and (wv le wrange[1]/2))
if (wgd[0] ne -1) then begin
  print, '    2nd Order Signal = ', total(data[type,wgd])*factor, ' pA', $
     ' at ', strtrim(wcenter/2,2), ' Angstroms'
endif
wgd = where( (wv ge wrange[0]/3) and (wv le wrange[1]/3))
if (wgd[0] ne -1) then begin
  print, '    3rd Order Signal = ', total(data[type,wgd])*factor, ' pA', $
    ' at ', strtrim(wcenter/3,2), ' Angstroms'
endif
print, ' '

goto, dorepeat

exitnow:
print, ' '

end

