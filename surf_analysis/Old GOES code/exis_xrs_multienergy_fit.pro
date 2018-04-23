pro xrs_surf_response, energy, thicks, predict

; Calculate the predicted XRS beam-normalized current (fA/mA) for a SURF beam with a given energy, and XRS filter of given thickness
; SURF parameters loaded via common block; energy in MeV
; thickness given in µm
; Result placed into "predict" output array (same number of elements are "energy" input array)


  ; Load SURF flux and beam energy arrays, and XRS detector area
  ; SURF flux in photons/(sec nm mA mm^2) ... beam energy in MeV
  ; XRS area in mm^2
  common exis_xrs_me_share1, surfflux, fluxenergy, area

  if (n_elements(surfflux) eq 0) or (n_elements(fluxenergy) eq 0) then message, 'SURF fluxes must be set in the common block!  Cannot continue...'
  if (n_elements(area) eq 0) then message, 'Channel area must be set in the common block!  Cannot continue...'
  if (getenv('henke_model') eq '') then message, 'Henke directory must be set in environment variable "henke_model!"  Cannot continue...'

  fC_per_e = 1.602d-19 * 1d15  ; electronic charge (C) * fC/C --> fC/electron
  
  nenergy = n_elements(energy)
  predict = fltarr(nenergy)

  ; If multiple thicknesses provided, use different passive elements...
  case n_elements(thicks) of
    1: elems = ['Be']
    2: elems = ['Be', 'BeO']
;    3: elems = ['Be', 'BeO', 'SiO']
;    4: elems = ['Be', 'BeO', 'SiO', 'Si']
  endcase

  ; Get Henke response for 55 µm Silicon, 70 Å SiO absorption layer, and specified thicknesses
  diode_param, elems, thicks*1E4, wv, resp, si=55.E4, ox=70., /noplot
  ; Wavelength given in Å -- convert to nm for compatibility with SURF
  ; Response given in electron/photon
  wv = reverse(wv)/10.
  resp = reverse(resp)

  ; Determine maximum wavelength range covering both Henke model and SURF beam fluxes
  wvmin = max( [min(surfflux[0,*]),min(wv)] )
  wvmax = min( [max(surfflux[0,*]),max(wv)] )
  wgs = where( (surfflux[0,*] ge wvmin) and (surfflux[0,*] le wvmax) )
  swave = reform(surfflux[0,wgs])

  ; get bandpass (wavelength step, i.e. bin widths)
  nsurf = n_elements(surfflux[0,*])
  bandwave = reform(abs(shift(surfflux[0,*],1) - shift(surfflux[0,*],-1))/2.)
  bandwave[0] = bandwave[1]
  bandwave[nsurf-1] = bandwave[nsurf-2]
  dwave = bandwave[wgs]

  for k=0, nenergy-1 do begin ; For each specified beam energy...
    ediff = min(abs(fluxenergy-energy[k]),isurf) ; determine which SURF flux to use
    if (ediff ne 0.0) then message, /info, 'WARNING: Using ' + strtrim(fluxenergy[isurf],2) + ' instead of ' + strtrim(energy[k],2) + ' MeV'
    sflux = reform(surfflux[isurf+1,wgs])
    
    ; get the Henke response interpolated to SURF flux wavelengths
    cresponse = interpol( resp, wv, swave )
  
    ; calculate the predicted beam-normalized current (fA/mA) = SUM [(ph/(sec nm mA mm^2)) * (el/ph) * (nm)] * mm^2 * fC/el = fC/(s mA)
    predict[k] = total( sflux * cresponse * dwave ) * area * fC_per_e
  endfor

end


