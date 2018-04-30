;
;	solar_esp.pro
;
;	Extract out solar signal for ESP from 36.233 data
;		CALIBRATION:  pre-flight calibration data near T-260
;		Option 1:  the data near 155 km on up-leg
;		Option 2:  rapid integration data during T+110 and T+450
;
;	Tom Woods
;	10/30/06
;
pro solar_esp, result, rawesp=rawesp

;
;	read the data
;
fileesp = '36233Flt_1m_esp.dat'
tzero = 17.*3600. + 58.*60.    ; launch time
plot_esp, fileesp, esp, tzero=tzero, xrange=[90,120]

esp.time = esp.time - tzero		; force always relative time
integ_time = 0.25				; default integration time

; optional output
rawesp = esp

;
;	CALIBRATION:  pre-flight calibration data near T-260
;
tcal = -260.
temp = min( abs(esp.time - tcal), wmin )
wextra = 15L
calesp = fltarr(9)
for k=0,8 do calesp[k] = mean( esp[wmin-wextra:wmin+wextra].cnt[k] )
calesp = calesp / integ_time
print, ' '
print, ' ESP #    Calibration (Hz)'
formc = '(I4,F15.1)'
for k=0,8 do print, k+1, calesp[k], format=formc

;
;	Option 1:  the data near 155 km on up-leg
;		T+108 to T+110 is from 154 km to 156.8 km (predicted)
;
t1solar = 109.0
temp = min( abs(esp.time - t1solar), wmin )
wextra = 2L
totalesp1 = fltarr(9)
for k=0,8 do totalesp1[k] = mean( esp[wmin-wextra:wmin+wextra].cnt[k] )
totalesp1 = totalesp1 / integ_time

t1back = 88.0
temp = min( abs(esp.time - t1back), wmin2 )
textra = 7L
backesp1 = fltarr(9)
for k=0,8 do backesp1[k] = mean( esp[wmin2-wextra:wmin2+wextra].cnt[k] )
backesp1 = backesp1 / integ_time

solesp1 = totalesp1 - backesp1

print, ' '
print, 'RESULTS at 155 km (T+109sec)'
print, ' ESP #    Total (Hz)    Background (Hz)      Solar (Hz)'
form = '(I4,F12.1,F16.1, F20.1)'
for k=0,8 do print, k+1, totalesp1[k], backesp1[k], solesp1[k], format=form

;
;	Option 2:  rapid integration data during T+110 and T+450
;	only select near-apogee data (near 260 km at 260 sec)
;	estimate real integration time by ESP#3 counts (assumes ESP#3 is DARK diode)
;
t2back = 460.0
temp = min( abs(esp.time - t2back), wmin2 )
textra = 7L
backesp2 = fltarr(9)
for k=0,8 do backesp2[k] = mean( esp[wmin2-wextra:wmin2+wextra].cnt[k] )
backesp2 = backesp2 / integ_time

t2solar1 = 210.
t2solar2 = 310.
;
;  estimate integration time based on ESP#3 (index 2) counts
;  because CLASSIC HV had significant noise that was causing ESP to integrate for short period of times
;
refch = 3L - 1
eslope = (backesp2[refch] - backesp1[refch]) / (t2back - t1back)
est_backesp = backesp1[refch] + eslope * (esp.time - t1back)
est_integ_time = esp.cnt[refch] / est_backesp

wgood1 = where( (esp.time ge t2solar1) and (esp.time le t2solar2) )
wgood2 = where( (esp.time ge t2solar1) and (esp.time le t2solar2) $
	and (est_integ_time ge median(est_integ_time[wgood1])))
totalesp2 = fltarr(9)
for k=0,8 do totalesp2[k] = total( esp[wgood2].cnt[k] )
est_integ_time_total = total(est_integ_time[wgood2])
totalesp2 = totalesp2 / est_integ_time_total

solesp2 = totalesp2 - (backesp1+backesp2)/2.

print, ' '
print, 'RESULTS at APOGEE assuming ESP#3 gives integration time'
print, 'T+210 to T+310 has approximately ', strtrim(est_integ_time_total,2), ' sec integration time'
print, ' ESP #    Total (Hz)    Background (Hz)      Solar (Hz)'
form = '(I4,F12.1,F16.1, F20.1)'
for k=0,8 do print, k+1, totalesp2[k], backesp2[k], solesp2[k], format=form

result = fltarr(4,9)
result[0,*] = findgen(9)+1
result[1,*] = calesp
result[2,*] = solesp1
result[3,*] = solesp2

return
end
