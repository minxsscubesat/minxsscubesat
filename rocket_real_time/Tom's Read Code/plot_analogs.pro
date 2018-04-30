;
;	plot_analogs.pro
;
;	Plot all analogs data time series from read_tm1_cd.pro
;
;	INPUT
;		filename	file name (*analogs.dat or '' to ask user to select file)
;		xrange=xrange    time range for plot
;		plotnum=plotnum  number of plot to do (single plot versus all 11 plots)
;		tzero       time (sec of day) for zero time (launch Time)
;		debug		stop at end of procedure
;		ccd			extract out CCD temperature
;
;	OUTPUT
;		data		all data from file
;
;	10/15/06  Tom Woods   Original Code
;	3/23/11   Tom Woods   Updated so can read *.sav file instead of binary *.dat file
;
pro plot_analogs, filename, data, xrange=xrange, plotnum=plotnum, tzero=tzero, rocket=rocket, $
				ccd=ccd, debug=debug

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick All Analogs Data File', filter='*analogs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

rnum = 36.290
if keyword_set(rocket) then rnum = rocket
if (rnum ne 36.275) and (rnum ne 36.233) and (rnum ne 36.240) and (rnum ne 36.258) $
	and (rnum ne 36.286) and (rnum ne 36.290) then begin
  stop, 'STOP:  ERROR with "rnum"...'
endif

;
;	needs to be same as what is defined in read_tm1_cd.pro
;
if (rnum eq 36.233) then begin
  numanalogs = 33L
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
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			exp_cur: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xps_tempa: 0.0, xps_tempb: 0.0, axs_tec_hot: 0.0  }
endif else if (rnum eq 36.290) then begin
   ;  Note smaller structure like 36.286
    ;		There are many changes in TM1 format
    ;   define the TM items for all of the analog monitors
    ;     X = WD + 3 (CD, -1 for RT), Y = FR - 1
    ;
    numanalogs = 24L
    atemp = { time: 0.0D0, tm_28v: 0.0, tm_cur: 0.0, exp_28v: 0.0, $
  			tv_12v: 0.0, tv_pos: 0.0, fpga_5v: 0.0, $
  			solar_press: 0.0, gate_valve: 0.0, cryo_hot_temp: 0.0, $
  			exp_cur: 0.0, megsa_ff: 0.0, megsb_ff: 0.0, $
  			megsa_ccd_temp: 0.0, megsa_heater: 0.0, megsp_temp: 0.0, $
  			megsb_ccd_temp: 0.0, megsb_heater: 0.0, xps_pwr: 0.0, $
  			xps_pos: 0.0, xps_cw: 0.0, xps_ccw: 0.0, $
  			xrs_5v: 0.0, xrs_temp1: 0.0, xrs_temp2: 0.0 }
endif

nbytes = n_tags(atemp,/length)

;
;  two options for reading data
;		1) *.dat reads binary file
;		2) *.sav reads IDL save set (restore)
;
;
;	read binary file if file given is *.dat or read (restore) IDL save set if file is *.sav
;
rpos = strpos( filename, '.', /reverse_search )
if (rpos lt 0) then begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endif
extfile = strupcase(strmid(filename,rpos+1,3))

;
;	READ IF block for *.DAT files
;
if (extfile eq 'DAT') then begin

openr,lun,filename, /get_lun
a = assoc(lun, atemp)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: only partial data set found, so nothing to plot"
  close, lun
  free_lun, lun
  return
endif

;
;	read the data
;
data = replicate( atemp, dcnt )
for k=0L,dcnt-1L do begin
  data[k] = a[k]
endfor

close, lun
free_lun, lun

endif else if (extfile eq 'SAV') then begin
  ;
  ;	READ IF block for *.SAV files
  ;
  restore, filename	; expect to have "analog" in this save set
  if (n_elements(analog) gt 10) then begin
    data = analog
    analog = 0L
  endif ; else assume that "data" was in the save set
endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

;
;	now plot the data
;
ans = ' '
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=800,ysize=600
setplot
numplots = 3L  ; multiple plots per page
!p.multi=[0,1,numplots]

kstart = 0L
kend = numanalogs-1L
plotmax = numanalogs/numplots
if ((plotmax*numplots) eq numanalogs) then plotmax = plotmax-1L
if keyword_set(plotnum) then begin
  if (plotnum lt 0) then plotnum = 0L
  if (plotnum gt plotmax) then plotnum = plotmax
  kstart=plotnum*numplots
  kend = kstart
  if (plotnum eq 0) then plotnum = 0.1   ; so keyword_set() works
endif

