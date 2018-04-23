;+
; NAME:
;	exis_xrs_linearity
;
; PURPOSE:
;	Plot linearity data
;	Updated for EXIS output format
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	exis_xrs_linearity, channel, [ filename, /debug, data=data, surfdata=surfdata, lineardata=lineardata]
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
;	2.	Pre-process the data
;	3.  Plot data versus Beam Current (BC)
;
; MODIFICATION HISTORY:
;	1/26/10		Tom Woods	Original file creation
;	11/1/11		Amir Caspi	Updated to use GSE data files (for XRS FM-1)
;
;+

pro exis_xrs_linearity, surffile, channel, fm=fm, includeall=includeall, despike=despike, correctbc=correctbc, correcttime=correcttime, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, debug=debug, help=help, data=data, surfdata=surfdata, lineardata=lineardata
;
;	1.  Check input parameters
;
if n_params() lt 2 or keyword_set(help) then begin
  message, /info, 'USAGE:  exis_xrs_linearity, <surffile>, <channel> [, fm=fm, includeall=includeall, despike=despike, correctbc=correctbc, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, debug=debug, help=help ]'
  message, /info, 'PLOTS linearity of detector versus beam current (deviation from mean).'
  message, /info, "Set fm to appropriate flight model number, 1-4, or 0 for ETU [DEFAULT: 1]"
  message, /info, "<channel> must be one of: A1, B1, A2, B2."
  message, /info, "Set /despike to attempt spike removal in SURF beam current (MAY exclude good data by accident)'
  message, /info, "Set /correctbc to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)"
  message, /info, "Set path_prefix, surf_dir, data_dir, and/or gain_dir if needed (default values in exis_process_surfdata.pro)"
  return
endif

; Check XRS channel for validity
ch = strupcase(strmid(channel,0,2))
if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
  message, /info, 'ERROR: Invalid Channel name.  Expected A1, A2, B1, or B2.'
  return
endif

;
;	2.	Pre-process the data
;
if n_elements(surffile) gt 1 then print, "WARNING: Multiple SURF files requested... each will be processed individually, THEN concatenated at the end..."
for i=0, n_elements(surffile)-1 do begin
  print, "Processing SURF file "+strtrim(i+1,2)+" of "+strtrim(n_elements(surffile),2)
  fovdata_temp = exis_process_surfdata(surffile[i], 'XRS', channel, fm=fm, /darkman, despike=despike, correctbc=correctbc, correcttime=correcttime, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, surfdata=surfdata_temp, tbase=tbase, debug=debug)
  if ((n_elements(fovdata_temp) eq 1) && (fovdata_temp eq -1)) then begin
    message, /info, "ERROR: exis_process_surfdata() returned -1; ABORTING..."
    return
  endif 
  fovdata = (n_elements(fovdata) eq 0) ? temporary(fovdata_temp) : [fovdata, temporary(fovdata_temp)]
  surfdata = (n_elements(surfdata) eq 0) ? temporary(surfdata_temp) : [[surfdata],[temporary(surfdata_temp)]]
endfor

data = fovdata
tbase = 0.
;
;	3.  Plot data versus Beam Current (BC)
;

;
;	Define cdata as the Signal for all data points
;
ytitle='Signal (fA / mA)'
cdata = data.signal
valid_channels = ['A1','B1','A2','B2']
isQuad = ([0, 0, 1, 1])[where(ch eq valid_channels)]
isignal = ([5, 4+6, 0+6, 1])[where(ch eq valid_channels)]
craw = isQuad ? total(data.rawdata.diodes[isignal:isignal+3,*],1) : reform(data.rawdata.diodes[isignal,*])
haveValves = ((mean(data.surfvalves) ne -1) and (mean(data.surfvalves) ne 0))

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
sdiff = smooth(smooth(sdiff,nsmooth,/edge_trunc),nsmooth,/edge_trunc)
wsbig = where( sdiff gt slimit, numsbig )
if (numsbig lt 1) then begin
    slimit2 = max(sdiff)/2.
    wsbig = where( sdiff gt slimit2, numsbig )
endif
if (numsbig gt 1) then begin
    ; compress steps to when the BC changes
    ans = ' '
    ; read, 'Next Plot ? ', ans
