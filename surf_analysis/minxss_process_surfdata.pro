function minxss_process_surfdata, datafile, surffile, instr, fm=fm, surfdata=surfdata, tbase=tbase, toff=toff, darkman=darkman, darkauto=darkauto, despike=despike, debug=debug, correctbc=correctbc, help=help

; 20 Oct 2014 - Amir Caspi - Initial version, based on exis_process_surfdata.pro

; SETUP - errors and warnings, plus default parameters

; Check input viability - print usage message if needed
if (n_params() lt 2) or keyword_set(help) then begin
  message, /info, 'USAGE:  data = minxss_process_surfdata(<datafile>, <surffile>, <instr>, [, fm=fm, surfdata=surfdata, tbase=tbase, darkman=darkman, darkauto=darkauto, despike=despike, debug=debug, help=help ])'
  message, /info, 'RETURNS struct with processed data; OPTIONALLY outputs "raw" SURF data array in surfdata keyword.'
  message, /info, "Set tbase to Julian Date of reference time; data and SURF times will be reported as seconds after tbase... if tbase is undefined, times will be seconds after first data point, whose time will be returned in tbase for possible usage in subsequent calls"
  message, /info, "Set /darkman to select dark intervals manually; set /darkauto to use first 30 secs."
  return, -1
endif

; Determine flight model validity
if ((fm lt 1) or (fm gt 2)) then begin
  message, /info, "ERROR: Flight model number " + strtrim(fm, 2) + " invalid.  Expected 1-2."
  if (fm eq 0) then message, /info, 'WARNING: flight model 0 == ETU.  This is not yet supported.'
  return, -1
endif

; Determine the instrument we're using and check validity, error out if no valid instrument specified
instrument = n_elements(instr) gt 0 ? strupcase(strtrim(instr, 2)) : ''
valid_instr = ['X123','XP','SPS']
if (where(valid_instr eq instrument) eq -1) then begin
  message, /info, "ERROR: Invalid instrument.  Expected X123, XP, or SPS."
  return, -1
endif

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
  temp = read_surflog_et( surffile[i], despike=despike, debug=debug )
  surfdata = (n_elements(surfdata) eq 0) ? temp : [[temporary(surfdata)],[temp]]
endfor
if keyword_set(debug) then message, /info, 'DEBUG: SURF file = ', surffile
nsurftimes = n_elements(surfdata[isurfJDUT,*])

; Read MinXSS data
; Check if datafile is a string [file] or actual data...
if (typename(datafile) eq 'STRING') then begin
  for i=0, n_elements(datafile)-1 do begin
    minxss_read_packets28, datafile[i], sci=temp, verbose=debug
    minxssdata = (n_elements(minxssdata) eq 0) ? temp : [temporary(minxssdata),temp]
  endfor
endif else if (typename(datafile) eq 'STRUCT') then begin
  minxssdata = datafile
endif else begin
  message, /info, '<datafile> must be either string [array] or existing data struct.'
  return, -1
endelse
; TODO: sort based on time in case files given out of order

; Define the consolidated data structure we want to use
numdata = n_elements(minxssdata)
alldatatemp = [minxssdata[0].xps_data, minxssdata[0].sps_data, minxssdata[0].x123_fast_count, minxssdata[0].x123_slow_count, minxssdata[0].x123_gp_count, minxssdata[0].x123_spectrum] * 0d0
data = { time: 0d0, signal: 0d0, $ ; measurement time and detector-integrated signal
         x123_fast_sig: 0d0, x123_slow_sig: 0d0, x123_gp_sig: 0d0, $ ; X123 counters
         x123_spectrum: dblarr(n_elements(minxssdata[0].x123_spectrum)), $ ; X123 spectrum
         xp_fa: 0d0, sps_fa: dblarr(n_elements(minxssdata[0].sps_data)), $ ; XP/SPS diode signals, dark-subtracted
         quadx: 0d0, quady: 0d0, quad13: 0d0, quad24: 0d0, $ ; quad-sums for SPS
         surfbc: 0d0, surfx: 0.0, surfy: 0.0, surfu: 0.0, surfv: 0.0, $ ; SURF beam current and positions
         surfenergy: 0.0, surfsize: 0.0, surfvalves: 0.0, $ ; SURF beam energy and size (FUZZ --> size > 0)
         rawdata: minxssdata[0], darklevels: alldatatemp } ; raw data struct, dark level for each channel
data = replicate(data, numdata)

