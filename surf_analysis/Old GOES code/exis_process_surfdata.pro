function exis_process_surfdata, surffile, instr, channel, fm=fm, surfdata=surfdata, tbase=tbase, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, time_dir=time_dir, path_prefix=path_prefix, darkman=darkman, darkauto=darkauto, despike=despike, correctbc=correctbc, correcttime=correcttime, debug=debug, help=help

; 20 July 2012 - Amir Caspi - Initial version, based on exis_center.pro code
; 25 July 2012 - Amir Caspi - Added time-interpolation of dark level, if multiple dark times selected
; 11 Apr 2013  - Amir Caspi - Added fm keyword for specifying flight model, correctbc keyword for TNW current mod, fixed minor plot bug

; SETUP - errors and warnings, plus default parameters

fm = n_elements(fm) ne 0 ? fm : 1
path_prefix = keyword_set(path_prefix) ? strtrim(path_prefix,2) : ''
; Set path to where instrument data resides
data_dir = keyword_set(data_dir) ? strtrim(data_dir,2) : path_prefix+'/goesr-work/data/fm'+strtrim(fm,2)+'/l0b' ; zuul
; Set path to directory where SURF beam data resides
surf_dir = keyword_set(surf_dir) ? strtrim(surf_dir,2) : path_prefix+'/goesr-work/data/fm'+strtrim(fm,2)+'/surfer' ; zuul
; Set path to directory where EXIS gain lookup table resides
gain_dir = keyword_set(gain_dir) ? strtrim(gain_dir,2) : path_prefix+'/goesr-work/data/cal/fm'+strtrim(fm,2) ; zuul
; Set path to directory where EXIS/SURF time sync files reside
time_dir = keyword_set(time_dir) ? strtrim(time_dir,2) : path_prefix+'/goesr-work/data/fm'+strtrim(fm,2)+'/surf_time_sync' ; zuul

; Check input viability - print usage message if needed
if (n_params() lt 2) or keyword_set(help) then begin
  message, /info, 'USAGE:  data = exis_process_surfdata(<surffile>, <instrument>, <channel> [, fm=fm, surfdata=surfdata, data_dir=data_dir, surf_dir=surf_dir, gain_dir=gain_dir, path_prefix=path_prefix, darkman=darkman, darkauto=darkauto, despike=despike, correctbc=correctbc, debug=debug, help=help ])'
  message, /info, 'RETURNS struct with processed data; OPTIONALLY outputs "raw" SURF data array in surfdata keyword.'
  message, /info, "Set fm to appropriate flight model number, 1-6, or 0 for ETU [DEFAULT: 1]"
  message, /info, "Instrument must be one of: xrs, euvs, sps; ensure <channel> is correctly set for the chosen instrument."
  message, /info, "Set tbase to Julian Date of reference time; data and SURF times will be reported as seconds after tbase... if tbase is undefined, times will be seconds after first data point, whose time will be returned in tbase for possible usage in subsequent calls"
  message, /info, "Set /darkman to select dark intervals manually; set /darkauto to use first 30 secs."
  message, /info, "Set /despike to attempt spike removal in SURF beam current (MAY exclude good data by accident)'
  message, /info, "Set /correctbc to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)"
  message, /info, "Set path_prefix and/or surf_dir [default = '/goesr-work/data/fm1/surfer'] and/or data_dir [default = '/goesr-work/data/fm1/l0b'] and/or gain_dir [default = '/goesr-work/code/idl/quicklook'] if needed."
  return, -1
endif

; Determine flight model validity
if ((fm lt 1) or (fm gt 4)) then begin
  message, /info, "ERROR: Flight model number " + strtrim(fm, 2) + " invalid.  Expected 1-4."
  if (fm eq 0) then message, /info, 'WARNING: flight model 0 == ETU.  This is not yet supported.'
  return, -1
endif

; Determine the instrument we're using and check validity, error out if no valid instrument specified
instrument = n_elements(instr) gt 0 ? strupcase(strtrim(instr, 2)) : ''
valid_instr = ['XRS','EUVS','SPS']
if (where(valid_instr eq instrument) eq -1) then begin
  message, /info, "ERROR: Invalid instrument.  Expected XRS, EUVS, or SPS."
  return, -1
endif

