;
;	minxss_validate_level2.pro
;
;	Validate minxss Level 2 and Level 3 results
;
;	Tom Woods, 8/18/2022
;
pro minxss_validate_level2, tag_index_in, date, fm=fm, version=version, verbose=verbose, debug=debug

;
;	Check input parameters
;
if keyword_set(fm) then fm_num = fm else fm_num = 1
if (fm_num lt 1) then fm_num = 1
if (fm_num gt 2) then fm_num = 2
fm_str = strtrim(fm_num,2)

if n_params() lt 1 then tag_index_in = 2		; x123_irradiance spectrum
if n_params() lt 2 then date = (fm_num eq 1 ? 2016203L : 2019002L)

if not keyword_set(version) then version = '3.2.0'

if keyword_set(verbose) then VERBOSE=1 else VERBOSE=0
if keyword_set(debug) then VERBOSE=1

;	get minxss L1, L2, and L3 data and store in common block
common minxss_validate, fm_last, minxss_level1_data, minxss1min, minxss1hour, minxss1day
if (fm_last eq !NULL) then fm_last = 0
if (minxss_level1_data eq !NULL) or (fm_last ne fm_num) then begin
	ddir = getenv('minxss_data') + path_sep() + 'fm'+fm_str + path_sep()
	file1='level1'+path_sep()+'minxss'+fm_str+'_l1_mission_length_v'+version+'.sav'
	print, '*** Restoring '+file1
	restore, ddir+file1
	minxss_level1_data = minxsslevel1.x123
	minxsslevel1 = 0  ; clear memory
	file2='level2'+path_sep()+'minxss'+fm_str+'_l2new_1minute_average_mission_length_v'+version+'.sav'
	print, '*** Restoring '+file2
	restore, ddir+file2
	minxss1min = minxsslevel2_x123
	file2='level2'+path_sep()+'minxss'+fm_str+'_l2new_1hour_average_mission_length_v'+version+'.sav'
	print, '*** Restoring '+file2
	restore, ddir+file2
	minxss1hour = minxsslevel2_x123
	file3='level3'+path_sep()+'minxss'+fm_str+'_l3new_1day_average_mission_length_v'+version+'.sav'
	print, '*** Restoring '+file3
	restore, ddir+file3
	minxss1day = minxsslevel3_x123
	minxss_average_data = 0L
	fm_last=fm_num	; remember the FM number
endif

;  get structure info
num_x123 = n_tags(minxss_level1_data[0])
x123_names = tag_names(minxss_level1_data[0])
tag_index = tag_index_in
if (tag_index lt 1) then tag_index = 1L
if (tag_index ge num_x123) then begin
	print, '**** Limit for Tag Index is ', num_x123
	tag_index = num_x123-1L
endif

vartype = size(minxss_level1_data[0].(tag_index), /type)
vardim = size(minxss_level1_data[0].(tag_index), /n_dimensions)
varsize = size(minxss_level1_data[0].(tag_index), /dimensions)

if (VERBOSE EQ 1) then begin
	print, '*** minxss Data Tag Name = ', x123_names[tag_index]
	print, '          Variable Type = ', vartype
	print, '          Variable Dim  = ', vardim
	print, '          Variable Size = ', varsize
endif

;  plot Variable for comparison - either as time series or as spectrum
if (vardim eq 0) then begin
	; plot time series over the mission
	if (VERBOSE EQ 1) then print, '*** Plotting time series'
	setplot & cc=rainbow(7) & dots,/large
	yr = [ min(minxss_level1_data.(tag_index))*0.95, max(minxss_level1_data.(tag_index))*1.05 ]
	if strupcase(x123_names[tag_index]) eq "NUMBER_SPECTRA" then $
		yr = [ 0, max(minxss1day.(tag_index))*1.05 ]
	if strupcase(strmid(x123_names[tag_index],0,4)) eq "TIME" then $
		yr = [ min(minxss_level1_data.(tag_index))*0.995, max(minxss_level1_data.(tag_index))*1.005 ]
	plot, minxss_level1_data.time.jd, minxss_level1_data.(tag_index), $
			psym=8, yrange=yr, ys=1, ytitle=strtrim(tag_index,2)+": "+x123_names[tag_index], $
			title="L1=black, 1min=red, 1hour=gold, 1day=green", $
			XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
	oplot, minxss1min.time.jd, minxss1min.(tag_index), psym=4, color=cc[0]
	oplot, minxss1hour.time.jd, minxss1hour.(tag_index), psym=5, color=cc[1]
	oplot, minxss1day.time.jd, minxss1day.(tag_index), psym=6, color=cc[3]

endif else if (vardim eq 1) then begin
	; plot spectra for single day
	if (VERBOSE EQ 1) then print, '*** Plotting spectra'
	setplot & cc=rainbow(7) & dots,/large
	temp=min(abs(minxss_level1_data.time.yyyydoy-(date+0.5)),wmin)
	theYD = long(minxss_level1_data[wmin].time.yyyydoy)
	wgd1 = where((minxss_level1_data.time.yyyydoy ge (theYD-0.1)) AND (minxss_level1_data.time.yyyydoy le (theYD+1.1)), numgd1 )
	wgd1day = where((minxss1day.time.yyyydoy ge (theYD-0.1)) AND (minxss1day.time.yyyydoy le (theYD+1.1)), numgd1day )
	yr = [ 0, max(minxss_level1_data[wgd1].(tag_index))*1.2 ]
	if strupcase(x123_names[tag_index ]) eq "SPECTRUM_CPS_STDDEV" then $
		yr = [ 0, max(minxss1day[wgd1day].(tag_index))*1.2 ]
	energy = minxss_level1_data[0].energy
	xr = [0,4]
	plot, energy, minxss_level1_data[wgd1[0]].(tag_index), psym=10, xr=xr, xs=1, xtitle='Energy', $
		yr=yr, ys=1, ytitle=strtrim(tag_index,2)+": "+x123_names[tag_index], $
		title=strtrim(theYD,2)+": L1=black, 1min=red, 1hour=gold, 1day=green"
	for k=1,numgd1-1 do oplot, energy, minxss_level1_data[wgd1[k]].(tag_index), psym=10
	wgd2 = where((minxss1min.time.yyyydoy ge (theYD-0.1)) AND (minxss1min.time.yyyydoy le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, minxss1min[wgd2[k]].(tag_index), psym=10, color=cc[0]
	wgd2 = where((minxss1hour.time.yyyydoy ge (theYD-0.1)) AND (minxss1hour.time.yyyydoy le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, minxss1hour[wgd2[k]].(tag_index), psym=10, color=cc[1]
	wgd2 = where((minxss1day.time.yyyydoy ge (theYD-0.1)) AND (minxss1day.time.yyyydoy le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, minxss1day[wgd2[k]].(tag_index), psym=10, line=2, color=cc[3]

endif else begin
	stop, '**** ERROR - unable to plot images...'
endelse

if keyword_set(debug) then stop, 'DEBUG at end of minxss_validate_level2.pro ... '

return
end
