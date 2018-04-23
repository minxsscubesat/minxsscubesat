;
;	minxss_plot_flare.pro
;
;	Plot MinXSS science data for specified day,
;	Select time range to focus on,
;	Select pre-flare and flare peak spectra
;	Plot results (count spectra)
;	Convert pre-flare and flare-peak spectra to Irradiance spectra (using C. Moore's code)
;
;	INPUT
;		doy			Day of Year
;		/year		Option to specify year besides 2016
;		/reload		Option to reload L0C, GOES XRS, and Orbit Number file
;		/eps		Option to make EPS graphics files after doing interactive plotting
;		/nolines	Option to omit emission line labels in spectral plot
;		/nogoes		Option to omit GOES XRS-A and B irradiance level in spectra plot
;		/raw_counts	Option to return raw counts spectra instead of irradiance spectra
;		/oplot2013	Option to over plot the 2013 rocket X123 irradiance spectrum
;		/debug		Option to debug at the end
;		/nowait		Option to run with CURSOR option of /nowait
;		/lowlimit	Option to specify the low energy limit (default=2.0)
;
;	OUTPUT
;		result		Irradiance spectra for pre-flare and flare-peak (or raw counts for /raw_counts)
;
;	FILES
;		MinXSS L0C		$minxss_data/merged/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Orbit Numbers  	$TLE_dir/orbit_number/minxss_orbit_number.dat
;		Rocket X123		$minxss_data/merged/X123_rocket_irradiances.sav
;		FM1 X123 Calibration	$minxss_data/calibration/minxss_fm1_response_structure.sav
;		Flare Plots		$minxss_data/flares/
;
;	CODE
;		This procedure plus Chris Moore X123 irradiance library and Tom's wrapper procedure in
;		$minxss_dir/code/L1_moore/ and also time conversion and plot routines in
;		$minxss_dir/code/production/convenience_functions_generic/
;
;	HISTORY
;		6/20/16  Tom Woods
;
pro minxss_plot_flare, doy, result, reload=reload, year=year, eps=eps, nolines=nolines, $
				raw_counts=raw_counts, oplot2013=oplot2013, nogoes=nogoes, debug=debug, $
				lowlimit=lowlimit, nowait=nowait

common minxss_data0c, hkdoy, hk, scidoy, sci, log, goes_doy, goes_xrsa, goes_xrsb, sunrise, sunset, base_year

;  option for CURSOR, /nowait for some computers (e.g. Mac IDLDE)
doNOWAIT = 0
cans=' '
if keyword_set(nowait) then doNOWAIT = 1

lowLimitDefault = 2.0		; median is 1.0 for bins 20-24
lowLimitDefault = 7.0		; needs to be higher for larger flares
if not keyword_set(lowlimit) then lowlimit = lowLimitDefault

;
;	read the MinXSS L0C merged file, GOES XRS data, and MinXSS Orbit Number data
;
dir_merged = getenv('minxss_data')+'/merged/'
if n_elements(hkdoy) lt 2 or keyword_set(reload) then begin
  ; file0c = 'minxss1_l0c_hk_mission_length.sav'
  ;  "all" file has all packet types for the MinXSS-1 mission (as of 6/10/2016)
  file0c = 'minxss1_l0c_all_mission_length.sav'
  restore, dir_merged + file0c		; hk
  ;
  ;	make hkdoy, datestr, and find indices for wel, wsun, wx123
  ;	also make scidoy
  ;
  if keyword_set(year) then base_year = year else base_year = 2016L
  if (base_year lt 2016) then base_year = 2016L
  hkdoy = jd2yd(gps2jd(hk.time)) - base_year*1000.D0
  scidoy = jd2yd(gps2jd(sci.time)) - base_year*1000.D0

  ;
  ;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
  ;
  xrs_file = 'goes_1mdata_widx_'+strtrim(base_year,2)+'.sav'
  xrs_dir = dir_merged
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_doy = jd2yd(gps2jd(goes.time)) - base_year*1000.D0  ; convert GPS to DOY fraction
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
endif else begin
  if keyword_set(year) then begin
    if (year ne base_year) then begin
    	hkdoy += (base_year - year) * 1000.D0
    	scidoy += (base_year - year) * 1000.D0
    	goes_doy += (base_year - year) * 1000.D0
    	sunrise += (base_year - year) * 1000.D0
    	sunset += (base_year - year) * 1000.D0
    	base_year = year
    endif
  endif
endelse

if n_params() lt 1 then begin
	doy = 0L
	print, 'Base Year = ', strtrim(long(base_year),2)
	read, '>>>>> Enter DOY ? ', doy
endif
if (doy lt 1) then doy=1L
if (doy gt 366) then doy=366L
doy_str = strtrim(long(doy),2)

;
;	set some parameters / flags for the data
;
max_doy = long(max(hkdoy))
datestr = '2016_'+ string(max_doy,format='(I03)')
wel = where( hk.eclipse_state ne 0 )
wsun = where( hk.eclipse_state eq 0 )
;  BUG in L0B processing for enable flags !!!
;wx123 = where( hk.enable_x123 ne 0, num_x123 )
wx123 = where( hk.x123_det_temp gt 0, num_x123 )
wx123_el = where( hk.x123_det_temp gt 0 and hk.eclipse_state ne 0, num_x123_el )
wx123_sun = where( hk.x123_det_temp gt 0 and hk.eclipse_state eq 0, num_x123_sun )

plotdir = getenv('minxss_data')+'/flares/'
ans = ' '

doEPS = 0   ; set to zero for first pass through for interactive plots
loopCnt = 0L

;
;	configure time in hours
;
hkhour = (hkdoy - doy)*24.
scihour = (scidoy - doy)*24.
goes_hour = (goes_doy - doy)*24.

;
;	prepare science data
;
sp = float(sci.x123_spectrum)
num_sci = n_elements(sci)
; convert to counts per sec (cps) with smallest time
for ii=0,num_sci-1 do sp[*,ii] = sp[*,ii] / (sci[ii].x123_live_time/1000.)

fast_count = sci.x123_fast_count / (sci.x123_accum_time/1000.)
fast_limit = 1.E5
slow_count = sci.x123_slow_count / (sci.x123_live_time/1000.)

sps_sum = total(sci.sps_data[0:3],1) / float(sci.sps_xps_count)
sps_sum_sun_min = 280000.   ; June 2016 it is 310K; this  allows for 1-AU changes and 5% degradation

; exclude spectra with radio on (flag > 1), not in sun, and high low counts
lowcnts = total( sp[20:24,*], 1 )
wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scidoy ge (doy-1)) and (scidoy lt (doy+2)) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp )

wdark = where( (sci.x123_radio_flag lt 2) and (sps_sum lt (sps_sum_sun_min/10.)) $
		and (scidoy ge (doy-1)) and (scidoy lt (doy+2)) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_dark )

if (num_sp le 1) then begin
	print, 'ERROR finding any SCI packets for DOY = ' + doy_str
	if keyword_set(debug) then stop, 'DEBUG ...'
endif

if (num_sp gt 1) then begin
	sp1day = sp[*,wsci]
	sphour = scihour[wsci]
	fast_count1 = fast_count[wsci]
	slow_count1 = slow_count[wsci]
	num_sp1 = n_elements(sphour)
endif else begin
	sp1day = sp
	sphour = scihour
	fast_count1 = fast_count
	slow_count1 = slow_count
	num_sp1 = 0L
endelse

LOOP_START:

;
;	Plot MinXSS science data for specified day
;
plot1 = 'minxss_flare_'+doy_str+'_day.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
endif
setplot
cc=rainbow(7)
cs123 = cc[3]  ; X123 slow counts color
grey = 'C0C0C0'X

xtitle='Time (Hour of ' + strtrim(long(base_year),2) + '/' + doy_str + ')'
hour_range = [ 0, 24.]
; read, ' >>>>> Enter the Hour Range (min, max) ? ', hour_range
xrange = hour_range

yr = [1E1,1E5]
ytitle='X123 Total Signal (cts/sec)'
mtitle='MinXSS-1'

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

if (num_sp1 gt 1) then oplot, sphour, slow_count1, psym=4, color=cs123