; Determine appropriate channel, error out if no valid channel specified.
if (instrument eq 'XRS') then begin
  if n_elements(channel) gt 0 then begin
    valid_channels = ['A1','B1','A2','B2']
    ch = strmid(strupcase(channel),0,2)
    if (where(ch eq valid_channels) eq -1) then begin
      message, /info, 'ERROR: Invalid XRS channel.  Expected A1, A2, B1, or B2.'
      return, -1
    endif
  endif else begin
    message, /info, 'ERROR: Missing XRS channel.  Need A1, A2, B1, or B2.'
    return, -1
  endelse
endif else if (instrument eq 'EUVS') then begin
  if n_elements(channel) gt 0 then begin
    valid_channels = ['A','B','C']
    ch = strmid(strupcase(channel),0,1)
    if (where(ch eq valid_channels) eq -1) then begin
      message, /info, "ERROR: Invalid EUVS channel.  Expected A, B, or C.'
      return, -1
    endif
  endif else begin
    message, /info, 'ERROR: Missing EUVS channel.  Need A, B, or C.'
    return, -1
  endelse
endif else begin ; Must be SPS
  ch = ''
  if n_elements(channel) gt 0 then message, /info, "WARNING: ignoring 'channel' input for SPS."
endelse


; Read SURF data
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
if (n_elements(surfdata) ne 0) then temp = temporary(surfdata) ; clear out any surfdata that was passed in... we don't want it!
for i=0, n_elements(surffile)-1 do begin
  temp = read_surflog_et( surf_dir+'/'+strtrim(surffile[i],2), despike=despike, debug=debug )
  ; Map SURF time to ESTE time
  if keyword_set(correcttime) then stimes = surf_correct_time(temp[isurfJDUT,*], filedir=time_dir, debug=debug)
  ; check to make sure we have good return data (obviously not if /correcttime not set)
  if ((n_elements(stimes) gt 1) and (n_elements(stimes) eq n_elements(temp[isurfJDUT,*]))) then temp[isurfJDUT,*] = stimes
  surfdata = (n_elements(surfdata) eq 0) ? temp : [[temporary(surfdata)],[temp]]
endfor
if keyword_set(debug) then message, /info, 'DEBUG: SURF file = '+ surf_dir+'/'+surffile
nsurftimes = n_elements(surfdata[isurfJDUT,*])
; TODO: sort surfdata based on time, else line 100 (numhrs) will not work properly if multiple files are passed out of order
; or could just change line 100 to use max and min...

; Read GOES data files corresponding to SURF time
; Path/Filename format = path_to_data/xrs/2012/056/xrs_2012056_09_000.txt
instr_dir = strlowcase(instrument) + ((instrument eq 'EUVS') ? strlowcase(ch) : '')
; Get number of hours that SURF data spans (example: 19:45 to 20:15 counts as spanning 2 hours, 19h and 20h)
numhrs = ceil(surfdata[isurfJDUT,nsurftimes-1]*24d0) - floor(surfdata[isurfJDUT,0]*24d0) - 1
; For each hour, read corresponding GOES data file and accumulate
for i = 0, numhrs do begin
  cur_hr = (floor(surfdata[isurfJDUT,0]*24d0) + i)/24d0 + 0.1d0/(24d0*3600d0) ; add 0.1s as kludge for round-off error
  caldat, cur_hr, i_mo, i_day, i_yr, i_hr
  i_yr = strtrim(i_yr, 2) & i_hr = string(i_hr, format='(I02)')
  i_doy = string(julday(i_mo,i_day,i_yr) - julday(1, 0, i_yr), format='(I03)')
  dfile = strjoin([data_dir, instr_dir, i_yr, i_doy, strjoin([instr_dir, i_yr + i_doy, i_hr, '*'], '_') + '.txt'], '/')
  dfile = file_search(dfile, count = numgood)
  if (numgood eq 0) then message, "ERROR: Couldn't find appropriate data file: "+dfile
;  dfile = dfile[numgood-1]
  if keyword_set(debug) and (numgood gt 1) then message, /info, "DEBUG: Multiple file match for "+strjoin([i_yr,i_doy,i_hr],'_')+" ... reading all and discarding duplicates..."
  for j = 0, numgood-1 do begin
    if keyword_set(debug) then message, /info, "DEBUG: Reading "+dfile[j]
    data_dn = (n_elements(data_dn) eq 0) ? read_goes_l0b_file(dfile[j]) : [temporary(data_dn), read_goes_l0b_file(dfile[j])]
  endfor
