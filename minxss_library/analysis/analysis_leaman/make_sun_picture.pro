;;; Histogram of SDO AIA .fits image
;;; Masks to solar disk and makes tri-colored image
;;; Determines fractional areas of solar features
;;; Plots the Model
;;; Determines and plots X^2 value.
;;CL-Summer 2016

f0193=readfits('/Users/cale4791/Desktop/CHIANTI_8.0.5_pro_standalone/AIA 06-11-2016_f0193.fits')
mask=make_sun_mask(514*4, 509*4, 402*4)
f0193_01=f0193*mask
f0193_02=f0193_01
xmin = (min(f0193_02) + 1) > 1
xmax = max(f0193_02)
h=histogram(f0193_02, binsize=1, min=xmin, max=xmax)
bins = findgen(xmax-xmin+1)+xmin
p=plot(bins, h, title='histogram', xtitle='Pixel Intensity', ytitle='Histogram Number of Pixels', xrange=[0, 2000])
pp=plot([90, 90], [0, 40000], /overplot, linestyle=2)
ppl=plot([1790, 1790], [0, 40000], /overplot, linestyle=2)
wch=where(f0193_02 le 90 and f0193_02 gt 0)
war=where(f0193_02 ge 1790)
wqs=where(f0193_02 gt 90 and f0193_02 lt 1790)
f0193_02[wch]=15
f0193_02[wqs]=54
f0193_02[war]=99
tvscl, rebin(f0193_02, 1024, 1024) mod 1000
num=n_elements(war)+n_elements(wch)+n_elements(wqs)
fch=n_elements(wch)/total(num)
fqs=n_elements(wqs)/total(num)
far=n_elements(war)/total(num)
print, fch, fqs, far
restore, '/Users/cale4791/Desktop/CHIANTI_8.0.5_pro_standalone/MinXSS_Data/Flare_Irradiance/minxss1_flare_result_2016163_C6.sav'
sunshineC1=make_sun_spectrum(fqs, far, fch, rqs, rar, rch)
nsmooth=20
smoothsun=smooth(smooth(sunshineC1[*,1], nsmooth),nsmooth)
rch1=smooth(smooth(rch, nsmooth),nsmooth)
rqs1=smooth(smooth(rqs, nsmooth),nsmooth)
rar1=smooth(smooth(rar, nsmooth),nsmooth)
i=0
name= '2016163_C6'
p1=plot(sunshineC1[*,0], smoothsun, /xlog, /ylog, xrange=[0.5,10], yrange=[1e0,1e+10], xstyle=1, name='Chianti Model', color='cornflower')
p2=plot(result[i].energy_bins, result[i].irradiance, /xlog, /ylog, /overplot, name= name)
p2b=plot([.8,.8], 10^!y.crange, /overplot, line=3)
pc1=plot(sunshineC1[*,0], rch1, /overplot, color='medium sea green', line=2)
pc2=plot(sunshineC1[*,0], rqs1, /overplot, color='dark orchid', line=2)
pc3=plot(sunshineC1[*,0], rar1, /overplot, color='crimson', line=2)
l=legend(target=[p1, p2], position=[0.8, 0.8])
t=text(2.5, 1e+7, string(far*100,format='(F6.2)') + '% Active Region', /data, color='crimson')
t=text(2.5, 3.3e+6, string(fqs*100, format='(F6.2)') + '% Quiet Sun', /data, color='dark orchid')
t=text(2.5, 1e+6, string(fch*100, format='(F6.2)') + '% Coronal Hole', /data, color='medium sea green')
p1.title='Chianti Model vs '+ name
p1.ytitle='Irradiance (photons/s/cm!U2!N/keV)'
p2.xtitle='Energy (keV)'
insmoothsun=interpol(smoothsun, sunshinec1[*,0], result[i].energy_bins)
wgood=where(result[i].energy_bins ge 0.8 and result[i].energy_bins lt 5)
ratio=result[i].irradiance/insmoothsun
p3=plot(result[i].energy_bins[wgood], ratio[wgood], yrange=[0,2], xrange=[0.5,10], xstyle=1, ystyle=1, /xlog, xtitle='Energy (keV)', ytitle= name + '/Chianti')
p4=plot([.1, 10], [1, 1], /overplot, color='green', linestyle=2)
wenergy=where(result[i].energy_bins gt 1 and result[i].energy_bins lt 4.0 and result[i].irradiance gt 10)
chi2=total(((result[i].irradiance[wenergy]-insmoothsun[wenergy])/result[i].irradiance[wenergy])^2)
p3.title='chi=' +string(chi2)
end