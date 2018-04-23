;+
; NAME:
;	plotxrs
;
; PURPOSE:
;	Do quick time series plot of XRS data
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:  
;	plotxrs, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, quaddata=quaddata]
;
; INPUTS:
;	channel		Channel names can be  'A1', 'A2', 'B1', or 'B2'
;	filename	DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
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
;  11/30/10    Andrew Jones  Changed the idark reference for A1 from 1 to 0
;                            Changed the darkFactors based on the data from
;                            XRS Raw Dump_11_30_10_10-24 
;+

pro plotxrs, channel, filename, surffile, itime=itime, debug=debug, $
			data=data, surfdata=surfdata, quaddata=quaddata

;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  plotxrs, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, quaddata=quaddata]'
  return
endif
use_new_surfer =1 ; Use this for Sep and Nov 2010
;  NOTE:  Dark Factors below are for R-XRS in Jan 2010 at 20 C (SURF Cal)

ch = strmid(strupcase(channel),0,2)
if (ch eq 'B1') then begin
  ptype = 2
  isQuad = 0
  isignal = 4
  idark = 5
;  darkFactor= 0.3129
  darkFactor = 0.7559 ; arj 11/30/2010
endif else if (ch eq 'B2') then begin
  ptype = 1
  isQuad = 1
  isignal = 1
  idark = 0
;  quadDarkFactor =[ 0.9392, 0.8662, 0.8773, 0.9041 ]
  quadDarkFactor = [ 0.9657, 0.8946, 0.9062, 0.9394 ]; arj 11/30/2010
endif else if (ch eq 'A1') then begin
  ptype = 1
  isQuad = 0
  isignal = 5
  idark = 0 ; was 1 fixed? arj 10/29/2010
;  darkFactor = 1.0092
   darkFactor = 1.0046 ; arj 11/30/2010
endif else if (ch eq 'A2') then begin
  ptype = 2
  isQuad = 1
  isignal = 0
  idark = 5
; quadDarkFactor = [ 0.3310, 0.3068, 0.3335, 0.3086 ]
  quadDarkFactor = [ 0.7409, 0.6812, 0.7452, 0.6876 ]
endif else begin
  print, 'ERROR plotxrs: Invalid Channel name.  Expected A1, A2, B1, or B2.'
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
if keyword_set( debug ) then  alldata = read_rxrs( filename, /debug ) $
else  alldata = read_rxrs( filename )
if (n_elements(alldata) lt 2) then begin
  print, 'ERROR plotxrs: No valid data found for ', filename
  return
endif

pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

if keyword_set(debug) then print, 'DataView file = ', fileshort

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
	
wgd=where(alldata.type eq ptype and alldata.value[0] gt 0, numgd)	
if (numgd lt 2) then begin
  print, 'ERROR plotxrs: not enough data packets for channel ', ch
  return
endif
data = replicate( tempdata, numgd )

;  convert file time (GPS seconds) into seconds of day (SOD)
;  also convert from UT to EST to be consistent with SURFER time
utoffset = 5. * 3600.D0
ydfulltime = jd2yd(gps2jd(alldata[wgd].time - utoffset))
ydtime = long(ydfulltime)
data.time = (ydfulltime-ydtime) * 24.D0 * 3600.

if keyword_set(debug) then print, 'DataView Date = ', strtrim(ydtime[0],2)

;  store Channel name
data.channel = ch

;  extract out dark diode count
data.rawdark = alldata[wgd].raw[idark]

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
    data.rawcnt = data.rawcnt + alldata[wgd].raw[isignal+j]
    fscale = float(quadDarkFactor[j])
    quadcnt[j,*] = (alldata[wgd].raw[isignal+j] - data.rawdark * fscale) > 1.
    data.cnt = data.cnt + reform(quadcnt[j,*])
    quadsignal[j,*] = quadcnt[j,*] * gain[isignal+j]
    data.signal = data.signal + reform(quadsignal[j,*])
    ; also save this into "quaddata" structure
    quaddata.rawcnt[j] = alldata[wgd].raw[isignal+j]
    quaddata.cnt[j] = reform(quadcnt[j,*]) / integtime
    quaddata.signal[j] = reform(quadsignal[j,*]) / integtime
  endfor
  data.quadx = reform(((quadsignal[1,*]+quadsignal[2,*]) - (quadsignal[0,*]+quadsignal[3,*])))/data.signal
  data.quady = reform(((quadsignal[0,*]+quadsignal[1,*]) - (quadsignal[2,*]+quadsignal[3,*])))/data.signal
  data.quad13 = reform((quadsignal[2,*]-quadsignal[0,*]) / (quadsignal[0,*]+quadsignal[2,*]))
  data.quad24 = reform((quadsignal[3,*]-quadsignal[1,*]) / (quadsignal[1,*]+quadsignal[3,*]))
endif else begin
  ;  simple AXUV-100 (no quad)
  data.rawcnt = alldata[wgd].raw[isignal]
  data.cnt = (data.rawcnt - data.rawdark * darkFactor) > 1.
  data.signal = data.cnt * gain[isignal]
endelse

;  fold in integration time
data.cnt = data.cnt / integtime
data.signal = data.signal / integtime

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
    print, 'plotxrs: First XRS time  = ', strtrim(data[0].time,2)
    print, 'plotxrs: First SURF time = ', strtrim(surfdata[0,0],2)
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
  smoothbc = smooth(surfdata[isurfbc,*],3,/edge)
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

; plot time series of "cnt"
plot, ptime, data.cnt, xmargin=xm, ymargin=ym, $
      xtitle=xtitle1, ytitle='XRS ' + ch, title=fileshort
oplot, ptime, data.rawdark/integtime, line=2

if (isQuad ne 0) then begin
  ym2 = [3,0.5]
  plot, ptime, data.quadx, /nodata, yrange=[-1,1], ystyle=1, xmargin=xm, ymargin=ym2, $
      xtitle=xtitle, ytitle='Quad Position', title=" "
  xx = !x.crange[0] * 0.9 + !x.crange[1] * 0.1
  yy = 0.75
  dy = 0.25
  if (doSURF ne 0) then begin
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

if keyword_set(debug) then begin
  if (debug gt 1) then stop, 'STOP: DEBUG at end of plotxrs.pro...'
endif

;
;	clean up to exit
;
!p.multi = 0

end
