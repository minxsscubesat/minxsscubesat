;
;	daxss_make_sp_average.pro
;
;	Make average spectrum for specified time and specified period and save into file
;
;	INPUT
;		time	Date in YYYYDOY or YYYYMMDD format and fraction of day
;		period	Time in seconds for averaging the data ( +/- of period/2 )
;
;	OUTPUT
;		data	Data array for the average spectrum including energy, counts, and uncertainty
;
;	HISTORY
;		5/24/2022	Tom Woods, original code
;
pro daxss_make_sp_average, time, period, data=data, directory=directory, debug=debug

if n_params() lt 2 then begin
	print, 'USAGE: daxss_make_sp_average, time, period, data=data, directory=directory'
	return
endif

if not keyword_set(directory) then directory = getenv('minxss_data') + path_sep() + 'analysis' + $
		path_sep() + 'daxss' + path_sep()

;
;	get JD value for input "time"
;
if (time gt 2030001L) then begin
	; YYYYMMDD format assumed
	year = long(time) / 10000L
	month = (long(time) - year*10000L)/100L
	day = (long(time) - year*10000L - month*100L)
	hour = (time - long(time))*24.
	time_jd = ymd2jd(year,month,day+hour/24.)
endif else begin
	; YYYYDOY format assumed
	year = long(time) / 1000L
	doy = (long(time) - year*1000L)
	hour = (time - long(time))*24.
	time_jd = yd2jd(time)
endelse

common daxss_plot_flare_common, daxss_level1, daxss_fe_abundance, daxss_s_abundance, daxss_si_abundance, $
			minxsslevel1, goes, goes_year, goes_jd
if (goes_year eq !NULL) then goes_year = 0L

;
;  make Fe abundance factor scaling to include in the flare plots with abundance expected between 1 to 4
;
DAXSS_FE_LINE_PEAK = 0.81
DAXSS_FE_CONTINUUM = 1.20
DAXSS_FE_WIDTH = 1L
DAXSS_FE_ABUNDANCE_SCALE_FACTOR = 0.080    ; based on non-flare first light spectrum so Fe abundance is ~ 4.0
DAXSS_FE_ABUNDANCE_VALUE_ONE_SCALE_FACTOR = 1E5

;  make S abundance factor scaling to include in the flare plots with abundance expected between 1 to 4
DAXSS_S_LINE_PEAK = 2.43
DAXSS_S_CONTINUUM = 1.94
DAXSS_S_WIDTH = 1L
DAXSS_S_ABUNDANCE_SCALE_FACTOR = 18.0
DAXSS_S_ABUNDANCE_VALUE_ONE_SCALE_FACTOR = 1E5

;  make Si abundance factor scaling to include in the flare plots with abundance expected between 1 to 4
DAXSS_SI_LINE_PEAK = 1.85
DAXSS_SI_CONTINUUM = 1.94
DAXSS_SI_WIDTH = 1L
DAXSS_SI_ABUNDANCE_SCALE_FACTOR = 0.50
DAXSS_SI_ABUNDANCE_VALUE_ONE_SCALE_FACTOR = 1E5

