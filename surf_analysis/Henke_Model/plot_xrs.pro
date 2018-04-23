;
;	plot_xrs
;
;	Plot XRS sensitivity but in A/W instead of electrons/photon
;
;	INPUT:  wv = Angstrom
;			sens = electrons / photon
;			type = 'A' or 'B' or 'C'
;
;			/log = option to plot on log scale
;			/ratio = option to plot sensitivity to PORD as ratio
;			/level = option to plot horizontal line at "level" (default 0.15) to determine GOES band
;			/spec = option to print where sensitivity is out of spec
;			/scale = option to multiple the optimal scale factor for the PORD sensitivity curve
;
;	For wv, sens:  can restore wv, xa, xb, xc  from "xrs_abc_sens.sav"
;
;
pro plot_xrs, wv, sens, type, log=log, ratio=ratio, level=level, spec=spec, scale=scale

if n_params() lt 3 then begin
   print, 'USAGE:  plot_xrs, wavelength_Angstrom, sens_electrons_per_photon, type'
   print, '                  where type = "A" or "B" or "C"'
   print, ' '
   return
endif

;
;  get GOES-R SIS PORD wavelength response for XRS
;		Keep in a common block
;
common xrs_ref_common, as, bs
if n_elements(as) lt 2 then begin
  as = read_dat( 'xrs_a_pord_response.dat' )
  bs = read_dat( 'xrs_b_pord_response.dat' )
endif

;
; convert wavelength to nm
; convert sensitivity to A/W
;
wvnm = wv / 10.					
saw = sens * 1.602D-19 / (6.624D-34*2.998D8 / (wvnm * 1.D-9))

xtype = strmid(strupcase(type),0,1)
if (xtype eq 'A') then begin
  mtitle='XRS-A with Si Diode'
  xs = as
endif else if (xtype eq 'B') then begin
  mtitle='XRS-B with Si Diode'
  xs = bs
endif else begin
  mtitle='XRS-C with Si Diode'
  xs = bs
endelse

if keyword_set(log) then begin
  xr = [0.04, 1.5]
  yr = [1E-3,1]
endif else begin
  xr = [0,1.5]
  yr = [0,0.3]
endelse
if (xtype eq 'C') then xr[1] = 2.

setplot
cc=rainbow(7)

;
;	determine best ratio between "saw" and PORD value xs[1,*]
;
;  OLD normalization was:  f = max(saw)
;
;  NEW normalization is ratio of saw / xs but weighted by sqrt(magnitude)
;
wgd = where( (xs[1,*] gt 0) and (xs[0,*] gt 0.1) )
fall = interpol( saw, wvnm, reform(xs[0,wgd]) ) / reform(xs[1,wgd])
fweight = sqrt(reform(xs[1,wgd]))
f = total(fall * fweight) / total(fweight)
if keyword_set(scale) then f = f * scale

printbad = 1		; set non-zero to print bad points in ratio
if (printbad ne 0) then print, 'Scale factor for Sensitivity = ', f

