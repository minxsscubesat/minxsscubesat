;+
; NAME:
;	plot_rxrs_hydra
;
; PURPOSE:
;	Do quick time series plot of Rocket XRS data from HYDRA TLM file
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:
;	plot_rxrs_hydra, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, quaddata=quaddata]
;
; INPUTS:
;	channel		Channel names can be  'A1', 'A2', 'B1', or 'B2'
;				   and 2018 addition:  'X123', 'SPS', and 'PSx' where x=1-6
;	filename	DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;	/est		Option to convert to Eastern Standard Time instead of EDT (default)
;	/quad45		Option to plot Quad13 and Quad24 instead of QuadX and QuadY (as needed at SURF)
;
; OUTPUTS:
;	PLOT		Plot to screen the time series of specified channel
;				Plot is normalized to SURF beam current if given surffile
;
;	data		Optional output to pass the data plotted back to user
;	surfdata	Optional output to pass the SURFER PC log data
;   quaddata	Optional output to pass the quad data (count & signal)
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.	Read the DataView dump file
;	3.	Read the SURFER log file (option)
;	4.  Make the "data" (time, counts or counts/mA)
;	5.  Plot the "data"
;
; MODIFICATION HISTORY:
;	1/19/10		Tom Woods	Original file creation
;	1/26/10		Tom Woods	Added Gain correction to data
; 11/30/10  Andrew Jones  Changed the idark reference for A1 from 1 to 0
;                         Changed the darkFactors based on the data from
;                         XRS Raw Dump_11_30_10_10-24
;	3/24/2018	Tom Woods	Updated for HYDRA pakcets for rocket XRS-X123-SPS
;+

pro plot_rxrs_hydra, channel, filename, surffile, itime=itime, debug=debug, $
			data=data, surfdata=surfdata, quaddata=quaddata, est=est, $
			quad45=quad45

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  plot_rxrs_hydra, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, quaddata=quaddata]'
  return
endif
use_new_surfer =1 ; Use this for Sep and Nov 2010
;  NOTE:  Dark Factors below are for R-XRS in Jan 2010 at 20 C (SURF Cal)

ch = strupcase(channel)
if (ch eq 'B1') then begin
  ptype = 2
  isQuad = 0
  isignal = 1
  idark = 10
;  darkFactor= 0.3129
;  darkFactor = 0.7559 ; arj 11/30/2010
  darkFactor = 1.2376 ; tnw 3/27/2018
endif else if (ch eq 'B2') then begin
  ptype = 1
  isQuad = 1
  isignal = 6
  idark = 10
;  quadDarkFactor =[ 0.9392, 0.8662, 0.8773, 0.9041 ]
;  quadDarkFactor = [ 0.9657, 0.8946, 0.9062, 0.9394 ]; arj 11/30/2010
  quadDarkFactor = [ 0.286, 2.617, 0.467, 1.711 ]; tnw 3/27/2018
endif else if (ch eq 'A1') then begin
  ptype = 1
  isQuad = 0
  isignal = 0
  idark = 10 ; was 1 fixed? arj 10/29/2010
;  darkFactor = 1.0092
;  darkFactor = 1.0046 ; arj 11/30/2010
  darkFactor = 2.0209 ; tnw 3/27/2018
endif else if (ch eq 'A2') then begin
  ptype = 2
  isQuad = 1
  isignal = 2
  idark = 10
; quadDarkFactor = [ 0.3310, 0.3068, 0.3335, 0.3086 ]
;  quadDarkFactor = [ 0.7409, 0.6812, 0.7452, 0.6876 ]
  quadDarkFactor = [ 0.057, 0.004, 0.072, 0.036 ]; tnw 3/27/2018
endif else if (ch eq 'X123') then begin
  ptype = 3
  isQuad = 0
  isignal = 12
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'X123_FAST') then begin
  ptype = 3
  isQuad = 0
  isignal = 13
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'SPS') then begin
  ptype = 4
  isQuad = 1
  isignal = 6
  idark = -1
  sdark = 27961.0
  quadDarkFactor = [ 1.0, 1.0, 1.0, 1.0 ]
