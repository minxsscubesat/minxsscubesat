;
;	find_flares.pro
;
;	Find GOES flares (searches for peaks)
;
;	Tom Woods
;	12/16/04
;
;	INPUTS:
;		date_range	range of days for finding flare peaks
;		minflare	minimum level for flare detection (1E-5 = M1)
;		/noplot		Option to not do the plot
;		/ip_flares	Option to search for Impulsive Phase part of flare (derivative of GOES X-ray)
;
;	OUTPUT:
;		tgoes		time of GOES data (YYYYDOY format)  [ optional ]
;		fgoes		flux of GOES data  [ optional ]
;
;   RETURN:
;		result		Array of results as structure (peak time, peak irradiance, ...)
;
function find_flares, date_range, minflare, tgoes, fgoes, noplot=noplot, debug=debug, ip_flares=ip_flares

if n_params() lt 1 then begin
	print, 'USAGE:  result = find_flares( date_range, minflare [, tgoes_out, fgoes_out, /noplot] )'
	return, -1L
endif

doDEBUG = 0	; set to non-zero for STOP command to debug find_flares.pro
if keyword_set(debug) then doDEBUG = 1

if n_params() lt 2 then minflare = 1E-6		; C1 = 1E-6 W/m^2

;
;	make date1 (start) and date2 (end) values in YYYYDOY format
;		Allow for YEAR or YYYYDOY input format
;		Allow for single value (either full year or full day)
;
date1 = double(date_range[0])
numdate = n_elements(date_range)
if (date1 lt 2100) then begin
    ; user only provided year values instead of YYYYDOY values
	date1 = date1 * 1000. + 1
	if (numdate gt 1) then begin
	    date2 = double(date_range[1])
	    if (date2 lt 2100) then date2 = date2 * 1000. + 365 + leap_year(date_range[1])
	endif else begin
		date2 = date1 + 364 + leap_year(date_range[0])
	endelse
endif else begin
	if (numdate gt 1) then begin
		date2 = double(date_range[1])
		if (date2 lt 2100) then date2 = date2 * 1000. + 365 + leap_year(date_range[1])
	endif else begin
		date2 = date1 + 1.
	endelse
endelse
if (date2 lt (date1 + 1.)) then date2 = date1 + 1
print, 'Finding Flares from ', strtrim(long(date1),2), ' to ', strtrim(long(date2),2), ' ...'

;
;	read GOES X-ray data (one year at a time)
;
goes = extract_goes_ts( [date1, date2] )
tgoes = reform(goes[*,0])
wgd = where( (tgoes ge date1) and (tgoes lt date2), numgd )
if (numgd lt 120) then begin
	print, 'Error finding enough GOES data - exiting find_flares().'
	if (doDEBUG ne 0) then print, '    Only ', strtrim(numgd,2), ' data points found.'
	return, -1L
endif
tgoes = tgoes[wgd]
fgoes = reform(goes[wgd,1])

;
;	define data structure for RESULT
;		Peak time, irradiance, class nmae
;		Pre-flare irradiance
;		Post-flare 1/2 down (log(GOES)) time
;
if keyword_set(ip_flares) then begin
  result_temp = { peak_time: 0.0D0, peak_hour: 0.0, peak_irr: 0.0, class: bytarr(4), preflare_irr: 0.0, $
  				 postflare_time: 0.0D0, ip_start_time: 0.0D0, ip_end_time: 0.0D0, $
  				 ip_above_M1: 0.0, ip_above_C5: 0.0 }
endif else begin
  result_temp = { peak_time: 0.0D0, peak_hour: 0.0, peak_irr: 0.0, class: bytarr(4), preflare_irr: 0.0, $
  			postflare_time: 0.0D0 }
endelse

;
;	Find values above the "minflare" level
;	then extract the peak times only
;
e = fgoes
nsm = 3
if nsm gt 1 then esm = smooth(e,nsm,/edge_trun) else esm = e
nume = n_elements(e)
ediff1 = esm / shift(esm,nsm)
ediff1[0:nsm-1] = 1.
ediff1[nume-nsm:nume-1] = 1.

