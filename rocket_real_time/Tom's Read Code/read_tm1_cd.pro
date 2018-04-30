;
;	read_tm1_cd.pro
;
;	Read NSROC 36.286 TM1 CD data files
;		Serial Data
;		Analog Monitors
;
;	Extract out data from TM1
;	Changed to 5 Mbps for 36.240 (March 2008)
;	Changed some analog monitors for 36.240
;	Added Serial Data for GOES-R XRS
;
;	INPUT
;		filename    filename of 36233*.bin or not given or '' to ask user to select file
;
;		launchtime=launchtime   time (SOD) for T-0   (or first time in file if not given)
;		time=time               time for extraction (seconds relative to T-0) < fltarr[2] >
;
;		single=single           single analog monitor with [X, Y, DX, DY] specified as array
;		analog=analog           all of the experiment analog monitors
;
;		/esp           serial data for ESP
;		/pmegs         serial data for MEGS-P
;       /xps           serial data for XPS
;       /axs           serial data for AXS
;		/xrs		   serial data for X123
;		/x123		   serial data for X123 (first on 36.290)
;		/cmd		   serial data for CMD Box / FPGA (first on 36.290)
;
;	OUTPUT
;
;		data        data extracted as time series if analog monitor or spectra if serial data
;
;	10/12/06
;	Tom Woods
;
;	Updated Apr 08 for 36.258 - included ROCKET option to specify the rocket number
;	Updated May 12 for 36.286 - TM1 format - monitor placement - changed
;	Updated Oct 22 for 36.290 - TM1 format changed
;
;	Usage:
;		!path = '/Users/Shared/Projects/Rocket_Folder/Data_36290/WSMR/code:' + !path
;		read_tm1_cd, file1, rocket=36.290, /analog, /esp, /pmegs, /xrs, /x123, /cmd
;
;
pro  read_tm1_cd, filename, launchtime=launchtime, time=time, single=single, analog=analog, $
					esp=esp, pmegs=pmegs, xps=xps, axs=axs, xrs=xrs, x123=x123, cmd=cmd, $
					debug=debug, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick TM CD Data File', filter='36*.log')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

;
;  open the TM CD Data file
;	Record is 83 words (166 bytes) x 8 rows
;	TM Record is 80 words for each row PLUS 3 words of time
;
;	NOTE:  words have bytes flipped for MAC but code written for any computer
;
openr,lun, filename, /get_lun

fb1 = rstrpos( filename, '/' )
if (fb1 lt 0) then fb1 = -1L
fb2 = rstrpos( filename, '.' )
if (fb2 lt 0) then fb2 = strlen(filename)
fbase = strmid( filename, fb1+1, fb2-fb1-1 ) + '_'

if keyword_set(rocket) then rnum = rocket else rnum = 36.290
if (rnum ne 36.290) and (rnum ne 36.286) and (rnum ne 36.275) and (rnum ne 36.240) $
	and (rnum ne 36.233) then begin
  print, 'ERROR: rocket number is not valid, resetting to 36.290'
  rnum = 36.290
endif
print, 'Processing for rocket # ', string(rnum,format='(F7.3)')

if not keyword_set(launchtime) then begin
  launchtime = 0.0D0
  ; fpos = strpos( filename, 'Flt' )
  if (rnum eq 36.217) then launchtime = 18*3600L + 23*60L + 30  ; UT time
  if (rnum eq 36.240) then launchtime = 16*3600L + 58*60L + 0.72D0
  if (rnum eq 36.258) then launchtime = 18*3600L + 32*60L + 2.00D0
  if (rnum eq 36.275) then launchtime = 17*3600L + 50*60L + 0.354D0
  if (rnum eq 36.286) then launchtime = 19*3600L + 30*60L + 1.000D0
  if (rnum eq 36.290) then launchtime = 18*3600L + 0*60L + 0.000D0
  print, 'NOTE:  set launch time for ', strtrim(launchtime,2), ' sec of day'
endif

;  36.290 has TM1 format changed
;  36.275 and 36.233 and 36.240 TM1 packet size and sync are the same but monitor placements are different
;  36.233 had 1 Mbps TM and  36.240 & 36.258 has 5 Mbps TM
;  Several analog monitors changed for 36.258

