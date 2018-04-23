;+
; NAME:
;	rxrs_center
;
; PURPOSE:
;	Identify Center value for scan across FOV
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:
;	rxrs_center, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2' PLUS added 'X123', 'X123_Fast', 'SPS', 'PS1' - 'PS6'
;	filename	Hydra Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;	/rocket		Option to use rocket XRS procedures instead of MinXSS XRS procedures
;	/etu		Option to use ETU XRS procedures instead of MinXSS XRS procedures
;	/quadx		Option to use Quad X data instead of finding edges
;	/quady		Option to use Quad Y data instead of finding edges
;	/quad45		Option to use Quad 45 degrees data instead of finding edges
;	/fitlimit	Option to specify range of fit from Maximum: default is 0.2 to 0.8 of Max
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
;	1/22/10		Tom Woods	Original file creation
;	9/21/10		Tom Woods	Updated for ETU XRS calibrations
;	3/24/18		Tom Woods	Updated for Rocket XRS with MinXSS-like packets (default option)
;+

pro rxrs_center, channel, filename, surffile, itime=itime, debug=debug, $
						rocket=rocket, etu=etu, fitlimit=fitlimit, $
						data=data, surfdata=surfdata, plotdata=plotdata, $
						quad45=quad45, quadx=quadx, quady=quady
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  rxrs_center, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]'
  return
endif

ch = strupcase(channel)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') and $
	(ch ne 'X123') and (ch ne 'X123_FAST') and (ch ne 'SPS') and $
	(ch ne 'PS1') and (ch ne 'PS2') and (ch ne 'PS3') and $
	(ch ne 'PS4') and (ch ne 'PS5') and (ch ne 'PS6') then begin
  print, 'ERROR rxrs_center: Invalid Channel name.  Expected A1, A2, B1, B2, X123, SPS, or PS1-PS6.'
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
    print, 'ERROR rxrs_center: user did not select valid time range'
    return
  endif
  fovdata = data[wfov]
endif else begin
  fovdata = data
endelse

;
;	determine which axis is moving
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
       end
    1: begin
       type='Y'
       sdata = fovdata.surfy
       slimit = 0.002
       cdata = fovdata.signal
       cntlimit = (max(cdata) - min(cdata))/100.
       if (cntlimit lt 50) then cntlimit = 50.
       ytitle='Signal per mA'
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
endelse

print, 'Doing CENTER analysis for ', type

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
if (median(cdata) lt 10) then nsmooth=11
if keyword_set(debug) then print, 'Smoothing signal by ', nsmooth
smcnt = smooth(cdata,nsmooth,/edge_trun)
if (median(cdata) lt 10) then cdata = smcnt

setplot
cc=rainbow(7)
plot, sdata, cdata, psym=-4, xtitle=type, ytitle=ytitle, ystyle=1
; stop, 'DEBUG ...'

; save the plot data
plotdata = [[sdata], [cdata]]

if (type eq 'X') or (type eq 'Y') or (doQuad eq 0) then begin
;
;	maximum signal
;
cmax = max(smcnt, wcmax)
smax = sdata[wcmax]
oplot, smax*[1,1],!y.crange,line=1, color=cc[0]
print, ' '
print, 'Maximum signal (red) is at ', strtrim(smax,2)
print, ' '

;
;	edge search by fitting line between 0.8 and 0.2 of (Max-Min)
;
edgelimit1 = 0.2 * cmax
edgelimit2 = 0.8 * cmax
if keyword_set(fitlimit) and n_elements(fitlimit) ge 2 then begin
	edgelimit1 = fitlimit[0] * cmax
	edgelimit2 = fitlimit[1] * cmax
