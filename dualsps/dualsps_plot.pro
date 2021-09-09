;+
; NAME:
;	dualsps_plot
;
; PURPOSE:
;	Do quick time series plot of Dual-SPS data from HYDRA TLM file
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:
;	dualsps_plot, filename, [ channel, surffile, /debug, data=data, surfdata=surfdata, plotdata=plotdata]
;
; INPUTS:
;	filename	HYDRA telemetry data file from Dual-SPS instrument
;	channel		Channel names can be 'SPS1', 'SPS1_X', 'SPS1_Y', 'SPS1_1' ... 'SPS1_4'
;					and 'SPS2', 'SPS2_X', 'SPS2_Y', 'SPS2_1' ... 'SPS2_4'
;				Default is 'SPS2' for Magnetograph TTM
;	surffile	Optional input to read SURFER log file
;	/debug		Option to print DEBUG messages
;	/edt		Option to convert to Eastern Daylight Time offset from UT
;	/est		Option to convert to Eastern Standard Time offset from UT
;	/quad45		Option to plot Quad13 and Quad24 instead of QuadX and QuadY (as needed at SURF)
;
; OUTPUTS:
;	PLOT		Plot to screen the time series of specified channel
;				Plot is normalized to SURF beam current if given surffile
;
;	data		Optional output to pass the data from the HYDRA data file
;	surfdata	Optional output to pass the SURFER PC log data
;   plotdata	Optional output to pass the plot data (time, signal)
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.	Read the HYDRA data file
;	3.	Read the SURFER log file (option)
;	4.  Make the "data" (time, counts or counts/mA)
;	5.  Plot the "data"
;
; MODIFICATION HISTORY:
;	8/27/2019	Tom Woods	Original based on plot_picosim.pro (did not test SURF options)
;+

pro dualsps_plot, filename, channel, surffile, debug=debug, $
			data=data, surfdata=surfdata, plotdata=plotdata, edt=edt, est=est, $
			quad45=quad45,win=win,xpos=xpos,ypos=ypos,xsize=xsize,ysize=ysize,inst=inst

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  dualsps_plot, filename, [ channel, surffile, /debug, data=data, surfdata=surfdata, plotdata=plotdata]'
  return
endif

if (n_params() lt 1) then begin
  filename = ''
endif

if n_params() lt 2 then channel = 'SPS2'  ; default value for Magnetograph TTM
ch = strupcase(channel)
if (ch ne 'SPS1') and (ch ne 'SPS1_X') and (ch ne 'SPS1_Y') $
	and (ch ne 'SPS1_1') and (ch ne 'SPS1_2') and (ch ne 'SPS1_3') and (ch ne 'SPS1_4') $
	and (ch ne 'SPS2') and (ch ne 'SPS2_X') and (ch ne 'SPS2_Y') $
	and (ch ne 'SPS2_1') and (ch ne 'SPS2_2') and (ch ne 'SPS2_3') and (ch ne 'SPS2_4') $
	and (ch ne 'X55') $
then begin
  print, 'ERROR dualsps_plot: Invalid Channel name.  Expected SPSn, SPSn_X, SPSn_Y, SPSn_1-SPSn_4 for n=1 or 2.'
  return
endif

if (n_params() lt 3) then doSURF = 0 else doSURF = 1

;
;	2.	Read the HYDRA telemetry data file
;		Also make a short version of filename for plot title
;
data = dualsps_read_file( filename, debug=debug, x55_packets=x55_packets, /verbose )  ;  add messages=msg to call for Messages
if (n_elements(data) lt 2) then begin
  print, 'ERROR dualsps_plot: No valid data found for ', filename
  return
endif

pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

if keyword_set(debug) then print, 'HYDRA file = ', fileshort

;
;	3.	Read the SURFER log file (option)
;
if (doSURF ne 0) then begin
  surfdata = surfer_read_data( surffile )
  pslash = strpos( surffile, '/', /reverse_search )
  if (pslash gt 0) then surfshort = strmid( surffile, pslash+1, strlen(surffile)-pslash-1) $
  else surfshort = surffile
  if keyword_set(debug) then print, 'SURF file = ', surfshort
endif

