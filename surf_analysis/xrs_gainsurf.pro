;+
; NAME:
;	xrs_gainsurf
;
; PURPOSE:
;	Extract out CAL ramp data from running DataView's Gain Full Test script
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	xrs_gainsurf [ , filename, surffile, itime=itime, /debug, result=result, data=data, surfdata=surfdata]
;
; INPUTS:
;	filename	DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	/debug		Option to print DEBUG messages
;	/rocket		Option to read rocket XRS data using plotxrs.pro: Default is ETU XRS data using plot_xrs_gse.pro
;
; OUTPUTS:  
;	PLOT		Showing FOV map data as Alpha and Beta scans
;
;	data		DataView Dump data
;	surfdata	SURFER PC log data
;	result		Results for this temperature data set
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data
;	3.  Print the median of the high signal
;
; MODIFICATION HISTORY:
;	1/28/10		Tom Woods	Original file creation
;	9/23/10		Tom Woods	Updated for ETU-XRS calibrations
;
;+

pro xrs_gainsurf, filename, surffile, itime=itime, rocket=rocket, $
						result=result, data=data, surfdata=surfdata, debug=debug
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_gainsurf [ , filename, surffile, itime=itime, /debug, data=data, surfdata=surfdata]'
  return
endif

if (n_params() lt 1) then begin
  filename =' '
endif

if (n_params() lt 2) then begin
  surffile=' '
endif

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

if not keyword_set(rocket) then begin
  ;  define XRS A file and XRS B file
  sp = strpos( filename, 'xrs' )
  if (sp lt 0) then begin
    print, 'ERROR: need XRS file (either A or B).'
    return
  endif
  afile = strmid(filename,0,sp+3) + 'a' + strmid(filename,sp+4,strlen(filename)-sp-4)
  bfile = strmid(filename,0,sp+3) + 'b' + strmid(filename,sp+4,strlen(filename)-sp-4)
endif

;
;	2.	Read/Plot the data using plotxrs.pro for each channel
;	3.  Print the median of the high signal
;		Order of data read:  A1, A2, B1, B2
;
setplot
cc=rainbow(7)
ans = ' '

reflimit = 0.1	; define limit to search for result
reflow = 1. - reflimit
refhigh = 1. + reflimit

ch = 'A1'
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, surfdata=surfdata
 endelse
endif else begin
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, afile, surffile, itime=integtime, data=data, surfdata=surfdata, /debug
 endif else begin
  plot_xrs_gse, ch, afile, surffile, itime=integtime, data=data, surfdata=surfdata
 endelse
endelse

;  make save set file name
sfile = 'gain_' + strtrim(long(median(data.temp1)),2) + 'C_' 
if keyword_set(rocket) then sfile += 'rxrs' else sfile += 'etu_xrs'
sfile += '.sav'

tempstruct = { time: 0.0D0, signal: 0.0, temp: 0.0 }
result = replicate(tempstruct,12)	; make array of result for A1, B1, A2 + 4 QD, B2 + 4 QD
icha1 = 0L
ichb1 = 1L
icha2 = 2L
ichb2 = 7L

ich = icha1 ; A1 index will be used next

temp = max( data[10:*].rawcnt, wmax )
wmax+=10L
ref = data[wmax].signal
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)), numgd )
surfref = max(data[wgd].surfbc) / 2.
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)) $
	and (data.surfbc gt surfref), numgd )
if (numgd gt 2) then begin
  result[ich].time = median(data[wgd].time)
  result[ich].signal = median(data[wgd].signal)
  result[ich].temp = median(data[wgd].temp1)  
  print, ' '
  print, '***** ', ch, ' Median = ', strtrim(median(data[wgd].signal), 2), '  fA/mA'
  tdata = data.time-data[0].time
  plot, tdata, data.signal, xtitle='Time', ytitle=ch+' Signal (fA/mA)', yr=[0,ref*refhigh]
  oplot, tdata[wgd], data[wgd].signal, psym=4, color=cc[3]
  oplot, tdata, data.surfbc*ref/max(data[wgd].surfbc), color=cc[0]
  if keyword_set(debug) then stop, 'STOP: check out results for ' + ch else read, 'Next Plot ? ', ans
endif else begin
  stop, 'STOP: did not find any data for '+ch
endelse

ch = 'A2'
ich=icha2
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, quaddata=quad, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, quaddata=quad
 endelse
endif else begin
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, bfile, surffile, itime=integtime, data=data, quaddata=quad, /debug
 endif else begin
  plot_xrs_gse, ch, bfile, surffile, itime=integtime, data=data, quaddata=quad
 endelse
endelse

temp = max( data[10:*].rawcnt, wmax )
wmax+=10L
ref = data[wmax].signal
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)), numgd )
surfref = max(data[wgd].surfbc) / 2.
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)) $
	and (data.surfbc gt surfref), numgd )
