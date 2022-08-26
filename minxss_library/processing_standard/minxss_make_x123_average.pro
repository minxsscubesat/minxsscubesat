;+
; NAME:
;   minxss_make_x123_average.pro
;
; PURPOSE:
;   Read Level 1 data product and make average data structure to produce Level 2 or 3 product.
;	This only processes the X123 data.
;
; INPUTS:
;   average_minutes		Number of minutes for the average (normally 1-min, 1-hour, 1-day)
;
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 1 or 2 (default is 1)
;   version [string]: Set this to specify a particular level 1 file to restore for filtering.
;                     Defaults to '' (nothing), which is intended for situations where you've
;                     just processed level 1 but didn't specify `version` in your call to minxss_make_level1.
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   None			Level 2 and 3 files are stored though
;
; OPTIONAL OUTPUTS
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires minxss_find_files.pro
;   Requires minxss_filename_parts.pro
;   Requires minxss_average_packets.pro
;   Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Call minxss_make_level1_average for each time average desired (1 minute, 1 hour)
;   2. Move the files it generates to the Level 2 folder
;+
pro minxss_make_x123_average, average_minutes, fm=fm, version=version, VERBOSE=VERBOSE, DEBUG=DEBUG

if n_params() lt 1 then begin
	print, 'USAGE:  minxss_make_x123_average, average_minutes, fm=fm, version=version, /VERBOSE'
	return
endif

; Defaults and validity checks - average_minutes, fm, version
average_minutes = long(average_minutes)
if (average_minutes lt 1) then average_minutes = 1L
if (average_minutes gt (24L*60L)) then average_minutes = 24L*60L

if keyword_set(DEBUG) then VERBOSE = 1

IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  message, /INFO, JPMsystime() + "ERROR: need a valid 'fm' value. FM can be 1 or 2."
  return
endif
fm_str = strtrim(fm,2)

IF version EQ !NULL THEN version = '4.0.0'
IF ~isA(version, 'string') THEN BEGIN
  message, /INFO, JPMsystime() + " ERROR: version input must be a string"
  return
ENDIF

;
;	read the Level 1 file
;		minxsslevel1.x123 and minxsslevel1.x123_meta are the only items kept
;
version1=version
if (version eq '4.0.0') then version1 = '3.2.0'
ddir1 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level1' + path_sep()
file1 = 'minxss' + fm_str + '_l1_mission_length_v' + version1 + '.sav'
if keyword_set(VERBOSE) then message, /INFO, 'Reading MinXSS Level-1 file '+ddir1+file1
restore, ddir1+file1

; stop, 'DEBUG Version number in Level 1...'
if (version1 ne version) then minxsslevel1.x123_meta.version = version

;
;	read the GOES XRS data:  GOES data will be added to the Level 2/3 product
;
goesdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
goesfilebase = 'goes_1mdata_widx_'
year1 = long(min(minxsslevel1.x123.time.yyyydoy)/1000.)
year2 = long(max(minxsslevel1.x123.time.yyyydoy)/1000.)
for year=year1,year2 do begin
	goesfile = goesfilebase + strtrim(year,2) + '.sav'
	; goes  data structure:  goes.time = GPS seconds, goes.short = XRS-A, goes.long = XRS-B
	if keyword_set(VERBOSE) then message, /INFO, 'Reading GOES file '+goesdir+goesfile
	restore, goesdir + goesfile
	if (year eq year1) then goes_all = goes $
	else goes_all = [ goes_all, goes ]
endfor
goes = 0  ; zero out that large variable

;
;	make the averages on a wall-clock boundary
;		First find the data that will fit into each bin
;		Then make the minxsslevel2 product
;		And make the data averages
;
jd1 = min(minxsslevel1.x123.time.jd)
jd2 = max(minxsslevel1.x123.time.jd)
day1 = long(jd1) - 1L & day2 = long(jd2) + 1L
num_bins = long( (day2 - day1 + 2L)*24.D0*60. / average_minutes )
bin_step = average_minutes / (24.D0*60.)  ; convert average_minutes to fraction of day
bin_start = dblarr(num_bins)
bin_valid = lonarr(num_bins)
num10 = num_bins / 10L

if keyword_set(VERBOSE) then message, /INFO, 'Checking for '+strtrim(num_bins,2)+' time intervals for MinXSS-'+fm_str

