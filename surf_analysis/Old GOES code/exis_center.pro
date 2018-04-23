pro exis_center, surffile, instrument, channel, fm=fm, scantype=scantype, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, darkman=darkman, darkauto=darkauto, quad45=quad45, smooth=smooth, despike=despike, correctbc=correctbc, correcttime=correcttime, debug=debug, plotdata=plotdata, help=help

; 8 June 2012 - Amir Caspi - Initial version
; 5 July 2012 - A.C. - revised quad45 keyword and subsequent data handling to differentiate
;                      between +/- 45 degree orientations (+45 was not properly supported previously)
; 16 July 2012 - A.C. - fixed bugs: multiple "same-hour" EXIS files now handled appropriately (use
;                       latest version instead of first), and other minor bug fixes.
; 4 Oct 2012 - A.C. - updated to use exis_process_surfdata, fixed sorting bug for uncertainties (ecdata)
;                     all data retrieval code moved to exis_process_surfdata (incl. comment from 7/16) 
; 11 Apr 2013 - A.C. - added fm and correctbc keywords (passed to exis_process_surfdata),
;                      added auto dark removal (if valves present and valid), fixed minor bugs

; Check input viability - print usage message if needed

if (n_params() lt 2) or keyword_set(help) then begin
  message, /info, 'USAGE:  exis_center, <surffile>, <instrument>, <channel>, [ fm=fm, darkman=darkman, darkauto=darkauto, quad45=quad45, smooth=smooth, despike=despike, correctbc=correctbc, debug=debug, plotdata=plotdata, surf_dir=surf_dir, data_dir=data_dir]'
  message, /info, "Set fm to appropriate flight model number, 1-6, or 0 for ETU [DEFAULT: 1]"
  message, /info, "Instrument must be one of: XRS, EUVS, SPS; ensure <channel> is correctly set for the chosen instrument (ignored for SPS)."
  message, /info, "<surffile> may be an ARRAY of filenames, if a test was split across multiple files..."
  message, /info, "Set /darkman to select dark intervals manually; set /darkauto to use first 30 secs."
  message, /info, "Set scantype = [X | Y | U | V] to FORCE checking that scan; by default, scan type is determined AUTOMATICALLY from SURF tank motions."
  message, /info, "Set quad45 = [1 | -1] for quad-sum analysis during U/V scans.  quad45 = 1 for +45 deg orientation, -1 for -45 deg."
  message, /info, "Set /despike to attempt spike removal in SURF beam current (MAY exclude good data by accident)'
  message, /info, "Set /correctbc to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)"
  message, /info, "Set path_prefix, surf_dir, data_dir, and/or gain_dir if needed (default values in exis_process_surfdata.pro)"
  return
endif

if n_elements(surffile) gt 1 then print, "WARNING: Multiple SURF files requested... each will be processed individually, THEN concatenated at the end..."
for i=0, n_elements(surffile)-1 do begin
  print, "Processing SURF file "+strtrim(i+1,2)+" of "+strtrim(n_elements(surffile),2)
  fovdata_temp = exis_process_surfdata(surffile[i], instrument, channel, fm=fm, darkman=darkman, darkauto=darkauto, correctbc=correctbc, correcttime=correcttime, despike=despike, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, surfdata=surfdata_temp, tbase=tbase, debug=debug)
  if ((n_elements(fovdata_temp) eq 1) && (fovdata_temp eq -1)) then begin
    message, /info, "ERROR: exis_process_surfdata() returned -1; ABORTING..."
    return
  endif 
  fovdata = (n_elements(fovdata) eq 0) ? temporary(fovdata_temp) : [fovdata, temporary(fovdata_temp)]
  surfdata = (n_elements(surfdata) eq 0) ? temporary(surfdata_temp) : [[surfdata],[temporary(surfdata_temp)]]
endfor
;fovdata = exis_process_surfdata(surffile, instrument, channel, /darkman, despike=despike, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, surfdata=surfdata, debug=debug)