ncol = 83L
nrow = 8L

nbytes = ncol*2L * nrow		; sync_1 + 3 words of time + sfid + 76 words of data + sync_2 + sync_3
nint = nbytes/2L
a = assoc( lun, uintarr(ncol,nrow) )

finfo = fstat(lun)
fsize = finfo.size
pcnt = fsize/nbytes
print, ' '
print, 'READ_TM1_CD:  ',strtrim(pcnt,2), ' records in ', filename

;
;	define constants / arrays for finding sync values
;
;	For 36.233 (1 Mbps) - 2006
;	Same for 36.240 (5 Mbps) - 2008
;	Same for 36.258 (5 Mbps) - 2010
;	Same for 36.275 (5 Mbps) - 2010
;	Same for 36.286 (5 Mbps) - 2012
;	Same for 36.290 (5 Mbps) - 2013
;
if (rnum eq 36.233) or (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) $
		or (rnum eq 36.286) or (rnum eq 36.290) then begin
  wordmask = '03FF'X
  sync1value = '0100'X
  sync1offset = 0L

  sync2value = '03EB'X
  sync2offset = nint-2L

  sync3value = '0333'X
  sync3offset = nint-1L
endif

acnt = 0L
aindex=ulong(lonarr(pcnt))
atime = dblarr(pcnt)

pcnt10 = pcnt/10L

;
;	find first valid time
;
for k=0L,pcnt-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) and $
  			((data[sync3offset] and wordmask) eq sync3value) then begin
    time1 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	time1 = time1 / 1000.D0   ; convert msec to sec
  	goto, gottime1
  endif
endfor

gottime1:
print, ' '
timetemp = time1
if (launchtime eq 0) then launchtime = time1   ;  set T+0 as start of file if launch time not given
hr = fix(timetemp/3600.)
min = fix((timetemp-hr*3600.)/60.)
sec = fix(timetemp-hr*3600.-min*60.)
print, 'Start Time = ', strtrim(hr,2), ':', strtrim(min,2), ':', strtrim(sec,2), ' at T ',strtrim(timetemp-launchtime,2)

;
;	find last valid time
;
for k=pcnt-1L,0L,-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) and $
  			((data[sync3offset] and wordmask) eq sync3value) then begin
    time2 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	time2 = time2 / 1000.D0   ; convert msec to sec
  	goto, gottime2
  endif
endfor

gottime2:
print, ' '
timetemp = time2
hr = fix(timetemp/3600.)
min = fix((timetemp-hr*3600.)/60.)
sec = fix(timetemp-hr*3600.-min*60.)
print, 'Stop  Time = ', strtrim(hr,2), ':', strtrim(min,2), ':', strtrim(sec,2), ' at T ',strtrim(timetemp-launchtime,2)
print, ' '

if keyword_set(time) then begin
  mytime = time
endif else begin
  mytime = [ 0., time2-time1]  ; all of the file, but ask user
  read, 'Enter time range (relative to T+0 in sec) [or -1000 for all] : ', mytime
  if (mytime[0] le -1000) then begin
    mytime=0
  endif
endelse

if n_elements(mytime) ge 2 then begin
  dtime = (time2-time1)/pcnt
  kstart = long( (mytime[0] - (time1 - launchtime)) / dtime )
  if (kstart lt 0) then kstart = 0L
  if (kstart ge pcnt) then kstart = pcnt-1
  if n_elements(mytime) lt 2 then kend = pcnt-1L else begin
    kend = long( (mytime[1] - (time1 - launchtime)) / dtime )
    if (kend lt 0) then kend = 0L
    if (kend ge pcnt) then kend = pcnt-1
  endelse
  if (kstart gt kend) then begin
    ktemp = kend
    kend = kstart
    kstart = ktemp
  endif
  timestr = strtrim(long(mytime[0]),2) + '_' + strtrim(long(mytime[1]),2) + '_'
endif else begin
  kstart = 0L
  kend = pcnt-1L
  timestr = ''
endelse
ktotal = kend - kstart + 1L

;
;	set up files / variables
;
fbase = fbase + timestr
fend = '.dat'

