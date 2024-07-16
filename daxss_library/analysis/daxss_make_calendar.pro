;
;	daxss_make_calendar.pro
;
;	Plot DAXSS observation calendar with number of observations per day and range of DAXSS Flare levels
;
; INPUTS
;	dates		Date Range in YD or YMD format
;	/all		Option to plot for all dates during IS1 mission - also saves result
;	/stats		Option to print summary of results per day
;	/pdf		Option to make PDF graphics files after making plot
;	/version	Option to specify which DAXSS version
;	/verbose	Option to print messages
;	/debug		Option to debug procedure
;
; OUTPUTS
;	result		Result of stats per day
;
;	Version 1:  9/30/2022	T. Woods
;
pro daxss_make_calendar, dates, result=result, stats=stats, all=all, pdf=pdf, $
							version=version, verbose=verbose, debug=debug

if (n_params() lt 1) AND (not keyword_set(all)) then begin
	dates = [0.0D0, 0.0D0]
	read, 'Enter Date Range (2 dates) in YD or YMD format: ', dates
endif

if not keyword_set(version) then version = '2.0.0'
version_long = long(version)

if keyword_set(debug) then verbose=1

if keyword_set(all) then begin
	pdf = 1
	stats = 1
endif
pdf_dir = getenv('minxss_data')+path_sep()+'fm3'+path_sep()+'calendar'+path_sep()

;	define Plot as 4 rows by 7 days
NUM_DAYS_PER_ROW = 7L
NUM_ROWS_PER_PAGE = 4L
NUM_DAYS_PER_PAGE = NUM_DAYS_PER_ROW * NUM_ROWS_PER_PAGE

common daxss_calendar_common, daxss_level1_data, hk, hk_jd, sci, sci_jd, $
				goes_year, goes, goes_jd, goes_jd_max

if (goes_year eq !NULL) then goes_year = 0L

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level1' + path_sep()
dfile1 = 'daxss_l1_mission_length_v'+version+'.sav'
if (daxss_level1_data eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
	restore, ddir+dfile1   ; daxss_level1 variable is structure
endif

;
;	Read DAXSS Level 0C
;
ddir0c = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level0c' + path_sep()
dfile0c = 'daxss_l0c_all_mission_length_v'+version+'.sav'
if (hk eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L0C data from '+ddir0c+dfile0c
	restore, ddir0c+dfile0c   ; hk and sci variables are packet structures
	hk_jd = gps2jd(hk.time)
	sci_jd = gps2jd(sci.time)
endif

if (version_long ge 2) then begin
	; Version 2 new variables
	slow_cps = daxss_level1_data.x123_slow_cps
endif else begin
	; Version 1
	slow_cps = daxss_level1_data.x123_slow_count
endelse

;
;	Read IS-1 Events file
;
is1_events = read_events( pdf_dir + 'is1_events.txt')
is1_yd = long(is1_events.date)

;
;	configure the range of dates
;
if keyword_set(all) then begin
	jd1 = yd2jd(2022058.0D0)  ; Sunday before X123 First Light on 2022/059
	jd2 = systime(/julian)
endif else begin
	num_date = n_elements(dates)
	if (dates[0] gt 2030001L) then begin
		; YYYYMMDD format assumed)
		date_str = strtrim(long(dates[0]),2)
		if (strlen(date_str) ne 8) then begin
			stop, 'STOP:  ERROR in dates[0] value.  It needs to be YYYYMMDD or YYYYDOY format.'
		endif
		jd1=ymd2jd( strmid(date_str,0,4), strmid(date_str,4,2), strmid(date_str,6,2))
	endif else begin
		; YYYYDOY format assumed)
		jd1 = yd2jd( double(dates[0]) )
	endelse
	if (num_date le 1) then begin
		jd2=jd1 + 28.	; force calendar to be 4 weeks
	endif else begin
		if (dates[0] gt 2030001L) then begin
			; YYYYMMDD format assumed)
			date_str = strtrim(long(dates[1]),2)
			if (strlen(date_str) ne 8) then begin
				stop, 'STOP:  ERROR in dates[1] value.  It needs to be YYYYMMDD or YYYYDOY format.'
			endif
			jd2=ymd2jd( strmid(date_str,0,4), strmid(date_str,4,2), strmid(date_str,6,2))
		endif else begin
			; YYYYDOY format assumed)
			jd2 = yd2jd( double(dates[1]) )
		endelse
	endelse