;  force each step to be consistent from day to day
bins_per_day = long(1.000001D0/bin_step)
for ii=day1,day2 do begin
	k1 = (ii-day1)*bins_per_day
	k2 = k1 + bins_per_day - 1
	bin_start[k1:k2] = (ii + 0.5D0) + findgen(bins_per_day) * bin_step
endfor

; check if there is any data for each time bin
for ii=0L,num_bins-2 do begin
	if keyword_set(VERBOSE) and ((ii mod num10) eq 0) and (ii ne 0) and (average_minutes le 60) then $
		print, '   ... at ',long((ii*100.)/num_bins), '% checked.'
	wgd = where( minxsslevel1.x123.time.jd ge bin_start[ii] AND minxsslevel1.x123.time.jd lt bin_start[ii+1], numgd)
	if (numgd ge 1) then bin_valid[ii] = 1L
endfor

num_good = long(total(bin_valid))
if keyword_set(VERBOSE) then message, /INFO, 'Processing '+strtrim(num_good,2)+' averages for MinXSS-'+fm_str

;
;	make the level2 data product
;
minxsslevel2_x123 = replicate( minxsslevel1.x123[0], num_good )
minxsslevel2_x123_meta = minxsslevel1.x123_meta  ; string array
nominal_jd = dblarr(num_good)

;
;	do the averages now
;
k = 0L  ; index for minxsslevel2_x123
good_types = [1, 2, 3, 4, 5, 6, 9, 12, 13, 14, 15]
x123_names = tag_names(minxsslevel1.x123[0])
num_time = n_tags(minxsslevel1.x123[0].time)
num_x123 = n_tags(minxsslevel1.x123[0])
num10 = num_bins / 10L