if keyword_set(single) then begin
  if n_elements(single) lt 2 then single = 0 else begin
    ;
    ;  single array = [ X, Y, dX, dY, maxX, maxY ]   only X, Y must be given
    ;
    ;	For TM1 definitions:  X = WD+3, Y = FR-1
    ;
    dummy = uintarr(ncol,nrow)
    dummy2 = extract_item( dummy, single )
    numsingle = n_elements(dummy2)
    dummy=0
    dummy2=0
    ;
    ;  open SINGLE file
    ;
    fsingle = fbase + 'sa-'+strtrim(single[0],2)+'-'+strtrim(single[1],2) $
    	+ '_' + strtrim(numsingle,2) + fend
    print, 'Saving single analog in ', fsingle
    openw,slun,fsingle,/get_lun
    sa = assoc(slun,dblarr(numsingle+1L))
    sdata = dblarr(numsingle+1L)
  endelse
endif
if keyword_set(analog) then begin
  ;
  ;   define the TM items for all of the analog monitors
  ;		X = WD + 3, Y = FR - 1
  ;
  if (rnum eq 36.233) then begin
    numanalogs = 33L
    axy = [ [79,3], [43,0], [70,0], $
  			[70,7], [43,7], [70,6], $
  			[67,6], [70,2], [67,7], $
  			[68,3], [71,0], [71,1], $
  			[68,4], [44,1], [43,3], $
  			[68,5], [68,0], [44,7], $
  			[44,3], [67,4], [67,5], $
  			[70,4], [68,6], [68,7], $
  			[70,5], [70,3], [67,1], $
  			[67,2], [67,3], [44,5], $
  			[67,0], [68,2], [68,1] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			megs_pwr: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xps_temp: 0.0, classic_fpga_temp: 0.0, classic_temp: 0.0, $
  			classic_hv1: 0.0, classic_hv2: 0.0, classic_hv10v: 0.0, $
  			classic_integ_bit0: 0.0, classic_integ_bit1: 0.0, axs_tec_hot: 0.0, $
  			axs_hv: 0.0, axs_temp: 0.0, axs_tec_temp: 0.0 }
  endif else if (rnum eq 36.240) then begin
    ;  Note that left structure the same but changes include:
    ;				MEGS_PWR = EXP_CUR (includes name change)
    ;				CLASSIC_FPGA_TEMP = XPS_TEMPB  (includes name change)
    ;				CLASSIC_TEMP = XPS_TEMPB
    ;				CLASSIC_HV1, _HV2, _hv10V = AXS_HV
    ;				CLASSIC_INTEG_BIT0, _BIT1 = TV_POS
    numanalogs = 33L
    axy = [ [77,1], [73,1], [58,6], $
  			[61,5], [56,1], [61,4], $
  			[57,4], [61,0], [57,5], $
  			[58,7], [61,6], [61,7], $
  			[58,2], [56,2], [56,0], $
  			[58,3], [57,6], [56,5], $
  			[56,3], [57,3], [57,2], $
  			[61,2], [58,1], [58,1], $
  			[56,6], [56,6], [56,6], $
  			[56,1], [56,1], [56,4], $
  			[56,6], [58,0], [57,7] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			exp_cur: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xps_tempa: 0.0, xps_tempb: 0.0, classic_temp: 0.0, $
  			classic_hv1: 0.0, classic_hv2: 0.0, classic_hv10v: 0.0, $
  			classic_integ_bit0: 0.0, classic_integ_bit1: 0.0, axs_tec_hot: 0.0, $
  			axs_hv: 0.0, axs_temp: 0.0, axs_tec_temp: 0.0 }
  endif else if (rnum eq 36.258) or (rnum eq 36.275) then begin
    ;  Note that left structure the same but changes include:
    ;				EXP_CUR = CRYO_TEMP2 (includes name change)
    ;				AXS_TEC_HOT = XRS_TEMP2 (includes name change)
    ;				AXS_HV = XRS_P5V (includes name change)
    ;				AXS_TEMP = XRS_M5V (includes name change)
    ;				AXS_TEC_TEMP = XRS_TEMP1 (includes name change)
    ;		Removed:	CLASSIC_TEMP, _HV1, _HV2, _hv10V
    ;					CLASSIC_INTEG_BIT0, _BIT1
    numanalogs = 27L
    axy = [ [77,1], [73,1], [58,6], $
  			[61,5], [56,1], [61,4], $
  			[57,4], [61,0], [57,5], $
  			[58,7], [61,6], [61,7], $
  			[58,2], [56,2], [56,0], $
  			[58,3], [57,6], [56,5], $
  			[56,3], [57,3], [57,2], $
  			[61,2], [58,1], [56,4], $
  			[56,6], [58,0], [57,7] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			cryo_temp2: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xps_tempa: 0.0, xps_tempb: 0.0, xrs_temp2: 0.0, $
  			xrs_p5v: 0.0, xrs_m5v: 0.0, xrs_temp1: 0.0 }
   endif else if (rnum eq 36.286) then begin
    ;  Note smaller structure, changes include:
    ;		Removed:		AXS_HV, AXS_TEMP, AXS_TEC_TEMP
    ;   define the TM items for all of the analog monitors
    ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
    ;
    numanalogs = 24L
    axy = [ [79, 5], [63,6], [58,6], $
  			[61,5], [56,1], [61,4], $
  			[57,4], [61,0], [57,5], $
  			[58,6], [61,6], [61,7], $
  			[58,2], [56,2], [56,0], $
  			[58,3], [57,6], [56,5], $
    		[56,3], [57,3], [57,2], $
			[67,4], [58,1], [56,4] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			exp_cur: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xps_tempa: 0.0, xps_tempb: 0.0, axs_tec_hot: 0.0 }
   endif else if (rnum eq 36.290) then begin
    ;  Note smaller structure like 36.286
    ;		There are many changes in TM1 format
    ;   define the TM items for all of the analog monitors
    ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
    ;
    numanalogs = 24L
    axy = [ [41,0], [34,0], [18,0], $
  			[67,7], [44,0], [67,6], $
  			[57,0], [67,2], [57,0], $
  			[34,0], [70,0], [70,1], $
  			[62,0], [45,0], [43,0], $
  			[80,0], [58,0], [50,0], $
    		[46,0], [55,0], [54,0], $
			[51,0], [59,0], [49,0] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			exp_cur: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xrs_5v: 0.0, xrs_temp1: 0.0, xrs_temp2: 0.0 }
 endif

  ;
  ;  open Analog file
  ;
  fanalog = fbase + 'analogs' + fend
  print, 'Saving all analogs in ', fanalog
  openw,alun,fanalog,/get_lun
  aa = assoc(alun,atemp)