;
;+
; NAME:
;	exis_xrs_multienergy_fit
;
; PURPOSE:
;	Process multi-energy SURF data to get scaling factors for Henke model
;	Updated for EXIS output format
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	exis_xrs_multienergy_fit, <channel> [, fm=fm, surffiles=, thick0=, /despike, /correctbc, /dataman, [other options, see usage info] ]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
; fm        Options are 0-4 (0=ETU, not yet supported)
; thick0    Initial estimate of Be filter thickness [nominal physical thickness]
;	/debug		Option to print DEBUG messages
;	
; OUTPUTS:  
;	PLOT		Showing fit of Henke model to SURF measurements at multi-energy
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data using plot_xrs_gse.pro
;	3.  Calculate the Henke model scale factors for each beam energy
;
; MODIFICATION HISTORY:
;  11/19/2012		Amir Caspi -- Original file creation based on ETU files
;  04/23/2013   Amir Caspi -- Added fm and correctbc keywords (passed to exis_process_surfdata)
;+

pro exis_xrs_multienergy_fit, channel, surffiles=surffiles, thick0=thick0, fm=fm, despike=despike, correctbc=correctbc, correcttime=correcttime, dataman=dataman, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, debug=debug, help=help
;
;	1.  Check input parameters
;

if n_params() lt 1 or keyword_set(help) then begin
  message, /info, 'USAGE:  exis_xrs_multienergy_fit, <channel> [, fm=fm, surffiles=surffiles, thick0=thick0, despike=despike, correctbc=correctbc, dataman=dataman, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, debug=debug, help=help ]'
  message, /info, 'CALCULATES optimal Be filter thickness for <channel> to match SURF multi-energy observations.'
  message, /info, "Set fm to appropriate flight model number, 1-4, or 0 for ETU [DEFAULT: 1]"
  message, /info, "<channel> must be one of: A1, B1, A2, B2."
  message, /info, "Looks for SURF files in energy-segregated directory tree [DEFAULT = path_prefix/goesr-work/science_analysis/amir/fm1/xrs/multienergy/]... to override default directory, set [surffiles] to scalar directory path... to override all searching, set [surffiles] to ARRAY of SURF filenames (to be found in path_prefix/surf_dir)."
  message, /info, "Set [thick0] to initial estimate of Be filter thickness, in microns [DEFAULT = 571 for A1/A2, 64 for B1/B2]."
  message, /info, "Set /despike to attempt spike removal in SURF beam current (MAY exclude good data by accident)'
  message, /info, "Set /correctbc to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)"
  message, /info, "Set path_prefix, surf_dir, data_dir, and/or gain_dir if needed (default values in exis_process_surfdata.pro)"
  return
endif

; Establish common block for SURF flux and beam energy arrays, XRS detector area, and conversion factor
; To be used with xrs_surf_response fitting function
common exis_xrs_me_share1, surfflux, fluxenergy, area
setenv,'henke_model='+path_prefix+'/goesr-work/science_analysis/amir/idl/Henke_Model'

; Check XRS channel for validity
ch = strupcase(strmid(channel,0,2))
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
  message, /info, 'ERROR: Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return
endif

; Define search directories
path_prefix = keyword_set(path_prefix) ? strtrim(path_prefix,2) : ''
surf_dir = keyword_set(surf_dir) ? surf_dir : ''
do_search = n_elements(surffiles) le 1
surf_filesdir = (n_elements(surffiles) eq 0) ? path_prefix + '/goesr-work/science_analysis/amir/fm1/xrs/multienergy/' + ch : ((n_elements(surffiles) eq 1) ? surffiles : surf_dir)
surf_fluxesdir = path_prefix + '/goesr-work/science_analysis/amir/fm1/xrs/surf_fluxes'

; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; TEST using old GSE data
;surf_filesdir = getenv('xrs_cal') + '/MultiEnergy/' + ch + '/Filt5'
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------

; Read the SURF flux file appropriate to the selected XRS channel (depends on the aperture!)
; *** surfflux and fluxenergy variables go into the common block for the automatic fitting ***
fluxfile = 'SURF_FLUX_XRS' + strmid(ch,1,1) + '.dat'
surfflux = read_dat(surf_fluxesdir + '/' + fluxfile)
fluxenergy = [ 183, 285, 331, 361, 380, 408 ]
nflux = n_elements(fluxenergy)

; Set appropriate XRS channel area
area = xrs_area(ch, fm=fm) * 100  ; convert from cm^2 to mm^2
; Set default initial Be filter thickness
be_thick = keyword_set(thick0) ? thick0 : ((strmid(ch,0,1) eq 'A') ? 571. : 63.5)

