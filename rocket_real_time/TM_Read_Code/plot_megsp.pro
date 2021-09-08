;
;	plot_megsp.pro
;
;	Plot MEGS-P channel time series from read_tm1_cd.pro
;
;	INPUT
;		filename	file name (*pmegs.dat or '' to ask user to select file)
;		xrange=xrange    time range for plot
;		channel=channel  number of channel to plot (single plot versus all channels)
;						 channel = 1-2
;
;		/allanalog  plot all analog channels for MEGS-A and MEGS-B monitors
;       analog=analog    analog monitor number (single plot versus all monitors)
;                        analog = 1-50
;
;
;	OUTPUT
;		data		all data from file
;
;	Tom Woods
;	10/15/06
;
pro plot_megsp, filename, pdata, xrange=xrange, yrange=yrange, channel=channel, $
					allanalog=allanalog, analog=analog, tzero=tzero, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick MEGS-P Data File', filter='*pmegs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

numpcnt = 2L
numpanalog = 64L

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
;
;	pdata data structure needs to be same as what is defined in read_tm1_cd.pro
;

;	add extra LONG at end to work on Intel based Mac
pmegs1 = { time: 0.0D0, fpga_time: 0.0, rec_error: 0, cnt: uintarr(numpcnt), monitor: ulonarr(numpanalog) } ; , dummy: 0L }
nbytes = n_tags(pmegs1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, pmegs1)

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
pdata = replicate( pmegs1, dcnt )
for k=0L,dcnt-1L do begin
  ptemp = a[k]
  ; swap_endian_inplace, ptemp, /swap_if_little_endian
  pdata[k] = ptemp
endfor

close, lun
free_lun, lun

endif else if (extfile eq 'SAV') then begin
  ;
  ;	READ IF block for *.SAV files
  ;
  restore, filename	; expect to have "pdata" in this save set
  if (n_elements(pmegs) gt 10) then pdata = pmegs
  ; else assume it is alraedy "pdata" in the restore file
endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

; stop, 'STOP:  Check out "pdata"...'

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.286
  if (rocket ne 36.258) and (rocket ne 36.275) and (rocket ne 36.286) $
  		and (rocket ne 36.290) and (rocket ne 36.300) and (rocket ne 36.318) $
  		and (rocket ne 36.336) and (rocket ne 36.353) then rocket = 36.353
endif else rocket = 36.353

if (rocket eq 36.258) then begin
    tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 15.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=5.
endif else if (rocket eq 36.275) then begin
    tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else if (rocket eq 36.286) then begin
    tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else if (rocket eq 36.290) then begin
    tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else if (rocket eq 36.300) then begin
    tzero = 19*3600L+15*60L+0.000D0  ; launch time in UT
    tapogee = 200.
    dtlight = 15.
    tdark1 = 100.
    tdark2 = 360.
    dtdark=5.
endif else if (rocket eq 36.318) then begin
    tzero = 19*3600L+0*0L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else if (rocket eq 36.336) then begin
    tzero = 19*3600L+0*0L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else if (rocket eq 36.353) then begin
    tzero = 17*3600L+25*60L+0.000D0  ; launch time in UT (TBD)
    tapogee = 275. ; TBD
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
endif else begin
	; force to 0.0 so don't look for special dark / visible times
	rocket = 0.0
endelse

;
;	now plot the data
;
ans = ' '
if (!d.name eq 'X') and ((!d.x_size ne 1200) or (!d.y_size ne 800)) then window,0,xsize=1200,ysize=800
setplot
!p.multi=[0,1,2]
kstart = 0L
kend = 1L
xmargin=[7,2]
ymargin=[3,2]
ans = ''

if keyword_set(channel) then begin
  !p.multi=0
  if (channel lt 1) then channel = 1L
  if (channel gt 2) then channel = 2L
  kstart=channel-1
  kend = kstart
  xmargin=[8,2]
  ymargin=[4,2]
endif

tz = pdata[0].time
if keyword_set(tzero) or (rocket ne 0) then tz = tzero
ptime = (pdata.time - tz)