endif
if keyword_set(esp) then begin
  fesp = fbase + 'esp' + fend
  print, 'Saving ESP spectra in ', fesp
  numesp = 9L
  esp1 = { time: 0.0D0, fpga_time: 0.0, rec_count: 0, rec_error: 0, cnt: uintarr(numesp) }
  esp1len = n_tags(esp1, /length)
  openw,elun,fesp,/get_lun
  ea = assoc(elun,esp1)
  eacnt = 0L
  efidvalue1 = '037E'X
  efidvalue2 = '0045'X
  ewcnt = 0L
  ewlen = numesp*8L
  ewords = uintarr(ewlen)
  if (rnum eq 36.233) then begin
    exy = [32,0,0,1]
  endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    exy = [11,1,0,2]
  endif else if (rnum eq 36.290) then begin
    exy = [11,1,0,2]
  endif
endif
if keyword_set(xps) and (rnum lt 36.290) then begin
  fxps = fbase + 'xps' + fend
  print, 'Saving XPS spectra in ', fxps
  numxps = 12L
  xps1 = { time: 0.0D0, fpga_time: 0.0, rec_error: 0, cnt: ulonarr(numxps) }
  xps1len = n_tags(xps1, /length)
  openw,xlun,fxps,/get_lun
  xa = assoc(xlun,xps1)
  xacnt = 0L
  xfidvalue1 = '037E'X
  xfidvalue2 = '0058'X
  xwcnt = 0L
  xwlen = numxps*8L
  xwords = uintarr(xwlen)
  if (rnum eq 36.233) then begin
    xxy = [31,0,0,1]
  endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    xxy = [11,0,0,2]
  endif
  ;  no XPS data for 36.290