;	If do_search is set, then using the directory structure, find appropriate energies and SURF log files to read
if do_search then begin
  fff = file_search(surf_filesdir + '/*', /test_dir)
  if (n_elements(fff) eq 0) then begin
    message, /info, "ERROR: Could not find any energy directories in " + surf_filesdir + '/'
    return
  endif else begin
    energy_dirs = fix(strsplit(fff[0], surf_filesdir + '/', /ex, /reg))
    for i=1,n_elements(fff)-1 do energy_dirs = [energy_dirs, fix(strsplit(fff[i], surf_filesdir + '/', /ex, /reg))]
  endelse
  nenergies = n_elements(energy_dirs)
endif else begin ; files keyword set to array of files... we will need to determine the beam energies from the files!
  nenergies = n_elements(surffiles)
endelse

setplot
cc=rainbow(7)
format = '(I5,2E12.3,F8.3,F16.5)'

energies = fltarr(nenergies)
meas = fltarr(nenergies)
meas_err = fltarr(nenergies)
predict = fltarr(nenergies)

for k=0, nenergies-1 do begin
  if do_search then begin
    fffdir = surf_filesdir + '/' + strtrim(energy_dirs[k],2)
    fff = file_search(fffdir + '/SURF_*.txt')
    if (n_elements(fff) eq 0) then begin
		  print, "ERROR: Could not find any SURF data files in " + fffdir + '/'
      return
    endif else if (n_elements(fff) gt 1) then begin
		  print, "Found multiple SURF files for " + strtrim(energy_dirs[k],2) + "- choose one:"
      for i = 0, n_elements(fff) - 1 do print, "["+strtrim(i,2)+"] "+fff[i]
      read, "Use which SURF file: ", i
      sfile = fff[i]
    endif else sfile = fff
  endif else sfile = surffiles[k]

; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; TEST using old GSE data
;ihenke = where(['','A1','A2','B1','B2'] eq ch)
;asic = ([2026, 2158, 2158, 2026])[ihenke-1]
;  fff = file_search(fffdir + '/*_xrs_'+strcompress(string(asic), /rem) + '.txt')
;  if (n_elements(fff) eq 0) then begin
;    print, "ERROR: Could not find any appropriate ASIC data files in " + fffdir
;    return
;  endif else if (n_elements(fff) gt 1) then begin
;    print, "Found multiple data files - choose one:"
;    for i = 0, n_elements(fff) - 1 do print, "["+strcompress(string(i), /rem)+"] "+fff[i]
;    read, "Use which data file: ", i
;    dfile = fff[i]
;  endif else dfile = fff
;  plot_xrs_gse_ac, ch, dfile, sfile, itime=1.0, data=data, debug = debug, /darkman
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------
; ------------- REMOVE ME ----------- REMOVE ME ------------- REMOVE ME ------------

  ; Process the EXIS data related to the specified SURF file
  print, "Processing SURF file "+strtrim(k+1,2)+" of "+strtrim(nenergies,2)
  data = exis_process_surfdata(sfile, 'XRS', ch, fm=fm, /darkman, despike=despike, correctbc=correctbc, correcttime=correcttime, data_dir=data_dir, surf_dir=surf_filesdir, gain_dir=gain_dir, path_prefix=path_prefix, debug=debug)
  ; Determine the dominant SURF beam energy (even if the energy was supposedly specified by the directory search)
  energies[k] = round(median(data.surfenergy))
  if keyword_set(debug) then message, /info, "DEBUG: Found beam energy of "+strtrim(energies[k],2)+" MeV"
  if ((n_elements(energy_dirs) ne 0) && (energies[k] ne energy_dirs[k])) then message, /info, "WARNING: beam energy of " + strtrim(energies[k],2) + " in data DIFFERS from directory name " + strtrim(energy_dirs[k],2)

  ans = keyword_set(dataman) ? 'N' : 'Y'
  ; Select the good data...
  repeat begin 
    plot, /nodata, data.time, data.signal, xs=4, ys=4
    if ((median(data.surfvalves) ne -1) and (median(data.surfvalves) ne 0)) then begin
      polyfill, [min(data.time), data.time, max(data.time)], [!y.crange[0], (data.surfvalves eq 7)*!y.crange[0] + (data.surfvalves ne 7)*!y.crange[1], !y.crange[0]], color='dddddd'x, noclip=0
    endif
    plot, /noerase, data.time, data.signal, xtitle='Time [sec]', ytitle='Signal [fA/mA]', title='XRS-'+ch+', E='+strtrim(energies[k],2)+' MeV'

    if (ans eq 'Y') then begin
    ; Automatically select good data

    ;  select the high data as right data for comparison
      dlimit = max(data.signal)*0.90
      whi = where( data.signal gt dlimit, numhi )
    endif else begin
    ; MANUALLY select good data
      print, 'Select the data range...'
      print, 'Move cursor to LEFT side of the Good (light) Data and click...'
      cursor, x1, y1, /down
      oplot, [x1, x1], !y.crange, line=2
      print, 'Move cursor to RIGHT side of the Good (light) Data and click...'
      cursor, x2, y2, /down
      oplot, [x2, x2], !y.crange, line=2
      ;  get scan data
      whi = where( (data.time ge x1) and (data.time le x2), numhi )
      dlimit = min(data[whi].signal)
    endelse
      
    if (numhi gt 2) then begin
      ; Determine average signal and uncertainty