endif else if (ch eq 'PS1') then begin
  ptype = 5
  isQuad = 0
  isignal = 0
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'PS2') then begin
  ptype = 5
  isQuad = 0
  isignal = 1
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'PS3') then begin
  ptype = 5
  isQuad = 0
  isignal = 2
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'PS4') then begin
  ptype = 5
  isQuad = 0
  idark = -1
  isignal = 3
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'PS5') then begin
  ptype = 5
  isQuad = 0
  isignal = 4
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else if (ch eq 'PS6') then begin
  ptype = 5
  isQuad = 0
  isignal = 5
  idark = -1
  sdark = 0.0
  darkFactor = 1.00
endif else begin
  print, 'ERROR plot_rxrs_hydra: Invalid Channel name.  Expected A1, A2, B1, B2, X123, SPS, or PS1-PS6.'
  return
endelse

if (n_params() lt 2) then begin
  filename = ''
endif

if (n_params() lt 3) then doSURF = 0 else doSURF = 1

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

;
;	2.	Read the DataView dump file
;		Also make a short version of filename for plot title
;
if keyword_set( debug ) then begin
	read_hydra_rxrs, filename, /verbose, hk=hk, sci=sci, sps=sps
endif else begin
	read_hydra_rxrs, filename, /verbose, hk=hk, sci=sci, sps=sps
endelse
if (n_elements(sci) lt 2) then begin
  print, 'ERROR plot_rxrs_hydra: No valid data found for ', filename
  return
endif
;  make alldata[] array like read_rxrs.pro
; tempdata = { time: 0.D0, type: 0, raw: lonarr(MAX_NUM), value: fltarr(MAX_NUM) }
if (ptype le 3) then begin
	; use the SCI packets for XRS and X123 data
	MAX_NUM = 14
	tempdata1 = { time: 0.D0, type: 0, value: fltarr(MAX_NUM) }
	alldata = replicate(tempdata1,n_elements(sci))
	alldata.time = sci.time
	alldata.type = ptype
	;  convert XRS and X123 data into counts per sec
	;	XRS-A1, B1, A2[4], B2[4], Dark1, Dark2, X123_Slow, X123_Fast
	alldata.value[0] = sci.xps_data2 / (sci.sps_xps_count > 1.)
	alldata.value[1] = sci.xps_data / (sci.sps_xps_count > 1.)
	for ii=0,3 do alldata.value[2+ii] = sci.sps_data[ii] / (sci.sps_xps_count > 1.)
	for ii=0,3 do alldata.value[6+ii] = sci.sps_data2[ii] / (sci.sps_xps_count > 1.)
	alldata.value[10] = sci.dark_data / (sci.sps_xps_count  > 1.)
	alldata.value[11] = sci.dark_data2 / (sci.sps_xps_count > 1.)
	alldata.value[12] = sci.x123_slow_count / (sci.X123_ACCUM_TIME/1000. > 0.1)
	alldata.value[13] = sci.x123_fast_count / (sci.X123_ACCUM_TIME/1000. > 0.1)
endif else begin
	; use the SPS packets for SPS and PicoSIM data
	MAX_NUM = 13
	tempdata1 = { time: 0.D0, type: 0, vis_nir_type: 0, value: fltarr(MAX_NUM) }
	alldata = replicate(tempdata1,n_elements(sps))
	alldata.time = sps.time
	alldata.type = 4
	alldata.vis_nir_type = sps.vis_nir_type
	for ii=0,3 do alldata.value[6+ii] = sps.sps_qd_signal[ii]
	alldata.value[10] = sps.sps_qd_sum
	alldata.value[11] = sps.sps_qd_x
	alldata.value[12] = sps.sps_qd_y
	for ii=0,5 do alldata.value[ii] = sps.vis_nir_signal[ii]
endelse

pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

if keyword_set(debug) then print, 'HYDRA file = ', fileshort

