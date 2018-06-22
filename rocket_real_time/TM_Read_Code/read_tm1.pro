;
;   read_tm1.pro
;
;   Read NSROC Woods 36.XXX TM1 CD data files
;     Serial Data
;     Analog Monitors
;
;   Extract out data from TM1
;
;
;   INPUT
;     filename    filename of 36233*.bin or not given or '' to ask user to select file
;
;     launchtime=launchtime   time (SOD) for T-0   (or first time in file if not given)
;     time=time               time for extraction (seconds relative to T-0) < fltarr[2] >
;
;     single=single           single analog monitor with [X, Y, DX, DY] specified as array
;     analog=analog           all of the experiment analog monitors
;
;     /esp           serial data for ESP
;     /pmegs         serial data for MEGS-P
;       /xps           serial data for XPS (removed before 36.290)
;       /axs           serial data for AXS (removed before 36.290)
;	  /xrs			serial data for GOES-R XRS (note that format changed for 36.290 for ISIS)
;	  /x123			serial data for X123 as part of XRS package (36.290 & 36.300 only)
;	  /cmd			serial data for CMD box added for 36.290
;
;   OUTPUT
;
;     data        data extracted as time series if analog monitor or spectra if serial data
;
;   SAME output format as read_tm1_cd.pro so that other supporting (plot) procedures will also work
;   DIFFERENCE between CD and RealTime is the time format and X_rt = X_cd - 1
;
;   10/22/06
;   Tom Woods
;
;	Updated for 36.240  (Apr 2008) - changed TM1 from 1 Mbps to 5 Mbps and rearranged TM items
;	3/17/08  Tom Woods
;
;	Updated Apr 08 for 36.240 - included ROCKET option to specify the rocket number
;	Updated Mar 3, 2015 for 36.300 so XRS is binary data  -  INCOMPLETE EDIT - DOES NOT WORK (yet)
;
;	Updated May 2016 for 36.318 and also so RT and CD version works under
;		one procedure with CD option flag (default is RT)
;
;	Updated June 2018 for 36.336 for CSOL analog monitors and new SPS-CSOL serial data
;		Also fixed so file doesn't have to start on Row 0
;
pro  read_tm1, filename, cd=cd, launchtime=launchtime, time=time, single=single, $
				analog=analog, esp=esp, pmegs=pmegs, xps=xps, axs=axs, xrs=xrs, x123=x123, $
				cmd=cmd, sps_csol=sps_csol, debug=debug, rocket=rocket

;  new code to check for CD or RT file type
if keyword_set(cd) then begin
	fileRT = 0
	fileType = 'CD Raw Log File'
	fileFilter = 'LOGFILE*.*'
	ncol = 83L	; CD has 6 extra header bytes (3 words) for Time
	nrow = 8L
endif else begin
	fileRT = 1
	fileType = 'DataView Raw Dump File'
	fileFilter = 'Raw*TM1_*.*'
	ncol = 80L
	nrow = 8L
endelse

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick TM#1 '+fileType, filter=fileFilter)
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

;
;   Record is 80 words (160 bytes) x 8 rows
;
;   NOTE:  words have bytes flipped for MAC but code written for any computer
;

