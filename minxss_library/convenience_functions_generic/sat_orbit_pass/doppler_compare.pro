;
;	doppler_compare.pro
;
;	Compare Doppler test data to Doppler predictions for set of objects (TLEs)
;
;	INPUT
;		data_file	string for data file with date/time and Doppler frequency shifts
;						(the file is read by read_dat.pro)
;		station		Station name ('Boulder', 'Fairbanks', or 'Parker')
;		object_set	Set of Satellite Objects to overplot their Doppler predictions
;						(this reads location_xxxx.sav files from satellite_pass.pro)
;		file_base	File name base for the Location Save set files for object_set
;		sat_name	Satellite Name (defaults to 'MinXSS-2')
;		sat_freq	Satellite Frequency (defaults to 437250 kHz)
;		/no_offset	Do not do correction of measured Doppler shift to better "zero"
;		/narrow		Make plot more narrow for zero crossing
;		/eps		Make EPS graphics file
;		/verbose	Print messages
;		/debug		Debug at end stop statement
;
;	OUTPUT
;		Plot is made showing doppler frequency
;
;	Tom Woods, 12/30/2018
;
pro doppler_compare, data_file, station, object_set, file_base=file_base, sat_name=sat_name, $
						no_offset=no_offset, narrow=narrow, eps=eps, verbose=verbose, debug=debug

if (n_params() lt 1) then begin
	print, 'USAGE: doppler_compare, data, station, object_set'
	return
endif

if (n_params() lt 2) then begin
	station = 'Fairbanks'
endif
station_caps = strupcase(station)
if (strlen(station_caps) lt 1) then begin
	print, 'ERROR: valid station name is needed to run doppler_compare.pro !'
	return
endif

if (n_params() lt 3) then begin
  object_set = [ '2018-099A', '2018-099BB', '2018-099BL', '2018-099BN', '2018-099BM' ]
endif
num_sat = n_elements(object_set)

if keyword_set(file_base) then begin
	file_name_base = file_base
endif else begin
	file_name_base = 'location_doppler1_'
endelse

if not keyword_set(sat_name) then sat_name = 'MinXSS-2'

if not keyword_set(sat_freq) then sat_freq = 437250.0   ; MinXSS-2 and CSIM frequency

if keyword_set(debug) then verbose=1

;   configure directory based on station value
;	Set TLE path
;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then slash = '\' else slash = '/'
path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then begin
	; check if need to remove end of string back slash
	spos = strpos(path_name, slash, /reverse_search )
	slen = strlen(path_name)
	if (spos eq (slen-1)) then path_name = strmid( path_name, 0, slen-1 )
endif
path_name += slash + station_caps + slash
if keyword_set(verbose) then print, '*** TLE path = ', path_name

;
;	Read the Data File
;		Expect to have 5 columns of data
;		Column 0:	YYYYDOY
;		Column 1:	HH
;		Column 2:	MM
;		Column 3: 	SS
;		Column 4:	Doppler Frequency Shift in kHz
data_file_full = path_name + data_file
if strpos( data_file, slash, /reverse_search ) ge 0 then data_file_full = data_file
if keyword_set(verbose) then print, '*** Reading Data File = ', data_file_full
data = read_dat( data_file_full )

;
;	Process the data to make JD time
;
data_yd = reform(data[0,*] + data[1,*]/24. + data[2,*]/(24.*60.) + $
				data[3,*]/(24.*3600.))
data_jd = yd2jd( data_yd )
jd_offset = 1./(24.*60.)  ; 1 min offset
jd_min = min(data_jd)-jd_offset & jd_max = max(data_jd)+jd_offset
date_str = strtrim(string(long(data_yd[0])),2)

data_doppler = reform(data[4,*])
if not keyword_set(no_offset) then begin
  meas_offset = (max(data_doppler) + min(data_doppler))/2.
  data_doppler_org = data_doppler
  data_doppler -= meas_offset
  print, '*** Measured Offset = ', meas_offset, ' kHz'
endif

;  magnify plot crossing zero
yrange=[-12,12]
if keyword_set(narrow) then begin
	wnarrow = where( abs(data_doppler) lt 5., num_narrow )
	if (num_narrow gt 3) then begin
		jd_min = min(data_jd[wnarrow])-jd_offset
		jd_max = max(data_jd[wnarrow])+jd_offset
		yrange=[-8,8]
	endif
endif

;
;	plot Doppler data
;
if keyword_set(eps) then begin
	efile = sat_name + '_' + date_str + '_doppler_compare'
	if keyword_set(narrow) then efile += '_narrow'
	efile += '.eps'
	print, '*** Writing graphics to ', path_name + efile
	eps2_p, path_name + efile
endif

setplot
cs = 2.0
num_colors = (num_sat+1) > 7
ccol = rainbow(num_colors)

my_date = LABEL_DATE( DATE_FORMAT=[ "%H:%I:%S" ] )

plot, data_jd, data_doppler, psym=-4, xrange=[jd_min,jd_max], xs=1, yrange=yrange, ys=1, $
		xtitle='Time on '+date_str, ytitle='Doppler Shift (kHz)', title=sat_name, $
		XTICKFORMAT = 'LABEL_DATE'

;
;	Read the satellite location data files to get their predicted Doppler velocities
;   frequency doppler shift =  -1. * frequency_base * velocity_m_per_s / speed_of_light
;
xx = jd_min + (jd_max-jd_min)*0.05
dy = (!y.crange[1]-!y.crange[0])/12.
yy = !y.crange[1] - 4*dy
speed_of_light = 2.998D5  ; km/sec
for ii=0,num_sat-1 do begin
	sat_file = file_name_base + object_set[ii] + '.sav'
	if keyword_set(verbose) then print, '*** Reading Satellite File = ', path_name + sat_file
	restore, path_name + sat_file
	sat_jd = location.time_jd
	sat_doppler = -1. * sat_freq * location.doppler_vel / speed_of_light
	oplot, sat_jd, sat_doppler, color=ccol[ii]
	sat_interpol = interpol( sat_doppler, sat_jd, data_jd )
	chi = sqrt( total((data_doppler - sat_interpol)^2. / (sat_interpol > 0.3) ) )
	chi_str = ' ('+strtrim(string(chi,format='(F8.1)'),2)+')'
	if (strpos(chi_str,'NaN') gt 0) then stop, 'DEBUG bad Chi value...'
	xyouts, xx, yy-dy*ii, object_set[ii]+chi_str, charsize=cs, color=ccol[ii]
endfor

if keyword_set(eps) then begin
	send2
endif

if keyword_set(debug) then stop, 'doppler_compare: DEBUG at end ...'
return
end
