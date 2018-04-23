;
;	minxss_L1_flare.pro
;
;	This procedure will select pre-flare and flare spectra interactively using MinXSS Level 1 data.
;
;	Procedure steps are:
;		Plot MinXSS Level 1 science data for specified day,
;		Select time range to focus on and then re-plots scienc data over focus range
;		Select pre-flare and flare peak spectra time ranges
;		Plot spectra results
;
;	INPUT
;		date		Date in format of Year and Day of Year (YYYYDOY) or it can be in YYYYMMDD format too
;		/fm			Option to specify which MinXSS Flight Model (default is 1)
;		/reload		Option to reload L1, GOES XRS, and Orbit Number file
;		/eps		Option to make EPS graphics files after doing interactive plotting
;		/nolines	Option to omit emission line labels in spectral plot
;		/nogoes		Option to omit GOES XRS irradiance level in spectra plot
;		/oplot2013	Option to over plot the 2013 rocket X123 irradiance spectrum
;		/debug		Option to debug at the end
;		/nowait		Option to run with CURSOR option of /nowait
;
;	OUTPUT
;		result		Irradiance spectra for pre-flare and flare-peak
;		selections	Optional return of mouse selections or known dates for making the plots
;					selections is fltarr(6) hours with index of 0=focus_left, 1=focus_right
;					2=preflare_left, 3=preflare_right, 4=flare_left, 5=flare_right
;					Pass selections as one number if want to return the mouse selections.
;
;	FILES
;		MinXSS L1		$minxss_data/fm1/level1/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Orbit Numbers  	$TLE_dir/orbit_number/minxss_orbit_number.dat
;		Rocket X123		$minxss_data/merged/X123_rocket_irradiances.sav
;		Flare Plots		$minxss_data/flares/
;
;		NOTE that system environment must be set for $minxss_data and $TLE_dir
;
;	CODE
;		This procedure plus plot routines in
;		$minxss_dir/code/production/convenience_functions_generic/
;
;	HISTORY
;		7/30/2016  Tom Woods   Original Code based on minxss_plot_flare used for Level 0C
;
pro minxss_flare, date, result, selections, fm=fm, reload=reload, eps=eps, nolines=nolines, $
				nogoes=nogoes, nowait=nowait, oplot2013=oplot2013, debug=debug

common minxss_data1, doy1, data1, goes_doy, goes_xrsa, goes_xrsb, sunrise, sunset, base_year

;
;	check input parameters
;
if n_params() lt 1 then begin
	print, ' '
	print, 'USAGE:  minxss_L1_flare, date, result, selections, fm=fm, /reload, /eps, $'
	print, '                          /nolines, /nogoes, /nowait, /oplot2013, /debug'
	print, ' '
	date = 2016001L
	read, '>>>>> Enter Date as YYYYDOY or YYYYMMDD format ? ', date
endif
if (date gt 2030000L) then begin
	; input format is assumed to be YYYYMMDD
	year = long(date / 10000.)
	mmdd = long(date - year*10000L)
	mm = long(mmdd / 100.)
	dd = long(mmdd - mm*100L)
	doy = long( julday(mm, dd, year) - julday(1,1,year,0,0,0) + 1. )
endif else begin
	; input format is assumed to be YYYYDOY
	year = long(date / 1000.)
	doy = long(date - year*1000L)
endelse
if (year lt 2016) then year = 2016L
if (year gt 2030) then year = 2030L
year_str = strtrim(long(year),2)
if (doy lt 1) then doy=1L
if (doy gt 366) then doy=366L
doy_str = strtrim(long(doy),2)
yyyydoy_str = year_str + '/' + doy_str
if keyword_set(debug) then print, '***** Processing data for ',yyyydoy_str

;  option for Flight Model, default is 1
if not keyword_set(fm) then fm=1
fm=long(fm)
if (fm lt 1) then fm=1
if (fm gt 2) then fm=2
fm_str = strtrim(long(fm),2)

;  option for CURSOR, /nowait for some computers (e.g. Mac IDLDE)
doNOWAIT = 0
cans=' '
if keyword_set(nowait) then doNOWAIT = 1

;  option for user to pass in the previous mouse selections
if n_params() lt 3 then doSelections = 1 else doSelections = (n_elements(selections) ge 6? 0 : 1)