endfor ; data_dn now contains all relevant data
; Get rid of duplicate data by eliminating anything with the same timestamp...
dtimes = julday(1,data_dn.time_yd mod 1000,data_dn.time_yd/1000L,0,0,data_dn.time_sod)
data_dn = data_dn[uniq(dtimes, sort(dtimes))]

; Kludge - for EUVS-C, convert unsigned int back to signed
if (instrument eq 'EUVS') && (ch eq 'C') then data_dn.data = fix(data_dn.data)

; Get signal in fA (includes correction for integration time)
junk = execute('data_fa = exis_fm'+strtrim(fm,2)+'_apply_gain(data_dn,/'+instr_dir+', filedir=gain_dir)')
; ----- DEBUG ------
if (instrument eq 'EUVS') && (ch eq 'C') then data_fa = data_dn.data
numdiodes = n_elements(data_fa[*,0])

; Define the consolidated data structure we want to use
numdata = n_elements(data_dn)
data = { time: 0d0, signal: 0.0, $  ; measurement time and detector-integrated signal
      quadx: 0.0, quady: 0.0, quad13: 0.0, quad24: 0.0, $  ; quad-sums for XRS/SPS, also used for split-pixel for EUVS A/B
      euvs_sa1: 0.0, euvs_sa2: 0.0, euvs_sa3: 0.0, euvs_sa4: 0.0, $  ; individual subarrays for EUVS A/B
      surfbc: 0.0D0, surfx: 0.0, surfy: 0.0, surfu: 0.0, surfv: 0.0, $  ; SURF beam current and positions
      surfenergy: 0.0, surfsize: 0.0, surfvalves: 0.0, $  ; SURF beam energy and size (FUZZ --> size > 0; NO FUZZ --> size == 0)
      rawdata: data_dn[0], diodesig_fa: fltarr(numdiodes), darklevel: fltarr(numdiodes) } ; raw data struct, dark-subtracted diode signals (in fA), selected dark level for each diode
data = replicate(data, numdata)

integtime = 0.25 * ((((instrument eq 'EUVS') && (ch eq 'C')) ? data_dn[0].cal_integtime : data_dn[0].asic_integtime) + 1.)
; Convert data and SURF times to seconds from the first data point (allows transitions over day boundaries)
; **OR** seconds from the tbase passed in as a keyword...
if not keyword_set(tbase) then tbase = julday(1,data_dn[0].time_yd mod 1000,data_dn[0].time_yd/1000L,0,0,data_dn[0].time_sod)
; Convert data time ... also subtract half the integration time
data.time = (julday(1,data_dn.time_yd mod 1000,data_dn.time_yd/1000L,0,0,data_dn.time_sod) - tbase) * 24. * 3600. - integtime/2.
; Convert SURF time
surfdata[isurftime,*] = (surfdata[isurfJDUT,*] - tbase) * 24. * 3600.
; determine valid time range for science data based on SURF data
surfmin = min(surfdata[isurftime,*])
surfmax = max(surfdata[isurftime,*])
wgood = where((data.time ge (surfmin)) and (data.time le (surfmax)))