wxrs = where( (goes_hour ge (xrange[0]-24)) and (goes_hour le (xrange[1]+24)), num_xrs )
xfactor = yr[0] / 1E-7
if (num_xrs gt 1) then oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
flare_name = [ 'B', 'C', 'M', 'X' ]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

if doEPS ne 0 then send2 else read, 'Enter key to select flare or Q to quit ? ', ans

if strmid(strupcase(ans),0,1) eq 'Q' then return   ; user says No

;
;	Select time range to focus on and replot
;
if (loopCnt eq 0) then begin
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
endif

hour_str = strtrim(long(xleft),2) + '-' + strtrim(long(xright),2)
plot2 = 'minxss_flare_'+doy_str+'_'+hour_str+'_ts.eps'
if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot2
	eps2_p,plotdir+plot2
endif
setplot
cc=rainbow(7)
cs123 = cc[3]  ; X123 slow counts color

xrange2 = [ xleft, xright ]
plot, sphour, slow_count1, /nodata, psym=1, xr=xrange2, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog

;
;	plot grey shading for eclipse period
;
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

if (num_sp1 gt 1) then oplot, sphour, slow_count1, psym=4, color=cs123

if (num_xrs gt 1) then oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

;
;	Select pre-flare and flare peak spectra
;
if (loopCnt eq 0) then begin
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
;	Plot results (count spectra first, then irradiance plot)
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
;	make pre-flare and peak flare spectra (average 3 spectra)
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
esp = findgen(1024) * 0.02930 - 0.13  ; ??? energy scale ???
;  smooth > 3 keV by 3 bins
whi = where(esp gt 3.0, numhi)
if (numhi gt 3) then begin
	if (num_pre ge 1) then begin
		sp_pre_smooth = smooth(sp_pre,3)
		sp_pre[whi] = sp_pre_smooth[whi]
	endif
	if (num_peak ge 1) then begin
		sp_peak_smooth = smooth(sp_peak,3)
		sp_peak[whi] = sp_peak_smooth[whi]
	endif
endif


; check if there are no spectra to plot
if (num_pre lt 1) and (num_peak lt 1) then goto, LOOP_END
if (num_pre lt 1) then sp_pre = sp_peak * 0.
if (num_peak lt 1) then sp_peak = sp_pre * 0.

;   ****************************************************************
;	Plot results (count spectra first)
;   ****************************************************************
;
  plot3 = 'minxss_flare_'+doy_str+'_'+hour_str+'_cts_sp.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot3
	eps2_p,plotdir+plot3
  endif
  setplot
  cc = rainbow(7)

  erange = [0.5, 10.]
  yrange2 = [1E-3,1E2]

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
  ytitle2 = 'X123 Signal (cts/sec)'
  mtitle2 = 'MinXSS-1 for ' + flare_str

  plot, esp, sp_pre, psym=10, /nodata, xr=erange, xs=1, yr=yrange2, ys=1, /xlog, /ylog, $
	xtitle='Energy (keV)', ytitle=ytitle2, title=mtitle2
  if (num_pre ge 1) then oplot, esp, sp_pre, psym=10, color=cc[3]
  if (num_peak ge 1) then oplot, esp, sp_peak, psym=10

  xx = 5. & yy = 5E0 & my=3.
  xyouts, xx, yy, 'Pre-Flare', color=cc[3]
  xyouts, xx, yy*my, 'Flare'

  if not keyword_set(nolines) then begin
    ; other bright lines are  Fe XXIII @ 1.056 keV; Fe XXII @ 1.054; Fe XXI @ 1.010; Fe XVII @ 0.826
    lineName=['Si XIII', 'Si XIV', 'Si XIII', 'Si XIV', 'Si XV', $
    	'Si XVI', 'Si XV', 'Ar XVIII', 'Ca XIX', 'Ca XX', 'Ca XIX', 'Fe XXV']
    lineKeV = [1.85, 2.00, 2.17, 2.37, 2.46, $
    	2.62, 2.88, 3.32, 3.86, 4.105, 4.583, 6.69 ]
    lineY = [ 15., 15, 10, 10, 3, 3, 3, 3, 3, 0.6, 0.6, 0.2]
    ii2kev = 60L
    f2 = sp_peak[ii2kev]
    if (f2 gt lineY[0]) then lineY *= 3.
    cs = 1.5
    nlines = n_elements(lineName)
    for ii=0,nlines-1 do xyouts, lineKeV[ii], lineY[ii], lineName[ii], orient=90, charsize=cs
  endif

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