endif
edgemid = (edgelimit1+edgelimit2)/2.
wedge1 = where( (smcnt gt edgelimit1) and (smcnt lt edgelimit2) and (sdata lt smax), numedge1 )
wedge2 = where( (smcnt gt edgelimit1) and (smcnt lt edgelimit2) and (sdata gt smax), numedge2 )
if (numedge1 gt 5) and (numedge2 gt 5) then begin
  cfit1 = poly_fit( sdata[wedge1], cdata[wedge1], 1 )
  srange1 = min(sdata[wedge1]) + findgen(11)*(max(sdata[wedge1])-min(sdata[wedge1]))/10.
  crange1 = cfit1[0] + cfit1[1] * srange1
  oplot, srange1, crange1, color=cc[5]
  fitedge1 = (edgemid - cfit1[0])/cfit1[1]
  oplot, fitedge1*[1,1],!y.crange,line=3, color=cc[5]
  cfit2 = poly_fit( sdata[wedge2], cdata[wedge2], 1 )
  srange2 = min(sdata[wedge2]) + findgen(11)*(max(sdata[wedge2])-min(sdata[wedge2]))/10.
  crange2 = cfit2[0] + cfit2[1] * srange2
  oplot, srange2, crange2, color=cc[5]
  fitedge2 = (edgemid - cfit2[0])/cfit2[1]
  oplot, fitedge2*[1,1],!y.crange,line=3, color=cc[5]
  fitcenter = (fitedge1 + fitedge2)/2.
  oplot, fitcenter*[1,1], !y.crange, line=3, color=cc[5]
  print, 'FIT Edges at ', strtrim(fitedge1,2), ' and ', strtrim(fitedge2,2)
  print, 'FIT Edge Center (blue) is at ', strtrim(fitcenter,2)
  print, ' '
endif else begin
  print, 'Warning: not enough points to fit line to edges.'
endelse

;
;	edge search
;
doFineTune = 1
edgelimit = 0.50
cntedge = cmax*edgelimit
if (cntedge lt min(smcnt)) then begin
  cntedge = max(smcnt) - (max(smcnt) - min(smcnt))/3.
  doFineTune = 1
endif
redoTune:
whigh = where( smcnt gt cntedge, numhigh )
if (numhigh gt 1) and (numhigh lt (n_elements(smcnt)-5)) then begin
  ii1 = [whigh[0]-1, whigh[0]]
  s1 = interpol( sdata[ii1], smcnt[ii1], cntedge )
  oplot, s1*[1,1], !y.crange, line=2, color=cc[3]
  ii2 = [whigh[numhigh-1], whigh[numhigh-1]+1]
  s2 = interpol( sdata[ii2], smcnt[ii2], cntedge )
  oplot, s2*[1,1], !y.crange, line=2, color=cc[3]
  scenter = (s1 + s2)/2.
  oplot, scenter*[1,1], !y.crange, line=2, color=cc[3]
  print, 'Edges at ', strtrim(s1,2), ' and ', strtrim(s2,2)
  print, 'Edge Center (green) is at ', strtrim(scenter,2)
  print, ' '
endif
if (doFineTune eq 1) then begin
  read, 'Enter level for edge search (-1 to exit) : ', cntedge
  if (cntedge gt 0) then goto, redoTune
endif
endif else begin
;
;	Do Quad Diode check
;  Search for where cdata crosses zero (Quad diode)
;
quadlimit = 0.5
wlow = where( abs(cdata) lt quadlimit, numlow )
if (numlow gt 1) then begin
  ; simple interpolate near zero for Quad value
  szero = interpol( sdata[wlow], cdata[wlow], 0.0 )
  oplot, szero*[1,1], !y.crange, line=1, color=cc[0]
  oplot, !x.crange, [0,0], color=cc[5]
  print, ' '
  print, 'Quad Zero Crossing (red) is at ', strtrim(szero,2)
  print, ' '
  ; fit line to data
  ccfit = poly_fit( cdata[wlow], sdata[wlow], 1 )
  xx = findgen(21)/20. - 0.5
  oplot, ccfit[0]+ccfit[1]*xx, xx, color=cc[3]
  szero2 = ccfit[0]
  oplot, szero2*[1,1], !y.crange, line=2, color=cc[3]
  print, 'Line Fit Zero Value (green) is at ', strtrim(szero2,2)
  print, '    Quad Multiplier = ', strtrim(60./ccfit[1],2), ' arc-min'
  print, ' '
endif
if keyword_set(debug) then begin
  print, 'Min. and Max. Signal = ', min(fovdata.rawcnt), max(fovdata.rawcnt)
  wlow2 = where( abs(fovdata.quadx) lt quadlimit, numlow2 )
  if (numlow2 gt 1) then begin
    ccfit2 = poly_fit( fovdata[wlow2].quadx, sdata[wlow2], 1 )
    print, ' X - Quad Multiplier = ', strtrim(60./ccfit2[1],2), ' arc-min'
  endif
  wlow2 = where( abs(fovdata.quady) lt quadlimit, numlow2 )
  if (numlow2 gt 1) then begin
    ccfit2 = poly_fit( fovdata[wlow2].quady, sdata[wlow2], 1 )
    print, ' Y - Quad Multiplier = ', strtrim(60./ccfit2[1],2), ' arc-min'
  endif
  print, ' '
  ; stop, 'DEBUG some more...'
endif
endelse
end
