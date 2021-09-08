;+
; NAME:
;	dualsps_track
;
; PURPOSE:
;	Do quick time series plot of Dual-SPS data from HYDRA TLM file for solar tracking with tip-tilt mirror (TTM)
;
; CATEGORY:
;	NSO Magnetograph TTM data analysis
;
; CALLING SEQUENCE:
;	dualsps_track, filename, /debug, channel=channel, data=data, plotdata=plotdata]
;
; INPUTS:
;	filename	HYDRA telemetry data file from Dual-SPS instrument
;	/channel		Channel names can be 'SPS1', 'SPS1_X', 'SPS1_Y', 'SPS1_1' ... 'SPS1_4'
;					and 'SPS2', 'SPS2_X', 'SPS2_Y', 'SPS2_1' ... 'SPS2_4'
;	/debug		Option to print DEBUG messages
;	/edt		Option to convert to Eastern Daylight Time offset from UT
;	/est		Option to convert to Eastern Standard Time offset from UT
;	/xrange		Option to limit time range in plot
;	/openloop	Option to allow non-track data to be plotted
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
;	3.  Make the "data" (time, counts or counts/mA)
;	4.  Plot the "data"
;
; MODIFICATION HISTORY:
;	9/5/2019	Tom Woods	Original based on dualsps_plot.pro
;+

pro dualsps_track, filename, channel=channel, debug=debug, $
			data=data, plotdata=plotdata, edt=edt, est=est, xrange=xrange, openloop=openloop

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  dualsps_track, filename, /debug, channel=channel, data=data, plotdata=plotdata, xrange=xrange'
  return
endif

if not keyword_set(channel) then channel = 'SPS2'
ch = strupcase(channel)
if (ch ne 'SPS1') and (ch ne 'SPS1_X') and (ch ne 'SPS1_Y') $
	and (ch ne 'SPS1_1') and (ch ne 'SPS1_2') and (ch ne 'SPS1_3') and (ch ne 'SPS1_4') $
	and (ch ne 'SPS2') and (ch ne 'SPS2_X') and (ch ne 'SPS2_Y') $
	and (ch ne 'SPS2_1') and (ch ne 'SPS2_2') and (ch ne 'SPS2_3') and (ch ne 'SPS2_4') $
then begin
  print, 'ERROR dualsps_plot: Invalid Channel name.  Expected SPSn, SPSn_X, SPSn_Y, SPSn_1-SPSn_4 for n=1 or 2.'
  return
endif

if (n_params() lt 1) then begin
  filename = ''
endif

;
;	2.	Read the HYDRA telemetry data file
;		Also make a short version of filename for plot title
;
data = dualsps_read_file( filename, debug=debug, /verbose )  ;  add messages=msg to call for Messages
if (n_elements(data) lt 2) then begin
  print, 'ERROR dualsps_track: No valid data found for ', filename
  return
endif

pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

if keyword_set(debug) then print, 'HYDRA file = ', fileshort

;
;	3.  Make the "plotdata" (time, counts/sec or counts/sec/mA)
;		time = Seconds of Day (SOD)
;		channel = channel name
;		signal = signal for selected channel
;		signal_per_mA = signal / surfbc if surffile is given
;		quadx, quady = Quad diode calculation
;
tempdata = { time: 0.0D0, channel: 'xx', signal: 0.0,  $
			quadx: 0.0, quady: 0.0, quadtotal: 0.0, $
			control_x: 0.0, control_y: 0.0, pzt_x: 0.0, pzt_y: 0.0  }

num_data = n_elements( data )
plotdata = replicate( tempdata, num_data )

;  convert file time into seconds of day (SOD)
utoffset = 0.0D0   ; no offset if HYDRA computer setup for UT time (default)
;  convert from EDT to UT be consistent with SURFER time
if keyword_set(edt) then utoffset = 4. * 3600.D0
; special check for EST instead of default EDT
if keyword_set(est) then utoffset = 5. * 3600.D0

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
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_X') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps1_quad_x
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_Y') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps1_quad_y
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_1') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[0]
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_2') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[1]
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_3') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[2]
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS1_4') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps1_data[3]
  wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps1 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps1_data