dirslash = path_sep()  ; is it Mac ('/') or Windows ('\')
fb1 = rstrpos( filename, dirslash )
if (fb1 lt 0) then fb1 = -1L
fb2 = rstrpos( filename, '.' )
if (fb2 lt 0) then fb2 = strlen(filename)
fbase = strmid( filename, fb1+1, fb2-fb1-1 ) + '_'
;  just use the full input file name
fbase = filename + '_'

if keyword_set(rocket) then rnum = rocket else rnum = 36.336	; Default of 36.336
if (rnum ne 36.336) and (rnum ne 36.318) and (rnum ne 36.300) and (rnum ne 36.290) and $
		(rnum ne 36.286) and (rnum ne 36.240) and (rnum ne 36.233) then begin
  print, 'ERROR: rocket number is not valid, resetting to 36.336'
  rnum = 36.336
endif
print, 'Processing for rocket # ', string(rnum,format='(F7.3)')

if not keyword_set(launchtime) then launchtime=0L
fpos = strpos( filename, 'flight' )
if (not keyword_set(launchtime)) and (fpos ge 0) then begin
  if (rnum eq 36.217) then launchtime = 12*3600L + 23*60L + 30  ; MDT instead of UT
  if (rnum eq 36.240) then launchtime = 10*3600L + 58*60L + 0
  if (rnum eq 36.258) then launchtime = 12*3600L + 32*60L + 2.00D0
  if (rnum eq 36.275) then launchtime = 11*3600L + 50*60L + 0.354D0
  if (rnum eq 36.286) then launchtime = 13*3600L + 30*60L + 1.000D0
  if (rnum eq 36.290) then launchtime = 12*3600L + 0*60L + 0.4D0
  if (rnum eq 36.300) then launchtime = 13*3600L + 14*60L + 25.1D0
  if (rnum eq 36.318) then launchtime = 19*3600L + 0*60L + 0.0D0
  if (rnum eq 36.336) then launchtime = 19*3600L + 0*60L + 0.0D0
  print, 'NOTE:  set launch time for ', strtrim(launchtime,2), ' sec of day'
endif else begin
  ; stop, 'DEBUG: Did not set Launch Time (tzero)...'
endelse


;  36.336 TM1 packet size is same as before but some monitor placements changed
;  36.233 and 36.240 TM1 packet size and sync are the same but monitor placements are different
;  36.233 had 1 Mbps TM and  36.240 has 5 Mbps TM
;  36.286 format also changed monitor placement in 2012
;  36.300 format changed monitor placement in 2015

; ncol and nrow are defined above based on CD or RT
nbytes = ncol*2L * nrow     ; [CD_time] sync_1 + sync_2 + sync_3 + sfid + 76 words of data
nint = nbytes/2L
ntotal = ncol * nrow

ntime = 2L                 ; DataView time is 4-bytes of milliseconds of time
packetrate = ntotal * 10L / 1.D6    ; number_words * 10_bits / bit_rate ==> sec per packet

RToffset = -1L		; X offset between CD data and RT data for the "X" value

;
;	define constants / arrays for finding sync values
;
;	For 36.233 (1 Mbps) - 2006
;	Same for 36.240 (5 Mbps) - 2008
;
if (rnum eq 36.233) or (rnum eq 36.240) or (rnum eq 36.286) or (rnum eq 36.290) or (rnum eq 36.300) or (rnum eq 36.318) or (rnum eq 36.336) then begin
 if keyword_set(CD) then begin
  wordmask = '03FF'X
  sync1value = '0100'X
  sync1offset = 0L

  sync2value = '03EB'X
  sync2offset = nint-2L

  sync3value = '0333'X
  sync3offset = nint-1L
 endif else begin
  wordmask = '03FF'X
  sync1value = '03EB'X
  sync1offset = 0L

  sync2value = '0333'X
  sync2offset = 1L

  sync3value = '0100'X
  sync3offset = 2L
 endelse
endif else begin
  print, 'ERROR: Invalid Rocket Number for SYNC word definition, exiting...'
  return
endelse

;  open the TM CD Data file
openr,lun, filename, /get_lun

if keyword_set(CD) then begin
	; Record for CD file
	a = assoc( lun, uintarr(ncol,nrow) )
endif else begin
 ;
 ;   DataView can have 4-byte (long) time word at end of each packet
 ;   so have to determine which type format by examining for Sync words
 ;
 atest = assoc( lun, uintarr(ntotal+ntime*2L+(sync1offset+1L)*2L) )
 dtest = atest[0]
 swap_endian_inplace, dtest, /swap_if_big_endian     ; only MACs will flip bytes
 if ((dtest[sync1offset] and wordmask) eq sync1value) and $
    ((dtest[sync1offset+ntotal] and wordmask) eq sync1value) then begin
  print, 'WARNING: assuming constant TIME rate for these packets'
  hasTime = 0L
  a = assoc( lun, uintarr(ncol,nrow) )
 endif else if ((dtest[sync1offset] and wordmask) eq sync1value) and $
    ((dtest[sync1offset+ntotal+ntime] and wordmask) eq sync1value) then begin
  hasTime = 1L
  a = assoc( lun, uintarr(ntotal+ntime) )
  nbytes = nbytes + ntime*2L  ; make file record longer
 endif else begin
  print, 'ERROR: could not find SYNC with or without TIME in these packets'
  close,lun
  free_lun,lun
  return
 endelse
endelse

finfo = fstat(lun)
fsize = finfo.size
pcnt = fsize/nbytes
print, ' '
print, 'READ_TM1:  ',strtrim(pcnt,2), ' records in ', filename
if not keyword_set(CD) then $
	print, ' WARNING:  DataView dumps are incomplete - use READ_TM1, /CD for complete data set.'

acnt = 0L
aindex=ulong(lonarr(pcnt))
atime = dblarr(pcnt)

pcnt10 = pcnt/10L

;
;   find first valid time
;
for k=0L,pcnt-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) and $
         ((data[sync3offset] and wordmask) eq sync3value) then begin
    if keyword_set(CD) then begin
      time1 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	  time1 = time1 / 1000.D0   ; convert msec to sec
    endif else begin
     if (hasTime ne 0) then begin
       time1 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
       time1 = time1 / 1000.D0   ; convert millisec to sec
     endif else begin
       time1 = k * packetrate
     endelse
    endelse
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
data1 = data

