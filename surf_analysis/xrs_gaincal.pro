;+
; NAME:
;	xrs_gaincal
;
; PURPOSE:
;	Extract out CAL ramp data from running DataView's Gain Full Test script
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	xrs_gaincal, [ filename, /debug, data=data, caldata=caldata]
;
; INPUTS:
;	channel		Options are  'A1', 'A2', 'B1', 'B2'
;	filename	DataView Dump file of Rocket XRS MCU data
;	/debug		Option to print DEBUG messages
;
; OUTPUTS:  
;	PLOT		Showing FOV map data as Alpha and Beta scans
;
;	data		DataView Dump data structure
;	caldata		CAL ramp data structure
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data using read_rxrs.pro
;	3.  Extract out CAL ramp data
;		Save the CAL data into file and also return as data structure
;		Format:  dTime Ch# RampStart RampEnd RampPeriod RampNum DarkPre DarkPost DarkStdDev SignalTotal SignalStdDev
;
; MODIFICATION HISTORY:
;	1/28/10		Tom Woods	Original file creation
;
;+

pro xrs_gaincal, filename, debug=debug, data=data, surfdata=surfdata
;
;	1.  Check input parameters
;
data = -1L
if n_params() lt 1 then begin
  print, 'Usage:  xrs_gaincal [ , filename, /debug, data=data, caldata=caldata]'
  return
endif

if (n_params() lt 1) then begin
  filename =' '
endif

;  default integtime to read the data file
integtime = 1.0

;
;	2.	Read/Plot the data using read_rxrs.pro
;
if keyword_set( debug ) then  data = read_rxrs( filename, /debug ) $
else  data = read_rxrs( filename )

;
;	3.  Extract out CAL ramp data
;		Save the CAL data into file and also return as data structure
;		Format:  dTime Ch# RampStart RampEnd RampPeriod RampNum DarkPre DarkPost DarkStdDev SignalTotal SignalStdDev
;
pslash = strpos( filename, '/', /reverse_search )
if (pslash gt 0) then fileshort = strmid( filename, pslash+1, strlen(filename)-pslash-1) $
else fileshort = filename

dtime=data.time-data[0].time     
w1=where(data.type eq 1 and data.value[0] gt 0, num1)	; Detector-1
w2=where(data.type eq 2 and data.value[0] gt 0, num2)	; Detector-2
w3=where(data.type eq 3, num3)							; Analog Monitors
w4=where(data.type eq 4, num4)  						; DAC1 settings
num_data = n_elements(data)

num_cal = 0L

if (num4 lt 2) then begin
  print, 'ERROR:  this file does not have any CAL Ramp data (no DAC1 packets)'
  return
endif

tempcal = { time: 0.D0, cal: 0.0, signal: fltarr(12), cal1dn: 0L, cal2dn: 0L, $
			dark: fltarr(12), int_time: 0.0 }

;  convert file time (GPS seconds) into seconds of day (SOD)
;  also convert from UT to EST to be consistent with SURFER time
utoffset = 5. * 3600.D0
ydfulltime = jd2yd(gps2jd(data.time - utoffset))
ydtime = long(ydfulltime)
sectime = (ydfulltime-ydtime) * 24.D0 * 3600.
zerotime = sectime - sectime[0]

;
;	process data for each ASIC
;		use DAC data to determine start and stop times for CAL Ramps (ramp time > 900)
;		get integtime and clean (only allow 1, 3, or 9 sec values)
;		parse into 1-sec and 3-sec and 9-sec results
;		isolate levels into 5 unique levels
;

; extract CAL ramp times
wcal = where( data[w4].raw[1] ge 900, numcal )
if (numcal lt 10) then begin
  print, 'ERROR:  this file does not have any CAL Ramp data (no DAC1 packets)'
  return
endif
acal = dblarr(4, numcal)   ; 0: time, 1: DACstart, 2: DACend, 3: DACperiod
acal[0,*] = zerotime[w4[wcal]]
acal[1,*] = data[w4[wcal-1]].value[0]  ; start is the DAC1 before the ramp end
acal[2,*] = data[w4[wcal]].value[0]
acal[3,*] = data[w4[wcal]].value[1]

gditimes = [1, 3, 9]
ngdtimes = n_elements(gditimes)

;		Format:  dTime Ch# RampStart RampEnd RampPeriod RampNum DarkPre DarkPost DarkStdDev SignalTotal SignalStdDev
tempcal = { integtime: 0.0, chnum: 0, rampstart: 0.0, rampend: 0.0, ramptime: 0.0, rampnum: 0, $
		darkpre: 0.0, darkpost: 0.0, darkdev: 0.0, signal: 0.0, signaldev: 0.0 }
tempcalref = tempcal
calcnt = 0L

;  define dark limit
darklimit = 50. * gditimes

setplot
cc=rainbow(7)