ediff2 = shift(ediff1,-1*nsm)
ediff2[0:nsm-1] = 1.1
ediff2[nume-nsm:nume-1] = 1.1

;
;	define FLARE class name for "minflare"
;
ilog = alog10(minflare)
if (ilog ne long(ilog)) and (ilog lt 0) then ilog = long(ilog) - 1 else ilog = long(ilog)
if (ilog gt -4) then ilog = -4	; force to be X-class
minnum = minflare / (10.^ilog)
ilog = ilog + 9
if (ilog lt 0) then ilog = 0
if (ilog gt 5) then ilog = 0
sclass = [ "?", "A", "B", "C", "M", "X"]
if (minnum ge 10) then minstr = sclass[ilog] + strtrim(long(minnum), 2) $
else minstr = sclass[ilog] + string(minnum,format='(F3.1)')

wflare = where((e ge minflare) and (ediff1 gt 1) and (ediff2 le 1),nflare)
if (nflare gt 0) then begin
  ;
  ; sort flares so don't have adjacent or nearby peaks (10 min limit)
  ;
  wflare1 = wflare
  numflares = 1L
  last_peak = wflare1[0]
  LIMIT_NEARBY = 10L	; 10-min limit for adjacent peaks
  nf1 = n_elements(wflare1)
  for k=1,nf1-1 do begin
    if (wflare1[k] gt (wflare1[k-1]+LIMIT_NEARBY)) then begin
      ; store new flare peak index
      wflare[numflares] = wflare1[k]
      numflares = numflares+1
      last_peak = wflare1[k]
    endif else begin
      if (fgoes[wflare1[k]] gt fgoes[last_peak]) then begin
        ; store larger peak info instead of first value
        wflare[numflares-1] = wflare1[k]
        last_peak = wflare1[k]
      endif
    endelse
  endfor
  wflare = wflare[0:numflares-1]

  results = replicate( result_temp, numflares )
  output = 'FIND_FLARES: ' + strtrim(numflares,2) + ' above class ' + minstr
  if (doDEBUG ne 0) then print, output

  if keyword_set(ip_flares) then begin
    ;  Impulsive Phase (IP) flare check needs GOES X-ray derivative for analysis
   	;		Use esm from above for this derivative
   	M1_FLARE_SIZE = 1.E-5
   	C5_FLARE_SIZE = 5.E-6
   	ip_flare = (shift(esm,-1) - esm) > 0.
  endif


  for k=0,numflares-1 do begin
  	;
  	;	get flare time
  	;
  	tflare = tgoes[wflare[k]]
  	hflare = (tflare-long(tflare))*24.
  	mflare = (hflare-long(hflare))*60.
	stime = '    ' + string(long(tflare/1000L),format='(I04)')+'/'+$
		string(long(tflare) mod 1000L,format='(I03)') + ' ' + $
		string(long(hflare),format='(I02)') + ':' + $
		string(long(mflare),format='(I02)') + '    '
	;
	;	get flare class
	;
	flare = fgoes[wflare[k]]
	ilog = alog10(flare)
	if (ilog ne long(ilog)) and (ilog lt 0) then ilog = long(ilog) - 1 $
	else ilog = long(ilog)
	if (ilog gt -4) then ilog = -4	; force to be X-class
	fnum = flare / (10.^ilog)
	ilog = ilog + 9
	if (ilog lt 0) then ilog = 0
	if (ilog gt 5) then ilog = 0
	if (fnum ge 10) then fstr = sclass[ilog] + strtrim(long(fnum), 2) $
	else fstr = sclass[ilog] + string(fnum,format='(F3.1)')
	;
	;	get pre-flare level
	;
	wpre = wflare[k]-60L	; go back 1 hour to look for minimum
	if (wpre lt 0) then wpre = 0L
	preflare = min(fgoes[wpre:wflare[k]])
	;
	;	find post-flare 1/2 down time (in log(GOES))
	;
	wpost = wflare[k]+8*60L  ; go ahead 8 hours to look for 1/2 down time
	if (wpost ge n_elements(fgoes)) then wpost = n_elements(fgoes)-1L
	log_goes = alog10(fgoes[wflare[k]:wpost]) - alog10(preflare)
	postlow = (alog10(flare) - alog10(preflare))/2.
	wlow = where( log_goes lt postlow, numlow )
	if (numlow gt 0) then post_time = tgoes[wflare[k]+wlow[0]] $
	else post_time = tgoes[wpost]  ; never saw 1/2 way down !!!
	;
	;	save result
	;
	results[k].peak_time = tflare
  	results[k].peak_hour = hflare
	results[k].peak_irr = flare
	ctemp = byte(fstr)
	cmax = n_elements(ctemp) - 1
	if (cmax ge 4) then cmax = 3
	results[k].class = ctemp[0:cmax]
	results[k].preflare_irr = preflare
	results[k].postflare_time = post_time

	if keyword_set(ip_flares) then begin
		;
		;	Get Impulsive Phase (IP) flare info too
		;		IP is when ip_flare (derivative of X-ray) is positive
		;
		jj_high = -1
		jj_high5 = -1
		jj1 = wflare[k]-1
		if (jj1 lt 0) then jj1=0L
		;  search backwards
		for jj=jj1,0,-1 do begin
		  if esm[jj] ge M1_FLARE_SIZE then jj_high = jj
		  if esm[jj] ge C5_FLARE_SIZE then jj_high5 = jj
		  if ip_flare[jj] le 0 then break
		endfor
		jj1 = jj
		; search forward
		for jj=wflare[k],nume-1,1 do begin
		  if ip_flare[jj] le 0 then break
		endfor
		jj2 = jj
		results[k].ip_start_time = tgoes[jj1]
		results[k].ip_end_time = tgoes[jj2]
		; "ip_above_M1" is percent IP detected for MEGS-B flare algorithm
		if (jj_high lt 0) then results[k].ip_above_M1 = 0.0 $
		else results[k].ip_above_M1 = float(jj2-jj_high)/float(jj2-jj1+1.)
		if (jj_high5 lt 0) then results[k].ip_above_C5 = 0.0 $
		else results[k].ip_above_C5 = float(jj2-jj_high5)/float(jj2-jj1+1.)
		; if (results[k].ip_above_M1 gt 1) then stop, 'DEBUG issue for ip_above_M1...'
	endif
  endfor