;
;	Read DAXSS Level 1
;
ddir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level1' + path_sep()
dfile1 = 'minxss3_l1_mission_length_v1.0.0.sav'
if (daxss_level1 eq !NULL) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading DAXSS L1 data from '+ddir+dfile1
	restore, ddir+dfile1   ; daxss_level1 variable is structure
	; estimate daxss_fe_abundance using Fe line peak at 0.81 keV to continuum level at 1.2 keV
	num_L1 = n_elements(daxss_level1.data)
	daxss_fe_abundance = fltarr(num_L1)
	temp1 = min(abs(daxss_level1.data[0].energy - DAXSS_FE_LINE_PEAK),wfe)
	temp2 = min(abs(daxss_level1.data[0].energy - DAXSS_FE_CONTINUUM),wcont)
	for ii=0L,num_L1-1 do begin
		fe_peak = total(daxss_level1.data[ii].irradiance[wfe-DAXSS_FE_WIDTH:wfe+DAXSS_FE_WIDTH])
		fe_cont = total(daxss_level1.data[ii].irradiance[wcont-DAXSS_FE_WIDTH:wcont+DAXSS_FE_WIDTH])
		daxss_fe_abundance[ii] = (fe_peak / fe_cont) * DAXSS_FE_ABUNDANCE_SCALE_FACTOR
	endfor

	; estimate daxss_S_abundance using S line peak at 2.43 keV to continuum level at 1.94 keV
	daxss_s_abundance = fltarr(num_L1)
	temp1 = min(abs(daxss_level1.data[0].energy - DAXSS_S_LINE_PEAK),ws)
	temp2 = min(abs(daxss_level1.data[0].energy - DAXSS_S_CONTINUUM),wscont)
	for ii=0L,num_L1-1 do begin
		s_peak = total(daxss_level1.data[ii].irradiance[ws-DAXSS_FE_WIDTH:ws+DAXSS_FE_WIDTH])
		s_cont = total(daxss_level1.data[ii].irradiance[wscont-DAXSS_FE_WIDTH:wscont+DAXSS_FE_WIDTH])
		daxss_s_abundance[ii] = (s_peak / s_cont) * DAXSS_S_ABUNDANCE_SCALE_FACTOR
	endfor

	; estimate daxss_Si_abundance using Si line peak at 1.85 keV to continuum level at 1.94 keV
	daxss_si_abundance = fltarr(num_L1)
	temp1 = min(abs(daxss_level1.data[0].energy - DAXSS_SI_LINE_PEAK),wsi)
	temp2 = min(abs(daxss_level1.data[0].energy - DAXSS_SI_CONTINUUM),wsicont)
	for ii=0L,num_L1-1 do begin
		si_peak = total(daxss_level1.data[ii].irradiance[wsi-DAXSS_FE_WIDTH:wsi+DAXSS_FE_WIDTH])
		si_cont = total(daxss_level1.data[ii].irradiance[wsicont-DAXSS_FE_WIDTH:wsicont+DAXSS_FE_WIDTH])
		daxss_si_abundance[ii] = (si_peak / si_cont) * DAXSS_SI_ABUNDANCE_SCALE_FACTOR
	endfor
endif

;
;	Read GOES data
;
gdir = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
gfile = 'goes_1mdata_widx_'+strtrim(year,2)+'.sav'
if (year ne goes_year) then begin
	if keyword_set(verbose) then message,/INFO, 'Reading GOES data from '+gdir+gfile
	restore, gdir+gfile   ; goes structure array
	goes_jd = gps2jd(goes.time)
	goes_year = year
endif

;
;	find closest time in the DAXSS Level 1
;
time_diff = min( abs(time_jd - daxss_level1.data.time_jd), wmin )
ans = ' '
if (time_diff gt 1.) then begin
	print, 'DAXSS Data are ' + strtrim(time_diff,2) + ' days from specified time !'
	read, 'Do you want to continue (Y/N) ? ', ans
	if (strupcase(strmid(ans,0,1)) eq 'N') then goto, theExit
endif
half_jd = (period/2.)/3600.D0/24.
jd_center = daxss_level1.data[wmin].time_jd
wgd = where( (daxss_level1.data.time_jd ge (jd_center-half_jd)) and $
		(daxss_level1.data.time_jd le (jd_center+half_jd)), num_gd )
jd_center = mean(daxss_level1.data[wgd].time_jd)

;
;	fill in the data[] array
;		data[0,*] = energy
;		data[1,*] = irradiance
;		data[2,*] = count rate
;		data[3,*] = irradiance uncertainty
;		data[4,*] = count precision
;
data = fltarr(5,1024)
data[0,*] = daxss_level1.data[wgd[0]].energy
temp = daxss_level1.data[wgd].irradiance
data[1,*] = total(temp,2) / float(num_gd)
temp = daxss_level1.data[wgd].spectrum_cps
data[2,*] = total(temp,2) / float(num_gd)
temp = daxss_level1.data[wgd].irradiance_uncertainty
data[3,*] = total(temp,2) / float(num_gd)
temp = daxss_level1.data[wgd].spectrum_cps_precision
data[4,*] = total(temp,2) / float(num_gd) / sqrt(num_gd)
wbad = where(data[0,*] lt 0.3)
for ii=1,4 do data[ii,wbad] = 0.0
wkeep = where(data[0,*] ge 0.3 and data[0,*] lt 12.)
data_all = data
data = data[*,wkeep]

