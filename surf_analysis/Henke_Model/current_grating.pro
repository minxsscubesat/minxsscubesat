;
;	predict current for a Si photodiode after a grating
;
;	pass in wavelength (w) and sensivity (s) for diode
;		can be calibrated values or predicted values
;		(sensitivity is electrons per photon)
;
;	sigout = Solar Max signal output
;
;	TNW   10/22/03
;
;	Started with current_ref.pro BUT 
;	uses grating sensitivity and grating scattered light factor
;
;	REQUIRED INPUTS:
;		w, s  are diode sensitivity from diode.pro
;	
;	OPTIONAL INPUTS:
;		wgr, sgr  are grating efficiency ( can enter constant value to use default values )
;		scatfactor = grating scattered light factor (default 1E-6)
;		megs = 'A' or 'B'
;
;	If  wgr, sgr  nor  megs inputs are given, then use grating curve for ESP
;
;	OUTPUTS:
;		wout, sigout  are diode signals based on ref_all_wave.dat (solar cycle Min)
;
;	EXAMPLES:
;	For ESP,      current_grating, w, s, 0., 0., wout, sigout
;	For MEGS-A,   current_grating, w, s, 0., 0., wout, sigout, megs='A'
;	For MEGS-B,   current_grating, w, s, 0., 0., wout, sigout, megs='B'
;
pro current_grating, w, s, wgr, sgr, wout, sigout, scatfactor=scatfactor, $
	nolabel=nolabel, stopit=stopit, megs=megs

if n_params(0) lt 2 then begin
	print, 'Usage:  current_grating, w, s, wgr, sgr, wout, sigout, /nolabel, /stopit, '
	print, '                        scatfactor=scatfactor, megs="A" or "B" '
	diode,w,s
endif

; setup default values
if not keyword_set(scatfactor) then scatfactor = 1E-6

if keyword_set(megs) then megsch = strupcase(strmid(megs,0,1)) else megsch = '?'

if (n_params(0) lt 4) then sgr=0.0
if ((n_elements(sgr) le 1) and (sgr[0] le 0.0)) then begin
	if (megsch eq 'A') then begin
      ; MEGS-A grating (1 using JY grating efficiency)
      wgr = [ 0., 25, 35, 50, 60, 80, 110, 240, 355, 360 ]
      sgr = [ 0., 0.001, 0.015, 0.0008, 0.01, 0.1, 0.25, 0.1, 0.07, 0.07 ]	
	endif else if megsch eq 'B' then begin
      ; MEGS-B gratings (2 using JY grating efficiency)
      wgr = [ 300., 330, 350, 560, 740, 1050, 1100 ]
      sgr = [ 0.0, 0.0, 0.008*0.006, 0.095*0.093, 0.05*0.048, 0.045*0.043, 0.045*0.043 ]	
	endif else begin
      ; 2500 gr/mm transmission grating for ESP (default)
      wgr = [ 0, 500, 1000, 1500, 1800 ]
      sgr = [ 0.1, 0.09, 0.05, 0.0, 0.0 ]
    endelse
endif

common euvflux, sunflux

if n_elements(sunflux) le 1 then begin
  print, 'Reading reference solar spectra...'
  sdir = getenv( 'henke_model' )
  if (strlen(sdir) gt 1) then sdir = sdir + '/'
  temp=read_dat(sdir+'ref_all_wave.dat')
  temp[0,*] = temp[0,*] * 10.	; convert nm to Angstroms
  tfactor = 1.E-9 * 5.03556E8 * temp[0,*]
  temp[1,*] = temp[1,*] * tfactor  ; make flux 1E9 ph/s/cm^2/nm
  ; 
  ; now convert to constant grid of 1 Angstrom and up to 10000 Angstrom (Si cutoff)
  ;
  temp1 = temp[0:1,*]
  nwave = 10000L
  sunflux=fltarr(2,nwave)
  sunflux[0,*] = findgen(nwave)+1.5
  sunflux[1,*] = (interpol( temp1[1,*], temp1[0,*], sunflux[0,*] ) ) > 1E-5

  area = 0.1	;  cm^2   assumption for grating slit 1 mm x 10 mm
  bandpass = 0.1 ; nm 		remove nm^-1 part of irradiance
  sunflux[1,*] = sunflux[1,*] * bandpass * area
