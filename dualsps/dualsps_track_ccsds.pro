;+
; NAME:
;	dualsps_track_ccsds
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
;	/channel		Channel names can be 'SPS', 'SPS_X', 'SPS_Y', 'SPS_1' ... 'SPS_4'
;	/debug		Option to print DEBUG messages0..
;	/xrange		Option to limit time range in plot
;	/openloop	Option to allow non-track data to be plotted
;	/nostat		Option to not print stat data on the plot
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
;	10/29/2020	Tom Woods	Updated to read 2020 CCSDS formatted file
;+

pro dualsps_track_ccsds, filename, channel=channel, debug=debug, $
			data=data, plotdata=plotdata, xrange=xrange, openloop=openloop, nostat=nostat

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  dualsps_track_ccsds, filename, channel=channel, /debug, /nostat, /openloop, $'
  print, '                        xrange=xrange, data=data, plotdata=plotdata'
  return
endif

if not keyword_set(channel) then channel = 'SPS'
ch = strupcase(channel)
if (ch ne 'SPS') and (ch ne 'SPS_X') and (ch ne 'SPS_Y') $
	and (ch ne 'SPS_1') and (ch ne 'SPS_2') and (ch ne 'SPS_3') and (ch ne 'SPS_4') $
then begin
  print, 'ERROR dualsps_track_ccsds: Invalid Channel name.  Expected SPS, SPS_X, SPS_Y, SPS_1-SPS_4.'
  return
ENDIF

if (n_params() lt 1) then begin
  filename = ''
endif

;
;	2.	Read the HYDRA telemetry data file
;		Also make a short version of filename for plot title
;
data = dualsps_read_file_ccsds( filename, messages=messages, /verbose ) ; debug=debug,
if (n_elements(data) lt 2) then begin
  print, 'ERROR dualsps_track_ccsds: No valid data found for ', filename
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

;  convert file time into seconds since data set started
sod = (data.jd - long(median(data.jd))) * 24.*3600.D0
tzero = sod[0]
tzsod = sod - tzero
plotdata.time = tzsod

;  store Channel name
plotdata.channel = ch

wgood = where( data.ttm_state ge 1, numgood )
if keyword_set(openloop) then wgood = where( data.ttm_state ge 0, numgood )


;  store Channel signal
if (ch eq 'SPS') then begin
	ptype = 4
	isQuad = 1
	sdark = 16450.	; quad diode dark signal
	; sdark = min(data.sps_data)
	quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
    plotdata.signal = data.sps_quad_sum
endif else if (ch eq 'SPS_X') then begin
	ptype = 4
	isQuad = 1
	sdark = 16450.	; quad diode dark signal
	; sdark = min(data.sps_data)
	quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
    plotdata.signal = data.sps_quad_x
endif else if (ch eq 'SPS_Y') then begin
	ptype = 4
	isQuad = 1
	sdark = 16450.	; quad diode dark signal
	; sdark = min(data.sps_data)
	quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
    plotdata.signal = data.sps_quad_y
endif else if (ch eq 'SPS_1') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps_diode_data[0]
endif else if (ch eq 'SPS_2') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps_diode_data[1]
endif else if (ch eq 'SPS_3') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps_diode_data[2]
endif else if (ch eq 'SPS_4') then begin
  ptype = 5
  isQuad = 0
  sdark = 16450.	; quad diode dark signal
  darkFactor = 1.00
  plotdata.signal = data.sps_diode_data[3]
endif

; reduce plotdata to the GOOD data
if (numgood lt 2) then begin
	print, 'ERROR dualsps_track_ccsds: no good SPS data found with TTM in tracking mode'
	if keyword_set(debug) then stop, 'DEBUG data ...'
	return
endif
print, 'dualsps_track_ccsds: reduced SPS data set to ', strtrim(numgood,2), ' elements.'
datagd = data[wgood]
plotdata = plotdata[wgood]
num_data = numgood

;
;  fill in the other plotdata points
;
plotdata.control_x = datagd.ttm_x_control_asec
plotdata.control_y = datagd.ttm_y_control_asec
plotdata.pzt_x = datagd.ttm_x_position_dn
plotdata.pzt_y = datagd.ttm_y_position_dn

;
;	If Quad, then calculate Quad X & Y values and also diagonal Quad values for Yaw and Pitch scans
;	These are unitless with range of -1 to 1.
;	To convert to degrees, then multiply by FOV for SPS.
;
doPrint = 0
if (isQuad ne 0) then begin
  quadsignal = fltarr(4,num_data)
  for j=0,3 do begin
    fscale = float(quadDarkFactor[j])
    quadsignal[j,*] = reform(datagd.sps_diode_data[j]) - sdark * fscale
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
  if (ch eq 'SPS') then begin
  	;  replace with TM values for Quad X and Y
  	plotdata.quadx = datagd.sps_quad_x
  	plotdata.quady = datagd.sps_quad_y
  	doPrint = 1
  endif
endif

ptime = plotdata.time
xtitle = 'Time (sec)'

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
	if (ch eq 'SPS') then print, '     Note that SPS X -> PZT Y and SPS Y -> PZT X'
	print, ' '
	if keyword_set(openloop) then begin
		print, 'Open Loop Results after removing running smooth of 3 sec'
		diff_x = plotdata.control_x - smooth(plotdata.control_x,151,/edge_trun)
		diff_y = plotdata.control_y - smooth(plotdata.control_y,151,/edge_trun)
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
yrange = [0,17000]  ; GEN-1
yrange = [0,4100]	; GEN-3
psignal = plotdata.signal

; plot time series of PZT
plot, ptime, plotdata.pzt_x, /nodata, xmargin=xm, ymargin=ym, yr=yrange, ystyle=1,  $
      xrange=xrange, xs=1, xtitle=xtitle1, ytitle=ytitle, title=fileshort
oplot, ptime, plotdata.pzt_x, psym=10, color=cc[3]
oplot, ptime, plotdata.pzt_y, psym=10, color=cc[0]
xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
dy = (!y.crange[1] - !y.crange[0])/8.
yy = !y.crange[1] - dy*1.2
if not keyword_set(nostat) then begin
  xyouts, xx, yy, 'TTM X '+string(median(plotdata.pzt_x),format='(F8.1)') $
    	+' +/- '+string(stddev(plotdata.pzt_x),format='(F7.2)'), color=cc[3], charsize=cs, charthick=ct
  xyouts, xx, yy-dy, 'TTM Y '+string(median(plotdata.pzt_y),format='(F8.1)') $
    	+' +/- '+string(stddev(plotdata.pzt_y),format='(F7.2)'), color=cc[0], charsize=cs, charthick=ct
endif

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
  if not keyword_set(nostat) then begin
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
  ;	extra plot of data to examine time lags of filtered SPS position (control) and raw SPS data
  ;
  if ((xrange[1]-xrange[0]) le 10) and (xrange[1] ne 0) then BEGIN
  	SPS_X_FOV_DEFAULT = 1151.0   ; TTM GONG Calibration on 8/31/19
  	SPS_Y_FOV_DEFAULT = 1780.0   ; TTM GONG Calibration on 8/31/19
  	oplot, ptime, plotdata.quadx * SPS_X_FOV_DEFAULT
  	oplot, ptime, plotdata.quady * SPS_Y_FOV_DEFAULT
  ENDIF

endif

;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  if (debug ge 1) then stop, 'STOP: DEBUG at end of dualsps_track_ccsds.pro...'
endif

data = datagd   ; return
end
