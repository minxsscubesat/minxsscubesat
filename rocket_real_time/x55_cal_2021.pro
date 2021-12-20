;
;	x55_cal_2021.pro
;
;	Apply DAXSS-1 calibration to X55 2021 rocket flight
;
;	Tom Woods, 9/28/2021
;

; read DAXSS-1 2018 cal data
file1s='/Users/twoods/Documents/CubeSat/NASA_MinXSS/Papers/DAXSS_Rocket_X123_Papers/daxss_spectrum.sav'
restore, file1s ; energy, irradiance, units
file1sc='/Users/twoods/Documents/CubeSat/NASA_MinXSS/Papers/DAXSS_Rocket_X123_Papers/daxss_countrate.sav'
restore, file1sc ; countrate
file1r = '/Users/twoods/Documents/CubeSat/NASA_MinXSS/Papers/DAXSS_Rocket_X123_Papers/daxss_response_final.sav'
restore,file1r  ; response
dE2018 = energy[1]-energy[0]
; estimate response to verify countrate is normalized correctly
response2018bad = countrate / (irradiance > 1) / dE2018
wbad=where(irradiance le 1.)
wgd =where(irradiance gt 1.)
response2018 = response2018bad
response2018[wbad] = interpol( response2018bad[wgd], energy[wgd], energy[wbad] )

; read X55 2021 rocket data
file2s='/Users/twoods/Dropbox/minxss_dropbox/rocket_eve/36.353/TM_Data/Flight/TM1/x55_packets_36353.sav'
restore, file2s  ; x55_packets[5170] data structure array, solar data [279:378]
; ramp up at Time_since_on[277] = 941.8s (shutter door ~T+85s), Time_since_on[381] = 1319.6s (shutter door ~T+476)
kstart=280L & kend=377L
x55_countrate = fltarr(1024)
cnt = 0L

x55_energy = energy*0.78+0.7*dE2018
x55_dE = 0.78*dE2018
wlow = where(x55_energy le 3.0)
bin_max = long(max(wlow))
print, 'X55 Energy 3.0 keV limit is at bin=', bin_max
; stop, 'DEBUG x55_energy for 3 keV ...'

for k=kstart,kend do begin
  ; x55_live_time provides correction for dead-time instead of using x55_accum_time
  if (total(x55_packets[k].x55_spectra) gt 100.) and (x55_packets[k].x55_live_time gt 1.) $
  			and (x55_packets[k].x55_bin_limit ge bin_max) then begin
  	x55_countrate += x55_packets[k].x55_spectra / x55_packets[k].x55_live_time
  	cnt++
  endif
endfor
print, 'X55 Total Integration is ',strtrim(cnt,2), ' Integrations.'
x55_countrate /= float(cnt)

;
; calculate x55_irradiance
; 		USE calculated response instead of response from Robert
x55_response = interpol(response2018, energy, x55_energy)
x55_irradiance = x55_countrate / (x55_response > 1E-10) / x55_dE
wlow = where(x55_response eq 0)
x55_irradiance[wlow] = 0.

setplot & cc=rainbow(7)
plot, energy, countrate, psym=10, xr=[0,4], xs=1, yrange=[0,max(x55_countrate)], $
			xtit='Energy (keV)', ytit='Count Rate (cps)', tit='Black=2018, Green=2021'
oplot, x55_energy,x55_countrate, psym=10, color=cc[3]
oplot, [0.5,0.5], !y.crange,line=2

ans= ' '
read, 'Next Plot ? ',ans

setplot & cc=rainbow(7)
yr2 = [1E1,1E10]
plot, energy, irradiance, psym=10, xr=[0,4], xs=1, yrange=yr2,ys=1,/ylog, $
			xtit='Energy (keV)', ytit='Irradiance (ph/s/cm!U2!N/keV)', tit='Black=2018, Green=2021'
oplot, x55_energy,x55_irradiance, psym=10, color=cc[3]
oplot, [0.5,0.5], 10.^!y.crange,line=2

read, 'Next Plot ? ',ans

