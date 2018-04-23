;+
; NAME:
;	rxrs_cruciform
;
; PURPOSE:
;	Analyze Cruciform Data for quad diode angle calibration
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:
;	rxrs_center, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]
;
; INPUTS:
;	channel		Options are  'A2', 'B2' and 'SPS'
;	filename	Hydra Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify integration time (not needed for 2018 data sets)
;	/debug		Option to print DEBUG messages
;	/rocket		Option to use rocket XRS procedures instead of MinXSS XRS procedures
;	/etu		Option to use ETU XRS procedures instead of MinXSS XRS procedures
;
; OUTPUTS:
;	PLOT		Showing scan data and print to screen of centering results
;				Center results include both edge finding and peak value
;
;	data		Hydra Telemetry data
;	surfdata	SURFER PC log data
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Plot the data using plotxrs.pro
;	3.  User selects time range of interest
;	4.  Re-plot and display center results (edges and peak)
;
; MODIFICATION HISTORY:
;	3/28/18		Tom Woods	Code started with rxrs_center.pro for selecting data
;+

pro rxrs_cruciform, channel, filename, surffile, itime=itime, debug=debug, $
						rocket=rocket, etu=etu, fitlimit=fitlimit, $
						data=data, surfdata=surfdata, plotdata=plotdata, $
						quadx=quadx, quady=quady, quad45=quad45
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  rxrs_cruciform, channel, [ filename, surffile, /debug, data=data, surfdata=surfdata]'
  return
endif

ch = strupcase(channel)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') and $
	(ch ne 'X123') and (ch ne 'X123_FAST') and (ch ne 'SPS') and $
	(ch ne 'PS1') and (ch ne 'PS2') and (ch ne 'PS3') and $
	(ch ne 'PS4') and (ch ne 'PS5') and (ch ne 'PS6') then begin
  print, 'ERROR rxrs_cruciform: Invalid Channel name.  Expected A1, A2, B1, B2, X123, SPS, or PS1-PS6.'
  return
endif

if (n_params() lt 2) then begin
  filename = ''
endif

if (n_params() lt 3) then begin
  doSURF = 0
  surffile=' '
endif else begin
  doSURF = 1
endelse

;  itime is not needed for 2018 processing
if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

if keyword_set(quad45) or keyword_set(quadx) or keyword_set(quady) then doQuad = 1 else doQuad = 0

;
;	2.	Plot the data using:
;			MinXSS-like (2018) files [2018 default]: plot_rxrs_hydra.pro
;			/rocket option for Rocket Hydra files:  plotxrs.pro
;			/etu option for ETU XRS files:  plot_xrs_gse.pro
;
if keyword_set(rocket) then begin
  ; Use ROCKET interface
 if keyword_set(debug) then begin
  if (doSURF ne 0) then begin
    plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
  endif else begin
    plotxrs, ch, filename, itime=integtime, data=data, /debug
  endelse
 endif else begin
  if (doSURF ne 0) then begin
    plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
  endif else begin
    plotxrs, ch, filename, itime=integtime, data=data
  endelse
 endelse
endif else if keyword_set(etu) then begin
  ; Use ETU XRS interface
 if keyword_set(debug) then begin
  if (doSURF ne 0) then begin
    plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
  endif else begin
    plot_xrs_gse, ch, filename, itime=integtime, data=data, /debug
  endelse
 endif else begin
  if (doSURF ne 0) then begin
    plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
  endif else begin
    plot_xrs_gse, ch, filename, itime=integtime, data=data
  endelse
 endelse
endif else begin
  ; Use default MinXSS (rocket 2018) XRS interface
  if (doSURF ne 0) then begin
    plot_rxrs_hydra, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, $
    			debug=debug, quad45=quad45
  endif else begin
    plot_rxrs_hydra, ch, filename, itime=integtime, data=data, debug=debug, quad45=quad45
  endelse
endelse

;
;	3.  User selects time range of interest
;
tbase = long(data[0].time/1000.) * 1000L
ans = 'Y'
read, 'Do you need to restrict the scan time ? (Y or N) ', ans
ans = strupcase(strmid(ans,0,1))
if (ans eq 'Y') then begin
  ans2=' '
  read, 'Move cursor to LEFT side of the FOV scan and hit RETURN key...', ans2
  cursor, x1, y1, /nowait
  read, 'Move cursor to RIGHT side of the FOV scan and hit RETURN key...', ans2
  cursor, x2, y2, /nowait
  ;  get scan data
  wfov = where( (data.time ge (x1+tbase)) and (data.time le (x2+tbase)), numfov )
  if (numfov lt 2) then begin
    print, 'ERROR rxrs_cruciform: user did not select valid time range'
    return
  endif
  fovdata = data[wfov]
endif else begin
  fovdata = data
endelse

