;
;	daxss_flare_ip.pro
;
;	Plot DAXSS time series for 6.4 and 6.7 keV to look for special Impulsive Phase (IP) peak at 6.4 keV
;
;	INPUT
;		date	YYYYDOY fractional day (needs to be near flare peak)
;					Flare Peak will be found automatically
;		ip_date	YYYYDOY fraction day for when to make spectral plot #2
;
;		/eps	Make EPS plot instead
;
;	OUTPUT
;		Plot-1	Plot of time series of 6.4 and 6.7 keV - at low Y-scale and flare-peak-scale
;		Plot-2	Spectral plot at time of IP initial rise (user selected or ip_date value)
;
;	HISTORY
;		8/20/2023	T. Woods, original code
;
pro daxss_flare_ip, date, ip_date, eps=eps, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE: daxss_flare_ip, date [, ip_date, /eps, /debug ] '
	return
endif

; prepare date values
date_year = long(long(date)/1000.)
date_doy = long(date) - date_year*1000L
date_hour = (date - date_year*1000L - date_doy) * 24.D0

;
;	Read GOES and DAXSS data
;
common daxss_flare_ip_common, goes_year, goes, goes_jd, daxss1
if n_elements(daxss1) lt 2 then begin
	file1 = getenv('minxss_data') + '/fm3/level1/daxss_l1_mission_length_v2.0.0.sav'
	if keyword_set(debug) then print, 'READING DAXSS Level 1 data from ', file1
	restore, file1 	; restores "daxss_level1_data" and "daxss_level1_meta" variables
	daxss1 = daxss_level1_data
	daxss_leve1_data = 0L
	; will use daxss1.time_jd, .time_yd, .irradiance, .energy
endif
if n_elements(goes) lt 2 then begin
READ_GOES:
	goes_year = date_year
	goes_year_str = strtrim(goes_year,2)
	gfile = getenv('minxss_data') + '/ancillary/goes/goes_1mdata_widx_' + $
				goes_year_str + '.sav'
	if keyword_set(debug) then print, 'READING GOES data from ', gfile
	restore, gfile  ; restores "goes" variable
	goes_jd = gps2jd(goes.time)
	; will use goes_jd, goes.long
endif
if (goes_year ne date_year) then goto, READ_GOES

;
;	find flare peak time more exactly
;
date_jd = yd2jd(date)
dhour = 1.D0	; search from date by +/- 1 hour for peak in GOES XRS-B
jd1 = date_jd - 1./24.D0  & jd2 = date_jd + 1./24.D0
wg = where( (goes_jd ge jd1) and (goes_jd le jd2), num_g)
if (num_g le 1) then begin
	print, 'ERROR finding any GOES data for this flare time.'
	if keyword_set(debug) then stop, 'DEBUG GOES flare time error ...'
endif
temp = max( goes[wg].long, wpeak )
peak_jd = goes_jd[wg[wpeak]]
peak_yd = jd2yd(peak_jd)
peak_hour = (peak_yd - long(peak_yd))*24.D0
peak_minute = (peak_hour - long(peak_hour))*60.
peak_hour_str = string(long(peak_hour),format='(I02)') + ':' + string(long(peak_minute),format='(I02)')
peak_year = long(long(peak_yd)/1000.)
peak_doy = long(peak_yd) - peak_year*1000L
peak_doy_str = strtrim(peak_year,2) + '/' + string(peak_doy,format='(I03)')

peak_flux = goes[wg[wpeak]].long
; prepare normalized GOES XRS-B too
goes_norm = goes[wg].long / max(peak_flux)
goes_plt_jd = goes_jd[wg]

; convert GOES flux into Flare Title
if peak_flux gt 1E-4 then begin
	peak_x = peak_flux/1E-4
	if (peak_x ge 10.) then goes_class = 'X' + string(peak_x,format='(F4.1)') $
	else goes_class = 'X' + string(peak_x,format='(F3.1)')
endif else if peak_flux gt 1E-5 then begin
	goes_class = 'M' + string(peak_flux/1E-5,format='(F3.1)')
endif else if peak_flux gt 1E-6 then begin
	goes_class = 'C' + string(peak_flux/1E-6,format='(F3.1)')