;
;   find last valid time
;
for k=pcnt-1L,0L,-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) and $
         ((data[sync3offset] and wordmask) eq sync3value) then begin
    if keyword_set(CD) then begin
      time2 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	  time2 = time2 / 1000.D0   ; convert msec to sec
    endif else begin
     if (hasTime ne 0) then begin
       time2 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
       time2 = time2 / 1000.D0   ; convert millisec to sec
     endif else begin
       time2 = k * packetrate
     endelse
    endelse
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
data2 = data

if keyword_set(time) then begin
  dtime = (time2-time1)/pcnt
  kstart = long( (time[0] - (time1 - launchtime)) / dtime )
  if (kstart lt 0) then kstart = 0L
  if (kstart ge pcnt) then kstart = pcnt-1
  if n_elements(time) lt 2 then kend = pcnt-1L else begin
    kend = long( (time[1] - (time1 - launchtime)) / dtime )
    if (kend lt 0) then kend = 0L
    if (kend ge pcnt) then kend = pcnt-1
  endelse
  if (kstart gt kend) then begin
    ktemp = kend
    kend = kstart
    kstart = ktemp
  endif
  timestr = strtrim(long(time[0]),2) + '_' + strtrim(long(time[1]),2) + '_'
endif else begin
  kstart = 0L
  kend = pcnt-1L
  timestr = ''
endelse
ktotal = kend - kstart + 1L

if keyword_set(debug) then stop, 'DEBUG first packet = data1 and last packet = data2 ...'

;
;   set up files / variables
;
fbase = fbase + timestr
fend = '.dat'