; UT time for launch time
if (rnum eq 36.217) then tz = 18*3600L + 23*60L + 30  $
else if (rnum eq 36.240) then tz = 16*3600L + 58*60L + 0.72D0 $
else if (rnum eq 36.258) then tz = 18*3600L + 32*60L + 2.00D0 $
else if (rnum eq 36.275) then tz = 17*3600L + 50*60L + 0.354D0 $
else if (rnum eq 36.286) then tz = 18*3600L + 0*60L + 0.0D0 $    ; ????
else tz = data[0].time

if keyword_set(tzero) then tz = tzero
if (data[0].time-tz) lt -500 then tz=data[0].time
ptime = (data.time - tz)		; relative time

xr = [min(ptime),max(ptime)]
if (xr[1]-xr[0]) gt 1000 then xr = median(ptime)+[-500,500]
if keyword_set(xrange) then xr=xrange

wgd = where((ptime ge xr[0]) and (ptime le xr[1]), numgd)
if (numgd lt 2) then wgd = where(ptime ne 0)

tnames = tag_names(atemp)

for k=kstart,kend,numplots do begin
  jend = k+numplots-1L
  if (jend ge numanalogs) then jend = numanalogs-1L
  pnumstr = strtrim(k/numplots,2)
  for j=k,jend do begin
    if (j eq (k+numplots-1L)) then begin
      xtitle='Time (sec)'
      ymargin=[3,1]
    endif else begin
      xtitle=''
      ymargin=[2.5,1.5]
    endelse
    rnumstr = strtrim(string(rnum,format='(F6.3)'),2)
    mtitle=rnumstr + '-P' + pnumstr + ': ' + tnames[j+1]
    plot, ptime[wgd], data[wgd].(j+1), yr=[0,5], ys=1, xrange=xr, xs=1, $
        xtitle=xtitle, ytitle='Volts', title=mtitle, xmargin=[7,2], ymargin=ymargin
  endfor
  if (not keyword_set(plotnum)) and ((k+numplots) lt numanalogs) then begin
    read, 'Next ? ', ans
    ans = strupcase(strmid(ans,0,1))
    if (ans eq 'N') then goto, exitplot
  endif
endfor

;
;	extract out CCD temperature into data file and convert to degrees C
;
if keyword_set(ccd) then begin
  num_tags = n_elements(tnames)
  ccda = -1L
  ccdb = -1L
  for k=0,num_tags-1 do begin
    if (strupcase(tnames[k]) eq 'MEGSA_CCD_TEMP') then ccda = k
    if (strupcase(tnames[k]) eq 'MEGSB_CCD_TEMP') then ccdb = k
  endfor
  ;
  ;	CCD temperature calibration in countdown Excel worksheet
  ;
  ccd_volt = [4.500, 4.375, 4.250, 4.125, 4.000, 3.875, 3.750, 3.625, 3.500, 3.375, 3.250, 3.125, 3.000, $
	2.875, 2.750, 2.625, 2.500, 2.375, 2.250, 2.125, 2.000 ]
  ccda_temp = [12.250, 7.938, 3.625, -0.688, -5.000, -9.313, -13.625, -17.938, -22.250, -26.563, $
	-30.875, -35.188, -39.500, -43.813, -48.125, -52.438, -56.750, -61.063, -65.375, -69.688, -74.000]
  ccdb_temp = [-0.975, -5.281, -9.587, -13.894, -18.200, -22.506, -26.813, -31.119, -35.425, -39.731, $
	-44.038, -48.344, -52.650, -56.956, -61.263, -65.569, -69.875, -74.181, -78.488, -82.794, -87.100]
  ;
  ;	store CCD temperature data
  ;
  ccd_data = fltarr(3,n_elements(ptime))
  ccd_data[0,*]=ptime
  if (ccda ge 0) then begin
  	avolt = data.(ccda)
  	atemp = -143.00 + 34.5001 * avolt
  	ccd_data[1,*] = atemp
  endif else print, 'ERROR finding MEGS-A CCD Temperature Record !!!!'
  if (ccdb ge 0) then begin
  	bvolt = data.(ccdb)
  	btemp = -156.00 + 34.4501 * bvolt
  	ccd_data[2,*] = btemp
  endif else print, 'ERROR finding MEGS-B CCD Temperature Record !!!!'
  ;
  ;	save CCD data
  ;
  ccd_file = 'ccd_temp_'+strtrim(string(rnum,format='(F6.3)'),2)+'.dat'
  write_dat,ccd_data,file='~/Desktop/'+ccd_file,format='(F12.6,2F10.2)'
  print, 'CCD data written to ', ccd_file
  stop, 'Debug CCD data results ...'
endif


exitplot:
!p.multi=0

if keyword_set(debug) then stop, 'DEBUG: stopped at end...'

return
end