for ii=0L,num_bins-2 do begin
	if keyword_set(VERBOSE) and ((ii mod num10) eq 0) and (ii ne 0) then $
		print, '   ... at ',long(((ii+1)*100.)/num_bins), '% processed.'
	wgd = where( minxsslevel1.x123.time.jd ge bin_start[ii] AND minxsslevel1.x123.time.jd lt bin_start[ii+1], numgd)
	if (numgd ge 1) then begin
		if numgd eq 1 then begin
			minxsslevel2_x123[k] = minxsslevel1.x123[wgd[0]]  ; no averaging required
		endif else begin
			; average the TIME structure first using the mean of JD time
			minxsslevel2_x123[k].time.spacecraftgpsformat = mean(minxsslevel1.x123[wgd].time.spacecraftgpsformat,/NAN)
			minxsslevel2_x123[k].time.tai = mean(minxsslevel1.x123[wgd].time.tai,/NAN)
			minxsslevel2_x123[k].time.jd = mean(minxsslevel1.x123[wgd].time.jd,/NAN)
			theISO = jpmjd2iso( minxsslevel2_x123[k].time.jd )
			minxsslevel2_x123[k].time.iso = theISO
			theHuman = theISO
			theHuman = theHuman.replace('T', ' ')
    		theHuman = theHuman.replace('Z', '')
			minxsslevel2_x123[k].time.human = theHuman
			tPos = strpos( theISO, 'T' )
			minxsslevel2_x123[k].time.hhmmss = strmid(theISO, tPos+1, 8 )
			minxsslevel2_x123[k].time.yyyymmdd = jpmjd2yyyymmdd( minxsslevel2_x123[k].time.jd )
			minxsslevel2_x123[k].time.yyyydoy = jpmjd2yyyydoy( minxsslevel2_x123[k].time.jd )
			minxsslevel2_x123[k].time.sod = jpmjd2sod( minxsslevel2_x123[k].time.jd )
			minxsslevel2_x123[k].time.fod = minxsslevel2_x123[k].time.sod / (24.D0*3600.)
			;
			;  original way gives confusing results for time average results
			;for n=0L,num_time-1L do begin
			;	vartype = size(minxsslevel1.x123[0].time.(n), /type)
			;	wmatch = where( good_types eq vartype, num_match )
			;	if (num_match ge 1) then begin
			;		minxsslevel2_x123[k].time.(n) = mean(minxsslevel1.x123[wgd].time.(n),/NAN)
			;	endif else begin
			;		; just copy first instance if can not make an average
			;		minxsslevel2_x123[k].time.(n) = minxsslevel1.x123[wgd[0]].time.(n)
			;	endelse
			;endfor
			;
			; average the other data arrays - skip the TIME structure at tag #0
			; averages have to avoid NaN values, so use the /NAN option for mean(), stddev() and total()
			for n=1L,num_x123-1L do begin
			  vartype = size(minxsslevel1.x123[0].(n), /type)
			  vardim = size(minxsslevel1.x123[0].(n), /n_dimensions)
			  varsize = size(minxsslevel1.x123[0].(n), /dimensions)
			  wmatch = where( good_types eq vartype, num_match )
			  if (num_match ge 1) then begin
				;  special updates for the energy, number_spectra, spectrum_cps_precision, spectrum_cps_stddev,
				;		spectrum_total_counts, spectrum_total_counts_accuracy, spectrum_total_counts_precision,
				;		valid_flag, and sps_on
			  	if (x123_names[n] eq 'ENERGY') then begin
			  		; store the first instance only so that energy[] values stay the same
			  		minxsslevel2_x123[k].(n) = minxsslevel1.x123[wgd[0]].(n)
			  	endif else if (x123_names[n] eq 'NUMBER_SPECTRA') then begin
			  		; store the numgd value only
			  		minxsslevel2_x123[k].(n) = numgd
			  	endif else if (x123_names[n] eq 'SPECTRUM_CPS_PRECISION') then begin
			  		; Precision is improved by sqrt(numgd)
			  		minxsslevel2_x123[k].(n) = mean(minxsslevel1.x123[wgd].(n),dim=2,/NAN) / sqrt(float(numgd))
			  	endif else if (x123_names[n] eq 'SPECTRUM_CPS_STDDEV') then begin
			  		; STDDEV is called instead of MEAN
			  		minxsslevel2_x123[k].(n) = stddev(minxsslevel1.x123[wgd].spectrum_cps,dim=2,/NAN)
			  	endif else if (x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS') OR $
			  					(x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS_ACCURACY') then begin
			  		; Just do total (not mean)
			  		minxsslevel2_x123[k].(n) = total(minxsslevel1.x123[wgd].spectrum_cps,2,/NAN)
			  	endif else if (x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS_PRECISION') then begin
			  		; Precision is total and then divided by sqrt(numgd)
			  		minxsslevel2_x123[k].(n) = total(minxsslevel1.x123[wgd].(n),2,/NAN) / sqrt(float(numgd))
			  	endif else if (x123_names[n] eq 'VALID_FLAG') then begin
			  		; Force > 0 values to be 1.0
			  		minxsslevel2_x123[k].(n) = mean(minxsslevel1.x123[wgd].(n),dim=2,/NAN)
			  		wpos = where(minxsslevel2_x123[k].(n) gt 0.0, numpos)
			  		if (numpos ge 1) then minxsslevel2_x123[k].(n)[wpos] = 1
			  	endif else if (x123_names[n] eq 'SPS_ON') then begin
			  		; Force > 0 values to be 1.0
			  		temp_sps_on = mean(minxsslevel1.x123[wgd].(n),/NAN)
			  		wpos = where(temp_sps_on gt 0.0, numpos)
			  		if (numpos ge 1) then temp_sps_on[wpos] = 1
			  		minxsslevel2_x123[k].(n) = fix(temp_sps_on)
			  	endif else begin
					if (vardim eq 0) then begin
						minxsslevel2_x123[k].(n) = mean(minxsslevel1.x123[wgd].(n),/NAN)
					endif else if (vardim eq 1) then begin
						minxsslevel2_x123[k].(n) = mean(minxsslevel1.x123[wgd].(n),dim=2,/NAN)
					endif else print, 'WARNING: can not average 3-D data for tag number ', n
				endelse
			  endif else begin
					; just copy first instance if can not make an average
					minxsslevel2_x123[k].(n) = minxsslevel1.x123[wgd[0]].(n)
			  endelse
			endfor
		endelse
		nominal_jd[k] = bin_start[ii] + (average_minutes/2.)/(24.D0*60.)
		k += 1L   ; Increment for the next record
	endif
endfor

if (k ne num_good) then stop, 'STOPPED:  error in getting the right number of bins for averages !!!'

;
;	add the Nominal "start" time and GOES X-ray values for each X123 measurement
;
if keyword_set(VERBOSE) then message, /INFO, 'Averages are done, now adding GOES values.'
minxsslevel2_x123 = JPMAddTagsToStructure(minxsslevel2_x123, 'NOMINAL_TIME_JD', 'double', $
						insertIndex = num_x123)
minxsslevel2_x123.nominal_time_jd = nominal_jd
minxsslevel2_x123 = JPMAddTagsToStructure(minxsslevel2_x123, 'NOMINAL_TIME_YYYYDOY', 'double', $
						insertIndex = num_x123+1)
minxsslevel2_x123.nominal_time_yyyydoy = jd2yd(nominal_jd)
minxsslevel2_x123 = JPMAddTagsToStructure(minxsslevel2_x123, 'GOES_XRSA', 'float', $
						insertIndex = num_x123+2)
minxsslevel2_x123 = JPMAddTagsToStructure(minxsslevel2_x123, 'GOES_XRSB', 'float', $
						insertIndex = num_x123+3)
goes_jd = gps2jd(goes_all.time)
minxsslevel2_x123.goes_xrsa = interpol( goes_all.short, goes_jd, nominal_jd )
minxsslevel2_x123.goes_xrsb = interpol( goes_all.long, goes_jd, nominal_jd )

;
;  add more to the META structure
;
num_meta = n_tags(minxsslevel2_x123_meta)
avg_min_str = strtrim(average_minutes,2) + '-minute' + (average_minutes le 1? '': 's')
if (average_minutes ge (24L*60L)) then avg_min_str='1-day'
minxsslevel2_x123_meta = JPMAddTagsToStructure(minxsslevel2_x123_meta, 'NOMINAL_TIME_JD', 'string', $
						insertIndex = num_meta)
minxsslevel2_x123_meta.nominal_time_jd = 'Nominal Time for '+avg_min_str+' Average in JD format'
minxsslevel2_x123_meta = JPMAddTagsToStructure(minxsslevel2_x123_meta, 'NOMINAL_TIME_YYYYDOY', 'string', $
						insertIndex = num_meta+1)
minxsslevel2_x123_meta.nominal_time_yyyydoy = 'Nominal Time for '+avg_min_str+' Average in YYYYDOY format'
minxsslevel2_x123_meta = JPMAddTagsToStructure(minxsslevel2_x123_meta, 'GOES_XRSA', 'string', $
						insertIndex = num_meta+2)
minxsslevel2_x123_meta.goes_xrsa = 'GOES XRS-A Irradiance for nominal time of average'
minxsslevel2_x123_meta = JPMAddTagsToStructure(minxsslevel2_x123_meta, 'GOES_XRSB', 'string', $
						insertIndex = num_meta+3)
minxsslevel2_x123_meta.goes_xrsb = 'GOES XRS-B Irradiance for nominal time of average'

;
;	Save the Level 2/3 file
;
version_out = version
if (average_minutes eq (24.*60.)) then begin
	ddir3 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level3' + path_sep()
	file3 = 'minxss' + fm_str + '_l3new_1day_average_mission_length_v' + version_out + '.sav'
	if keyword_set(VERBOSE) then message, /INFO, 'Saving Level 3 data product in '+ddir3+file3
	minxsslevel3_x123 = minxsslevel2_x123
	minxsslevel3_x123_meta = minxsslevel2_x123_meta
	minxsslevel2_x123 = 0
	save, minxsslevel3_x123, minxsslevel3_x123_meta, file=ddir3+file3
endif else begin
	min_str = strtrim(long(average_minutes),2) + 'minutes'
	if (average_minutes eq 1) then min_str = '1minute'
	if (average_minutes eq 60) then min_str = '1hour'
	ddir2 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level2' + path_sep()
	file2 = 'minxss' + fm_str + '_l2new_'+min_str+'_average_mission_length_v' + version_out + '.sav'
	if keyword_set(VERBOSE) then message, /INFO, 'Saving Level 2 data product in '+ddir2+file2
	save, minxsslevel2_x123, minxsslevel2_x123_meta, file=ddir2+file2
endelse

if keyword_set(DEBUG) then stop, 'STOPPED at end of minxss_make_x123_average.pro ...'
return
end