endif
if keyword_set(pmegs) then begin
  fpmegs = fbase + 'pmegs' + fend
  print, 'Saving MEGS-P spectra in ', fpmegs
  numpcnt = 2L
  numpanalog = 64L
  pmegs1 = { time: 0.0D0, fpga_time: 0.0, rec_error: 0, cnt: uintarr(numpcnt), monitor: ulonarr(numpanalog) }
  pmegs1len = n_tags(pmegs1, /length)
  openw,plun,fpmegs,/get_lun
  pa = assoc(plun,pmegs1)
  pacnt = 0L
  pfidvalue1 = '037E'X
  pfidvalue2 = '004D'X
  pwcnt = 0L
  pwlen = (numpcnt+numpanalog)*8L
  pwords = uintarr(pwlen)
  if (rnum eq 36.233) then begin
    pxy = [33,0,0,1]
  endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    pxy = [16,0,0,2]
  endif else if (rnum eq 36.290) then begin
    pxy = [16,0,0,2]
  endif
endif
if keyword_set(axs) and (rnum lt 36.290) then begin
  faxs = fbase + 'axs' + fend
  print, 'Saving axs spectra in ', faxs
  numaxs = 2048L
  axs1 = { time: 0.0D0, rec_error: 0, cnt: uintarr(numaxs) }
  axs1len = n_tags(axs1,/length)
  openw,axslun,faxs,/get_lun
  axsa = assoc(axslun,axs1)
  axsacnt = 0L
  axsfidvalue1 = '0294'X  ; 660.
  axsfidvalue2 = '0000'X
  axswcnt = 0L
  axswlen = numaxs*8L
  axswords = uintarr(axswlen)
  if (rnum eq 36.233) then begin
    axsxy = [6,0,20,1]
  endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    axsxy = [7,0,0,1]
  endif
  ;  no AXS data for 36.290
endif
if keyword_set(xrs) then begin
  fgxrs = fbase + 'goes_xrs' + fend
  print, 'Saving GOES-R XRS serial data in ', fgxrs
  openw,gxlun,fgxrs,/get_lun
  gxrscnt = 0L
  if (rnum eq 36.233) or (rnum eq 36.240) then begin
    gxxy = [17,1,0,2]
    print, 'ERROR: can not have GOES-R XRS data for NASA ', strtrim(rnum,2)
  endif else if (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    gxxy = [17,1,0,2]
  endif else if (rnum eq 36.290) then begin
    gxxy = [17,1,0,2]
  endif
endif
if keyword_set(x123) and (rnum ge 36.290) then begin
  fx123 = fbase + 'x123' + fend
  print, 'Saving X123 serial data in ', fx123
  openw,x123lun,fx123,/get_lun
  x123cnt = 0L
  if (rnum eq 36.290) then begin
    x123xy = [47,0,0,1]
  endif
endif
if keyword_set(cmd) and (rnum ge 36.290) then begin
  fcmd = fbase + 'cmd_fpga' + fend
  print, 'Saving CMD Box / FPGA serial data in ', fcmd
  openw,cmdlun,fcmd,/get_lun
  cmdcnt = 0L
  if (rnum eq 36.290) then begin
    cmdxy = [63,0,0,2]
  endif
endif

kfullcnt = kend - kstart
print, 'Reading ', strtrim(kfullcnt,2), ' records...'

;
;	read all of the data
;
;	Save the TIME
;		TIME_millisec:  [(((byte 5) & 0xF0) << 9) (byte 3) << 8 + (byte 2) ] * 1000. +
;				[ ((byte 5) & 0x03) << 8 + (byte 4) ] +
;				[ ((byte 7) & 0x03) << 8 + (byte 6) ] / 1000.
;
for k=kstart,kend do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes

  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) and $
  			((data[sync3offset] and wordmask) eq sync3value) then begin
    atime[acnt] = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	atime[acnt] = atime[acnt] / 1000.   ; convert msec to sec
  	aindex[acnt] = k

  	if keyword_set(single) then begin
  	  dummy = extract_item( data, single, /analog )
	  sdata[0] = atime[acnt]
	  sdata[1:*] = dummy
	  sa[acnt] = sdata  ; write data to file
  	endif

  	if keyword_set(analog) then begin
  	  for jj=0,numanalogs-1 do begin
  	    dummy = extract_item( data, reform(axy[*,jj]), /analog )
  	    atemp.(jj+1) = dummy[0]
	  endfor
	  atemp.time = atime[acnt]
	  aa[acnt] = atemp  ; write data to file
  	endif

  	if keyword_set(esp) then begin
      if (ewcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, exy )
        jend = n_elements(temp)
        if keyword_set(debug) then begin
          print, temp, format='(4Z5)'
          edebugcnt = edebugcnt + 1
          if (edebugcnt gt 20) then begin
            edebugcnt = 0
            stop, 'Check out ESP data...'
          endif
        endif
        for jj=0,jend-1 do if (temp[jj] eq efidvalue1) then goto, egotfid
        goto, enotyet