endif else if peak_flux gt 1E-7 then begin
	goes_class = 'B' + string(peak_flux/1E-7,format='(F3.1)')
endif else begin
	goes_class = 'A' + string((peak_flux > 1E-8)/1E-8,format='(F3.1)')
endelse

;
;	make DAXSS 6.4 and 6.7 keV time series
;	FWHM at 6.4 keV = 0.1368 keV
;	FWHM at 6.7 keV = 0.1395 keV
;
wd = where( (daxss1.time_jd ge jd1) and (daxss1.time_jd le jd2), num_d )
if (num_d le 1) then begin
	print, 'ERROR finding any DAXSS data for this flare time.'
	if keyword_set(debug) then stop, 'DEBUG DAXSS flare time error ...'
endif
e = daxss1[wd[0]].energy
eband = e[1] - e[0]
fwhm = 0.10
e1 = 6.4
e2 = 6.6
e2adj = e2 + fwhm/2.
wr1 = where( (e gt (e1-fwhm)) and (e lt (e1+fwhm)), num_r1 )  ; range 6.3-6.5 keV
wr2 = where( (e gt (e2-fwhm)) and (e lt (e2+fwhm*2)), num_r2 ) ; range 6.5-6.8 keV
d1_jd = daxss1[wd].time_jd
d1_flux1 = reform(total(daxss1[wd].irradiance[wr1],1)*eband)
d1_flux2 = reform(total(daxss1[wd].irradiance[wr2],1)*eband)
;  normalize to peak flux of each line
norm_flux1 = d1_flux1 / max(d1_flux1)
norm_flux2 = d1_flux2 / max(d1_flux2)

; get precision too
d1_prec1 = reform(total(daxss1[wd].spectrum_cps_precision[wr1],1))/float(num_r1)
d1_cps1 = reform(total(daxss1[wd].spectrum_cps[wr1],1))/float(num_r1)
d1_rel_prec1 = d1_prec1 / d1_cps1
d1_prec2 = reform(total(daxss1[wd].spectrum_cps_precision[wr2],1))/float(num_r2)
d1_cps2 = reform(total(daxss1[wd].spectrum_cps[wr2],1))/float(num_r2)
d1_rel_prec2 = d1_prec2 / d1_cps2

;
;	PLOT-1: Plot of time series of 6.4 and 6.7 keV - at low Y-scale and flare-peak-scale
;
; YRANGE_HIGH = max(d1_flux2)
; YRANGE_LOW = YRANGE_HIGH / 10.
YRANGE_HIGH = 1.1
YRANGE_LOW = 0.1
ans = ' '
pjd1 = peak_jd - 0.5/24.D0
pjd2 = peak_jd + 0.5/24.D0
title_goes = 'XRS '+goes_class+' @ ' + peak_doy_str + ' ' + peak_hour_str

setplot & cc=rainbow(7) & cs=2.0
result = LABEL_DATE(date_format="%H:%I")
plot, d1_jd, norm_flux2, psym=10, xrange=[pjd1,pjd2], xs=1, yrange=[0,YRANGE_HIGH], ys=1, $
		ytitle='DAXSS Irradiance Normalized', XTICKFORMAT='LABEL_DATE', $
		title=title_goes
oplot, goes_plt_jd, goes_norm, psym=10, color=cc[3]
oplot, d1_jd, norm_flux1, psym=10, color=cc[0]

dx = (pjd2-pjd1)/15.
xx = pjd1 + dx
yy = 0.9*YRANGE_HIGH & dy = 0.1*yy
xyouts, xx, yy, '6.65 keV', charsize=cs
xyouts, xx, yy-dy, '6.40 keV', charsize=cs, color=cc[0]
xyouts, xx, yy-2*dy, 'XRS-B', charsize=cs, color=cc[3]

read, 'Next Plot ? ', ans

setplot & cc=rainbow(7) & cs=2.0
result = LABEL_DATE(date_format="%H:%I")
plot, d1_jd, norm_flux2, psym=10, xrange=[pjd1,pjd2], xs=1, yrange=[0,YRANGE_LOW], ys=1, $
		ytitle='DAXSS Irradiance Normalized', XTICKFORMAT='LABEL_DATE', $
		title=title_goes
