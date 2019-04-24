;
;	minxss_flare_playback.pro
;
;	Write script to playback high-cadence HK & SCI packets for flare event
;	Select time range to focus on flare event
;	Select pre-flare and flare peak time ranges
;	Create flare playback scripts
;		1)  single playback if pre-flare & flare peak time ranges over lap
;		2)  separate playbacks for pre-flare and flare peak time ranges that don't overlap
;
;	INPUT
;		date			Year - DOY
;		/year		Option to specify year besides 2016
;		/reload		Option to reload L0C, GOES XRS, and Orbit Number file
;		/eps		Option to make EPS graphics files after doing interactive plotting
;		/debug		Option to debug at the end
;		/script_path	Option to specify ISIS script path
;
;	OUTPUT
;		SCRIPT FILES in ISIS/scripts/ directory
;
;	FILES
;		MinXSS L0C		$minxss_data/merged/minxss1_l0c_all_mission_length.sav
;		GOES XRS		$minxss_data/merged/goes_1mdata_widx_YEAR.sav  (YEAR=2016 for now)
;		Orbit Numbers  	$TLE_dir/orbit_number/minxss_orbit_number.dat
;
;	OTHER CODE
;		minxss_time_to_sd_offset is used to get SD-Card offsets based on time
;
;	HISTORY
;		7/12/16  Tom Woods	Original code based on minxss_plot_flare.pro
;
pro minxss_flare_playback, date, reload=reload, eps=eps,  chosen_filename=chosen_filename, $
				script_path=script_path, debug=debug, station=station

common minxss_data0c, hkdoy, hk, scidoy, sci, log, goes_doy, goes_xrsa, goes_xrsb, sunrise, sunset, base_year

 ;  slash for Mac = '/', PC = '\'
IF !version.os_family EQ 'Windows' THEN slash = '\' ELSE slash = '/'

year = long(date / 1000L)
doy = date - year*1000L
if (year lt 2016) then begin
  year = 2016
  print, 'WARNING: changing to Year 2016 and DOY = ', doy
endif

;
;	read the MinXSS L0C merged file, GOES XRS data, and MinXSS Orbit Number data
;
dir_merged = getenv('minxss_data')+slash+'merged'+slash
dir_level0c = getenv('minxss_data') + slash+'fm2'+slash+'level0c'+slash
if n_elements(hkdoy) lt 2 or keyword_set(reload) then begin
  ; file0c = 'minxss1_l0c_hk_mission_length.sav'
  ;  "all" file has all packet types for the MinXSS-1 mission (as of 6/10/2016)
  file0c = 'minxss2_l0c_all_mission_length.sav'
  print, 'Loading ', dir_level0c+file0c
  restore, dir_level0c + file0c		; hk
  ;
  ;	make hkdoy, datestr, and find indices for wel, wsun, wx123
  ;	also make scidoy
  ;
  base_year = year
  if (base_year lt 2016) then base_year = 2016L
  hkdoy = jd2yd(gps2jd(hk.time)) - base_year*1000.D0
  scidoy = jd2yd(gps2jd(sci.time)) - base_year*1000.D0

  ;
  ;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
  ;
  xrs_file = 'goes_1mdata_widx_'+strtrim(base_year,2)+'.sav'
  xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
  print, 'Loading ', xrs_dir+xrs_file
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_doy = jd2yd(gps2jd(goes.time)) - base_year*1000.D0  ; convert GPS to DOY fraction
  goes_xrsb = goes.long
  goes_xrsa = goes.short
  goes=0L

  ;
  ;	load orbit number data
  ;
  db_pos = strpos( dir_merged, 'minxss_dropbox' )
  if (db_pos gt 0) then begin
    tle_dir = strmid( dir_merged,0, db_pos+14) + slash + 'tle'
  endif else begin
    tle_dir = getenv('TLE_dir')
  endelse
  if strlen(tle_dir) gt 0 then tle_dir += slash
  orbit_dir = tle_dir +'orbit_number'+slash
  orbit_num_file = 'minxss2_orbit_number.dat'
  orbit_num = read_dat( orbit_dir + orbit_num_file )
  ;  make DOY value
  sunrise = orbit_num[1,*] - base_year*1000.D0 + orbit_num[3,*]/(24.D0*3600.)
  sunset = orbit_num[1,*] - base_year*1000.D0 + orbit_num[4,*]/(24.D0*3600.)
endif else begin
    if (year ne base_year) then begin
    	hkdoy += (base_year - year) * 1000.D0
    	scidoy += (base_year - year) * 1000.D0
    	goes_doy += (base_year - year) * 1000.D0
    	sunrise += (base_year - year) * 1000.D0
    	sunset += (base_year - year) * 1000.D0
    	base_year = year
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

doPreflare = 0  ; set to default as being off (i.e., no separate pre-flare script)