;
;	3.	Read the SURFER log file (option) --old arj
;
;**** change this to surferpc_et for Dec2010 onwards
;if (doSURF ne 0) then begin
;   if (use_new_surfer eq 1) then begin
;      if keyword_set(debug) then  surfdata = read_surflog_et( surffile, /debug ) $
;      else  surfdata = read_surflog_et( surffile )
;   endif else begin
;      if keyword_set(debug) then  surfdata = read_surferpc( surffile, /debug ) $
;      else  surfdata = read_surferpc( surffile )
;   endelse
;
;  isurftime = 0
;  isurfx = 1
;  isurfy = 2
;  isurfu = 3
;  isurfv = 4
;  isurfbc = 5
;  pslash = strpos( surffile, '/', /reverse_search )
;  if (pslash gt 0) then surfshort = strmid( surffile, pslash+1, strlen(surffile)-pslash-1) $
;  else surfshort = surffile
;  if keyword_set(debug) then print, 'SURF file = ', surfshort
;endif
;
;	3.	Read the SURFER log file (option)
;
if (doSURF ne 0) then begin
  if keyword_set(debug) then  surfdata = read_surflog_et( surffile, /debug ) $
  else  surfdata = read_surflog_et( surffile )
  isurftime = 0
  isurfx = 1
  isurfy = 2
  isurfu = 3
  isurfv = 4
  isurfbc = 5
  isurfenergy = 6
  isurfsize = 7
  pslash = strpos( surffile, '/', /reverse_search )
  if (pslash gt 0) then surfshort = strmid( surffile, pslash+1, strlen(surffile)-pslash-1) $
  else surfshort = surffile
  if keyword_set(debug) then print, 'SURF file = ', surfshort
endif

;
;	4.  Make the "data" (time, counts/sec or counts/sec/mA)
;		time = Seconds of Day (SOD)
;		channel = channel name
;		rawcnt = raw counts (DN) [total for Quad]
;		rawdark = raw dark diode counts (DN)
;		bc = Beam Current (mA)
;		cnt = counts/sec or counts/sec/mA if surffile is given
;		signal = fA/sec or fA/sec/mA if surffile is given
;		quadx, quady = Quad diode calculation
;
;tempdata = { time: 0.0, channel: 'xx', rawcnt: 0.0, rawdark: 0.0, cnt: 0.0, signal: 0.0, $
;			quadx: 0.0, quady: 0.0, quad13: 0.0, quad24: 0.0, $
;			surfbc: 0.0D0, surfx: 0.0, surfy: 0.0, surfu: 0.0, surfv: 0.0  }
;
;tempquad = { time: 0.0, channel: 'xx', surfbc: 0.0D0, $
;			rawcnt: fltarr(4), cnt: fltarr(4), signal: fltarr(4) }
;quaddata = -1
tempdata = { time: 0.0, channel: 'xx', temp1: 0.0, temp2: 0.0, rawcnt: 0.0, rawdark: 0.0, cnt: 0.0, signal: 0.0, $
			quadx: 0.0, quady: 0.0, quad13: 0.0, quad24: 0.0, $
			surfbc: 0.0D0, surfx: 0.0, surfy: 0.0, surfu: 0.0, surfv: 0.0, $
			surfenergy: 0.0, surfsize: 0.0  }

tempquad = { time: 0.0, channel: 'xx', surfbc: 0.0D0, $
			rawcnt: fltarr(4), cnt: fltarr(4), signal: fltarr(4) }
quaddata = -1

;
;	define GAIN values for rocket XRS  (gain == fA/ (count/sec) )
;
gaina = [ 6.0982, 6.1403, 6.4611, 7.7942, 6.1598, 5.9589 ]
gainb = [ 5.7313, 5.3794, 5.5627, 5.3828, 5.2651, 6.1227 ]
if (ptype eq 1) then gain = gaina else gain = gainb
gain = [ gaina, gainb ]
; these need to be updated for 2018 Rocket XRS format
; SEE Worksheet "Slit Coordinates" for the ASIC - channel definitions for GOES-R XRS
; The gaina and gainb values are re-arranged so new data array goes as A1, B1, A2-QD, B2-QD, Dark1, Dark2
gain = [ gaina[5], gainb[4], gainb[0], gainb[1], gainb[2], gainb[3], gaina[1], gaina[2], gaina[3], gaina[4], gaina[0], gainb[5] ]

wgd=where(alldata.value[isignal] ge 0, numgd)
if (numgd lt 2) then begin
  print, 'ERROR plot_hydra_xrs: not enough data packets for channel ', ch
  return
endif
data = replicate( tempdata, numgd )

;  convert file time (GPS seconds) into seconds of day (SOD)
;  convert from UT to EDT to be consistent with SURFER time
utoffset = 4. * 3600.D0
; special check for EST instead of default EDT
if keyword_set(est) then utoffset = 5. * 3600.D0

ydfulltime = jd2yd(gps2jd(alldata[wgd].time - utoffset))
ydtime = long(ydfulltime)
data.time = (ydfulltime-ydtime) * 24.D0 * 3600.

