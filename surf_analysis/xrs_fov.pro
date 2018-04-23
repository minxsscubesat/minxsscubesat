;+
; NAME:
;	xrs_fov
;
; PURPOSE:
;	Plot FOV map data
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	xrs_fov, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
;	filename	DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;	/rocket		Option to select rocket XRS, default is ETU XRS
;
; OUTPUTS:  
;	PLOT		Showing FOV map data as Alpha and Beta scans
;
;	data		DataView Dump data
;	surfdata	SURFER PC log data
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data using plotxrs.pro for /rocket or  plot_xrs_gse.pro for ETU-XRS
;	3.  Re-plot as Alpha and Beta Scans
;
; MODIFICATION HISTORY:
;	1/25/10		Tom Woods	Original file creation
;	9/21/10		Tom Woods	Updated so /rocket allows heritage calls to plotxrs.pro
;
;+

pro xrs_fov, channel, filename, surffile, itime=itime, debug=debug, $
				rocket=rocket, data=data, surfdata=surfdata
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_fov, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]'
  return
endif

ch = strmid(strupcase(channel),0,2)
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
  print, 'ERROR xrs_center: Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return
endif

if (n_params() lt 2) then begin
  filename =' '
endif

if (n_params() lt 3) then begin
  surffile=' '
endif

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

;
;	2.	Read/Plot the data using plotxrs.pro
;
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=fovdata, surfdata=surfdata, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=fovdata, surfdata=surfdata
 endelse
endif else begin
 ; new code for ETU XRS (Sep 2010)
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, filename, surffile, itime=integtime, data=fovdata, surfdata=surfdata, /debug
 endif else begin
  plot_xrs_gse, ch, filename, surffile, itime=integtime, data=fovdata, surfdata=surfdata
 endelse
endelse

;
;	3.  Re-plot as Alpha and Beta Scans
;