doEPS = 0   ; set to zero for first pass through for interactive plots
loopCnt = 0L

  ;
  ; Set script path
  ;
  IF keyword_set(script_path) THEN BEGIN
    spath_name = script_path
  ENDIF ELSE BEGIN
    if keyword_set(station) then begin
      spath_name='C:\Users\OPS\Dropbox\Hydra\MinXSS\HYDRA_FM-2_'+strtrim(station,2)+'\Scripts\'
    endif else begin
      spath_name='C:\Users\OPS\Dropbox\Hydra\MinXSS\HYDRA_FM-2_Fairbanks\Scripts\'
    endelse
  ENDELSE
  IF strlen(spath_name) GT 0 THEN BEGIN
    ; check if need to add slash
    spos = strpos(spath_name, slash, /reverse_search )
    slen = strlen(spath_name)
    IF (spos NE (slen-1)) THEN spath_name = spath_name + slash
  ENDIF
  IF keyword_set(debug) THEN print, '*** Script path = ', spath_name

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

sps_sum = total(sci.sps_data[0:3],1) / float(sci.xps_data)
sps_sum_sun_min = 280000.   ; June 2016 it is 310K; this  allows for 1-AU changes and 5% degradation

; exclude spectra with radio on (flag > 1), not in sun, and high low counts
lowcnts = total( sp[20:24,*], 1 )
lowLimit = 7.0		; median is 1.0 for bins 20-24 - larger limit is needed for bigger flares (was 2.0)
wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scidoy ge (doy-1)) and (scidoy lt (doy+2)) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp )

if (num_sp le 1) then begin
	print, 'WARNING: no good SCI packets for DOY = ' + doy_str
	sphour = scihour
	fast_count1 = fast_count
	slow_count1 = slow_count
	num_sp1 = n_elements(sphour)
endif else begin
	sphour = scihour[wsci]
	fast_count1 = fast_count[wsci]
	slow_count1 = slow_count[wsci]
	num_sp1 = n_elements(sphour)
endelse

;	Select GOES X-ray data for +/- 1 day in case flare goes over day boundary
wxrs = where( (goes_doy ge (doy-1)) and (goes_doy lt (doy+2)), num_xrs )
;	Check if there is GOES X-ray data for single day
wxrs1 = where( (goes_doy ge doy) and (goes_doy lt (doy+1)), num_xrs1 )
if (num_xrs1 le 1) then begin
	print, 'ERROR: no GOES X-ray data for DOY = ' + doy_str
	if keyword_set(debug) then stop, 'DEBUG minxss_flare_playback ...'
	;return
endif

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
mtitle='MinXSS-2'

plot, sphour, fast_count1, /nodata, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog

;
;	plot grey shading for eclipse period
;
wrise = where( (sunrise ge doy) and (sunrise le (doy+1L)), num_sun )
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
  xbox = [ sunmin, sunmax, sunmax, sunmin, sunmin ]
  ybox = 10.^[ !y.crange[0]+0.1, !y.crange[0]+0.1, !y.crange[1]-0.1, !y.crange[1]-0.1, !y.crange[0]+0.1 ]
  polyfill, xbox, ybox, color=grey
endfor

oplot, sphour, slow_count1, psym=4, color=cs123

xfactor = yr[0] / 1E-7
oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
flare_name = [ 'B', 'C', 'M', 'X' ]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

if doEPS ne 0 then send2 else read, 'Enter key to select flare or Q to quit ? ', ans

if strmid(strupcase(ans),0,1) eq 'Q' then return   ; user says No for selecting a flare

;
;	Select time range to focus on and replot
;
if (loopCnt eq 0) then begin
	print, ' '
	print, ' ***** '
	print, ' ***** Select Left Edge for flare focus period ...'
	cursor, xleft, y1
	wait, 0.25
	xleft = long(xleft * 10.)/10.
	print, ' '
	print, ' ***** '
	print, ' ***** Select Right Edge for flare focus period ...'
	cursor, xright, y2
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
plot, sphour, fast_count1, /nodata, psym=1, xr=xrange2, xs=1, yr=yr, ys=1, $
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
  if (sunmin le xrange2[1]) and (sunmax ge xrange2[0]) then begin
    xbox = [ sunmin, sunmax, sunmax, sunmin, sunmin ]
    ybox = 10.^[ !y.crange[0]+0.1, !y.crange[0]+0.1, !y.crange[1]-0.1, !y.crange[1]-0.1, !y.crange[0]+0.1 ]
    polyfill, xbox, ybox, color=grey
  endif
endfor

oplot, sphour, slow_count1, psym=4, color=cs123