; Copy relevant data to struct
; Normalize X123 instrument data to per second (otherwise dark subtraction is not valid)
data.x123_fast_sig = minxssdata.x123_fast_count / minxssdata.x123_accum_time
data.x123_slow_sig = minxssdata.x123_slow_count / minxssdata.x123_accum_time
data.x123_gp_sig   = minxssdata.x123_gp_count   / minxssdata.x123_accum_time
data.x123_spectrum = minxssdata.x123_spectrum   / minxssdata.x123_accum_time
; Normalize and apply gains to ASIC data to get them into calibrated units (from DN/s to fA)
gain_xp = (fm eq 1) ? (6.6302) : (6.4350)  ; fC/DN
gain_sps = (fm eq 1) ? ([7.1081, 6.3791, 6.5085, 5.5359]) : ([6.5300, 6.4411, 6.7212, 6.8035])  ; fC/DN
data.xp_fa  = minxssdata.xps_data *       gain_xp                                    / minxssdata.sps_xps_count; now in fA
data.sps_fa = minxssdata.sps_data * rebin(gain_sps, size(minxssdata.sps_data, /dim)) / minxssdata.sps_xps_count; now in fA

; Get a big array of all our data together to make it easier to do dark subtraction
; First define the indices where various data pieces live
di_xp = 0
di_sps =       max(di_xp)        + 1 + indgen(n_elements(minxssdata[0].sps_data))
di_x123_fast = max(di_sps)       + 1 + indgen(n_elements(minxssdata[0].x123_fast_count))
di_x123_slow = max(di_x123_fast) + 1 + indgen(n_elements(minxssdata[0].x123_slow_count))
di_x123_gp =   max(di_x123_slow) + 1 + indgen(n_elements(minxssdata[0].x123_gp_count))
di_x123_spec = max(di_x123_gp)   + 1 + indgen(n_elements(minxssdata[0].x123_spectrum))
; Now define the giant consolidated array
data_fa = [[minxssdata.xps_data], [minxssdata.sps_data], [minxssdata.x123_fast_count], [minxssdata.x123_slow_count], [minxssdata.x123_gp_count], [minxssdata.x123_spectrum]]
numchannels = n_elements(data_fa[*,0])

; Convert data GPS seconds to Julian date
leapseconds = 16
data.time = julday(1, 6, 1980, 0, 0, long(data.time) - leapseconds) ; Get Julian Date (subtract leap seconds)

integtime = data.x123_real_time
; Convert data and SURF times to seconds from the first data point (allows transitions over day boundaries)
; **OR** seconds from the tbase passed in as a keyword...
if not keyword_set(tbase) then tbase = data[0].time
; Subtract half the integration time
data.time = (data.time - tbase) * 24. * 3600 - integtime/2.
; Convert SURF time
surfdata[isurftime,*] = (surfdata[isurfJDUT,*] - tbase) * 24. * 3600.
; KLUDGE - time offset
if keyword_set(toff) then surfdata[isurftime,*] -= toff
; determine valid time range for science data based on SURF data
surfmin = min(surfdata[isurftime,*])
surfmax = max(surfdata[isurftime,*])
wgood = where((data.time ge (surfmin)) and (data.time le (surfmax)))

; if /darkman, do dark subtraction manually...
if keyword_set(darkman) then begin
  setplot, thick=1.5
  cc = rainbow(numchannels-1)
  plot, /ylog, /nodata, data.time, data_fa[0,*], ys=5, yr=plotrange(data_fa[*,wgood] > 0.5), xs=5, xr=plotrange([surfmin,surfmax], margin=0.15)
  ; Shade where the valves are closed, for reference
  ; Don't do this if there is no valve position info!
  if median(surfdata[isurfvalves,*]) ne -1 then $
  	polyfill, [surfmin, reform(surfdata[isurftime,*]), surfmax], 10^[!y.crange[0], reform((surfdata[isurfvalves,*] eq 7)*!y.crange[0] + (surfdata[isurfvalves,*] ne 7)*!y.crange[1]), !y.crange[0]], color='dddddd'x, noclip=0
  plot, /ylog, /noerase, data.time, data_fa[0,*]>0.5, /ys, yr=10^!y.crange, /xs, xr=!x.crange, xtitle='Time [sec]', ytitle='Intensity [fA or cts]', title='DARK SELECTION - please select dark times'
  ; Plot the raw diode signal data for dark selection...
  for j=1,numchannels-1 do oplot, data.time, data_fa[j,*], color=cc[(j-1) mod 255] ; 255 is limitation of rainbow()
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
      darkdata = (n_elements(darkdata) eq 0) ? total(data_fa[*,wdark], 2)/numdark : [[temporary(darkdata)], [total(data_fa[*,wdark], 2)/numdark]]
      darktimes = (n_elements(darktimes) eq 0) ? mean(data[wdark].time) : [temporary(darktimes), mean(data[wdark].time)]
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
  darkdata = total(data_fa[*,wdark], 2)/numdark
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
    for i=0, numchannels-1 do darklevels[i,*] = interpol(darkdata[i,*], darktimes, data.time)
  endelse
  data_fa -= darklevels
endif

