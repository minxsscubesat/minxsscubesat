;+
; NAME:
;	x123_linearity
;
; PURPOSE:
;	Plot linearity data
;	Updated for Rocket X123 data read (from exis_xrs_linearity.pro)
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:
;	x123_linearity, filename, surffile, [ /debug, data=data, surfdata=surfdata, lineardata=lineardata]
;
; INPUTS:
;	channel		NO - only X123 Option:  Options are  'A1', 'A2', 'B1', 'B2'
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
;	3/29/18		Tom Woods, Bennet Schwab  Updated for Rocket X123 linearity calibrations at SURF
;+

pro x123_linearity, filename, surffile, deadtime=deadtime, data=data, debug=debug
;
;	1.  Check input parameters
;
if n_params() lt 2 or keyword_set(help) then begin
  message, /info, 'USAGE:  x123_linearity, <filename>, <surffile>, [, deadtime=deadtime, data=data, /debug ]'
  return
endif

; Check XRS channel for validity
;ch = strupcase(strmid(channel,0,2))
;if (ch ne 'B1') and (ch ne 'B2') and (ch  ne 'A1') and (ch ne 'A2') then begin
;  message, /info, 'ERROR: Invalid Channel name.  Expected A1, A2, B1, or B2.'
;  return
;endif

;
;	2.	Read the Rocket XRS-X123 and SURFER Log data
;
read_hydra_rxrs, filename, hk=hk, sci=sci, /verbose	;  get X123 Spectra in the SCI packets
fast = sci.x123_fast_count / (sci.x123_accum_time/1000.)
slow = sci.x123_slow_count / (sci.x123_accum_time/1000.)

   surfdata = read_surflog_et( surffile, debug=debug )
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

;  NOT sure about units of time for surfdata and sci !!!!!
;  convert file time (GPS seconds) into seconds of day (SOD)
;  convert from UT to EDT to be consistent with SURFER time
utoffset = 4. * 3600.D0
; special check for EST instead of default EDT
if keyword_set(est) then utoffset = 5. * 3600.D0

ydfulltime = jd2yd(gps2jd(sci.time - utoffset))
ydtime = long(ydfulltime)
myTime = (ydfulltime-ydtime) * 24.D0 * 3600.   ; seconds of day

surfbc = interpol( surfdata[isurfbc,*], surfdata[isurftime,*], myTime )

; plot,myTime-myTime[0],slow,/ylog

;
;	goodData are those data above the noise level of slow and fast
;
goodData=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) )

elements=0
sumslow=0.
sumfast=0.
sumbc=0.
count=0

for i=0, N_Elements(goodData)-2 DO BEGIN

  if (goodData[i+1]-goodData[i] eq 1) THEN BEGIN

    sumslow=sumslow+slow[goodData[i]]
    sumfast=sumfast+fast[goodData[i]]
    sumbc=sumbc+surfbc[goodData[i]]
    count=count+1

  endif else BEGIN
    sumslow=sumslow+slow[goodData[i]]
    sumfast=sumfast+fast[goodData[i]]
    sumbc=sumbc+surfbc[goodData[i]]
    count=count+1
    if elements eq 0 THEN BEGIN
      avgslow = sumslow/count
      avgfast = sumfast/count
      avgbc = sumbc/count
      avgcount = count
    endif else BEGIN
      avgslow = [avgslow, sumslow/count]
      avgfast = [avgfast, sumfast/count]
      avgbc = [avgbc, sumbc/count]
      avgcount = [avgcount, count]
    endelse
    elements=elements+1
    sumslow=0.
    sumfast=0.
    sumbc=0.
    count=0
  endelse
endfor

; exclude few points
wkeep = where( avgcount gt 5, numkeep )
avgslow = avgslow[wkeep]
avgfast = avgfast[wkeep]
avgbc = avgbc[wkeep]
avgcount = avgcount[wkeep]
elements = numkeep
print, ' '
print, 'SURF BC is from ', min(avgbc), ' to ', max(avgbc)
print, ' '