; if /darkman, do dark subtraction manually...
if keyword_set(darkman) then begin
  setplot, thick=1.5
  cc = rainbow(numdiodes-1)
  plot, /ylog, /nodata, data.time, data_fa[0,*], ys=5, yr=plotrange(data_fa[*,wgood]>1, /log), xs=5, xr=plotrange([surfmin,surfmax], margin=0.15)
  ; Shade where the valves are closed, for reference
  ; Don't do this if there is no valve position info!
  if median(surfdata[isurfvalves,*]) ne -1 then $
    polyfill, [surfmin, reform(surfdata[isurftime,*]), surfmax], 10^[!y.crange[0], reform((surfdata[isurfvalves,*] eq 7)*!y.crange[0] + (surfdata[isurfvalves,*] ne 7)*!y.crange[1]), !y.crange[0]], color='dddddd'x, noclip=0
  plot, /ylog, /noerase, data.time, data_fa[0,*]>0.1, /ys, yr=10^!y.crange, /xs, xr=!x.crange, xtitle='Time [sec]', ytitle='Total Signal [fA]', title='DARK SELECTION - please select dark times'
  ; Plot the raw diode signal data for dark selection...
  for j=1,numdiodes-1 do oplot, data.time, data_fa[j,*], color=cc[(j-1) mod 255] ; 255 is limitation of rainbow()
  ; Overplot SURF file time limits
  oplot, surfmin*[1,1], 10^!y.crange, line=1, color=cc[0], thick=3 & xyouts, surfmin+(!x.crange[1]-!x.crange[0])*.02, 10^(!y.crange[1]*.97), orientation=90., alignment=1., 'SURFfile start'
  oplot, surfmax*[1,1], 10^!y.crange, line=1, color=cc[0], thick=3 & xyouts, surfmax-(!x.crange[1]-!x.crange[0])*.005, 10^(!y.crange[1]*.97), orientation=90., alignment=1., 'SURFfile end'
  message, /info, "Manual dark subtraction:"
  repeat begin
    ans = 'Y'
    print, 'Move cursor to LEFT side of the dark data and click...'
    cursor, x1, y1, /down
    oplot, [x1, x1],10^!y.crange,line=2;,/noclip  ; Caution: noclip breaks Windows IDL
    print, 'Move cursor to RIGHT side of the dark data and click...'
    cursor, x2, y2, /down
    oplot, [x2, x2],10^!y.crange,line=2;,/noclip  ; Caution: noclip breaks Windows IDL
    ;  get scan data inside user limits
    wdark = where( data.time ge (x1) and data.time le (x2), numdark )
    if (numdark lt 2) then begin
      message, /info, 'ERROR: invalid time range, insufficient dark data... TRY AGAIN.'
    endif else begin
      darkdata = (n_elements(darkdata) eq 0) ? total(data_fa[*,wdark], 2)/numdark : [[darkdata], [total(data_fa[*,wdark], 2)/numdark]]
      darktimes = (n_elements(darktimes) eq 0) ? mean(data[wdark].time) : [darktimes, mean(data[wdark].time)]
      read, prompt='Select additional darks for time interpolation ? (Y or N) ...  ', ans
      ans = strupcase(strmid(ans,0,1))
    endelse
  endrep until (ans ne 'Y')
; else if /darkauto then select the first 30 seconds...
endif else if keyword_set(darkauto) then begin
  ;  TW - select first 30 seconds as dark
  message, /info, "Automatic dark subtraction (first 30 secs within SURF log time)..."
  numsecs = 30
  wdark = where( (data.time ge surfmin) and (data.time le (surfmin+numsecs)), numdark)
  if keyword_set(debug) then message, /info, "DEBUG: Using dark times " + strtrim(data[wdark[0]].time,2) + " to " + strtrim(data[wdark[numdark-1]].time,2) + " (" + strtrim(numdark,2) + " samples)"
  darkdata = total(data_fa[*, wdark], 2)/numdark
  darktimes = mean(data[wdark].time)
endif else message, /info, "WARNING: No dark data selected.  Set /darkman or /darkauto for dark subtraction."
; Now subtract dark data, if we have any
if (n_elements(darkdata) ne 0) then begin ; if we have dark data...
  if (size(darkdata,/n_dim) eq 1) then begin ; if we only have one dark time...
    ; Subtract constant dark value (per diode) from all data
    darklevels = rebin(darkdata, size(data_fa,/dim))
  endif else begin ; if we have multiple dark times...
    ; Interpolate dark measurements (per diode) to data time and then subtract from data
    darklevels = fltarr(size(data_fa,/dim))
    for i=0, numdiodes-1 do darklevels[i,*] = interpol(darkdata[i,*], darktimes, data.time)
  endelse
  data_fa -= darklevels
endif
  
;if keyword_set(darkman) or keyword_set(darkauto) then begin
;  darkdata = total(data_fa[*,wdark], 2)/numdark
;  data_fa -= rebin(darkdata, size(data_fa,/dim))
;endif

; Copy raw and minimally-preprocessed data into data struct
data.rawdata = data_dn
data.diodesig_fa = data_fa
if (n_elements(darkdata) ne 0) then data.darklevel = darklevels