;    setplot
    cc=rainbow(7)
    if keyword_set(debug) then plot, data.time-tbase, slog, xtitle='Time', ytitle='log(SURF BC)'
    ws_step = indgen(numsbig)
    ws_step2 = ws_step	; end value for decrease
    num = 1
    ws_step[0] = (wsbig[0] - nsmooth2) > 0
    ctime = data[wsbig[0]].time - tbase
    if keyword_set(debug) then oplot, ctime*[1,1], !y.crange, line=2
    for k=1,numsbig-1 do begin
      if (wsbig[k] gt (wsbig[k-1]+1)) then begin
        ws_step2[num-1] = wsbig[k-1] + nsmooth2
        ws_step[num] = (wsbig[k] - nsmooth2) > 0
        num = num + 1
        ctime = data[wsbig[k]].time - tbase
        if keyword_set(debug) then oplot, ctime*[1,1], !y.crange, line=2
        ctime2 = data[wsbig[k-1]].time - tbase
        if keyword_set(debug) then oplot, ctime2*[1,1], !y.crange, line=3, color=cc[3]
      endif
    endfor
    ws_step2[num-1] = wsbig[numsbig-1]
    ctime2 = data[wsbig[k-1]].time - tbase
    if keyword_set(debug) then oplot, ctime2*[1,1], !y.crange, line=3, color=cc[3]
    ws_step = ws_step[0:num-1]
    ws_step2 = ws_step2[0:num-1]
    nums_step = num
endif

; ws_step2 is where "stable" data starts... ws_step is where "stable" data ends...
; Make sure to capture data before the first step and after the last step...
ws_step2 = [0L, ws_step2]
ws_step = [ws_step, n_elements(sdiff)-1]

;
;	now sort data into averages
;   require data to be 3 sigma above background [dark]
;		skip first 3 and last 3 points as might be transitioning from dark level
;
numfit=num+1
cbin = fltarr(numfit)
ecbin = fltarr(numfit)
sbin = fltarr(numfit)

ans = ' '
if keyword_set(debug) then begin
  read, 'Next Plot ? ', ans
  if (strupcase(strmid(ans, 0, 1)) eq 'S') then stop
endif

start_k = 0
low_k = numfit
for k=0,numfit-1 do begin
  numii = ws_step[k] - ws_step2[k] - 2
  if (numii gt 5) then begin
    ii = indgen(numii) + ws_step2[k] + 1
    ; TODO: Remove saturated points!!
;    wgd = where( craw[ii] gt darkmax, numgd )
    if (haveValves) then begin ; valve info present
      wgd = where(data[ii].surfvalves eq 7, numgd) ; pick the data with open valves, duh
      if (numgd gt 7) then begin
        if (median(cdata[ii[wgd[3:numgd-4]]]) le (5 * stddev(cdata[ii[wgd[3:numgd-4]]]))) then begin
          print, "WARNING: selected data for BC = " + strtrim(median(sdata[ii]), 2) + " mA is within 5 sigma of dark level!  Result may be suspect!"
          if keyword_set(includeall) then begin
            low_k = min([k, low_k])
          endif else begin
            numgd = 0
            print, "Ignoring this point... set /includeall to include suspect points."
          endelse
        endif
      endif
    endif else begin ; no valve info
      ; Do very broad smoothing, max of that should be roughly equal to mean illuminated signal
      ; If we want this value to be ~10 sigma above dark [0], then pick only points >50% of this value
      wgd = where(cdata[ii] ge max(smooth(cdata[ii],n_elements(ii)/10,/edge_trunc))/2., numgd)
      ; If this level is still too close to the dark, wgd will likely contain non-contiguous indices... warn the user.
      if (numgd ge 2) then begin
        if (total(wgd[1:*]-wgd[0:numgd-2]) ge numgd) then begin
          print, "WARNING: selected data for BC = " + strtrim(median(sdata[ii]), 2) + " mA contains non-contiguous points and is likely too close to dark level!  Result may be suspect!"
          if keyword_set(includeall) then begin
            low_k = min([k, low_k])
          endif else begin
            numgd = 0
            print, "Ignoring this point... set /includeall to include suspect points."
          endelse
        endif
      endif
    endelse
    if (numgd gt 7) then begin
      cbin[k] = median(cdata[ii[wgd[3:numgd-4]]])	; median() instead of mean()
      ecbin[k] = stddev(cdata[ii[wgd[3:numgd-4]]])/sqrt(numgd-6)
      sbin[k] = median(sdata[ii[wgd[3:numgd-4]]])
      if keyword_set(debug) then begin
        if (k eq start_k) then begin
          setplot, thick=3
          cc=rainbow(numfit+1)
          mtitle = 'Linearity: XRS-'+ch+' (FM'+strtrim(fm,2)+')'
          yrange = cbin[0]*[0.5,1.5]
          xrange = plotrange(sdata, /log)
          plot_oi, sdata[ii[wgd[3:numgd-4]]], cdata[ii[wgd[3:numgd-4]]], psym=4, xr=xrange, xs=1, yr=yrange, ys=1, xtitle='SURF BC (mA)', ytitle=ytitle, title=mtitle
        endif else $
          oplot, sdata[ii[wgd[3:numgd-4]]], cdata[ii[wgd[3:numgd-4]]], psym=4, color=cc[k]
      endif
    endif else begin
      if keyword_set(debug) then print, "No good data for BC = " + strtrim(median(sdata[ii]), 2)
      start_k += 1
    endelse
  endif
