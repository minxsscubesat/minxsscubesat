;
;	plot_esp.pro
;
;	Main procedure to plot results in esp_extend.dat
;	Tom Woods
;	10/23/03
;
if (n_elements(data) lt 2) then data = read_dat('esp_extend_v2.dat')

fstr = [ 'Ti/C Diode', 'Al/C Diode', 'Al/Mg Diode', 'Al/Sn/C Diode', 'Bare Diode' ]
nd = n_elements(fstr)

retry:
print, ' '
for k=0,nd-1 do print, '  ', strtrim(k,2), '    ', fstr[k]
print, ' '
ans = '1'
read, 'Enter diode type (0-4) : ', ans
type = long(ans)
if (type lt 0) or (type ge nd) then goto, retry

plot_io, data[0,*], data[type+1,*], yr=[1E-6,1E-1], xr=[0,1000], $
  xtitle='Wavelength (Angstrom)', ytitle='Signal (nA)', title=fstr[type]

;
;	show higher order contributions too
;	use 1. / order^2 as scaling factor for estimated grating efficiency change
;
cc=rainbow(7)
cc2 = cc[0]
cc3 = cc[5]
oplot, data[0,*]*2, data[type+1,*]/4., color=cc2
oplot, data[0,*]*3, data[type+1,*]/9., color=cc3
yout = 4E-2
xout = 600.
xyouts, xout, yout, '1st Order'
xyouts, xout, yout/2., '2nd Order', color=cc2
xyouts, xout, yout/4., '3rd Order', color=cc3

wcenter = 300
print, ' '
read, 'Enter center wavelength (60 Angstrom bandpass used) : ', wcenter

gratingfactor = 0.1  * 1000.	; also convert to pA from nA

print, ' '
print, fstr[type], '  (with Al Filter)'
wgd = where( (data[0,*] ge (wcenter-30.)) and (data[0,*] le (wcenter+30.)))
if (wgd[0] ne -1) then begin
  print, '    1st Order Signal = ', total(data[type+1,wgd])*gratingfactor, ' pA', $
  	' at ', strtrim(wcenter,2), ' Angstroms'
endif
wgd = where( (data[0,*] ge (wcenter/2-15.)) and (data[0,*] le (wcenter/2+15.)))
if (wgd[0] ne -1) then begin
  print, '    2nd Order Signal = ', total(data[type+1,wgd])*gratingfactor, ' pA', $
     ' at ', strtrim(wcenter/2,2), ' Angstroms'
endif
wgd = where( (data[0,*] ge (wcenter/3-10.)) and (data[0,*] le (wcenter/3+10.)))
if (wgd[0] ne -1) then begin
  print, '    3rd Order Signal = ', total(data[type+1,wgd])*gratingfactor, ' pA', $
    ' at ', strtrim(wcenter/3,2), ' Angstroms'
endif
print, ' '

end