if keyword_set(debug) then print, 'HYDRA Date = ', strtrim(ydtime[0],2)

;  store Channel name
data.channel = ch

;  extract out dark diode count
if (idark ge 0) then data.rawdark = alldata[wgd].value[idark] else data.rawdark = sdark

;
;  extract out signal:  if Quad, then get sum of all signals
;
if (isQuad ne 0) then begin
  data.rawcnt = 0.0
  data.cnt = 0.0
  quadsignal = fltarr(4,numgd)
  quadcnt = fltarr(4,numgd)

  ; create "quaddata" for returning
  quaddata = replicate( tempquad, numgd )
  quaddata.time = data.time
  quaddata.channel = ch

  for j=0,3 do begin
    data.rawcnt = data.rawcnt + alldata[wgd].value[isignal+j]
    fscale = float(quadDarkFactor[j])
    quadcnt[j,*] = (alldata[wgd].value[isignal+j] - data.rawdark * fscale)
    if (ptype eq 4) then quadcnt[j,*] = -1.*quadcnt[j,*] ; invert Signal for PicoSIM SPS quad diode
    data.cnt = data.cnt + reform(quadcnt[j,*])
    if (ptype le 2) then quadsignal[j,*] = quadcnt[j,*] * gain[isignal+j] $
    else quadsignal[j,*] = quadcnt[j,*]   ; gain of 1.0 for SPS
    data.signal = data.signal + reform(quadsignal[j,*])
    ; also save this into "quaddata" structure
    quaddata.rawcnt[j] = alldata[wgd].value[isignal+j]
    quaddata.cnt[j] = reform(quadcnt[j,*])
    quaddata.signal[j] = reform(quadsignal[j,*])
  endfor
  data.quadx = reform(((quadsignal[1,*]+quadsignal[2,*]) - (quadsignal[0,*]+quadsignal[3,*])))/data.signal
  data.quady = reform(((quadsignal[0,*]+quadsignal[1,*]) - (quadsignal[2,*]+quadsignal[3,*])))/data.signal
  data.quad13 = reform((quadsignal[2,*]-quadsignal[0,*]) / (quadsignal[0,*]+quadsignal[2,*]))
  data.quad24 = reform((quadsignal[3,*]-quadsignal[1,*]) / (quadsignal[1,*]+quadsignal[3,*]))
  if (ptype eq 4) then begin
  	; new SPS in PicoSIM already has QD_SUM, QD_X and QD_Y values calculated
  	USE_SPS_ON_BOARD_CALCULATION = 0   ; set to non-zero if want to use on-board SPS X & Y angles
  	if (USE_SPS_ON_BOARD_CALCULATION ne 0) then begin
  	  data.cnt = alldata[wgd].value[isignal+4]
  	  data.signal = alldata[wgd].value[isignal+4]
  	  data.quadx = alldata[wgd].value[isignal+5]
  	  data.quady = alldata[wgd].value[isignal+6]
  	endif
  endif
endif else begin
  ;  simple AXUV-100 (no quad)
  data.rawcnt = alldata[wgd].value[isignal]
  data.cnt = (data.rawcnt - data.rawdark * darkFactor)
  if (ptype le 2) then gainfactor = gain[isignal] else gainfactor = 1.0
  data.signal = data.cnt * gainfactor
endelse

;  fold in integration time:  this is not NEEDED in 2018 version
; data.cnt = data.cnt / integtime
; data.signal = data.signal / integtime

;  normalize counts with beam current (BC) if surffile is given
if (doSURF ne 0) then begin
  ; check on time range for data
  surfmin = min(surfdata[0,*]) - 60	; allow 1-min lapse
  surfmax = max(surfdata[0,*]) + 60  ; allow 1-min lapse
  if (min(data.time) lt surfmin) or (max(data.time) gt surfmax) then begin
    print, 'WARNING: SURFER and DataView Dump Times do not align !!!!!'
    if (min(data.time) lt surfmin) then $
	    print, '      MIN Time difference = ', abs(min(data.time) - surfmin)
    if (max(data.time) gt surfmax) then $
    	print, '      MAX Time difference = ', abs(min(data.time) - surfmin)
    ;  continue anyway !!! ???
    ; if keyword_set(debug) then stop, 'STOP: DEBUG SURFER time...'
  endif
  if keyword_set(debug) then begin
    print, ' '
    print, 'plot_rxrs_hydra: First XRS time  = ', strtrim(data[0].time,2)
    print, 'plot_rxrs_hydra: First SURF time = ', strtrim(surfdata[0,0],2)
    extra_offset = 0.0
    read, 'Enter Offset Time for DataView (sec): ', extra_offset
    data.time = data.time + extra_offset
  endif
