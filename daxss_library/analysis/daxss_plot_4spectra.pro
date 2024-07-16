;
;	daxss_plot_4spectra.pro
;
;	Plot for Amal Chandran's IS-1 First-Light Paper
;

doEPS = 0	; make EPS plot if not zero

if daxss_level1_data eq !NULL then restore, '/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level1/daxss_l1_mission_length_v2.0.0.sav'
energy = daxss_level1_data[0].energy

if sci eq !NULL then restore, '/Users/twoods/Dropbox/minxss_dropbox/data/fm3/level0c/daxss_l0c_all_mission_length_v2.0.0.sav'
sci_gps_offset = -206.
sci_jd = gps2jd(sci.time + sci_gps_offset)
sci_yd = jd2yd(sci_jd)
sp = sci.x123_spectrum
numsp = n_elements(sci)
for k=0,numsp-1 do sp[*,k] = sp[*,k] / ((sci[k].x123_accum_time/1000.) > 1.)

; QS spectrum
ydqs = [ 2022074.94434D0, 2022074.94487D0 ]  ; pre-flare for DOY 074
ydqs = [ 2022144.01903D0, 2022144.01946D0 ]  ; pre-occultation for DOY 144
numqs = 5L	; expectation for number of DAXSS spectra for this time range
wqs=where(sci_yd ge ydqs[0] and sci_yd le ydqs[1])
if (n_elements(wqs) ne numqs) then begin
	print, 'WARNING: Number of QS Solar spectra is not ', numqs
	numqs=n_elements(wqs)
endif
sp_qs = total(sp[*,wqs],2)/float(numqs)

; Flare Spectrum
ydf = [ 2022074.97529D0,  2022074.97614D0 ]
numf = 9L	; expectation for number of DAXSS spectra for this time range
wf=where(sci_yd ge ydf[0] and sci_yd le ydf[1])
if (n_elements(wf) ne numf) then begin
	print, 'WARNING: Number of Flare Solar spectra is not ', numf
	numf=n_elements(wf)
endif
sp_flare = total(sp[*,wf],2)/float(numf)

; Solar Occultation spectrum
yd_before_atmos = 2022144.017997D0
yda = [ 2022144.02122D0, 2022144.02134D0 ]
numa = 2L	; expectation for number of DAXSS spectra for this time range
wa=where(sci_yd ge yda[0] and sci_yd le yda[1])
if (n_elements(wf) ne numf) then begin
	print, 'WARNING: Number of Solar Occultation spectra is not ', numa
	numa=n_elements(wa)
endif
sp_atmos = total(sp[*,wa],2)/float(numa)

; Energetic particle spectrum
ydep = [2022119.27320D0,  2022119.27363D0]
numep = 5L	; expectation for number of DAXSS spectra for this time range
wep=where(sci_yd ge ydep[0] and sci_yd le ydep[1])
if (n_elements(wep) ne numep) then begin
	print, 'WARNING: Number of Energetic Particle spectra is not ', numep
	numep=n_elements(wep)
endif
sp_ep = total(sp[*,wep],2)/float(numep)
; print longitude & latitude for Particles
w1ep = where(daxss_level1_data.time_yd ge ydep[0] and daxss_level1_data.time_yd le ydep[1])
print, "Energetic Particle location (Long., Lat.) is ", $
				mean(daxss_level1_data[w1ep].longitude), $
				mean(daxss_level1_data[w1ep].latitude)

if (doEPS ne 0) then begin
	efile = 'DAXSS_Example_4Spectra.eps'
	edir = getenv("minxss_data")+"/fm3/trends/sci/"
	print, 'Saving Graphics into '+edir+efile
	eps2_p, edir+efile
endif

setplot
cc=rainbow(7)
cs=2.0

plot, energy, sp_qs, psym=10, /nodata, xr=[0,15], xs=1, xtitle='Energy (keV)', $
		/ylog, yr=[1,5000], ys=1, ytitle='DAXSS Signal (cps)'
xx = 8.0
yy = 1000. & my=2
xyouts, xx, yy, 'Solar Flare', charsize=cs, color=cc[6]
xyouts, xx, yy/my^1, 'Quiescent', charsize=cs, color=cc[3]
xyouts, xx, yy/my^2, 'Occultation', charsize=cs, color=cc[0]
xyouts, xx, yy/my^3, 'Particles', charsize=cs, color=cc[1]

oplot, energy, sp_ep, psym=10, color=cc[1]
oplot, energy, sp_flare, psym=10, color=cc[6]
oplot, energy, sp_qs, psym=10, color=cc[3]
oplot, energy, sp_atmos, psym=10, color=cc[0]

if (doEPS ne 0) then send2

end
