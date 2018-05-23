;+
; NAME:
; x123_linearity
;
; PURPOSE:
; Find Tau Values for Slow and Fast count (accounting for decline in ratio of counts/beamcurrent)
; Find deltaTau - the difference between Tauslow and Taufast
; Use deltaTau to calculate the slow counts from the fast counts measured
; Compare these calculated slow count values to the measured slow counts
; Plot linearity data
; Updated for Rocket X123 data read (from x123_linearity.pro)
;
; CATEGORY:
; SURF calibration procedure
;
; CALLING SEQUENCE:
; linearity, filename, surffile, [ /debug, data=data, surfdata=surfdata, lineardata=lineardata]
;
; INPUTS:
; channel   NO - only X123 Option:  Options are  'A1', 'A2', 'B1', 'B2'
; filename  DataView Dump file of Rocket XRS MCU data
; surffile  Optional input to read SURFER log file
; itime   Optional input to specify the integration time: default is 1.0 sec
; /debug    Option to print DEBUG messages
; /rocket   Option to read rocket XRS data - default now ETU XRS GSE data
;
; OUTPUTS:
; PLOT    Showing linearity data as difference between linear fit
;
; data    DataView Dump data
; surfdata  SURFER PC log data
; lineardata  Linear data (ratio plot data)
;
; COMMON BLOCKS:
; None
;
; PROCEDURE:
;
; 1.  Check input parameters
; 2.  Pre-process the data
; 3.  Plot data versus Beam Current (BC)
;
; MODIFICATION HISTORY:
; 1/26/10   Tom Woods Original file creation
; 11/1/11   Amir Caspi  Updated to use GSE data files (for XRS FM-1)
; 3/29/18   Tom Woods, Bennet Schwab  Updated for Rocket X123 linearity calibrations at SURF
;+

pro x123_linearity, filename, surffile, deadtime=deadtime, data=data, debug=debug
;
; 1.  Check input parameters
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
; 2.  Read the Rocket XRS-X123 and SURFER Log data
;
read_hydra_rxrs, filename, hk=hk, sci=sci, /verbose ;  get X123 Spectra in the SCI packets
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
; goodData are those data above the noise level of slow and fast
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
; make data array
;
  data = [ [avgbc], [avgslow], [avgfast], [avgcount] ]

;
; fit deadtime for slow and fast
;   slow is expected to be related to the peaking time
;   fast is expected to be 120 nsec
;
; Fast = Predicted * exp( -Predicted * tau_fast )    F = P * exp(-P * t_f)
;   want Predicted calculated.   If F~P then  P ~= F * exp( F * t_f )
; Slow = Predicted * exp( -Predicted * tau_slow )    S = P * exp(-P * t_s)
;   Substitute in P:   S ~= F * exp( -F * (t_s - t_f) )
;
tau_slow = [0.0, 0.6,1.2,2.4,4.8,9.6]  ; 0.6, 1.2, 2.4, 4.8, 9.6 microsec standard ones
tau_fast = 0.12   ; 120 nsec
num_tau = n_elements(tau_slow)
index=0
if keyword_set(deadtime) then begin
  tau_slow[0] = deadtime
endif else begin
  print, 'Index  Tau_slow_microsec'
  print, '-----  -----------------'
  for k=1,num_tau-1 do print, k, tau_slow[k], format='(I4,F8.2)'
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Setting up arrays and calculating means & standard deviations
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

setplot
cc=rainbow(7)


;
; Ranges for each beam current
;
;bcrange=[1e-8,1e-6,2e-6,5e-6,1e-5,2e-5,5e-5,1e-4,2e-4,5e-4, $
;  1e-3,2e-3,5e-3,1e-2,2e-2,5e-2,1e-1,2e-1,5e-1]

bcrange=[1e-8,1.5e-6,2.5e-6,5.5e-6,1.5e-5,2.5e-5,5.5e-5,1.5e-4,2.5e-4,5.5e-4, $
  1.5e-3,2.5e-3,5.5e-3,1.5e-2,2.5e-2,1]


;
; Create an array of all the values of for the ranges of beam currents
;
smlow=[]

;
; Find data points for each range corresponding to a change in beam current
;
Smlow15=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[14]) and (surfbc lt bcrange[15]))
if smlow15[0] eq -1 then begin
  print,'no smlow15'
endif else begin
  Smlow15=Smlow15[2:n_elements(Smlow15)-2]
  smlow=[smlow,smlow15]
endelse

