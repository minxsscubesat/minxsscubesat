;+
; NAME:
;   daxss_make_x123_average.pro
;
; PURPOSE:
;   Read Level 1 data product and make average data structure to produce Level 2 or 3 product.
;	This only processes the X123 data.
;
; INPUTS:
;   average_minutes		Number of minutes for the average (normally 1-min, 1-hour, 1-day)
;
; OPTIONAL INPUTS:
;   fm [integer]: Flight Model number 3 (default is 3)
;   version [string]: Set this to specify a particular level 1 file to restore for filtering.
;                     Defaults to '' (nothing), which is intended for situations where you've
;                     just processed level 1 but didn't specify `version` in your call to daxss_make_level1.
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
;   Requires daxss_find_files.pro
;   Requires daxss_filename_parts.pro
;   Requires daxss_average_packets.pro
;   Uses the library routines for converting time (GPS seconds, Julian date, etc.)
;
; PROCEDURE:
;   1. Call daxss_make_level1_average for each time average desired (1 minute, 1 hour)
;   2. Move the files it generates to the Level 2 folder
;+
pro daxss_make_x123_average, average_minutes, fm=fm, version=version, VERBOSE=VERBOSE, DEBUG=DEBUG

if n_params() lt 1 then begin
	print, 'USAGE:  daxss_make_x123_average, average_minutes, fm=fm, version=version, /VERBOSE'
	return
endif

; Defaults and validity checks - average_minutes, fm, version
average_minutes = long(average_minutes)
if (average_minutes lt 1) then average_minutes = 1L
if (average_minutes gt (24L*60L)) then average_minutes = 24L*60L

if keyword_set(DEBUG) then VERBOSE = 1

IF fm EQ !NULL THEN fm = 3
if (fm gt 3) or (fm lt 3) then begin
  message, /INFO, JPMsystime() + "ERROR: Forcing FM can be 3."
  fm=3
endif
fm_str = strtrim(fm,2)

IF version EQ !NULL THEN version = '2.0.0'
IF ~isA(version, 'string') THEN BEGIN
  message, /INFO, JPMsystime() + " ERROR: version input must be a string"
  return
ENDIF

;
;	read the Level 1 file
;		daxss_level1_data and daxss_level1_meta are in the L1 product
;
ddir1 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level1' + path_sep()
file1 = 'daxss' + '_l1_mission_length_v' + version + '.sav'
if keyword_set(VERBOSE) then message, /INFO, 'Reading daxss Level-1 file '+ddir1+file1
restore, ddir1+file1

;
;	read the GOES XRS data:  GOES data will be added to the Level 2/3 product
;
goesdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
goesfilebase = 'goes_1mdata_widx_'
year1 = long(min(daxss_level1_data.time_yd)/1000.)
year2 = long(max(daxss_level1_data.time_yd)/1000.)
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
;		Then make the daxsslevel2 product
;		And make the data averages
;
jd1 = min(daxss_level1_data.time_jd)
jd2 = max(daxss_level1_data.time_jd)
day1 = long(jd1) - 1L & day2 = long(jd2) + 1L
num_bins = long( (day2 - day1 + 2L)*24.D0*60. / average_minutes )
bin_step = average_minutes / (24.D0*60.)  ; convert average_minutes to fraction of day
bin_start = dblarr(num_bins)
bin_valid = lonarr(num_bins)
num10 = num_bins / 10L

if keyword_set(VERBOSE) then message, /INFO, 'Checking for '+strtrim(num_bins,2)+' time intervals for DAXSS'

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
	wgd = where( daxss_level1_data.time_jd ge bin_start[ii] AND daxss_level1_data.time_jd lt bin_start[ii+1], numgd)
	if (numgd ge 1) then bin_valid[ii] = 1L
endfor

num_good = long(total(bin_valid))
if keyword_set(VERBOSE) then message, /INFO, 'Processing '+strtrim(num_good,2)+' averages for DAXSS'

;
;	make the level2 data product
;
daxss_average_data = replicate( daxss_level1_data[0], num_good )
daxss_average_meta = daxss_level1_meta  ; string array
nominal_jd = dblarr(num_good)

;
;	do the averages now
;
k = 0L  ; index for daxss_average_data
good_types = [1, 2, 3, 4, 5, 6, 9, 12, 13, 14, 15]
x123_names = tag_names(daxss_level1_data[0])
num_x123 = n_tags(daxss_level1_data[0])
num10 = num_bins / 10L

