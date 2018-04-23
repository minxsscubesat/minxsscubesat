; temp models vs MinXSS flare spectra
;;; 1st is Level 1 Data temp model
;;;2nd is Level 0 data temp models
;;;calculates chi2
;; CL- summer 2016
restore, 'LOGtemp_Variables.sav'
;radius of sun (m) = 6.963E+8
;sun-earth distance (m) = 1.496E+11
r_sun=6.963E+8
sun_earth_distance= 1.496E+11
steradian_correction=!pi*(((r_sun/sun_earth_distance)^(2.0)))
restore, 'MinXSS_Data/Flare_Irradiance/minxss1_flare_DOY203_M1.2.sav'
name= '203_M1.2'
i=1
if i eq 0 then energy_max=4 else energy_max=8
select_index=where((result[i].energy_bins gt 0.8) and (result[i].energy_bins lt energy_max) and (result[i].irradiance gt 10))
energies_select=result[i].energy_bins[select_index]
spec_select=result[i].irradiance[select_index]
counts_spec_select=result[i].counts[select_index]
sigma_counts_spec_select=sqrt(counts_spec_select)
p1=plot(energies_select, spec_select, /xlog, /ylog, xrange=[.5, 10], yrange=[1e0,1e+10], title= 'MinXSS '+ name +' Flare vs LOGtemp', xtitle='Energies (keV)', ytitle='Irradiances (Photons/s/cm!U2!N/keV)')
colour=['red', 'orange', 'pink', 'green', 'blue', 'purple', 'goldenrod', 'coral', 'crimson']
name=['5.6', '5.8', '6.0', '6.2', '6.4', '6.6', '6.8', '7.0', '7.2']
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
  factor=spec_select[wmin]/model[wmin]
  p2=plot(energies_select, model*factor, /overplot, color=colour[k-1])
  nchi2=total(((spec_select-model*factor)/spec_select)^2)
  print, k, factor, nchi2
  t=text(0.6, (1000000/3^k), /data, name[k-1], color=colour[k-1])
endfor

stop

;correcting chianti steradian

;temporary check
data =data2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Calculating estimated MinXSS system from CHIANTI synthetic spectrum

;0 kev ffset
converted_energy_bins_offset_bins = 0.0

;set file path to minxss_instrument_structure_data_file
minxss_instrument_structure_data_file = '/Users/cale4791/IDLWorkspace85/Default/minxss_fm1_response_structure.sav.SAV'

p5_window=window(DIMENSIONS=[700,700], title='Chianti MinXSS'+name +' Flare Signal Estimate comparison')
p5_chianti=plot(result[i].energy_bins, result[i].counts, /xlog, /ylog, xrange=[.5, 10], yrange=[1e-3,1E+2], margin=0.2, xtitle='Energies (keV)', ytitle='Signal (CPS)', thick=2, font_size=14, /current)

sigma_counts_spec_select=sqrt(result[i].counts)

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
  
chianti_corrected=steradian_correction*data.spectrum

chianti_minxss123_estimate = minxss_x123_full_signal_estimate(result[i].energy_bins, converted_energy_bins_offset_bins, data.lambda, chianti_corrected, minxss_instrument_structure_data_file=minxss_instrument_structure_data_file, /use_detector_area)


xmin= 1.0
xmax= 3.0
ymin=1.0E+4
ymax=1.0E+7
temp=min(abs(result[i].energy_bins-1.0), wmin)
factor=result[i].counts[wmin]/chianti_minxss123_estimate[wmin]
p5_data=plot(result[i].energy_bins, chianti_minxss123_estimate*factor, color=colour[k-1], /overplot)
t=text(5, (80/1.8^k), /data, name[k-1], color=colour[k-1])

select_index=where((result[i].energy_bins gt 1.0) and (result[i].energy_bins lt energy_max) and (result[i].counts gt 0.01), numselect)
nchi1=total(((((chianti_minxss123_estimate[select_index]*factor-result[i].counts[select_index])^2)/(result[i].counts[select_index])^2)))
print, k, nchi1


chi2=total(((((chianti_minxss123_estimate[select_index]*factor-result[i].counts[select_index])^2)/sigma_counts_spec_select[select_index])^2)/(numselect-1.0))
print, k, chi2

;nchi=carrie_chi_square_reduced(result[i].energy_bins, chianti_minxss123_estimate, result[i].energy_bins, counts_spec_select, datay_uncertainty=sigma_counts_spec_select[select_index])
;print, nchi/(n_elements(result[i].energy_bins) - 1.0)

endfor


end