endelse

;
;	make the all_jd[] and all_dates[] arrays
;
num_dates = long(jd2-jd1+1L)
if (num_dates gt 2000) then begin
	ans = ' '
	print, '***** There are ', strtrim(num_dates,2), ' dates !!!!!'
	read, '***** Do you really want to continue with Calendar plots (Y/N) ', ans
	if strupcase(strmid(ans,0,1)) ne 'Y' then return
endif

all_jd = findgen(num_dates) + jd1
all_dates = long(jd2yd(all_jd)) + 0.5D0

;  make RESULT structure to store the results
result_1 = { date_jd: 0.0D0, date_yd: 0.0D0, date_iso: ' ', x123_obs_number: 0L, $
			hours24: findgen(24)+0.5, x123_coverage: intarr(24), xrs_low: ' ', xrs_high: ' ' }
result = replicate(result_1, num_dates)

;
;	Do big FOR Loops for a plot of 4 x 7 days
;
ans=' '
pdf_loop = 0
daxss_xrsb_array = fltarr(num_dates)
goes_xrsb_array = fltarr(num_dates)

iMax = (num_dates / NUM_DAYS_PER_PAGE) + 1
jMax = NUM_ROWS_PER_PAGE
kMax = NUM_DAYS_PER_ROW

; define BOX size
BOX_WIDTH = 200
BOX_HEIGHT = 200
dy = BOX_HEIGHT/8.
box_full_x = [-1.*BOX_WIDTH/2.+1, BOX_WIDTH/2.-1, BOX_WIDTH/2.-1, -1.*BOX_WIDTH/2.+1, -1.*BOX_WIDTH/2.+1]
box_full_y = [-1.*BOX_HEIGHT/2.+1, -1.*BOX_HEIGHT/2.+1, BOX_HEIGHT/2.-1, BOX_HEIGHT/2.-1, -1.*BOX_HEIGHT/2.+1]
box_half_y = [0., 0., BOX_HEIGHT/2., BOX_HEIGHT/2., 0.] - dy*1.0 - 5.
box_row_y = [-5., -5., dy, dy, -5.] + dy*3.0

; define COLOR limits for SOME_DATA, and GOOD_DATA
GOOD_LIMIT = 120L
OK_LIMIT = GOOD_LIMIT / 2
window,1, xsize=BOX_WIDTH*(NUM_DAYS_PER_ROW+1), ysize=BOX_HEIGHT*NUM_ROWS_PER_PAGE
bars, long(box_width/24.)+7, long(dy-2)  ; load User "bars" symbol
; dots

for ii=0L,iMax-1 do begin
 ; start a new PLOT
 pdf_loop = 0