for ii=0L,num_bins-2 do begin
	if keyword_set(VERBOSE) and ((ii mod num10) eq 0) and (ii ne 0) then $
		print, '   ... at ',long(((ii+1)*100.)/num_bins), '% processed.'
	wgd = where( daxss_level1_data.time_jd ge bin_start[ii] AND daxss_level1_data.time_jd lt bin_start[ii+1], numgd)
	if (numgd ge 1) then begin
		if numgd eq 1 then begin
			daxss_average_data[k] = daxss_level1_data[wgd[0]]  ; no averaging required
		endif else begin
			; DAXSS does not have the TIME structure, so normal data array averaging possible
			; (MINXSS code) daxss_average_data[k].time.spacecraftgpsformat = mean(daxss_level1_data[wgd].time.spacecraftgpsformat,/NAN)
			; (MINXSS code) daxss_average_data[k].time.tai = mean(daxss_level1_data[wgd].time.tai,/NAN)
			; (MINXSS code) daxss_average_data[k].time_jd = mean(daxss_level1_data[wgd].time_jd,/NAN)
			; (MINXSS code) theISO = jpmjd2iso( daxss_average_data[k].time_jd )
			; (MINXSS code) daxss_average_data[k].time.iso = theISO
			; (MINXSS code) theHuman = theISO
			; (MINXSS code) theHuman = theHuman.replace('T', ' ')
    		; (MINXSS code) theHuman = theHuman.replace('Z', '')
			; (MINXSS code) daxss_average_data[k].time.human = theHuman
			; (MINXSS code) tPos = strpos( theISO, 'T' )
			; (MINXSS code) daxss_average_data[k].time.hhmmss = strmid(theISO, tPos+1, 8 )
			; (MINXSS code) daxss_average_data[k].time.yyyymmdd = jpmjd2yyyymmdd( daxss_average_data[k].time_jd )
			; (MINXSS code) daxss_average_data[k].time.yyyydoy = jpmjd2yyyydoy( daxss_average_data[k].time_jd )
			; (MINXSS code) daxss_average_data[k].time.sod = jpmjd2sod( daxss_average_data[k].time_jd )
			; (MINXSS code) daxss_average_data[k].time.fod = daxss_average_data[k].time.sod / (24.D0*3600.)
			;
			; average the other data arrays - unlike MinXSS, don't skip tag #0 (Minxss.time structure)
			; averages have to avoid NaN values, so use the /NAN option for mean(), stddev() and total()
			for n=0L,num_x123-1L do begin
			  vartype = size(daxss_level1_data[0].(n), /type)
			  vardim = size(daxss_level1_data[0].(n), /n_dimensions)
			  varsize = size(daxss_level1_data[0].(n), /dimensions)
			  wmatch = where( good_types eq vartype, num_match )
			  if (num_match ge 1) then begin
				;  special updates for the energy, number_spectra, spectrum_cps_precision, spectrum_cps_stddev,
				;		spectrum_total_counts, spectrum_total_counts_accuracy, spectrum_total_counts_precision,
				;		valid_flag, and sps_on
			  	if (x123_names[n] eq 'ENERGY') then begin
			  		; store the first instance only so that energy[] values stay the same
			  		daxss_average_data[k].(n) = daxss_level1_data[wgd[0]].(n)
			  	endif else if (x123_names[n] eq 'NUMBER_SPECTRA') then begin
			  		; store the numgd value only
			  		daxss_average_data[k].(n) = numgd
			  	endif else if (x123_names[n] eq 'SPECTRUM_CPS_PRECISION') then begin
			  		; Precision is improved by sqrt(numgd)
			  		daxss_average_data[k].(n) = mean(daxss_level1_data[wgd].(n),dim=2,/NAN) / sqrt(float(numgd))
			  	endif else if (x123_names[n] eq 'SPECTRUM_CPS_STDDEV') then begin
			  		; STDDEV is called instead of MEAN
			  		daxss_average_data[k].(n) = stddev(daxss_level1_data[wgd].spectrum_cps,dim=2,/NAN)
			  	endif else if (x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS') OR $
			  					(x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS_ACCURACY') then begin
			  		; Just do total (not mean)
			  		daxss_average_data[k].(n) = total(daxss_level1_data[wgd].spectrum_cps,2,/NAN)
			  	endif else if (x123_names[n] eq 'SPECTRUM_TOTAL_COUNTS_PRECISION') then begin
			  		; Precision is total and then divided by sqrt(numgd)
			  		daxss_average_data[k].(n) = total(daxss_level1_data[wgd].(n),2,/NAN) / sqrt(float(numgd))
			  	endif else if (x123_names[n] eq 'VALID_FLAG') then begin
			  		; Force > 0 values to be 1.0
			  		daxss_average_data[k].(n) = mean(daxss_level1_data[wgd].(n),dim=2,/NAN)
			  		wpos = where(daxss_average_data[k].(n) gt 0.0, numpos)
			  		if (numpos ge 1) then daxss_average_data[k].(n)[wpos] = 1
			  	endif else if (x123_names[n] eq 'SPS_ON') then begin
			  		; Force > 0 values to be 1.0
			  		temp_sps_on = mean(daxss_level1_data[wgd].(n),/NAN)
			  		wpos = where(temp_sps_on gt 0.0, numpos)
			  		if (numpos ge 1) then temp_sps_on[wpos] = 1
			  		daxss_average_data[k].(n) = fix(temp_sps_on)
			  	endif else begin
					if (vardim eq 0) then begin
						daxss_average_data[k].(n) = mean(daxss_level1_data[wgd].(n),/NAN)
					endif else if (vardim eq 1) then begin
						daxss_average_data[k].(n) = mean(daxss_level1_data[wgd].(n),dim=2,/NAN)
					endif else print, 'WARNING: can not average 3-D data for tag number ', n
				endelse
			  endif else begin
					; just copy first instance if can not make an average
					daxss_average_data[k].(n) = daxss_level1_data[wgd[0]].(n)
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
daxss_average_data = JPMAddTagsToStructure(daxss_average_data, 'NOMINAL_TIME_JD', 'double', $
						insertIndex = num_x123)
daxss_average_data.nominal_time_jd = nominal_jd
daxss_average_data = JPMAddTagsToStructure(daxss_average_data, 'NOMINAL_TIME_YD', 'double', $
						insertIndex = num_x123+1)
daxss_average_data.nominal_time_yd = jd2yd(nominal_jd)
daxss_average_data = JPMAddTagsToStructure(daxss_average_data, 'GOES_XRSA', 'float', $
						insertIndex = num_x123+2)
daxss_average_data = JPMAddTagsToStructure(daxss_average_data, 'GOES_XRSB', 'float', $
						insertIndex = num_x123+3)
goes_jd = gps2jd(goes_all.time)
daxss_average_data.goes_xrsa = interpol( goes_all.short, goes_jd, nominal_jd )
daxss_average_data.goes_xrsb = interpol( goes_all.long, goes_jd, nominal_jd )
wbad_goes = where( nominal_jd gt max(goes_jd), num_bad )
if (num_bad gt 0) then begin
	daxss_average_data[wbad_goes].goes_xrsa = -1  ; missing data value
	daxss_average_data[wbad_goes].goes_xrsa = -1
endif

;
;  add more to the META structure
;
num_meta = n_tags(daxss_average_meta)
avg_min_str = strtrim(average_minutes,2) + '-minute' + (average_minutes le 1? '': 's')
if (average_minutes ge (24L*60L)) then avg_min_str='1-day'
daxss_average_meta = JPMAddTagsToStructure(daxss_average_meta, 'NOMINAL_TIME_JD', 'string', $
						insertIndex = num_meta)
daxss_average_meta.nominal_time_jd = 'Nominal Time for '+avg_min_str+' Average in JD format'
daxss_average_meta = JPMAddTagsToStructure(daxss_average_meta, 'NOMINAL_TIME_YD', 'string', $
						insertIndex = num_meta+1)
daxss_average_meta.nominal_time_yd = 'Nominal Time for '+avg_min_str+' Average in YYYYDOY format'
daxss_average_meta = JPMAddTagsToStructure(daxss_average_meta, 'GOES_XRSA', 'string', $
						insertIndex = num_meta+2)
daxss_average_meta.goes_xrsa = 'GOES XRS-A Irradiance for nominal time of average'
daxss_average_meta = JPMAddTagsToStructure(daxss_average_meta, 'GOES_XRSB', 'string', $
						insertIndex = num_meta+3)
daxss_average_meta.goes_xrsb = 'GOES XRS-B Irradiance for nominal time of average'

;
;	Save the Level 2/3 file
;
if (average_minutes eq (24L*60L)) then begin
	ddir3 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level3' + path_sep()
	file3 = 'daxss' + '_l3_1day_average_mission_length_v' + version + '.sav'
	if keyword_set(VERBOSE) then message, /INFO, 'Saving Level 3 data product in '+ddir3+file3
	save, daxss_average_data, daxss_average_meta, file=ddir3+file3
endif else begin
	min_str = strtrim(long(average_minutes),2) + 'minutes'
	if (average_minutes eq 1) then min_str = '1minute'
	if (average_minutes eq 60) then min_str = '1hour'
	ddir2 = getenv('minxss_data') + path_sep() + 'fm' + fm_str + path_sep() + 'level2' + path_sep()
	file2 = 'daxss' + '_l2_'+min_str+'_average_mission_length_v' + version + '.sav'
	if keyword_set(VERBOSE) then message, /INFO, 'Saving Level 2 data product in '+ddir2+file2
	save, daxss_average_data, daxss_average_meta, file=ddir2+file2
endelse

if keyword_set(DEBUG) then stop, 'STOPPED at end of daxss_make_x123_average.pro ...'
return
end