;
;	read the MinXSS L0C merged file, GOES XRS data, and MinXSS Orbit Number data
;	one can /reload by command or it will reload if the year changes from previous call
;
dir_fm = getenv('minxss_data')+'/fm'+fm_str+'/'
dir_merged = getenv('minxss_data')+'/merged/'
if n_elements(doy1) lt 2 then base_year = 0L
if (year ne base_year) or keyword_set(reload) then begin
  ; file1 = 'minxss1_l1_mission_length.sav'
  file1 = 'minxss'+fm_str+'_l1_mission_length.sav'
  restore, dir_fm + 'level1/' + file1   ; restores minxsslevel1 and minxsslevel1_meta
  ;
  ;	make doy1 and data1
  ;
  base_year = year
  data1 = minxsslevel1
  minxsslevel1 = 0L    ; clear memory of this variable
  doy1 = data1.time.jd - julday(1,1,base_year,0,0,0) + 1.

  ;
  ;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
  ;
  xrs_file = 'goes_1mdata_widx_'+strtrim(base_year,2)+'.sav'
  xrs_dir = dir_merged
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_doy = gps2jd(goes.time) - julday(1,1,base_year,0,0,0) + 1.  ; convert GPS to DOY fraction
  goes_xrsb = goes.long
  goes_xrsa = goes.short
  goes=0L

  ;
  ;	load orbit number data
  ;
  tle_dir = getenv('TLE_dir') + '/orbit_number/'
  orbit_num_file = 'minxss_orbit_number.dat'
  orbit_num = read_dat( tle_dir + orbit_num_file )
  ;  make DOY value
  sunrise = orbit_num[1,*] - base_year*1000.D0 + orbit_num[3,*]/(24.D0*3600.)
  sunset = orbit_num[1,*] - base_year*1000.D0 + orbit_num[4,*]/(24.D0*3600.)
endif

;
;	set some parameters / flags for the data
;
max_doy = long(max(doy1))

plotdir = getenv('minxss_data')+'/flares/'
ans = ' '

doEPS = 0   ; set to zero for first pass through for interactive plots
loopCnt = 0L

;
;	configure time in hours
;
hour1 = (doy1 - doy)*24.
goes_hour = (goes_doy - doy)*24.

;
;	prepare science data for +/- 1 day around chosen DOY in case selects outside 24-hour period
;
wsci = where( (doy1 ge (doy-1)) and (doy1 lt (doy+2)), num_sp )

if (num_sp le 1) then begin
	print, 'ERROR finding any L1 science data for DOY = ' + doy_str
	if keyword_set(debug) then stop, 'DEBUG ...'
endif

if (num_sp gt 1) then begin
	sp1day = data1[wsci].irradiance
	sphour = hour1[wsci]
	slow_count1 = data1[wsci].x123_slow_count
endif else begin
	sp1day = data1.irradiance
	sphour = hour1
	slow_count1 = data1.x123_slow_count
	num_sp = 0L
endelse

LOOP_START:

flare_name = [ 'B', 'C', 'M', 'X' ]
hour_range = [ 0, 24.]
; read, ' >>>>> Enter the Hour Range (min, max) ? ', hour_range
xrange = hour_range
xtitle='Time (Hour of ' + yyyydoy_str + ')'
yr = [1E1,1E5]
ytitle='X123 Total Signal (cts/sec)'
mtitle='MinXSS-'+fm_str

if (doSelections eq 0) then goto, FOCUS_PLOT

;
;	Plot MinXSS science data for specified day
;
plot1 = 'minxss'+fm_str+'_L1_flare_'+year_str+'-'+doy_str+'_day.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
endif
setplot
cc=rainbow(7)
cs123 = cc[3]  ; X123 slow counts color
grey = 'C0C0C0'X

plot, sphour, slow_count1, /nodata, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog

;
;	plot grey shading for eclipse period
;
wrise = where( (sunrise ge (doy-0.5)) and (sunrise le (doy+1.5)), num_sun )
for k=0L, num_sun-1 do begin
  temp = min( abs(sunrise[wrise[k]]-sunset), wmin )
  sunmax = (sunset[wmin] - doy) * 24.
  sunmin = (sunrise[wrise[k]] - doy) * 24.
  if (sunmin gt sunmax) then begin
    temp = sunmin
    sunmin = sunmax
    sunmax = temp
  endif
  if (sunmax gt xrange[1]) then sunmax = xrange[1]
  if (sunmin lt xrange[0]) then sunmin = xrange[0]
  if (sunmin lt xrange[1]) and (sunmax gt xrange[0]) then begin
	  xbox = [ sunmin, sunmax, sunmax, sunmin, sunmin ]
	  ybox = 10.^[ !y.crange[0]+0.1, !y.crange[0]+0.1, !y.crange[1]-0.1, !y.crange[1]-0.1, !y.crange[0]+0.1 ]
	  polyfill, xbox, ybox, color=grey
  endif
endfor

if (num_sp gt 1) then oplot, sphour, slow_count1, psym=4, color=cs123

wxrs = where( (goes_hour ge (xrange[0]-24)) and (goes_hour le (xrange[1]+24)), num_xrs )
xfactor = yr[0] / 1E-7
if (num_xrs gt 1) then oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

if doEPS ne 0 then send2 else read, 'Hit the Enter key to select flare or Q to quit ? ', ans

if strmid(strupcase(ans),0,1) eq 'Q' then return   ; user says No

FOCUS_PLOT:
;
;	Select time range to focus on and replot
;
if (loopCnt eq 0) then begin
  if (doSelections ne 0) then begin
	print, ' '
	print, ' ***** '
	print, ' ***** Select Left Edge for flare analysis ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xleft, y1, /nowait
	endif else cursor, xleft, y1
	wait, 0.25
	xleft = long(xleft * 10.)/10.
	print, ' '
	print, ' ***** '
	print, ' ***** Select Right Edge for flare analysis ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xright, y2, /nowait
	endif else cursor, xright, y2
	xright = long(xright * 10.)/10.
	wait, 0.25
	selections = fltarr(6)
	selections[0] = xleft
	selections[1] = xright
  endif else begin
    xleft = selections[0]
    xright = selections[1]
  endelse
endif

hour_str = strtrim(long(xleft),2) + '-' + strtrim(long(xright),2)
plot2 = 'minxss'+fm_str+'_L1_flare_'+year_str+'-'+doy_str+'_'+hour_str+'_ts.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot2
	eps2_p,plotdir+plot2
endif
setplot
cc=rainbow(7)
cs123 = cc[3]  ; X123 slow counts color
grey = 'C0C0C0'X

xrange2 = [ xleft, xright ]
plot, sphour, slow_count1, /nodata, psym=1, xr=xrange2, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog

;
;	plot grey shading for eclipse period
;
wrise = where( (sunrise ge (doy-0.5)) and (sunrise le (doy+1.5)), num_sun )
for k=0L, num_sun-1 do begin
  temp = min( abs(sunrise[wrise[k]]-sunset), wmin )
  sunmax = (sunset[wmin] - doy) * 24.
  sunmin = (sunrise[wrise[k]] - doy) * 24.
  if (sunmin gt sunmax) then begin
    temp = sunmin
    sunmin = sunmax
    sunmax = temp
  endif
  if (sunmax gt xrange2[1]) then sunmax = xrange2[1]
  if (sunmin lt xrange2[0]) then sunmin = xrange2[0]
  if (sunmin lt xrange2[1]) and (sunmax gt xrange2[0]) then begin
    xbox = [ sunmin, sunmax, sunmax, sunmin, sunmin ]
    ybox = 10.^[ !y.crange[0]+0.1, !y.crange[0]+0.1, !y.crange[1]-0.1, !y.crange[1]-0.1, !y.crange[0]+0.1 ]
    polyfill, xbox, ybox, color=grey
  endif
endfor

if (num_sp gt 1) then oplot, sphour, slow_count1, psym=4, color=cs123

wxrs = where( (goes_hour ge (hour_range[0]-24)) and (goes_hour le (hour_range[1]+24)), num_xrs )
xfactor = yr[0] / 1E-7
if (num_xrs gt 1) then oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