if (numgd gt 2) then begin
  result[ich].time = median(data[wgd].time)
  result[ich].signal = median(data[wgd].signal)
  result[ich].temp = median(data[wgd].temp1)  
  print, ' '
  print, '***** ', ch, ' Median = ', strtrim(median(data[wgd].signal), 2), '  fA/mA'
  for j=0,3 do begin
    print, '  *** Q', strtrim(j+1,2), ' Median = ', strtrim(median(quad[wgd].signal[j]), 2), '  fA/mA'
    result[ich+j+1].time = result[ich].time
    result[ich+j+1].signal = median(quad[wgd].signal[j])
    result[ich+j+1].temp = result[ich].temp  
  endfor
  tdata = data.time-data[0].time
  plot, tdata, data.signal, xtitle='Time', ytitle=ch+' Signal (fA/mA)', yr=[0,ref*refhigh]
  oplot, tdata[wgd], data[wgd].signal, psym=4, color=cc[3]
  oplot, tdata, data.surfbc*ref/max(data[wgd].surfbc), color=cc[0]
  if keyword_set(debug) then stop, 'STOP: check out results for ' + ch else read, 'Next Plot ? ', ans
endif else begin
  stop, 'STOP: did not find any data for '+ch
endelse

ch = 'B1'
ich=ichb1
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data
 endelse
endif else begin
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, bfile, surffile, itime=integtime, data=data, /debug
 endif else begin
  plot_xrs_gse, ch, bfile, surffile, itime=integtime, data=data
 endelse
endelse

temp = max( data[10:*].rawcnt, wmax )
wmax+=10L
ref = data[wmax].signal
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)), numgd )
surfref = max(data[wgd].surfbc) / 2.
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)) $
	and (data.surfbc gt surfref), numgd )
if (numgd gt 2) then begin
  result[ich].time = median(data[wgd].time)
  result[ich].signal = median(data[wgd].signal)
  result[ich].temp = median(data[wgd].temp1)  
  print, ' '
  print, '***** ', ch, ' Median = ', strtrim(median(data[wgd].signal), 2), '  fA/mA'
  tdata = data.time-data[0].time
  plot, tdata, data.signal, xtitle='Time', ytitle=ch+' Signal (fA/mA)', yr=[0,ref*refhigh]
  oplot, tdata[wgd], data[wgd].signal, psym=4, color=cc[3]
  oplot, tdata, data.surfbc*ref/max(data[wgd].surfbc), color=cc[0]
  if keyword_set(debug) then stop, 'STOP: check out results for ' + ch else read, 'Next Plot ? ', ans
endif else begin
  stop, 'STOP: did not find any data for '+ch
endelse

ch = 'B2'
ich=ichb2
if keyword_set(rocket) then begin
 if keyword_set(debug) then begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, quaddata=quad, /debug
 endif else begin
  plotxrs, ch, filename, surffile, itime=integtime, data=data, quaddata=quad
 endelse
endif else begin
 if keyword_set(debug) then begin
  plot_xrs_gse, ch, afile, surffile, itime=integtime, data=data, quaddata=quad, /debug
 endif else begin
  plot_xrs_gse, ch, afile, surffile, itime=integtime, data=data, quaddata=quad
 endelse
endelse

temp = max( data[10:*].rawcnt, wmax )
wmax+=10L
ref = data[wmax].signal
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)), numgd )
surfref = max(data[wgd].surfbc) / 2.
wgd = where( (data.signal ge (ref*reflow)) and (data.signal le (ref*refhigh)) $
	and (data.surfbc gt surfref), numgd )
if (numgd gt 2) then begin
  result[ich].time = median(data[wgd].time)
  result[ich].signal = median(data[wgd].signal)
  result[ich].temp = median(data[wgd].temp1)  
  print, ' '
  print, '***** ', ch, ' Median = ', strtrim(median(data[wgd].signal), 2), '  fA/mA'
  for j=0,3 do begin
    print, '  *** Q', strtrim(j+1,2), ' Median = ', strtrim(median(quad[wgd].signal[j]), 2), '  fA/mA'
    result[ich+j+1].time = result[ich].time
    result[ich+j+1].signal = median(quad[wgd].signal[j])
    result[ich+j+1].temp = result[ich].temp  
  endfor
  tdata = data.time-data[0].time
  plot, tdata, data.signal, xtitle='Time', ytitle=ch+' Signal (fA/mA)', yr=[0,ref*refhigh]
  oplot, tdata[wgd], data[wgd].signal, psym=4, color=cc[3]
  oplot, tdata, data.surfbc*ref/max(data[wgd].surfbc), color=cc[0]
  if keyword_set(debug) then stop, 'STOP: check out results for ' + ch  ;  else read, 'Next Plot ? ', ans
endif else begin
  stop, 'STOP: did not find any data for '+ch
endelse

print, 'Saving "result" in ', sfile
save, result, file=sfile

if keyword_set(debug) then begin
   stop, 'DEBUG at end of xrs_gainsurf...'
endif

end