oplot, goes_plt_jd, goes_norm, psym=10, color=cc[3]
oplot, d1_jd, norm_flux1, psym=10, color=cc[0]

yy = 0.9*YRANGE_LOW & dy = 0.1*yy
xyouts, xx, yy, '6.65 keV', charsize=cs
xyouts, xx, yy-dy, '6.40 keV', charsize=cs, color=cc[0]
xyouts, xx, yy-2*dy, 'XRS-B', charsize=cs, color=cc[3]

if n_params() lt 2 then begin
	read, 'Move cursor to special IP 6.4 keV peak time and hit ENTER key...', ans
	cursor, xip, yip, /nowait
	ip_date = jd2yd(xip)
endif else begin
	read, 'Next Plot ? ', ans
endelse

; prepare ip_date values
ip_date_year = long(long(ip_date)/1000.)
ip_date_doy = long(ip_date) - ip_date_year*1000L
ip_date_hour = (ip_date - ip_date_year*1000L - ip_date_doy) * 24.D0
ip_minute = (ip_date_hour - long(ip_date_hour))*60.
ip_hour_str = string(long(ip_date_hour),format='(I02)') + ':' + string(long(ip_minute),format='(I02)')
ip_str = 'IP @ ' + ip_hour_str

; get index for peak_jd and ip_jd
ip_jd = yd2jd(ip_date)
temp = min(abs(d1_jd-ip_jd), ip_index )
temp = min(abs(d1_jd-peak_jd), peak_index )

setplot & cc=rainbow(7) & cs=2.0
result = LABEL_DATE(date_format="%H:%I")
plot,d1_jd,norm_flux1/norm_flux2, psym=10, xr=[pjd1,pjd2], xs=1, yr=[0,5], ys=1, $
		ytitle='Normalized 6.4 keV / 6.65 keV', XTICKFORMAT='LABEL_DATE', $
		title=title_goes+', '+ip_str
; over plot peak_date and ip_date
oplot, peak_jd*[1,1], !y.crange, line=2
oplot, ip_jd*[1,1], !y.crange, line=2, color=cc[0]

read, 'Next Plot ? ', ans

;
;	PLOT-2: Spectral plot at time of IP initial rise (user selected or ip_date value)
;		make plot of irradiance spectrum near 6.5 keV using ip_index and peak_index
;
num_avg = 3
num_off = long(num_avg/2.) > 1L
num_total = num_off*2.+1.
ip_spectrum = total(daxss1[wd[ip_index-num_off:ip_index+num_off]].irradiance,2) / num_total
peak_spectrum = total(daxss1[wd[peak_index-num_off:peak_index+num_off]].irradiance,2) / num_total
we65 = where( (e gt 6.3) and (e lt 6.8) )
we61 = where( (e gt 6.05) and (e lt 6.15) )

setplot & cc=rainbow(7) & cs=2.0
plot, e, peak_spectrum, psym=10, xrange=[6,7], xs=1, xtitle='Energy (keV)', $
		yrange=[0,max(peak_spectrum[we65])*1.1], ys=1, ytitle='DAXSS Irradiance (ph/s/cm!U2!N/keV)', $
		title=title_goes+', '+ip_str

ip_factor = total(peak_spectrum[we61]) / total(ip_spectrum[we61])
oplot, e, ip_spectrum*ip_factor, psym=10, color=cc[0]
oplot, e1*[1,1], !y.crange, line=2
oplot, e2adj*[1,1], !y.crange, line=2
xx = 6.05
dy = (!y.crange[1] - !y.crange[0])/10.
yy = !y.crange[1]-dy*2
xyouts, xx, yy, 'Peak Irradiance', charsize=cs
ip_factor_str = strtrim( string(ip_factor,format='(F6.1)'), 2)
xyouts, xx, yy-dy, 'IP Irrad. X '+ip_factor_str, color=cc[0], charsize=cs

read, 'Next Plot ? ', ans

if keyword_set(debug) then stop, 'DEBUG at end of daxss_flare_ip.pro ...'

return
end