PDF_LOOPBACK:
 if keyword_set(pdf) then begin
	if pdf_loop eq 0 then begin
		; make the PS (and PDF) files first and then plot to screen
		idate = ii*NUM_DAYS_PER_PAGE
		if (idate ge num_dates) then idate = num_dates-1
		fdate_str = strtrim( long(all_dates[idate]), 2 )
		pdf_file = 'daxss_calendar_'+fdate_str + '.ps'
		pdf_file_fullname = pdf_dir + pdf_file
		ps_on, filename=pdf_file_fullname    ; , /landscape
	endif
 endif
 setplot & cc=rainbow(7) & cs=2.4
 plot, [0,1], [0,1], /nodata, xrange=[0,BOX_WIDTH*(NUM_DAYS_PER_ROW+1)], xstyle=1+4, $
 		yrange=[BOX_HEIGHT*NUM_ROWS_PER_PAGE,0], ystyle=1+4, $
 		xmargin=[0,0], ymargin=[0,0]

 for jj=0L,jMax-1 do begin
  for kk=0L,kMax-1 do begin
	; determine index into all_dates[]
	index = ii*NUM_DAYS_PER_PAGE + jj*NUM_ROWS_PER_PAGE + kk;
	if (index ge num_dates) then goto, BIG_LOOP_END
	; save date results
	result[index].date_jd = all_jd[index]
	result[index].date_yd = all_dates[index]
	full_iso = jpmjd2iso(all_jd[index], /NO_T_OR_Z)
	theISO = strmid(full_iso,0,10)
	result[index].date_iso = theISO
	; determine box center
	xcenter = (kk + 1.5) * BOX_WIDTH
	ycenter = (jj + 0.5) * BOX_HEIGHT
	if (kk eq 0) then begin
		xyouts, xcenter-BOX_WIDTH, ycenter-dy*3., theISO, align=0.5, charsize=cs*1.2
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter-dy*2., 'DAXSS Obs #', align=1.0, charsize=cs*0.8
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter-dy*1., 'XRS Range', align=1.0, charsize=cs*0.8
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter+dy*0., 'IS1 Event', align=1.0, charsize=cs*0.8
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter+dy*1., 'DAXSS Hourly', align=1.0, charsize=cs*0.8
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter+dy*2., 'MEGS-B Hourly', align=1.0, charsize=cs*0.8
		xyouts, xcenter-BOX_WIDTH/2.-5, ycenter+dy*3., 'CH2-XSM Hourly', align=1.0, charsize=cs*0.8
	endif

	; YYYYDOY format for all_dates
	year = long(all_dates[index]) / 1000L
	doy = (long(all_dates[index]) - year*1000L)
	date_str = string(year,format='(I04)') + '/' + string(doy,format='(I03)')
	date_yd = year*1000L+doy

	;
	;	Look for DAXSS data within the JD time range and draw 1/2 box with color based on number of data points
	;
	wdax =  where((daxss_level1_data.time_jd ge all_jd[index]) AND $
					(daxss_level1_data.time_jd lt (all_jd[index]+1.D0)), num_dax )
	result[index].x123_obs_number = num_dax

	;
	;	draw the boxes:  1 for date as grey and 1 for X123 observations
	;
	polyfill, xcenter + box_full_x, ycenter - box_row_y, color='C0C0C0'X
	theColor = (num_dax ge GOOD_LIMIT? cc[3] : (num_dax ge OK_LIMIT? cc[4]: (num_dax gt 0? cc[1]: 'FFFFFF'X) ))
	if (theColor ne 'FFFFFF'X) then polyfill, xcenter + box_full_x, ycenter - box_half_y, color=theColor
	oplot, box_full_x + xcenter, box_full_y + ycenter, thick=2

	;
	;	determine the number of observations per hour
	;	plot hourly coverage at  (ycenter+dy)
	;
	if (num_dax gt 0) then begin
		yd = daxss_level1_data[wdax].time_yd
		hour = (yd - long(yd[0]))*24.
		for hh=0L,23L do begin
			whour = where( (hour ge hh) AND (hour lt (hh+1)), num_hour )
			if (num_hour gt 0) then result[index].x123_coverage[hh] = num_hour
		endfor
		;  draw hourly coverage using special "bars" user symbol (8)
		wbars = where(result[index].x123_coverage gt 0)
		yy = ycenter+dy*0.75+intarr(24)
		oplot, xcenter+(result[index].hours24[wbars]-12.)*BOX_WIDTH/24., yy[wbars], psym=8
		; debug 'bars' to verify there are no gaps
		; if (kk eq 0) and (ii eq 0) and (jj eq 0) and keyword_set(debug) then $
		;	oplot, xcenter+(result[index].hours24-12.)*BOX_WIDTH/24., yy+dy*findgen(24)/24., psym=8, color=cc[0]
	endif

	;
	;	write DAXSS information into the box
	;
	xyouts, xcenter, ycenter-dy*3., date_str, align=0.5, charsize=cs*1.2
	xyouts, xcenter, ycenter-dy*2., strtrim(num_dax,2), align=0.5, charsize=cs*1.2

	;
	;	Read GOES data
	;
	gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
	gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
	if (year ne goes_year) then begin
		if keyword_set(verbose) then message,/INFO, 'Reading GOES data from '+gdir+gfile
		restore, gdir+gfile   ; goes structure array
		goes_jd = gps2jd(goes.time)
		goes_jd_max = max(goes_jd)
		goes_year = year
	endif
	;
	;	determine GOES XRS range for DAXSS data
	;
	if (num_dax gt 0) AND (goes_jd_max ge (all_jd[index]+1.)) then begin
		goes_daxss = interpol( goes.long, goes_jd, daxss_level1_data[wdax].time_jd )
		result[index].xrs_low = goes_xrs_class( min(goes_daxss))
		result[index].xrs_high = goes_xrs_class( max(goes_daxss))
		range_str = result[index].xrs_low + '-' + result[index].xrs_high
		xyouts, xcenter, ycenter-dy*1., range_str, align=0.5, charsize=cs
	endif

	;
	;	print IS-1 event text (if have one)
	;
	wmsg = where( is1_yd eq date_yd, num_msg )
	if (num_msg gt 0) then begin
		xyouts_optimize, xcenter, ycenter+dy*0., is1_events[wmsg[0]].event_text, $
				BOX_WIDTH*0.95/(BOX_WIDTH*(NUM_DAYS_PER_ROW+1)), limit=cs, align=0.5
	endif

  endfor
 endfor
 ;
 ;	save PDF file (if requested)
 ;
 if keyword_set(pdf) then begin
	if pdf_loop eq 0 then begin
		ps_off
		if keyword_set(verbose) then message, /INFO, 'Making PDF file: '+pdf_file_fullname
		pstopdf, pdf_file_fullname, /wait, /deleteps
	endif
	pdf_loop += 1
	;  loop-back for plot to screen
	if (pdf_loop eq 1) then goto, PDF_LOOPBACK
 endif else read, 'Next Plot ? ', ans