for k=0,1 do begin
  if (k eq 0) then begin
    wa = w1 
    ch1 = 1
    if keyword_set(debug) then print, '***** ASIC-A'
  endif else begin
    wa = w2
    ch1 = 7
    if keyword_set(debug) then print, '***** ASIC-B'
  endelse
  
  ;
  ;  extract integration times and clean up 3-sec spikes
  ;
  integtime = data[wa].raw[0] / (data[wa].value[0] > 0.1)
  itshift2a = shift(integtime,-2)
  itshift2b = shift(integtime,2)
  wbadit = where( (integtime eq 3) and (itshift2a eq 1) and (itshift2b eq 1), numbadit)
  if (numbadit gt 0) then begin
    orgit = integtime
    integtime[wbadit] = 1.0
  endif
  
  ;  do analysis for each gditimes[]
  for j=0,ngdtimes-1 do begin
    wgd = where(integtime eq gditimes[j], numgd)
    if keyword_set(debug) then print, '******* Integration Time = ', strtrim(gditimes[j],2), ', n=',strtrim(numgd,2)
    if (numgd gt 2) then begin
      ;  tag each integration with being dark or CAL ramp
      gd = data[wa[wgd]]
      gdindex = indgen(numgd)
      gdtime = zerotime[wa[wgd]]
      gdtype = intarr(numgd) - 1  ; negative if not cal, index into acal otherwise
      tlo = gditimes[j] - 1.5
      thi = gditimes[j] + 2.5
      for i=0,numcal-1 do begin
        tdiff = gdtime - acal[0,i]
        ww = where( (tdiff ge tlo) and (tdiff le thi), nww )
        if (nww gt 0) then begin
          ; sometimes have to use the next one in line if doing 1-sec integrations
          if (gdtype[ww[0]] ge 0) and (nww gt 1) then gdtype[ww[1]] = i else gdtype[ww[0]] = i
        endif
      endfor
      ;  identify dark data (will need to exclude high/low points though)
      wd = where(gdtype lt 0, numd)
      ;  sort the CAL by ramp level and do averages
      wc = where(gdtype ge 0, numc)
      if (numc le 2) and keyword_set(debug) then begin
        print, '********* WARNING: no CAL data for ',strtrim(gditimes[j],2), '-sec'
      endif
      
      if (numc gt 2) then begin
        timelimit = gditimes[j] * 3.		; time limit for breaking up average
        climit = 10./1023.	; in Volts (not DN)
        i1 = 0
        while (i1 lt numc) do begin
          clevel = acal[1,gdtype[wc[i1]]]
          for i2=i1,numc-1 do begin
            if (abs(acal[1,gdtype[wc[i2]]]-clevel) gt climit) then break
          endfor
          if (i2 ge numc) then i2 = numc-1 else i2=i2-1
          
          if keyword_set(debug) then $
             print, '********* ',strtrim(gditimes[j],2), '-sec, DAC=',strtrim(clevel,2),', n=',strtrim(i2-i1+1,2), $
             		', tz=',strtrim(acal[0,gdtype[wc[i1]]],2)
          
          ;  identify time for pre-dark
          if (i1 eq 0) then ta = gdtime[0] else ta = acal[0,gdtype[wc[i1-1]]]
          tb = acal[0,gdtype[wc[i1]]]
          wpre = where( (gdtime gt ta) and (gdtime lt tb) and (gdtype lt 0), numpre )
          if (numpre gt 0) then xmin = min(gdtime[wpre]) else xmin = 0.
          
          ;  identify time for post-dark
          ta = acal[0,gdtype[wc[i2]]]
          if (i2 ge (numc-1)) then tb = gdtime[numgd-1] else tb = acal[0,gdtype[wc[i2+1]]]
          wpost = where( (gdtime gt ta) and (gdtime lt tb) and (gdtype lt 0), numpost )
          if (numpost gt 0) then xmax = max(gdtime[wpost]) else xmax = 1000.

          ;  identify time for CAL ramp
          wcal = where( (gdtime ge acal[0,gdtype[wc[i1]]]) and (gdtime le acal[0,gdtype[wc[i2]]]) and (gdtype ge 0), ncal )
     
		  ;  
		  ;  fill in values for each channel
		  ;      tempcal = { integtime: 0.0, chnum: 0, rampstart: 0.0, rampend: 0.0, ramptime: 0.0, rampnum: 0, $
		  ;      darkpre: 0.0, darkpost: 0.0, signal: 0.0, signaldev: 0.0 }
		  ;
		  tempcal.integtime = gditimes[j]
		  tempcal.rampstart = mean( acal[1,gdtype[wc[i1:i2]]] )
		  tempcal.rampend = mean( acal[2,gdtype[wc[i1:i2]]] )
		  tempcal.ramptime = mean( acal[3,gdtype[wc[i1:i2]]] )
		  tempcal.rampnum = i2-i1+1
		  
		  
		  for nch=0,5 do begin
		    tempcal.chnum = ch1 + nch
		    
		    doPlot = 0
		    if (nch eq 0) and keyword_set(debug) and (doPlot ne 0) then begin
		      plot, gdtime, gd.raw[nch], xrange=[xmin,xmax], psym=4
		      if (numpre gt 1) then oplot, gdtime[wpre], gd[wpre].raw[0], color=cc[4], psym=4
		      if (numpost gt 1) then oplot, gdtime[wpost], gd[wpost].raw[0], color=cc[0], psym=4
		      if (ncal gt 1) then oplot, gdtime[wcal], gd[wcal].raw[0], color=cc[3], psym=6
		    endif
		    
		    ;  get Dark-Pre
		    tempcal.darkpre = 0.0
		    predev = 0.0
		    if (numpre gt 2) then begin
		      mdark = median( gd[wpre].raw[nch] )
		      wwdark = where( (gd[wpre].raw[nch] ge (mdark-darklimit[j])) and (gd[wpre].raw[nch] le (mdark+darklimit[j])), ndark )
		      if (ndark gt 1) then tempcal.darkpre = mean( gd[wpre[wwdark]].raw[nch] )
		      if (ndark gt 1) then predev = stddev( gd[wpre[wwdark]].raw[nch] )
		    endif
		    
		    ;  get Dark-Post
		    tempcal.darkpost = 0.0
		    postdev = 0.0
		    if (numpost gt 2) then begin
		      mdark = median( gd[wpost].raw[nch] )
		      wwdark = where( (gd[wpost].raw[nch] ge (mdark-darklimit[j])) and (gd[wpost].raw[nch] le (mdark+darklimit[j])), ndark )
		      if (ndark gt 1) then tempcal.darkpost = mean( gd[wpost[wwdark]].raw[nch] )
		      if (ndark gt 1) then postdev = stddev( gd[wpost[wwdark]].raw[nch] )
		    endif
		    
		    tempcal.darkdev = 0.0
		    if (predev ne 0) and (postdev ne 0) then tempcal.darkdev = (predev+postdev)/2. $
		    else if (predev ne 0) then tempcal.darkdev = predev $
		    else if (postdev ne 0) then tempcal.darkdev = postdev
		    
		    ;  get Signal
		    tempcal.signal = 0.0
		    tempcal.signaldev = 0.0
		    if (ncal gt 2) then begin
		      mcal = median( gd[wcal].raw[nch] )
		      wwcal2 = where( (gd[wcal].raw[nch] ge (mcal-darklimit[j]*3)) and (gd[wcal].raw[nch] le (mcal+darklimit[j]*3)), ncal2 )
		      if (ncal2 gt 2) then begin
		        ; ignore first one as have ramp up effect
		        tempcal.signal = mean( gd[wcal[wwcal2[1:*]]].raw[nch] )	
		        tempcal.signaldev = stddev( gd[wcal[wwcal2[1:*]]].raw[nch] )	
		      endif    
		    endif
		    
		    if (calcnt eq 0) then caldata=tempcal else caldata=[caldata,tempcal]
		    calcnt = calcnt + 1
		  endfor
		  ; start on next cal ramp group
          i1 = i2 + 1  
        endwhile
      endif
    endif
  endfor