;---
;  smoothbc = smooth(surfdata[isurfbc,*],3,/edge)
;  data.surfbc = interpol( smoothbc, surfdata[isurftime,*], data.time )
;  data.cnt = data.cnt / data.surfbc
;  data.signal = data.signal / data.surfbc
;  data.surfx = interpol( surfdata[isurfx,*], surfdata[isurftime,*], data.time )
;  data.surfy = interpol( surfdata[isurfy,*], surfdata[isurftime,*], data.time )
;  data.surfu = interpol( surfdata[isurfu,*], surfdata[isurftime,*], data.time )
;  data.surfv = interpol( surfdata[isurfv,*], surfdata[isurftime,*], data.time )
;---
  smoothbc = smooth(surfdata[isurfbc,*],3,/edge_truncate)
  data.surfbc = interpol( smoothbc, surfdata[isurftime,*], data.time )
  data.cnt = data.cnt / data.surfbc
  data.signal = data.signal / data.surfbc
  data.surfx = interpol( surfdata[isurfx,*], surfdata[isurftime,*], data.time )
  data.surfy = interpol( surfdata[isurfy,*], surfdata[isurftime,*], data.time )
  data.surfu = interpol( surfdata[isurfu,*], surfdata[isurftime,*], data.time )
  data.surfv = interpol( surfdata[isurfv,*], surfdata[isurftime,*], data.time )
  data.surfenergy = interpol( surfdata[isurfenergy,*], surfdata[isurftime,*], data.time )
  data.surfsize = interpol( surfdata[isurfsize,*], surfdata[isurftime,*], data.time )

  if (isQuad ne 0) then begin
    quaddata.surfbc = data.surfbc
    for j=0,3 do begin
      quaddata.cnt[j] = quaddata.cnt[j] / data.surfbc
      quaddata.signal[j] = quaddata.signal[j] / data.surfbc
    endfor
  endif
endif

;
;	5.  Plot the "data"
;		Simple time series for A1 or B1
;		Dual plot for Quad A2 and B2: simple time series and X-Y location
;
setplot
cc = rainbow(7)
cs = 1.8
ct = 1.5

tbase = long(data[0].time/1000.) * 1000L
ptime = data.time - tbase
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

ytitle = ch
if (ptype le 2) then ytitle='XRS ' + ch
if (ptype ge 4) then ytitle='PicoSIM ' + ch

; plot time series of "cnt"
plot, ptime, data.cnt, xmargin=xm, ymargin=ym, $
      xtitle=xtitle1, ytitle=ytitle, title=fileshort
oplot, ptime, data.rawdark/integtime, line=2

if (isQuad ne 0) then begin
  ym2 = [3,0.5]
  plot, ptime, data.quadx, /nodata, yrange=[-1,1], ystyle=1, xmargin=xm, ymargin=ym2, $
      xtitle=xtitle, ytitle='Quad Position', title=" "
  xx = !x.crange[0] * 0.9 + !x.crange[1] * 0.1
  yy = 0.75
  dy = 0.25
  if keyword_set(quad45) then begin
    oplot, ptime, data.quad13, color=cc[0]  ; red
    oplot, ptime, data.quad24, color=cc[3]  ; green
    xyouts, xx, yy, 'Quad13 Rel. Pos.', color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy, 'Quad24 Rel. Pos.', color=cc[3], charsize=cs, charthick=ct
  endif else begin
    oplot, ptime, data.quadx, color=cc[0]  ; red
    oplot, ptime, data.quady, color=cc[3]  ; green
    xyouts, xx, yy, 'X Rel. Pos.', color=cc[0], charsize=cs, charthick=ct
    xyouts, xx, yy-dy, 'Y Rel. Pos.', color=cc[3], charsize=cs, charthick=ct
  endelse
endif

;
;	clean up to exit
;
!p.multi = 0
if keyword_set(debug) then begin
  if (debug gt 1) then stop, 'STOP: DEBUG at end of plot_rxrs_hydra.pro...'
endif

end