; Copy appropriate data depending on instrument and channel...
case instrument of
  'XRS': begin
    ; Determine if channel is mono or quad, and array index of its signal data
    isQuad = ([0, 0, 1, 1])[where(ch eq valid_channels)]
    isignal = ([5, 4+6, 0+6, 1])[where(ch eq valid_channels)]
    if isQuad then begin ; Quad-diode, do quad-sums
      quadsignal = data_fa[isignal:isignal+3,*]
      data.signal = total(quadsignal,1)
      data.quadx = reform(((quadsignal[0,*]+quadsignal[3,*]) - (quadsignal[1,*]+quadsignal[2,*])))/data.signal
      data.quady = reform(((quadsignal[2,*]+quadsignal[3,*]) - (quadsignal[0,*]+quadsignal[1,*])))/data.signal
      data.quad13 = reform((quadsignal[2,*]-quadsignal[0,*]) / (quadsignal[0,*]+quadsignal[2,*]))
      data.quad24 = reform((quadsignal[3,*]-quadsignal[1,*]) / (quadsignal[1,*]+quadsignal[3,*]))
    endif else begin ;  simple AXUV-100 (no quad)
      data.signal = reform(data_fa[isignal,*])
    endelse
  end
  'EUVS': begin
    case ch of
      'A': begin
        choice_labels = ['25.6 nm (A1+A4)', '28.4 nm (A2)', '30.4 nm (A3)', 'Split Pixels']
        sig_labels = ['euvs_sa1', 'euvs_sa2', 'euvs_sa3', 'quady']
;        pixel_mask = bytarr(3,24)
;        pixel_mask[0,[2,3,4,5,6,24,23,22,21,20,19]-1] = 1
;        pixel_mask[1,[7,8,9,10,11]-1] = 1
;        pixel_mask[2,[18,17,16,15,14,13]-1] = 1
        isplits = [16,15]-1
;        for k=0,n_elements(sig_labels)-1 do begin
;          junk = execute('data.'+sig_labels[k]+' = reform(total(data_fa*rebin(pixel_mask['+k+',*],size(data_fa,/dim)),1))')
;          junk = execute('data.signal += data.'+sig_labels[k])
;        endfor
        data.euvs_sa1 = reform(total(data_fa[[2,3,4,5,6,24,23,22,21,20,19]-1,*],1))
        data.euvs_sa2 = reform(total(data_fa[[7,8,9,10,11]-1,*],1))
        data.euvs_sa3 = reform(total(data_fa[[18,17,16,15,14,13]-1,*],1))
        data.signal = data.euvs_sa1 + data.euvs_sa2 + data.euvs_sa3
        data.quady = reform((data_fa[isplits[0],*]-data_fa[isplits[1],*]) / (data_fa[isplits[0],*]+data_fa[isplits[1],*]))
      end
      'B': begin
        choice_labels = ['117.5 nm (B3)', '121.6 nm (B2)', '133.5 nm (B4)', '140.5 nm (B1)', 'Split Pixels']
        sig_labels = ['euvs_sa1', 'euvs_sa2', 'euvs_sa3', 'euvs_sa4', 'quady']
;        pixel_mask = bytarr(4,24)
;        pixel_mask[0,[18,17,16,15,14]-1] = 1
;        pixel_mask[1,[7,8,9,10,11,12]-1] = 1
;        pixel_mask[2,[23,22,21,20,19]-1] = 1
;        pixel_mask[3,[1,2,3,4,5,6]-1] = 1
        isplits = [10,9]-1
;        for k=0,n_elements(sig_labels)-1 do begin
;          junk = execute('data.'+sig_labels[k]+' = reform(total(data_fa*rebin(pixel_mask['+k+',*],size(data_fa,/dim)),1))')
;          junk = execute('data.signal += data.'+sig_labels[k])
;        endfor
        data.euvs_sa1 = reform(total(data_fa[[18,17,16,15,14]-1,*],1))
        data.euvs_sa2 = reform(total(data_fa[[7,8,9,10,11,12]-1,*],1))
        data.euvs_sa3 = reform(total(data_fa[[23,22,21,20,19]-1,*],1))
        data.euvs_sa4 = reform(total(data_fa[[1,2,3,4,5,6]-1,*],1))
        data.signal = data.euvs_sa1 + data.euvs_sa2 + data.euvs_sa3 + data.euvs_sa4
        data.quady = reform((data_fa[isplits[0],*]-data_fa[isplits[1],*]) / (data_fa[isplits[0],*]+data_fa[isplits[1],*]))
      end
      'C': begin
        choice_labels = ['Medium (core+wing)', 'Small (core)']
        sig_labels = ['euvs_sa1', 'euvs_sa2']