;
;	print MEGS-P detector results
;
if (rocket ne 0.0) then begin
  wgd = where( (ptime gt (tapogee-dtlight)) and (ptime lt (tapogee+dtlight)) )
  wgd1 = where( (ptime gt (tdark1-dtdark)) and (ptime lt (tdark1+dtdark)) )
  wgd2 = where( (ptime gt (tdark2-dtdark)) and (ptime lt (tdark2+dtdark)) )
  temp = mean( ptime )  ; dummy so header strings printed after MEAN compile messages
  print, ' '
  print, '  Channel      Dark-1    Dark-2      Apogee  Signal(=Light-Dark)'
endif

if not keyword_set(xrange) then xrange = [ min(ptime), max(ptime) ]

for k=kstart,kend do begin
    mtitle='MEGS-P #' + strtrim(k+1,2)

    yr = [0,60]
    if keyword_set(yrange) then yr = yrange
    plot, ptime, pdata.cnt[k], xrange=xrange, xs=1, yrange=yr, ys=1, $
        xtitle='Time (sec)', ytitle='Counts', title=mtitle, xmargin=xmargin, ymargin=ymargin

    if (rocket ne 0.0) then begin
      oplot, (tapogee-dtlight)*[1,1], !y.crange, line=2
      oplot, (tapogee+dtlight)*[1,1], !y.crange, line=2
      oplot, (tdark1-dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark1+dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark2-dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark2+dtdark)*[1,1], !y.crange, line=1
      light = mean( pdata[wgd].cnt[k] )
      dark1 = mean( pdata[wgd1].cnt[k] )
      dark2 = mean( pdata[wgd2].cnt[k] )
      signal = light-(dark1+dark2)/2.
      print, 'MEGS-P #',k+1,dark1,dark2,light,signal,format='(A8,I2,2F10.2,F12.2,F12.2)'
    endif
endfor
!p.multi=0

;
;	now check if need to plot analog monitors
;
if (not keyword_set(allanalog)) and (not keyword_set(analog)) then goto, exitplot
ans = ' '
read, 'Next  plot ? (Y/N) ', ans
ans = strupcase(strmid(ans,0,1))
if (ans eq 'N') then goto, exitplot

numplots = 3L
!p.multi=[0,1,numplots]
kstart = 0L
kend = numpanalog-1L
xmargin=[7,2]
ymargin=[3,2]
ans = ''

if keyword_set(analog) then begin
  !p.multi=0
  if (analog lt 1) then analog = 1L
  if (analog gt numpanalog) then analog = numpanalog
  kstart=analog-1L
  kend = kstart
  xmargin=[8,2]
  ymargin=[4,3]
endif

;
;	define analog conversions and names
;
aunits = [ "V", "¡C", "V", "V", "V", $
			"V", "C", "C", "V", "V", $
			"V", "V", "V", "V", "V", $
			"V", "V", "V", "V", "V", $
			"V", "V", "DN", "DN", "DN", $
			"DN", "DN", "DN", "V", "V", "V", $
			"V", "C", "C", "V", "V", $
			"V", "V", "V", "V", "V", $
			"V", "V", "V", "V", "V", $
			"V", "V", "DN", "DN", "DN", $
			"DN", "DN", "DN", "V", "V", "V", $
			"V", "V", "V", "V", "V", $
			"V", "V" ]