; Set SURF array variables -- needed for determining dwell points at potentially finer timescale than EXIS data
isurftime = 0
isurfx = 1
isurfy = 2
isurfu = 3
isurfv = 4
isurfbc = 5
isurfenergy = 6
isurfsize = 7
isurfvalves = 8
isurfJDUT = 9 ; Julian date in UT for beam clock
nsurftimes = n_elements(surfdata[isurftime,*])

; Set labels for subarrays for analysis and plotting
instr = strupcase(strtrim(instrument, 2))
case instr of
  'XRS': begin
    ch = strmid(strupcase(channel),0,2)
    if (((ch eq 'A1') or (ch eq 'B1')) and keyword_set(quad45)) then begin
      message, /info, "WARNING: XRS A1/B1 channels do not support quad45 keyword; ignoring..."
      quad45 = 0
    endif
  end
  'EUVS': begin
    if keyword_set(quad45) then begin
      message, /info, "WARNING: EUVS instrument does not support quad45 keyword; ignoring..."
      quad45 = 0
    endif
    ch = strmid(strupcase(channel),0,1)
    case ch of
      'A': begin
        choice_labels = ['25.6 nm (A1+A4)', '28.4 nm (A2)', '30.4 nm (A3)']
        sig_labels = ['euvs_sa1', 'euvs_sa2', 'euvs_sa3']
;        pixel_mask = bytarr(3,24)
;        pixel_mask[0,[2,3,4,5,6,24,23,22,21,20,19]-1] = 1 ; SA1
;        pixel_mask[1,[7,8,9,10,11]-1] = 1 ; SA2
;        pixel_mask[2,[18,17,16,15,14,13]-1] = 1 ; SA3
        isplits = [16,15]-1
        idarks = [1,12]-1
      end
      'B': begin
        choice_labels = ['117.5 nm (B3)', '121.6 nm (B2)', '133.5 nm (B4)', '140.5 nm (B1)']
        sig_labels = ['euvs_sa1', 'euvs_sa2', 'euvs_sa3', 'euvs_sa4']
;        pixel_mask = bytarr(4,24)
;        pixel_mask[0,[18,17,16,15,14]-1] = 1 ; SA1
;        pixel_mask[1,[7,8,9,10,11,12]-1] = 1 ; SA2
;        pixel_mask[2,[23,22,21,20,19]-1] = 1 ; SA3
;        pixel_mask[3,[1,2,3,4,5,6]-1] = 1 ; SA4
        isplits = [10,9]-1
        idarks = [13,24]-1
      end
      'C': begin
        choice_labels = ['Medium (core+wing)', 'Small (core)']
        sig_labels = ['euvs_sa1', 'euvs_sa2']
;        pixel_mask = bytarr(2,512)
;        pixel_mask[0,indgen(257)-128+274] = 1 ; +/- 128 pixels around peak of response
;        pixel_mask[1,indgen(65)-32+274] = 1 ; +/- 32 pixels around peak of response
        idarks = indgen(64)
      end
    endcase
  end
  'SPS': begin
    ch = ''
  end
endcase

; Exclude dark data
; Do this by checking the SURF valve positions (all open = good, any closed = bad)
; If ENTIRE file shows dark (0) or missing (-1) valves, skip this step
if ((median(fovdata.surfvalves) ne -1) and (median(fovdata.surfvalves) ne 0)) then begin
  ; REMOVE TWO additional data points on either side, to account for valve motion latency
  wgood = where((fovdata.surfvalves eq 7) and (shift(fovdata.surfvalves, 1) eq 7) and (shift(fovdata.surfvalves, -1) eq 7) and (shift(fovdata.surfvalves, 2) eq 7) and (shift(fovdata.surfvalves, -2) eq 7), ngood)
;  darklevel = mean(fovdata.rawcnt - fovdata.cnt * fovdata.surfbc)
;  wgood = where( fovdata.rawcnt gt darklevel * 2., ngood )  ; assumes S/N > 2 for real data...
  if (ngood lt 10) then begin
    print, 'ERROR finding enough good data for centering!'
    return
  endif
  fovdata = fovdata[wgood]
