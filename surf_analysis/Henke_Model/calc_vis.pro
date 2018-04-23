;
;	calc_vis.pro
;
;	Calculate visible sensitivity for XPS bare diodes
;

;
;	make reference spectra for all wavelengths
;
ref1 = read_dat('$solar_models/solar_ref_astm_e490.dat')
ref1[0,*] = ref1[0,*] * 1E3		; microns --> nm
ref1[1,*] = ref1[1,*] * 1E-3	; 1/microns -->  1/nm
;  TSI = 1366.1 from this file

ref2 = read_dat('$solar_models/ref_min_27day_11yr.dat')
ref2[1,*] = ref2[1,*] / (503.556D9 * ref2[0,*])  ;  ph/s/cm^2/nm --> W/m^2/nm

wgd = where(ref1[0,*] gt max(ref2[0,*]))

n2 = n_elements(ref2[0,*]) 
ntot = n2 + n_elements(wgd)
ref = fltarr(2, ntot)

ref[0,0:n2-1] = ref2[0,*]
ref[0,n2:ntot-1] = ref1[0,wgd]

;  irradiance is averaged of solar min and max
temp = ref2[1,*] * (((ref2[3,*] - 1.) / 2.) + 1.)
ref[1,0:n2-1] = temp[0:n2-1]
ref[1,n2:ntot-1] = ref1[1,wgd]

refwv = reform( ref[0,*] )
refirr = reform(ref[1,*] )

;
;	get Si diode sensitivity and convert to nm and A/W (C/J) units
;
sisens = read_dat( 'si_sensitivity.dat')	; in Angstroms & electrons/photon
sisens[0,*] = sisens[0,*] / 10.
sifactor = 1.602D-19 * 1.D-9 / (6.624D-34 * 2.998D8)
sisens[1,*] = sisens[1,*] * sifactor * sisens[0,*] 

sens = reform(interpol( sisens[1,*], sisens[0,*], refwv ))

;
;	Area of aperture
;
area = 10.E-6 * 10.E-6 * 64		; 8 x 8 grid of 10 micron square apertures

;
;	wavelength step for integration
;
dwave = abs(shift(refwv,1) - shift(refwv,-1))/2.
dwave[0] = dwave[1] / 2.
dwave[ntot-1] = dwave[ntot-2] / 2.

;
;	weighted response =  integral( Irrad * Sens * Area * dwave )
;						/  integral( Irrad * dwave )
;
sirr = refirr * sens
rtop = total( refirr * sens * area * dwave )
rbottom = total( refirr * dwave )
rw = rtop / rbottom

print, ' '
print, 'Weighted Response (A/W m^2)  = ', rw
print, 'Area (m^2) =                   ', area
print, 'Weighted Response/Area (A/W) = ', rw/area
print, ' '

wmax = where( refwv lt 1100. )
rmeas = total( refirr[wmax] * dwave[wmax] )
print, 'Percent Measured by Si Diode = ', rmeas * 100. / rbottom
print, ' '

cc = rainbow(7)
setplot
plot_oo, refwv, refirr, xr=[1E1,2E3], xs=1, yr=[1E-6,1E1], ys=1, $
	xtitle='Wavelength (nm)', ytitle=''
oplot, refwv, sirr, color=cc[3]
oplot, refwv, sens, color=cc[0]

end