if keyword_set(ratio) then begin
    xratio = interpol(saw,wvnm,xs[0,*]) / (xs[1,*] * f)
    yr = [0, 2]
    plot, xs[0,*], xratio, xr=xr, xs=1, yr=yr, ys=1, $
	  xtitle='Wavelength (nm)', ytitle='Sensitivity Ratio to PORD', title=mtitle  
	oplot,!x.crange,[1,1],line=2
	sratiohigh = xs[2,*]/xs[1,*]
	sratiolow = xs[3,*]/xs[1,*]
	oplot, xs[0,*], sratiohigh, color=cc[1]
	oplot, xs[0,*], sratiolow, color=cc[1]
	;  highlight ones outside limit
	wbad1 = where( (xratio - sratiohigh) gt 0, nbad1 )
	if (nbad1 eq 1) then oplot, xs[0,wbad1[0]]*[1,1], xratio[wbad1[0]]*[1,1], color=cc[0], psym=6 $
	else if (nbad1 gt 1) then oplot, xs[0,wbad1], xratio[wbad1], color=cc[0], psym=6
	wbad2 = where( (xratio - sratiolow) lt 0, nbad2 )
	if (nbad2 eq 1) then oplot, xs[0,wbad2[0]]*[1,1], xratio[wbad2[0]]*[1,1], color=cc[0], psym=6 $
	else if (nbad2 gt 1) then oplot, xs[0,wbad2], xratio[wbad2], color=cc[0], psym=6
	if (printbad ne 0) then begin
	  if (nbad1 ge 1) then begin
	    print, 'Bad High Points'
	    for k=0,nbad1-1 do print, xs[0,wbad1[k]], xratio[wbad1[k]]*xs[1,wbad1[k]]
	  endif
	  if (nbad2 ge 1) then begin
	    print, 'Bad Low Points'
	    for k=0,nbad2-1 do print, xs[0,wbad2[k]], xratio[wbad2[k]]*xs[1,wbad2[k]]
	  endif
	endif
endif else begin
  if keyword_set(log) then begin
    plot_oo, wvnm, saw, xr=xr, xs=1, yr=yr, ys=1, $
    	xticklen=1.0, xgrid=2, yticklen=1.0, ygrid=2, $
	  xtitle='Wavelength (nm)', ytitle='Sensitivity (A/W)', title=mtitle
  endif else begin
    plot, wvnm, saw, xr=xr, xs=1, yr=yr, ys=1, $
	  xtitle='Wavelength (nm)', ytitle='Sensitivity (A/W)', title=mtitle
  endelse
  
  oplot, wvnm, saw, thick=5, color=cc[3]

  oplot, xs[0,*], xs[1,*]*f, color=cc[5], psym=-4
  oplot, xs[0,*], xs[2,*]*f, color=cc[4]
  oplot, xs[0,*], xs[3,*]*f, color=cc[4]
  
  if keyword_set(level) then begin
    yy = level
    if (yy lt 0.01) then yy = 0.15	; default value
    if (yy ge 1.0) then yy = 0.15	; default value
    oplot, !x.crange, yy*f*[1,1], line=2
  endif
endelse

if keyword_set(spec) then begin
	print, ' '
	print, mtitle
	;  SPEC can be value to include margin:  e.g.,  SPEC = 1.1 means 10% margin (factor x 1.1 better than spec)
	margin = spec
	if (margin lt 1) then margin = 1.
	if (margin gt 1.2) then margin = 1.2
	if (margin ne 1.0) then print, 'MARGIN = ', strtrim(margin,2)
	;  this uses the "f" derived for scaling xs[1,*] to saw
	snew = interpol( saw, wvnm, reform(xs[0,*]) ) / f
	kend = n_elements(xs[0,*])
	;  print results plus identify which ones are out of spec
	badcnt = 0L
	print, ' Wave (nm) PORD_MID  PORD_HI   PORD_LOW  SENS_NORMALIZE'
	for k=0,kend-1 do begin
	  if (snew[k] gt (xs[2,k]/margin)) or (snew[k] lt (xs[3,k]*margin)) then begin
		print, xs[0:3,k], snew[k], " ***** ", format='(F9.3,4F10.6,A10)'
		if (badcnt eq 0) then wbad = k else wbad = [wbad, k]
		badcnt = badcnt + 1
	  endif else begin
		print, xs[0:3,k], snew[k], format='(F9.3,4F10.6)'
	  endelse
	endfor
	if (badcnt gt 0) then begin
	  print, 'Number of wavelengths out of spec = ', strtrim(badcnt,2)
	  if (badcnt eq 1) then wbad=[wbad,wbad]
	  oplot, xs[0,wbad], snew[wbad]*f, psym=6, color=cc[0]
	endif
endif

return
end
