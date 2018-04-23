;
;	minxss_doy_playback.pro
;
;	Write script to playback HK, LOG & SCI packets for over a few days
;	Plot data with GOES X-ray overplotted
;   Specify Date (DOY) and number of days for the playback
;	Create DOY playback script
;
;	INPUT
;		date		Date in YYYYDOY or YYYYMMDD format
;		numberDays	Number of days for playback (defaults to 2)
;		/reload		Option to reload L0C, GOES XRS, and Orbit Number file
;		/debug		Option to debug at the end
;		/script_path	Option to specify ISIS script path
;   /auto_make     Option to generate playback without being interactive (pick 0-24 UT)
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
;		9/29/16  Tom Woods	Original code based on minxss_flare_playback.pro
;
pro minxss_doy_playback, date, numberDays, reload=reload, $
				script_path=script_path, debug=debug, auto_make=auto_make

common minxss_data0c, hkdoy, hk, scidoy, sci, log, goes_doy, goes_xrsa, goes_xrsb, sunrise, sunset, base_year

if n_params() lt 1 then begin
	date = 0L
	read, '>>>>> Enter Date (either YYYYDOY or YYYYMMDD) ? ', date
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

if n_params() lt 2 then numberDays = 2  ; default value
if (numberDays lt 1) then numberDays = 1
if (numberDays gt 10) then numberDays = 10
numDayStr = strtrim(numberDays,2)
if keyword_set(debug) then print, '***** Plotting data for ',yyyydoy_str, ' for ', numDayStr, ' days'

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
;
dir_merged = getenv('minxss_data')+slash+'merged'+slash
dir_level0c = getenv('minxss_data')+slash+'fm1'+slash+'level0c'+slash
if n_elements(hkdoy) lt 2 then base_year = 0L
if n_elements(hkdoy) lt 2 or keyword_set(reload) or (base_year ne year) then begin
  print, 'Restoring Level-0C data...'
  ; file0c = 'minxss1_l0c_hk_mission_length.sav'
  ;  "all" file has all packet types for the MinXSS-1 mission (as of 6/10/2016)
  file0c = 'minxss1_l0c_all_mission_length.sav'
  restore, dir_level0c + file0c		; hk
  ;
  ;	make hkdoy, datestr, and find indices for wel, wsun, wx123
  ;	also make scidoy
  ;
  base_year = year
  hkdoy = jd2yd(gps2jd(hk.time)) - base_year*1000.D0
  scidoy = jd2yd(gps2jd(sci.time)) - base_year*1000.D0

  ;
  ;	load GOES XRS data from titus/timed/analysis/goes/ IDL save set (file per year)
  ;
  xrs_file = 'goes_1mdata_widx_'+strtrim(base_year,2)+'.sav'
  xrs_dir = getenv('minxss_data')+slash+'ancillary'+slash+'goes'+slash
  restore, xrs_dir + xrs_file   ; goes data structure
  goes_doy = jd2yd(gps2jd(goes.time)) - base_year*1000.D0  ; convert GPS to DOY fraction
  goes_xrsb = goes.long
  goes_xrsa = goes.short
  goes=0L

  ;
  ;	load orbit number data
  ;
  db_pos = strpos( dir_merged, 'minxss_dropbox')
  if (db_pos gt 0) then begin
  	tle_dir = strmid( dir_merged, 0, db_pos+14 ) + slash + 'tle'
  endif else begin
    tle_dir = getenv('TLE_dir')
  endelse
  if strlen(tle_dir) gt 0 then tle_dir += slash
  orbit_dir = tle_dir + 'orbit_number' + slash
  orbit_num_file = 'minxss_orbit_number.dat'
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

ans = ' '

  ;
  ; Set script path
  ;
  IF keyword_set(script_path) THEN BEGIN
    spath_name = script_path
  ENDIF ELSE BEGIN
    ;  default is to use directory $ISIS_scripts_dir
    spath_name = getenv('ISIS_scripts_dir')
    ; else path_name is empty string
  ENDELSE
  IF strlen(spath_name) GT 0 THEN BEGIN
    ; check if need to add slash
    spos = strpos(spath_name, slash, /reverse_search )
    slen = strlen(spath_name)
    IF (spos NE (slen-1)) THEN spath_name = spath_name + slash
  ENDIF
  IF keyword_set(debug) THEN print, '*** Script path = ', spath_name

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
lowLimit = 7.0		; median is 1.0 for bins 20-24
wsci = where( (sci.x123_radio_flag lt 2) and (sps_sum gt sps_sum_sun_min) $
		and (scidoy ge (doy-2)) and (scidoy lt (doy+numberDays+2)) $
		and (lowcnts lt lowLimit) and (fast_count lt fast_limit), num_sp )

if (num_sp le 1) then begin
	print, 'WARNING: no good SCI packets for DOY = ' + doy_str
	spdoy = scidoy
	fast_count1 = fast_count
	slow_count1 = slow_count
	num_sp1 = n_elements(spdoy)
endif else begin
	spdoy = scidoy[wsci]
	fast_count1 = fast_count[wsci]
	slow_count1 = slow_count[wsci]
	num_sp1 = n_elements(spdoy)
endelse