;
;	determine which axis is moving:  expect both Pitch and Yaw to be moving for alpha-beta scans
;
if (doSURF ne 0) then begin
  diff = fltarr(4)
  diff[0] = max(fovdata.surfx) - min(fovdata.surfx)
  diff[1] = max(fovdata.surfy) - min(fovdata.surfy)
  diff[2] = max(fovdata.surfu) - min(fovdata.surfu)
  diff[3] = max(fovdata.surfv) - min(fovdata.surfv)
  temp = max(diff, wdiff)
  case wdiff of
    0: begin
       type='X'
       sdata = fovdata.surfx
       slimit = 0.005
       cdata = fovdata.signal
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 50) then cntlimit = 50.
       ytitle='Signal per mA)'
       stop, 'STOPPED:  you should use rxrs_center.pro to analyze X scan data...'
       end
    1: begin
       type='Y'
       sdata = fovdata.surfy
       slimit = 0.002
       cdata = fovdata.signal
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 50) then cntlimit = 50.
       ytitle='Signal per mA'
       stop, 'STOPPED:  you should use rxrs_center.pro to analyze Y scan data...'
       end
    2: begin
       type='Yaw (U)'
       sdata = fovdata.surfu
       slimit = 0.05
        if (doQuad eq 0) then begin
         cdata = fovdata.signal
         ytitle='Signal per mA'
       endif else if keyword_set(quadx) then begin
         cdata = fovdata.quadx
         ytitle='Quad-X'
       endif else if keyword_set(quady) then begin
         cdata = fovdata.quady
         ytitle='Quad-Y'
       endif else begin
         cdata = fovdata.quad13
         ytitle='Quad-13'
       endelse
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 0.02) then cntlimit = 0.02
       end
    3: begin
       type='Pitch (V)'
       sdata = fovdata.surfv
       slimit = 0.05
       if (doQuad eq 0) then begin
         cdata = fovdata.signal
         ytitle='Signal per mA'
       endif else if keyword_set(quadx) then begin
         cdata = fovdata.quadx
         ytitle='Quad-X'
       endif else if keyword_set(quady) then begin
         cdata = fovdata.quady
         ytitle='Quad-Y'
       endif else begin
         cdata = fovdata.quad24
         ytitle='Quad-24'
       endelse
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 0.02) then cntlimit = 0.02
      end
  endcase
endif else begin
  type = 'Time'
  sdata = fovdata.time - tbase
  slimit = 10.
  cdata = fovdata.signal
  cntlimit = (max(cdata) - min(cdata))/100.
  if (cntlimit lt 50) then cntlimit = 50.
  ytitle='Signal'
  stop, 'STOPPED:  you should use rxrs_center.pro to plot TIME series data...'
endelse

;  FIND which Quad Diode direction is changing the most
  diff2 = fltarr(4)
  diff2[0] = max(fovdata.quadx) - min(fovdata.quadx)
  diff2[1] = max(fovdata.quady) - min(fovdata.quady)
  diff2[2] = max(fovdata.quad13) - min(fovdata.quad13)
  diff2[3] = max(fovdata.quad24) - min(fovdata.quad24)
  temp2 = max(diff2[0:1], wdiff2)
  case wdiff2 of
    0: begin
       type='Alpha'
       sdata = -0.7071 * fovdata.surfu -0.7071 * fovdata.surfv
       slimit = 0.05
       cdata = fovdata.quadx
       ytitle='Quad-X'
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 0.02) then cntlimit = 0.02
       end
    1: begin
       type='Beta'
       sdata = -0.7071 * fovdata.surfu + 0.7071 * fovdata.surfv
       slimit = 0.05
       cdata = fovdata.quady
       ytitle='Quad-Y'
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 0.02) then cntlimit = 0.02
       end
	endcase

print, 'Doing Cruciform analysis for ', type

