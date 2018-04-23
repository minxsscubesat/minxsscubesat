;
;	minxss_L1_movie.pro
;
;	This procedure will select pre-flare and flare spectra interactively using MinXSS Level 1 data.
;
;	Procedure steps are:
;		Plot MinXSS Level 1 science data for specified day,
;		Select time range to focus on and then re-plots science data over focus range
;		Select pre-flare time range and flare period for the movie
;		Plot spectra results with 1-minute time steps - these frames then make up the movie
;
;	INPUT
;		date		Date in format of Year and Day of Year (YYYYDOY) or it can be in YYYYMMDD format too
;		/fm			Option to specify which MinXSS Flight Model (default is 1)
;		/reload		Option to reload L1, GOES XRS, and Orbit Number file
;		/debug		Option to debug at the end
;		/nowait		Option to run with CURSOR option of /nowait
;		/format		Option to set movie frame format:  1080 or 720, default is 1080
;						HD 1080 is 1920 x 1080,  HD 720 is 1280 x 720
;		/half_width	Option to just use half width so solar images can used for other half
;
;	OUTPUT
;		result		Irradiance spectra for pre-flare and flare time series
;		selections	Optional return of mouse selections or known dates for making the plots
;					selections is fltarr(6) hours with index of 0=focus_left, 1=focus_right
;					2=preflare_left, 3=preflare_right, 4=flare_left, 5=flare_right
;					Pass selections as one number if want to return the mouse selections.
;
;	FILES
;		MinXSS L1		$minxss_data/fm1/level1/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Orbit Numbers  	$TLE_dir/orbit_number/minxss_orbit_number.dat
;		Flare Movie		$minxss_data/movies/
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
pro minxss_movie, date, result, selections, fm=fm, reload=reload, $
						nowait=nowait, debug=debug, format=format, half_width=half_width

common minxss_data1, doy1, data1, goes_doy, goes_xrsa, goes_xrsb, sunrise, sunset, base_year

;
;	check input parameters
;
if n_params() lt 1 then begin
	print, ' '
	print, 'USAGE:  minxss_L1_movie, date, result, selections, fm=fm, /reload, $'
	print, '                          /nowait, format=format, /half_width, /debug'
	print, '         format can be 1080 for 1920x1080 or  720 for 1280x720'
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

;  option for movie frame size
if keyword_set(format) then format = long(format) else format=720L
if (format ne 1080) and (format ne 720) then format=720L
if (format eq 1080) then begin
	tv_width = 1920L
	tv_height = 1080L
endif else begin
	tv_width = 1280L
	tv_height = 720L
endelse
movie_name = '_L1_movie'
if keyword_set(half_width) then begin
	tv_width /= 2L
	movie_name = '_L1_Hmovie'
endif
if (format eq 1080) then movie_name = movie_name + '1080_' $
else movie_name = movie_name + '720_'

;  option for CURSOR, /nowait for some computers (e.g. Mac IDLDE)
doNOWAIT = 0
cans=' '
if keyword_set(nowait) then doNOWAIT = 1

;  option for user to pass in the previous mouse selections
if n_params() lt 3 then doSelections = 1 else doSelections = (n_elements(selections) ge 6? 0 : 1)
loopCnt = 0L   ; do selections (left over from EPS option from minxss_flare.pro)

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

moviedir = getenv('minxss_data')+'/movies/'
ans = ' '

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

wset, 0  ; set window 0 for time series plot (not part of the movie)
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
plot1 = 'minxss'+fm_str+movie_name+year_str+'-'+doy_str+'_day'
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

read, 'Hit the Enter key to select flare or Q to quit ? ', ans

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
plot2 = 'minxss'+fm_str+movie_name+year_str+'-'+doy_str+'_'+hour_str+'_ts'
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
	print, ' ***** Select Movie Left Time ...'
	if (doNOWAIT) then begin
		read, '(hit ENTER key when cursor is in position)', cans
		cursor, xpeaka, y2a, /nowait
	endif else cursor, xpeaka, y2a
	wait, 0.25
	oplot, xpeaka*[1,1], 10.^!y.crange, line=2
	print, ' '
	print, ' ***** '
	print, ' ***** Select Movie Right Time ...'
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

read, 'Next ? ', ans

;
;	Plot results - first select and average the results within the selected time ranges
;	In the MOVIE case, just use the pre-flare average
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
	print, 'ERROR finding movie spectrum'
	if keyword_set(debug) then stop, 'DEBUG...'
	print, '*****  EXITING  *****'
	return
endif

;
;	make pre-flare average spectrum
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

; define energy scale
esp = data1[wpre[0]].energy

; check if there are no spectra to plot
if (num_pre lt 1) and (num_peak lt 1) then goto, MOVIE_END
if (num_pre lt 1) then sp_pre = fltarr(1024)