endif else begin
  results = -1L
  output = 'FLARES: none above class ' + minstr
  if (doDEBUG ne 0) then print, output
endelse

;
;	optionally, do a plot of GOES data
;
if not keyword_set(noplot) then begin
  setplot
  cc = rainbow(7)
  tzero = long(tgoes[0]/1000L)*1000L
  tdiff = yd2jd(tgoes)-yd2jd(tzero)
  plot_io, tdiff, fgoes, xtitle='Time [days of '+strtrim(tzero/1000L,2)+']', $
  	ytitle='Irradiance [W/m!U2!N]', yrange=[1E-7,2E-4], ys=1
  if (numflares gt 1) then begin
    rtime = yd2jd(results.peak_time)-yd2jd(tzero)
    oplot, rtime, results.peak_irr, psym=5, color=cc[3]
    oplot, rtime, results.preflare_irr, psym=4, color=cc[0]
    postlevel = 10.^((alog10(results.peak_irr)+alog10(results.preflare_irr))/2.)
    oplot, yd2jd(results.postflare_time)-yd2jd(tzero), postlevel, psym=6, color=cc[4]
  endif
endif

if doDEBUG ne 0 then begin
	;  print results summary
	print, '  Date    Hour  Class '
	for k=0,numflares-1 do $
	    print, long(results[k].peak_time), results[k].peak_hour, string(results[k].class), $
	    		format='(I8,F6.2,A7)'
	stop, 'find_flares: STOPPED for debugging...'
endif

return, results
end
