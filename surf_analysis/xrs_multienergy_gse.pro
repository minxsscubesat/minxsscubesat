;+
; NAME:
;	xrs_multienergy_gse
;
; PURPOSE:
;	Process multi-energy SURF data to get scaling factors for Henke model
;	Updated for ETU-XRS that uses ASIC GSE
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	xrs_multienergy, channel [ , itime=itime, /debug, data=data]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;
; OUTPUTS:  
;	PLOT		Showing fit of Henke model to SURF measurements at multi-energy
;
;	data		Scale Factors for each beam energy
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
;	1/27/10		Tom Woods	Original file creation
;	9/22/10		Tom Woods	Updated for ETU-XRS
;+

pro xrs_multienergy_gse, channel, itime=itime, debug=debug, data=data
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_multienergy_gse, channel [ , itime=itime, /debug, data=data ]'
  return
endif

ch = strmid(strupcase(channel),0,2)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
  print, 'ERROR xrs_multienergy_gse: Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return
endif

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

;
;	Define Directories
;		basedir = Path for Multi-Energy files
;		chdir = basedir + Channel Name
;		fluxdir = Path for where SURF Flux and Henke Model files are located
;
basedir = '/Users/ajones/Desktop/SURF/SURF_XRS/rocketXRSdec10/MultiEnergy/'
chdir = basedir + ch + '/'
fluxdir = '/Users/ajones/Desktop/SURF/SURF_XRS/idl/'

;
;	Read the SURF Flux and Henke Model files (static)
;
surfflux = read_dat( fluxdir + 'SURF_FLUX_GOES.dat' )
fluxenergy = [ 229, 285, 331, 361, 380, 408 ]
nflux = n_elements(fluxenergy)

;	ETU_XRS_HENKE_Ver1:  50 microns Si + 70 Ang SiO: A1 Be 500 microns, A2 Be 530 microns, B1 Be 60 microns, B2 Be 30 microns
; henke = read_dat( fluxdir + 'ETU_XRS_HENKE_Ver1.dat' )
;	ETU_XRS_HENKE_Ver2:  50 microns Si + 70 Ang SiO: A1 Be 490 microns, A2 Be 520 microns, B1 Be 52 microns, B2 Be 27 microns
; henke = read_dat( fluxdir + 'ETU_XRS_HENKE_Ver2.dat' )
;	ETU_XRS_HENKE_Ver3:  50 microns Si + 70 Ang SiO: A1 Be 470 microns, A2 Be 490 microns, B1 Be 53 microns, B2 Be 28 microns
;				Tune A1/A2 for 0.55 nm in Henke and Tune B1/B2 for 0.95 nm in Henke
; henke = read_dat( fluxdir + 'ETU_XRS_HENKE_Ver3.dat' )
;	ETU_XRS_HENKE_Ver4:  50 microns Si + 70 Ang SiO: A1 Be 468.5 microns, A2 Be 488 microns, B1 Be 53.3 microns, B2 Be 27.6 microns
henke = read_dat( fluxdir + 'ETU_XRS_HENKE_Ver4.dat' )

;
;	Define files depending on Channel
;
case ch of
    'A1': begin
		energy = [ 331, 380, 408 ]
		nenergy = n_elements(energy)
		datafile = '22-Sep-2010112423_asic_time_xrsa.txt'
		surffile = 'surflog_09-22-10_1124'
		ihenke = 1
       end
    'A2': begin
		energy = [ 380, 408 ]
		nenergy = n_elements(energy)
		datafile = '22-Sep-2010124230_asic_time_xrsb.txt'
		surffile = 'surflog_09-22-10_1240'
		ihenke = 2
       end
    'B1': begin
		energy = [ 285, 331, 380, 408 ]
		nenergy = n_elements(energy)
		datafile = '22-Sep-2010100851_asic_time_xrsb.txt'
		surffile = 'surflog_09-22-10_1010'
		ihenke = 3
       end
    'B2': begin
		energy = [ 285, 331, 380, 408 ]
		nenergy = n_elements(energy)
		datafile = '22-Sep-2010083227_asic_time_xrsa.txt'
		surffile = 'surflog_09-22-10_0832'
		ihenke = 4
      end
endcase

;
;	2.	Read/Plot the data using plot_xrs_gse.pro
;
dfile = chdir + datafile
sfile = chdir + surffile
if keyword_set(debug) then begin
    plot_xrs_gse, ch, dfile, sfile, itime=integtime, data=dall, /debug
endif else begin
    plot_xrs_gse, ch, dfile, sfile, itime=integtime, data=dall
endelse

;
; FOR LOOP:
;	3.  Calculate the Henke model scale factors for each beam energy
;				(in fA units)
;			Predicted_Current = integral_all_wavelengths( Flux * Area * Responsivity ) * 1E9 * qe
;			Measured_Current = Gain * Count_per_sec / BC  (returned from plotxrs.pro in fA)
;
qe = 1.602D-19
factor = qe * 1D15	; convert electrons to fC
ans=' '
ans2=' '
meas = fltarr(nenergy)
predict = fltarr(nenergy)

setplot
cc=rainbow(7)

; Time Base
tbase = long(dall[0].time/1000.) * 1000L