;        pixel_mask = bytarr(2,512)
;        pixel_mask[0,indgen(257)-128+274] = 1
;        pixel_mask[1,indgen(65)-32+274] = 1
;        for k=0,n_elements(sig_labels)-1 do begin
;          junk = execute('data.'+sig_labels[k]+' = reform(total(data_fa*rebin(pixel_mask['+k+',*],size(data_fa,/dim)),1))')
;          junk = execute('data.signal += data.'+sig_labels[k])
;        endfor
        data.euvs_sa1 = reform(total(data_fa[indgen(256)+274,*],1))
        data.euvs_sa2 = reform(total(data_fa[indgen(64)+274,*],1))
        data.signal = reform(total(data_fa[64:*,*],1))  ; Ignore first 64 pixels (dark)
      end
    endcase
  end
    'SPS': begin
    ; Quad-diode, do quad-sums - CHECK THAT THESE ARE THE CORRECT QUADS
    isignal = 0
    quadsignal = data_fa[isignal:isignal+3,*]
    data.signal = total(quadsignal,1)
    data.quadx = reform(((quadsignal[0,*]+quadsignal[3,*]) - (quadsignal[1,*]+quadsignal[2,*])))/data.signal
    data.quady = reform(((quadsignal[2,*]+quadsignal[3,*]) - (quadsignal[0,*]+quadsignal[1,*])))/data.signal
    data.quad13 = reform((quadsignal[2,*]-quadsignal[0,*]) / (quadsignal[0,*]+quadsignal[2,*]))
    data.quad24 = reform((quadsignal[3,*]-quadsignal[1,*]) / (quadsignal[1,*]+quadsignal[3,*]))
  end
endcase ; data contains proper values based on instrument and channel

; restrict data to times when SURF data exists
data_org = data
data = data[wgood]

; Get SURF BC at data times and normalize data by it to compensate for beam decay
smoothbc = smooth(surfdata[isurfbc,*], 3, /edge_trunc)  ; smooth to remove fast fluctuations
if keyword_set(correctbc) then smoothbc = surf_correct_bc(smoothbc)
data.surfbc = interpol(smoothbc, surfdata[isurftime,*], data.time)
data.signal /= data.surfbc
; For XRS and SPS, quad-sums do NOT need BC normalization, they are already normalized to each other... same for EUVS A/B split-pixels
; But for EUVS A/B/C subarrays, the "euvs_saX" variables hold regular data which DOES need normalization...
if (n_elements(sig_labels) ne 0) then begin
  for k=0, n_elements(sig_labels)-1 do if (sig_labels[k] ne 'quady') then junk = execute('data.'+sig_labels[k]+' /= data.surfbc')
endif

; Interpolate remaining SURF values to data times, and store
data.surfx = interpol( surfdata[isurfx,*], surfdata[isurftime,*], data.time )
data.surfy = interpol( surfdata[isurfy,*], surfdata[isurftime,*], data.time )
data.surfu = interpol( surfdata[isurfu,*], surfdata[isurftime,*], data.time )
data.surfv = interpol( surfdata[isurfv,*], surfdata[isurftime,*], data.time )
data.surfenergy = interpol( surfdata[isurfenergy,*], surfdata[isurftime,*], data.time )
data.surfsize = interpol( surfdata[isurfsize,*], surfdata[isurftime,*], data.time )
data.surfvalves = interpol( surfdata[isurfvalves,*], surfdata[isurftime,*], data.time )


setplot, thick=1.5
cc = rainbow(7)
cc = cc[[0, 4, 1]]

; Select time range of interest
!p.multi=[0,1,2]

ans = 'Y'
while (ans eq 'Y') do begin
xr = plotrange(data.time, margin=0.05); [min(data.time), max(data.time)]+[-1,1]*0.05*(max(data.time)-min(data.time))
yr1 = plotrange([data.surfx, data.surfy, data.surfu, data.surfv]); [min([data.surfx, data.surfy, data.surfu, data.surfv]), max([data.surfx, data.surfy, data.surfu, data.surfv])]+[-1,1]*0.025*(max([data.surfx, data.surfy, data.surfu, data.surfv])-min([data.surfx, data.surfy, data.surfu, data.surfv]))
plot, /nodata, [data.time, data.time, data.time, data.time], [data.surfx, data.surfy, data.surfu, data.surfv], xs=5, xrange = xr, ys=5, yrange = yr1, ymargin=[2,2]
; Shade where the valves are closed, for reference
; Don't do this if there is no valve position info!
if median(surfdata[isurfvalves,*]) ne -1 then begin
  polyfill, [surfmin, reform(surfdata[isurftime,*]), surfmax], [!y.crange[0], reform((surfdata[isurfvalves,*] eq 7)*!y.crange[0] + (surfdata[isurfvalves,*] ne 7)*!y.crange[1]), !y.crange[0]], color='dddddd'x, noclip=0
