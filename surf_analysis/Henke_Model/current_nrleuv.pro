;
;	predict current for a diode
;
;	pass in wavelength (w) and sensivity (s) for diode
;		can be calibrated values or predicted values
;		(sensitivity is electrons per photon)
;
;	sigout = Solar Max signal output
;
;	TNW   9/6/93
;
;	added serr input for sensitivity error (in percentage)
;
;	same as current.pro BUT uses NRLEUV Flare Spectra 
;	instead of EUV81 results
;
pro current_nrleuv, w, s, serr, wout, sigout, nolabel=nolabel, stopit=stopit

if n_params(0) lt 2 then begin
	print, 'Usage:  current_nrleuv, w, s, [/nolabel]'
	diode,w,s
endif

common euvflux3, sunlow, sunhigh

if n_elements(sunlow) le 1 then begin
  print, 'Reading NRLEUV solar spectra...'
  sdir = getenv( 'henke_model' )
  if (strlen(sdir) gt 1) then sdir = sdir + '/'
  temp=read_dat(sdir+'NRLEUV_sp.dat')    ;  or  'nrleuv_bastille_flare.dat'
  tfactor = 1.E-9 * 5.03556E11 * temp[0,*]
  temp[0,*] = temp[0,*] * 10 	; wavelength in Angstroms
  temp[1,*] = temp[1,*] * tfactor   ; make flux 1E9 ph/s/cm^2
  temp[2,*] = temp[2,*] * tfactor  ; make flux 1E9 ph/s/cm^2
  sunlow = temp[0:1,*]		; solar min.
  sunhigh = temp[0:1,*]		; solar max
  sunhigh[1,*] = temp[2,*]
  ; stop, 'Check out sunlow, sunhigh ...'
    ; limit the solar spectrum to 1230 Angstrom because of HENKE constants
  wgd = where( sunlow[0,*] lt 1230. )
  sunlow = sunlow[*,wgd]
  sunhigh = sunhigh[*,wgd]
endif

wv = sunlow(0,*)
;
; current unit is nA  (* 1.6E-19 for e- * 1.E9 for flux * 1.E9 for nA)
;
sslow = interpol( s, w, sunlow(0,*) ) > 0.0
clow = sunlow(1,*) * sslow * 1.602E-1

sshigh = interpol( s, w, sunhigh(0,*) ) > 0.0
chigh = sunhigh(1,*) * sshigh * 1.602E-1

wupper = max(w)
if wupper gt 2000 then wupper = 2000
gd = where( sunlow(0,*) lt wupper )

!ytitle = 'Current (nA)'
!xtitle = 'Wavelength (Angstrom)'

!grid = 0

wvhigh = sunhigh(0,*)
wvlow = sunlow(0,*)

if keyword_set(nolabel) then begin
	wvhigh = wvhigh/10.
	wvlow = wvlow/10.
	!xtitle = 'Wavelength (nm)'
;	set_xy,0,100,0,0
	nolabel = 1
endif else begin
	nolabel = 0
	set_xy,0,1250,0,0
endelse

plot, wvhigh, chigh

if (nolabel eq 0) then begin

; stop, 'Check out !p.multi for setting character sizes...'

csize = 1.0 - !p.multi[2] * 0.1
if csize lt 0.25 then csize = 0.5
cc = rainbow(7)
c2 = cc[0]		; color for solar max

oplot, wvlow, clow, color=c2

cnt = 0
ystep = (!y.crange[1]-!y.crange[0])/12.
ystart = !y.crange[1] - 3*ystep
x1 = 550
x2 = 800
x3 = 950
xyouts, x1, ystart, 'Wavelength',charsize=csize
xyouts, x2, ystart+ystep, 'Solar',charsize=csize
xyouts, x2, ystart, 'Min %',charsize=csize
xyouts, x3, ystart+ystep, 'Solar',charsize=csize
xyouts, x3, ystart, 'Max %',charsize=csize
hightot = total(chigh(gd))
lowtot = total(clow(gd))

do_bandpass = 1	; set to 1 if want special bandpass on plots

;
;	now estimate best bandpass on 1 nm intervals
;
limit = 1.
print, ' '
print, 'Checking for bandpass in 0.5 nm intervals...'
print, ' '
kstep = 10
w1=-1.
w2=1240.
print, ' '
for k=0,fix(wupper),kstep do begin
  wgd = where( (wv ge k) and (wv lt (k+kstep) ) )
  if wgd(0) ne -1 then begin
    plow = total(clow(wgd)) / lowtot * 100.
    phigh = total(chigh(wgd)) / hightot * 100.
    if (plow gt limit) or (phigh gt limit) then begin
	if (w1 lt 0) then w1 = float(k)
	w2 = float(k+kstep)
    endif else if (w1 ge 0) then begin
	print, 'Bandpass = ', w1, w2
	if do_bandpass ne 0 then begin
	  cnt = cnt + 1
	  xyouts, x1, ystart-cnt*ystep, string(fix(w1),'(I4)')+'-'+ $
			string(fix(w2),'(I4)'),charsize=csize
	  wgd = where( (wv ge w1) and (wv lt w2 ) )
  	  plow = total(clow(wgd)) / lowtot * 100.
    	  phigh = total(chigh(wgd)) / hightot * 100.
	  xyouts, x2, ystart-cnt*ystep, string( fix(plow+0.5), '(I3)'),charsize=csize
	  xyouts, x3, ystart-cnt*ystep, string( fix(phigh+0.5), '(I3)'),charsize=csize
          print, string(fix(w1),'(I4)')+'-'+string(fix(w2),'(I4)'), plow, phigh
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
    plow = total(clow(wgd)) / lowtot * 100.
    phigh = total(chigh(wgd)) / hightot * 100.
    if (plow gt limit) or (phigh gt limit) then begin
	cnt = cnt + 1
	xyouts, x1, ystart-cnt*ystep, string(k,'(I4)')+'-'+ $
			string(k+kstep,'(I4)'),charsize=csize
	xyouts, x2, ystart-cnt*ystep, string( fix(plow+0.5), '(I3)'),charsize=csize
	xyouts, x3, ystart-cnt*ystep, string( fix(phigh+0.5), '(I3)'),charsize=csize
    endif
  endif