oplot, goes_hour[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

;
;	Select pre-flare and flare peak spectra
;
if (loopCnt eq 0) then begin
	print, ' '
	print, ' ***** '
	print, ' ***** Select Pre-flare Left Time ...'
	cursor, xprea, y1a
	wait, 0.25
	oplot, xprea*[1,1], 10.^!y.crange, line=1
	print, ' '
	print, ' ***** '
	print, ' ***** Select Pre-flare Right Time ...'
	cursor, xpreb, y1b
	wait, 0.25
	oplot, xpreb*[1,1], 10.^!y.crange, line=1
	print, ' '
	print, ' ***** '
	print, ' ***** Overlap Peak Flare time with Pre-flare time if want single playback *****'
	print, ' ***** '
	print, ' ***** Select Peak Flare Left Time ...'
	cursor, xpeaka, y2a
	wait, 0.25
	oplot, xpeaka*[1,1], 10.^!y.crange, line=2
	print, ' '
	print, ' ***** '
	print, ' ***** Select Peak Flare Right Time ...'
	cursor, xpeakb, y2b
	oplot, xpeakb*[1,1], 10.^!y.crange, line=2
	wait, 0.25
endif

if doEPS ne 0 then send2 else read, 'Next ? ', ans

;  END OF LOOP
loopcnt += 1
if (loopcnt eq 1) and keyword_set(eps) then begin
	; make EPS files now (repeat the plots)
	print, ' '
	print, 'MAKING EPS FILES ...'
   doEPS = 1
   goto, LOOP_START
endif

;  calculate center time
xpre = (xprea+xpreb)/2.  ; time of center of pre-flare
xpeak = (xpeaka+xpeakb)/2.  ; time of center of peak flare

;  put Time ranges in order if necessary
if (xprea gt xpreb) then begin
	temp=xprea
	xprea=xpreb
	xpreb=temp
endif
if (xpeaka gt xpeakb) then begin
	temp=xpeaka
	xpeaka=xpeakb
	xpeakb=temp
endif

;
;	Determine HK and SCI SD-Card sector start, stop, and stepSize values
;	1)  Check if pre-flare and peak flare time ranges over lap or not
;	2A)	If not, then do two playback scripts
;	2B) If so, then do single playback script
;

HK_NUM_SECTORS = 200.		; desired number of sectors for HK for playback
SCI_NUM_SECTORS = 360.		; desired number of sectors for SCI for playback

PLAYBACK_RATE = 1.7			; number of sectors per second for playback

base_jd = yd2jd( long(base_year)*1000.D0 + long(doy) )

if ((xpeaka lt xpreb) and (xpeaka gt xprea)) or ((xprea lt xpeakb) and (xprea gt xpeaka)) then begin
	; single playback script
	doPreflare = 0
	jd1 = base_jd + min( [xprea, xpeaka] ) / 24.
	minxss_time_to_sd_offset, hk, jd1, offsets1
	jd2 = base_jd + max( [xpreb, xpeakb] ) / 24.
	minxss_time_to_sd_offset, hk, jd2, offsets2
	HKstartSector = offsets1[0]
	HKstopSector = offsets2[0]
	HKstepSize = long(((HKstopSector-HKstartSector) / HK_NUM_SECTORS) + 0.5)
	if (HKstepSize lt 3) then HKstepSize = 3
	HKtime = ((HKstopSector-HKstartSector) / HKstepSize) / PLAYBACK_RATE / 60.
	SCIstartSector = offsets1[1]
	SCIstopSector = offsets2[1]
	SCIstepSize = long(((SCIstopSector-SCIstartSector) / 7L / SCI_NUM_SECTORS) + 0.5)
	if (SCIstepSize lt 1) then SCIstepSize = 1
	SCItime = ((SCIstopSector-SCIstartSector) / 7L / SCIstepSize) / PLAYBACK_RATE / 60.
	print, ' '
	print, 'SINGLE FLARE PLAYBACK SCRIPT'
	print, '----------------------------'
	print, 'HK  sectors ', HKstartSector, HKstopSector, HKstepSize
	print, 'SCI sectors ', SCIstartSector, SCIstopSector, SCIstepSize
	print, 'Playback time = ', string(HKtime + SCItime,format='(F5.1)'), ' minutes'