;	compare to CH-2 SXM at same time (do on UT minutes)
;   first make 1-min averages for T+180 to T+360 (T+420 end)
;	RESULTS:
;		Making X55 Spectra with 1-min averages:
;		   i = 0 # samples = 15 for T+180sec  CountRate=14950  Slow=14402
;		   i = 1 # samples = 15 for T+240sec  CountRate=14571  Slow=14027
;		   i = 2 # samples = 14 for T+300sec  CountRate=14392  Slow=13846
;		   i = 3 # samples = 15 for T+360sec  CountRate=14120  Slow=13596
;
x55_spectra = fltarr(4,1024)
x55_countrate = fltarr(4)
x55_slow_rate = fltarr(4)
time_min = [3.,4,5,6]
x55_time_hour = 17.+(25.+time_min+0.5)/60.
x55_time_sod = x55_time_hour * 3600.
;  fix X55_PACKETS time keeping and convert to T+x flight time
x55_time = x55_packets.x55_time_since_on + findgen(n_elements(x55_packets))*0.115
t85 = x55_time[277]
x55_time = x55_time - t85 + 85.
print, ' '
print, 'Making X55 Spectra with 1-min averages:'
setplot & cc=rainbow(25)

for i=0,3 do begin
	wgd =where( (x55_time ge (time_min[i]*60.)) and (x55_time lt ((time_min[i]+1.)*60.)), numgd )
	temp_countrate = fltarr(1024)
	temp_slow_rate = 0.0
	cnt=0L
	for k=0,numgd-1 do begin
		if (total(x55_packets[wgd[k]].x55_spectra) gt 100.) and (x55_packets[wgd[k]].x55_live_time gt 1.) $
					and (x55_packets[wgd[k]].x55_bin_limit ge bin_max) then begin
			new_countrate = x55_packets[wgd[k]].x55_spectra / x55_packets[wgd[k]].x55_live_time
			temp_countrate += new_countrate
			temp_slow_rate += x55_packets[wgd[k]].x55_slow_count / x55_packets[wgd[k]].x55_accum_time
			cnt++
			if (cnt eq 1) then plot, x55_energy, /nodata, new_countrate, yr=[0,500], ys=1, $
					xr=[0,5], xs=1, xtit='Energy (keV)', ytit='Count Rate (cps)', $
					tit='T+'+strtrim(long(time_min[i]),2)+'min'
			oplot, x55_energy, new_countrate, psym=10, color=cc[k]
		endif
	endfor
	temp_countrate /= float(cnt)
	temp_slow_rate /= float(cnt)
	x55_countrate[i] = total(temp_countrate)
	x55_slow_rate[i] = temp_slow_rate
	x55_spectra[i,*] = temp_countrate / (x55_response > 1E-10) / x55_dE
	x55_spectra[i,wlow] = 0.
	print, '   i = ',strtrim(i,2), ' # samples = ',strtrim(cnt,2), ' for T+', $
			strtrim(long(time_min[i]*60.),2), 'sec  CountRate=', strtrim(long(x55_countrate[i]),2), $
			'  Slow=',strtrim(long(x55_slow_rate[i]),2)
	read, 'Next 1-min Plot ? ',ans
endfor
print, ' '

setplot & cc=rainbow(7)
plot, energy, irradiance, psym=10, xr=[0,4], xs=1, yrange=yr2,ys=1,/ylog, $
			xtit='Energy (keV)', ytit='Irradiance (ph/s/cm!U2!N/keV)', tit='Black=2018, Color=2021'
for k=0,3 do oplot, x55_energy,x55_spectra[k,*], psym=10, color=cc[k]
oplot, [0.5,0.5], 10.^!y.crange,line=2

;
;	do text (*.dat) file for the four 1-min averages
;	Restrict to 0.5 - 3.5 keV range
;
wkeep = where(x55_energy ge 0.5 and x55_energy le 3.0, num_keep)
data = fltarr(5,num_keep)
data[0,*] = x55_energy[wkeep]
for k=0,3 do data[k+1,*] = reform(x55_spectra[k,wkeep])
data_file = 'x55_36353_1-min-averages.dat'
print, ' '
print, 'Writing X55 0.5-3.0 keV spectra to ',data_file
write_dat,data,file=data_file, format='(F8.4,4E12.4)', $
	comments=['NASA 36.353 X55 (DAXSS-2) Preliminary Irradiance', $
		'Sept. 9, 2021 Launch, 17:28:30UT, 17:29:30UT, 17:30:30UT, 17:31:30UT', $
		'Contact: Tom Woods, tom.woods@lasp.colorado.edu'], $
	lintext='NASA 36.353 X55 Preliminary Irradiance for Sept 9, 2021', $
	coltext='Energy_keV, Four Irradiance Spectra in units of photons/s/cm^2/keV'

end
