;+
; NAME:
;	dualsps_scan_cal
;
; PURPOSE:
;	Analyze TTM scan data for Dual-SPS data from HYDRA TLM file
;
; CATEGORY:
;	TTM calibrations / configuration studies
;
; CALLING SEQUENCE:
;	dualsps_scan_cal, channel, axis, filename, /debug, data=data, plotdata=plotdata]
;
; INPUTS:
;	channel		Channel number can be 1 or 2 for SPS-1 or SPS-2
;	axis		Axis name of X or Y
;	filename	HYDRA telemetry data file from Dual-SPS instrument
;	/debug		Option to print DEBUG messages
;	/edt		Option to convert to Eastern Daylight Time offset from UT
;	/est		Option to convert to Eastern Standard Time offset from UT
;
; OUTPUTS:
;	PLOT		Plot to screen the SPS response during X or Y scan of TTM
;
;	data		Optional output to pass the data from the HYDRA data file
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
;	8/28/2019	Tom Woods	Original based on dualsps_plot.pro
;+

pro dualsps_scan_cal, filename, channel, axis, debug=debug, $
			data=data, plotdata=plotdata, edt=edt, est=est

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  dualsps_scan_cal, filename, [channel, axis, /debug, data=data, plotdata=plotdata]'
  return
endif

if n_params() lt 2 then channel = 2
chname = strtrim(long(channel),2)
if (chname ne '1') and (chname ne '2') then begin
  ; force to channel 2
  channel = 2
  chname = '2'
endif

if n_params() lt 3 then axis = '?'
axisname = strupcase(axis)

if (n_params() lt 1) then begin
  filename = ''
endif

;
;	2.	Read the HYDRA telemetry data file
;		Also make a short version of filename for plot title
;
data = dualsps_read_file( filename, debug=debug, /verbose )  ;  add messages=msg to call for Messages
if (n_elements(data) lt 2) then begin
  print, 'ERROR dualsps_scan_cal: No valid data found for ', filename
  return
endif

pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

if keyword_set(debug) then print, 'HYDRA file = ', fileshort

;  check for Axis Data
if (axisname ne 'X') and (axisname ne 'Y') then begin
  ; find if there are any Scan data
  wgdx = where( data.ttm_state eq 'ScX', numx )
  wgdy = where( data.ttm_state eq 'ScY', numy )
  if (numx lt 2) and (numy lt 2) then begin
  	print, 'ERROR dualsps_scan_cal: Invalid Axis name. Expect X or Y.'
  	return
  endif
  if (numx gt numy) then begin
  	axis = 'X'
  endif else begin
  	axis = 'Y'
  endelse
  axisname = axis
endif

;
;	3.  Make the "plotdata" (ttm_data versus sps_data)
;		time = Seconds of Day (SOD)
;		channel = channel name
;		signal = signal for selected channel
;		signal_per_mA = signal / surfbc if surffile is given
;		quadx, quady = Quad diode calculation
;
tempdata = { time: 0.0D0, channel: 'xx', axis: 'xx', ttm_data: 0.0, $
			quadsum: 0.0, quadx: 0.0, quady: 0.0, ttm_x: 0.0, ttm_y: 0.0  }
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

;  store Channel name and Axis name
plotdata.channel = chname
plotdata.axis = axisname

;  store Channel signal
if (chname eq '1') then begin
  sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.quadsum = data.sps1_quad_sum
  plotdata.quadx = data.sps1_quad_x
  plotdata.quady = data.sps1_quad_y
  wgood = where( data.have_sps1 eq 1, numgood )
endif else if (chname eq '2') then begin
   sdark = 16450.	; quad diode dark signal
  ; sdark = min(data.sps_data)
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
  plotdata.quadsum = data.sps2_quad_sum
  plotdata.quadx = data.sps2_quad_x
  plotdata.quady = data.sps2_quad_y
  wgood = where( data.have_sps2 eq 1, numgood )
endif else begin
  print, 'ERROR dualsps_scan_cal: Invalid Channel number. Expect 1 or 2.'
  return
endelse

; reduce plotdata to the GOOD data
if (numgood lt 2) then begin
	print, 'ERROR dualsps_scan_cal: no good SPS data found for channel ', chname
	return
endif
print, 'dualsps_scan_cal: reduced SPS data set to ', strtrim(numgood,2), ' elements.'
plotdata = plotdata[wgood]
num_data = numgood

plotdata.ttm_x = data.ttm_x_position_dn
plotdata.ttm_y = data.ttm_y_position_dn

if (axisname eq 'X') then begin
  plotdata.ttm_data = data.ttm_x_position_dn
  wgood = where( (data.have_ttm eq 1) and (data.ttm_state eq 'ScX'), numgood )
endif else if (axisname eq 'Y') then begin
  plotdata.ttm_data = data.ttm_y_position_dn
  wgood = where( (data.have_ttm eq 1) and (data.ttm_state eq 'ScY'), numgood )
endif else begin
  print, 'ERROR dualsps_scan_cal: Invalid Channel number. Expect 1 or 2.'
  return
endelse

; reduce plotdata to the GOOD data
if (numgood lt 2) then begin
	print, 'ERROR dualsps_scan_cal: no good TTM Scan data found for axis ', axisname
	return
endif
; print, 'dualsps_scan_cal: reduced SPS/TTM data set to ', strtrim(numgood,2), ' elements.'
plotdata = plotdata[wgood]
num_data = numgood

