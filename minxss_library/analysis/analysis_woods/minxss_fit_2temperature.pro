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
;		/integration_period		Option to specify X123 integration period (default is 10. sec)
;		/nolimit	Option to not Limit the irradiance level for the fit (e.g. for Sphinx-2009 fit)
;		/energy_res	Option to specify the energy resolution at 1 keV (default is 0.2 keV)
;						Energy Resolution at 1 keV:  MinXSS-1 0.21keV, MinXSS-2 0.12keV, DAXSS 0.08keV
;
;	OUTPUT
;		fit_flux	Array of model fits: [0,*] is energy, [1,*] is total flux, [2,*] is Temp-1 fit,
;						[3,*] is Temp-2 fit, [4,*] is baseline (continuum) from Temp-1 fit
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
;		9/17/2016  Tom Woods   Updated so 2nd Temperature can not be hotter than 1st Temperature (version 1)
;		11/28/2016 Tom Woods   Updated so abundance from first fit is used for second fit (version 2)
;		5/12/2017  Tom Woods   Updated so abundance is fit for all lines above 1.6 keV (version 3)
;		5/29/2017  Tom Woods   Updated so model normalization is consistent for abundance fits (version 4)
;		12/29/2021 Tom Woods	Updated with /limit, /nolimit, and energy-resolution options (version 5)
;
pro minxss_fit_2temperature, energy, flux, fit_flux, parameters=parameters, chi=chi, $
						noplot=noplot, eps=eps, integration_period=integration_period, $
						limit=limit, nolimit=nolimit, energy_res=energy_res, $
						verbose=verbose, debug=debug

common minxss_fit_temperature, wch_units, wch_temp, wch_energy, wch_cor, wch_photo

;
;	check input parameters
;
if n_params() lt 2 then begin
	print, ' '
	print, 'USAGE:  minxss_fit_2temperature, energy, flux, fit_flux, parameters=parameters, /noplot, /eps, limit=limit, /nolimit, energy_res=energy_res, /verbose, /debug'
	print, ' '
	return
endif

if not keyword_set(integration_period) then integration_period = 10.0

if not keyword_set(limit) then limit = 600.0		; MinXSS-1 irradiance limit for single 10-sec spectrum

if not keyword_set(energy_res) then energy_res = 0.2		; MinXSS-1 energy resolution number

if not keyword_set(verbose) then verbose = 0
if keyword_set(debug) then verbose = 1

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
; version 3: add abundance_fe_xxv as separate fit of abundance of just Fe XXV line
;			and abundance is value for fitting lines > 1.6 keV
parameters = { logT: 0.0, cor_density: 0.0D0, photo_density: 0.0D0, abundance: 0.0, $
			abundance_fe_xxv: 0.0, fe_xxv_flux: 0.0, abundance_ca_xix: 0.0, ca_xix_flux: 0.0, $
			logT_2: 0.0, cor_density_2: 0.0D0, photo_density_2: 0.0D0, abundance_2: 0.0, $
			uncertainty_abund: 0.0, uncertainty_abund_fe: 0.0, uncertainty_abund_ca: 0.0 }
fit_flux = -1L

FLUX_MIN = 600.   ; assumes units of photons/s/cm^2/keV from MinXSS X123: 1-sigma = 500.
FLUX_MIN = limit  ; Updated for Version 5 so user can specify irradiance lower limit
FLUX_MIN2 = FLUX_MIN/100.
if keyword_set(nolimit) then begin
	FLUX_MIN = 0.01
	FLUX_MIN2 = FLUX_MIN
endif
whigh = where( (flux gt FLUX_MIN*2.) and (energy le 10), num_high )
NUM_FIT_MIN = 20L
if (num_high lt NUM_FIT_MIN) then begin
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
; if (e_min gt 1.7) then e_min = 1.7
if (e_min gt 2.1) then e_min = 2.1

wfit = where( (energy ge e_min) and (energy le e_max) and (flux gt (FLUX_MIN*2.)), num_fit )
if (num_fit lt NUM_FIT_MIN) then begin
	if keyword_set(debug) then print, 'ERROR: not enough data to fit !'
	return