egotfid:
		nw = jend-jj
        ewords[ewcnt:ewcnt+nw-1] = temp[jj:jend-1]
        ewcnt = ewcnt + nw
        esp1.time = atime[acnt]		; save time of the fiducial (in sec)
enotyet:
		; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, exy )
        jend = n_elements(temp)
        if keyword_set(debug) then begin
          print, temp, format='(4Z5)'
          edebugcnt = edebugcnt + 1
          if (edebugcnt gt 20) then begin
            edebugcnt = 0
            stop, 'Check out ESP data...'
          endif
        endif
        for jj=0,jend-1 do if (temp[jj] eq efidvalue1) then goto, egotfid2
        if (ewcnt lt (ewlen-2*jend)) then begin
          ; OK to throw out zero filled data
          ewords[ewcnt:ewcnt+jend-1] = temp
          ewcnt = ewcnt + jend
        endif
        goto, enotyet2
egotfid2:
		nw = jj
        if (jj gt 0) then begin
          ewords[ewcnt:ewcnt+jj-1] = temp[0:jj-1]
          ewcnt = ewcnt + nw
        endif
        ;  process the data stream into ESP record
        esp_raw2record, ewords, ewcnt, esp1, esp1len
        ;  save the record
        ; if (eacnt lt 10) then stop, 'Check out ESP record ...'
        ea[eacnt] = esp1
        eacnt = eacnt + 1L
        ;  start new record stream
        ewcnt = 0L
		nw = jend-jj
        ewords[ewcnt:ewcnt+nw-1] = temp[jj:jend-1]
        ewcnt = ewcnt + nw
        esp1.time = atime[acnt]		; save time of the fiducial (in sec)
enotyet2:
		; read some more data
      endelse
  	endif

  	if keyword_set(xps) and (rnum lt 36.290) then begin
      if (xwcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, xxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq xfidvalue1) then goto, xgotfid
        goto, xnotyet
xgotfid:
		nw = jend-jj
        xwords[xwcnt:xwcnt+nw-1] = temp[jj:jend-1]
        xwcnt = xwcnt + nw
        xps1.time = atime[acnt]		; save time of the fiducial (in sec)
xnotyet:
		; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, xxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq xfidvalue1) then goto, xgotfid2
        if (xwcnt lt (xwlen-2*jend)) then begin
          ; OK to throw out zero filled data
          xwords[xwcnt:xwcnt+jend-1] = temp
          xwcnt = xwcnt + jend
        endif
        goto, xnotyet2
xgotfid2:
		nw = jj
        if (jj gt 0) then begin
          xwords[xwcnt:xwcnt+jj-1] = temp[0:jj-1]
          xwcnt = xwcnt + nw
        endif
        ;  process the data stream into XPS record
        xps_raw2record, xwords, xwcnt, xps1, xps1len
        ;  save the record
        ; if (xacnt lt 5) then stop, 'Check out XPS record ...'
        xa[xacnt] = xps1
        xacnt = xacnt + 1L
        ;  start new record stream
        xwcnt = 0L
		nw = jend-jj
        xwords[xwcnt:xwcnt+nw-1] = temp[jj:jend-1]
        xwcnt = xwcnt + nw
        xps1.time = atime[acnt]		; save time of the fiducial (in sec)
xnotyet2:
		; read some more data
      endelse
  	endif

  	if keyword_set(pmegs) then begin
      if (pwcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, pxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq pfidvalue1) then goto, pgotfid
        goto, pnotyet
pgotfid:
		nw = jend-jj
        pwords[pwcnt:pwcnt+nw-1] = temp[jj:jend-1]
        pwcnt = pwcnt + nw
        pmegs1.time = atime[acnt]		; save time of the fiducial (in sec)