if keyword_set(debug) then begin
  ;  do plot of signal versus time and overplot beam energy values too
  plot, dall.time-tbase, dall.signal, yr=[10.,10.E6], ys=1, /ylog, $
       xtitle='Time (sec)', ytitle='Signal (fA/mA)', title='XRS-'+ch+', Energy in RED'
  oplot, dall.time-tbase, dall.surfenergy, color=cc[0]
  ; read, 'Hit RETURN key to continue: ', ans
endif

print, ' '
print, 'Energy    Measure    Predict    Ratio M/P'
print, '------    -------    -------    ---------'
format = '(I5,2E12.3,F8.3)'

for k=0, nenergy-1 do begin
  ; select the data for the right beam energy and beam size (< 0.3 mm)
  wgd = where( (dall.surfenergy gt (energy[k]-5)) and (dall.surfenergy lt (energy[k]+5)) and (dall.surfsize lt 0.35), numgd )
  if (numgd lt 10) then begin
    wgd = where( (dall.surfenergy gt (energy[k]-5)) and (dall.surfenergy lt (energy[k]+5)), numgd )
    if (numgd lt 10) then begin 
      stop, 'STOP: error in not finding data for specific beam energy !'
    endif else begin
      print, 'WARNING: No Fuzz condition not found for Energy = ', strtrim(energy[k],2), ' MeV !'
    endelse
  endif
  d = dall[wgd]
  ;  exclude end points as usually corrupted with change in beam energy
  numbad = 60
  if (numgd gt (3*numbad)) then d = d[numbad:n_elements(d)-numbad]
  
  ;  select the high data as right data for comparison
  dlimit = max(d.signal)*0.80
  whi = where( d.signal gt dlimit, numhi )
  plot, dall.time-tbase, dall.signal, yr=[10.,10.E6], ys=1, /ylog, $
         xtitle='Time (sec)', ytitle='Signal (fA/mA)', title='XRS-'+ch+', E='+strtrim(energy[k],2)+'MeV'
  oplot, dall.time-tbase, dall.surfenergy, color=cc[0]
  ;plot, d.time-tbase, d.signal, xtitle='Time (sec)', ytitle='Signal (fA/mA)', $
  ;		title='XRS-'+ch+' E='+strtrim(energy[k],2)
  if (numhi gt 2) then begin
    meas[k] = median(d[whi].signal)
    oplot, !x.crange, dlimit*[1,1], line=2
    ;oplot, !x.crange, meas[k]*[1,1], color=cc[3]
    oplot, d[whi].time-tbase, d[whi].signal, color=cc[3]
  endif else begin
    print, 'WARNING: using maximum signal'
    meas[k] = max(d.signal)
  endelse
  
  ; let user select the time frame for the data
  if keyword_set(debug) then begin
    read, 'Select time range for this energy (Y or N) ? ', ans
    ans = strupcase(strmid(ans,0,1))
    if (ans eq 'Y') then begin
      read, 'Move cursor to LEFT side of good data and hit RETURN key...', ans2
      cursor,t1,y1,/nowait
      read, 'Move cursor to RIGHT side of good data and hit RETURN key...', ans2
      cursor,t2,y2,/nowait
      wgd2 = where( (dall.time ge (t1+tbase)) and (dall.time le (t2+tbase)), numgd2 )
      if (numgd2 gt 2) then begin
        meas[k] = median(dall[wgd2].signal)
        oplot, !x.crange, meas[k]*[1,1], color=cc[5]
      endif else begin
        print, 'ERROR selecting valid time range !'
      endelse
    endif
  endif

  ; get the area in mm^2
  area = xrs_area( ch ) * 100.	; convert cm^2 to mm^2
  
  ; get the SURF flux
  wvmin = max( [min(surfflux[0,*]),min(henke[0,*])] )
  wvmax = min( [max(surfflux[0,*]),max(henke[0,*])] )
  wgs = where( (surfflux[0,*] ge wvmin) and (surfflux[0,*] le wvmax) )
  wave = reform(surfflux[0,wgs])
  mine = min(abs(fluxenergy-energy[k]),isurf) ; determine which SURF flux to use
  if (mine ne 0.0) then print, 'WARNING: Using ', strtrim(fluxenergy[isurf],2), ' instead of ', strtrim(energy[k],2), ' MeV'
  isurf = isurf + 1
  sflux = reform(surfflux[isurf,wgs])

  ; get bandpass (wavelength step)
  nsurf = n_elements(surfflux[0,*])
  bandwave = reform(abs(shift(surfflux[0,*],1) - shift(surfflux[0,*],-1))/2.)
  bandwave[0] = bandwave[1]
  bandwave[nsurf-1] = bandwave[nsurf-2]
  dwave = bandwave[wgs]
  
  ; get the response interpolated to SURF flux wavelengths
  cresponse = interpol( henke[ihenke,*], henke[0,*], wave )
  
  ; calculate the predicted current
  predict[k] = total( sflux * cresponse * dwave ) * area * factor
  
  ;print, 'Energy  Measure  Predict  Ratio M/P'
  print, energy[k], meas[k], predict[k], meas[k]/predict[k], format=format
  read, 'Next Energy ? ', ans
endfor

print, ' '
print, 'Energy    Measure    Predict    Ratio M/P  for XRS-'+ch
print, '------    -------    -------    ---------'
for k=0,nenergy-1 do print, energy[k], meas[k], predict[k], meas[k]/predict[k], format=format
print, ' '

data = dall

; if keyword_set(debug) then stop, 'DEBUG at end of xrs_multienergy_gse...'

end