; Copy raw data for posterity, and processed data from big array back to where it belongs
data.rawdata = minxssdata
data.xp_fa = data_fa[[di_xp], *]
data.sps_fa = data_fa[[di_sps], *]
data.x123_fast_sig = data_fa[[di_x123_fast], *]
data.x123_slow_sig = data_fa[[di_x123_slow], *]
data.x123_gp_sig = data_fa[[di_x123_gp], *]
data.x123_spectrum = data_fa[[di_x123_spec], *]
if (n_elements(darkdata) ne 0) then data.darklevels = darklevels

; Process additional data depending on instrument and channel...
case instrument of
  'X123': begin
;    choice_labels = ['Slow counter';], 'Fast counter', 'Energy range']
;    sig_labels = ['x123_slow_sig';], 'x123_fast_sig', 'signal']
    data.signal = [[data.x123_fast_sig],[data.x123_slow_sig]]
    yunits = 'cps'
  end
  'XP': begin
    data.signal = data.xp_fa
    yunits = 'fA'
  end
  'SPS': begin
      data.signal = total(data.sps_fa,1)
      data.quadx = reform(((data.sps_fa[0,*]+data.sps_fa[3,*]) - (data.sps_fa[1,*]+data.sps_fa[2,*])))/data.signal
      data.quady = reform(((data.sps_fa[2,*]+data.sps_fa[3,*]) - (data.sps_fa[0,*]+data.sps_fa[1,*])))/data.signal
      data.quad13 = reform((data.sps_fa[2,*]-data.sps_fa[0,*]) / (data.sps_fa[0,*]+data.sps_fa[2,*]))
      data.quad24 = reform((data.sps_fa[3,*]-data.sps_fa[1,*]) / (data.sps_fa[1,*]+data.sps_fa[3,*]))
      yunits = 'fA'
  end
endcase ; data contains proper values based on instrument

; restrict data to times when SURF data exists
data_org = data
data = data[wgood]

; Get SURF BC at data times and normalize data by it to compensate for beam decay
smoothbc = smooth(surfdata[isurfbc,*], 3, /edge_trunc)  ; smooth to remove fast fluctuations
if keyword_set(correctbc) then smoothbc = surf_correct_bc(smoothbc)
data.surfbc = interpol(smoothbc, surfdata[isurftime,*], data.time)
data.signal /= data.surfbc
data.x123_spectrum /= transpose(rebin(data.surfbc, reverse(size(data.spectrum, /dim))))
data.x123_fast_sig /= data.surfbc
data.x123_slow_sig /= data.surfbc
data.x123_gp_sig /= data.surfbc
data.xp_fa /= data.surfbc
data.sps_fa /= transpose(rebin(data.surfbc, reverse(size(data.sps_fa, /dim))))

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
plot, /nodata, /noerase, data.time, data.signal, xs=5, xrange = !x.crange, ys=4, yrange = plotrange(data.signal)
if median(surfdata[isurfvalves,*]) ne -1 then begin
  polyfill, [surfmin, reform(surfdata[isurftime,*]), surfmax], [!y.crange[0], reform((surfdata[isurfvalves,*] eq 7)*!y.crange[0] + (surfdata[isurfvalves,*] ne 7)*!y.crange[1]), !y.crange[0]], color='dddddd'x, noclip=0
endif
plot, /noerase, data.time, data.signal[*,0], /xs, xrange = !x.crange, xtitle = "Time [sec]", ytitle = "Signal ["+yunits+"/mA]", /ys, yrange = !y.crange, ymargin=[2,2]
; Hack to plot second X123 counter
if (n_elements(data.signal) eq (2*n_elements(data.time))) then oplot, data.time, data.signal[*,1], color=cc[0]
yr2 = !y.crange
!p.multi[0] = 0

ans = 'Y'
read, prompt='Do you need to restrict the scan time ? (Y or N) ...  ', ans
ans = strupcase(strmid(ans,0,1))
while (ans eq 'Y') do begin
  print, 'Move cursor to LEFT side of the FOV scan and click... (either plot window is fine)'
  cursor, x1, y1, /down
  plot, /noerase, [x1, x1], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]  
  !p.multi[0] = 1
  plot, /noerase, [x1, x1], yr2, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
  print, 'Move cursor to RIGHT side of the FOV scan and click... (either plot window is fine)'
  cursor, x2, y2, /down
  plot, /noerase, [x2, x2], yr2, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr2
  !p.multi[0] = 0
  plot, /noerase, [x2, x2], yr1, line = 2, xs = 5, xrange = xr, ys = 5, yrange = yr1, ymargin = [2,2]

  ; Copy out selected data and accumulate
  wtime = where( (data.time ge x1) and (data.time le x2), numtime )
  if (numtime lt 2) then begin
    message, /info, 'ERROR: no valid time range selected; try again.'
  endif else begin
    fovdata = (n_elements(fovdata) eq 0) ? data[wtime] : [temporary(fovdata), data[wtime]]
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
