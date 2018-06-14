;
;	timer_validate.pro
;
;	Validate the rocket Timer times using analog data
;
;	INPUT
;		filename	file name (*analogs.dat or '' to ask user to select file)
;		tzero       time (sec of day) for zero time (launch Time)
;		debug		stop at end of procedure
;
;	OUTPUT
;		log			log messages of timer checks
;
; EXAMPLE
;   file = dialog_pickfile( /read, filter='TM1*' )
;   timer_validate, file, log, rocket=36.318, /debug
;
;	3/5/2016	Tom Woods   original code
; 5/3/2016  Tom Woods   Update with call to read_tm1_rt.pro
;
pro timer_validate, filename, log, tzero=tzero, rocket=rocket, debug=debug

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick All Analogs Data File', filter='*analogs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

rnum = 36.318
if keyword_set(rocket) then rnum = rocket
if (rnum ne 36.275) and (rnum ne 36.233) and (rnum ne 36.240) and (rnum ne 36.258) $
	and (rnum ne 36.286) and (rnum ne 36.290) and (rnum ne 36.300) and (rnum ne 36.318) then begin
  stop, 'STOP:  ERROR with "rnum"...'
endif
rocket_str = string(rnum,format='(F6.3)')

;
;	get the analog data
;     First check is *.sav file exists, else read in binary data (which is very slow)
;
print, 'Reading analog data from ', filename, ' ... '
fp = rstrpos( filename, '.dat' )
flen = strlen(filename)
if (fp ne (flen-4)) then begin
  ; reading will be very slow the first time
  print, '      Reading full TM1 file, so it will be slow.'
  read_tm1_rt, filename, /analog, rocket=rnum, debug=debug
  print, ' '
  filename += '_analogs.dat'
endif
;  reading the saved binary file of analog data records
plot_analogs, filename, data, /noplot, rocket=rnum, debug=debug

if keyword_set(debug) then stop, 'STOP: Check out analog "data" ...'

; UT time for launch time
if (rnum eq 36.217) then tz = 18*3600L + 23*60L + 30  $
else if (rnum eq 36.240) then tz = 16*3600L + 58*60L + 0.72D0 $
else if (rnum eq 36.258) then tz = 18*3600L + 32*60L + 2.00D0 $
else if (rnum eq 36.275) then tz = 17*3600L + 50*60L + 0.354D0 $
else if (rnum eq 36.286) then tz = 18*3600L + 30*60L + 1.000D0 $
else if (rnum eq 36.290) then tz = 18*3600L + 0*60L + 0.4D0 $
else if (rnum eq 36.300) then tz = 19*3600L + 14*60L + 25.1D0 $
else tz = data[0].time

