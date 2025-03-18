;
;	daxss_goes_compare.pro
;
;	Compare DAXSS to GOES XRS irradiance
;
;	2024-05-07	T. Woods, original code for DAXSS Level 2 1-min averages Version 2
;
pro daxss_goes_compare, version=version, eps=eps, verbose=verbose, result=result

if not keyword_set(version) then version = '2.2.0'
version = strtrim(version,2)
doEPS = keyword_set(eps)
; force VERBOSE to be On
; VERBOSE = 1

d2file = '$minxss_data/fm3/level2/daxss_l2_1minute_average_mission_length_v'+version+'.sav'
if keyword_set(verbose) then print, 'Restoring DAXSS Level 2 file, version '+version+'...'
restore, d2file		; daxss_average_data and daxss_average_meta
if keyword_set(verbose) then print, 'DAXSS Number of Spectra = ', n_elements(daxss_average_data)

x123_energy = daxss_average_data[0].energy ; in keV
x123_energy_step = x123_energy[2] - x123_energy[1]  ; assumes constant grid
; convert DAXSS irradiance units of photons/sec/cm^2/keV  to Watts/m^2/keV
h = 6.62607D-34
c = 2.998D8
area_factor = 1E4
x123_wavelength = 1.23984D0 / x123_energy
energy_factor = (h * c / (x123_wavelength*1D-9)) * area_factor

;
;	integrate DAXSS spectra for XRS-B band (0.1-0.8 nm) and XRS-A band (0.05-0.4 nm)
;
xrsb_band = 1.23984 / [0.1,0.8]
wgoodb = where( (x123_energy ge xrsb_band[1]) AND (x123_energy le xrsb_band[0]) )
num_sp = n_elements(daxss_average_data)
daxss_xrs_b = dblarr(num_sp)
for i=0L,num_sp-1 do begin
	daxss_xrs_b[i] = total((daxss_average_data[i].irradiance[wgoodb] > 0.) $
						* energy_factor[wgoodb] * x123_energy_step )
endfor

xrsa_band = 1.23984 / [0.05,0.4]
wgooda = where( (x123_energy ge xrsa_band[1]) AND (x123_energy le xrsa_band[0]) )
daxss_xrs_a = dblarr(num_sp)
for i=0L,num_sp-1 do begin
	daxss_xrs_a[i] = total((daxss_average_data[i].irradiance[wgooda] > 0.) $
						* energy_factor[wgooda] * x123_energy_step )
endfor

result = [ [daxss_average_data.time_jd], [daxss_xrs_a], [daxss_average_data.goes_xrsa], $
				[daxss_xrs_b], [daxss_average_data.goes_xrsb] ]
;
;	do plots now - plot XRS-B comparison first
;
ans = ' '
if (doEPS) then begin
	efile = 'daxss_goes_xrs-b_compare_v'+version+'.eps'
	print, 'XRS-B Plot written to ', efile
	eps2_p, efile
endif

setplot
cc = rainbow(7)
cs = 2.0
version_str = 'DAXSS L2 1-min Avg. Ver '+version
xlinear = 10.^(findgen(12)-11.D0)
brange = [1E-7,1E-4]
wscaleb = where( (daxss_average_data.goes_xrsb ge 1E-6) AND (daxss_average_data.goes_xrsb le 1E-5) )
ratio_b = median( daxss_average_data[wscaleb].goes_xrsb / daxss_xrs_b[wscaleb] )

plot, daxss_xrs_b, daxss_average_data.goes_xrsb, psym=4, title=version_str, $
		xrange=brange, xs=1, /xlog, yrange=brange, ys=1, /ylog, $
		xtitle='DAXSS Band for XRS-B (W/m!U2!N)', ytitle='GOES XRS-B (W/m!U2!N)'

oplot, xlinear, xlinear, color=cc[3]
oplot, xlinear, xlinear*ratio_b, color=cc[0]
xyouts, 3E-7, 3E-5, 'Ratio GOES/DAXSS ='+string(ratio_b,format='(F6.3)'), color=cc[0], charsize=cs

if (doEPS) then send2 else read, 'Next Plot ? ', ans

;
;	do plots now - plot XRS-A comparison second
;
if (doEPS) then begin
	efile = 'daxss_goes_xrs-a_compare_v'+version+'.eps'
	print, 'XRS-A Plot written to ', efile
	eps2_p, efile
endif

setplot
cc = rainbow(7)
cs = 2.0
arange = [1E-10,1E-5]
wscalea = where( (daxss_average_data.goes_xrsa ge 1E-7) AND (daxss_average_data.goes_xrsa le 1E-6) )
ratio_a = median( daxss_average_data[wscalea].goes_xrsa / daxss_xrs_a[wscalea] )

plot, daxss_xrs_a, daxss_average_data.goes_xrsa, psym=4, title=version_str, $
		xrange=arange, xs=1, /xlog, yrange=arange, ys=1, /ylog, $
		xtitle='DAXSS Band for XRS-A (W/m!U2!N)', ytitle='GOES XRS-A (W/m!U2!N)'

oplot, xlinear, xlinear, color=cc[3]
oplot, xlinear, xlinear*ratio_a, color=cc[0]
xyouts, 5E-10, 1E-6, 'Ratio GOES/DAXSS ='+string(ratio_a,format='(F6.3)'), color=cc[0], charsize=cs

if (doEPS) then send2 else read, 'Next Plot ? ', ans

if keyword_set(verbose) then stop, 'DEBUG at end of daxss_goes_compare.pro ...'
return
end
