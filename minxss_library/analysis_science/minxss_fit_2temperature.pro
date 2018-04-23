;
;	minxss_fit_2temperature.pro
;
;	This procedure will compare CHIANTI reference spectra to a provided SXR spectrum
;	and return model fit along with temperature and abundance multiplier (photosphere 0 - 1 corona)
;
;	This is similar to minxss_fit_temperature.pro except this version does high-energy fit first
;	and then low-energy fit for second temperature.
;
;	INPUT
;		energy		Energy bins (keV)
;		flux		Irradiance spectrum (photons/s/cm^2/keV)
;		/eps		Option to make EPS graphics files after doing fit - a name is passed for EPS file
;		/noplot		Option to not do fit plot
;		/debug		Option to debug at the end
;
;	OUTPUT
;		fit_flux	Array of model fit of energy[0,*] and flux[1,*]
;		/parameters	Model fit parameters: 	log(Temperature_K), DEM_density_1E27, abundance_factor
;		/chi		CHI squared fitted value
;
;	FILES
;		MinXSS L1		$minxss_data/fm1/level1/minxss1_l0c_all_mission_length.sav
;		Fit Plots		$minxss_data/trends/chianti_fits  directory
;		CHIANTI Model   $minxss_data/merged/ch_iso-temp_5.7-7.7_irradiance.sav
;
;		NOTE that system environment must be set for $minxss_data
;
;	CODE
;		This procedure plus plot routines in
;		$minxss_dir/code/production/convenience_functions_generic/
;
;	HISTORY
;		9/12/2016  Tom Woods   Original Code
;		9/17/2016  Tom Woods   Updated so 2nd Temperature can not be hotter than 1st Temperature
;		11/28/2016 Tom Woods   Updated so abundance from first fit is used for second fit
;
pro minxss_fit_2temperature, energy, flux, fit_flux, parameters=parameters, chi=chi, $
						noplot=noplot, eps=eps, debug=debug

common minxss_fit_temperature, wch_units, wch_temp, wch_energy, wch_cor, wch_photo

;
;	check input parameters
;
if n_params() lt 2 then begin
	print, ' '
	print, 'USAGE:  minxss_fit_2temperature, energy, flux, fit_flux, parameters=parameters, /noplot, /eps, /debug'
	print, ' '
	return
endif

;
;	get directory names
;
;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
endif else begin
    slash = '/'
endelse
dir_data = getenv('minxss_data') + slash
dir_merged = dir_data + 'merged' + slash
dir_eps = dir_data + 'trends' + slash + 'chianti_fits' + slash

;
;	load CHIANTI reference spectra
;		ch_cor is for coronal abundance
;		ch_photo is for photospheric abundance
;
if n_elements(wch_temp) lt 1 then begin
	ch_file_name = 'ch_weighted-temp_5.7-7.7_irradiance.sav'
	print, 'Restoring CHIANTI spectra from ', ch_file_name
	restore, dir_merged + ch_file_name  ; wch_units, wch_temp, wch_energy, wch_cor, wch_photo
endif

;
;	prepare variables for the fit
;		only fit the high energy tail of the input spectrum (flux)
;		ideally, want to fit between 3 and 10 keV
;
num_temp = n_elements(wch_temp)
chi_fit = dblarr(num_temp)
normalize_fit = dblarr(num_temp)
parameters = { logT: 0.0, cor_density: 0.0D0, photo_density: 0.0D0, abundance: 0.0, fe_xxv_flux: 0.0, $
			logT_2: 0.0, cor_density_2: 0.0D0, photo_density_2: 0.0D0, abundance_2: 0.0 }
fit_flux = -1L

FLUX_MIN = 200.   ; assumes units of photons/s/cm^2/keV from MinXSS X123
FLUX_MIN2 = FLUX_MIN/100.
whigh = where( (flux gt FLUX_MIN) and (energy le 10), num_high )
if (num_high lt 20) then begin
	if keyword_set(debug) then print, 'ERROR: not enough data in the flux spectrum !'
	return
endif

e_max = max(energy[whigh])
if (e_max gt 10) then e_max = 10.
e_lower_factor = 3.33
e_min = e_max / e_lower_factor
if (e_max lt 1.6) then begin
	if keyword_set(debug) then print, 'WARNING: flux spectrum is below 1.6 keV.'
endif
if (e_min lt 1.0) then e_min = 1.0

wfit = where( (energy ge e_min) and (energy le e_max) and (flux gt (FLUX_MIN/2.)), num_fit )
if (num_fit lt 20) then begin
	if keyword_set(debug) then print, 'ERROR: not enough data to fit !'
	return
endif

e_data = energy[wfit]
f_data = flux[wfit]