;
;	exclude dark data (in case there is beam injection
;
wgd = where( fovdata.rawcnt gt (min(fovdata.rawcnt)+100.), numgd )
if (numgd lt 10) then begin
  print, 'ERROR finding enough good data for FOV map !'
  return
endif
fovdata = fovdata[wgd]

;
;	Define cdata as the Signal for all data points
;
  ytitle='Signal (fA / mA)'
  cdata = fovdata.signal
  cntlimit = (max(cdata) - min(cdata))/100.
  if (cntlimit lt 50) then cntlimit = 50.

;
;	determine which 2 axes are moving - expect it to be Yaw & Pitch
;
  diff = fltarr(4)
  diff[0] = max(fovdata.surfx) - min(fovdata.surfx)
  diff[1] = max(fovdata.surfy) - min(fovdata.surfy)
  diff[2] = max(fovdata.surfu) - min(fovdata.surfu)
  diff[3] = max(fovdata.surfv) - min(fovdata.surfv)
  ;  Get First Maximum Range
  temp = max(diff, wdiff)
  case wdiff of
    0: begin
       type='X'
       sdata1 = fovdata.surfx
       slimit1 = 0.005
       end
    1: begin
       type='Y'
       sdata1 = fovdata.surfy
       slimit1 = 0.002
       end
    2: begin
       type='Yaw (U)'
       sdata1 = fovdata.surfu
       slimit1 = 0.05
       cdata1 = fovdata.quad13
       cntlimit1 = (max(cdata1) - min(cdata1))/100.
       if (cntlimit1 lt 0.02) then cntlimit1 = 0.02
       end
    3: begin
       type='Pitch (V)'
       sdata1 = fovdata.surfv
       slimit1 = 0.05
       cdata1 = fovdata.quad24
       cntlimit1 = (max(cdata1) - min(cdata1))/100.
       if (cntlimit1 lt 0.02) then cntlimit1 = 0.02
      end
  endcase
  ;  Get Second Maximum Range
  diff2 = diff
  diff2[wdiff] = 0.0
  temp = max(diff2, wdiff2)
  case wdiff2 of
    0: begin
       type=type + ' & X'
       sdata2 = fovdata.surfx
       slimit2 = 0.005
       end
    1: begin
       type=type + ' & Y'
       sdata2 = fovdata.surfy
       slimit2 = 0.002
       end
    2: begin
       type=type + ' & Yaw (U)'
       sdata2 = fovdata.surfu
       slimit2 = 0.05
       cdata2 = fovdata.quad13
       cntlimit2 = (max(cdata2) - min(cdata2))/100.
       if (cntlimit2 lt 0.02) then cntlimit2 = 0.02
       end
    3: begin
       type=type + ' & Pitch (V)'
       sdata2 = fovdata.surfv
       slimit2 = 0.05
       cdata2 = fovdata.quad24
       cntlimit2 = (max(cdata2) - min(cdata2))/100.
       if (cntlimit2 lt 0.02) then cntlimit2 = 0.02
      end
  endcase

if ((wdiff ne 2) or (wdiff2 ne 3)) and ((wdiff ne 3) or (wdiff2 ne 2)) then begin
    print, 'ERROR xrs_fov: expected U & V map instead of ', type
    return
endif

print, 'Doing FOV map plots for ', type


;
;	Assume no time offsets seen between DataView and SURFER
;	Code from xrs_center.pro
;
doTimeOffset = 0  ;  = keyword_set(debug)
if (doTimeOffset ne 0) then begin
 tbase = long(fovdata[0].time/1000.) * 1000L
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
;	Sort Yaw and Pitch data into moving or not moving
;
sdiff1 = abs(sdata1 - shift(sdata1,1))
sdiff1[0] = 1.
sdiff2 = abs(sdata2 - shift(sdata2,1))
sdiff2[0] = 1.
wmap = where( (sdiff1 eq 0) and (sdiff2 eq 0), nummap )
if (nummap lt 15) then begin
  print, 'ERROR xrs_fov: not enough map data points'
  return
endif

;
;	save only the non-moving data for the plots
;
cmap = cdata[wmap]
if (wdiff eq 2) then begin
  ; Yaw first
  smap1 = sdata1[wmap]
  smap2 = sdata2[wmap]
endif else begin
  ; Pitch first
  smap1 = sdata2[wmap]
  smap2 = sdata1[wmap]
endelse

;
;	calculate ALPHA and BETA
;
alpha = -0.707 * smap1 - 0.707 * smap2
beta = -0.707 * smap1 + 0.707 * smap2

alpha1 = min(alpha)
alpha2 = max(alpha)
ralpha = [ alpha1 - (alpha2-alpha1)/5., alpha2 * 1.2 ]
beta1 = min(beta)
beta2 = max(beta)
rbeta = [ beta1 - (beta2-beta1)/5., beta2 * 1.2 ]

;
;	ask user if ready for next plot
;
ans = ' '
read,'Ready for BETA plot ? ', ans

setplot
cs = 1.8
ct = 1.6

yr = [ min(cmap)*0.98, max(cmap)*1.02]
cmapmedian = median(cmap)
if (yr[0] lt (cmapmedian * 0.95)) then yr[0] = cmapmedian * 0.95
if (yr[1] gt (cmapmedian * 1.05)) then yr[1] = cmapmedian * 1.05

wcenter = 0.1
wnot = where( (abs(alpha) gt wcenter) or (abs(beta) gt wcenter), numnot )
if (numnot gt 2) then yr = [ min(cmap[wnot])*0.98, max(cmap[wnot])*1.02]

cmapmedian = median(cmap)
if (yr[0] lt (cmapmedian * 0.90)) then yr[0] = cmapmedian * 0.90
if (yr[1] gt (cmapmedian * 1.10)) then yr[1] = cmapmedian * 1.10

;
;  do BETA plot first (so sort by Alpha)
;
plot, beta, cmap, /nodata, xtitle='Beta (deg)', xrange=rbeta, xs=1, ytitle=ytitle, yrange=yr, ys=1
; sort by alpha bins for plots in color
mapstep = 0.2
anum = long((alpha2-alpha1)/mapstep) + 1
alpha1 = alpha1 - mapstep/3.
xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
dy = (!y.crange[1] - !y.crange[0])/15.
yy = !y.crange[0] + dy
cc=rainbow(anum+1)

xx2 = !x.crange[0] * 0.05 + !x.crange[1] * 0.95
yy2 = (!y.crange[0] + !y.crange[1])/2.
oplot, xx2*[1,1], yy2*[0.995,1.005], thick=5
xyouts, xx2, yy2*1.006, '1%', charsize=cs, charthick=ct

for k=0,anum-1 do begin
  wgd = where( (alpha ge (alpha1+k*mapstep)) and (alpha lt (alpha1+(k+1)*mapstep)), numgd )
  if (numgd gt 1) then begin
    oplot, beta[wgd], cmap[wgd], psym=4, color=cc[k]
    knum = (alpha1+k*mapstep + mapstep/3.)*10.
    if (knum gt 0) then knum = knum + 0.5
    aStr = string(long(knum)/10.,format='(F5.1)')
    xyouts, xx, yy + k*dy, aStr, color=cc[k], charsize=cs, charthick=ct
  endif  
endfor
xyouts, xx, yy + anum*dy, 'Alpha', charsize=cs, charthick=ct
bfile = 'fov_beta_'+ch+'.jpg'
write_jpeg_tv, bfile

;
;  do ALPHA plot second (so sort by Beta)
;
read,'Ready for ALPHA plot ? ', ans

plot, alpha, cmap, /nodata, xtitle='Alpha (deg)', xrange=ralpha, xs=1, ytitle=ytitle, yrange=yr, ys=1
; sort by beta bins for plots in color
mapstep = 0.2
anum = long((beta2-beta1)/mapstep) + 1
beta1 = beta1 - mapstep/3.
xx = !x.crange[0] * 0.95 + !x.crange[1] * 0.05
dy = (!y.crange[1] - !y.crange[0])/15.
yy = !y.crange[0] + dy
cc=rainbow(anum+1)

xx2 = !x.crange[0] * 0.05 + !x.crange[1] * 0.95
yy2 = (!y.crange[0] + !y.crange[1])/2.
oplot, xx2*[1,1], yy2*[0.995,1.005], thick=5
xyouts, xx2, yy2*1.006, '1%', charsize=cs, charthick=ct

for k=0,anum-1 do begin
  wgd = where( (beta ge (beta1+k*mapstep)) and (beta lt (beta1+(k+1)*mapstep)), numgd )
  if (numgd gt 1) then begin
    oplot, alpha[wgd], cmap[wgd], psym=4, color=cc[k]
    knum = (beta1+k*mapstep + mapstep/3.)*10.
    if (knum gt 0) then knum = knum + 0.5
    aStr = string(long(knum)/10.,format='(F5.1)')
    xyouts, xx, yy + k*dy, aStr, color=cc[k], charsize=cs, charthick=ct
  endif  
endfor
xyouts, xx, yy + anum*dy, 'Beta', charsize=cs, charthick=ct
afile = 'fov_alpha_'+ch+'.jpg'
write_jpeg_tv, afile
print, 'JPEG files written: ', afile, '  ', bfile

;  return DataView dump data
data = fovdata

return
end