endif

wv = reform(sunflux[0,*])
wmax = max(w, wposmax)

sgrwv = interpol( sgr, wgr, wv )
swv = interpol( s, w, wv )
wbad = where( wv gt wmax )
if (wbad[0] ne -1) then swv[wbad] = s[wposmax[0]]	; fix long wavelength values

;
; current unit is nA  (* 1.6E-19 for e- * 1.E9 for flux * 1.E9 for nA)
;
ssavg = swv * sgrwv
cavg = sunflux[1,*] * swv * sgrwv * 1.602E-1
wvavg = sunflux[0,*]

if (megsch eq 'B') then wpass = where((wvavg lt 340.) or (wvavg gt 1050.)) $
else wpass = -1	; for ESP or MEGS-A that limits bandpass by foil filter
if (wpass[0] ne -1) then cavg[wpass] = cavg[wpass] * scatfactor

!ytitle = 'Current (nA)'
!xtitle = 'Wavelength (Angstrom)'
!grid = 0
cc = rainbow(7)

if keyword_set(nolabel) then begin
	wvavg = wvavg/10.
	!xtitle = 'Wavelength (nm)'
;	set_xy,0,100,0,0
	nolabel = 1
endif else begin
	nolabel = 0
	set_xy,0,1250,0,0
endelse

plot, wvavg, cavg

if (nolabel eq 0) then begin

; stop, 'Check out !p.multi for setting character sizes...'

csize = 1.0 - !p.multi[2] * 0.1
if csize lt 0.25 then csize = 0.5

c2 = cc[0]		; color for solar max

cnt = 0
ystep = (!y.crange[1]-!y.crange[0])/12.
ystart = !y.crange[1] - 3*ystep
x1 = 550
x2 = 800
x3 = 950
xyouts, x1, ystart, 'Wavelength',charsize=csize
xyouts, x2, ystart, 'Signal %',charsize=csize

;  scattered light part does not have transmission of grating
;  For MEGS-B, it does have transmission of first grating (assume SQRT(both gratings))
if (megsch eq 'B') then cscat = scatfactor * sunflux[1,*] * swv * sqrt(sgrwv) * 1.602E-1 $
else cscat = scatfactor * sunflux[1,*] * swv * 1.602E-1

avgtot = total(cavg + cscat)
scatpart = total(cscat) / avgtot
print, ' '
print, 'Scattered Light contribution = ', string(scatpart*100.,format='(F7.2)'), ' %'
print, ' '

do_bandpass = 1	; set to 1 if want special bandpass on plots

;
;	now estimate best bandpass on 1 nm intervals
;
limit = 1.
print, ' '
print, 'Checking for bandpass in 1 nm intervals...'
print, ' '
kstep = 10
w1=-1.
w2=1240.
print, ' '
for k=0,fix(wmax),kstep do begin
  wgd = where( (wv ge k) and (wv lt (k+kstep) ) )
  if wgd(0) ne -1 then begin
    pavg = total(cavg[wgd]) / avgtot * 100.
    if (pavg gt limit) then begin
 	  if (w1 lt 0) then w1 = float(k)
	  w2 = float(k+kstep)
    endif else if (w1 ge 0) then begin
	  print, 'Bandpass = ', w1, w2
	  if do_bandpass ne 0 then begin
	    cnt = cnt + 1
	    xyouts, x1, ystart-cnt*ystep, string(fix(w1),'(I4)')+'-'+ $
			string(fix(w2),'(I4)'),charsize=csize
	    wgd = where( (wv ge w1) and (wv lt w2 ) )
  	    pavg = total(cavg[wgd]) / avgtot * 100.
	    xyouts, x2, ystart-cnt*ystep, string( fix(pavg+0.5), '(I3)'),charsize=csize
        print, string(fix(w1),'(I4)')+'-'+string(fix(w2),'(I4)'), pavg
	  endif
	  w1 = -1.
    endif
  endif
endfor
print, ' '

if do_bandpass ne 0 then goto, skipregular

