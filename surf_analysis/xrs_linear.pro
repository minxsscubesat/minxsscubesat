;+
; NAME:
;	xrs_linear
;
; PURPOSE:
;	Plot linearity data
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	xrs_linear, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, lineardata=lineardata]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
;	filename	DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;	/rocket		Option to read rocket XRS data - default now ETU XRS GSE data
;
; OUTPUTS:  
;	PLOT		Showing linearity data as difference between linear fit
;
;	data		DataView Dump data
;	surfdata	SURFER PC log data
;	lineardata	Linear data (ratio plot data)
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data using plotxrs.pro
;	3.  Plot data versus Beam Current (BC)
;
; MODIFICATION HISTORY:
;	1/26/10		Tom Woods	Original file creation
;
;+

pro xrs_linear, channel, filename, surffile, itime=itime, rocket=rocket, $
					debug=debug, data=data, surfdata=surfdata, lineardata=lineardata
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_linear, channel, [ filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata, lineardata=lineardata]'
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
;	2.	Read/Plot the data using plotxrs.pro for rocket XRS or plot_xrs_gse.pro for ETU XRS
;
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
 endelse
endif else begin
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
 endif else begin
  plot_xrs_gse, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
 endelse
endelse

;
; ask user to select data range (in case saturated or had re-injection)
;
setplot
cc=rainbow(7)
tbase = long(data[0].time/1000.) * 1000L
plot_io, data.time-tbase, data.signal, yr=[10,1E8], ys=1
oplot, data.time-tbase, data.surfbc * 1E6, color=cc[0]
ans=' '
read, 'Do you want to reduce the data range (Y or N) ? ', ans
ans = strupcase(strmid(ans,0,1))
if (ans eq 'Y') then begin
  read, 'Move cursor to LEFT side and hit RETURN key...', ans
  cursor,t1,y1,/nowait
  read, 'Move cursor to RIGHT side and hit RETURN key...', ans
  cursor,t2,y2,/nowait
  wgd = where( (data.time ge (t1+tbase)) and (data.time le (t2+tbase)), numgd )
  if (numgd gt 10) then begin
    data = data[wgd]
  endif else begin
    print, 'ERROR: not enough data selected !'
    return
  endelse
endif

;
;	3.  Plot data versus Beam Current (BC)
;

;
;	Define cdata as the Signal for all data points
;
ytitle='Signal (fA / mA)'
cdata = data.signal
craw = data.rawcnt

;
;  find steps in surf beam current (BC)
;
sdata = (data.surfbc > 1E-9)
slog = alog10(sdata)
slimit = alog10(2.) / 10.
;  shift across 10 seconds as ramp down is slow
nsmooth = 11L
nsmooth2 = nsmooth*2 + 1
sdiff = abs(shift(slog,nsmooth-1) - slog)	; drops are positive rises
sdiff[0:nsmooth-1] = sdiff[10]
ndiff = n_elements(sdiff)
sdiff[ndiff-nsmooth:*] = sdiff[ndiff-nsmooth-1]
sdiff = smooth(smooth(sdiff,nsmooth,/edge),nsmooth,/edge)
wsbig = where( sdiff gt slimit, numsbig )
if (numsbig lt 1) then begin
    slimit2 = max(sdiff)/2.
    wsbig = where( sdiff gt slimit2, numsbig )
endif
if (numsbig gt 1) then begin
    ; compress steps to when the BC changes
    ans = ' '
    ; read, 'Next Plot ? ', ans
    setplot
    cc=rainbow(7)
    plot, data.time-tbase, slog, xtitle='Time', ytitle='log(SURF BC)'
    ws_step = indgen(numsbig)
    ws_step2 = ws_step	; end value for decrease
    num = 1
    ws_step[0] = (wsbig[0] - nsmooth2) > 0
    ctime = data[wsbig[0]].time - tbase
    oplot, ctime*[1,1], !y.crange, line=2
    for k=1,numsbig-1 do begin
      if (wsbig[k] gt (wsbig[k-1]+1)) then begin
        ws_step2[num-1] = wsbig[k-1] + nsmooth2
        ws_step[num] = (wsbig[k] - nsmooth2) > 0
        num = num + 1
        ctime = data[wsbig[k]].time - tbase
        oplot, ctime*[1,1], !y.crange, line=2
        ctime2 = data[wsbig[k-1]].time - tbase
        oplot, ctime2*[1,1], !y.crange, line=3, color=cc[3]
      endif
    endfor
    ws_step2[num-1] = wsbig[numsbig-1]
    ctime2 = data[wsbig[k-1]].time - tbase
    oplot, ctime2*[1,1], !y.crange, line=3, color=cc[3]
    ws_step = ws_step[0:num-1]
    ws_step2 = ws_step2[0:num-1]
    nums_step = num