endif

; Determine the primary moving axis by checking for biggest SURF tank motion
diff = fltarr(4)
diff[0] = max(fovdata.surfx) - min(fovdata.surfx)
diff[1] = max(fovdata.surfy) - min(fovdata.surfy)
diff[2] = max(fovdata.surfu) - min(fovdata.surfu)
diff[3] = max(fovdata.surfv) - min(fovdata.surfv)
temp = max(diff, wdiff)
; If user has set scantype appropriately, override automatic determination
if keyword_set(scantype) then begin
  temp = where(['X','Y','U','V'] eq strupcase(strmid(scantype,0,1)))
  if (temp ne -1) then wdiff = temp else message, /info, 'WARNING: invalid scantype keyword, defaulting to AUTOMATIC scan type determination..."
endif

case wdiff of
	0: begin
		type='X'
		sdata = fovdata.surfx
		sdata_fine = surfdata[isurfx,*]
    cdata = keyword_set(quad45) ? ((quad45 gt 0) ? fovdata.quad13 : fovdata.quad24) : fovdata.signal
       end
  1: begin
		type='Y'
		sdata = fovdata.surfy
    sdata_fine = surfdata[isurfy,*]
    cdata = keyword_set(quad45) ? ((quad45 gt 0) ? fovdata.quad24 : fovdata.quad13) : fovdata.signal
       end
  2: begin
    type='Yaw (U)'
    sdata = fovdata.surfu
    sdata_fine = surfdata[isurfu,*]
    cdata = keyword_set(quad45) ? ((quad45 gt 0) ? fovdata.quad13 : fovdata.quad24) : fovdata.signal
	     end
  3: begin
    type='Pitch (V)'
    sdata = fovdata.surfv
    sdata_fine = surfdata[isurfv,*]
    cdata = keyword_set(quad45) ? ((quad45 gt 0) ? fovdata.quad24 : fovdata.quad13) : fovdata.signal
       end
endcase
tdata = fovdata.time

; Eliminate points while moving...
; First, check there's at least 2 stable points...
sdiff = sdata - shift(sdata,1)
sdiff[0] = sdiff[1]
wgood = where( sdiff eq 0, numgood )
if (numgood lt 2) then stop, 'ERROR: no good data for finding center.  Debug...'

; Next, figure out when the SURF tank is holding steady...
sdiff = sdata_fine - shift(sdata_fine,1)
sdiff[0] = sdiff[1]
wgood = where( sdiff eq 0, numgood )
gooddiff = [wgood - shift(wgood,1), -999]
runstarts = where( gooddiff ne 1 )
integtime = 0.25 * ((((instr eq 'EUVS') && (ch eq 'C')) ? fovdata[0].rawdata[0].cal_integtime : fovdata[0].rawdata[0].asic_integtime) + 1.)

; Then, find the science data, analyze it, plot it...

repeat begin ; allow looping over multiple data sets until user exits (only for EUVS)

ytitle = instr+(ch ne '' ? '-'+ch : '')
if (n_elements(sig_labels) ne 0) then begin
  junk = 'Which data set to use?  [0] Full Sum ...  '
  for k=0,n_elements(choice_labels)-1 do junk += '  ['+strtrim(k+1,2)+'] '+choice_labels[k]+' ...  '
  ans = ''
  read, prompt=junk, ans
  ans = fix(strupcase(strmid(ans,0,1)))
  while ((ans lt 0) or (ans gt n_elements(choice_labels))) do begin
    print, "Invalid answer; try again..."
    ans = ''
    read, prompt=junk, ans
    ans = fix(strupcase(strmid(ans,0,1)))
  endwhile
  if (ans eq 0) then begin
    cdata = fovdata.signal
    ytitle += ': Full Detector'
  endif else begin
    junk = execute('cdata = fovdata.'+sig_labels[ans-1]+' & ytitle += ": '+choice_labels[ans-1]+'"')
    quad45 = (choice_labels[ans-1] eq 'Split Pixels')
  endelse