;
;	save energy, pre-flare spectrum, and movie spectra into result
;
result = fltarr( num_peak+2, n_elements(esp) )
result[0,*] = esp
result[1,*] = sp_pre
for k=0L,num_peak-1 do result[k+2,*] = sp1day[*,wpeak[k]]

wxrs2 = where( (goes_hour ge xrange2[0]) and (goes_hour le xrange2[1]), num_xrs2 )
flare_str = '? class'
flare_class = '?'
if (num_xrs2 gt 1) then begin
  	ftemp = max(goes_xrsb[wxrs2])
  	flare_str = 'A'
  	if (ftemp gt 9.95E-4) then begin
  	  flare_class = 'X'
  	  flare_str = 'X' + string(long(ftemp/1E-4),format='(I2)')
  	endif else if (ftemp gt 9.95E-5) then begin
  	  flare_class = 'X'
  	  flare_str = 'X' + string(ftemp/1E-4,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-6) then begin
  	  flare_class = 'M'
  	  flare_str = 'M' + string(ftemp/1E-5,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-7) then begin
  	  flare_class = 'C'
  	  flare_str = 'C' + string(ftemp/1E-6,format='(F3.1)')
  	endif else if (ftemp gt 9.95E-8) then begin
  	  flare_class = 'B'
  	  flare_str = 'B' + string(ftemp/1E-7,format='(F3.1)')
  	endif
  	flare_str += ' flare'
endif
mtitle2 = 'MinXSS-'+fm_str+' for ' + flare_str
print, ' '
print, '*****  Making '+strtrim(num_peak,2)+' Movie Frames for ', mtitle2
print, '       Graphics files are saved in ', moviedir
print, ' '

;
;   ****************************************************************
;	Plot results as series of figures that can be sequenced as movie
;   ****************************************************************
;
;   Make Window 1 for Movie Frame
;window,1, xsize=tv_width, ysize=tv_height, title=mtitle2
;wset,1