endfor   ; END of big loop for ii, jj, kk

BIG_LOOP_END:

;  do smooth close down of PDF file
if keyword_set(pdf) then begin
	if pdf_loop eq 0 then begin
		ps_off
		if keyword_set(verbose) then message, /INFO, 'Making PDF file: '+pdf_file_fullname
		pstopdf, pdf_file_fullname, /wait, /deleteps
	endif
endif

;
;	/stats	Option to store / print number of packets per day
;
if keyword_set(stats) then begin
	print, ' '
	print, 'DAXSS_MAKE_CALENDAR Stats'
	print, '-------------------------'
	print, 'Number of Days = ', strtrim(n_elements(result),2)
	print, 'Number of DAXSS observations = ', strtrim(total(result.x123_obs_number),2)
	wtemp = where( result.x123_obs_number gt 0, num_with )
	print, 'Number of days  with   downlinked observations = ', strtrim(num_with,2)
	wtemp = where( result.x123_obs_number le 0, num_without )
	print, 'Number of days without downlinked observations = ', strtrim(num_without,2)
	print, ' '
endif

if keyword_set(all) then begin
	; save RESULT in IDL SaveSet
	save_file = 'daxss_calendar_result.sav'
	daxss_calendar_result = result
	if keyword_set(verbose) then print, '*** Save DAXSS Calendar Result in ', pdf_dir+save_file
	save, daxss_calendar_result, file=pdf_dir+save_file
endif

if keyword_set(debug) then stop, "DEBUG at end of daxss_plot_flare.pro ..."
return
end