endfor

;
;  print results to screen and also to file
;
savefile = fileshort + '_RESULTS.txt'
print, ' '
print, 'Saving Gain Cal results in ', savefile
openw,lun,savefile,/get_lun

;		Format:  dTime Ch# RampStart RampEnd RampPeriod RampNum DarkPre DarkPost DarkStdDev SignalTotal SignalStdDev
;  		tempcal = { integtime: 0.0, chnum: 0, rampstart: 0.0, rampend: 0.0, ramptime: 0.0, rampnum: 0, $
;				darkpre: 0.0, darkpost: 0.0, darkdev: 0.0, signal: 0.0, signaldev: 0.0 }
;
format = '(2I5,3F8.3,I5,5F10.2)'
hdr1 = 'iTime Ch-No R-Start  R-End  R-Time Cycles Dark-Pre Dark-Post  Dark-Dev Sig-Total  Sig-Dev'
hdr2 = '----- ----- ------- ------- ------- ---- --------- --------- --------- --------- ---------'

print, ' '
print, hdr1
print, hdr2
printf,lun,"format = '(2I5,3F8.3,I5,5F10.2)'"
printf,lun,hdr1
printf,lun,hdr2

for i=0,calcnt-1 do begin
  print, caldata[i].integtime, caldata[i].chnum, caldata[i].rampstart, caldata[i].rampend, caldata[i].ramptime, caldata[i].rampnum, $
    	caldata[i].darkpre, caldata[i].darkpost, caldata[i].darkdev, caldata[i].signal, caldata[i].signaldev, format=format
  printf,lun, caldata[i].integtime, caldata[i].chnum, caldata[i].rampstart, caldata[i].rampend, caldata[i].ramptime, caldata[i].rampnum, $
    	caldata[i].darkpre, caldata[i].darkpost, caldata[i].darkdev, caldata[i].signal, caldata[i].signaldev, format=format
endfor

close,lun
free_lun,lun

if keyword_set(debug) then begin
   stop, 'DEBUG at end of xrs_gaincal...'
endif

end