;      meas[k] = median(data[whi].signal)
      meas[k] = mean(data[whi].signal)
      meas_err[k] = stddev(data[whi].signal) ;/ numhi
    endif else begin
      ; Only one or two data points chosen... 
      print, 'WARNING: not enough data points close to max ... using only maximum signal (1 point!)'
      meas[k] = max(data.signal)
      meas_err[k] = meas[k]
    endelse
  
    oplot, !x.crange, dlimit*[1,1], line=2
    ;oplot, !x.crange, meas[k]*[1,1], color=cc[3]
    oplot, data[whi].time, data[whi].signal, color=cc[3]
    read, prompt="Selected data range OK? [Y] ", ans
  endrep until (strmid(strupcase(ans),0,1) eq "Y" or ans eq "")
  
  ; Calculate predicted current with INITIAL filter thickness
  xrs_surf_response, energies[k], be_thick, xxx
  predict[k] = xxx
  
  if keyword_set(debug) and (k lt nenergies-1) then read, prompt='Next Energy ? [Hit RETURN when ready] ', ans
endfor

print, ' '
print, 'For INITIAL THICKNESS of ' + strtrim(be_thick,2) + ' microns:'
print, 'Energy    Measure    Predict    Ratio M/P   Rel. Uncertainty  for XRS-'+ch
print, '------    -------    -------    ---------   ---------------'
for k=0,nenergies-1 do print, energies[k], meas[k], predict[k], meas[k]/predict[k], meas_err[k]/meas[k], format=format
print, ' '

thicks = [be_thick, 70./1e4]
status = 1
; Find best-fit filter thickness based on measurements vs. energy
while (status ne 0) do begin
  predict = curvefit(energies, meas, 1/meas_err^2, be_thick, be_thick_sig, chisq=chisq, /double, /noderiv, itmax=100, status=status, funct='xrs_surf_response')
; predict = curvefit(energies, meas, 1/meas_err^2, thicks, thicks_sig, chisq=chisq, /double, /noderiv, itmax=100, status=status, funct='xrs_surf_response')
  if (status ne 0) then begin
    read, prompt="ERROR: fit failed at thickness " + strtrim(be_thick,2) + "!  Try different initial thickness? [enter new value, or 0 to ignore] : ", xxx
    if (xxx eq 0) then status = 0 else be_thick = xxx
  endif