;
;	make data array
;
	data = [ [avgbc], [avgslow], [avgfast], [avgcount] ]

;
;	fit deadtime for slow and fast
;		slow is expected to be related to the peaking time
;		fast is expected to be 120 nsec
;
;	Fast = Predicted * exp( -Predicted * tau_fast )    F = P * exp(-P * t_f)
;		want Predicted calculated.   If F~P then  P ~= F * exp( F * t_f )
;	Slow = Predicted * exp( -Predicted * tau_slow )    S = P * exp(-P * t_s)
;		Substitute in P:   S ~= F * exp( -F * (t_s - t_f) )
;
tau_slow = [0.0, 0.6,1.2,2.4,4.8,9.6]	 ; 0.6, 1.2, 2.4, 4.8, 9.6 microsec standard ones
tau_fast = 0.12   ; 120 nsec
num_tau = n_elements(tau_slow)
index=0
if keyword_set(deadtime) then begin
  tau_slow[0] = deadtime
endif else begin
  print, 'Index  Tau_slow_microsec'
  print, '-----  -----------------'
  for k=1,num_tau-1 do print, k+1, tau_slow[k], format='(I4,F8.2)'
  read, 'ENTER INDEX for tau_slow : ', index
  if (index lt 1) then index=1
  if (index gt num_tau) then index=num_tau
endelse

;  range from low BC currents for averages
wnorm = where( (avgfast ge 200.) and (avgfast le 3000.), num_norm)
if (num_norm lt 2) then begin
	k1 = elements-5
	k2 = elements-3
endif else begin
	k1 = min(wnorm)
	k2 = max(wnorm)
endelse

rate_per_bc = mean(avgfast[k1:k2]) / mean(avgbc[k1:k2])
bc_range = 10.^(findgen(51)/10.-5.)
predicted = bc_range * rate_per_bc
fast_calc = predicted * exp( -predicted * tau_fast*2.D-6 )
slow_calc = predicted * exp( -predicted * tau_slow[index]*2.D-6 )
slow_calc_alt = avgfast * exp( -avgfast * (tau_slow[index] - tau_fast)*2.D-6 )

print, 'Fast / BC Calibration = ', rate_per_bc
print, ' '

;
;	make plot
;
setplot
cc=rainbow(7)

ratioslow=avgslow/avgbc
ratiofast=avgfast/avgbc
; normalize them to unity
ratioslow=ratioslow/mean(ratioslow[k1:k2])
ratiofast=ratiofast/mean(ratiofast[k1:k2])

slow_calc_alt_ratio = slow_calc_alt/avgbc
slow_calc_alt_ratio = slow_calc_alt_ratio / mean(slow_calc_alt_ratio[k1:k2])

;plot,avgbc,avgslow,psym=4,/ylog,/xlog
;plot,avgbc,avgslow/avgbc,psym=4,/xlog

plot,avgbc,ratioslow,psym=4,/nodata,/xlog,xtitle='SURF Beam Current [mA]',ytitle='Normalized Signal/BC',$
  xrange=[1e-6,2e-1],xstyle=1,yrange=[0,1.2],ystyle=1, $
  title='Tau_slow = '+string(tau_slow[index],format='(F3.1)') + ' microsec'
xyouts,(10^!x.crange[0])*2,0.6,'X123 Slow'
xyouts,(10^!x.crange[0])*2,0.75,'X123 Fast',color=cc[0]
xyouts,(10^!x.crange[0])*2,0.45,'Slow Predicted from Fast',color=cc[3]
oplot,10^!x.crange,[1,1],color=cc[1]

oplot, bc_range, fast_calc/predicted, line=3, color=cc[0]
oplot, bc_range, slow_calc/predicted, line=3
oplot, avgbc, slow_calc_alt_ratio, psym=-6, color=cc[3]

oplot,avgbc,ratioslow,psym=5
oplot,avgbc,ratiofast,psym=4,color=cc[0]

if keyword_set(debug) then stop, 'STOPPED at end of x123_linearity ...'

end