;
;	4.  Make the "plotdata" (time, counts/sec or counts/sec/mA)
;		time = Seconds of Day (SOD)
;		channel = channel name
;		signal = signal for selected channel
;		signal_per_mA = signal / surfbc if surffile is given
;		quadx, quady = Quad diode calculation
;
tempdata = { time: 0.0D0, channel: 'xx', signal: 0.0, signal_per_mA: 0.0, $
			quadx: 0.0, quady: 0.0, quad13: 0.0, quad24: 0.0, quadtotal: 0.0, $
			surfbc: 0.0D0, surfx: 0.0, surfy: 0.0, surfu: 0.0, surfv: 0.0, $
			surfenergy: 0.0, surfheight: 0.0, surffuzz: 0.0, surfvalves: 0, x55_spectra: fltarr(1024L)  }

num_data = n_elements( data )
plotdata = replicate( tempdata, num_data )

;  convert file time into seconds of day (SOD)
utoffset = 0.0D0   ; no offset if HYDRA computer setup for UT time (default)
;  convert from EDT to UT be consistent with SURFER time
if keyword_set(edt) then utoffset = 4. * 3600.D0
; special check for EST instead of default EDT
if keyword_set(est) then utoffset = 5. * 3600.D0

; configure time as Seconds Of Day
sod = data.hour * 3600.D0 + data.minute * 60. + data.second + utoffset
plotdata.time = sod

;  store Channel name
plotdata.channel = ch