limit = 4.5
kstep = 25

for k=0,1200,kstep do begin
  wgd = where( (wv ge k) and (wv lt (k+kstep) ) )
  if wgd(0) ne -1 then begin
    pavg = total(cavg[wgd]) / avgtot * 100.
    if (plow gt limit) then begin
	  cnt = cnt + 1
	  xyouts, x1, ystart-cnt*ystep, string(k,'(I4)')+'-'+ $
			string(k+kstep,'(I4)'),charsize=csize
	  xyouts, x2, ystart-cnt*ystep, string( fix(pavg+0.5), '(I3)'),charsize=csize
    endif
  endif
endfor

skipregular:

cnt = cnt + 2
xyouts, x1-50, ystart-cnt*ystep, 'Total Current',charsize=csize
xyouts, x2, ystart-cnt*ystep, string( avgtot, '(F7.3)'),charsize=csize

print, 'Assuming 0.1 cm^2 area...'
print, 'Current (nA) for solar activity is ', avgtot
print, ' '

;
;	now calculate mean transmission for given bandpass
;
w1 = 0.0
w2 = 350.0
ans=''
redo:
if (n_params(0) lt 4) then read, 'Enter bandpass for this diode (w1, w2) {Ang} : ', w1, w2
if w2 lt w1 then begin
	temp = w1
	w1 = w2
	w2 = temp
endif

wgd2 = where( (wv ge w1) and (wv le w2) )
e_ph = 1.9861E-6 / wv
; convert Sensitivity back to Filter transmission
; and convert Current back to photons and flux in bottom to right units
tfactor = (3.63 * 1.E-9) / e_ph
;
;	take out e_ph weight factors if don't want energy unit usage
;	do integration of T * E over all wavelengths / 
;		/ integration of E ONLY over bandpass
;
avgFavg = total( cavg * tfactor * e_ph ) / $
        total( cavg[wgd2] * tfactor[wgd2] * e_ph[wgd2] )
        
avgTavg = total( cavg[wgd2] * tfactor[wgd2] * e_ph[wgd2] ) / $
	total( sunflux[1,wgd2] * e_ph[wgd2] )
		
;
;	calculate the SPECIAL factor (f) for case where ignore 0-7 nm region
;
wn07 = where( wv gt 70. )	; for all wavelengths beyond 70 Angstroms
spFavg = total( cavg[wn07] * tfactor[wn07] * e_ph[wn07] ) / $
        total( cavg[wgd2] * tfactor[wgd2] * e_ph[wgd2] )

;
;	assume 10% error
;
serr = fltarr(n_elements(w)) + 0.10

serror = interpol( serr, w, wv )
avgErr = total( serror[wgd2] * sunflux[1,wgd2] * e_ph[wgd2] ) / $
	total( sunflux[1,wgd2] * e_ph[wgd2] )

e_ph2 = 1.986e-8/w
www2 = where( (wv ge w1) and (wv le w2) )
avgT = mean( ssavg[www2] * 3.63 * 1.602E-12 / e_ph2[www2] )
avgSig = total( cavg[www2] )

print, ' '
print, 'Spectrometer Diode Signal'
print, '-------------------------'
print, 'Wavelength range = ', w1, ' - ', w2
print, 'Signal in range  = ', avgSig, ' nA'
print, 'Signal ratio     = ', (avgSig / avgTot)*100., ' %'

; print, 'T for NO solar weighting   = ', avgT
; print, 'T with solar weighting     = ', avgTavg, $
; 	' +/- ', avgErr*100.,' %'
;
; print, 'Bandpass "f"    (unitless)   = ', avgFavg        
; print, 'Bandpass <T>    (unitless)   = ', avgTavg
;         
; print, 'Special "f" (> 7nm) (unitless) = ', spFavg
print, ' '

if (n_params(0) lt 6) then begin
	read, 'Do new bandpass ? (Y/N) ', ans
	if strupcase(strmid(ans,0,1)) eq 'Y' then goto, redo
endif

endif		; for nolabel

wout = wvavg	; optional output is solar signal
sigout = cavg

if keyword_set(stopit) then stop, 'Check out wvavg and cavg ...'

return
end
