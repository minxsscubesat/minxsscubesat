; Two-temp models for Flare/PreFlare spectra
;step 1: fit preflare--> best fit = T1 and fractional fit of T1 = f[T1]
restore, 'LOGtemp_Variables.sav'
r_sun=6.963E+8
sun_earth_distance= 1.496E+11
steradian_correction=!pi*(((r_sun/sun_earth_distance)^(2.0)))
restore, 'MinXSS_Data/Flare_Irradiance/minxss1_flare_result_2016161_C1.sav'
flarename= '161_C1'
i=0
if i eq 0 then energy_max=4 else energy_max=8
select_index=where((result[i].energy_bins gt 0.8) and (result[i].energy_bins lt energy_max) and (result[i].irradiance gt 10))
energies_select=result[i].energy_bins[select_index]
spec_select=result[i].irradiance[select_index]
counts_spec_select=result[i].counts[select_index]
sigma_counts_spec_select=sqrt(counts_spec_select)
p1=plot(energies_select, spec_select, /xlog, /ylog, xrange=[.5, 10], yrange=[1e0,1e+10], title= 'MinXSS '+flarename+ ' PreFlare vs LOGtemp', xtitle='Energies (keV)', ytitle='Irradiances (Photons/s/cm!U2!N/keV)')
colour=['red', 'orange', 'pink', 'green', 'blue', 'purple', 'goldenrod', 'coral', 'crimson']
name=['5.6', '5.8', '6.0', '6.2', '6.4', '6.6', '6.8', '7.0', '7.2']
chi1=fltarr(9)
factor=fltarr(9)
for k=1,9 do begin
  case k of
    1: data=data1
    2: data=data2
    3: data=data3
    4: data=data4
    5: data=data5
    6: data=data6
    7: data=data7
    8: data=data8
    9: data=data9
  endcase
  nsmooth=20
  modelspec=smooth(smooth(data.spectrum,nsmooth),nsmooth)
  Model=interpol(modelspec, data.lambda, energies_select)
  temp=min(abs(energies_select-1.0), wmin)
  factor[k-1]=spec_select[wmin]/model[wmin]
  p2=plot(energies_select, model*factor[k-1], /overplot, color=colour[k-1])
  nchi2=total(((spec_select-model*factor[k-1])/spec_select)^2)
  print, name[k-1], factor[k-1], nchi2
  chi1[k-1]=nchi2
  t=text(0.6, (1000000/3^k), /data, name[k-1], color=colour[k-1])
endfor
mchi=min(chi1, wmin)
print, 'The minimum chi-squared is ', mchi, ' at temperature of ', name[wmin], ' for PreFlare ', flarename, ' where factor is equal to ', factor[wmin]
case wmin+1 of
  1: data=data1
  2: data=data2
  3: data=data3
  4: data=data4
  5: data=data5
  6: data=data6
  7: data=data7
  8: data=data8
  9: data=data9
endcase
modelspec=smooth(smooth(data.spectrum,nsmooth),nsmooth)
Model_preflare=interpol(modelspec, data.lambda, result[i].energy_bins)*factor[wmin]

;;;;;;;;;;;;;;;;;;;;;
;Step 2: Fit flare with equation 1
restore, 'LOGtemp_Variables.sav'
r_sun=6.963E+8
sun_earth_distance= 1.496E+11
steradian_correction=!pi*(((r_sun/sun_earth_distance)^(2.0)))


i=1
if i eq 0 then energy_max=4 else energy_max=8
select_index=where((result[i].energy_bins gt 0.8) and (result[i].energy_bins lt energy_max) and (result[i].irradiance gt 10))
energies_select=result[i].energy_bins[select_index]
spec_select=result[i].irradiance[select_index]
counts_spec_select=result[i].counts[select_index]
sigma_counts_spec_select=sqrt(counts_spec_select)
spec_flare=(spec_select-model_preflare[select_index]) > 10
p1=plot(energies_select, spec_flare, /xlog, /ylog, xrange=[.5, 10], yrange=[1e0,1e+10], title= 'MinXSS '+flarename+ ' Flare vs LOGtemp', xtitle='Energies (keV)', ytitle='Irradiances (Photons/s/cm!U2!N/keV)')
chi1flare=fltarr(9)
factorflare=fltarr(9)
for k=1,9 do begin
  case k of
    1: data=data1
    2: data=data2
    3: data=data3
    4: data=data4
    5: data=data5
    6: data=data6
    7: data=data7
    8: data=data8
    9: data=data9
  endcase
  nsmooth=20
  modelspec=smooth(smooth(data.spectrum,nsmooth),nsmooth)
  Model=interpol(modelspec, data.lambda, energies_select)
  temp=min(abs(energies_select-1.0), wmin)
  factorflare[k-1]=spec_flare[wmin]/model[wmin]
  p2=plot(energies_select, model*factorflare[k-1], /overplot, color=colour[k-1])
  nchi2=total(((spec_flare-model*factorflare[k-1])/spec_flare)^2)
  print, name[k-1], factorflare[k-1], nchi2
  chi1flare[k-1]=nchi2
  t=text(0.6, (1000000/3^k), /data, name[k-1], color=colour[k-1])
endfor
mchi=min(chi1flare, wmin)
print, 'The minimum chi-squared is ', mchi, ' at temperature of ', name[wmin], ' for Flare ', flarename, ' where factor is equal to ', factorflare[wmin]

case wmin+1 of
  1: data=data1
  2: data=data2
  3: data=data3
  4: data=data4
  5: data=data5
  6: data=data6
  7: data=data7
  8: data=data8
  9: data=data9
endcase
modelspec=smooth(smooth(data.spectrum,nsmooth),nsmooth)
Model_flare=interpol(modelspec, data.lambda, result[i].energy_bins)*factorflare[wmin]

Model=(model_preflare+model_flare)
nchi3=total(((spec_select-model[select_index])/spec_select)^2)
print, name[wmin] ,nchi3

p3=plot(energies_select, spec_select, /xlog, /ylog, xrange=[.5, 10], yrange=[1e0,1e+10], title= 'MinXSS '+flarename+ ' Flare vs Model', xtitle='Energies (keV)', ytitle='Irradiances (Photons/s/cm!U2!N/keV)', name= flarename)
p4=plot(result[i].energy_bins, model, /overplot, color='blue', name= 'Model Temperature')
l=legend(target=[p3, p4], position=[0.8, 0.8])
t=text(1.0, 1e+2, /data, 'X!U2!N = '+ strtrim(nchi3, 2))

end