for k=0L,num_peak-1 do begin
  sp_peak = sp1day[*,wpeak[k]]
  sp_time = sphour[wpeak[k]]
  sp_hour = long(sp_time)
  sp_min = long((sp_time - sp_hour)*60.)
  sp_sec = long((sp_time - sp_hour - sp_min/60.)*3600.)
  date_str = year_str+'/'+doy_str+' '
  time_str = string(sp_hour,format='(I02)')+':'+string(sp_min,format='(I02)')+ $
  				':'+string(sp_sec,format='(I02)')
  file_time_str = year_str + doy_str + '_' + string(sp_hour,format='(I02)')+ $
  					string(sp_min,format='(I02)') + string(sp_sec,format='(I02)')

  plot3 = 'minxss'+fm_str+movie_name+file_time_str    ;  no extension yet
  ;
  ; OLD code for plot procedure is commented out and plot function is used to make graphics files
  ;setplot
  ;cc = rainbow(7)
  ;cpre = cc[3]
  ;cpeak = cc[0]
  cpre = 'green'
  cpeak = 'red'

  erange = [0.7, 10.]
  yrange4 = [1E2,3E8]
  ytitle4 = 'Irradiance (photons/sec/cm!U2!N/keV)'
  xmargin=[6,2]

  if (k eq 0) then begin
    pcurrent = 0
  endif else begin
  	pcurrent = 1
  	w = p1.window
    w.Erase
  endelse

  ; plot, esp, sp_pre, psym=10, /nodata, xr=erange, xs=1, /xlog, /ylog, $
  ;  xmargin=xmargin, ymargin=[2.5,12], xtickname=[' ', ' ', ' ', ' ', ' ', ' '], $
  ;	yr=yrange4, ys=1, xtitle=' ', ytitle=ytitle4, title=' '

  if keyword_set(half_width) then begin
  		xmargin1 = 0.16
  		xmargin2 = 0.04
  endif else begin
  		xmargin1 = 0.08
  		xmargin2 = 0.02
  endelse

  p1 = plot( esp, sp_pre, /histogram, color=cpre, title=' ', window_title=mtitle2, $
  		xrange=erange, xstyle=1, /xlog, xtitle=' ', xshowtext=0, current=pcurrent, $
  		yrange=yrange4, ystyle=1, /ylog, ytitle=ytitle4,  $
  		margin=[xmargin1,0.05,xmargin2,0.45], dimensions=[tv_width, tv_height], font_size=18 )

  ; oplot, esp, sp_pre, psym=10, color=cpre
  ; oplot, esp, sp_peak, psym=10, color=cpeak
  p2 = plot( esp, sp_peak, /histogram, color=cpeak, /overplot )

  xx = 2.5 & xx2 = 4. & yy = 3E6 & my=4.
  cslabel = 18
  if keyword_set(half_width) then cslabel=16
  ;xyouts, xx, yy, 'Pre-Flare', color=cpre
  t1 = text( xx, yy, 'Pre-Flare', color=cpre, /data, font_size=cslabel, clip=0 )
  ;xyouts, xx, yy*my, 'Flare', color=cpeak
  t2 = text( xx, yy*my, 'Flare  '+date_str+time_str, color=cpeak, /data, font_size=cslabel, clip=0 )
  ;xyouts, xx2, yy*my^2, date_str + time_str, color=cpeak
  ;xyouts, xx2, yy*my^3, mtitle2
  t4 = text( xx, yy*my^2, mtitle2, /data, font_size=cslabel, clip=0 )

  xbottom = ['0.7', '1', '2', '4', '7', '10']
  xbot = float(xbottom)
  xbot[1] += 0.05
  num_x = n_elements(xbottom)
  ; csbot=2.5
  csbot = 18
  ybot = yrange4[0]/3.
  tb = objarr( num_x )
  for i=0L,num_x-1 do begin
    botname = xbottom[i]
    if (i eq 1) then botname += ' keV'
  	; xyouts,xbot[i],ybot,botname,align=0.5,charsize=csbot
  	tb[i] = text( xbot[i],ybot,botname,align=0.5, /data, font_size=csbot, clip=0 )
  endfor
  xtop = 1.24 / xbot
  ; cstop=2.0
  cstop = 14
  ytop = yrange4[1]*1.5
  tt = objarr( num_x )
  for i=0L,num_x-1 do begin
    topname = string(xtop[i],format='(F4.2)')
    if (i eq 1) then topname += ' nm'
  	; xyouts,xbot[i],ytop,topname,align=0.5,charsize=cstop
  	tt[i] = text( xbot[i],ytop,topname,align=0.5, /data, font_size=cstop, clip=0 )
  endfor

  ;  add GOES time series to above this plot
  wxrs2 = where( (goes_hour ge (xrange2[0])) and (goes_hour le (xrange2[1])), num_xrs )
  gmax = max(goes_xrsb[wxrs2])*1.00504  ; force to next flare class if necessary
  gfactor = 10.^(long(alog10(gmax))-1.)
  gmax = gmax / gfactor
  if (gmax lt 2) then ymax = 2. $
  else if (gmax lt 5) then ymax = 5. $
  else ymax = 10.
  yrange5=[0,ymax]
  ytitle5 = 'GOES ' + flare_class + ' class'
  goes_scaled = goes_xrsb[wxrs2]/gfactor
  ; plot, goes_hour[wxrs2], goes_scaled, /nodata, /noerase, xmargin=xmargin, ymargin=[21.5,0.5], $
  ;		xrange=xrange2, xs=2, yrange=yrange5, ys=1, xtitle=xtitle, ytitle=ytitle5, title=' '
  p5 = plot( goes_hour[wxrs2], goes_scaled, /nodata, /current, title=' ', $
  		position=[xmargin1, 0.68, 1.-xmargin2, 0.98], font_size=18, $
  		xrange=xrange2, xstyle=2, xtitle=xtitle, $
  		yrange=yrange5, ystyle=1, ytitle=ytitle5 )

  ;
  ;	plot grey shading for eclipse period
  ;
  wrise = where( (sunrise ge (doy-0.5)) and (sunrise le (doy+1.5)), num_sun )
  num_sun = -1L  ; skip eclipse
  for i=0L, num_sun-1 do begin
    temp = min( abs(sunrise[wrise[i]]-sunset), wmin )
    sunmax = (sunset[wmin] - doy) * 24.
    sunmin = (sunrise[wrise[i]] - doy) * 24.
    if (sunmin gt sunmax) then begin
      temp = sunmin
      sunmin = sunmax
      sunmax = temp
    endif
    if (sunmax gt xrange2[1]) then sunmax = xrange2[1]
    if (sunmin lt xrange2[0]) then sunmin = xrange2[0]
    if (sunmin lt xrange2[1]) and (sunmax gt xrange2[0]) then begin
      xbox = [ sunmin, sunmax, sunmax, sunmin, sunmin ]
      ybox = [ yrange5[0]+0.1, yrange5[0]+0.1, yrange5[1]-0.1, yrange5[1]-0.1, yrange5[0]+0.1 ]
      polyfill, xbox, ybox, color=grey
    endif
  endfor

  ; oplot, goes_hour[wxrs2], goes_scaled
  p6 = plot( goes_hour[wxrs2], goes_scaled, /overplot )
  ; oplot, sp_time*[1,1], yrange5, color=cpeak, thick=3
  p7 = plot( sp_time*[1,1], yrange5, color=cpeak, thick=3, /overplot )

  ;
  ;  save the Plot as PNG file
  ;
  graphics_ext = '.png'
  plot3 = plot3 + graphics_ext
  print, '    Saving Graphics file ', plot3
  p1.Save, moviedir+plot3, WIDTH=tv_width, HEIGHT=tv_height, BORDER=10

  read, 'Next ? ', ans
endfor

MOVIE_END:
if keyword_set(debug) then stop, 'DEBUG at end of minxss_L1_movie ...'

end
