;+
; NAME:
;	minxss_fovmap
;
; PURPOSE:
;	Plot FOV map data for MinXSS instruments
;
; CATEGORY:
;	SURF calibration procedure
;
; CALLING SEQUENCE:  
;	minxss_fovmap, datafile, surffile, instrument [, orientation=orientation, noplot=noplot, solar_disk_avg=solar_disk_avg, multiplier=multiplier, despike=despike, mapstep=mapstep, minxssdata=minxssdata, surfdata=surfdata, outmap=outmap, debug=debug]
;
; INPUTS:
; surffile  The SURF log file, must be found in surf_dir path or default path
; instrument  Options are 'XP', 'SPS', or 'X123'
;	/debug		Option to print DEBUG messages
;
; OUTPUTS:  
;	PLOT		Showing FOV map data as Alpha and Beta scans
;
;	minxsss	  MinXSS pre-processed data
;	surfdata	SURFER PC log data
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Read/Plot the data using exis_process_surfdata.pro
;	3.  Re-plot as Alpha and Beta Scans
;
; MODIFICATION HISTORY:
;   20 Jul 2012 - Amir Caspi - Initial version
;   25 Jul 2012 - Amir Caspi - Added instrument orientation, changed 'data' keyword to 'minxssdata'
;   15 Aug 2012 - Amir Caspi - Added outmap output keyword, solar disk averaging, and ability to do all pixels at once (for EUVS A/B/C)
;   16 Apr 2013 - Amir Caspi - Added fm and correctbc keywords (passed to exis_process_surfdata)
;   06 Feb 2015 - Amir Caspi - Modified for use with MinXSS
;+

pro minxss_fovmap, datafile, surffile, instrument, fm=fm, orientation=orientation, noplot=noplot, solar_disk_avg=solar_disk_avg, multiplier=multiplier, despike=despike, correctbc=correctbc, mapstep=mapstep, minxssdata=minxssdata, surfdata=surfdata, outmap = outmap, includedark = includedark, debug=debug, help=help

; Check input viability - print usage message if needed
if (n_params() lt 2) or keyword_set(help) then begin
  message, /info, 'USAGE:  minxss_fovmap, <datafile>, <surffile>, <instrument> [, fm=fm, orientation=orientation, despike=despike, solar_disk_avg=solar_disk_avg, multiplier=multiplier, mapstep=mapstep, minxssdata=minxssdata, surfdata=surfdata, debug=debug, help=help ]'
  message, /info, 'PLOTS contour map of FOV relative variation from boresight; set /noplot to suppress plot (see outmap keyword, below)'
  message, /info, 'OPTIONALLY outputs FOV map data in outmap keyword, MinXSS data in minxssdata keyword, and "raw" SURF data in surfdata keyword.'
  message, /info, "Set fm to appropriate flight model number, 1-2 [DEFAULT: 1]"
  message, /info, "Instrument must be one of: XP, SPS, X123"
  message, /info, "<datafile> and <surffile> must absolute path, or relative path from current directory"
;  message, /info, "<datafile> and/or <surffile> may be an ARRAY of filenames, if a test was split across multiple files..."
  message, /info, "Set orientation < 0 or > 0 (e.g. -1 or +1) to signify -45 or +45 degree orientation, respectively, in BL-2 gimbal [DEFAULT = -45 orientation]"
  message, /info, "Set /multiplier to return a map of multiplicative factors instead of the DEFAULT difference map."
  message, /info, "Set /solar_disk_avg to average nominal FOV map over 0.5-degree solar disk."
  message, /info, "Set /despike to attempt spike removal in SURF beam current (MAY exclude good data by accident)'
  message, /info, "Set /correctbc to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)"
  message, /info, "Set mapstep to override automatic calculation of distance (in degrees) between successive alpha/beta points"
  return
endif
; Input parameters datafile, surffile, instrument, are all checked for viability in minxss_process_surfdata... no need to check them here as long as they're present.