Smlow14=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[13]) and (surfbc lt bcrange[14]))
if smlow14[0] eq -1 then begin
  print,'no smlow14'
endif else begin
  Smlow14=Smlow14[1:n_elements(Smlow14)-2]
  smlow=[smlow,smlow14]
endelse

Smlow13=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[12]) and (surfbc lt bcrange[13]))
if smlow13[0] eq -1 then begin
  print,'no smlow13'
endif else begin
  Smlow13=Smlow13[1:n_elements(Smlow13)-2]
  smlow=[smlow,smlow13]
endelse

Smlow12=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[11]) and (surfbc lt bcrange[12]))
if smlow12[0] eq -1 then begin
  print,'no smlow12'
endif else begin
  Smlow12=Smlow12[1:n_elements(Smlow12)-2]
  smlow=[smlow,smlow12]
endelse

Smlow11=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[10]) and (surfbc lt bcrange[11]))
if smlow11[0] eq -1 then begin
  print,'no smlow11'
endif else begin
  Smlow11=Smlow11[1:n_elements(Smlow11)-2]
  smlow=[smlow,smlow11]
endelse

Smlow10=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[9]) and (surfbc lt bcrange[10]))
if smlow10[0] eq -1 then begin
  print,'no smlow10'
endif else begin
  Smlow10=Smlow10[1:n_elements(Smlow10)-2]
  smlow=[smlow,smlow10]
endelse

Smlow9=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[8]) and (surfbc lt bcrange[9]))
if smlow9[0] eq -1 then begin
  print,'no smlow9'
endif else begin
  Smlow9=Smlow9[1:n_elements(Smlow9)-2]
  smlow=[smlow,smlow9]
endelse

Smlow8=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[7]) and (surfbc lt bcrange[8]))
if smlow8[0] eq -1 then begin
  print,'no smlow8'
endif else begin
  Smlow8=Smlow8[1:n_elements(Smlow8)-2]
  smlow=[smlow,smlow8]
endelse

Smlow7=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[6]) and (surfbc lt bcrange[7]))
if smlow7[0] eq -1 then begin
  print,'no smlow7'
endif else begin
  Smlow7=Smlow7[1:n_elements(Smlow7)-2]
  smlow=[smlow,smlow7]
endelse

Smlow6=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[5]) and (surfbc lt bcrange[6]))
if smlow6[0] eq -1 then begin
  print,'no smlow6'
endif else begin
  Smlow6=Smlow6[1:n_elements(Smlow6)-2]
  smlow=[smlow,smlow6]
endelse

Smlow5=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[4]) and (surfbc lt bcrange[5]))
if smlow5[0] eq -1 then begin
  print,'no smlow5'
endif else begin
  Smlow5=Smlow5[1:n_elements(Smlow5)-2]
  smlow=[smlow,smlow5]
endelse

Smlow4=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[3]) and (surfbc lt bcrange[4]))
if smlow4[0] eq -1 then begin
  print,'no smlow4'
endif else begin
  Smlow4=Smlow4[1:n_elements(Smlow4)-2]
  smlow=[smlow,smlow4]
endelse

Smlow3=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[2]) and (surfbc lt bcrange[3]))
if smlow3[0] eq -1 then begin
  print,'no smlow3'
endif else begin
  Smlow3=Smlow3[1:n_elements(Smlow3)-2]
  smlow=[smlow,smlow3]
endelse

Smlow2=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
  and (surfbc gt bcrange[1]) and (surfbc lt bcrange[2]))
if smlow2[0] eq -1 then begin
  print,'no smlow2'
endif else begin
  Smlow2=Smlow2[1:n_elements(Smlow2)-2]
  smlow=[smlow,smlow2]
endelse

Smlow1=where( (slow gt (3.*median(slow))) and (fast gt (3.*median(fast))) $
   and (surfbc gt bcrange[0]) and (surfbc lt bcrange[1]))
if smlow1[0] eq -1 then begin
   print,'no smlow1'
endif else begin
  Smlow1=Smlow1[1:n_elements(Smlow1)-2]
  smlow=[smlow,smlow1]
endelse


; Find where the constant noise floor for dark (no beam current but still counts)
; darkval = noise floor for slow counts
; darkvalf = noise floor for fast counts
;
dark = where(surfbc lt 1e-7)

darkval = mean(slow[dark])
darkvalf=mean(fast[dark])