pnotyet:
		; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, pxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq pfidvalue1) then goto, pgotfid2
        if (pwcnt lt (pwlen-2*jend)) then begin
          ; OK to throw out zero filled data
          pwords[pwcnt:pwcnt+jend-1] = temp
          pwcnt = pwcnt + jend
        endif
        goto, pnotyet2
pgotfid2:
		nw = jj
        if (jj gt 0) then begin
          pwords[pwcnt:pwcnt+jj-1] = temp[0:jj-1]
          pwcnt = pwcnt + nw
        endif
        ;  process the data stream into MEGS-P record
        megsp_raw2record, pwords, pwcnt, pmegs1, pmegs1len
        ;  save the record
        ; if (pacnt lt 5) then stop, 'Check out MEGS-P record ...'
        pa[pacnt] = pmegs1
        pacnt = pacnt + 1L
        ;  start new record stream
        pwcnt = 0L
		nw = jend-jj
        pwords[pwcnt:pwcnt+nw-1] = temp[jj:jend-1]
        pwcnt = pwcnt + nw
        pmegs1.time = atime[acnt]		; save time of the fiducial (in sec)
pnotyet2:
		; read some more data
      endelse
  	endif

  	if keyword_set(axs) and (rnum lt 36.290) then begin
      if (axswcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, axsxy )
        jend = n_elements(temp)
        ;
        ;	DEBUG code for AXS
        ;
        ;sum = total(temp)
        ;if (sum ne 0) and (sum ne '7FE0'X) then begin
        ;  print, temp, form='(16Z6)'
        ;  stop, 'Check out "temp" for AXS data...'
        ;endif
        ;  end of DEBUG code
        for jj=0,jend-2 do if (temp[jj] eq axsfidvalue1) and (temp[jj+1] eq axsfidvalue2) then goto, axsgotfid
        goto, axsnotyet
axsgotfid:
		nw = jend-jj
         ;  look for non fiducial value to start saving the data
        wdata = where( temp[jj:jend-1] ne axsfidvalue1, ndata )
        if (ndata gt 0) then begin
          nw = jend - (jj+wdata[0])
          axswords[axswcnt:axswcnt+nw-1] = temp[jj+wdata[0]:jend-1]
          axswcnt = axswcnt + nw
          axs1.time = atime[acnt]		; save time of the fiducial (in sec)
        endif
axsnotyet:
		; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, axsxy )
        jend = n_elements(temp)
        for jj=0,jend-2 do if (temp[jj] eq axsfidvalue1) and (temp[jj+1] eq axsfidvalue2) then goto, axsgotfid2
        if (axswcnt lt (axswlen-2*jend)) then begin
          ; OK to throw out zero filled data
          axswords[axswcnt:axswcnt+jend-1] = temp
          axswcnt = axswcnt + jend
        endif
        goto, axsnotyet2
axsgotfid2:
		nw = jj
        if (jj gt 0) then begin
          axswords[axswcnt:axswcnt+jj-1] = temp[0:jj-1]
          axswcnt = axswcnt + nw
        endif
        ;  process the data stream into AXS spectrum
        axs1.rec_error = axswcnt - numaxs
        if (axswcnt gt numaxs) then axswcnt = numaxs
        axs1.cnt[0:axswcnt-1] = axswords[0:axswcnt-1]
        ;  save the record
        ; if (axsacnt lt 3) then stop, 'Check out AXS record ...'
        axsa[axsacnt] = axs1
        axsacnt = axsacnt + 1L
        ;  start new record stream
        axswcnt = 0L
        ;  ASSUMES rest of the "temp" is also the fiducial
		;nw = jend-jj
        ;axswords[axswcnt:axswcnt+nw-1] = temp[jj:jend-1]
        ;axswcnt = axswcnt + nw
        ;axs1.time = atime[acnt]		; save time of the fiducial (in sec)