;	Select GOES X-ray data for +/- 1 day in case flare goes over day boundary
wxrs = where( (goes_doy ge (doy-2)) and (goes_doy lt (doy+numberDays+2)), num_xrs )
;	Check if there is GOES X-ray data for single day
if (num_xrs le 1) then begin
	print, 'WARNING: no GOES X-ray data for DOY = ' + doy_str
    num_xrs = n_elements(goes_doy)
    wxrs = indgen(num_xrs)
endif

;
;	Plot MinXSS science data for specified day
;
setplot
cc=rainbow(7)
cs123 = cc[3]  ; X123 slow counts color
grey = 'C0C0C0'X

xtitle='Time (DOY of ' + strtrim(long(base_year),2) + ')'
xrange = [doy - 1, doy + numberDays + 1]

;yr = [1E1,1E5]
yr = [1E0,1E5] ; CSM, changed the plot range to go down to 1 cps for NuSTAR data
ytitle='X123 Total Signal (cts/sec)'
mtitle='MinXSS-1'

plot, spdoy, fast_count1, /nodata, psym=1, xr=xrange, xs=1, yr=yr, ys=1, $
	xtitle=xtitle, ytitle=ytitle, title=mtitle, /ylog

;
;	plot grey shading for eclipse period
;
if (numberDays lt 3) then begin
 wrise = where( (sunrise ge (doy-1L)) and (sunrise le (doy+numberDays+1L)), num_sun )
 for k=0L, num_sun-1 do begin
  temp = min( abs(sunrise[wrise[k]]-sunset), wmin )
  sunmax = sunset[wmin]
  sunmin = sunrise[wrise[k]]
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
endif

oplot, spdoy, slow_count1, psym=4, color=cs123

xfactor = yr[0] / 1E-7
oplot, goes_doy[wxrs], goes_xrsb[wxrs]*xfactor, color=cc[0]
flare_name = [ 'B', 'C', 'M', 'X' ]
xx = !x.crange[0]*1.05 - !x.crange[1]*0.05
for jj=0,3 do xyouts, xx, yr[0]*2.* 10.^jj, flare_name[jj], color=cc[0]

;  over-plot data range for the DOY playback
oplot, doy*[1,1], 10.^!y.crange, line=2
oplot, (doy+numberDays)*[1,1], 10.^!y.crange, line=2

ans = ' '
if (not keyword_set(auto_make)) or (n_params() lt 2) then begin
  read, 'Hit ENTER key to make DOY playback script or Q to Quit ', ans
endif
if strmid(strupcase(ans),0,1) eq 'Q' then return   ; user says No for making playback file

;
;	Determine HK and SCI SD-Card sector start, stop, and stepSize values
;

HK_NUM_SECTORS = 200.		; desired number of sectors for HK for playback
SCI_NUM_SECTORS = 200.		; desired number of sectors for SCI for playback
LOG_NUM_SECTORS = 60.

PLAYBACK_RATE = 1.7			; number of sectors per second for playback

base_jd = yd2jd( long(base_year)*1000.D0 + long(doy) )

	;
	; single playback script between DOY and (DOY+NUMBERDAYS)
	;
	jd1 = base_jd
	minxss_time_to_sd_offset, hk, jd1, offsets1
	jd2 = base_jd + numberDays
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
	LOGstartSector = offsets1[3]
	LOGstopSector = offsets2[3]
	if ((LOGstopSector-LOGstartSector) gt LOG_NUM_SECTORS) then $
		LOGstopSector = long(LOGstartSector + LOG_NUM_SECTORS)
	LOGtime = (LOGstopSector-LOGstartSector) / PLAYBACK_RATE / 60.
	print, ' '
	print, 'DOY PLAYBACK SCRIPT'
	print, '----------------------------'
	print, 'HK  sectors ', HKstartSector, HKstopSector, HKstepSize
	print, 'LOG  sectors ', LOGstartSector, LOGstopSector, 1L
	print, 'SCI sectors ', SCIstartSector, SCIstopSector, SCIstepSize
	print, 'Playback time = ', string(HKtime + SCItime + HKtime,format='(F5.1)'), ' minutes'
print, ' '

  ;
  ;		Read playback_doy_template SCRIPT file
  ;
  filename = spath_name+'playback_doy_template.prc'
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
  filledscript = strreplace(filledscript, ['<THKstartSector>', '<THKstopSector>', '<THKstepSize>', $
  						'<TLOGstartSector>', '<TLOGstopSector>', '<TLOGstepSize>', $
  						'<TSCIstartSector>', '<TSCIstopSector>', '<TSCIstepSize>'], $
  					strtrim(long([HKstartSector, HKstopSector, HKstepSize, $
  						LOGstartSector, LOGstopSector, 1, $
  						SCIstartSector, SCIstopSector, SCIstepSize]),2))

  date_str = string(long(base_year),format='(I04)') + string(long(doy),format='(I03)') + $
  			'_'+strtrim(long(numberDays),2) + 'days'
  new_file = 'playback_doy_' + date_str + '.prc'
  print, 'Saving New DOY Playback script in ', new_file
  filename = spath_name+new_file
  openw, lun, filename, /get_lun
  printf, lun, filledscript
  close, lun
  free_lun, lun

if keyword_set(debug) then stop, 'DEBUG at end of minxss_doy_playback ...'

end