;  store Channel signal
if (ch eq 'SPS1') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps1_quad_sum
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_X') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps1_quad_x
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_Y') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps1_quad_y
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_1') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[0]
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_2') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[1]
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_3') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[2]
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_4') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[3]
  wgood = where( data.have_sps1 eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS2') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_sum
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_X') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_x
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_Y') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_y
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_1') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[0]
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_2') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[1]
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_3') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[2]
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_4') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[3]
  wgood = where( data.have_sps2 eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'X55') then begin
  wgood = where( x55_packets.have_x55 eq 1, numgood )
  plotdata.x55_spectra=x55_packets[wgood[-1]].x55_spectra
endif

; reduce plotdata to the GOOD data
if (ch eq 'X55') then begin
  setplot
  if keyword_set(win) then window,win,title=inst, XPOS=xpos , YPOS=ypos, XSIZE=xsize , YSIZE=ysize
  plot,indgen(1024),plotdata.x55_spectra,title='X55 Spectra',ytitle='Counts',xtitle='Bin'
endif else begin

if (numgood lt 10) then begin
  print, 'ERROR dualsps_plot: no good SPS data found for channel ', ch
  return
endif
print, 'dualsps_plot: reduced SPS data set to ', strtrim(numgood,2), ' elements.'
plotdata = plotdata[wgood]
ch_sps_data = ch_sps_data[wgood,*]
num_data = numgood
;
;	If Quad, then calculate Quad X & Y values and also diagonal Quad values for SURF Yaw and Pitch scans
;	These are unitless with range of -1 to 1.
;	To convert to degrees, then multiply by about 4 degrees for SPS.
;
doPrint = 0
if (isQuad ne 0) then begin
  quadsignal = fltarr(4,num_data)
  for j=0,3 do begin
    fscale = float(quadDarkFactor[j])
    quadsignal[j,*] = reform(ch_sps_data[*,j]) - sdark * fscale
  endfor
  quadtotal = total(quadsignal,1) > 1.
  plotdata.quadtotal = quadtotal
  plotdata.quadx = reform(((quadsignal[2,*]+quadsignal[3,*]) - (quadsignal[0,*]+quadsignal[1,*])))/quadtotal
  plotdata.quady = reform(((quadsignal[0,*]+quadsignal[3,*]) - (quadsignal[1,*]+quadsignal[2,*])))/quadtotal
  plotdata.quad13 = reform((quadsignal[0,*]-quadsignal[2,*]) / ((quadsignal[0,*]+quadsignal[2,*])>1.))
  plotdata.quad24 = reform((quadsignal[3,*]-quadsignal[1,*]) / ((quadsignal[1,*]+quadsignal[3,*])>1.))
  if (min(quadtotal) lt 10) then begin
  	wlow = where(quadtotal lt 10)
  	plotdata[wlow].quadx = 0.0
  	plotdata[wlow].quady = 0.0
  	plotdata[wlow].quad13 = 0.0
  	plotdata[wlow].quad24 = 0.0
  endif
  if (ch eq 'SPS1') then begin
  	;  replace with TM values for Quad X and Y
  	plotdata.quadx = data.sps1_quad_x
  	plotdata.quady = data.sps1_quad_y
  	doPrint = 1
  endif else if (ch eq 'SPS2') then begin
  	;  replace with TM values for Quad X and Y
  	plotdata.quadx = data.sps2_quad_x
  	plotdata.quady = data.sps2_quad_y
  	doPrint = 1
  endif
endif

if (doPrint ne 0) then begin
	print, ' '
	print, ch, ' Median signal ', median( plotdata.signal), ' +/- ', stddev(plotdata.signal)
	print, '     Quad X Median ', median( plotdata.quadx), ' +/- ', stddev(plotdata.quadx)
	print, '     Quad Y Median ', median( plotdata.quady), ' +/- ', stddev(plotdata.quady)
	print, ' '
endif

;
;	Fill in the SURF data and also normalize signal with beam current (BC) if surffile is given
if (doSURF ne 0) then begin
  ; check on time range for data
  surfmin = min(surfdata.time_sod) - 120	; allow 2-min lapse
  surfmax = max(surfdata.time_sod) + 120  ; allow 2-min lapse
  if (min(plotdata.time) lt surfmin) or (max(plotdata.time) gt surfmax) then begin
    print, 'WARNING: SURFER and HYDRA Times do not align !!!!!'
    if (min(plotdata.time) lt surfmin) then $
	    print, '      MIN Time difference = ', abs(min(plotdata.time) - surfmin)
    if (max(plotdata.time) gt surfmax) then $
    	print, '      MAX Time difference = ', abs(min(plotdata.time) - surfmax)
    ;  continue anyway !!! ???
    ; if keyword_set(debug) then stop, 'STOP: DEBUG SURFER time...'
    ;
    ans = ' '
    read, 'Do you want to adjust PicoSIM time scale with its Sequence Count (Y or N) ? ', ans
    ans3 = strupcase(strmid(ans,0,1))
    if (ans3 eq 'Y') then begin
		;	attempt to fix the time issue (e.g. broken Real Time Clock on PicoSIM)
		;	by finding time when Valves were last opened and a Valve was last closed
		; TIME PICOSIM ===> data.sequence_count * 1.4527sec  as first-order guess
		period = 1.4527
		newtime = surfdata[0].time_sod+(data.sequence_count-data[0].sequence_count)*period
		tzero = surfdata[0].time_sod
		stime = surfdata.time_sod - tzero
		ptime = newtime - tzero
		; FIND SURF Valve open time
		wclose = where(surfdata.valves lt 7,numclose)
		wopen = where(surfdata.valves ge 7,numopen)
		sopen = 0.0 & sclose = 0.0
		if (numclose gt 2) then begin
			diffclose = stime[wclose[1:numclose-1]] - stime[wclose[0:numclose-2]]
			temp = max(diffclose,wmax)
			sopen = stime[wclose[wmax]+1]
		endif
		; FIND SURF Valve last close time
		if (numopen gt 2) then begin
			sclose = stime[wopen[numopen-1]]
		endif
		; FIND Signal dark and light times
		signal = plotdata.signal
		if (ch eq 'SPS_X') or (ch eq 'SPS_Y') then signal = data.sps_quad_sum
		cmax = max(signal)  &  cmin = min(signal) & crange = cmax-cmin
		clow = cmin + crange*0.10  ;  10% level
		chigh = cmax - crange*0.50 ; 50% level
		w_close = where(signal lt clow,num_close)
		w_open = where(signal gt chigh,num_open)
		popen = 0.0 & pclose = 0.0
		; FIND Signal last opened time
		if (num_close gt 2) then begin
			diff_close = ptime[w_close[1:num_close-1]] - ptime[w_close[0:num_close-2]]
			temp = max(diff_close,w_max)
			popen = ptime[w_close[w_max]+1]
		endif
		; FIND Signal last close time
		if (num_open gt 2) then begin
			pclose = ptime[w_open[num_open-1]]
		endif
		if (sopen ne 0.0) and (sclose ne 0.0) and (popen ne 0.0) and (pclose ne 0.0) then begin
			delta_time = popen - sopen
			period_factor = (sclose - sopen) / (pclose - popen)
			newtime = surfdata[0].time_sod - delta_time
			newtime += (data.sequence_count-data[0].sequence_count)*period*period_factor
			print, '***** WARNING ***** PicoSIM time adjusted with Sequence Count'
			print, '                    delta_time = ', strtrim(delta_time,2)
			print, '                 period_factor = ', strtrim(period_factor,2)
		endif else begin
			print, '***** WARNING ***** Rough estimate for PicoSIM time is made with Sequence Count'
		endelse
		old_plot_time = plotdata.time
	LOOPBACK_PLOT:
		plotdata.time = newtime
		setplot
		cc=rainbow(7)
		plot,stime,surfdata.valves,xtitle='SURF Time',ytitle='SURF Valves'
		oplot,sopen*[1,1],!y.crange,line=2
		oplot,sclose*[1,1],!y.crange,line=3
		sigmax = max(signal)
		sigmin = min(signal)
		signalscaled = (signal-sigmin)*7/(sigmax-sigmin)
		oplot,newtime-tzero,signalscaled,color=cc[3]
		oplot,popen*[1,1],!y.crange,line=2,color=cc[3]
		oplot,pclose*[1,1],!y.crange,line=3,color=cc[3]
		ans = ' '
		read, 'Do you accept this PicoSIM time adjustment (Y or N) ? ', ans
		ans = strupcase(strmid(ans,0,1))
		if (ans eq 'N') then begin
			; go back to first guess and get User input
			newtime = surfdata[0].time_sod+(data.sequence_count-data[0].sequence_count)*period
			plot,stime,surfdata.valves,xtitle='SURF Time',ytitle='SURF Valves'
			oplot,newtime-tzero,signalscaled,color=cc[3]
			ans2=' '
			print, 'You will now select the REFERENCE transitions for the SURF BL Valve...'
			read, 'Move cursor to LEFT side of Reference Valve Change and hit RETURN key...', ans2
			cursor, rx1, y1, /nowait
			sopen = rx1
			oplot,sopen*[1,1],!y.crange,line=2
			read, 'Move cursor to RIGHT side of Reference Valve Change and hit RETURN key...', ans2
			cursor, rx2, y2, /nowait
			sclose = rx2
			oplot,sclose*[1,1],!y.crange,line=3
			print, 'You will now select the DATA transitions for the SURF Valve Changes...'
			read, 'Move cursor to LEFT side of Reference Valve Change and hit RETURN key...', ans2
			cursor, dx1, y1, /nowait
			popen = dx1
			oplot,popen*[1,1],!y.crange,line=2,color=cc[3]
			read, 'Move cursor to RIGHT side of Reference Valve Change and hit RETURN key...', ans2
			cursor, dx2, y2, /nowait
			pclose = dx2
			oplot,pclose*[1,1],!y.crange,line=3,color=cc[3]
			;  calculate new time scale
			delta_time = popen - sopen
			period_factor = (sclose - sopen) / (pclose - popen)
			newtime = surfdata[0].time_sod - delta_time
			newtime += (data.sequence_count-data[0].sequence_count)*period*period_factor
			print, '***** WARNING ***** PicoSIM time adjusted with Sequence Count'
			print, '                    delta_time = ', strtrim(delta_time,2)
			print, '                 period_factor = ', strtrim(period_factor,2)
			goto, LOOPBACK_PLOT
		endif
	  endif
  endif
  ; stop, 'STOP: Debug SURFER / PicoSIM time difference (enter .c to continue)...'
  if keyword_set(debug) then begin
    print, ' '
    print, 'dualsps_plot: First HYDRA time = ', strtrim(plotdata[0].time,2)
    print, 'dualsps_plot: First SURF  time = ', strtrim(surfdata[0].time_sod,2)
    extra_offset = 0.0
    read, 'Enter Offset Time to add to HYDRA time (sec): ', extra_offset
    plotdata.time = plotdata.time + extra_offset
  endif
  smoothbc = smooth(surfdata.beam_current_mA,3,/edge_truncate)
  plotdata.surfbc = interpol( smoothbc, surfdata.time_sod, plotdata.time )
  plotdata.signal_per_mA = plotdata.signal / (plotdata.surfbc > 1E-6)
  plotdata.surfx = interpol( surfdata.x_pos_arcsec, surfdata.time_sod, plotdata.time )
  plotdata.surfy = interpol( surfdata.y_pos_arcsec, surfdata.time_sod, plotdata.time )
  plotdata.surfu = interpol( surfdata.yaw_deg, surfdata.time_sod, plotdata.time )
  plotdata.surfv = interpol( surfdata.pitch_deg, surfdata.time_sod, plotdata.time )
  plotdata.surfenergy = interpol( surfdata.energy_mev, surfdata.time_sod, plotdata.time )
  plotdata.surfheight = interpol( surfdata.height_mm, surfdata.time_sod, plotdata.time )
  plotdata.surffuzz = interpol( surfdata.fuzz_factor, surfdata.time_sod, plotdata.time )
  plotdata.surfvalves = interpol( surfdata.valves, surfdata.time_sod, plotdata.time )
endif

;
;	5.  Plot the plotdata.siganl
;		Simple time series for PS1-PS6
;		Dual plot for SPS:  time series and X-Y quad values
;
setplot
cc = rainbow(7)
cs = 1.8
ct = 1.5

tbase = long(plotdata[0].time/1000.) * 1000L
ptime = plotdata.time - tbase
xtitle = 'Time (SOD'
if (tbase ne 0) then xtitle=xtitle+'-'+strtrim(tbase,2)+')' else xtitle=xtitle+')'

if (isQuad ne 0) then begin
  !p.multi=[0,1,2]
  xm = [8.5,2]
  ym = [2.0,1.5]
  xtitle1 = ' '
endif else begin
  !p.multi=0
  xm = [8.5,2]
  ym = [3.0,1.5]
  xtitle1 = xtitle
endelse

ytitle = ch + ' Signal'
psignal = plotdata.signal
if (doSURF ne 0) then begin
	ytitle = ytitle + ' / mA'
	psignal = plotdata.signal_per_mA
endif
if (ch eq 'SPS_X') then begin
	ytitle='SPS X'
	psignal = plotdata.signal
endif
if (ch eq 'SPS_Y') then begin
	ytitle='SPS Y'
	psignal = plotdata.signal
endif

; plot time series of "cnt"
if keyword_set(win) then window,win,title=inst, XPOS=xpos , YPOS=ypos, XSIZE=xsize , YSIZE=ysize
plot, ptime[-11:-1], psignal[-11:-1], xmargin=xm, ymargin=ym, ystyle=1, $
      xtitle=xtitle1, ytitle=ytitle, title=fileshort

if (isQuad ne 0) then begin
  ym2 = [3,0.5]
  plot, ptime[-11:-1], plotdata[-11:-1].quadx, /nodata, yrange=[-1,1], ystyle=1, xmargin=xm, ymargin=ym2, $
      xtitle=xtitle, ytitle='Quad Position', title=" "
  xx = !x.crange[0] * 0.9 + !x.crange[1] * 0.1
  yy = 0.75
  dy = 0.25
  if keyword_set(quad45) then begin
    oplot, ptime, plotdata.quad13, color=cc[0]  ; red
    oplot, ptime, plotdata.quad24, color=cc[3]  ; green
    xyouts, xx, yy, 'Quad13 Rel. Pos.', color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy, 'Quad24 Rel. Pos.', color=cc[3], charsize=cs, charthick=ct
  endif else begin
    oplot, ptime[-11:-1], plotdata[-11:-1].quadx, color=cc[0]  ; red
    oplot, ptime[-11:-1], plotdata[-11:-1].quady, color=cc[3]  ; green
    xyouts, xx, yy, 'X Rel. Pos. '+string(median(plotdata.quadx),format='(F6.3)') $
    	+' +/- '+string(stddev(plotdata.quadx),format='(F7.4)'), color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy, 'Y Rel. Pos. '+string(median(plotdata.quady),format='(F6.3)') $
    	+' +/- '+string(stddev(plotdata.quady),format='(F7.4)'), color=cc[3], charsize=cs, charthick=ct
    xyouts, xx, yy-dy*2, 'Quad Sum Mean '+string(median(plotdata.signal),format='(F8.0)') $
    	+' +/- '+string(stddev(plotdata.signal),format='(F9.1)') , charsize=cs, charthick=ct
  endelse
endif
endelse
;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  if (debug ge 1) then stop, 'STOP: DEBUG at end of dualsps_plot.pro...'
endif

end