if keyword_set(single) then begin
  if n_elements(single) lt 2 then single = 0 else begin
    ;
    ;  single array = [ X, Y, dX, dY, maxX, maxY ]   only X, Y must be given
    ;
    ;   For TM1 definitions for RT:  X = WD+1, Y = FR-1
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
if arg_present(analog) or keyword_set(analog) then begin
  ;
  ;   define the TM items for all of the analog monitors
  ;     X = WD + 3, Y = FR - 1
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
  endif else if (rnum eq 36.300) then begin
    ;
    ;   define the TM items for all of the analog monitors
    ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
    ;
    numanalogs = 28L
    axy = [ [41,0], [34,0], [18,0], $
  			[67,7], [56,1], [67,6], $
  			[56,0], [67,2], [57,0], $
  			[61,0], [70,0], [70,1], $
  			[62,0], [45,0], [43,0], $
  			[80,0], [58,0], [50,0], $
    		[46,0], [55,0], [54,0], $
			[59,0], [49,0], [51,0], $
			[75,3], [75,4], [75,5], $
			[35,0] ]
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			xps_tempb: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xrs_28v: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xrs_tempa: 0.0, xrs_tempb: 0.0, xrs_5v: 0.0, $
  			shutter_door_pos: 0.0, shutter_door_mon: 0.0, shutter_door_volt: 0.0, $
  			shutter_door_cur: 0.0 }
  endif else if (rnum eq 36.318) then begin
  ;
  ;   define the TM items for all of the analog monitors
  ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
  ;
  numanalogs = 28L
  axy = [ [41,0], [34,0], [18,0], $
    [68,2], [56,1], [68,1], $
    [56,0], [67,5], [57,0], $
    [61,0], [68,3], [68,4], $
    [62,0], [45,0], [43,0], $
    [67,2], [58,0], [50,0], $
    [46,0], [55,0], [54,0], $
    [59,0], [49,0], [51,0], $
    [74,4], [74,5], [74,7], $
    [35,0] ]
  atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
    tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
    solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
    xps_tempb: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
    megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
    megsb_ccd_temp: 0.0, megsb_heater: 0.0, xrs_28v: 0.0, $
    xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
    xrs_tempa: 0.0, xrs_tempb: 0.0, xrs_5v: 0.0, $
    shutter_door_pos: 0.0, shutter_door_mon: 0.0, shutter_door_volt: 0.0, $
    shutter_door_cur: 0.0 }
  endif else if (rnum eq 36.336) then begin
  ;
  ;   define the TM items for all of the analog monitors
  ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
  ;
  numanalogs = 33L
  axy = [ [41,0], [34,0], [18,0], $
  	[67,6], [56,0], [68,0], $
    [68,2], [56,1], [68,1], $
    [67,5], [57,0], [67,4], $
    [61,0], [68,3], [68,4], $
    [62,0], [45,0], [43,0], $
    [67,2], [58,0], [50,0], $
    [46,0], [55,0], [54,0], $
    [59,0], [49,0], [51,0], $
    [74,4], [74,5], [74,7], $
    [71,7], [66,0], [67,3] ]
  atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  	hvs_press: 0.0, solar_press: 0.0, exp_15v: 0.0, $
    tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
    gate_valve: 0.0, cryo_cold_temp: 0.0, cryo_hot_temp: 0.0, $
    xps_tempb: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
    megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
    megsb_ccd_temp: 0.0, megsb_heater: 0.0, xrs_28v: 0.0, $
    xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
    xrs_tempa: 0.0, xrs_tempb: 0.0, xrs_5v: 0.0, $
    shutter_door_pos: 0.0, shutter_door_mon: 0.0, shutter_door_volt: 0.0, $
    shutter_door_cur: 0.0, csol_5v: 0.0, csol_tec_temp: 0.0 }
endif

if not keyword_set(CD) then begin
  ; convert from CD to RT "X"
  for jj=0L,numanalogs-1 do axy[0,jj] = axy[0,jj] + RToffset
endif

  ;
  ;  open Analog file
  ;
  fanalog = fbase + 'analogs' + fend
  print, 'Saving all analogs in ', fanalog
  openw,alun,fanalog,/get_lun
  aa = assoc(alun,atemp)
endif

;
;	Serial Data
;		X = WD + 3 (CD, -1 for RT),  Y = FR - 1
;
if arg_present(esp) or keyword_set(esp) then begin
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
   endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) or (rnum eq 36.300) or (rnum eq 36.318) or (rnum eq 36.336) then begin
    exy = [11,1,0,2]
  endif
  if not keyword_set(CD) then begin
	  exy[0] = exy[0] + RToffset	; convert from CD to RT "X"
  endif
  edebugcnt = 0
endif