axsnotyet2:
		; read some more data
      endelse
  	endif

  	if keyword_set(xrs) then begin
  	  dummy = extract_item( data, gxxy )
  	  ndummy = n_elements(dummy)
  	  for jj=0,ndummy-1 do begin
  	    if (dummy[jj] ne 0) then begin
  	      ; write 7-bit BYTE to file (bit-shift 2 bits down)
  	      ;  TEST:  printf,gxlun,dummy[jj],format='(Z4)'
  	      writeu,gxlun,byte(ishft(dummy[jj],-2) and '7F'X)
	      gxrscnt = gxrscnt + 1
	    endif
	  endfor
  	endif

  	if keyword_set(x123) and (rnum ge 36.290) then begin
   	  dummy = extract_item( data, x123xy )
  	  ndummy = n_elements(dummy)
  	  for jj=0,ndummy-1 do begin
  	    if (dummy[jj] ne 0) then begin
  	      ; write 8-bit BYTE to file (bit-shift 2 bits down)
  	      writeu,x123lun,byte(ishft(dummy[jj],-2) and 'FF'X)
	      x123cnt = x123cnt + 1
	    endif
	  endfor
  	endif

  	if keyword_set(cmd) and (rnum ge 36.290) then begin
  	  dummy = extract_item( data, cmdxy )
  	  ndummy = n_elements(dummy)
  	  for jj=0,ndummy-1 do begin
  	    if (dummy[jj] ne 0) then begin
  	      ; write 8-bit BYTE to file (bit-shift 2 bits down)
  	      writeu,cmdlun,byte(ishft(dummy[jj],-2) and 'FF'X)
	      cmdcnt = cmdcnt + 1
	    endif
	  endfor
  	endif

  	acnt = acnt + 1L
  endif

  if (k mod pcnt10) eq 0 then print, '  @ ', strtrim(long(k/pcnt10)*10,2), ' %...'
endfor

print, ' '
print, 'READ_TM1_CD: processed ',strtrim(acnt,2), ' records'
print, '             expected to process ', strtrim(ktotal,2)
if (acnt ne pcnt) then begin
  atime=atime[0:acnt-1]
  aindex=aindex[0:acnt-1]
endif

;
;	close original file now
;   and all of the open output files
;
close, lun
free_lun, lun

ans = 'Y'
if keyword_set(single) then begin
  close, slun
  free_lun, slun
  read, 'Plot Single Analog time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_single, fsingle
endif
if keyword_set(analog) then begin
  close, alun
  free_lun, alun
  read, 'Plot All Analogs time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_analogs, fanalog
endif
if keyword_set(esp) then begin
  close, elun
  free_lun, elun
  print, ' '
  print, strtrim(eacnt,2), ' ESP records saved.'
  read, 'Plot ESP channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_esp, fesp
endif
if keyword_set(xps) and (rnum lt 36.290) then begin
  close, xlun
  free_lun, xlun
  print, ' '
  print, strtrim(xacnt,2), ' XPS records saved.'
  read, 'Plot XPS channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_xps, fxps
endif
if keyword_set(pmegs) then begin
  close, plun
  free_lun, plun
  print, ' '
  print, strtrim(pacnt,2), ' MEGS-P records saved.'
  read, 'Plot MEGS-P channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_megsp, fpmegs
endif
if keyword_set(axs) and (rnum lt 36.290) then begin
  close, axslun
  free_lun, axslun
  print, ' '
  print, strtrim(axsacnt,2), ' AXS records saved.'
  read, 'Show AXS movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_axs, faxs
endif
if keyword_set(xrs) then begin
  close, gxlun
  free_lun, gxlun
  print, ' '
  print, strtrim(gxrscnt,2), ' GOES-R XRS serial stream characters saved.'
  ; read, 'Plot XRS channels time series (Y/N) ? ', ans
  ; ans = strupcase(strmid(ans,0,1))
  ; if (ans eq 'Y') then plot_goes_xrs, fgxrs
endif
if keyword_set(x123) and (rnum ge 36.290) then begin
  close, x123lun
  free_lun, x123lun
  print, ' '
  print, strtrim(x123cnt,2), ' X123 serial stream characters saved.'
endif
if keyword_set(cmd) and (rnum ge 36.290) then begin
  close, cmdlun
  free_lun, cmdlun
  print, ' '
  print, strtrim(cmdcnt,2), ' CMD Box / FPGA serial stream characters saved.'
endif

if keyword_set(debug) then stop, 'STOP:  Check out results, atime, aindex, acnt ...'

return
end