endif else if (ch eq 'SPS2') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_sum
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_X') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_x
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_Y') then begin
  ptype = 4
  isQuad = 1
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.signal = data.sps2_quad_y
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_1') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[0]
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_2') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[1]
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_3') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[2]
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif else if (ch eq 'SPS2_4') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps2_data[3]
  wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1 and data.ttm_state eq 'ON', numgood )
  if keyword_set(openloop) then wgood = where( data.have_sps2 eq 1 and data.have_ttm eq 1, numgood )
  ch_sps_data = data.sps2_data
endif

; reduce plotdata to the GOOD data
if (numgood lt 2) then begin
	print, 'ERROR dualsps_track: no good SPS data found for channel ', ch
	return
endif
print, 'dualsps_track: reduced SPS data set to ', strtrim(numgood,2), ' elements.'
datagd = data[wgood]
plotdata = plotdata[wgood]
ch_sps_data = ch_sps_data[wgood,*]
num_data = numgood

; us TIMED_SINCE_ON time so have millisec resolution
plotdata.time = datagd.TIME_SINCE_ON

;
;  fill in the other plotdata points
;
plotdata.control_x = datagd.ttm_x_control_asec
plotdata.control_y = datagd.ttm_y_control_asec
plotdata.pzt_x = datagd.ttm_x_position_dn
plotdata.pzt_y = datagd.ttm_y_position_dn

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
  if (min(quadtotal) lt 10) then begin
  	wlow = where(quadtotal lt 10)
  	plotdata[wlow].quadx = 0.0
  	plotdata[wlow].quady = 0.0
  	plotdata[wlow].quad13 = 0.0
  	plotdata[wlow].quad24 = 0.0
  endif
  if (ch eq 'SPS1') then begin
  	;  replace with TM values for Quad X and Y
  	plotdata.quadx = datagd.sps1_quad_x
  	plotdata.quady = datagd.sps1_quad_y
  	doPrint = 1
  endif else if (ch eq 'SPS2') then begin
  	;  replace with TM values for Quad X and Y
  	plotdata.quadx = datagd.sps2_quad_x
  	plotdata.quady = datagd.sps2_quad_y
  	doPrint = 1
  endif
endif

tbase = long(plotdata[0].time/100.) * 100L
ptime = plotdata.time - tbase
xtitle = 'Time (sec'
if (tbase ne 0) then xtitle=xtitle+'-'+strtrim(tbase,2)+')' else xtitle=xtitle+')'

doXlimit = 0
printdata = plotdata

if not keyword_set(xrange) then begin
	xrange=[0,0]
endif else begin
	wlimit = where(ptime ge xrange[0] and ptime le xrange[1],numlimit)
	if (numlimit ge 3) then begin
		printdata = plotdata[wlimit]
		doXlimit = 1
	endif
endelse


if (doPrint ne 0) then begin
	print, ' '
	if (doXlimit ne 0) then begin
		print, 'X-Range Limit is time from ', xrange[0], ' to ', xrange[1], ' sec.'
		print, ' '
	endif
	print, ch, ' Median signal ', median( printdata.signal), ' +/- ', stddev(printdata.signal)
	print, '     Quad X Median ', median( printdata.quadx), ' +/- ', stddev(printdata.quadx)
	print, '     Quad Y Median ', median( printdata.quady), ' +/- ', stddev(printdata.quady)
	print, ' '
	print, '     PZT X Median ', median( printdata.pzt_x), ' +/- ', stddev(printdata.pzt_x)
	print, '     PZT Y Median ', median( printdata.pzt_y), ' +/- ', stddev(printdata.pzt_y)
	print, ' '
	print, '     SPS Control X Median ', median( printdata.control_x), ' +/- ', stddev(printdata.control_x)
	print, '     SPS Control Y Median ', median( printdata.control_y), ' +/- ', stddev(printdata.control_y)
	if (ch eq 'SPS2') then print, '     Note that SPS X -> PZT Y and SPS Y -> PZT X'
	print, ' '
	if keyword_set(openloop) then begin
		print, 'Open Loop Results after removing running smooth of 10 sec'
		diff_x = plotdata.control_x - smooth(plotdata.control_x,51,/edge_trun)
		diff_y = plotdata.control_y - smooth(plotdata.control_y,51,/edge_trun)
		print, '     SPS Control X Jitter ', median( diff_x ), ' +/- ', stddev(diff_x)
		print, '     SPS Control Y Jitter ', median( diff_y ), ' +/- ', stddev(diff_y)
		print, ' '
	endif