;
; Find Mean of Slow and Fast Values with subtracting off dark
; Make an array with means in each range of beam currents
;
meanslow=[mean(slow[Smlow1]-darkval),mean(slow[Smlow2]-darkval),$
  mean(slow[Smlow3]-darkval),mean(slow[Smlow4]-darkval),$
  mean(slow[Smlow5]-darkval),mean(slow[Smlow6]-darkval),$
  mean(slow[Smlow7]-darkval),mean(slow[Smlow8]-darkval)]
  
meanfast=[mean(fast[Smlow1]-darkvalf),mean(fast[Smlow2]-darkvalf),$
  mean(fast[Smlow3]-darkvalf),mean(fast[Smlow4]-darkvalf),$
  mean(fast[Smlow5]-darkvalf),mean(fast[Smlow6]-darkvalf),$
  mean(fast[Smlow7]-darkvalf),mean(fast[Smlow8]-darkvalf)]


;
; Find Mean of beam current for each of these values and make array
;
meanbc=[mean(surfbc[Smlow1]),mean(surfbc[Smlow2]),$
  mean(surfbc[Smlow3]),mean(surfbc[Smlow4]),$
  mean(surfbc[Smlow5]),mean(surfbc[Smlow6]),$
  mean(surfbc[Smlow7]),mean(surfbc[Smlow8])]


;
; Make array of the ratio of slow/fast to beam current for each range of beam currents
;
meanratio=[mean((slow[Smlow1]-darkval)/surfbc[Smlow1]),mean((slow[Smlow2]-darkval)/surfbc[Smlow2]),$
  mean((slow[Smlow3]-darkval)/surfbc[Smlow3]),mean((slow[Smlow4]-darkval)/surfbc[Smlow4]),$
  mean((slow[Smlow5]-darkval)/surfbc[Smlow5]),mean((slow[Smlow6]-darkval)/surfbc[Smlow6]),$
  mean((slow[Smlow7]-darkval)/surfbc[Smlow7]),mean((slow[Smlow8]-darkval)/surfbc[Smlow8])]
  
meanratiofast=[mean((fast[Smlow1]-darkvalf)/surfbc[Smlow1]),mean((fast[Smlow2]-darkvalf)/surfbc[Smlow2]),$
  mean((fast[Smlow3]-darkvalf)/surfbc[Smlow3]),mean((fast[Smlow4]-darkvalf)/surfbc[Smlow4]),$
  mean((fast[Smlow5]-darkvalf)/surfbc[Smlow5]),mean((fast[Smlow6]-darkvalf)/surfbc[Smlow6]),$
  mean((fast[Smlow7]-darkvalf)/surfbc[Smlow7]),mean((fast[Smlow8]-darkvalf)/surfbc[Smlow8])]


;
; Make array of the standard deviation of slow/fast to beam current for each range of beam currents
;
stddevratio=[stddev((slow[Smlow1]-darkval)/surfbc[Smlow1]),stddev((slow[Smlow2]-darkval)/surfbc[Smlow2]),$
  stddev((slow[Smlow3]-darkval)/surfbc[Smlow3]),stddev((slow[Smlow4]-darkval)/surfbc[Smlow4]),$
  stddev((slow[Smlow5]-darkval)/surfbc[Smlow5]),stddev((slow[Smlow6]-darkval)/surfbc[Smlow6]),$
  stddev((slow[Smlow7]-darkval)/surfbc[Smlow7]),stddev((slow[Smlow8]-darkval)/surfbc[Smlow8])]

stddevratiofast=[stddev((fast[Smlow1]-darkvalf)/surfbc[Smlow1]),stddev((fast[Smlow2]-darkvalf)/surfbc[Smlow2]),$
  stddev((fast[Smlow3]-darkvalf)/surfbc[Smlow3]),stddev((fast[Smlow4]-darkvalf)/surfbc[Smlow4]),$
  stddev((fast[Smlow5]-darkvalf)/surfbc[Smlow5]),stddev((fast[Smlow6]-darkvalf)/surfbc[Smlow6]),$
  stddev((fast[Smlow7]-darkvalf)/surfbc[Smlow7]),stddev((fast[Smlow8]-darkvalf)/surfbc[Smlow8])]


;
; Find weighted mean for slow/fast (numerator and denomenator, then putting them togeter)
;
weightedmeannum=meanratio[3]/stddevratio[3]+meanratio[4]/stddevratio[4]+meanratio[5]/stddevratio[5] 
weightedmeanden=1/stddevratio[3]+1/stddevratio[4]+1/stddevratio[5]
weightedmean=weightedmeannum/weightedmeanden