if (loopcnt eq 0) then begin
  ;
  ;  SAVE results as irradiance spectra
  ;
  if keyword_set(raw_counts) then begin
	result = transpose([ [esp], [sp_pre], [sp_peak] ])
  endif else begin
	;
	;	now convert the results to irradiance units
	;
	x123_irradiance_wrapper, sp_pre, irr_pre, result=result1, fm=1, debug=debug
	x123_irradiance_wrapper, sp_peak, irr_peak, result=result2, fm=1, debug=debug

	result= [ result1, result2 ]
  endelse
endif

;   ****************************************************************
;	Plot results (irradiance spectra second)
;   ****************************************************************
;
if not keyword_set(raw_counts) then begin
  plot4 = 'minxss_flare_'+doy_str+'_'+hour_str+'_irr_sp.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot4
	eps2_p,plotdir+plot4
  endif
  setplot
  cc = rainbow(7)

  erange = [0.5, 10.]
  yrange4 = [1E2,3E8]
  ytitle4 = 'Irradiance (photons/sec/cm!U2!N/keV)'

  plot, result[0].energy_bins, result[0].irradiance, psym=10, /nodata, xr=erange, xs=1, /xlog, /ylog, $
	yr=yrange4, ys=1, xtitle='Energy (keV)', ytitle=ytitle4, title=mtitle2
  oplot, result[0].energy_bins, result[0].irradiance, psym=10, color=cc[3]
  oplot, result[1].energy_bins, result[1].irradiance, psym=10

  xx = 5. & yy = 1E6 & my=5.
  xyouts, xx, yy, 'Pre-Flare', color=cc[3]
  xyouts, xx, yy*my, 'Flare'

  if keyword_set(oplot2013) then begin
  	restore, dir_merged + 'X123_rocket_irradiances.sav'
  	oplot, energies2013_mean, spec2013_lower, psym=10, color=cc[0]
  	xyouts, xx, yy*my^2, 'Rkt-2013', color=cc[0]
  endif

  if not keyword_set(nolines) then begin
    lineY *= (yrange4[0]/yrange2[0])
    ii2kev = 60L
    f2 = result[1].irradiance[ii2kev]
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
	x123_band = result[0].energy_bins[20] - result[0].energy_bins[19]  ; ~ 0.03 keV/bin
	wgxa = where( (result[0].energy_bins ge aband[1]) and (result[0].energy_bins lt aband[0]) )
	aphoton2energy = (hc*result[0].energy_bins[wgxa]) * 1.D4 / (1.D-10*EFang)
	x123_a1 = total(result[0].irradiance[wgxa]*x123_band*aphoton2energy)
	x123_a2 = total(result[1].irradiance[wgxa]*x123_band*aphoton2energy)
	wgxb = where( (result[0].energy_bins ge bband[1]) and (result[0].energy_bins lt bband[0]) )
	bphoton2energy = (hc*result[0].energy_bins[wgxb]) * 1.D4 / (1.D-10*EFang)
	x123_b1 = total(result[0].irradiance[wgxb]*x123_band*bphoton2energy)
	x123_b2 = total(result[1].irradiance[wgxb]*x123_band*bphoton2energy)
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
	; oplot, aband, (total(result[0].irradiance[wgxa])*x123_band/awidth)*[1,1], thick=2, color=cc[3]
	; oplot, aband, (total(result[1].irradiance[wgxa])*x123_band/awidth)*[1,1], thick=2
	x123_b1_ph = (total(result[0].irradiance[wgxb])*x123_band/bwidth)
	x123_b2_ph = (total(result[1].irradiance[wgxb])*x123_band/bwidth)
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
endif

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

if keyword_set(debug) then stop, 'DEBUG at end of minxss_plot_flare ...'

end