endfor

wgood = where( cbin ge 1.0 , ngood)
cbin=cbin[wgood]
sbin=sbin[wgood]
if keyword_set(debug) then begin
  if (low_k lt numfit) then begin
    oplot, sqrt(sbin[low_k] * sbin[low_k-1])*[1,1], yrange, line=2, color='00bb00'x
    xyouts, sqrt(sbin[low_k] * sbin[low_k-1])*1.05, max(yrange)*.98, color='00bb00'x, '>5!9s!3', orient=-90
  endif
;  color_complement, cc, ccc
  for i=0, ngood-1 do oplot, [sbin[i]], [cbin[i]], psym=6, symsize=2, color='0000ff'x;  ccc[i]
  for i=0, ngood-1 do errplot, sbin[i], cbin[i]-ecbin[i], cbin[i]+ecbin[i], width=1e-20, color='0000ff'x;  ccc[i]
  ans = ' '
  read, 'Next Plot ? ', ans
  if (strupcase(strmid(ans, 0, 1)) eq 'S') then stop
endif

;
;	do plot of ratio from linearity
;

refbins = indgen(5)
if (ch eq 'B1') then refbins = refbins + 2
;reflevel = mean( cbin[refbins] )
reflevel = (poly_fit(sbin[refbins], cbin[refbins], 0, measure_errors = ecbin[refbins]))[0]

ratio = cbin/reflevel
print, ' '
print, 'Ratio MIN, Mean, Max = ', min(ratio), mean(ratio), max(ratio)
mtitle = 'Linearity: XRS-'+ch+' (FM'+strtrim(fm,2)+')'
xrange = plotrange(sdata, /log)
yrange = [ min(ratio) < 0.95, max(ratio) > 1.05 ]

;  keep results: Beam Current, Counts, Errors, Ratio (in plot)
lineardata = [ [sbin], [cbin*sbin], [ecbin*sbin], [ratio] ]

plot_oi, sbin, ratio, psym=6, xr=xrange,xs=1, yrange=yrange, ys=1, symsize=2, $
	xtitle='SURF BC (mA)', ytitle='Ratio: Measurement / Reference', title=mtitle
errplot, sbin, ratio - ecbin/reflevel, ratio + ecbin/reflevel, width=1e-20

if (low_k lt numfit) then begin
  oplot, sqrt(sbin[low_k] * sbin[low_k-1])*[1,1], yrange, line=2, color='00bb00'x
  xyouts, sqrt(sbin[low_k] * sbin[low_k-1])*1.05, max(yrange)*0.98 + min(yrange)*0.02, color='00bb00'x, '>5!9s!3', orient=-90
endif

oplot, xrange, 1.02*[1,1], line=2
oplot, xrange, 0.98*[1,1], line=2

oplot, xrange, 1.01*[1,1], line=1
oplot, xrange, 0.99*[1,1], line=1

;if keyword_set(debug) then stop, 'STOP:  DEBUG exis_xrs_linearity...'

end
