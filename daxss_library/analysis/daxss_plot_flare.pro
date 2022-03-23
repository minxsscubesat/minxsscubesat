;
;	daxss_plot_flare.pro
;
;	Plot DAXSS Flare time series and spectrum
;
; INPUTS
;	date		Fractional day in YD or YMD format
;	/minxss1	Option to over-plot MinXSS-1 flare too
;	/range_hours	Option to specify time range before / after flare (default is 1-hour)
;					That is, plot is peak-range_hours to peak+range_hours
;	/verbose	Option to print messages
;
;	T. Woods, 3/23/2022
;
pro daxss_plot_flare, date, minxss1=minxss1, range_hours=range_hours, verbose=verbose

if n_params() lt 1 then begin
	date = 0.0D0
	read, 'Enter Date for flare (in YD or YMD format, fractional day): ', date
endif

if not keyword_set(range_hours) then range_hours = 1

;
;	figure out the Date in JD and hours
;
if (date gt 2030001L) then begin
	; YYYYMMDD format assumed
	year = long(date) / 10000L
	month = (long(date) - year*10000L)/100L
	day = (long(date) - year*10000L - month*100L)
	hour = (date - long(date))*24.
	jd_mid = ymd2jd(year,month,day+hour/24.)
endif else begin
	; YYYYDOY format assumed
	year = long(date) / 100L
	doy = (long(date) - year*1000L)
	hour = (date - long(date))*24.
	jd_mid = yd2jd(date)
endelse
jd1 = jd_mid - range_hours/24.
jd2 = jd_mid + range_hours/24.

if (jd_min lt yd2jd(2022045.D0)) or (jd_min gt systime(/julian)) then begin
	message,/INFO, 'ERROR with Date being outside the InspireSat-1 mission range !'
	return
endif

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm4' + path_sep() 'level1' + path_sep()
dfile1 = 'minxss4_l1_mission_length_v1.0.0.sav'
if keyword_set(verbose) then begin message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
restore, ddir+dfile1   ; daxss_level1 variable is structure

;
;	Look for DAXSS data within the JD time range
;
wdax =  where((daxss_level1.time_jd ge jd1) AND (daxss_level1.time_jd le jd2), num_dax )
if (num_dax lt 2) then begin
	message,/INFO, 'ERROR finding any DAXSS data during this flare.'
	return
endif

;
;	Read GOES data
;
gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
if keyword_set(verbose) then begin message,/INFO, 'Reading GOES data from '+gdir+gfile
restore, gdir+gfile   ; goes structure array

;
;	Read MinXSS-1 Level 1 data
;
if keyword_set(minxss1) then begin
	mdir = getenv('minxss_data') + path_sep() + 'fm1' + path_sep() 'level1' + path_sep()
	mfile1 = 'minxss1_l1_mission_length_v3.1.0.sav'
	if keyword_set(verbose) then begin message,/INFO, 'Reading MinXSS-1 L1 data from '+mdir+mfile1
	restore, mdir+mfile1   ; minxsslevel1 variable is structure
endif

;
;	make Time Series plot with DAXSS slow counts and GOES XRS irradiance
;
setplot
cc=rainbow(7)

xrange = [jd1, jd2]
yrange1 = [1E2, 1E6]
yrange2 = [1E-8,1E-4]
p1_title = 'DAXSS Flare '+strtrim(long(date),2)

p1 = plot( daxss_level1.time_jd, daxss_level1.x123_slow_count, xrange=xrange, xs=1, /ylog, yrange=yrange1, ys=1, title=p1_title )

return
end