endfor

skipregular:

cnt = cnt + 2
xyouts, x1-50, ystart-cnt*ystep, 'Total Current',charsize=csize
xyouts, x2, ystart-cnt*ystep, string( lowtot, '(F7.3)'),charsize=csize
xyouts, x3, ystart-cnt*ystep, string( hightot, '(F7.3)') + ' nA',charsize=csize

print, 'Assuming 1 cm^2 area...'
print, 'Current (nA) low solar activity is ', lowtot
print, 'Current (nA) high solar activity is ', hightot
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
avgFlow = total( clow * tfactor * e_ph ) / $
        total( clow(wgd2) * tfactor(wgd2) * e_ph(wgd2) )
avgFhigh = total( chigh * tfactor * e_ph ) / $
        total( chigh(wgd2) * tfactor(wgd2) * e_ph(wgd2) )
avgTlow = total( clow(wgd2) * tfactor(wgd2) * e_ph(wgd2) ) / $
	total( sunlow(1,wgd2) * e_ph(wgd2) )
avgThigh = total( chigh(wgd2) * tfactor(wgd2) * e_ph(wgd2) ) / $
	total( sunhigh(1,wgd2) * e_ph(wgd2) )

;
;	calculate the SPECIAL factor (f) for case where ignore 0-7 nm region
;
wn07 = where( wv gt 70. )	; for all wavelengths beyond 70 Angstroms
spFlow = total( clow[wn07] * tfactor[wn07] * e_ph[wn07] ) / $
        total( clow(wgd2) * tfactor(wgd2) * e_ph(wgd2) )
spFhigh = total( chigh[wn07] * tfactor[wn07] * e_ph[wn07] ) / $
        total( chigh(wgd2) * tfactor(wgd2) * e_ph(wgd2) ) 

;
;	assume 10% error if not given
;
if (n_params(0) lt 3) then serr = fltarr(n_elements(w)) + 0.10

serror = interpol( serr, w, wv )
avgErrlow = total( serror(wgd2) * sunlow(1,wgd2) * e_ph(wgd2) ) / $
	total( sunlow(1,wgd2) * e_ph(wgd2) )
avgErrhigh = total( serror(wgd2) * sunhigh(1,wgd2) * e_ph(wgd2) ) / $
	total( sunhigh(1,wgd2) * e_ph(wgd2) )


e_ph2 = 1.986e-8/w
www2 = where( (w ge w1) and (w le w2) )
avgT = mean( s(www2) * 3.63 * 1.602E-12 / e_ph2(www2) )

print, ' '
print, 'Avg. Filter Transmission'
print, '------------------------'
print, 'Wavelength range = ', w1, ' - ', w2
print, 'T for NO solar weighting     = ', avgT
print, 'T at low  solar activity level = ', avgTlow, $
	' +/- ', avgErrlow*100.,' %'
print, 'T at high solar activity level = ', avgThigh, $
	' +/- ', avgErrhigh*100.,' %'
;print, 'Difference of <T>   (%)      = ', $
;	abs(avgThigh-avgTlow)*200./(avgThigh+avgTlow)
print, 'Bandpass "f"    (unitless)   = ', (avgFlow + avgFhigh)/2.
print, 'Error for "f"   (%)          = ', $
        abs(avgFhigh-avgFlow)*100./(avgFhigh+avgFlow)
print, 'Bandpass <T>    (unitless)   = ', (avgTlow + avgThigh)/2.
print, 'Error for <T>   (%)          = ', $
        abs(avgThigh-avgTlow)*100./(avgThigh+avgTlow)
print, ' '
print, 'Special "f" (> 7nm) (unitless) = ', (spFlow + spFhigh)/2.
print, 'Error for Special "f"   (%)    = ', $
        abs(spFhigh-spFlow)*100./(spFhigh+spFlow)
print, ' '
; stop, 'Check clow and chigh...'
print, 'sp f = ', spFlow, spFhigh

if (n_params(0) lt 4) then begin
	read, 'Do new bandpass ? (Y/N) ', ans
	if strupcase(strmid(ans,0,1)) eq 'Y' then goto, redo
endif

endif		; for nolabel

wout = wvhigh	; optional output is Solar Max result
sigout = chigh

if keyword_set(stopit) then stop, 'Check out clow and chigh ...'

return
end