endif
!p.multi[0] = 0
plot, /noerase, /nodata, [data.time, data.time, data.time, data.time], [data.surfx, data.surfy, data.surfu, data.surfv], /xs, xrange = !x.crange, /ys, yrange = !y.crange, ymargin=[2,2], xtitle = 'Time [sec]', ytitle = 'SURF XYUV', title='DATA SELECTION - please restrict data window (if needed)'
oplot, data.time, data.surfx, color=cc[0], psym=4
oplot, data.time, data.surfy, psym=1
oplot, data.time, data.surfu, color=cc[1], psym=7
oplot, data.time, data.surfv, color=cc[2], psym=6
xyouts, [0.135, 0.135, 0.135, 0.135], [0.9, 0.875, 0.85, 0.825], /norm, ['X','Y','U','V'], color=[cc[0],!p.color,cc[1],cc[2]]
!p.multi[0] = 1
plot, /nodata, /noerase, data.time, data.signal, xs=5, xrange = !x.crange, ys=4
if median(surfdata[isurfvalves,*]) ne -1 then begin
  polyfill, [surfmin, reform(surfdata[isurftime,*]), surfmax], [!y.crange[0], reform((surfdata[isurfvalves,*] eq 7)*!y.crange[0] + (surfdata[isurfvalves,*] ne 7)*!y.crange[1]), !y.crange[0]], color='dddddd'x, noclip=0
endif
plot, /noerase, data.time, data.signal, /xs, xrange = !x.crange, xtitle = "Time [sec]", ytitle = "Total Signal [fA/mA]"
if (n_elements(sig_labels) ne 0) then begin
  cc = rainbow(n_elements(sig_labels))
  for k=0,n_elements(sig_labels)-1 do junk = execute('oplot, data.time, data.'+sig_labels[k]+', color=cc['+string(k)+']')
endif
yr2 = !y.crange
!p.multi[0] = 0

ans = 'Y'
read, prompt='Do you need to restrict the scan time ? (Y or N) ...  ', ans
ans = strupcase(strmid(ans,0,1))
while (ans eq 'Y') do begin
  print, 'Move cursor to LEFT side of the FOV scan and click... (either plot window is fine)'
  cursor, x1, y1, /down
;  oplot, [x1, x1], !y.crange, line = 2
  plot, /noerase, [x1, x1], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]
  !p.multi[0] = 1
;  oplot, [x1, x1],[-1d8,1d20],line=2
  plot, /noerase, [x1, x1], yr2, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
  print, 'Move cursor to RIGHT side of the FOV scan and click... (either plot window is fine)'
  cursor, x2, y2, /down
;  !p.multi[0] -= 1
;  oplot, [x2, x2],[-1d8,1d20],line=2
  plot, /noerase, [x2, x2], yr2, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
  !p.multi[0] = 0
  plot, /noerase, [x2, x2], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]
;  oplot, [x2, x2],[-1d8,1d20],line=2
;  !p.multi[0] = 0

  ; Copy out selected data and accumulate
  wtime = where( (data.time ge x1) and (data.time le x2), numtime )
  if (numtime lt 2) then begin
    message, /info, 'ERROR: no valid time range selected; try again.'
  endif else begin
    fovdata = (n_elements(fovdata) eq 0) ? data[wtime] : [fovdata, data[wtime]]
    read, prompt='Define additional interval ? (Y or N) ...  ', ans
    ans = strupcase(strmid(ans,0,1))
  endelse
endwhile
if (n_elements(fovdata) ne 0) then begin
  ; Make sure we don't have duplicate data if the user accidentally selected overlapping times...
  fovdata = fovdata[uniq(fovdata.time, sort(fovdata.time))]
  read, prompt = 'Re-plot restricted data set? (Y or N) ...  ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then data = temporary(fovdata)
endif
endwhile
; If we haven't selected anything yet, then select all
if (n_elements(fovdata) eq 0) then begin
  message, /info, "Selecting all data..."
  fovdata = data
endif

!p.multi=[0,1,1]

return, fovdata

END