endif

e_data = energy[wfit]
f_data = flux[wfit]
f_error = sqrt((f_data*(integration_period)) > 1.)

;
;	smooth CHIANTI spectra for energy_res at 1 keV
;
etemp = min(abs(wch_energy-1.0),wemin)
nsmooth = long( energy_res / ((wch_energy[wemin+1] - wch_energy[wemin-1])/2.) + 0.5 )
smch_cor = wch_cor
smch_photo = wch_photo
if (nsmooth ge 3) then begin
	if (verbose ne 0) then print, '***** Smoothing CHIANTI spectra by ',strtrim(nsmooth,2),' bins.'
	for k=0L,num_temp-1 do begin
		smch_cor[k,*] = smooth(smooth(reform(wch_cor[k,*]),nsmooth,/edge_trun),nsmooth,/edge_trun)
		smch_photo[k,*] = smooth(smooth(reform(wch_photo[k,*]),nsmooth,/edge_trun),nsmooth,/edge_trun)
	endfor
endif ; else no smoothing needed

;
;	find which model temperature has the smallest CHI squared value
;
for k=0L, num_temp-1 do begin
	f_fit = interpol( smch_cor[k,*], wch_energy, e_data )
	normalize_factor = total(f_data[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	normalize_fit[k] = normalize_factor
	; Reduced chi-squared test
	chi_fit[k] = total((abs(f_fit - f_data)/f_error)^2.) / (num_fit-1.)
endfor

;
;	best fit is the one with smallest CHI squared value
;
chi1 = min(chi_fit, wmin)
fit_flux = fltarr(5, n_elements(wch_energy))
fit_flux[0,*] = wch_energy
fit_flux[1,*] = smch_cor[wmin,*] * normalize_fit[wmin]  ; total model flux
fit_flux[2,*] = fit_flux[1,*]  ; temp-1 model
parameters.logT = wch_temp[wmin]
; default CHIANTI model DEM value is 1E27
MODEL_DEM = 1.D27
parameters.cor_density = MODEL_DEM * normalize_fit[wmin]
normalize_fit_save = normalize_fit[wmin]
parameters.photo_density = 0.0
; Default is to fit with Corona abundance model
CF = 2.138  ; CHIANTI model abundance ratio of Fe for Corona to Photosphere
CF_LOW = 0.5
CF_HIGH = 6.0
PHOTOF = 1.0  ; unity by definition
parameters.abundance = CF
parameters.abundance_fe_xxv = 0.0	; only set if flux is high enough
parameters.abundance_ca_xix = 0.0

; relative uncertainity of abundance is based on photon statistics = 1. / sqrt((flux_line - flux_ref)/FLUX_MIN)
parameters.uncertainty_abund = -1.0
parameters.uncertainty_abund_fe = -1.0
parameters.uncertainty_abund_ca = -1.0

if (verbose ne 0) then begin
	print, '***************** Temperature-1 Fit ***********************'
	print, '***** Temp-1 = ', parameters.logT
	print, '***** EM-1   = ', parameters.cor_density
	print, '***** AF-1   = ', parameters.abundance
endif

;
;	Version 5:  fit abundance by weighting COR and PHOTO spectra
;
cf_weight = findgen(21)*0.05	; 0.0 to 1.0 in 0.05 increments
num_cf = n_elements(cf_weight)
cf_normalize_fit = fltarr(num_cf)
cf_chi_fit = fltarr(num_cf)
for k=0,num_cf-1 do begin
	smch_weighted = cf_weight[k] * smch_cor[wmin,*] + (1. - cf_weight[k]) * smch_photo[wmin,*]
	f_fit = interpol( smch_weighted, wch_energy, e_data )
	normalize_factor = total(f_data[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	cf_normalize_fit[k] = normalize_factor
	; Reduced chi-squared test
	cf_chi_fit[k] = total((abs(f_fit - f_data)/f_error)^2.) / (num_fit-1.)
endfor
;
;	best fit is the one with smallest CHI squared value
;
cf_chi1 = min(cf_chi_fit, cf_wmin)
smch_weighted_best = cf_weight[cf_wmin] * smch_cor[wmin,*] + (1. - cf_weight[cf_wmin]) * smch_photo[wmin,*]
smch_weighted_best *= cf_normalize_fit[cf_wmin]
fit_flux[1,*] = smch_weighted_best  ; total model flux
fit_flux[2,*] = fit_flux[1,*]  ; temp-1 model
parameters.cor_density = MODEL_DEM * cf_normalize_fit[cf_wmin]
; Abundance factor ranges between COR and PHOTO model AF values (so limit of 1.0 to 2.138)
parameters.abundance = cf_weight[cf_wmin] * CF + (1. - cf_weight[cf_wmin]) * PHOTOF

if (verbose ne 0) then begin
	print, '***************** Abundance-1 Fit ***********************'
	print, '***** Temp-1 = ', parameters.logT
	print, '***** EM-1   = ', parameters.cor_density
	print, '***** AF-1   = ', parameters.abundance
endif

;
; use Coronal Abundance model for 2nd temperature fit (unless get abundance from 1st fit)
;
model2_af = CF
model2 = smch_cor

use_norm_save = 0	; set to 1 if want to use Abundance fits with normalize_fit_save
DEBUG_SPECIAL = 1	; set to 1 if want plot of Full Range (Si) Abundance fit
didSpecialPlot = 0

; use SMOOTH Flux for peak finding
fff = finite(flux)  ; first fix NaN and INFINITY in the flux spectrum
wbad=where( fff ne 1, numbad)
if (numbad gt 0) then flux[wbad] = 0.
sm_flux = smooth(flux,3,/edge_trun) > 0.

;
;	Do Abundance fitting for Si (> 1.7 keV), Ca (> 3.3 keV), and Fe (> 6.0 keV)
;	Adjust model fit when abundance changes
;
;
;	VERSION 3:  fit abundance for the full spectral range - mostly for Si lines at lower energy
;	if logT > 5.7 and max energy > 5 keV then can also do abundance fit for all SXR lines
;
;		Abundance Factor of Photospheric Abundance for all lines is calculated as
;			AF = total(flux - baseline) / total(model_photo - baseline)
;	where baseline = ((CF * model_photo) - model_cor) / (CF - 1.0) [spectra difference]
;	where CF = 2.138 from the abundance value used in CHIANTI model run
;
e_min_abund = 2.0		; Version 3.1 = 1.7 (Si), Version 3.2 = 2.0 (Si), Version 3.3 = 3.5 (Ca)
e_max_abund = e_min_abund * 1.5
e_min_abund2 = e_min_abund + 0.3  ; for normalization range
e_min_line1 = 2.3
e_min_line2 = e_min_line1 + 0.3
if (verbose ne 0) then begin
  print, ' '
  print, 'DEBUG Si Fit: parameters.logT ge 5.8: ', parameters.logT
  print, 'DEBUG Si Fit: e_max ge e_max_abund: ', e_max, e_max_abund
endif
if (parameters.logT ge 5.8) and (e_max ge e_max_abund) then begin
	; select energy range for the fitted range between e_min and e_max
	wch = where( (wch_energy ge e_min_abund) and (wch_energy le e_min_abund2) )
	wch_step = abs(wch_energy[wch[1]] - wch_energy[wch[0]])
	win = where( (energy ge e_min_abund) and (energy le e_min_abund2) )
	in_step = abs(energy[win[1]] - energy[win[0]])
	band_factor = (max(wch_energy[wch])-min(wch_energy[wch]))
	flux_ref = total(flux[win]*in_step) / (max(energy[win])-min(energy[win]))
	flux_in = flux[win]
	wline = where( (energy ge e_min_line1) and (energy le e_min_line2) )
	flux_line = total(flux[wline]*in_step) / (max(energy[wline])-min(energy[wline]))
	;  only calculate abundance if signal is high enough for good calculation
	if (verbose ne 0) then begin
  		print, 'DEBUG Si Fit: flux_ref gt (FLUX_MIN*6): ', flux_ref, FLUX_MIN*6.
	endif
	if (flux_ref gt (FLUX_MIN*6)) then begin
		parameters.uncertainty_abund = 1. / sqrt(((flux_line - flux_ref)/FLUX_MIN)> 1.)
		if (use_norm_save eq 0) then norm_cor = flux_ref / (total(reform(smch_cor[wmin,wch])*wch_step)/band_factor) $
		else norm_cor = normalize_fit_save  ; new normalization - Version 4
		model_cor = reform(smch_cor[wmin,*]) * norm_cor
		parameters.cor_density = MODEL_DEM * norm_cor
		if (use_norm_save eq 0) then norm_photo = flux_ref / (total(reform(smch_photo[wmin,wch])*wch_step)/band_factor) $
		else norm_photo = normalize_fit_save  ; new normalization - Version 4
		model_photo = reform(smch_photo[wmin,*]) * norm_photo
		parameters.photo_density = MODEL_DEM * norm_photo
		;  get scaling from 0 (photosphere) to 1 (coronal) for the abuandance based on full SXR spectrum
		norm_avg = (norm_cor + norm_photo)/2.
		model_cor_ref = reform(smch_cor[wmin,*]) * norm_avg
		model_photo_ref = reform(smch_photo[wmin,*]) * norm_avg
		cbaseline = ((CF * model_photo_ref - model_cor_ref) / (CF-1.0)) > 0.
		baseline = interpol( cbaseline, wch_energy, energy[win] ) > 0.
		clines = (model_photo_ref - cbaseline) > 0.   ; is the same thing as (model_cor - model_photo) / (CF-1.0)
		lines = interpol( clines, wch_energy, energy[win] ) > 0.
		meas_lines = smooth( smooth(flux_in - baseline, 3, /edge_trun), 3, /edge_trun) > 0.
		abundance_full_guess = total(meas_lines) / total(lines)  ; first order estimate only
		;  do fits to get chi-square minimum
		n_grid = long((CF_HIGH - CF_LOW)/0.05 + 1)
		a_grid = findgen(n_grid)*0.05 + CF_LOW
		chi_grid = fltarr(n_grid)
		for k=0L,n_grid-1 do begin
			chi_grid[k] = total( abs(meas_lines-lines*a_grid[k])^2. )   ; / meas_lines
		endfor
		min_chi_grid = min(chi_grid, wmin_grid)
		abundance_full = a_grid[wmin_grid]
		parameters.abundance = abundance_full
		;  limit abundance range
		if (parameters.abundance lt CF_LOW) then parameters.abundance = CF_LOW
		if (parameters.abundance gt CF_HIGH) then parameters.abundance = CF_HIGH
		;
		;  now scale for better model fit using A = abundance
		;		model = A * Photo - ((A-1)/(CF-1))*(CF*Photo - Cor)
		;
		model_better = parameters.abundance * model_photo_ref - ((parameters.abundance-1.)/(CF-1.)) * $
						(CF * model_photo_ref - model_cor_ref)
		wnew = where( wch_energy ge e_min_abund )
		fit_flux[1,wnew] = model_better[wnew]
		fit_flux[2,wnew] = model_better[wnew]
		fit_flux[4,*] = cbaseline   ; also keep baseline (continuum)

		if (DEBUG_SPECIAL ne 0) then begin
		  setplot & cc=rainbow(7)
		  didSpecialPlot = 1
		  mtitle = 'log(T)='+string(parameters.logT,format='(F4.2)')+', A='+$
		  			string(parameters.abundance,format='(F4.2)')
		  if (parameters.ca_xix_flux gt 0) then mtitle += ', A_Ca='+$
		  			string(parameters.abundance_ca_xix,format='(F4.2)')
		  if (parameters.fe_xxv_flux gt 0) then mtitle += ', A_Fe='+$
		  			string(parameters.abundance_fe_xxv,format='(F4.2)')
		  plot,energy,flux,xr=[1,10],xs=1,/xlog,yr=[1E2,1E8],ys=1,/ylog,psym=10, $
		  		xtitle='Energy (keV)', ytitle='Irradiance', title=mtitle
		  oplot,e_min*[1,1],10.^!y.crange,line=1
		  oplot,e_min_abund*[1,1],10.^!y.crange,line=2
		  oplot,energy[win],meas_lines,psym=10,thick=3,color=cc[6]
		  oplot,wch_energy,model_photo_ref,color=cc[3]
		  oplot,wch_energy,model_cor_ref,color=cc[1]
		  oplot,wch_energy,cbaseline,color=cc[0]
		  oplot,wch_energy,clines*abundance_full,color=cc[4]
		endif

		;
		;	use 1st fit abundance for 2nd fit
		;
		model2_af = parameters.abundance
		for k=0L, num_temp-1 do begin
			model2[k,wnew] = model2_af * reform(smch_photo[k,wnew]) - $
				((model2_af-1.)/(CF-1.)) * (CF * reform(smch_photo[k,wnew]) - reform(smch_cor[k,wnew]))
		endfor
	endif else begin
		if (verbose ne 0) then print, 'WARNING: All (Si) abundance not fit as flux is low: ', flux_ref
	endelse
endif

;
;	do abundance fit for Ca XIX 3.9 keV if logT > 6.7 and energy > 3.3 keV
;
;		Abundance Factor of Photospheric Abundance at Ca 3.9 keV is calculated as
;			AF = (max(flux_3.9keV) - baseline) / (max(model_photo_3.9keV) - baseline)
;	where baseline = (CF * max(model_photo_3.9keV) - max(model_cor_3.9keV)) / (CF - 1.0)
;	where CF = 2.138 from the abundance values of Ca used in CHIANTI model run
;
if (verbose ne 0) then begin
  print, ' '
  print, 'DEBUG Ca Fit: parameters.logT ge 6.2: ', parameters.logT
  print, 'DEBUG Ca Fit: (e_min lt 3.3) and (e_max gt 4.0): ', e_min, e_max
endif
if (parameters.logT ge 6.2) and (e_min lt 3.3) and (e_max gt 4.0) then begin
	wch = where( (wch_energy ge 3.3) and (wch_energy le 3.6) )
	wch_step = abs(wch_energy[wch[1]] - wch_energy[wch[0]])
	win = where( (energy ge 3.3) and (energy le 3.6) )
	in_step = abs(energy[win[1]] - energy[win[0]])
	band_factor = (max(wch_energy[wch])-min(wch_energy[wch]))
	flux_ref = total(flux[win]*in_step) / (max(energy[win])-min(energy[win]))
	wline = where( (energy ge 3.6) and (energy le 4.2) )
	flux_line = total(flux[wline]*in_step) / (max(energy[wline])-min(energy[wline]))
	parameters.ca_xix_flux = flux_ref
	;  only calculate abundance if signal is high enough for good calculation
	if (verbose ne 0) then begin
  		print, 'DEBUG Ca Fit: flux_ref gt (FLUX_MIN*4): ', flux_ref, FLUX_MIN*4.
	endif
	if (flux_ref gt (FLUX_MIN*4)) then begin
		parameters.uncertainty_abund_ca = 1. / sqrt(((flux_line - flux_ref)/FLUX_MIN)> 1.)
		if (use_norm_save eq 0) then norm_cor = flux_ref / (total(reform(smch_cor[wmin,wch])*wch_step) / band_factor) $
		else norm_cor = normalize_fit_save  ; new normalization - Version 4
		model_cor = reform(smch_cor[wmin,*]) * norm_cor
		parameters.cor_density = MODEL_DEM * norm_cor
		if (use_norm_save eq 0) then norm_photo = flux_ref / (total(reform(smch_photo[wmin,wch])*wch_step) / band_factor) $
		else norm_photo = normalize_fit_save  ; new normalization - Version 4
		model_photo = reform(smch_photo[wmin,*]) * norm_photo
		parameters.photo_density = MODEL_DEM * norm_photo
		;  get scaling from 0 (photosphere) to 1 (coronal) for the abuandance based on Fe peak at 6.7 keV
		wchpeak = where( (wch_energy ge 3.75) and (wch_energy le 4.05) )
		peak_cor = max(model_cor[wchpeak])
		peak_photo = max(model_photo[wchpeak])
		winpeak = where( (energy ge 3.75) and (energy le 4.05) )
		peak_flux = max(sm_flux[winpeak])
		baseline = (CF * peak_photo - peak_cor) / (CF - 1.0)
		parameters.abundance_ca_xix = (peak_flux - baseline) / (peak_photo - baseline)
		;  limit abundance range
		if (parameters.abundance_ca_xix lt CF_LOW) then parameters.abundance_ca_xix = CF_LOW
		if (parameters.abundance_ca_xix gt CF_HIGH) then parameters.abundance_ca_xix = CF_HIGH
		;
		;  now scale for better model fit using A = abundance_fe_xxv
		;		model = A * Photo - ((A-1)/(CF-1))*(CF*Photo - Cor)
		;
		model_better = parameters.abundance_ca_xix * model_photo - ((parameters.abundance_ca_xix-1.)/(CF-1.)) * $
						(CF * model_photo - model_cor)
		wnew = where( wch_energy ge 3.3 )
		fit_flux[1,wnew] = model_better[wnew]
		fit_flux[2,wnew] = model_better[wnew]
		;
		;	use 1st fit abundance for 2nd fit
		;
		model2_af = parameters.abundance_ca_xix
		for k=0L, num_temp-1 do begin
			model2[k,wnew] = model2_af * reform(smch_photo[k,wnew]) - $
				((model2_af-1.)/(CF-1.)) * (CF * reform(smch_photo[k,wnew]) - reform(smch_cor[k,wnew]))
		endfor
	endif else begin
		if (verbose ne 0) then print, 'WARNING: Ca abundance not fit as flux is low: ', flux_ref
	endelse
endif

;
;	do abundance fit for Fe XXV 6.7 keV if logT > 6.8 and energy > 6.0 keV
;
;		Abundance Factor of Photospheric Abundance at Fe 6.7 keV is calculated as
;			AF = (max(flux_6.7keV) - baseline) / (max(model_photo_6.7keV) - baseline)
;	where baseline = (CF * max(model_photo_6.7keV) - max(model_cor_6.7keV)) / (CF - 1.0)
;	where CF = 2.138 from the abundance values of Fe used in CHIANTI model run
;
if (verbose ne 0) then begin
  print, ' '
  print, 'DEBUG Fe Fit: parameters.logT ge 6.6: ', parameters.logT
  print, 'DEBUG Fe Fit: (e_min lt 6.0) and (e_max gt 7.0): ', e_min, e_max
endif
if (parameters.logT ge 6.6) and (e_min lt 6.0) and (e_max gt 7.0) then begin
	wch = where( (wch_energy ge 6.0) and (wch_energy le 6.3) )
	wch_step = abs(wch_energy[wch[1]] - wch_energy[wch[0]])
	win = where( (energy ge 6.0) and (energy le 6.3) )
	in_step = abs(energy[win[1]] - energy[win[0]])
	band_factor = (max(wch_energy[wch])-min(wch_energy[wch]))
	flux_ref = total(flux[win]*in_step) / (max(energy[win])-min(energy[win]))
	wline = where( (energy ge 6.3) and (energy le 7.0) )
	flux_line = total(flux[wline]*in_step) / (max(energy[wline])-min(energy[wline]))
	parameters.fe_xxv_flux = flux_line
	;  only calculate abundance if signal is high enough for good calculation
	if (verbose ne 0) then begin
  		print, 'DEBUG Fe Fit: flux_ref gt (FLUX_MIN*2.): ', flux_ref, FLUX_MIN
	endif
	if (flux_ref gt (FLUX_MIN*2.)) then begin
		parameters.uncertainty_abund_fe = 1. / sqrt(((flux_line - flux_ref)/FLUX_MIN)> 1.)
		if (use_norm_save eq 0) then norm_cor = flux_ref / (total(reform(smch_cor[wmin,wch])*wch_step) / band_factor) $
		else norm_cor = normalize_fit_save  ; new normalization - Version 4
		model_cor = reform(smch_cor[wmin,*]) * norm_cor
		parameters.cor_density = MODEL_DEM * norm_cor
		if (use_norm_save eq 0) then norm_photo = flux_ref / (total(reform(smch_photo[wmin,wch])*wch_step) / band_factor) $
		else norm_photo = normalize_fit_save  ; new normalization - Version 4
		model_photo = reform(smch_photo[wmin,*]) * norm_photo
		parameters.photo_density = MODEL_DEM * norm_photo
		;  get scaling from 0 (photosphere) to 1 (coronal) for the abuandance based on Fe peak at 6.7 keV
		wchpeak = where( (wch_energy ge 6.55) and (wch_energy le 6.85) )
		peak_cor = max(model_cor[wchpeak])
		peak_photo = max(model_photo[wchpeak])
		winpeak = where( (energy ge 6.55) and (energy le 6.85) )
		peak_flux = max(sm_flux[winpeak])
		baseline = (CF * peak_photo - peak_cor) / (CF - 1.0)
		parameters.abundance_fe_xxv = (peak_flux - baseline) / (peak_photo - baseline)
		;  limit abundance range
		if (parameters.abundance_fe_xxv lt CF_LOW) then parameters.abundance_fe_xxv = CF_LOW
		if (parameters.abundance_fe_xxv gt CF_HIGH) then parameters.abundance_fe_xxv = CF_HIGH
		;
		;  now scale for better model fit using A = abundance_fe_xxv
		;		model = A * Photo - ((A-1)/(CF-1))*(CF*Photo - Cor)
		;
		model_better = parameters.abundance_fe_xxv * model_photo - ((parameters.abundance_fe_xxv-1.)/(CF-1.)) * $
						(CF * model_photo - model_cor)
		wnew = where( wch_energy ge 6.0 )
		fit_flux[1,wnew] = model_better[wnew]
		fit_flux[2,wnew] = model_better[wnew]
		;
		;	use 1st fit abundance for 2nd fit
		;
		model2_af = parameters.abundance_fe_xxv
		for k=0L, num_temp-1 do begin
			model2[k,wnew] = model2_af * reform(smch_photo[k,wnew]) - $
				((model2_af-1.)/(CF-1.)) * (CF * reform(smch_photo[k,wnew]) - reform(smch_cor[k,wnew]))
		endfor
	endif else begin
		if (verbose ne 0) then print, 'WARNING: Fe abundance not fit as flux is low: ', flux_ref
	endelse
endif

if (DEBUG_SPECIAL ne 0) and (didSpecialPlot ne 0) then begin
	if (e_max gt 7.0) then begin
		print, 'Abundance full = ', strtrim(abundance_full,2), ', Abundance Ca XIX = ', $
		    		strtrim(parameters.abundance_ca_xix,2), ', Abundance Fe XXV = ', $
		    		strtrim(parameters.abundance_fe_xxv,2)
		; stop, 'DEBUG baseline for Version 3...'
	endif
	oplot,wch_energy,fit_flux[1,*],color=cc[3],thick=3,line=2
endif

;
;	Version 2: new part for fitting second temperature
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

wfit2 = where( (energy ge e_min2) and (energy le e_max2) and (flux_residual gt (FLUX_MIN*2.)), num_fit2 )
if (num_fit2 lt NUM_FIT_MIN) then begin
	if keyword_set(debug) then begin
		print, 'ERROR: not enough data to fit for 2nd temperature ! (#points='+strtrim(num_fit2,2)+')'
		stop, 'DEBUG FIT-Temp-2 ...'
	endif
	goto, PLOT_START
endif

e_data2 = energy[wfit2]
f_data2 = flux_residual[wfit2]
f_error2 = sqrt((f_data2*(integration_period)) > 1.)

;
;	find which model temperature has the smallest CHI squared value
;		replace smch_cor[k,*] with model2[k,*] which has same abundance as 1st fit
;
for k=0L, num_temp-1 do begin
	f_fit = interpol( model2[k,*], wch_energy, e_data2 )
	normalize_factor = total(f_data2[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	normalize_fit2[k] = normalize_factor
	; Reduced chi-squared test
	chi_fit2[k] = total((abs(f_fit - f_data2)/f_error2)^2.) / (num_fit2-1.)
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


if (verbose ne 0) then begin
	print, '***************** Temperature-2 Fit ***********************'
	print, '***** Temp-2 = ', parameters.logT_2
	print, '***** EM-2   = ', parameters.cor_density_2
	print, '***** AF-2   = ', parameters.abundance_2
endif

;
;	Version 5:  fit abundance by weighting COR and PHOTO spectra
;
cf_weight = findgen(21)*0.05	; 0.0 to 1.0 in 0.05 increments
num_cf = n_elements(cf_weight)
cf_normalize_fit2 = fltarr(num_cf)
cf_chi_fit2 = fltarr(num_cf)
for k=0,num_cf-1 do begin
	smch_weighted = cf_weight[k] * smch_cor[wmin2,*] + (1. - cf_weight[k]) * smch_photo[wmin2,*]
	f_fit = interpol( smch_weighted, wch_energy, e_data2 )
	normalize_factor = total(f_data2[0:9]) / total(f_fit[0:9])   ; force scaling by first 10 points
	f_fit *= normalize_factor
	cf_normalize_fit2[k] = normalize_factor
	; Reduced chi-squared test
	cf_chi_fit2[k] = total((abs(f_fit - f_data2)/f_error2)^2.) / (num_fit2-1.)
endfor
;
;	best fit is the one with smallest CHI squared value
;
cf_chi2 = min(cf_chi_fit2, cf_wmin2)
smch_weighted_best2 = cf_weight[cf_wmin2] * smch_cor[wmin2,*] + (1. - cf_weight[cf_wmin2]) * smch_photo[wmin2,*]
smch_weighted_best2 *= cf_normalize_fit2[cf_wmin2]
fit_flux[3,*] = smch_weighted_best2  ; total model flux
fit_flux[1,*] = fit_flux[2,*] + fit_flux[3,*] ; temp-1 model + temp-2 model
; parameters.logT_2 = wch_temp[wmin2]  ; already determined
; default CHIANTI model DEM value is 1E27
parameters.cor_density_2 = MODEL_DEM * cf_normalize_fit2[cf_wmin2]
parameters.photo_density_2 = 0.0
parameters.abundance_2 = cf_weight[cf_wmin2] * CF + (1. - cf_weight[cf_wmin2]) * PHOTOF

if (verbose ne 0) then begin
	print, '***************** Abundance-2 Fit ***********************'
	print, '***** Temp-2 = ', parameters.logT_2
	print, '***** EM-2   = ', parameters.cor_density_2
	print, '***** AF-2   = ', parameters.abundance_2
endif

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

  if (num_fit2 ge NUM_FIT_MIN) then begin
    xyouts, xx, yy/my^3, '(2) logT='+string(parameters.logT_2,format='(F4.2)')+',', charsize=cs, color=cc[1]
    xyouts, xx, yy/my^4, '    EM ='+string(parameters.cor_density_2,format='(E7.1)')+',', charsize=cs, color=cc[1]
    xyouts, xx, yy/my^5, '    A_ph='+string(parameters.abundance_2,format='(F6.3)'), charsize=cs, color=cc[1]
    oplot, fit_flux[0,*], fit_flux[2,*], psym=10, color=cc[4], line=2
    oplot, e_data2, f_data2, psym=10, color=cc[5]
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