endif

;
;	now sort data into averages
;		skip first 2 points as might be rising from dark level
;
numfit=num-2
cbin = fltarr(numfit)
sbin = fltarr(numfit)
istart = 0
if (ws_step[0] le 0) then istart=1
ii = indgen(ws_step[istart]-1)
darkmax = 1000
wgd = where( craw[ii] gt darkmax, numgd )
if (numgd gt 5) then begin
  cbin[istart] = median(cdata[ii[wgd[2:*]]])
  sbin[istart] = median(sdata[ii[wgd[2:*]]])
endif else begin
  print, 'ERROR xrs_linear: no data for first BC step.'
  stop, 'DEBUG problem...'
endelse

ans = ' '
read, 'Next Plot ? ', ans

setplot
cc=rainbow(numfit+1)
if keyword_set(rocket) then mtitle = 'R-XRS Channel '+ch $
else mtitle = 'ETU-XRS Channel '+ch

yrange = cbin[istart]*[0.5,1.5]
xrange = [1E-4,max(sdata)]
if keyword_set(rocket) and (ch eq 'B1') then xrange[0] = 1E-6

plot_oi, sdata[ii], cdata[ii], psym=4, xr=xrange, xs=1, yr=yrange, ys=1, $
	xtitle='SURF BC (mA)', ytitle=ytitle, title=mtitle
	
for k=istart,numfit-1 do begin
  numii = ws_step[k+1] - ws_step2[k] - 2
  if (numii gt 5) then begin
    ii = indgen(numii) + ws_step2[k] + 1
    wgd = where( craw[ii] gt darkmax, numgd )
    if (numgd gt 5) then begin
      cbin[k] = median(cdata[ii[wgd[2:*]]])	; median() instead of mean()
      sbin[k] = median(sdata[ii[wgd[2:*]]])
      oplot, sdata[ii], cdata[ii], psym=4, color=cc[k]
    endif
  endif
endfor
wgood = where( cbin ne 0.0 )
cbin=cbin[wgood]
sbin=sbin[wgood]
oplot, sbin, cbin, psym=6

if keyword_set(rocket) then xrsname='rxrs' else xrsname='etuxrs'
jfile = 'linearity_'+xrsname+'_'+ch+'.jpg'
write_jpeg_tv, jfile

;
;	do plot of ratio from linearity
;
ans = ' '
read, 'Next Plot ? ', ans

refbins = indgen(5)
if (ch eq 'B1') then refbins = refbins + 2
reflevel = mean( cbin[refbins] )
yrange = [ 0.9, 1.1 ]

ratio = cbin/reflevel
print, ' '
print, 'Ratio MIN, Mean, Max = ', min(ratio), mean(ratio), max(ratio)

;  keep results: Beam Current, Counts, Ratio (in plot)
lineardata = [ [sbin], [cbin*sbin], [ratio] ]

plot_oi, sbin, ratio, psym=6, xr=xrange,xs=1, yrange=yrange, ys=1, $
	xtitle='SURF BC (mA)', ytitle='Ratio Measure / Fit', title=mtitle

oplot, xrange, 1.02*[1,1], line=2
oplot, xrange, 0.98*[1,1], line=2

oplot, xrange, 1.01*[1,1], line=1
oplot, xrange, 0.99*[1,1], line=1

jfile2 = 'linearity_ratio_'+xrsname+'_'+ch+'.jpg'
write_jpeg_tv, jfile2
print, ' '
print, 'JPEG files written to ', jfile, '  and  ', jfile2

if keyword_set(debug) then stop, 'STOP:  DEBUG xrs_linear...'

end
