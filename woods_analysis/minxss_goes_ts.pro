;
;	minxss_goes_ts.pro
;
;	This procedure will compare MinXSS L1 spectral irradiance integrated over GOES-B band
;	to GOES XRS-B irradiance as time series (ts).
;
;	INPUT
;		date		Date in format of Year and Day of Year (YYYYDOY) or it can be in YYYYMMDD format too
;		date_end	Optional date for end of time series (if not provided, then just one day)
;		/fm			Option to specify which MinXSS Flight Model (default is 1)
;		/reload		Option to reload L1, GOES XRS, and Orbit Number file
;		/eps		Option to make EPS graphics files after doing interactive plotting
;		/goes_no_cal  Option to not make correction for GOES calibration
;		/debug		Option to debug at the end
;		/xrs_a		Option to do analysis for XRS-A instead of XRS-B
;
;	OUTPUT
;		result		Array of time, MinXSS_integrated_XRS-B, GOES_XRS-B, ratio_X123_to_GOES
;
;	FILES
;		MinXSS L1		$minxss_data/fm1/level1/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Flare Plots		$minxss_data/trends/goes
;
;		NOTE that system environment must be set for $minxss_data
;
;	CODE
;		This procedure plus plot routines in
;		$minxss_dir/code/production/convenience_functions_generic/
;
;	HISTORY
;		8/30/2016  Tom Woods   Original Code based on minxss_flare used for Level 1 flares
;
pro minxss_goes_ts, date, date_end, result=result, fm=fm, reload=reload, eps=eps, $
					goes_no_cal=goes_no_cal, xrs_a=xrs_a, debug=debug

common minxss_data1_ts, doy1, data1, x123_xrsa, x123_xrsb, goes_doy, goes_xrsa_save, goes_xrsb_save, base_year

;
;	check input parameters
;
if n_params() lt 1 then begin
	print, ' '
	print, 'USAGE:  minxss_goes_ts, date, date_end, result=result, fm=fm, /reload, /xrs_a, /eps, /debug'
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

; default year2, doy2 values for a single DOY
year2 = year
doy2 = doy + 1
doy2_str = strtrim(long(doy2),2)
doDays = 0
numDays = 1

if n_params() ge 2 then begin
  doDays = 1
  numDays = yd2jd(date_end) - yd2jd(date)
  if (date_end gt 2030000L) then begin
	; input format is assumed to be YYYYMMDD
	year2 = long(date_end / 10000.)
	mmdd = long(date_end - year*10000L)
	mm = long(mmdd / 100.)
	dd = long(mmdd - mm*100L)
	doy2 = long( julday(mm, dd, year) - julday(1,1,year2,0,0,0) + 1. )
  endif else begin
	; input format is assumed to be YYYYDOY
	year2 = long(date_end / 1000.)
	doy2 = long(date_end - year*1000L)
  endelse
  if (year2 lt 2016) then year2 = 2016L
  if (year2 gt 2030) then year2 = 2030L
  year2_str = strtrim(long(year2),2)
  if (doy2 lt 1) then doy2=1L
  if (doy2 gt 366) then doy2=366L
  if (doy2 le doy) and (year2 eq year) then doy2 = doy + 2
  doy2_str = strtrim(long(doy2),2)
  yyyydoy2_str = year2_str + '/' + doy2_str
  yyyydoy_str += ' to ' + yyyydoy2_str
endif

if keyword_set(debug) then print, '***** Processing data for ',yyyydoy_str

;  option for Flight Model, default is 1
if not keyword_set(fm) then fm=1
fm=long(fm)
if (fm lt 1) then fm=1
if (fm gt 2) then fm=2
fm_str = strtrim(long(fm),2)

;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