if (arg_present(xps) or keyword_set(xps)) and (rnum lt 36.290) then begin
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
  if not keyword_set(CD) then begin
	xxy[0] = xxy[0] + RToffset	; convert from CD to RT "X"
  endif
endif

if arg_present(pmegs) or keyword_set(pmegs) then begin
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
  endif else if (rnum eq 36.240) or (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) or (rnum eq 36.300) or (rnum eq 36.318) or (rnum eq 36.336) then begin
    pxy = [16,0,0,2]
  endif
  if not keyword_set(CD) then begin
	pxy[0] = pxy[0] + RToffset  ; convert from CD to RT "X"
  endif
endif

if (arg_present(axs) or keyword_set(axs)) and (rnum lt 36.290) then begin
	;  S1 = Serial 1 (no longer used)
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
  endif else if (rnum eq 36.240) then begin
    axsxy = [7,0,0,1]
  endif else if (rnum eq 36.286) then begin
    axsxy = [7,0,0,1]
  endif
  if not keyword_set(CD) then begin
	axsxy[0] = axsxy[0] + RToffset  ;  convert from CD to RT "X"
  endif
endif

if arg_present(xrs) or keyword_set(xrs) then begin
  fgxrs = fbase + 'goes_xrs' + fend
  print, 'Saving GOES-R XRS serial data in ', fgxrs
  openw,gxlun,fgxrs,/get_lun
  gxrscnt = 0L
  if (rnum eq 36.233) or (rnum eq 36.240) then begin
    gxxy = [17,1,0,2]
    print, 'ERROR: can not have GOES-R XRS data for NASA ', strtrim(rnum,2)
  endif else if (rnum eq 36.258) or (rnum eq 36.275) or (rnum eq 36.286) then begin
    gxxy = [17,1,0,2]
  endif else if (rnum eq 36.300) or (rnum eq 36.318) or (rnum eq 36.336)  then begin
    gxxy = [47,0,0,1]
  endif
  if not keyword_set(CD) then begin
	gxxy[0] = gxxy[0] + RToffset	; convert from CD to RT "X"
  endif
  glastchar = -1
endif
if (arg_present(x123) or keyword_set(x123)) and ((rnum eq 36.290) or (rnum lt 36.300)) then begin
  fx123 = fbase + 'x123' + fend
  print, 'Saving X123 serial data in ', fx123
  openw,x123lun,fx123,/get_lun
  x123cnt = 0L
  x123xy = [47,0,0,1]
  if not keyword_set(CD) then begin
	x123xy[0] = x123xy[0] + RToffset	; convert from CD to RT "X"
  endif
endif

if (arg_present(cmd) or keyword_set(cmd)) and (rnum ge 36.290) then begin
  fcmd = fbase + 'cmd_fpga' + fend
  print, 'Saving CMD Box / FPGA serial data in ', fcmd
  openw,cmdlun,fcmd,/get_lun
  cmdcnt = 0L
  if (rnum eq 36.290) or (rnum eq 36.300) or (rnum eq 36.318) or (rnum eq 36.336)  then begin
    cmdxy = [63,0,0,2]
  endif
  if not keyword_set(CD) then begin
	cmdxy[0] = cmdxy[0] + RToffset	; convert from CD to RT "X"
  endif
endif

if (arg_present(sps_csol) or keyword_set(sps_csol)) and (rnum eq 36.336) then begin
  fsps = fbase + 'sps_csol' + fend
  print, 'Saving SPS-CSOL serial data in ', fsps
  openw,spslun,fsps,/get_lun
  spscnt = 0L
  if (rnum eq 36.336) then begin
    spsxy = [17,1,0,2]
  endif
  if (not keyword_set(CD)) then begin
	spsxy[0] = spsxy[0] + RToffset	; convert from CD to RT "X"
  endif
  spslastchar = -1
endif

kfullcnt = kend - kstart
print, 'Reading ', strtrim(kfullcnt,2), ' records...'