; Set BL-2 gimbal angle to +/- 45 based on sign of orientation keyword (if set; DEFAULT = -45)
if not keyword_set(orientation) then message, /info, "WARNING: orientation not specified, ASSUMING -45 degrees..."
orient = (keyword_set(orientation) ? (0 + (orientation gt 0) - (orientation lt 0)) : -1) * 45 * !dpi/180.
if keyword_set(debug) then print, "DEBUG: Set BL-2 gimbal orientation angle to ",strtrim(orient*180./!pi,2)," degrees"

if n_elements(surffile) gt 1 then print, "WARNING: Multiple SURF files requested... each will be processed individually, THEN concatenated at the end..."
for i=0, n_elements(surffile)-1 do begin
  print, "Processing SURF file "+strtrim(i+1,2)+" of "+strtrim(n_elements(surffile),2)
  fovdata_temp = minxss_process_surfdata(datafile, surffile[i], instrument, fm=fm, surfdata=surfdata_temp, /darkman, correctbc=correctbc, despike=despike, tbase=tbase, debug=debug)
  if ((n_elements(fovdata_temp) eq 1) && (fovdata_temp eq -1)) then begin
    message, /info, "ERROR: minxss_process_surfdata() returned -1; ABORTING..."
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

; Set labels for analysis and plotting
instr = strupcase(strtrim(instrument, 2))
case instr of
  'X123': begin
    choice_labels = ['Fast Counter', 'Slow Counter']
    sig_labels = ['x123_fast_sig', 'x123_slow_sig']
  end
  'XP': begin
  end
  'SPS': begin
  end
endcase

; Exclude dark data
; Do this by checking the SURF valve positions (all open = good, any closed = bad)
; If ENTIRE file shows dark (0) or missing (-1) valves, skip this step
if not keyword_set(includedark) then begin
if ((median(fovdata.surfvalves) ne -1) and (median(fovdata.surfvalves) ne 0)) then begin
  ; REMOVE TWO additional data points on either side, to account for valve motion latency
  wgood = where((fovdata.surfvalves eq 7) and (shift(fovdata.surfvalves, 1) eq 7) and (shift(fovdata.surfvalves, -1) eq 7) and (shift(fovdata.surfvalves, 2) eq 7) and (shift(fovdata.surfvalves, -2) eq 7), ngood)
;  darklevel = mean(fovdata.rawcnt - fovdata.cnt * fovdata.surfbc)
;  wgood = where( fovdata.rawcnt gt darklevel * 2., ngood )  ; assumes S/N > 2 for real data...
  if (ngood lt 10) then begin
    print, 'ERROR finding enough good data for fovmap!'
    return
  endif
  fovdata = fovdata[wgood]
endif
endif

;
;	determine which 2 axes are moving - expect it to be Yaw & Pitch, error out otherwise
;
  diff = fltarr(4)
;  diff[0] = max(fovdata.surfx) - min(fovdata.surfx)
;  diff[1] = max(fovdata.surfy) - min(fovdata.surfy)
  diff[2] = max(fovdata.surfu) - min(fovdata.surfu)
  diff[3] = max(fovdata.surfv) - min(fovdata.surfv)
  ;  Get First Maximum Range
  temp = max(diff, wdiff)
  case wdiff of
    0: begin
       type='X'
       end
    1: begin
       type='Y'
       end
    2: begin
       type='Yaw (U)'
;       sdata1 = fovdata.surfu
;       sdata1_fine = surfdata[isurfu,*]
       end
    3: begin
       type='Pitch (V)'
;       sdata1 = fovdata.surfv
;       sdata1_fine = surfdata[isurfv,*]
      end
  endcase
  ;  Get Second Maximum Range
  diff2 = diff
  diff2[wdiff] = 0.0
  temp = max(diff2, wdiff2)
  case wdiff2 of
    0: begin
       type+= ' & X'
       end
    1: begin
       type+= ' & Y'
       end
    2: begin
       type+= ' & Yaw (U)'
;       sdata2 = fovdata.surfu
;       sdata2_fine = surfdata[isurfu,*]
       end
    3: begin
       type+= ' & Pitch (V)'
;       sdata2 = fovdata.surfv
;       sdata2_fine = surfdata[isurfv,*]
      end
  endcase