weightedmeannumfast=meanratiofast[3]/stddevratiofast[3]+meanratiofast[4]/stddevratiofast[4]+meanratiofast[5]/stddevratiofast[5]
weightedmeandenfast=1/stddevratiofast[3]+1/stddevratiofast[4]+1/stddevratiofast[5]
weightedmeanfast=weightedmeannumfast/weightedmeandenfast

;
;;
;; Create an array of all the values of for the ranges of beam currents
;;
;smlow=[smlow15,smlow14,smlow13,smlow12,smlow11,smlow10,smlow9,smlow8,$
;  smlow7,smlow6,smlow5,smlow4,smlow3,smlow2,smlow1]


;
; Create one array with the standard deviation values corresponding to each value in smlow array
;
stddevarr=[]
stddevarrf=[]

for i=0,n_elements(smlow1)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow1]-darkval)/surfbc[Smlow1])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow1]-darkvalf)/surfbc[Smlow1])]
endfor

for i=0,n_elements(smlow2)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow2]-darkval)/surfbc[Smlow2])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow2]-darkvalf)/surfbc[Smlow2])]
endfor

for i=0,n_elements(smlow3)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow3]-darkval)/surfbc[Smlow3])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow3]-darkvalf)/surfbc[Smlow3])]
endfor

for i=0,n_elements(smlow4)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow4]-darkval)/surfbc[Smlow4])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow4]-darkvalf)/surfbc[Smlow4])]
endfor

for i=0,n_elements(smlow5)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow5]-darkval)/surfbc[Smlow5])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow5]-darkvalf)/surfbc[Smlow5])]
endfor

for i=0,n_elements(smlow6)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow6]-darkval)/surfbc[Smlow6])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow6]-darkvalf)/surfbc[Smlow6])]
endfor

for i=0,n_elements(smlow7)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow7]-darkval)/surfbc[Smlow7])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow7]-darkvalf)/surfbc[Smlow7])]
endfor

for i=0,n_elements(smlow8)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow8]-darkval)/surfbc[Smlow8])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow8]-darkvalf)/surfbc[Smlow8])]
endfor

for i=0,n_elements(smlow9)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow9]-darkval)/surfbc[Smlow9])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow9]-darkvalf)/surfbc[Smlow9])]
endfor

for i=0,n_elements(smlow10)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow10]-darkval)/surfbc[Smlow10])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow10]-darkvalf)/surfbc[Smlow10])]
endfor

for i=0,n_elements(smlow11)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow11]-darkval)/surfbc[Smlow11])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow11]-darkvalf)/surfbc[Smlow11])]
endfor

for i=0,n_elements(smlow12)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow12]-darkval)/surfbc[Smlow12])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow12]-darkvalf)/surfbc[Smlow12])]
endfor

for i=0,n_elements(smlow13)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow13]-darkval)/surfbc[Smlow13])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow13]-darkvalf)/surfbc[Smlow13])]
endfor

for i=0,n_elements(smlow14)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow14]-darkval)/surfbc[Smlow14])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow14]-darkvalf)/surfbc[Smlow14])]
endfor

for i=0,n_elements(smlow15)-1 do begin
  stddevarr=[stddevarr,stddev((slow[Smlow15]-darkval)/surfbc[Smlow15])]
  stddevarrf=[stddevarrf,stddev((fast[Smlow15]-darkvalf)/surfbc[Smlow15])]
endfor







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Calculating TauSlow
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Create an array for slow tau values
;
tauarrays=(tau_slow[index]-1.0)*1.0e-6-(0.0000004e-07)+findgen(4001)/2.0e9


;
; Create an array that will be filled with the Chi-Squared values
;   which are calculated by iterating through the slow tau array (tauarrays)
;   then used to find the tau value that gives the minimum Chi-Squared value (and best fit)
;
chisq=[]

for j=0, N_elements(tauarrays)-1 do begin
  chisqnum=0
  chisqden=0
  scalc=(surfbc[smlow]*weightedmean)*Exp(-2*surfbc[smlow]*weightedmean*tauarrays[j])
  for i=0, N_elements(smlow)-1 do begin
    chisqnum=chisqnum+((slow[smlow[i]]-darkval-scalc[i])^2/(stddevarr[i])^2)
    chisqden=chisqden+(1/stddevarr[i])^2
  endfor
  chisq=[chisq,chisqnum/chisqden]
  
endfor