; **************************************   READ DATA  ************************************
;   read all of the data
;
;   Save the TIME
;     TIME_millisec:  data[ntotal] + ISHFT(ulong(data[ntotal+1]),16)
;
;	2018:  Updated so Row 0 doesn't have to be first row in file
;
sfidxy = [4,0,0,1]
sfid_mask = '000F'X
if not keyword_set(CD) then sfidxy[0] = sfidxy[0] + RToffset	; convert from CD to RT "X"
data_last = a[kstart > 0? kstart-1 : kstart]
sfid_last = extract_item(data_last, sfidxy)

for k=kstart,kend do begin
  datanew = a[k]
  ;  2018: new make sure SFID is in right order
  sfid = extract_item(datanew, sfidxy)
  data = datanew
  if (sfid[0] and sfid_mask) ne 0 then begin
  	; file alignment is NOT OK for Row 0
  	; use data from data_last to start new data packet
  	for ii=0,nrow-1 do begin
  		if (sfid_last[ii] and sfid_mask) eq 0 then begin
  			; found Row 0
  			ii_last = nrow-ii-1
  			data[*,0:ii_last] = data_last[*,ii:nrow-1]
  			if (ii gt 0) then data[*,ii_last+1:nrow-1] = datanew[*,0:ii-1]
  			break
  		endif
  	endfor
  	if keyword_set(debug) then stop, 'DEBUG two data packet merging ...'
  endif
  ;  remember data for next packet read merging option
  data_last = datanew
  sfid_last = sfid

  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes

  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) and $
         ((data[sync3offset] and wordmask) eq sync3value) then begin
    if keyword_set(CD) then begin
      atime[acnt] = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	  atime[acnt] = atime[acnt] / 1000.   ; convert msec to sec
    endif else begin
     if (hasTime ne 0) then begin
      atime[acnt] = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
      atime[acnt] = atime[acnt] / 1000.D0   ; convert millisec to sec
        ; print, data[0:5],data[ntotal:ntotal+1],format='(8Z5)'
        ; print, 'time = ', atime[acnt]
        ; stop, 'Debug data and atime[acnt] ...'
      ;  restructure data into ncol x nrow (without time)
      data = reform( data[0:ntotal-1], ncol, nrow )
     endif else begin
      atime[acnt] = k * packetrate
     endelse
    endelse

    aindex[acnt] = k

    if keyword_set(single) then begin
      dummy = extract_item( data, single, /analog )
      sdata[0] = atime[acnt]
      sdata[1:*] = dummy
      sa[acnt] = sdata  ; write data to file
    endif

    if arg_present(analog) or keyword_set(analog) then begin
      for jj=0,numanalogs-1 do begin
        dummy = extract_item( data, reform(axy[*,jj]), /analog )
        atemp.(jj+1) = dummy[0]
      endfor
      atemp.time = atime[acnt]
      aa[acnt] = atemp  ; write data to file
      if (acnt ge 0) and (acnt lt 2) and keyword_set(debug) then begin
        print, 'Analog Record'
        help, atemp, /struct
        print, ' '
        stop, 'Debug ANALOG atemp, atime[acnt], acnt ...'
      endif
    endif

    if arg_present(esp) or keyword_set(esp) then begin
      if (ewcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, exy )
        jend = n_elements(temp)
        if keyword_set(debug) and (ewcnt lt 0) then begin
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
        esp1.time = atime[acnt]     ; save time of the fiducial (in sec)
enotyet:
       ; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, exy )
        jend = n_elements(temp)
        if keyword_set(debug) and (ewcnt lt 0) then begin
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
        esp1.time = atime[acnt]     ; save time of the fiducial (in sec)
enotyet2:
       ; read some more data
      endelse
    endif

    if (arg_present(xps) or keyword_set(xps)) and (rnum lt 36.290) then begin
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
        xps1.time = atime[acnt]     ; save time of the fiducial (in sec)
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
        xps1.time = atime[acnt]     ; save time of the fiducial (in sec)