;
;	Select pre-flare and flare peak spectra
;
if (loopCnt eq 0) then begin
  if (doSelections ne 0) then begin
	print, ' '
	print, ' ***** '
	print, ' ***** Select Pre-flare Left Time ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xprea, y1a, /nowait
	endif else cursor, xprea, y1a
	wait, 0.25
	oplot, xprea*[1,1], 10.^!y.crange, line=1
	print, ' '
	print, ' ***** '
	print, ' ***** Select Pre-flare Right Time ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xpreb, y1b, /nowait
	endif else cursor, xpreb, y1b
	wait, 0.25
	oplot, xpreb*[1,1], 10.^!y.crange, line=1
	print, ' '
	print, ' ***** '
	print, ' ***** Select Peak Flare Left Time ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xpeaka, y2a, /nowait
	endif else cursor, xpeaka, y2a
	wait, 0.25
	oplot, xpeaka*[1,1], 10.^!y.crange, line=2
	print, ' '
	print, ' ***** '
	print, ' ***** Select Peak Flare Right Time ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xpeakb, y2b, /nowait
	endif else cursor, xpeakb, y2b
	oplot, xpeakb*[1,1], 10.^!y.crange, line=2
	wait, 0.25
	selections[2] = xprea
	selections[3] = xpreb
	selections[4] = xpeaka
	selections[5] = xpeakb
  endif else begin
    xprea = selections[2]
    xpreb = selections[3]
    xpeaka = selections[4]
    xpeakb = selections[5]
    oplot, xprea*[1,1], 10.^!y.crange, line=1
	oplot, xpreb*[1,1], 10.^!y.crange, line=1
	oplot, xpeaka*[1,1], 10.^!y.crange, line=2
	oplot, xpeakb*[1,1], 10.^!y.crange, line=2
  endelse
endif else begin
	oplot, xprea*[1,1], 10.^!y.crange, line=1
	oplot, xpreb*[1,1], 10.^!y.crange, line=1
	oplot, xpeaka*[1,1], 10.^!y.crange, line=2
	oplot, xpeakb*[1,1], 10.^!y.crange, line=2
endelse
xpre = (xprea+xpreb)/2.  ; time of center of pre-flare
xpeak = (xpeaka+xpeakb)/2.  ; time of center of peak flare

if doEPS ne 0 then send2 else read, 'Next ? ', ans

;
;	Plot results - first select and average the results within the selected time ranges
;
limit1 = 0.25   ; limit for finding first spectrum
limit2 = 0.083  ; limit for finding adjacent spectrum for including
wpre = where( (sphour ge xprea) and (sphour le xpreb), num_pre )
if (num_pre lt 1) then begin
	print, 'ERROR finding pre-flare spectrum'
	if keyword_set(debug) then stop, 'DEBUG...'
endif
wpeak = where( (sphour ge xpeaka) and (sphour le xpeakb), num_peak )
if (num_peak lt 1) then begin
	print, 'ERROR finding peak flare spectrum'
	if keyword_set(debug) then stop, 'DEBUG...'
endif

;
;	make pre-flare and peak flare spectra
;
if (num_pre ge 1) then begin
  sp_pre = reform(sp1day[*,wpre[0]])
  count1=1.
  for k=1L,num_pre-1 do begin
    sp_pre += reform(sp1day[*,wpre[k]])
    count1 += 1.
  endfor
  sp_pre /= count1
endif

if (num_peak ge 1) then begin
  sp_peak = reform(sp1day[*,wpeak[0]])
  count1=1.
  for k=1L,num_peak-1 do begin
    sp_peak += reform(sp1day[*,wpeak[k]])
    count1 += 1.
  endfor
  sp_peak /= count1
endif

; define energy scale
esp = data1[wpre[0]].energy

; check if there are no spectra to plot
if (num_pre lt 1) and (num_peak lt 1) then goto, LOOP_END
if (num_pre lt 1) then sp_pre = sp_peak * 0.
if (num_peak lt 1) then sp_peak = sp_pre * 0.

;
;	save energy, pre-flare spectrum, and peak-flare spectrum into result
;
result = transpose([ [esp], [sp_pre], [sp_peak] ])

wxrs2 = where( (goes_hour ge xrange2[0]) and (goes_hour le xrange2[1]), num_xrs2 )
flare_str = '? class'
if (num_xrs2 gt 1) then begin
  	ftemp = max(goes_xrsb[wxrs2])
  	flare_str = 'A'
  	if (ftemp gt 9.95E-4) then begin
  	  flare_str = 'X' + string(long(ftemp/1E-4),format='(I2)')
  	endif else if (ftemp gt 9.95E-5) then begin
  	  flare_str = 'X' + string(ftemp/1E-4,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-6) then begin
  	  flare_str = 'M' + string(ftemp/1E-5,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-7) then begin
  	  flare_str = 'C' + string(ftemp/1E-6,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-8) then begin
  	  flare_str = 'B' + string(ftemp/1E-7,format='(F3.1)')
  	endif
   	flare_str += ' flare'