anames = [ "Spare 1", "FPGA Bd Temp", "FPGA +5V", "FPGA +3.3V", "FPGA +2.5V", $
			"FPGA 1.2V", "MEGS-A CEB Temp", "MEGS-A CPR Temp", "MEGS-A +24V", "MEGS-A +15V", $
			"MEGS-A -15V", "MEGS-A +5V Analog", "MEGS-A -5V Analog", "MEGS-A +5V Digital", "MEGS-A +2.5V", $
			"MEGS-A +24 Current", "MEGS-A +15 Current", "MEGS-A -15 Current", "MEGS-A +5 Alg Current", "MEGS-A -5 Alg Current", $
			"MEGS-A +5 Dgt Current", "MEGS-A +2.5 Current", "MEGS-A Integration", "MEGS-A Analog Mux", "MEGS-A Digital Status", $
			"MEGS-A Timer", "MEGS-A Cmd Error Count", "MEGS-A CEB FPGA Version", "Spare 2", "Spare 3", "Spare 4", $
			"Spare 5", "MEGS-B CEB Temp", "MEGS-B CPR Temp", "MEGS-B +24V", "MEGS-B +15V", $
			"MEGS-B -15V", "MEGS-B +5V Analog", "MEGS-B -5V Analog", "MEGS-B +5V Digital", "MEGS-B +2.5V", $
			"MEGS-B +24 Current", "MEGS-B +15 Current", "MEGS-B -15 Current", "MEGS-B +5 Alg Current", "MEGS-B -5 Alg Current", $
			"MEGS-B +5 Dgt Current", "MEGS-B +2.5 Current", "MEGS-B Integration", "MEGS-B Analog Mux", "MEGS-B Digital Status", $
			"MEGS-B Timer", "MEGS-B Cmd Error Count", "MEGS-B CEB FPGA Version", "Spare 6", "Spare 7", "Spare 8", $
			"Spare 9", "Spare 10", "Spare 11", "Spare 12", "Spare 13", $
			"Spare 14", "Spare 15" ]

adbase = -10.
adslope = 20. / (2.^16-1.)
tempbase = 20. - 0.56 /2.E-3 + adbase / 2.E-3
tempslope = adslope / 2.E-3
aconvert = [ [adbase, adslope], [tempbase, tempslope], [adbase, adslope]*2., [adbase, adslope]*2., [adbase, adslope]*2., $
		[adbase, adslope]*2., [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-8.), [adbase, adslope]*(-6.), $
		[adbase, adslope]*6., [adbase, adslope]*(-2.), [adbase, adslope]*2., [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), $
		[adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), $
		[adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [0.,1.], [0.,1.], [0.,1.], $
		[0.,1.], [0.,1.], [0.,1.], [adbase, adslope], [adbase, adslope], [adbase, adslope], $
		[adbase, adslope], [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-8.), [adbase, adslope]*(-6.), $
		[adbase, adslope]*6., [adbase, adslope]*(-2.), [adbase, adslope]*2., [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), $
		[adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [adbase, adslope]*(-2.), $
		[adbase, adslope]*(-2.), [adbase, adslope]*(-2.), [0.,1.], [0.,1.], [0.,1.], $
		[0.,1.], [0.,1.], [0.,1.], [adbase, adslope], [adbase, adslope], [adbase, adslope], $
		[adbase, adslope], [adbase, adslope], [adbase, adslope], [adbase, adslope], [adbase, adslope], $
		[adbase, adslope], [adbase, adslope]  ]
aconvert = reform( aconvert, 2, n_elements(aconvert)/2 )

;
;	big loop for doing plots
;
for k=kstart,kend,numplots do begin
  jend = k+numplots-1L
  if (jend ge numpanalog) then jend = numpanalog-1L
   for j=k,jend do begin
    if (j eq (k+numplots-1L)) then begin
      xtitle='Time (sec)'
      ymargin=[3,1]
    endif else begin
      xtitle=''
      ymargin=[2.5,1.5]
    endelse
    pnumstr = 'A' + strtrim(j+1,2) + ': '
    mtitle=pnumstr + anames[j]
    ytitle=aunits[j]

    ; convert to proper unit
    analogdata = pdata.monitor[j] * aconvert[1,j] + aconvert[0,j]
    yrange = median(analogdata) * [0.9, 1.1]
    if keyword_set(xrange) then begin
      plot, ptime, analogdata, yrange=yrange, ys=1, xrange=xrange, xs=1, $
        xtitle=xtitle, ytitle=ytitle, title=mtitle, xmargin=[7,2], ymargin=ymargin
    endif else begin
      plot, ptime, analogdata, yrange=yrange, ys=1, $
        xtitle=xtitle, ytitle=ytitle, title=mtitle, xmargin=[7,2], ymargin=ymargin
    endelse
  endfor
  if (not keyword_set(plotnum)) and ((k+numplots) lt numpanalog) then begin
    read, 'Next ? ', ans
    ans = strupcase(strmid(ans,0,1))
    if (ans eq 'N') then goto, exitplot
  endif
endfor

exitplot:
!p.multi = 0

return
end