;
;	Debug time offsets seen between Hydra and SURFER
;
if keyword_set(debug) and (doSURF ne 0) then begin
 if (debug gt 1) then begin
  ;  find steps in counts
  cntdiff = abs(cdata - shift(cdata,1))
  cntdiff[0] = cntdiff[1]
  wcbig = where( cntdiff gt cntlimit, numcbig )
  if (numcbig lt 1) then begin
    cntlimit = max(cntdiff)/2.
    wcbig = where( cntdiff gt cntlimit, numcbig )
  endif
  if (numcbig gt 1) then begin
    ; compress steps to when the move starts
    if (type eq 'X') or (type eq 'Y') then begin
      plot_io, fovdata.time-tbase, cdata, ys=1, yrange=[100,max(cdata)*1.1], $
          xtitle='Time', ytitle=ytitle
      fullrange = 10.^!y.crange
    endif else begin
      plot, fovdata.time-tbase, cdata, ys=1, yrange=[-1.,1.], $
          xtitle='Time', ytitle=ytitle
      fullrange = !y.crange
    endelse
    wc_step = indgen(numcbig)
    num = 1
    wc_step[0] = wcbig[0]
    ctime = fovdata[wcbig[0]].time - tbase
    oplot, ctime*[1,1], fullrange, line=2
    for k=1,numcbig-1 do begin
      if (wcbig[k] gt (wcbig[k-1]+1)) then begin
        wc_step[num] = wcbig[k]
        num = num + 1
        ctime = fovdata[wcbig[k]].time - tbase
        oplot, ctime*[1,1], fullrange, line=2
      endif
    endfor
    wc_step = wc_step[0:num-1]
    numc_step = num
  endif

  ;  find steps in surf position
  sdiff = abs(sdata - shift(sdata,1))
  sdiff[0] = sdiff[1]
  wsbig = where( sdiff gt slimit, numsbig )
  if (numsbig lt 1) then begin
    slimit2 = max(sdiff)/2.
    wsbig = where( sdiff gt slimit2, numsbig )
  endif
  if (numsbig gt 1) then begin
    ; compress steps to when the move starts
    ans = ' '
    read, 'Next Plot ? ', ans
    plot, fovdata.time-tbase, sdata, xtitle='Time', ytitle=type
    ws_step = indgen(numsbig)
    num = 1
    ws_step[0] = wsbig[0]
    ctime = fovdata[wsbig[0]].time - tbase
    oplot, ctime*[1,1], !y.crange, line=2
    for k=1,numsbig-1 do begin
      if (wsbig[k] gt (wsbig[k-1]+1)) then begin
        ws_step[num] = wsbig[k]
        num = num + 1
        ctime = fovdata[wsbig[k]].time - tbase
        oplot, ctime*[1,1], !y.crange, line=2
      endif
    endfor
    ws_step = ws_step[0:num-1]
    nums_step = num
  endif

  ;  print results
  if (numc_step gt 1) and (nums_step gt 1) then begin
    kmax = long(max([numc_step,nums_step])-1L)
    print, 'Time Base = ', strtrim(tbase,2)
    print, 'Index  Cnt_Step_Time   SURF_Step_Time '
    print, '-----  --------------  -------------- '
    format='(I5,4F8.1)'
    EMPTY_VALUE = -9999.0
    tcntlast = 0.
    tslast = 0.
    for k=0L,kmax do begin
      if (k lt numc_step) then tcnt = fovdata[wc_step[k]].time - tbase else tcnt = EMPTY_VALUE
      if (tcnt ne EMPTY_VALUE) and (k ne 0) then ccdiff = tcnt - tcntlast else ccdiff = 0.0
      tcntlast = tcnt
      if (k lt nums_step) then ts = fovdata[ws_step[k]].time - tbase else ts = EMPTY_VALUE
      if (ts ne EMPTY_VALUE) and (k ne 0) then ssdiff = ts - tslast else ssdiff = 0.0
      tslast = ts
      print, k, tcnt, ccdiff, ts, ssdiff, format=format
    endfor
  endif
 endif
endif

;
;	4.  Re-plot and display center results (edges and peak)
;
if keyword_set(debug) then begin
  ans = ' '
  read, 'Center plot ? ', ans
endif

;
;	smooth the data a bit
;
nsmooth = 3
if (median(cdata) lt 10) then nsmooth=7
if keyword_set(debug) then print, 'Smoothing signal by ', nsmooth
smcnt = smooth(cdata,nsmooth,/edge_trun)
if (median(cdata) lt 10) then cdata = smcnt

setplot
cc=rainbow(7)
plot, sdata, cdata, psym=-4, xtitle=type, ytitle=ytitle, ystyle=1, title=ch
; stop, 'DEBUG ...'

; save the plot data
plotdata = [[sdata], [cdata]]

;
;	Do linear fit between sdata (alpha/beta) and cdata (Quad X/Y)
;
cfit1 = poly_fit( sdata, cdata, 1, sigma=sig1 )
print, ' '
print, 'FIT-1 is  ', ytitle, ' = ', strtrim(cfit1[0],2), ' + ', strtrim(cfit1[1],2), ' * ',type
print, '     Parameter Sigma = ', strtrim(sig1[0],2), ' & ', strtrim(sig1[1],2)
print, ' '
xfit1 = sdata[sort(sdata)]
yfit1 = cfit1[0] + cfit1[1] * xfit1
oplot, xfit1, yfit1, color=cc[3]

cfit2 = poly_fit( cdata, sdata, 1, sigma=sig2 )
print, 'FIT-2 is  ', type, ' = ', strtrim(cfit2[0],2), ' + ', strtrim(cfit2[1],2), ' * ',ytitle
print, '     Parameter Sigma = ', strtrim(sig2[0],2), ' & ', strtrim(sig2[1],2)
print, ' '

if keyword_set(debug) then begin
	stop, 'STOPPED at end of rxrs_cruciform...'
endif
end