;
;	read the MinXSS L0C merged file, GOES XRS data, and MinXSS Orbit Number data
;	one can /reload by command or it will reload if the year changes from previous call
;
dir_fm = getenv('minxss_data')+slash+'fm'+fm_str+slash
dir_merged = getenv('minxss_data')+slash+'merged'+slash
if n_elements(doy1) lt 2 then base_year = 0L
if (year ne base_year) or keyword_set(reload) then begin
  print, 'Reading and processing MinXSS Level 1 and GOES data...'
  ; file1 = 'minxss1_l1_mission_length.sav'
  file1 = 'minxss'+fm_str+'_l1_mission_length.sav'
  restore, dir_fm + 'level1' + slash + file1   ; restores minxsslevel1 and minxsslevel1_meta
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
  xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_doy = gps2jd(goes.time) - julday(1,1,base_year,0,0,0) + 1.  ; convert GPS to DOY fraction
  goes_xrsb_save = goes.long
  goes_xrsa_save = goes.short
  goes=0L

  ;
  ;		calculate GOES XRS-B equivalent band using X123 spectra
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

  esp = data1[0].energy
  x123_band = esp[20] - esp[19]  ; ~ 0.03 keV/bin
  wgxa = where( (esp ge aband[1]) and (esp lt aband[0]) )
  aphoton2energy = (hc*esp[wgxa]) * 1.D4 / (1.D-10*EFang)
  wgxb = where( (esp ge bband[1]) and (esp lt bband[0]) )
  bphoton2energy = (hc*esp[wgxb]) * 1.D4 / (1.D-10*EFang)

  num_x123 = n_elements(data1)
  x123_xrsa = fltarr(num_x123)
  x123_xrsb = fltarr(num_x123)


  ;
  ;  get X123 integrated irradiance in units of W/m^2 for direct comparison to GOES
  ;
  for k=0L, num_x123-1 do begin
	x123_xrsa[k] = total(data1[k].irradiance[wgxa]*x123_band*aphoton2energy)
	x123_xrsb[k] = total(data1[k].irradiance[wgxb]*x123_band*bphoton2energy)
  endfor
endif

;  NOAA calibration for GOES XRS A & B
acal = 1. / 0.85	; XRS-A / 0.85 for "true" irradiance level
bcal = 1. / 0.70   ; XRS-B / 0.70  for "true" irradiance level
if not keyword_set(goes_no_cal) then begin
  ; apply "calibration" to GOES XRS (just done once)
  goes_xrsa = goes_xrsa_save * acal
  goes_xrsb = goes_xrsb_save * bcal
endif else begin
  goes_xrsa = goes_xrsa_save
  goes_xrsb = goes_xrsb_save
endelse

;
;	set some parameters / flags for the data
;
max_doy = long(max(doy1))

plotdir = getenv('minxss_data')+slash+'trends'+slash+'goes'+slash
ans = ' '

doEPS = 0   ; set to zero for first pass through for interactive plots
loopCnt = 0L

;
;	configure time in hours or in days
;
if (doDays ne 0) then begin
	; time1 is in units of DOY for multiple days (assumes same year)
	time1 = doy1
	goes_time = goes_doy
	xtitle='Time (' + year_str + ' DOY)'
	xrange=[doy,doy2]
endif else begin
	; time1 is in units of hours for a single DOY
	time1 = (doy1 - doy)*24.
	goes_time = (goes_doy - doy)*24.
	xtitle='Time (Hour of ' + yyyydoy_str + ')'
	xrange = [0,24]
endelse

;
;	prepare science data for day around chosen DOY in case selects outside 24-hour period
;
wsci = where( (doy1 ge doy) and (doy1 lt doy2), num_sp )

if (num_sp le 1) then begin
	print, 'ERROR finding any L1 science data for DOY = ' + doy_str
	if keyword_set(debug) then stop, 'DEBUG ...'
endif

;  limit data for returning "result"
sptime = time1[wsci]
slow_count1 = data1[wsci].x123_slow_count
goes_xrsb_cmp = interpol( goes_xrsb, goes_time, sptime )
goes_xrsa_cmp = interpol( goes_xrsa, goes_time, sptime )

; make X123 version of XRS-B by integrating over GOES XRS-B band width
x123_xrsb_cmp = x123_xrsb[wsci]
x123_xrsa_cmp = x123_xrsa[wsci]

; save "result"
result = dblarr(4,num_sp)
result[0,*] = sptime
result[1,*] = x123_xrsb_cmp
result[2,*] = goes_xrsb_cmp
result[3,*] = x123_xrsb_cmp / goes_xrsb_cmp
ytitle='X123 XRS-B Band'
fgoes_name = 'goes'
goes_name = 'GOES XRS-B'
x123_goes_name = 'X123 XRS-B Band'
theCal = bcal

if keyword_set(xrs_a) then begin
  result[1,*] = x123_xrsa_cmp
  result[2,*] = goes_xrsa_cmp
  result[3,*] = x123_xrsa_cmp / goes_xrsa_cmp
  ytitle='X123 XRS-A Band'
  fgoes_name = 'goes_a'
  goes_name = 'GOES XRS-A'
  x123_goes_name = 'X123 XRS-A Band'
  theCal = acal
endif

LOOP_START:

flare_name = [ 'A', 'B', 'C', 'M', 'X' ]

mtitle='MinXSS-'+fm_str

if not keyword_set(goes_no_cal) then mtitle += ': GOES Cal applied'