endif
mtitle2 = 'MinXSS-'+fm_str+' for ' + flare_str

;
;   ****************************************************************
;	Plot results
;   ****************************************************************
;
  plot3 = 'minxss'+fm_str+'_L1_flare_'+year_str+'-'+doy_str+'_'+hour_str+'_sp.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot3
	eps2_p,plotdir+plot3
  endif
  setplot
  cc = rainbow(7)

  erange = [0.5, 10.]
  yrange4 = [1E2,3E8]
  ytitle4 = 'Irradiance (photons/sec/cm!U2!N/keV)'

  plot, result[0,*], result[1,*], psym=10, /nodata, xr=erange, xs=1, /xlog, /ylog, $
	yr=yrange4, ys=1, xtitle='Energy (keV)', ytitle=ytitle4, title=mtitle2
  oplot, result[0,*], result[1,*], psym=10, color=cc[3]
  oplot, result[0,*], result[2,*], psym=10

  xx = 5. & yy = 1E6 & my=5.
  xyouts, xx, yy, 'Pre-Flare', color=cc[3]
  xyouts, xx, yy*my, 'Flare'

  if keyword_set(oplot2013) then begin
  	restore, dir_merged + 'X123_rocket_irradiances.sav'
  	oplot, energies2013_mean, spec2013_lower, psym=10, color=cc[0]
  	xyouts, xx, yy*my^2, 'Rkt-2013', color=cc[0]
  endif

  if not keyword_set(nolines) then begin
    ; other bright lines are  Fe XXIII @ 1.056 keV; Fe XXII @ 1.054; Fe XXI @ 1.010; Fe XVII @ 0.826
    lineName=['Si XIII', 'Si XIV', 'Si XIII', 'Si XIV', 'Si XV', $
    	'Si XVI', 'Si XV', 'Ar XVIII', 'Ca XIX', 'Ca XX', 'Ca XIX', 'Fe XXV']
    lineKeV = [1.85, 2.00, 2.17, 2.37, 2.46, $
    	2.62, 2.88, 3.32, 3.86, 4.105, 4.583, 6.69 ]
    lineY = [ 15., 15, 10, 10, 3, 3, 3, 3, 3, 0.6, 0.6, 0.2]
    yrange2 = [1E-3,1E2]
    lineY *= (yrange4[0]/yrange2[0])
    ii2kev = 60L
    f2 = result[2,ii2kev]
    if (f2 gt lineY[0]) then lineY *= (f2/lineY[0])*1.2
    cs = 1.5
    nlines = n_elements(lineName)
    for ii=0,nlines-1 do xyouts, lineKeV[ii], lineY[ii], lineName[ii], orient=90, charsize=cs
  endif

  if not keyword_set(nogoes) then begin
    ;
    ;	include comparison of GOES XRS broadband irradiance to X123 integrated irradiance
    ;		NOAA recommends XRS-B / 0.70 and  XRS-A / 0.85 for "true" irradiance level
    ;
    gcs = 1.5
    hc = 6.626D-34 * 2.998D8
  	EFang = 12.398
  	aband = EFang / [ 0.5, 4 ]	; convert Angstrom to keV for XRS bands
  	awidth = aband[0] - aband[1]
  	acenter = (aband[0]+aband[1])/2.
  	actr_weighted = 4.13   ; 1/E^5 irradiance weighting means low energy more important
  	bband = EFang / [ 1, 8 ]
  	bwidth = bband[0] - bband[1]
  	bcenter = (bband[0]+bband[1])/2.
  	bctr_weighted = 2.06  ; 1/E^5 irradiance weighting means low energy more important
  	;
  	;  get X123 integrated irradiance in units of W/m^2 for direct comparison to GOES
  	;
	x123_band = result[0,20] - result[0,19]  ; ~ 0.03 keV/bin
	wgxa = where( (result[0,*] ge aband[1]) and (result[0,*] lt aband[0]) )
	aphoton2energy = (hc*result[0,wgxa]) * 1.D4 / (1.D-10*EFang)
	x123_a1 = total(result[1,wgxa]*x123_band*aphoton2energy)
	x123_a2 = total(result[2,wgxa]*x123_band*aphoton2energy)
	wgxb = where( (result[0,*] ge bband[1]) and (result[0,*] lt bband[0]) )
	bphoton2energy = (hc*result[0,wgxb]) * 1.D4 / (1.D-10*EFang)
	x123_b1 = total(result[1,wgxb]*x123_band*bphoton2energy)
	x123_b2 = total(result[2,wgxb]*x123_band*bphoton2energy)
	;  get GOES XRS data for flare data time
	temp1 = min( abs(goes_hour - xpre), wg1 )
	temp2 = min( abs(goes_hour - xpeak), wg2 )
	acal = 1. / 0.85	; XRS-A / 0.85 for "true" irradiance level
	xrs_a1 = goes_xrsa[wg1] * acal
	xrs_a2 = goes_xrsa[wg2] * acal
	bcal = 1. / 0.70   ; XRS-B / 0.70  for "true" irradiance level
	xrs_b1 = goes_xrsb[wg1] * bcal
	xrs_b2 = goes_xrsb[wg2] * bcal
	;  display results in legend in plot
	xleg = 0.55
	yleg = 1.E3
	my = 2.2
	xyouts, xleg, yleg, 'X123 W/m!U2!N  GOES_XRS-B  X123/GOES', charsize=gcs, color=cc[5]
	ratio_b1 = x123_b1/xrs_b1
	ratio_b2 = x123_b2/xrs_b2
	xyouts, xleg, yleg/my, string(x123_b2,format='(E9.2)') + string(xrs_b2,format='(E13.2)')+$
			string(ratio_b2,format='(F12.3)'), charsize=gcs
	xyouts, xleg, yleg/my^2., string(x123_b1,format='(E9.2)') + string(xrs_b1,format='(E13.2)')+$
			string(ratio_b1,format='(F12.3)'), charsize=gcs, color=cc[3]
	;
	;  graphically show the broad bands for GOES bands
	;
	; oplot, aband, (total(result[1,wgxa])*x123_band/awidth)*[1,1], thick=2, color=cc[3]
	; oplot, aband, (total(result[2,wgxa])*x123_band/awidth)*[1,1], thick=2
	x123_b1_ph = (total(result[1,wgxb])*x123_band/bwidth)
	x123_b2_ph = (total(result[2,wgxb])*x123_band/bwidth)
	bxxx = bband[1] / 1.05
	xyouts, bxxx, x123_b1_ph, 'X123-B', align=1.0, color=cc[3], charsize=gcs
	xyouts, bxxx, x123_b2_ph, 'X123-B', align=1.0, charsize=gcs
	oplot, bband, x123_b1_ph*[1,1], thick=2, color=cc[3]
	oplot, bband, x123_b2_ph*[1,1], thick=2

	; convert GOES W/m^2 into photons/sec/cm^2/keV using W/m^2 ratios above
	; oplot, aband, (x123_a1_ph/ratio_a1)*[1,1], line=3, thick=2, color=cc[3]
	; oplot, aband, (x123_a2_ph/ratio_a2)*[1,1], line=3, thick=2
	bxx = bband[1] / 1.35
	goes_b1 = x123_b1_ph / ratio_b1
	goes_b2 = x123_b2_ph / ratio_b2
	;xyouts, bxx, goes_b1, 'GOES', align=1.0, color=cc[3], charsize=gcs
	;xyouts, bxx, goes_b2, 'GOES', align=1.0, charsize=gcs
	;oplot, bband, goes_b1*[1,1], line=2, thick=3, color=cc[3]
	;oplot, bband, goes_b2*[1,1], line=2, thick=3
  endif

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

;  END OF LOOP
LOOP_END:
loopcnt += 1
if (loopcnt eq 1) and keyword_set(eps) then begin
	; make EPS files now
	print, ' '
	print, 'MAKING EPS FILES ...'
   doEPS = 1
   goto, LOOP_START
endif

if keyword_set(debug) then stop, 'DEBUG at end of minxss_L1_flare ...'

end