endif else begin
	; peak flare and pre-flare playscripts
	doPreflare = 1
	;    PEAK FLARE SCRIPT
	jd1 = base_jd + xpeaka / 24.
	minxss_time_to_sd_offset, hk, jd1, offsets1
	jd2 = base_jd + xpeakb / 24.
	minxss_time_to_sd_offset, hk, jd2, offsets2
	HKstartSector = offsets1[0]
	HKstopSector = offsets2[0]
	HKstepSize = long(((HKstopSector-HKstartSector) / HK_NUM_SECTORS) + 0.5)
	if (HKstepSize lt 3) then HKstepSize = 3
	HKtime = ((HKstopSector-HKstartSector) / HKstepSize) / PLAYBACK_RATE / 60.
	SCIstartSector = offsets1[1]
	SCIstopSector = offsets2[1]
	SCIstepSize = long(((SCIstopSector-SCIstartSector) / 7L / SCI_NUM_SECTORS) + 0.5)
	if (SCIstepSize lt 1) then SCIstepSize = 1
	SCItime = ((SCIstopSector-SCIstartSector) / 7L / SCIstepSize) / PLAYBACK_RATE / 60.
	print, ' '
	print, 'PEAK FLARE PLAYBACK SCRIPT'
	print, '----------------------------'
	print, 'HK  sectors ', HKstartSector, HKstopSector, HKstepSize
	print, 'SCI sectors ', SCIstartSector, SCIstopSector, SCIstepSize
	print, 'Playback time = ', string(HKtime + SCItime,format='(F5.1)'), ' minutes'

	;    PRE-FLARE SCRIPT
	jd1 = base_jd + xprea / 24.
	minxss_time_to_sd_offset, hk, jd1, offsets1
	jd2 = base_jd + xpreb / 24.
	minxss_time_to_sd_offset, hk, jd2, offsets2
	preHKstartSector = offsets1[0]
	preHKstopSector = offsets2[0]
	preHKstepSize = long(((preHKstopSector-preHKstartSector) / HK_NUM_SECTORS) + 0.5)
	if (preHKstepSize lt 3) then preHKstepSize = 3
	HKtime = ((preHKstopSector-preHKstartSector) / preHKstepSize) / PLAYBACK_RATE / 60.
	preSCIstartSector = offsets1[1]
	preSCIstopSector = offsets2[1]
	preSCIstepSize = long(((preSCIstopSector-preSCIstartSector) / 7L / SCI_NUM_SECTORS) + 0.5)
	if (preSCIstepSize lt 1) then preSCIstepSize = 1
	SCItime = ((preSCIstopSector-preSCIstartSector) / 7L / preSCIstepSize) / PLAYBACK_RATE / 60.
	print, ' '
	print, ' PRE-FLARE PLAYBACK SCRIPT'
	print, '----------------------------'
	print, 'HK  sectors ', preHKstartSector, preHKstopSector, preHKstepSize
	print, 'SCI sectors ', preSCIstartSector, preSCIstopSector, preSCIstepSize
	print, 'Playback time = ', string(HKtime + SCItime,format='(F5.1)'), ' minutes'
endelse
print, ' '

  ;
  ;		Read playback_flare_template SCRIPT file
  ;
  filename = 'C:\Users\OPS\Dropbox\Hydra\MinXSS\HYDRA_FM-2_Fairbanks\Scripts\scripts_auto_template\playback_flare_template.prc'
  finfo = file_info(filename)
  openr, lun, filename, /get_lun
  scriptbytes = bytarr(finfo.size)
  readu, lun, scriptbytes
  close, lun
  free_lun, lun

  ;
  ;		write playback_flare_YYYYDOY SCRIPT file
  ;
  filledscript = string(scriptbytes)
  filledscript = strreplace(filledscript, ['<THKstartSector>', '<TSCIstartSector>', '<StepSize>'], $
  					strtrim(long([HKstartSector, SCIstartSector, SCIstepSize]),2))

IF keyword_set(chosen_filename) then new_file = chosen_filename + '.prc' else begin
  ;Flare start hour
  hr = xpeaka
  date_str = string(long(base_year),format='(I04)') + string(long(doy),format='(I03)') + '_' + string(long(hr),format='(I02)') + 'UT'
  new_file = 'playback_flare_' + date_str + '.prc'
  endelse
  print, 'Saving New Flare Playback script in ', new_file
  filename = spath_name+new_file
  openw, lun, filename, /get_lun
  printf, lun, filledscript
  close, lun
  free_lun, lun

if (doPreflare ne 0) then begin
  ;
  ;		write playback_preflare_YYYYDOY SCRIPT file
  ;
  filledscript = string(scriptbytes)
  filledscript = strreplace(filledscript, ['<THKstartSector>','<TSCIstartSector>','<StepSize>'], $
  					strtrim(long([preHKstartSector, preSCIstartSector, preSCIstepSize]),2))

IF keyword_set(chosen_filename) then new_file = chosen_filename + '_preflare.prc' else begin
  hr = xprea
  date_str = string(long(base_year),format='(I04)') + string(long(doy),format='(I03)') + '_'  + string(long(hr),format='(I02)') + 'UT'
  new_file = 'playback_flare_' + date_str + '_preflare.prc'
  endelse
  print, 'Saving New Pre-Flare Playback script in ', new_file
  filename = spath_name+new_file
  openw, lun, filename, /get_lun
  printf, lun, filledscript
  close, lun
  free_lun, lun
endif

if keyword_set(debug) then stop, 'DEBUG at end of minxss_flare_playback ...'

end