;
;   ****************************************************************
;	Plot results
;   ****************************************************************
;
  plot1 = 'minxss'+fm_str+'_'+fgoes_name+'_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot1
	eps2_p,plotdir+plot1
  endif
  setplot
  cc = rainbow(7)

  yrange4 = [1E-8,1E-3]
  ytitle4 = 'Irradiance (W/m!U2!N)'
  cs_goes = 2.0

  if (numDays gt 6062) then begin
    ;
    ;	Plot with Months labeled instead of DOY for greater than 2 months
    ;		James Mason Example
    ;		p1 = plot(time.jd, irradiance,  XTITLE = 'Time [UTC]', $
	;			XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Day', 'Month'])
	;
	labelDate = label_date(DATE_FORMAT = ['%D', '%M'])
	xtitle1a = 'Time (UTC)'
	pjd = yd2jd(base_year*1000.D0 + result[0,*])
	gjd = yd2jd(base_year*1000.D0 + goes_time)

    plot, pjd, result[1,*], psym=10, /nodata, xr=xrange, xs=1, /ylog, $
	  yr=yrange4, ys=1, xtitle=xtitle1a, ytitle=ytitle4, title=mtitle, $
	  XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Day', 'Month']
    oplot, pjd, result[1,*], psym=4, color=cc[3]
    if keyword_set(xrs_a) then oplot, gjd, goes_xrsa, color=cc[0] $
    else oplot, gjd, goes_xrsb, color=cc[0]

  endif else begin
    ;
    ;  Plot with DOY values as less than 2 months
    ;
    plot, result[0,*], result[1,*], psym=10, /nodata, xr=xrange, xs=1, /ylog, $
	  yr=yrange4, ys=1, xtitle=xtitle, ytitle=ytitle4, title=mtitle
    oplot, result[0,*], result[1,*], psym=4, color=cc[3]
    if keyword_set(xrs_a) then oplot, goes_time, goes_xrsa, color=cc[0] $
    else oplot, goes_time, goes_xrsb, color=cc[0]
  endelse

  dx = (!x.crange[1] - !x.crange[0])/10.
  xx = !x.crange[0] - dx
  my=2.
  if not keyword_set(xrs_a) then begin
    for jj=0L,n_elements(flare_name)-1 do begin
      xyouts, xx, my * 10.^float(!y.crange[0] + jj), flare_name[jj], color=cc[0], charsize=cs_goes
    endfor
  endif
  x1 = !x.crange[0] + 2*dx
  y1 = 7E-5 & my1 = 3.
  xyouts, x1, y1, goes_name, charsize=cs_goes, color=cc[0]
  xyouts, x1, y1*my1, x123_goes_name, charsize=cs_goes, color=cc[3]

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;   plot 2  is  RATIO plot
  ;
  plot2 = 'minxss'+fm_str+'_'+fgoes_name+'_ts_'+year_str+'-'+doy_str+'_'+doy2_str+'_ratio.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot2
	eps2_p,plotdir+plot2
  endif
  setplot
  cc = rainbow(7)

  if not keyword_set(goes_no_cal) then yrange2 = [0,1.5] else yrange2 = [0, 2.0]
  ytitle2 = 'Ratio X123 / GOES'
  cs_goes = 2.0

  plot, result[0,*], result[3,*], psym=10, /nodata, xr=xrange, xs=1, $
	yr=yrange2, ys=1, xtitle=xtitle, ytitle=ytitle2, title=mtitle
  oplot, !x.crange, [1,1], line=2
  oplot, result[0,*], result[3,*], psym=4

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;   plot 3  is  GOES versus X123
  ;
  plot3 = 'minxss'+fm_str+'_'+fgoes_name+'_'+year_str+'-'+doy_str+'_'+doy2_str+'_vs_x123.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot3
	eps2_p,plotdir+plot3
  endif
  setplot
  cc = rainbow(7)

  if keyword_set(xrs_a) then range3 = [1E-9, 1E-5] else range3 = [1E-8,1E-4]
  ytitle3 = x123_goes_name
  xtitle3 = goes_name + ' (W/m!U2!N)'
  dot, /large

  plot, result[2,*], result[1,*], psym=8, xr=range3, xs=1, /xlog, $
	yr=range3, ys=1, /ylog, xtitle=xtitle3, ytitle=ytitle3, title=mtitle

  yy = range3[0] / 3.
  mx=2.
  if not keyword_set(xrs_a) then begin
    for jj=0L,n_elements(flare_name)-2 do begin
      xyouts, mx * 10.^float(!x.crange[0] + jj), yy, flare_name[jj], color=cc[0], charsize=cs_goes
    endfor
  endif

  if doEPS ne 0 then send2 else read, 'Next ? ', ans

  ;
  ;		FIT ratio trend for X123/GOES as function of GOES intensity
  ;
  if not keyword_set(goes_no_cal) then fit_range = [0.15, 1.5] else fit_range = [0.25, 2.0]
  if keyword_set(xrs_a) then begin
     xrs_min = 4E-8
     xrs_max = 1E-5
  endif else begin
     xrs_min = 5E-8
     xrs_max = 2E-5
  endelse
  wfit = where( result[3,*] gt fit_range[0] and result[3,*] lt fit_range[1] $
  				and result[2,*] gt xrs_min and result[2,*] lt xrs_max, num_fit )
  if (num_fit gt 10) then begin
	xglog = alog10(reform(result[2,wfit])) & yratio = reform(result[3,wfit])
	if keyword_set(xrs_a) then nfit = 1 else nfit = 3
	coeff = poly_fit( xglog, yratio, nfit, sigma=sigma_fit, chi=chi_fit, yfit=yfit1 )
	; exclude 3-sigma bad points
	diff = abs(yratio-yfit1)
	wgood = where( diff lt 3.*stddev(diff), num_good )
	if (num_good gt 10) then begin
	  coeff = poly_fit( xglog[wgood], yratio[wgood], nfit, sigma=sigma_fit, chi=chi_fit, yfit=yfit2 )
	  wfit = wfit[wgood]
	  num_fit = num_good
	endif
	print, ' '
	print, 'Number of point used in fitting is ', num_fit, ' for ', goes_name
	print, 'Std Dev of difference is ', stddev(diff)
	print, 'Median of fitted ratio is ', median(result[3,wfit])
	print, strtrim(nfit,2) + 'th Order Fit for log(GOES) to Ratio_X123/GOES; Chi=',chi_fit
	xfit = findgen(71)/20. - 7.5  ; A3 to X1
	yfit = dblarr(71)
	for j=0,nfit do begin
		print, j, coeff[j], sigma_fit[j]
		yfit = yfit + coeff[j] * xfit^j
	endfor
	print, ' '
  endif

  ; SPECIAL fit for Sept 2016 Early Results Paper
  if (doy eq 160L) and (doy2 eq 260L) and (not keyword_set(xrs_a)) then begin
    print, 'SPECIAL FIT is used for DOY 160-260 for Paper'
    nfit = 3
  	coeff2 = [ 11.003D0, 5.9256, 1.2196, 0.08300 ]
  	xfit = findgen(71)/20. - 7.5  ; A3 to X1
	yfit = dblarr(71)
	for j=0,nfit do begin
		yfit = yfit + coeff[j] * xfit^j
	endfor
  endif

  ;
  ;   plot 4  is  GOES versus Ratio
  ;
  plot4 = 'minxss'+fm_str+'_'+fgoes_name+'_'+year_str+'-'+doy_str+'_'+doy2_str+'_vs_ratio.eps'
  if doEPS ne 0 then begin
	print, 'Writing EPS plot to ', plot4
	eps2_p,plotdir+plot4
  endif
  setplot
  cc = rainbow(7)

  xtitle3 = goes_name + ' (W/m!U2!N)'
  cs_goes = 2.0
  dot, /large

  plot, result[2,*], result[3,*], /nodata, psym=8, xr=range3, xs=1, /xlog, $
	yr=yrange2, ys=1, xtitle=xtitle3, ytitle=ytitle2, title=mtitle

  oplot, 10.^!x.crange, [1,1], line=2

  if (num_fit gt 10) then begin
  	oplot, result[2,wfit], result[3,wfit], psym=8
  	oplot, 10.^xfit, yfit, color=cc[3], thick=5
  endif else begin
	oplot, result[2,*], result[3,*], psym=8
  endelse

  dy = (!y.crange[1] - !y.crange[0])/10.
  yy = !y.crange[0] - dy
  mx=2.
  if not keyword_set(xrs_a) then begin
    for jj=0L,n_elements(flare_name)-2 do begin
      xyouts, mx * 10.^float(!x.crange[0] + jj), yy, flare_name[jj], color=cc[0], charsize=cs_goes
    endfor
  endif
  if not keyword_set(goes_no_cal) then begin
	  ; draw no calibration position
	  oplot, [1E-8, 2E-7, 2E-7], [1/theCal, 1/theCal, 0], line=2, color=cc[0]
	  xyouts, 1.5E-8, 0.55, 'No Cal', charsize=cs_goes, color=cc[0]
	  if keyword_set(xrs_a) then goes_cal_name = 'GOES Cal 1/0.85' else goes_cal_name = 'GOES Cal 1/0.7'
	  xyouts, 1.5E-8, 1.1, goes_cal_name, charsize=cs_goes
  endif else begin
    oplot, 10.^!x.crange, theCal*[1,1], line=3, thick=3, color=cc[0]
  endelse

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

if keyword_set(debug) then stop, 'DEBUG at end of minxss_goes_ts ...'

end