;
; Find the place in chisq array where Chi-Squared is a minimum
;
chisqmin=where(chisq eq min(chisq))
tauslow=tauarrays[chisqmin[0]]


;
; Plot slow counts (minus dark) vs. surf beam current
; Overplot the calculated slow count from the weighted mean and tauslow
;
plot,surfbc[smlow],slow[smlow]-darkval,/xlog,/ylog,psym=1,yrange=[10,1e6],xrange=[1e-8,1]
oplot,surfbc[smlow],(surfbc[smlow]*weightedmean)*Exp(-2*surfbc[smlow]*weightedmean*tauslow)


print,"Lowest chi squared value for slow counts was found to be",min(chisq),$
  "   for TauSlow value of",tauslow

print," "



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Calculating TauFast
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Plot fast counts (minus dark) vs. surf beam current
;
plot,surfbc[smlow],fast[smlow]-darkvalf,/xlog,/ylog,psym=1


;
; Create an array for fast tau values
;
tauarrayf=(index-1.0)*1.0e-8+findgen(9001)/1.0e11

;
; Create an array that will be filled with the fast Chi-Squared values
;   which are calculated by iterating through the fast tau array (tauarrayf)
;   then used to find the tau value that gives the minimum Chi-Squared value (and best fit)
;

if index eq 2 then datathreshold = 219

chisqf=[]

for j=0, N_elements(tauarrayf)-1 do begin
  chisqnumf=0
  chisqdenf=0
  fcalc=(surfbc[smlow]*weightedmeanfast)*Exp(-2*surfbc[smlow]*weightedmeanfast*tauarrayf[j])
  for i=0, datathreshold do begin
    chisqnumf=chisqnumf+((fast[smlow[i]]-darkvalf-fcalc[i])^2/(stddevarrf[i])^2)
    chisqdenf=chisqdenf+(1/stddevarrf[i])^2
  endfor
  chisqf=[chisqf,chisqnumf/chisqdenf]

endfor


;
; Find the place in chisq array where Chi-Squared is a minimum
;
chisqminf=where(chisqf eq min(chisqf))
taufast=tauarrayf[chisqminf[0]]


;
; Overplot the calculated slow count from the weighted mean and tauslow
;
oplot,surfbc[smlow[0:datathreshold]],(surfbc[smlow[0:datathreshold]]*weightedmeanfast)*Exp(-2*surfbc[smlow[0:datathreshold]]*weightedmeanfast*taufast)


print,"Lowest chi squared value for fast counts was found to be",min(chisqf),$
  "   for TauFast value of",taufast

print," "




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Using DeltaTau to calculate Slow counts
; 
; (DeltaTau = TauSlow-TauFast)
; 
; Then comparing measured slow counts with calculated slow counts
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;
; Delta Tau
;
deltatau=tauslow-taufast


;
; Calculated Slow counts from measured fast counts and DeltaTau value
;
sdelta=(fast[smlow]-darkvalf)*Exp(-2*(fast[smlow]-darkvalf)*deltatau)


;
; Plot measured slow count values in black and calculated slow count values in red
;
plot,surfbc[smlow],slow[smlow]-darkval,/xlog,/ylog,psym=1,yrange=[10,1e6],xrange=[1e-8,1]
oplot,surfbc[smlow],sdelta,psym=1,color=cc[0]

print," "


chisqd=[]

for j=0, N_elements(tauarrays)-1 do begin
  chisqnumd=0
  chisqdend=0
  sdelta2=(fast[smlow]-darkvalf)*Exp(-2*(fast[smlow]-darkvalf)*tauarrays[j])
  for i=52, 219 do begin
    chisqnumd=chisqnumd+((slow[smlow[i]]-darkval-sdelta2[i])^2)
    chisqdend=chisqdend+(1)
  endfor
  chisqd=[chisqd,chisqnumd/chisqdend]

endfor

chisqmind=where(chisqd eq min(chisqd))
taud=tauarrays[chisqmind[0]]

oplot,surfbc[smlow[0:datathreshold]],(fast[smlow[0:datathreshold]]-darkvalf)*Exp(-2*(fast[smlow[0:datathreshold]]-darkvalf)*taud)

print,taud,chisqmind

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Rest of Dr. Woods's Code
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


print, 'Fast / BC Calibration = ', rate_per_bc
print, ' '

;
; make plot
;


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



;
; For post-surf analysis
;
plot,surfbc[goodData],slow[goodData],/xlog,/ylog,psym=1



if keyword_set(debug) then stop, 'STOPPED at end of x123_linearity ...'

end