endif
if (instr eq 'XRS') or (instr eq 'SPS') then begin
  ytitle += '!C' + (keyword_set(quad45) ? ((type eq 'Yaw (U)') ? "Quad 2-4" : "Quad 1-3") : 'Signal [fA/mA]')
endif else begin ; instrument is EUVS
  ytitle += '!C' + (keyword_set(quad45) ? 'Split Pixel Diff. Ratio' : 'Signal [fA/mA]')
endelse

; Find all the science data during stable periods, and mark it
for k = 1, n_elements(runstarts)-1 do begin
	tmax = (surfdata[isurftime,[wgood[runstarts[k]-1]]])[0]
  tmin = (surfdata[isurftime,[wgood[runstarts[k-1]]]])[0]
	tgood = where( (tdata ge (tmin + integtime/2.)) and (tdata le (tmax - integtime/2.)), ngood )
  ; If good data exists during this stable period, average it and accumulate
  if (ngood ge 1) then begin
    cmax = max(cdata[tgood])
    tgood2 = where(abs(cdata[tgood]) ge abs(cmax * 0.3), ngood2)  ; Eliminate dropouts
    ctemp = mean(cdata[tgood[tgood2]])  ; Average all points
    ectemp = stddev(cdata[tgood[tgood2]])/sqrt(ngood2)  ; Estimated error
    ; Error estimate is lower limit, does NOT properly propagate errors from dark subtraction or other summing
    stemp = sdata[tgood[0]] ; Save SURF value (no need to average since it's the same for all points in this run)
;    if keyword_set(debug) then message, /info, "DEBUG: "+stemp, " ---- ", ctemp, " ---- ", cdata[tgood[tgood2]]
    cdata2 = (n_elements(cdata2) eq 0) ? ctemp : [cdata2, ctemp]
    ecdata2 = (n_elements(ecdata2) eq 0) ? ectemp : [ecdata2, ectemp]
    sdata2 = (n_elements(sdata2) eq 0) ? stemp : [sdata2, stemp]
  endif else if keyword_set(debug) then message, /info, "DEBUG: No good data for time interval: "+strtrim(tmin,2) + " -- " + strtrim(tmax,2)
endfor

; Now, throw out all non-stable data
cdata_org = cdata
sdata_org = sdata
cdata=cdata2[sort(sdata2)]  ; Sort on SURF position so the original ordering doesn't matter!
ecdata=ecdata2[sort(sdata2)]
sdata=sdata2[sort(sdata2)]

; Remove remaining dropouts by comparing points with neighbors
; ENABLE ONLY IF REQUIRED FOR DATA INTEGRITY
;tgood = [0]
;for k=1, n_elements(sdata)-2 do if not (((cdata[k-1] ge 0.1*max(cdata)) or (cdata[k+1] ge 0.1*max(cdata))) and (cdata[k] le cdata[k-1]*0.2) and (cdata[k] le cdata[k+1]*0.2)) then tgood = [tgood, k]
;tgood = [tgood, n_elements(sdata)-1]
;print, "TGOOD === ", tgood
;cdata = cdata[tgood]
;sdata = sdata[tgood]

;	smooth the data if desired
if keyword_set(smooth) then begin
  if keyword_set(debug) then message, /info, 'DEBUG: Smoothing signal by ', smooth
  cdata = smooth(cdata,smooth,/edge_trunc)
endif

setplot, thick=1.5
cc=rainbow(7)
plot, sdata, cdata, psym=-4, xtitle=type, ytitle=ytitle, xstyle=1, xrange=plotrange(sdata), ystyle=1, yrange=plotrange(cdata), xmargin=[11,3], title='RESULTS'
errplot, sdata, cdata-ecdata, cdata+ecdata, width=1e-20

; save the plot data
plotdata = [[sdata], [cdata], [ecdata]]

; BEGIN CENTERING ANALYSIS
print, 'Doing CENTER analysis for ', type

;if ((type eq 'X') or (type eq 'Y')) and not keyword_set(quad45) then begin
if not keyword_set(quad45) then begin
  ;	Determine maximum signal (not fully robust if data is noisy... look into fitting later)
  cmax = max(cdata, wcmax)
  smax = sdata[wcmax]
  oplot, smax*[1,1],!y.crange,line=1, color=cc[0]
  print, ' '
  print, 'Peak signal (red) is at ', strtrim(smax,2)

  ;	For Y-scans, fit parabola and Gaussian for more accurate center point, but ONLY to XRS -- all other channels are flatish
  if ((type eq 'Y')  and (instr eq 'XRS')) then begin
    wyfit = where( (sdata ge (smax-0.3)) and (sdata le (smax+0.3)), num_yfit )
    if (num_yfit gt 3) then begin
      cc2 = poly_fit( sdata[wyfit], cdata[wyfit], 2, sigma=cc2_sigma )
      ytemp = (findgen(1001)-500.)*0.4/1000. + smax
      ctemp = cc2[0] + cc2[1] * ytemp + cc2[2] * ytemp^2.
      oplot, ytemp, ctemp, color=cc[4]
      cmaxtemp = max(ctemp,wcmaxtemp)
      smaxtemp = ytemp[wcmaxtemp]
      smaxcalc = -0.5 * cc2[1] / cc2[2]
      yerr = sqrt( (cc2_sigma[1] / cc2[2])^2. + (cc2[1] * cc2_sigma[2] / (cc2[2]^2.))^2. )
      print, '    Y-Scan Parabolic Fit PEAK is at ', smaxcalc, '  +/- ', yerr
      cc3 = fltarr(4)
      cc3[0] = cmaxtemp
      cc3[1] = smaxcalc
      cc3[2] = 0.1
      ; cc3[2] = 2*sqrt( cc2[1] - 4*cc2[2]*(cc2[0]/2. - cc2[1]^2/(8.*cc2[2]))) / cc2[2]
      ; print, 'Initial width guess = ', cc3[2]
      yy3fit = gaussfit( sdata[wyfit], cdata[wyfit], cc3, nterms=3, sigma=cc3_sigma )
      zz3 = double((ytemp - cc3[1])/cc3[2]) < 20.
      yy3 = cc3[0] * exp( -0.5 * zz3^2. ) ; + cc3[3]
      oplot, ytemp, yy3, color=cc[1]
      print, '    Y-Scan Gaussian Fit PEAK is at ', cc3[1],  ' +/- ', cc3_sigma[1]
    endif
  endif
  print, ' '

  ;	50% (or user-tunable limit) edge search
  edgelimit = 0.50
  while (edgelimit gt 0) do begin
    cntedge = cmax*edgelimit
    if (cntedge lt min(cdata)) then cntedge = max(cdata) - (max(cdata) - min(cdata))/3.
    whigh = where( cdata gt cntedge, numhigh )
    if (numhigh ge 2) and (numhigh le (n_elements(cdata)-2)) then begin
      ii1 = [whigh[0]-1, whigh[0]]
      s1 = interpol( sdata[ii1], cdata[ii1], cntedge )
      oplot, s1*[1,1], !y.crange, line=2, color=cc[3]
      ii2 = [whigh[numhigh-1], whigh[numhigh-1]+1]
      s2 = interpol( sdata[ii2], cdata[ii2], cntedge )
      oplot, s2*[1,1], !y.crange, line=2, color=cc[3]
      scenter = (s1 + s2)/2.
      oplot, scenter*[1,1], !y.crange, line=2, color=cc[3]
      print, 'Edges at ', strtrim(s1,2), ' and ', strtrim(s2,2)
      print, 'Edge Center (green) is at ', strtrim(scenter,2),'   (value there is '+strtrim(interpol(cdata,sdata,scenter),2)+')'
      print, ' '
    endif
    if keyword_set(debug) then read, prompt='Enter different percentage level (0-1) for edge search (-1 to exit) : ', edgelimit else edgelimit = -1
  endwhile

  ; edge search by fitting line between 0.8 and 0.2 of (Max-Min)
  edgelimit1 = 0.2 * (cmax - min(cdata)) + min(cdata)
  edgelimit2 = 0.8 * (cmax - min(cdata)) + min(cdata)
  edgemid = (edgelimit1 + edgelimit2)/2.
  wedge1 = where( (cdata gt edgelimit1) and (cdata lt edgelimit2) and (sdata lt smax), numedge1 )
  wedge2 = where( (cdata gt edgelimit1) and (cdata lt edgelimit2) and (sdata gt smax), numedge2 )
  if (numedge1 ge 3) and (numedge2 ge 3) then begin
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
    print, 'WARNING: not enough points to fit line to edges.'
  endelse

  ; If scan looks lopsided, can do separate edge scans for left/right edges...
  ans = ''
  read, prompt='Check L/R edges separately ? (Y or N) ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then begin
    plot, sdata, cdata, psym=-4, xtitle=type, ytitle=ytitle, xstyle=1, xrange=plotrange(sdata), ystyle=1, yrange=plotrange(cdata), xmargin=[11,3], title='RESULTS - EDGE SEARCH'
    edgelimit = 0.50
    while (edgelimit gt 0) do begin
      print, 'Define LEFT edge (click left AND right of edge) ...'
      cursor, x1, y1, /down
      oplot, [x1,x1],!y.crange,line=2,color=129200
      cursor, x2, y2, /down
      oplot, [x2,x2],!y.crange,line=2,color=129200
      wleft = where( (sdata ge x1) and (sdata lt x2) )

      ; Trim to only left-edge data, but save original for restoring to do the other edge
      cdata_ooo = cdata
      sdata_ooo = sdata
      cdata = cdata[wleft]
      sdata = sdata[wleft]

      cmax = max(cdata, wcmax)
      smax = sdata[wcmax]
      oplot, smax*[1,1],!y.crange,line=1, color=cc[0]
      print, ' '
      print, 'Peak signal (red) is at ', strtrim(smax,2)

      cntedge = cmax*edgelimit
      if (cntedge lt min(cdata)) then cntedge = max(cdata) - (max(cdata) - min(cdata))/3.
      whigh = where( cdata gt cntedge, numhigh )
      if (numhigh ge 2) and (numhigh le (n_elements(cdata)-2)) then begin
        ii1 = [whigh[0]-1, whigh[0]]
        s1 = interpol( sdata[ii1], cdata[ii1], cntedge )
        oplot, s1*[1,1], !y.crange, line=2, color=cc[3]
      endif else begin
        s1 = -9999
        print, "No edge found on left!"
      endelse

      edgelimit1 = 0.2 * (cmax - min(cdata)) + min(cdata)
      edgelimit2 = 0.8 * (cmax - min(cdata)) + min(cdata)
      edgemid = (edgelimit1 + edgelimit2)/2.
      wedge1 = where( (cdata gt edgelimit1) and (cdata lt edgelimit2) and (sdata lt smax), numedge1 )
      if (numedge1 ge 3) then begin
        cfit1 = poly_fit( sdata[wedge1], cdata[wedge1], 1 )
        srange1 = min(sdata[wedge1]) + findgen(11)*(max(sdata[wedge1])-min(sdata[wedge1]))/10.
        crange1 = cfit1[0] + cfit1[1] * srange1
        oplot, srange1, crange1, color=cc[5]
        fitedge1 = (edgemid - cfit1[0])/cfit1[1]
        oplot, fitedge1*[1,1],!y.crange,line=3, color=cc[5]
      endif else begin
        print, 'WARNING: not enough points to fit line to LEFT edge.'
        fitedge1 = -9999
      endelse

      ; restore original data
      cdata = cdata_ooo
      sdata = sdata_ooo

      print, 'Define RIGHT edge (click left AND right of edge) ...'
      cursor, x1, y1, /down
      oplot, [x1,x1],!y.crange,line=2,color=129200
      cursor, x2, y2, /down
      oplot, [x2,x2],!y.crange,line=2,color=129200
      wright = where( (sdata ge x1) and (sdata lt x2) )

      cdata = cdata[wright]
      sdata = sdata[wright]

      cmax = max(cdata, wcmax)
      smax = sdata[wcmax]
      oplot, smax*[1,1],!y.crange,line=1, color=cc[0]
      print, ' '
      print, 'Peak signal (red) is at ', strtrim(smax,2)

      cntedge = cmax*edgelimit
      if (cntedge lt min(cdata)) then cntedge = max(cdata) - (max(cdata) - min(cdata))/3.
      whigh = where( cdata gt cntedge, numhigh )
      if (numhigh ge 2) and (numhigh le (n_elements(cdata)-2)) then begin
        ii2 = [whigh[numhigh-1], whigh[numhigh-1]+1]
        s2 = interpol( sdata[ii2], cdata[ii2], cntedge )
        oplot, s2*[1,1], !y.crange, line=2, color=cc[3]
      endif else begin
        s2 = -9999
        print, "No edge found on right!"
      endelse

      edgelimit1 = 0.2 * (cmax - min(cdata)) + min(cdata)
      edgelimit2 = 0.8 * (cmax - min(cdata)) + min(cdata)
      edgemid = (edgelimit1 + edgelimit2)/2.
      wedge2 = where( (cdata gt edgelimit1) and (cdata lt edgelimit2) and (sdata gt smax), numedge2 )
      if (numedge2 ge 3) then begin
        cfit2 = poly_fit( sdata[wedge2], cdata[wedge2], 1 )
        srange2 = min(sdata[wedge2]) + findgen(11)*(max(sdata[wedge2])-min(sdata[wedge2]))/10.
        crange2 = cfit2[0] + cfit2[1] * srange2
        oplot, srange2, crange2, color=cc[5]
        fitedge2 = (edgemid - cfit2[0])/cfit2[1]
        oplot, fitedge2*[1,1],!y.crange,line=3, color=cc[5]
      endif else begin
        print, 'WARNING: not enough points to fit line to RIGHT edge.'
        fitedge2 = -9999
      endelse

      scenter = (s1 + s2)/2.
      oplot, scenter*[1,1], !y.crange, line=2, color=cc[3]
      print, 'Left/Right Edges at ', strtrim(s1,2), ' and ', strtrim(s2,2)
      print, 'Left/Right Edge Center (green) is at ', strtrim(scenter,2)
      print, ' '

      fitcenter = (fitedge1 + fitedge2)/2.
      oplot, fitcenter*[1,1], !y.crange, line=3, color=cc[5]
      print, 'Left/Right FIT Edges at ', (fitedge1 ne -9999) ? strtrim(fitedge1,2) : 'UNDEF', ' and ', (fitedge2 ne -9999) ? strtrim(fitedge2,2) : 'UNDEF'
      print, 'Left/Right FIT Edge Center (blue) is at ', ((fitedge1 ne -9999) and (fitedge2 ne -9999)) ? strtrim(fitcenter,2) : 'UNDEF'
      print, ' '

      if keyword_set(debug) then read, prompt='Enter different percent level for edge search (-1 to exit) : ', edgelimit else edgelimit = -1
    endwhile
  endif
endif $ ; if quad45 not set
else begin ; if quad45 is set
;  if ((type ne 'X') and (type ne 'Y') and not keyword_set(quad45)) then print, "Pitch/Yaw scan WITHOUT /quad45 enabled... not much to do here."
  if ((type eq 'X') or (type eq 'Y')) then message, /info, "WARNING: X/Y scan with quad45 will yield strange results..."
  ; Do Quad Diode check - search for where quad-sum crosses zero
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
  endif else print, "Not enough points near zero, cannot determine a quad zero crossing..."
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
  endif
endelse

; For EUVS, prompt user whether to try a different data set
if n_elements(sig_labels) ne 0 then begin
  read, prompt='Want to check a different data set on this scan? (Y/N) ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then begin
;    cdata = cdata_org
    sdata = sdata_org
    junk = temporary(cdata2)
    junk = temporary(ecdata2)
    junk = temporary(sdata2)
  endif
endif else ans = 'N'
    
endrep until (ans ne 'Y')

END