xnotyet2:
       ; read some more data
      endelse
    endif

    if arg_present(pmegs) or keyword_set(pmegs) then begin
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
        pmegs1.time = atime[acnt]     ; save time of the fiducial (in sec)
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
        pmegs1.time = atime[acnt]     ; save time of the fiducial (in sec)
pnotyet2:
       ; read some more data
      endelse
    endif

    if (arg_present(axs) or keyword_set(axs)) and (rnum lt 36.290)  then begin
      if (axswcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, axsxy )
        jend = n_elements(temp)
        ;
        ;   DEBUG code for AXS
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
          axs1.time = atime[acnt]     ; save time of the fiducial (in sec)
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
        ; if (axsacnt lt 5) then stop, 'Check out AXS record ...'
        axsa[axsacnt] = axs1
        axsacnt = axsacnt + 1L
        ;  start new record stream
        axswcnt = 0L
        ;  ASSUMES rest of the "temp" is also the fiducial
       ;nw = jend-jj
        ;axswords[axswcnt:axswcnt+nw-1] = temp[jj:jend-1]
        ;axswcnt = axswcnt + nw
        ;axs1.time = atime[acnt]       ; save time of the fiducial (in sec)
axsnotyet2:
       ; read some more data
      endelse
    endif

  	if (arg_present(xrs) or keyword_set(xrs)) and (rnum lt 36.290) then begin
  	  dummy = extract_item( data, gxxy )
  	  ndummy = n_elements(dummy)
  	  if (glastchar eq -1) and keyword_set(debug) then begin
  	    print, 'Data Record'
  	    for kk=0,7 do begin
  	       print, data[*,kk], format='(20Z4)'
  	       print, ' '
  	    endfor
  	  	glastchar = 0
  	  endif
   	  ; stop, 'Check out dummy and data ...'
 	  for jj=0,ndummy-1 do begin
  	    if (dummy[jj] ne '3FF'X) and (dummy[jj] ne 0) then begin
  	      ; print, 'S=', dummy[jj], string(byte(ishft(dummy[jj],-2) and '7F'X)), format='(A3,Z4,A3)'
  	      glastchar = dummy[jj]
  	 	  ; stop, 'check out XRS serial data in "dummy" ...'
  	      ; write 7-bit BYTE to file (bit-shift 2 bits down
  	      ;  TEST:  printf,gxlun,dummy[jj],format='(Z4)'
  	      writeu,gxlun,byte(ishft(dummy[jj],-2) and 'FF'X)  ; changed mask from '7F'X
	      gxrscnt = gxrscnt + 1
	    endif
	  endfor
  	endif

  	if (arg_present(xrs) or keyword_set(xrs)) and (rnum ge 36.290) then begin
  	  dummy = extract_item( data, gxxy )
  	  ndummy = n_elements(dummy)
  	  ; change in 2015 so XRS-X123 data are binary packets (CCSDS, MinXSS)
  	  ; so no bit shifting or masking for now...
  	  ; if total(dummy) ne 0 and (gxrscnt lt 10000L) then print, 'XRS:',dummy,format='(A8,8Z5)'
  	  dummy2 = dummy
  	  cnt2=0L
  	  for jj=0,ndummy-1 do begin
  	   if (dummy[jj] ne 0) then begin
  	      ; write 7-bit BYTE to file (bit-shift 2 bits down)
  	      ;  TEST:  printf,gxlun,dummy[jj],format='(Z4)'
  	      aByte = byte(ishft(dummy[jj],-2) and 'FF'X)  ; was '7F'X mask before 2015
  	      dummy2[cnt2] = aByte
  	      cnt2 += 1L
  	      writeu,gxlun, aByte
	      gxrscnt = gxrscnt + 1
	    endif
	  endfor
	  ; if cnt2 gt 0 and (gxrscnt lt 10000L) then print, 'XRS:',dummy2[0:cnt2-1],format='(A8,8Z5)'
  	endif

  	if (arg_present(x123) or keyword_set(x123)) and ((rnum eq 36.290) or (rnum eq 36.300)) then begin
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

  	if (arg_present(cmd) or keyword_set(cmd)) and (rnum ge 36.290) then begin
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

	if (arg_present(sps_csol) or keyword_set(sps_csol)) and (rnum eq 36.336) then begin
	  dummy = extract_item( data, spsxy )
  	  ndummy = n_elements(dummy)
  	  ; if (ndummy gt 0) then stop, 'DEBUG SPS-CSOL ...'
  	  for jj=0,ndummy-1 do begin
  	    if (dummy[jj] ne 0) then begin
  	      ; write 8-bit BYTE to file (bit-shift 2 bits down)
  	      writeu,spslun,byte(ishft(dummy[jj],-2) and 'FF'X)
	      spscnt = spscnt + 1
	    endif
	  endfor
	endif

    acnt = acnt + 1L
  endif

  if (k mod pcnt10) eq 0 then print, '  @ ', strtrim(long(k/pcnt10)*10,2), ' %...'
endfor

print, ' '
print, 'READ_TM1: processed ',strtrim(acnt,2), ' records'
print, '             expected to process ', strtrim(kfullcnt,2)
if (acnt ne pcnt) then begin
  atime=atime[0:acnt-1]
  aindex=aindex[0:acnt-1]
endif

;
;   close original file now
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
if arg_present(analog) or keyword_set(analog) then begin
  close, alun
  free_lun, alun
  read, 'Plot All Analogs time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_analogs, fanalog, tzero=launchtime
endif
if arg_present(esp) or keyword_set(esp) then begin
  close, elun
  free_lun, elun
  print, ' '
  print, strtrim(eacnt,2), ' ESP records saved.'
  read, 'Plot ESP channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_esp, fesp
endif
if (arg_present(xps) or keyword_set(xps)) and (rnum lt 36.290) then begin
  close, xlun
  free_lun, xlun
  print, ' '
  print, strtrim(xacnt,2), ' XPS records saved.'
  read, 'Plot XPS channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_xps, fxps
endif
if arg_present(pmegs) or keyword_set(pmegs) then begin
  close, plun
  free_lun, plun
  print, ' '
  print, strtrim(pacnt,2), ' MEGS-P records saved.'
  read, 'Plot MEGS-P channels time series (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then plot_megsp, fpmegs, /all
endif
if (arg_present(axs) or keyword_set(axs)) and (rnum lt 36.290) then begin
  close, axslun
  free_lun, axslun
  print, ' '
  print, strtrim(axsacnt,2), ' AXS records saved.'
  read, 'Show AXS movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_axs, faxs
endif
if arg_present(xrs) or keyword_set(xrs) then begin
  close, gxlun
  free_lun, gxlun
  print, ' '
  print, strtrim(gxrscnt,2), ' GOES-R XRS serial stream characters saved.'
  ; read, 'Plot XRS channels time series (Y/N) ? ', ans
  ; ans = strupcase(strmid(ans,0,1))
  ; if (ans eq 'Y') then plot_goes_xrs, fgxrs
endif
if (arg_present(x123) or keyword_set(x123)) and ((rnum eq 36.290) or (rnum eq 36.300)) then begin
  close, x123lun
  free_lun, x123lun
  print, ' '
  print, strtrim(x123cnt,2), ' X123 serial stream characters saved.'
endif
if (arg_present(cmd) or keyword_set(cmd)) and (rnum ge 36.290) then begin
  close, cmdlun
  free_lun, cmdlun
  print, ' '
  print, strtrim(cmdcnt,2), ' CMD Box / FPGA serial stream characters saved.'
endif
if (arg_present(sps_csol) or keyword_set(sps_csol)) and (rnum eq 36.336) then begin
  close, spslun
  free_lun, spslun
  print, ' '
  print, strtrim(spscnt,2), ' SPS-CSOL serial stream characters saved.'
endif

if keyword_set(debug) then stop, 'STOP:  Check out results, atime, aindex, acnt ...'

return
end
