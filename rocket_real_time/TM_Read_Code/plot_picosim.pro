;+
; NAME:
;	plot_picosim
;
; PURPOSE:
;	Do quick time series plot of PicoSIM-SPS data from HYDRA TLM file
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:
;	plot_picosim, channel, [ filename, surffile, /debug, data=data, surfdata=surfdata, plotdata=plotdata]
;
; INPUTS:
;	channel		Channel names can be 'SPS', 'SPS_X', 'SPS_Y' and 'PSx' where x=1-6
;	filename	HYDRA telemetry data file from PicoSIM-SPS instrument
;	surffile	Optional input to read SURFER log file
;	/debug		Option to print DEBUG messages
;	/est		Option to convert to Eastern Standard Time instead of EDT (default)
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
;	3/24/2018	Tom Woods	Original based on plot_rxrs_hydra.pro
;+

pro plot_picosim, channel, filename, surffile, debug=debug, $
			data=data, surfdata=surfdata, plotdata=plotdata, est=est, $
			quad45=quad45, tzero=tzero

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  plot_picosim, channel, [ filename, surffile, /debug, data=data, surfdata=surfdata, plotdata=plotdata]'
  return
endif

ch = strupcase(channel)
if (ch ne 'SPS') and (ch ne 'SPS_X') and (ch eq 'SPS_Y') $
	and (ch ne 'PS1') and (ch ne 'PS2') and (ch ne 'PS3') $
	and (ch ne 'PS4') and (ch ne 'PS5') and (ch ne 'PS6') and (ch ne 'PS') then begin
  print, 'ERROR plot_picosim: Invalid Channel name.  Expected SPS, SPS_X, SPS_Y, or PS1-PS6.'
  return
endif

if (n_params() lt 2) then begin
  filename = ''
endif

if (n_params() lt 3) then doSURF = 0 else doSURF = 1

;
;	2.	Read the HYDRA telemetry data file
;		Also make a short version of filename for plot title
;
data = picosim_read_file( filename, debug=debug, /verbose )
if (n_elements(data) lt 2) then begin
  print, 'ERROR plot_picosim: No valid data found for ', filename
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
			surfenergy: 0.0, surfheight: 0.0, surffuzz: 0.0, surfvalves: 0  }

num_data = n_elements( data )
plotdata = replicate( tempdata, num_data )

;  convert file time into seconds of day (SOD)
;  convert from EDT to UT be consistent with SURFER time
utoffset = 4. * 3600.D0
; special check for EST instead of default EDT
if keyword_set(est) then utoffset = 5. * 3600.D0

sod = data.hour * 3600.D0 + data.minute * 60. + data.second + utoffset
plotdata.time = sod

;  store Channel name
plotdata.channel = ch

;  store Channel signal
if (ch eq 'SPS') then begin
  ptype = 4
  isQuad = 1
  sdark = 27961.0  ; valid for SPS #1
  sdark = max(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps_quad_sum
endif else if (ch eq 'SPS_X') then begin
  ptype = 4
  isQuad = 1
  sdark = 27961.0
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps_quad_x
endif else if (ch eq 'SPS_Y') then begin
  ptype = 4
  isQuad = 1
  sdark = 27961.0
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps_quad_y
endif else if (ch eq 'PS1') or (ch eq 'PS') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[0]
endif else if (ch eq 'PS2') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[1]
endif else if (ch eq 'PS3') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[2]
endif else if (ch eq 'PS4') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[3]
endif else if (ch eq 'PS5') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[4]
endif else if (ch eq 'PS6') then begin
  ptype = 5
  isQuad = 0
  sdark = 0.0
  darkFactor = 1.00
  plotdata.signal = data.picosim_data[5]
endif

;
;	If Quad, then calculate Quad X & Y values and also diagonal Quad values for SURF Yaw and Pitch scans
;	These are unitless with range of -1 to 1.
;	To convert to degrees, then multiply by about 4 degrees for SPS.
;
if (isQuad ne 0) then begin
  quadsignal = fltarr(4,num_data)
  for j=0,3 do begin
    fscale = float(quadDarkFactor[j])
    quadsignal[j,*] = reform((data.sps_data[j] - sdark * fscale)*(-1.)); invert Signal for PicoSIM SPS quad diode
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
endif

;
;	Fill in the SURF data and also normalize signal with beam current (BC) if surffile is given
if (doSURF ne 0) then begin
  ; check on time range for data
  surfmin = min(surfdata.time_sod) - 60	; allow 1-min lapse
  surfmax = max(surfdata.time_sod) + 60  ; allow 1-min lapse
  if (min(plotdata.time) lt surfmin) or (max(plotdata.time) gt surfmax) then begin
    print, 'WARNING: SURFER and HYDRA Times do not align !!!!!'
    if (min(plotdata.time) lt surfmin) then $
	    print, '      MIN Time difference = ', abs(min(plotdata.time) - surfmin)
    if (max(plotdata.time) gt surfmax) then $
    	print, '      MAX Time difference = ', abs(min(plotdata.time) - surfmax)
    ;  continue anyway !!! ???
    ; if keyword_set(debug) then stop, 'STOP: DEBUG SURFER time...'
  endif
  if keyword_set(debug) then begin
    print, ' '
    print, 'plot_picosim: First HYDRA time = ', strtrim(plotdata[0].time,2)
    print, 'plot_picosim: First SURF  time = ', strtrim(surfdata[0].time_sod,2)
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
if keyword_set(tzero) then tbase = tzero[0]
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
plot, ptime, psignal, xmargin=xm, ymargin=ym, $
      xtitle=xtitle1, ytitle=ytitle, title=fileshort

if (isQuad ne 0) then begin
  ym2 = [3,0.5]
  plot, ptime, plotdata.quadx, /nodata, yrange=[-1,1], ystyle=1, xmargin=xm, ymargin=ym2, $
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
    oplot, ptime, plotdata.quadx, color=cc[0]  ; red
    oplot, ptime, plotdata.quady, color=cc[3]  ; green
    xyouts, xx, yy, 'X Rel. Pos.', color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy, 'Y Rel. Pos.', color=cc[3], charsize=cs, charthick=ct
  endelse
endif

if (ch eq 'PS') then begin
	; overplot all channels
	xx = !x.crange[0]*0.9 + !x.crange[1]*0.1
	dy = (!y.crange[1]-!y.crange[0])/18.
	yy = !y.crange[1] - dy*2.
	for k=0,5 do begin
		oplot, ptime, data.picosim_data[k], color=cc[k]
		xyouts, xx, yy-k*dy, strtrim(k+1,2), color=cc[k], charsize=cs
	endfor
endif

;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  if (debug gt 1) then stop, 'STOP: DEBUG at end of plot_picosim.pro...'
endif

end
