;
;	daxss_validate_level2.pro
;
;	Validate DAXSS Level 2 and Level 3 results
;
;	Tom Woods, 8/18/2022
;
pro daxss_validate_level2, tag_index_in, date, verbose=verbose, debug=debug

if n_params() lt 1 then tag_index_in = 5		; x123_irradiance spectrum
if n_params() lt 2 then date = 2022074L

if keyword_set(verbose) then VERBOSE=1 else VERBOSE=0
if keyword_set(debug) then VERBOSE=1

;	get DAXSS L1, L2, and L3 data and store in common block
common daxss_validate, daxss_level1_data, daxss1min, daxss1hour, daxss1day
if daxss_level1_data eq !NULL then begin
	ddir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep()
	file1='level1'+path_sep()+'daxss_l1_mission_length_v2.0.0.sav'
	print, '*** Restoring '+file1
	restore, ddir+file1
	file2='level2'+path_sep()+'daxss_l2new_1minute_average_mission_length_v2.0.0.sav'
	print, '*** Restoring '+file2
	restore, ddir+file2
	daxss1min = daxss_average_data
	file2='level2'+path_sep()+'daxss_l2new_1hour_average_mission_length_v2.0.0.sav'
	print, '*** Restoring '+file2
	restore, ddir+file2
	daxss1hour = daxss_average_data
	file3='level3'+path_sep()+'daxss_l3new_1day_average_mission_length_v2.0.0.sav'
	print, '*** Restoring '+file3
	restore, ddir+file3
	daxss1day = daxss_average_data
	daxss_average_data = 0L
endif

;  get structure info
num_x123 = n_tags(daxss_level1_data[0])
x123_names = tag_names(daxss_level1_data[0])
tag_index = tag_index_in
if (tag_index lt 0) then tag_index = 0L
if (tag_index ge num_x123) then begin
	print, '**** Limit for Tag Index is ', num_x123
	tag_index = num_x123-1L
endif

vartype = size(daxss_level1_data[0].(tag_index), /type)
vardim = size(daxss_level1_data[0].(tag_index), /n_dimensions)
varsize = size(daxss_level1_data[0].(tag_index), /dimensions)

if (VERBOSE EQ 1) then begin
	print, '*** DAXSS Data Tag Name = ', x123_names[tag_index]
	print, '          Variable Type = ', vartype
	print, '          Variable Dim  = ', vardim
	print, '          Variable Size = ', varsize
endif

;  plot Variable for comparison - either as time series or as spectrum
if (vardim eq 0) then begin
	; plot time series over the mission
	if (VERBOSE EQ 1) then print, '*** Plotting time series'
	setplot & cc=rainbow(7) & dots,/large
	yr = [ min(daxss_level1_data.(tag_index))*0.95, max(daxss_level1_data.(tag_index))*1.05 ]
	if strupcase(x123_names[tag_index]) eq "NUMBER_SPECTRA" then $
		yr = [ 0, max(daxss1day.(tag_index))*1.05 ]
	if strupcase(strmid(x123_names[tag_index],0,4)) eq "TIME" then $
		yr = [ min(daxss_level1_data.(tag_index))*0.995, max(daxss_level1_data.(tag_index))*1.005 ]
	plot, daxss_level1_data.time_jd, daxss_level1_data.(tag_index), $
			psym=8, yrange=yr, ys=1, ytitle=strtrim(tag_index,2)+": "+x123_names[tag_index], $
			title="L1=black, 1min=red, 1hour=gold, 1day=green", $
			XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
	oplot, daxss1min.time_jd, daxss1min.(tag_index), psym=4, color=cc[0]
	oplot, daxss1hour.time_jd, daxss1hour.(tag_index), psym=5, color=cc[1]
	oplot, daxss1day.time_jd, daxss1day.(tag_index), psym=6, color=cc[3]

endif else if (vardim eq 1) then begin
	; plot spectra for single day
	if (VERBOSE EQ 1) then print, '*** Plotting spectra'
	setplot & cc=rainbow(7) & dots,/large
	temp=min(abs(daxss_level1_data.time_yd-(date+0.5)),wmin)
	theYD = long(daxss_level1_data[wmin].time_yd)
	wgd1 = where((daxss_level1_data.time_yd ge (theYD-0.1)) AND (daxss_level1_data.time_yd le (theYD+1.1)), numgd1 )
	wgd1day = where((daxss1day.time_yd ge (theYD-0.1)) AND (daxss1day.time_yd le (theYD+1.1)), numgd1day )
	yr = [ 0, max(daxss_level1_data[wgd1].(tag_index))*1.2 ]
	if strupcase(x123_names[tag_index ]) eq "SPECTRUM_CPS_STDDEV" then $
		yr = [ 0, max(daxss1day[wgd1day].(tag_index))*1.2 ]
	energy = daxss_level1_data[0].energy
	xr = [0,4]
	plot, energy, daxss_level1_data[wgd1[0]].(tag_index), psym=10, xr=xr, xs=1, xtitle='Energy', $
		yr=yr, ys=1, ytitle=strtrim(tag_index,2)+": "+x123_names[tag_index], $
		title=strtrim(theYD,2)+": L1=black, 1min=red, 1hour=gold, 1day=green"
	for k=1,numgd1-1 do oplot, energy, daxss_level1_data[wgd1[k]].(tag_index), psym=10
	wgd2 = where((daxss1min.time_yd ge (theYD-0.1)) AND (daxss1min.time_yd le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, daxss1min[wgd2[k]].(tag_index), psym=10, color=cc[0]
	wgd2 = where((daxss1hour.time_yd ge (theYD-0.1)) AND (daxss1hour.time_yd le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, daxss1hour[wgd2[k]].(tag_index), psym=10, color=cc[1]
	wgd2 = where((daxss1day.time_yd ge (theYD-0.1)) AND (daxss1day.time_yd le (theYD+1.1)), numgd2 )
	for k=0,numgd2-1 do oplot, energy, daxss1day[wgd2[k]].(tag_index), psym=10, line=2, color=cc[3]

endif else begin
	stop, '**** ERROR - unable to plot images...'
endelse

if keyword_set(debug) then stop, 'DEBUG at end of daxss_validate_level2.pro ... '

return
end