;
;	print some information
;		GOES XRS-B level for the DAXSS data
;		Number of Spectra in average
;
goes_daxss = interpol( goes.long, goes_jd, jd_center ) > 1E-8
if (goes_daxss lt 9.95E-8) then goes_name = 'A' + string(goes_daxss/1E-8,format='(F3.1)') $
else if (goes_daxss lt 9.95E-7) then goes_name = 'B' + string(goes_daxss/1E-7,format='(F3.1)') $
else if (goes_daxss lt 9.95E-6) then goes_name = 'C' + string(goes_daxss/1E-6,format='(F3.1)') $
else if (goes_daxss lt 9.95E-5) then goes_name = 'M' + string(goes_daxss/1E-5,format='(F3.1)') $
else if (goes_daxss lt 9.95E-4) then goes_name = 'X' + string(goes_daxss/1E-4,format='(F3.1)') $
else goes_name = 'X' + string(goes_daxss/1E-4,format='(F4.1)')

time_yd = jd2yd(jd_center)
hour = (time_yd - long(time_yd))*24.
minute = (hour - long(hour))*60.
second = (minute - long(minute))*60.
period_actual = (daxss_level1.data[wgd[-1]].time_jd - daxss_level1.data[wgd[0]].time_jd)/24.D0/3600.
time_str = strtrim(long(time_yd),2) + '_' + string(long(hour),format='(I02)') + $
				'-' + string(long(minute),format='(I02)') + $
				'-' + string(long(second),format='(I02)')
print, ' '
print, 'DAXSS_MAKE_SP_AVERAGE: ' + strtrim(num_gd,2) +' spectra at ' + time_str +  $
			' when XRS-B level is ' + goes_name
print, ' '

;
;	plot the spectrum
;
setplot
yMax = 10.^(long(alog10(max(data[1,*])))+1.)
plot, data[0,*], data[1,*], psym=10, title=time_str+' @ XRS-B = '+goes_name, $
		xrange=[0.0,10], xs=1, xtitle='Energy (keV)', $
		/ylog, yrange=[1E1,yMax], ys=1, ytitle='DAXSS Irradiance (ph/s/cm!U2!N/keV)'

;
;	write result to a file
;
read, 'Do you want to save this spectrum (Y/N) ? ', ans
if (strupcase(strmid(ans,0,1)) eq 'N') then goto, theExit

theFile = 'daxss_sp_average_' + time_str + '_' + strtrim(long(period_actual),2) + 'sec.dat'
print, 'Saving averaged spectrum in '+directory+theFile
comments = [ 'InspireSat-1 DAXSS Spectrum created on '+systime(), $
			'Time for Spectrum Average = '+time_str, $
			'Number of Spectra in average = '+strtrim(num_gd,2), $
			'GOES XRS-B level = '+goes_name, $
			'Column 1:  Energy in units of keV', $
			'Column 2:  Irradiance in units of photons/sec/cm^2/keV', $
			'Column 3:  Count Rate in units of counts per sec', $
			'Column 4:  Irradiance Accuracy in units of photons/sec/cm^2/keV', $
			'Column 5:  Count Rate Precision in units of counts per sec' ]
write_dat, data, file=directory+theFile, $
		lintext='DAXSS Spectrum created by daxss_make_sp_average.pro on '+systime(), $
		coltext='Energy_keV, Irradiance, Count_Rate, Irradiance_Accuracy, Count_Rate_Precision ', $
		comments=comments, format='(F8.4,4E12.4)'

theExit:
if keyword_set(debug) then stop, 'STOPPED at end of daxss_make_sp_average.pro'
end