if keyword_set(tzero) then tz = tzero
;  check for invalid T_zero time (needs to be within range of data.time
if (tz lt min(data.time)) or (tz gt max(data.time)) then begin
	; Try shifting T-zero to local time (MDT to UT is -6 hours)
	tz -= (6.*3600.)
	if (tz lt min(data.time)) or (tz gt max(data.time)) then tz=data[0].time
endif
ptime = (data.time - tz)		; relative time


;
;	configuration for timer times (T time for 36.290)
;
timer_times = [ 52., 53, 82, 83, 90, 452, 459, 469, 500, 530, 580, 585, 586 ]
timer_names = ['A', 'B', 'D', 'E', 'H', 'G', 'M', 'N', 'F', 'K', 'L', 'P', 'R']

num_timers = n_elements(timer_times)
log = strarr( num_timers )
timer_actual = fltarr(num_timers)

nformat = '(F8.2)'

nsmooth = 7   ; smooth by ~10 msec

gv_offset = -3.3  ; offset to properly align with Timer and Gate Valve (GV) movement

;
;	First check that T_zero (launch time) is appropriate based on Timer D (Gate Valve open)
;
;	Index 2		D = GATE_VALVE goes from 1.0V to 0.0V (with 0.1V noise)
;
sm_gate_valve = smooth( data.gate_valve, nsmooth, /edge_trun )
wclose = where( (sm_gate_valve gt 0.8) and (sm_gate_valve lt 1.2), numclose )
wmove = where(sm_gate_valve lt 0.2, nummove )
wopen = where(sm_gate_valve gt 3.6, numopen )
;
;	Look for Open Cycle on 1-sec grid to tune in T-zero time
;		1.1V for 5sec, 0.1V for 7sec, 3.8V for 10sec
;
gnum = long(max(ptime)-min(ptime))
gtime = fltarr(gnum)
gtime = long(min(ptime))+0.5 + findgen(gnum)
g_gate_valve = interpol( sm_gate_valve, ptime, gtime )
gv_open = [ 1.1, 1.1, 1.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, $
		3.8, 3.8, 3.8, 3.8, 3.8, 3.8, 3.8, 3.8, 3.8, 3.8]
nprofile=n_elements(gv_open)
gv_chi = fltarr(gnum) + nprofile*10.  ; maximum value
for k=nprofile/2L,gnum-nprofile/2L-1 do $
	gv_chi[k] = total(abs(g_gate_valve[k-nprofile/2L:k+nprofile/2L-1] - gv_open))
temp1 = min( gv_chi, wopen1 )
time_open1 = gtime[wopen1]
if (temp1 gt 20.) then print, "WARNING: Gate Valve Open wasn't observed !"
;
;  search for max time near time_open1 when Closed and min time near time_open1 when Moving
;
wclose1 = where( (sm_gate_valve gt 0.8) and (sm_gate_valve lt 1.2) and abs(ptime-time_open1) lt 10, numclose )
wmove1 = where(sm_gate_valve lt 0.2 and abs(ptime-time_open1) lt 10, nummove )
time1a = max(ptime[wclose1])
time1b = min(ptime[wmove1])
timer_actual[2] = (time1a + time1b)/2.
;  adjust this timer by 0.24 sec because of mechanical response time for gate valve
timer_actual[2] += gv_offset
if abs(timer_actual[2] - timer_times[2]) gt 1.0 then begin
	new_tzero = tz + (timer_actual[2] - timer_times[2])
	new_hour = long(new_tzero / 3600.)
	new_min = long((new_tzero-new_hour*3600.) / 60.)
	new_sec = new_tzero-new_hour*3600.-new_min*60.
	new_tzero_str = string(new_hour,format='(I02)') + ':' + string(new_min,format='(I02)') $
						+ ':' + string(new_sec,format='(F05.2)')
	old_hour = long(tz / 3600.)
	old_min = long((tz-old_hour*3600.) / 60.)
	old_sec = tz-old_hour*3600.-old_min*60.
	old_tzero_str = string(old_hour,format='(I02)') + ':' + string(old_min,format='(I02)') $
						+ ':' + string(old_sec,format='(F05.2)')
	print, ' '
	print, 'Current T_zero (launch time) is at ', old_tzero_str
	print, 'Predicted Launch Time based on Gate Valve opening is at ', new_tzero_str
	ans = ' '
	read, 'Do you want to use this new T_zero time ? ', ans
	if strupcase(strmid(ans,0,1)) eq 'Y' then begin
		tz = new_tzero
		ptime = (data.time - tz)
		timer_actual[2] = timer_times[2]
	endif
endif
log[2] = 'Timer D (T  '+strtrim(long(timer_times[2]),2)+'sec) occurred at '+$
			string(timer_actual[2],format=nformat)

; Index 0		A = MEGSA_FF and MEGSB_FF go from 0.05V to 0.3V (with 0.05V noise)
sm_megsa_ff = smooth( data.megsa_ff, nsmooth, /edge_trun )
sm_megsb_ff = smooth( data.megsb_ff, nsmooth, /edge_trun )
whi = where( sm_megsa_ff gt 0.20, numhi )
wlow = where(sm_megsa_ff lt 0.15, numlow )
temp1 = min( abs(ptime[whi] - timer_times[0]), wmin1 )
temp2 = min( abs(ptime[wlow] - timer_times[0]), wmin2 )
; timer_actual[0] = (ptime[whi[wmin1]] + ptime[wlow[wmin2]])/2.
timer_actual[0] = (temp1 gt temp2 ? ptime[whi[wmin1]] : ptime[wlow[wmin2]] )
log[0] = 'Timer A (T  '+strtrim(long(timer_times[0]),2)+'sec) occurred at '+$
			string(timer_actual[0],format=nformat)

; Index 1		B = MEGSA_FF and MEGSB_FF go from 0.3V to 0.05V
;whi = where( sm_megsa_ff gt 0.20, numhi )
;wlow = where(sm_megsa_ff lt 0.15, numlow )
temp1 = min( abs(ptime[whi] - timer_times[1]), wmin1 )
temp2 = min( abs(ptime[wlow] - timer_times[1]), wmin2 )
; timer_actual[1] = (ptime[whi[wmin1]] + ptime[wlow[wmin2]])/2.
timer_actual[1] = (temp1 gt temp2 ? ptime[whi[wmin1]] : ptime[wlow[wmin2]] )
log[1] = 'Timer B (T  '+strtrim(long(timer_times[1]),2)+'sec) occurred at '+$
			string(timer_actual[1],format=nformat)

; Index 3		E = unable to confirm
log[3] = 'Timer E (T  '+strtrim(long(timer_times[3]),2)+'sec) can not be confirmed.'

; Index 4		H = unable to confirm (unless have HVS monitor)
log[4] = 'Timer H (T  '+strtrim(long(timer_times[4]),2)+'sec) can not be confirmed.'

; Index 5		G = unable to confirm
log[5] = 'Timer G (T '+strtrim(long(timer_times[5]),2)+'sec) can not be confirmed.'

; Index 6		M = GATE_VALVE goes from 3.8V to 0.0V
temp1 = min( abs(ptime[wopen] - timer_times[6]), wclose1 )
temp2 = min( abs(ptime[wmove] - timer_times[6]), wclose2 )
; timer_actual[6] = (ptime[wopen[wclose1]] + ptime[wmove[wclose2]])/2.
timer_actual[6] = (temp1 gt temp2 ? ptime[wopen[wclose1]] : ptime[wmove[wclose2]] )
;  adjust this timer by 0.24 sec because of mechanical response time for gate valve
; timer_actual[6] += gv_offset
if abs(timer_actual[6] - timer_times[6]) gt 10 then begin
	log[6] = 'Timer M (T '+strtrim(long(timer_times[6]),2)+'sec) ERROR (not seen) with detection at '+$
			string(timer_actual[6],format=nformat)
endif else begin
	log[6] = 'Timer M (T '+strtrim(long(timer_times[6]),2)+'sec) occurred at '+$
			string(timer_actual[6],format=nformat)
endelse

; Index 7		N = unable to confirm
log[7] = 'Timer N (T '+strtrim(long(timer_times[7]),2)+'sec) can not be confirmed.'

; Index 8		F = MEGSA_FF and MEGSB_FF go from 0.05V to 0.3V (with 0.05V noise)
;whi = where( sm_megsa_ff gt 0.20, numhi )
;wlow = where(sm_megsa_ff lt 0.15, numlow )
temp1 = min( abs(ptime[whi] - timer_times[8]), wmin1 )
temp2 = min( abs(ptime[wlow] - timer_times[8]), wmin2 )
; timer_actual[8] = (ptime[whi[wmin1]] + ptime[wlow[wmin2]])/2.
timer_actual[8] = (temp1 gt temp2 ? ptime[whi[wmin1]] : ptime[wlow[wmin2]] )
if abs(timer_actual[8] - timer_times[8]) gt 10 then begin
	log[8] = 'Timer F (T '+strtrim(long(timer_times[8]),2)+'sec) ERROR (not seen) with detection at '+$
			string(timer_actual[8],format=nformat)
endif else begin
	log[8] = 'Timer F (T '+strtrim(long(timer_times[8]),2)+'sec) occurred at '+$
			string(timer_actual[8],format=nformat)
endelse

; Index 9		K = MEGSA_FF and MEGSB_FF go from 0.3V to 0.05V
;whi = where( sm_megsa_ff gt 0.20, numhi )
;wlow = where(sm_megsa_ff lt 0.15, numlow )
temp1 = min( abs(ptime[whi] - timer_times[9]), wmin1 )
temp2 = min( abs(ptime[wlow] - timer_times[9]), wmin2 )
; timer_actual[9] = (ptime[whi[wmin1]] + ptime[wlow[wmin2]])/2.
timer_actual[9] = (temp1 gt temp2 ? ptime[whi[wmin1]] : ptime[wlow[wmin2]] )
if abs(timer_actual[9] - timer_times[9]) gt 10 then begin
	log[9] = 'Timer K (T '+strtrim(long(timer_times[9]),2)+'sec) ERROR (not seen) with detection at '+$
			string(timer_actual[9],format=nformat)
endif else begin
	log[9] = 'Timer K (T '+strtrim(long(timer_times[9]),2)+'sec) occurred at '+$
			string(timer_actual[9],format=nformat)
endelse

; Index 10		L = unable to confirm
log[10] = 'Timer L (T '+strtrim(long(timer_times[10]),2)+'sec) can not be confirmed.'

; Index 11		P = FPGA_5V goes from 0.45V to 0.0V (with 0.05V noise)
sm_fpga_5v = smooth( data.fpga_5v, nsmooth, /edge_trun )
w5hi = where( (sm_fpga_5v gt 0.35) and (sm_fpga_5v lt 0.55), num5hi )
w5low = where(sm_fpga_5v lt 0.1, num5low )
temp1 = min( abs(ptime[w5hi] - timer_times[11]), wmin1 )
temp2 = min( abs(ptime[w5low] - timer_times[11]), wmin2 )
; timer_actual[11] = (ptime[w5hi[wmin1]] + ptime[w5low[wmin2]])/2.
timer_actual[11] = (temp1 gt temp2 ? ptime[w5hi[wmin1]] : ptime[w5low[wmin2]] )
if abs(timer_actual[11] - timer_times[11]) gt 10 then begin
	log[11] = 'Timer P (T '+strtrim(long(timer_times[11]),2)+'sec) ERROR (not seen) with detection at '+$
			string(timer_actual[11],format=nformat)
endif else begin
	log[11] = 'Timer P (T '+strtrim(long(timer_times[11]),2)+'sec) occurred at '+$
			string(timer_actual[11],format=nformat)
endelse

; Index 12		R = unable to confirm
log[12] = 'Timer R (T '+strtrim(long(timer_times[12]),2)+'sec) can not be confirmed.'

print, ' '
for k=0,num_timers-1 do begin
	print, log[k]
endfor
print, ' '

if keyword_set(debug) then stop, 'DEBUG: stopped at end of timer_validate.pro ...'

return
end