;  only use data that has same TTM position as previous position (that is, not moving)
adata = plotdata
ttm_diff = (shift(adata.ttm_data,-1) - shift(adata.ttm_data,1))
wkeep = where( (adata.ttm_data gt 0) and (ttm_diff eq 0), numkeep )
if (numkeep lt 2) then begin
	print, 'ERROR dualsps_scan_cal: not enough TTM stable data points'
	return
endif
print, 'dualsps_scan_cal: reduced SPS/TTM data set to ', strtrim(numkeep,2), ' elements.'
plotdata = plotdata[wkeep]

; stop, 'DEBUG dualsps_scan_cal before doing plot ...'

;
;	4.  Plot the Scan Data
;
setplot
cc = rainbow(7)
cs = 1.8
ct = 1.5

xtitle = 'TTM ' + axisname + ' Scan'
ytitle = 'SPS ' + chname

; plot scan data of TTM data versus SPS X & Y data
yrange = [ min([plotdata.quadx,plotdata.quady]), $
			max([plotdata.quadx,plotdata.quady]) ]

plot, plotdata.ttm_data, plotdata.quadx, psym=4, $
		xrange=[0, 17000.], xstyle=1, yrange=yrange, ystyle=1, $
		xtitle=xtitle, ytitle=ytitle, title=fileshort
oplot, plotdata.ttm_data, plotdata.quady, psym=5, color=cc[3]

ans=' '
read, 'Next plot ? ', ans

; plot time series of scans
tbase = long(plotdata[0].time/1000.) * 1000L
ptime = plotdata.time - tbase
xtitle2 = 'Time (SOD'
if (tbase ne 0) then xtitle2=xtitle2+'-'+strtrim(tbase,2)+')' else xtitle=xtitle+')'

plot, ptime, plotdata.quadx, psym=4, $
		xstyle=1, yrange=yrange, ystyle=1, $
		xtitle=xtitle2, ytitle=ytitle, title=fileshort
oplot, ptime, plotdata.quady, psym=5, color=cc[3]

; restrict time range for doing the best fits
read, 'Do you want to restrict the time range for the Scan calibration ? ', ans
ans = strupcase(strmid(ans,0,1))
if (ans eq 'Y') then begin
	read, 'Place your cursor over the Starting Time in the plot and hit RETURN key...',ans
	cursor, x1, y1, /nowait
	oplot, x1*[1,1], !y.crange, line=2
	read, 'Place your cursor over the Ending Time in the plot and hit RETURN key...',ans
	cursor, x2, y2, /nowait
	trange = [x1, x2]
	oplot, x2*[1,1], !y.crange, line=2
endif else begin
	trange = [ min(ptime), max(ptime) ]
endelse

read, 'Next plot ? ', ans
;
;  do data analysis (linear fit)
;
wfit = where( (ptime ge trange[0]) and (ptime le trange[1]), numfit)
if (numfit gt 3) then begin
	print, ' '
	cxfit = poly_fit( plotdata[wfit].ttm_data, plotdata[wfit].quadx, 1 )
	print, 'FIT for SPS X: ' + strtrim(cxfit[0],2) + "  +  " + $
			strtrim(cxfit[1],2) + "  *  TTM_" + axisname
	cyfit = poly_fit( plotdata[wfit].ttm_data, plotdata[wfit].quady, 1 )
	print, 'FIT for SPS Y: ' + strtrim(cyfit[0],2) + "  +  " + $
			strtrim(cyfit[1],2) + "  *  TTM_" + axisname
	range_ttm = max(plotdata[wfit].ttm_data) - min(plotdata[wfit].ttm_data)
	range_sps_x = max(plotdata[wfit].quadx) - min(plotdata[wfit].quadx)
	range_sps_y = max(plotdata[wfit].quady) - min(plotdata[wfit].quady)
	print, 'Ranges of TTM, Quad-X, Quad-Y: ',range_ttm, range_sps_x, range_sps_y
	; S-330 PZT conversion factors:  (14-bit DN / 100 V) * (100 V/ 2 mrad)
	S330_FACTOR = ((2.^14) / 100.) * 0.2424  ;  (DN/V) * (V/arcsec)
	print, 'S-330 PZT: X FOV (arcsec) = ', (range_ttm/S330_FACTOR) / range_sps_x
	print, 'S-330 PZT: Y FOV (arcsec) = ', (range_ttm/S330_FACTOR) / range_sps_y
	print, ' '
	;  make line for over plotting
	ttm_fit = findgen(101)*16535./100.
	xfit = cxfit[0] + cxfit[1] * ttm_fit
	yfit = cyfit[0] + cyfit[1] * ttm_fit
endif else begin
	print, 'ERROR: dualsps_scan_cal:  not enough data points to fit scan data.'
	return
endelse

;
;	do plot with fit
;
plot, plotdata.ttm_data, plotdata.quadx, /nodata, psym=4, $
		xrange=[0, 17000.], xstyle=1, yrange=yrange, ystyle=1, $
		xtitle=xtitle, ytitle=ytitle, title=fileshort

oplot, plotdata[wfit].ttm_data, plotdata[wfit].quadx, psym=4, color=cc[0]
oplot, ttm_fit, xfit, line=2, color=cc[0]
xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
yy = !y.crange[0] * 0.1 + !y.crange[1] * 0.9
dy = (!y.crange[1] - !y.crange[0]) / 10.
xyouts, xx, yy, 'SPS-X', color=cc[0]

oplot, plotdata[wfit].ttm_data, plotdata[wfit].quady, psym=5, color=cc[3]
oplot, ttm_fit, yfit, line=2, color=cc[3]
xyouts, xx, yy-dy, 'SPS-Y', color=cc[3]

;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  stop, 'STOP: DEBUG at end of dualsps_scan_cal.pro...'
endif

end