endif

;
;	4.  Plot the plotdata.siganl
;		Simple time series for PS1-PS6
;		Dual plot for SPS:  time series and X-Y quad values
;
setplot
cc = rainbow(7)
cs = 1.8
ct = 1.5


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

ytitle = 'PZT Position'
yrange = [0,17000]
psignal = plotdata.signal

; plot time series of PZT
plot, ptime, plotdata.pzt_x, /nodata, xmargin=xm, ymargin=ym, yr=yrange, ystyle=1,  $
      xrange=xrange, xs=1, xtitle=xtitle1, ytitle=ytitle, title=fileshort
oplot, ptime, plotdata.pzt_x, psym=10, color=cc[3]
oplot, ptime, plotdata.pzt_y, psym=10, color=cc[0]
xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
dy = (!y.crange[1] - !y.crange[0])/8.
yy = !y.crange[1] - dy*1.2
xyouts, xx, yy, 'TTM X '+string(median(plotdata.pzt_x),format='(F8.1)') $
    	+' +/- '+string(stddev(plotdata.pzt_x),format='(F7.2)'), color=cc[3], charsize=cs, charthick=ct
xyouts, xx, yy-dy, 'TTM Y '+string(median(plotdata.pzt_y),format='(F8.1)') $
    	+' +/- '+string(stddev(plotdata.pzt_y),format='(F7.2)'), color=cc[0], charsize=cs, charthick=ct

if (isQuad ne 0) then begin
  ym2 = [3,0.5]
  yrange2 = [min([min(plotdata.control_x),min(plotdata.control_y)]), $
  				max([max(plotdata.control_x),max(plotdata.control_y)]) ]
  control_x_median = median(plotdata.control_x)
  control_y_median = median(plotdata.control_y)
  if ((abs(control_x_median) lt 5) and (abs(control_y_median) lt 5)) $
  		and not keyword_set(openloop) then yrange2=[-8,8]
  plot, ptime, plotdata.control_x, /nodata, yrange=yrange2, ystyle=1, xmargin=xm, ymargin=ym2, $
      xrange=xrange, xs=1, xtitle=xtitle, ytitle='SPS Control arc-sec', title=" "
  xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
  dy = (!y.crange[1] - !y.crange[0])/8.
  yy = !y.crange[1] - dy*1.2
  oplot, ptime, plotdata.control_x, psym=10, color=cc[0]  ; red
  oplot, ptime, plotdata.control_y, psym=10, color=cc[3]  ; green
  xyouts, xx, yy, 'SPS X '+string(control_x_median,format='(F8.2)') $
    	+' +/- '+string(stddev(plotdata.control_x),format='(F7.4)'), color=cc[0], charsize=cs, charthick=ct
  xyouts, xx, yy-dy, 'SPS Y '+string(control_x_median,format='(F8.2)') $
    	+' +/- '+string(stddev(plotdata.control_y),format='(F7.4)'), color=cc[3], charsize=cs, charthick=ct
  if keyword_set(openloop) then begin
  	xyouts, xx, yy-dy*2, 'Jitter X '+string(median(diff_x),format='(F8.2)') $
    	+' +/- '+string(stddev(diff_x),format='(F7.4)'), color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy*3, 'Jitter Y '+string(median(diff_y),format='(F8.2)') $
    	+' +/- '+string(stddev(diff_y),format='(F7.4)'), color=cc[3], charsize=cs, charthick=ct
  endif
endif

;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  if (debug ge 1) then stop, 'STOP: DEBUG at end of dualsps_track.pro...'
endif

data = datagd   ; return
end
