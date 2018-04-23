;+
; NAME:
;	xrs_multienergy
;
; PURPOSE:
;	Process multi-energy SURF data to get scaling factors for Henke model
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
;	2.	Read/Plot the data (several files) using plotxrs.pro
;	3.  Calculate the Henke model scale factors for each beam energy
;
; MODIFICATION HISTORY:
;	1/27/10		Tom Woods	Original file creation
;  12/02/10    Andrew Jones Setup for Dec2010 rXRS cal
;+

pro xrs_multienergy, channel, itime=itime, debug=debug, data=data
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_multienergy, channel [ , itime=itime, /debug, data=data ]'
  return
endif

ch = strmid(strupcase(channel),0,2)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
  print, 'ERROR xrs_multienergy: Invalid Channel name.  Expected A1, A2, B1, or B2.'
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

;	RXRS_HENKE:  50 micron Si: A1 Be 60 microns, A2 Be 494 microns, B1 Al/C 250/100 nm, B2 Be 8 microns
;	RXRS_HENKE_v2:  5 microns Si: 10% less of Be and Al
;	RXRS_HENKE_v3:  50 microns Si: 10% less of Be and Al
;	RXRS_HENKE_v4:  50 microns Si: A1 Be 48 microns, A2 Be 470 microns, B1 A/C 250/110 nm, B2 Be 6.0 microns
	; A1 ratio of 1.097, A2 is GOOD, B1 needs less C, B2 is GOOD
;	RXRS_HENKE_v5:  50 microns Si: A1 Be 46 microns, A2 Be 470 microns, B1 A/C 250/90 nm, B2 Be 6.0 microns
	; A1 ratio of 0.987, A2 is GOOD, B1 needs less Si, B2 is GOOD
;	RXRS_HENKE_v6:  50 microns Si: A1 Be 46.3 microns, A2 Be 470 microns, B1 A/C 250/90 nm & 45 micron Si, B2 Be 6.0 microns
	; A1 is GOOD, A2 is GOOD, B1 needs more Al, B2 is GOOD
;	RXRS_HENKE_v7:  50 microns Si: A1 Be 46.3 microns, A2 Be 470 microns, B1 A/C 260/90 nm, B2 Be 6.0 microns
	; A1 is GOOD, A2 is GOOD, B1 needs even more Al and less C, B2 is GOOD
;	RXRS_HENKE_v8:  50 microns Si: A1 Be 46.3 microns, A2 Be 470 microns, B1 A/C 300/80 nm, B2 Be 6.0 microns
	; A1 is GOOD, A2 is GOOD, B1 needs abit more Al and abit less C, B2 is GOOD
;	RXRS_HENKE_v9:  50 microns Si: A1 Be 46.3 microns, A2 Be 470 microns, B1 A/C 320/70 nm, B2 Be 6.0 microns
;	RXRS_HENKE_v10:  50 microns Si + 70 Ang SiO: A1 Be 468.5 microns, A2 Be 488 microns, B1 Be 53.3 microns, B2 Be 27.6 microns
henke = read_dat( fluxdir + 'RXRS_HENKE_v10.dat' )

;
;	Define files depending on Channel
;
case ch of
    'A1': begin
		energy = [ 331, 361, 380, 408 ]
		nenergy = n_elements(energy)
		dvfiles = [ 'XRS Raw Dump_12_01_10_16-41']
		surffiles = [ 'surflog_12-01-10_1641' ]
		ihenke = 1
       end
    'A2': begin
		energy = [ 285, 331, 361, 380, 408 ]
		nenergy = n_elements(energy)
		dvfiles = [ 'XRS Raw Dump_12_01_10_15-18' ]
		surffiles = [ 'surflog_12-01-10_1518' ]
		ihenke = 2
       end
    'B1': begin
		energy = [ 285, 331, 361, 380, 408 ]
		nenergy = n_elements(energy)
		dvfiles = [ 'XRS Raw Dump_12_01_10_12-31' ]
		surffiles = [ 'surflog_12-01-10_1231' ]
		ihenke = 3
       end
    'B2': begin
		energy = [ 285, 331, 361, 380, 408 ]
		nenergy = n_elements(energy)
		dvfiles = [ 'XRS Raw Dump_12_01_10_13-50' ]
		surffiles = [ 'surflog_12-01-10_1350' ]
		ihenke = 4
      end
endcase

;
; FOR LOOP:
;	2.	Read/Plot the data using plotxrs.pro
;	3.  Calculate the Henke model scale factors for each beam energy
;				(in fA units)
;			Predicted_Current = integral_all_wavelengths( Flux * Area * Responsivity ) * 1E9 * qe
;			Measured_Current = Gain * Count_per_sec / BC  (returned from plotxrs.pro in fA)
;
qe = 1.602D-19
factor = qe * 1D15	; convert electrons to fC
ans=' '
meas = fltarr(nenergy)
predict = fltarr(nenergy)
print, ' '
print, 'Energy    Measure    Predict    Ratio M/P'
print, '------    -------    -------    ---------'
format = '(I5,2E12.3,F8.3)'

setplot
cc=rainbow(7)

for k=0, nenergy-1 do begin

  ; read the files
  dfile = chdir + dvfiles[k]
  sfile = chdir + surffiles[k]
  if keyword_set(debug) then begin
    plotxrs, ch, dfile, sfile, itime=integtime, data=d, /debug
  endif else begin
    plotxrs, ch, dfile, sfile, itime=integtime, data=d
  endelse

  ;  select the high data as right data for comparison
  dlimit = max(d.signal)*0.90
  whi = where( d.signal gt dlimit, numhi )
  tbase = long(d[0].time/1000.) * 1000L
  plot, d.time-tbase, d.signal, xtitle='Time', ytitle='Signal (fA/mA)', $
  		title='XRS-'+ch+' E='+strtrim(energy[k],2)
  if (numhi gt 2) then begin
    meas[k] = median(d[whi].signal)
    oplot, !x.crange, dlimit*[1,1], line=2
    oplot, !x.crange, meas[k]*[1,1], color=cc[3]
  endif else begin
    print, 'WARNING: using maximum signal'
    meas[k] = max(d.signal)
  endelse
  
  ; let user select the time frame for the data ???

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

if keyword_set(debug) then stop, 'DEBUG at end of xrs_multienergy...'

end