tdata = fovdata.time
tdata_fine = surfdata[isurftime,*]

if ((wdiff ne 2) or (wdiff2 ne 3)) and ((wdiff ne 3) or (wdiff2 ne 2)) then begin
    message, /info, 'ERROR: invalid map type: ' + type + '; expected Yaw (U) & Pitch (V)'
    return
endif

print, 'Doing FOV map plots for ', type

;
; Sort Yaw and Pitch data into moving or not moving
; Changed Raster labview VI so does Yaw first and then Pitch (before did them at same time)
; so need to verify adjacent points didn't change either
;
;sdiff1 = sdata1_fine - shift(sdata1_fine,1)
;sdiff1[0] = -999
;sdiff2 = sdata2_fine - shift(sdata2_fine,1)
;sdiff2[0] = -999

sdata_x_fine = surfdata[isurfx,*]
sdata_y_fine = surfdata[isurfy,*]
sdata_yaw = fovdata.surfu
sdata_u_fine = surfdata[isurfu,*]
sdata_pitch = fovdata.surfv
sdata_v_fine = surfdata[isurfv,*]

sdiff_x = sdata_x_fine - shift(sdata_x_fine,1)  &  sdiff_x[0] = -999
sdiff_y = sdata_y_fine - shift(sdata_y_fine,1)  &  sdiff_y[0] = -999
sdiff_u = sdata_u_fine - shift(sdata_u_fine,1)  &  sdiff_u[0] = -999
sdiff_v = sdata_v_fine - shift(sdata_v_fine,1)  &  sdiff_v[0] = -999

; @TODO: change line below to allow small moves, e.g. gimbal settling... WHAT EPSILON TO USE?  This should also affect the number of stable points (line 310)
epsilon = 0.005
wgood = where( (abs(sdiff_x) le epsilon) and (abs(sdiff_y) le epsilon) and (abs(sdiff_u) le epsilon) and (abs(sdiff_v) le epsilon), ngood )
if (ngood lt 15) then begin
  message, /info, 'ERROR: not enough stable map data points'
  return
endif
gooddiff = [wgood - shift(wgood,1), -999]
runstarts = where( gooddiff ne 1 )
integtime = mean(fovdata.rawdata.x123_real_time) / 1000 ; convert ms to s

title = 'FOV Uniformity: ' + instr+' (FM'+strtrim(fm,2)+', '+string(round(orient*180./!pi), format='(I+0)')+string(176b)+')'
if (n_elements(sig_labels) ne 0) then begin
  junk = 'Which data set to use?  '
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
  ;  if (ans eq 0) then begin
  ;    cdata = fovdata.signal
  ;    ytitle += ': Full Detector'
  ;  endif else begin
  junk = execute('cdata = fovdata.'+sig_labels[ans-1]+' & title += ": '+choice_labels[ans-1]+'"')
  ;  endelse
endif else begin ; For XP and SPS, use total signal
  cdata = fovdata.signal
endelse ; cdata now contains the correct signal(s) to use