endwhile
print, 'Initial fit: ' + strtrim(be_thick,2)+' +/- '+strtrim(be_thick_sig,2) + ' microns'
; Plot the predictions vs. energy for comparison
plot, /nodata, energies, meas, xtitle='Beam Energy [MeV]', ytitle='Signal [fA/mA]', title='Filter Cal: XRS-'+ch+' (FM'+strtrim(fm,2)+')', /ylog, /xs, /ys, xr = plotrange(energies), yr = plotrange([(meas-meas_err) > 1e-1,meas+meas_err], /log); 10^(alog10([min(meas-meas_err),max(meas+meas_err)])+[-1,1]*0.025*(alog10(max(meas+meas_err))-alog10(min(meas-meas_err))))
oplot, energies, predict, color=cc[1]
oplot, energies, meas, psym=4, symsize=2
errplot, energies, meas-meas_err, meas+meas_err, width=1e-20
xyouts, 0.5, 0.875, /norm, align=1., 'SINGLE FIT: '+string(be_thick, format='(F6.2)')+' +/- '+string(be_thick_sig, format='(F6.2)') + ' [microns]'

; Run Monte Carlo around best fit +/- 10% to determine spread of results ("flatness" of chi^2 space around best fit)
common rseed, seed
ntrials = 100
mc_bethick = fltarr(ntrials)
print, 'Beginning Monte Carlo trials...'
s=systime(1)
failct = 0
for k=0, ntrials-1 do begin
  be_temp = be_thick * (randomn(seed, /uni)*0.2 + 0.9)
  xxx = curvefit(energies, meas, 1/meas_err^2, be_temp, be_temp_sig, chisq=chisq, /double, /noderiv, itmax=100, status=status, funct='xrs_surf_response')
  mc_bethick[k] = be_temp
  if (status gt 0) then begin
    failct += 1
    if (failct ge ntrials*10) then begin
      print, "ERROR: too many MC fit failures!  Completed "+strtrim(k,2)+" successful runs."
      break
    endif
    k -= 1
  endif else begin
    oplot, energies, xxx, color=cc[4]
    if (((k+1) mod (ntrials/10)) eq 0) then print, 'Completed: ' + strtrim(k+1,2) + '/' + strtrim(ntrials,2)
  endelse
endfor
print, "MC TIME ELAPSED: "+strtrim(systime(1)-s,2) + " sec"

; Replot the original data OVER the fits
oplot, energies, meas, psym=-4, symsize=2
errplot, energies, meas-meas_err, meas+meas_err, width=1e-20

print, ' '
print, 'SINGLE FIT: Be_thick [micron] = '+strtrim(be_thick,2)+' +/- '+strtrim(be_thick_sig,2)
if keyword_set(thick0) then print, '('+strtrim(be_thick/thick0,2)+' times nominal thickness of '+strtrim(thick0,2)+' microns)'
print, 'MC AVERAGE: Be_thick [micron] = '+strtrim(mean(mc_bethick[0:k-1]),2)+' +/- '+strtrim(stddev(mc_bethick[0:k-1]),2)
if keyword_set(thick0) then print, '('+strtrim(mean(mc_bethick[0:k-1])/thick0,2)+' times nominal thickness of '+strtrim(thick0,2)+' microns)'
;xyouts, !x.crange[1]*0.98, !y.crange[1]*0.9, al=1, 'SINGLE FIT: '+strtrim(be_thick,2)+' +/- '+strtrim(be_thick_sig,2) + ' [microns]'
xyouts, 0.5, 0.85, /norm, align=1., 'MC AVERAGE: '+string(mean(mc_bethick[0:k-1]), format='(F6.2)')+' +/- '+string(stddev(mc_bethick[0:k-1]), format='(F6.2)') + ' [microns]'

; Recalculate predictions based on mean best-fit thickness
xrs_surf_response, energies, mean(mc_bethick[0:k-1]), predict
print, 'Energy    Measure    Predict    Ratio M/P   Rel. Uncertainty  for XRS-'+ch
print, '------    -------    -------    ---------   ---------------'
for k=0,nenergies-1 do print, energies[k], meas[k], predict[k], meas[k]/predict[k], meas_err[k]/meas[k], format=format
print, ' '

; if keyword_set(debug) then stop, 'DEBUG at end of xrs_multienergy_gse...'

end