;
;	find which model temperature has the smallest CHI squared value
;
for k=0L, num_temp-1 do begin
	f_fit = interpol( wch_cor[k,*], wch_energy, e_data )
	normalize_factor = total(f_data[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	normalize_fit[k] = normalize_factor
	chi_fit[k] = total((abs(f_fit - f_data)/f_data)^2.)
endfor

;
;	best fit is the one with smallest CHI squared value
;
chi1 = min(chi_fit, wmin)
fit_flux = fltarr(4, n_elements(wch_energy))
fit_flux[0,*] = wch_energy
fit_flux[1,*] = wch_cor[wmin,*] * normalize_fit[wmin]  ; total model flux
fit_flux[2,*] = fit_flux[1,*]  ; temp-1 model
parameters.logT = wch_temp[wmin]
; default CHIANTI model DEM value is 1E27
MODEL_DEM = 1.D27
parameters.cor_density = MODEL_DEM * normalize_fit[wmin]
parameters.photo_density = 0.0
; Default is to fit with Corona abundance model
CF = 2.138  ; CHIANTI model abundance ratio of Fe for Corona to Photosphere
CF_LOW = 0.5
CF_HIGH = 4.0
parameters.abundance = CF

; use Coronal Abundance model for 2nd temperature fit (unless get abundance from 1st fit)
model2_af = CF
model2 = wch_cor

;
;	if logT > 6.8 and energy > 6 keV then can also do abundance fit
;
;		Abundance Factor of Photospheric Abundance at Fe 6.7 keV is calculated as
;			AF = (max(flux_6.7keV) - baseline) / (max(model_photo_6.7keV) - baseline)
;	where baseline = (CF * max(model_photo_6.7keV) - max(model_cor_6.7keV)) / (CF - 1.0)
;	where CF = 2.138 from the abundance values of Fe used in CHIANTI model run
;
if (parameters.logT ge 6.75) and (e_min lt 6.0) and (e_max gt 7.2) then begin
	wch = where( (wch_energy ge 6.0) and (wch_energy le 6.3) )
	wch_step = abs(wch_energy[wch[1]] - wch_energy[wch[0]])
	win = where( (energy ge 6.0) and (energy le 6.3) )
	in_step = abs(energy[win[1]] - energy[win[0]])
	band_factor = (max(wch_energy[wch])-min(wch_energy[wch]))
	flux_ref = total(flux[win]*in_step) / (max(energy[win])-min(energy[win]))
	;  only calculate abundance if signal is high enough for good calculation
	parameters.fe_xxv_flux = flux_ref
	if (flux_ref gt (FLUX_MIN*5)) then begin
		norm_cor = flux_ref / (total(reform(wch_cor[wmin,wch])*wch_step) / band_factor)
		model_cor = reform(wch_cor[wmin,*]) * norm_cor
		parameters.cor_density = MODEL_DEM * norm_cor
		norm_photo = flux_ref / (total(reform(wch_photo[wmin,wch])*wch_step) / band_factor)
		model_photo = reform(wch_photo[wmin,*]) * norm_photo
		parameters.photo_density = MODEL_DEM * norm_photo
		;  get scaling from 0 (photosphere) to 1 (coronal) for the abuandance based on Fe peak at 6.7 keV
		wchpeak = where( (wch_energy ge 6.55) and (wch_energy le 6.85) )
		peak_cor = max(model_cor[wchpeak])
		peak_photo = max(model_photo[wchpeak])
		winpeak = where( (energy ge 6.55) and (energy le 6.85) )
		peak_flux = max(flux[winpeak])
		baseline = (CF * peak_photo - peak_cor) / (CF - 1.0)
		parameters.abundance = (peak_flux - baseline) / (peak_photo - baseline)
		;  limit abundance range
		if (parameters.abundance lt CF_LOW) then parameters.abundance = CF_LOW
		if (parameters.abundance gt CF_HIGH) then parameters.abundance = CF_HIGH
		;
		;  now scale for better model fit using A = abundance
		;		model = A * Photo - ((A-1)/(CF-1))*(CF*Photo - Cor)
		;
		model_better = parameters.abundance * model_photo - ((parameters.abundance-1.)/(CF-1.)) * $
						(CF * model_photo - model_cor)
		fit_flux[1,*] = model_better
		fit_flux[2,*] = fit_flux[1,*]
		;
		;	use 1st fit abundance for 2nd fit
		;
		model2_af = parameters.abundance
		for k=0L, num_temp-1 do begin
			model2[k,*] = model2_af * reform(wch_photo[k,*]) - $
				((model2_af-1.)/(CF-1.)) * (CF * reform(wch_photo[k,*]) - reform(wch_cor[k,*]))
		endfor
	endif
endif

;
;	NEW part for fitting second temperature
;
chi_fit2 = dblarr(num_temp)
normalize_fit2 = dblarr(num_temp)
chi2 = -1.0

e_max2 = e_min
e_lower_factor2 = 3.33
e_min2 = e_max2 / e_lower_factor2
if (e_min2 lt 0.9) then e_min2 = 0.9

model_1 = interpol( reform(fit_flux[2,*]), reform(fit_flux[0,*]), energy )
flux_residual = (flux - model_1) > 0.0  ; subtract off Temp-1 model

; default residual is zero but fill in values from first fit for the plot checks
e_data2 = e_data
f_data2 = f_data

wfit2 = where( (energy ge e_min2) and (energy le e_max2) and (flux_residual gt (FLUX_MIN*5.)), num_fit2 )
num_pts_min = 20L
if (num_fit2 lt num_pts_min) then begin
	if keyword_set(debug) then begin
		print, 'ERROR: not enough data to fit for 2nd temperature ! (#points='+strtrim(num_fit2,2)+')'
		stop, 'DEBUG ...'
	endif
	goto, PLOT_START
endif

e_data2 = energy[wfit2]
f_data2 = flux_residual[wfit2]

;
;	find which model temperature has the smallest CHI squared value
;		replace wch_cor[k,*] with model2[k,*] which has same abundance as 1st fit
;
for k=0L, num_temp-1 do begin
	f_fit = interpol( model2[k,*], wch_energy, e_data2 )
	normalize_factor = total(f_data2[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	normalize_fit2[k] = normalize_factor
	chi_fit2[k] = total((abs(f_fit - f_data2)/f_data2)^2.)
endfor

;
;	best fit is the one with smallest CHI squared value
;
chi2 = min(chi_fit2, wmin2)
;  new check to force Temperature-2 to be less than Temperature-1
if (wmin2 ge wmin) then wmin2 = wmin-1
fit_flux[3,*] = model2[wmin2,*] * normalize_fit2[wmin2]  ; Temp-2 model
fit_flux[1,*] = fit_flux[2,*] + fit_flux[3,*]   ; add both models for total
parameters.logT_2 = wch_temp[wmin2]
; default CHIANTI model DEM value is 1E27
parameters.cor_density_2 = MODEL_DEM * normalize_fit2[wmin2]
parameters.photo_density_2 = 0.0
parameters.abundance_2 = model2_af

PLOT_START:
if not keyword_set(noplot) then begin
 if keyword_set(eps) then begin
	if size(eps,/type) ne 7 then eps_name = 'fit_2temperature.eps' else eps_name = eps
	print, 'Writing EPS graphics to ', dir_eps + eps_name
	eps2_p, dir_eps + eps_name
 endif
 setplot
 cc=rainbow(7)
 cs=2.0

 plot, energy, flux, xr=[0.8,10], psym=10, xs=1, /xlog, $
	yr=[min(f_data)/10., max(f_data2)*2.], ys=1, /ylog, $
	xtitle='Energy (keV)', ytitle='Irradiance (ph/s/cm!U2!N/keV)', $
	title='Fit Chi_1='+strtrim(long(chi1),2)+', Chi_2='+strtrim(long(chi2),2)

  xx = 0.95
  my = 3.33
  yy = (10.^!y.crange[0]) * my^6
  xyouts, xx, yy,      '(1) logT='+string(parameters.logT,format='(F4.2)')+',', charsize=cs, color=cc[4]
  dem_density = parameters.cor_density
  if (parameters.photo_density ne 0) then dem_density = (parameters.photo_density+parameters.cor_density)/2.
  xyouts, xx, yy/my^1, '    EM ='+string(parameters.cor_density,format='(E7.1)')+',', charsize=cs, color=cc[4]
  xyouts, xx, yy/my^2, '    A_ph='+string(parameters.abundance,format='(F6.3)'), charsize=cs, color=cc[4]

  if (num_fit2 ge num_pts_min) then begin
    xyouts, xx, yy/my^3, '(2) logT='+string(parameters.logT_2,format='(F4.2)')+',', charsize=cs, color=cc[1]
    xyouts, xx, yy/my^4, '    EM ='+string(parameters.cor_density_2,format='(E7.1)')+',', charsize=cs, color=cc[1]
    xyouts, xx, yy/my^5, '    A_ph='+string(parameters.abundance_2,format='(F6.3)'), charsize=cs, color=cc[1]
    oplot, fit_flux[0,*], fit_flux[2,*], psym=10, color=cc[4], line=2
    oplot, min(energy[wfit2])*[1,1], 10.^!y.crange, line=1
  endif

 oplot, fit_flux[0,*], fit_flux[3,*], psym=10, color=cc[1], line=1
 oplot, fit_flux[0,*], fit_flux[1,*], psym=10, color=cc[3]

 oplot, min(energy[wfit])*[1,1], 10.^!y.crange, line=2
 oplot, max(energy[wfit])*[1,1], 10.^!y.crange, line=2

 if keyword_set(eps) then send2
endif

chi = [ chi1, chi2 ]  ; combine CHI values from both fits
if keyword_set(debug) then stop, 'STOP at end of minxss_fit_2temperature ...'
return
end