; Find all the science data during stable periods, and mark it
for k = 1, n_elements(runstarts)-1 do begin
  tmax = (tdata_fine[wgood[runstarts[k]-1]])[0]
  tmin = (tdata_fine[wgood[runstarts[k-1]]])[0]
  tgood = where( (tdata ge (tmin + integtime/2.)) and (tdata le (tmax - integtime/2.)), ngood )
  ; If sufficient good data exists during this stable period, average it and accumulate
  if (ngood ge 3) then begin
    ctemp = dblarr(n_elements(cdata[0,*]))   &   ectemp = ctemp
    for j = 0, n_elements(ctemp)-1 do begin
      cmax = max(cdata[tgood,j])
      tgood2 = where(abs(cdata[tgood,j]) ge abs(cmax * 0.75), ngood2)  ; Eliminate dropouts
      ctemp[j] = mean(cdata[tgood[tgood2],j])  ; Average all points
      ectemp[j] = stddev(cdata[tgood[tgood2],j])/sqrt(ngood2)  ; Estimated error
      ; Error estimate is lower limit, does NOT properly propagate errors from dark subtraction or other summing
    endfor
    stemp_u = sdata_yaw[tgood[0]] ; Save SURF value (no need to average since it's the same for all points in this run)
    stemp_v = sdata_pitch[tgood[0]]
;    if keyword_set(debug) then message, /info, "DEBUG: "+stemp, " ---- ", ctemp, " ---- ", cdata[tgood[tgood2]]
    cdata_avg = (n_elements(cdata_avg) eq 0) ? ctemp : [[cdata_avg], [ctemp]]
    ecdata_avg = (n_elements(ecdata_avg) eq 0) ? ectemp : [[ecdata_avg], [ectemp]]
    sdata_u_avg = (n_elements(sdata_u_avg) eq 0) ? stemp_u : [sdata_u_avg, stemp_u]
    sdata_v_avg = (n_elements(sdata_v_avg) eq 0) ? stemp_v : [sdata_v_avg, stemp_v]
  endif else if keyword_set(debug) then print, "No good data for time interval: ",tmin,tmax
endfor

;
;	save only the non-moving data for the plots
;
cmap = transpose(cdata_avg)
ecmap = transpose(ecdata_avg)
;if (wdiff eq 2) then begin
  ; Yaw first
;  yaws = sdata1_avg
;  pitches = sdata2_avg
;endif else begin
  ; Pitch first
;  yaws = sdata2_avg
;  pitches = sdata1_avg
;endelse
yaws = sdata_u_avg
pitches = sdata_v_avg

;	Calculate instrument ALPHA and BETA angles based on BL-2 gimbal PITCH and YAW
;	Yaws are NEGATIVE compared to the usual (sane) direction...
;alphas = -sqrt(1/2.) * yaws - sqrt(1/2.) * pitches
;betas = -sqrt(1/2.) * yaws + sqrt(1/2.) * pitches
alphas = cos(orient) * (-yaws) + sin(orient) * pitches
betas = -sin(orient) * (-yaws) + cos(orient) * pitches

; If mapstep not given, find most common step size of alpha and beta (ASSUMES row/col scanning) and ROUND to nearest 0.1 degree
if not keyword_set(mapstep) then begin
  mapstep = median(abs((alphas+betas)-shift(alphas+betas,1)))
  mapstep = round(mapstep/.1d)*.1d
endif

; Re-grid cmap to 2D array based on alpha, beta positions (average points with identical position)
alpha_rnd = round(alphas/mapstep)*mapstep  &  alphas = alpha_rnd[uniq(alpha_rnd,sort(alpha_rnd))]
n_alpha = n_elements(alphas)
beta_rnd = round(betas/mapstep)*mapstep  &  betas = beta_rnd[uniq(beta_rnd,sort(beta_rnd))]
n_beta = n_elements(betas)
cmap_regrid = fltarr(n_alpha,n_beta, n_elements(cmap[0,*]))   &   ecmap_regrid = cmap_regrid

for i=0,n_alpha-1 do begin
  for j=0,n_beta-1 do begin
    wgood = where((alpha_rnd eq alphas[i]) and (beta_rnd eq betas[j]), ngood)
    if (ngood ne 0) then begin
      ; Ignore first and last center-point measurements...
;      if ((i eq n_alpha/2) and (j eq n_beta/2)) then wgood = wgood[where((wgood ge 2) and (wgood le n_elements(cmap_regrid)))]
      cmap_regrid[i,j,*] = mean(cmap[wgood,*],dim=1)
      ecmap_regrid[i,j,*] = sqrt(total(ecmap[wgood,*]^2,1))/sqrt(ngood)
    endif else begin
      cmap_regrid[i,j,*] = !values.f_nan
      ecmap_regrid[i,j,*] = !values.f_nan
      if keyword_set(debug) then print,"DEBUG: No good data for (alpha,beta) = ("+string(alphas[i],format='(F4.1)')+','+string(betas[j],format='(F4.1)')+')'
    endelse
  endfor
endfor

; Normalize map to center-point average
;cmap_ctr_avg = mean(cmap[where((abs(alphas) le mapstep/10.) and (abs(betas) le mapstep/10.))])
;cmap = ((cmap/cmap_ctr_avg) - 1.) * 100.
a0 = where(alphas eq 0)
b0 = where(betas eq 0)
pct_factor = keyword_set(multiplier) ? 1. : 100.
add_factor = keyword_set(multiplier) ? 0. : 1.
for k=0,n_elements(cmap[0,*])-1 do begin
  ecmap_regrid[*,*,k] *= pct_factor/(cmap_regrid[a0,b0,k])[0] ; Must do errors first because of reassignment below...
  cmap_regrid[*,*,k] = ((cmap_regrid[*,*,k]/(cmap_regrid[a0,b0,k])[0]) - add_factor) * pct_factor
endfor

if not keyword_set(solar_disk_avg) then begin
  ; Our FOV map is complete, store it in the output variable
  outmap = { alphas_deg: alphas, betas_deg: betas, fovmap_pct: cmap_regrid, errormap_pct: ecmap_regrid }
endif else begin
  ; We need to average over the 0.5-degree solar disk, for each point...
  ; Since our grid is uniform in each dimension, begin by calculating the area mask - the fractions of each grid point covered by disk centered at (0,0)
  cmap_new = cmap_regrid * 0.
  ecmap_new = ecmap_regrid * 0.
  areas = fltarr(n_alpha,n_beta)
  for i=0,n_alpha-1 do begin
    for j=0,n_beta-1 do begin
      areas[i,j] = poly_circarea(transpose([[alphas[i]-(mapstep/2.),alphas[i]+(mapstep/2.),alphas[i]+(mapstep/2.),alphas[i]-(mapstep/2.)],[betas[j]-(mapstep/2.),betas[j]-(mapstep/2.),betas[j]+(mapstep/2.),betas[j]+(mapstep/2.)]]), 0.25, [0,0])
    endfor
  endfor
  ; Now, for each point, shift the area mask to be centered at that point and calculate the weighted average
  for i=0,n_alpha-1 do begin
    for j=0,n_beta-1 do begin
      mask = rebin(ashift(areas, [i-a0,j-b0], fill=0.),size(cmap_new,/dim))
      cmap_new[i,j,*] = total(total(mask * cmap_regrid,2),1) / total(total(mask,2),1)
      ecmap_new[i,j,*] = sqrt(total(total((mask * ecmap_regrid)^2,2),1))
    endfor
  endfor

  ; Store the smoothed map in the previous variables, so plotting below works either way...
  cmap_orig = cmap_regrid  &  ecmap_orig = ecmap_regrid
  cmap_regrid = cmap_new  &  ecmap_regrid = ecmap_new
  title += ' [Solar Disk Average]'
  ; And, output the smoothed FOV map, but restrict it ONLY to where we don't clip, within 0.25 degrees of the edges
;  a5 = where(abs(alphas) le 0.5)  &  b5 = where(abs(betas) le 0.5)
  a5 = where((abs(alphas) + 0.25) le min(abs([min(alphas),max(alphas)])))  &  b5 = where((abs(betas) + 0.25) le min(abs([min(betas),max(betas)])))
  outmap = { alphas_deg: alphas[a5], betas_deg: betas[b5], fovmap_pct: cmap_regrid[a5,b5,*], errormap_pct: ecmap_regrid[a5,b5,*] }
endelse

if not keyword_set(noplot) then begin

if keyword_set(debug) then begin
  ans = ''
  read,prompt='DEBUG: Hit RETURN for Alpha/Beta DEBUG grid plot ... ', ans
  contour, cmap_regrid, alphas, betas, /iso, /nodata, /xs, /ys, xtitle = 'Alpha [deg]', ytitle = 'Beta [deg]', title = title, xr=plotrange(alphas), yr=plotrange(betas)
  for i=0,n_alpha-1 do begin
    for j=0,n_beta-1 do begin
      xyouts, alphas[i], betas[j], string(cmap_regrid[i,j],format='(F+4.1)')
    endfor
  endfor

  ; ask user if ready for next plot
  ans = ''
  read,prompt='DEBUG: Hit RETURN for Alpha/Beta contour plot ... ', ans

endif

; Bilinearly interpolate on 5x finer grid
;alphas = (findgen((n_alpha-1)*5+1)/((n_alpha-1)*5)-0.5) * (max(alphas)-min(alphas))
;betas = (findgen((n_beta-1)*5+1)/((n_beta-1)*5)-0.5) * (max(betas)-min(betas))
alphas = interpol(alphas, findgen(n_alpha), findgen((n_alpha-1)*5+1)/5.)
betas = interpol(betas, findgen(n_beta), findgen((n_beta-1)*5+1)/5.)
cmap_regrid = bilinear(cmap_regrid,findgen((n_alpha-1)*5+1)/5.,findgen((n_beta-1)*5+1)/5.)

neg_thresh = keyword_set(multiplier) ? 1. : 0.
format_str = keyword_set(multiplier) ? '(F5.3)' : '(F+4.1)'
pct_str = keyword_set(multiplier) ? '' : '%'

contour, cmap_regrid, alphas, betas, /iso, /nodata, /xs, /ys, xtitle = 'Alpha [deg]', ytitle = 'Beta [deg]', title = title, xr=plotrange(alphas), yr=plotrange(betas)
device,decomp=0
loadct, 1, /silent ; Blue/White
wgood = where(cmap_regrid lt neg_thresh, ngood) ; Plot negative deviations in blue...
percentstep = ((instr eq 'XP') ? 0.5 : ((instr eq 'SPS') ? 0.5 : 0.5)) / (keyword_set(multiplier) ? 100. : 1.)
if (ngood ne 0) then begin
  minval = floor(min(cmap_regrid[wgood])/percentstep)*percentstep ; minimum contour level needed in tenths of a percent (NEGATIVE)
  levels = findgen(abs(minval-neg_thresh)/percentstep+1)*percentstep + minval ; contours from minval up to 0, in tenths of a percent
  colors = indgen(n_elements(levels))*100/(n_elements(levels)-1)+155 ; darker blue = more negative
  contour, cmap_regrid, alphas, betas, levels=levels, c_colors=colors, /iso, /cell_fill, /over
  contour, cmap_regrid, alphas, betas, levels=levels, /iso, /over, c_charsize=2, c_annotation=string(levels[0:n_elements(levels)-2],format=format_str)+pct_str
endif
loadct, 3, /silent ; Red Temperature
wgood = where(cmap_regrid gt neg_thresh, ngood) ; Plot positive deviations in red...
if (ngood ne 0) then begin
  minval = ceil(max(cmap_regrid[wgood])/percentstep)*percentstep ; maximum contour level needed in tenths of a percent (POSITIVE)
  levels = findgen(round(abs(minval-neg_thresh)/percentstep+1))*percentstep + neg_thresh; contours from 0 up to minval, in tenths of a percent
  colors = reverse(indgen(n_elements(levels))*100/(n_elements(levels)-1)+135) ; reversed so darker red = more positive
  contour,cmap_regrid,alphas,betas,levels=levels,c_colors=colors,/iso,/cell_fill,/over,/noerase
  contour,cmap_regrid,alphas,betas,levels=levels,/iso,/over,c_charsize=2,c_annotation=string(levels,format=format_str)+pct_str
endif

; Overplot circle at +/- 20 arcmin to show PORD requirements
circle_points = transpose([[(20./60.) * cos((2 * !PI / 99.0) * FINDGEN(100))], [(20./60.) * sin((2 * !PI / 99.0) * FINDGEN(100))]])
;plots, 0., 0., psym=7, thick=4,symsize=2
plots, 0., 0., psym=1, thick=4,symsize=2.5
oplot, circle_points[0,*], circle_points[1,*], thick=4
circle_points = transpose([[(27./60.) * cos((2 * !PI / 99.0) * FINDGEN(100))], [(27./60.) * sin((2 * !PI / 99.0) * FINDGEN(100))]])
oplot, circle_points[0,*], circle_points[1,*], thick=4, color=125

endif ; if not noplot

minxssdata = fovdata

return
end
