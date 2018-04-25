;+
; NAME:
;	  rocket_x123_fovmap
;
; PURPOSE:
;	  Plot FOV map data for rocket X123 instrument
;
; CATEGORY:
;	  SURF calibration procedure
;
; CALLING SEQUENCE:  
;	  minxss_fovmap, datafile, surffile [, orientation=orientation, noplot=noplot, solar_disk_avg=solar_disk_avg, multiplier=multiplier, despike=despike, mapstep=mapstep, sci=sci, surferData=surferData, outmap=outmap, debug=debug]
;
; INPUTS:
;   datafile [string]: The Hydra telemetry binary file containing the calibration data from the rocket instruments
;   surffile [string]: The SURF log file, must be found in surf_dir path or default path
; 
; OPTIONAL INPUTS:
;   orientation [integer]: Set orientation < 0 or > 0 (e.g. -1 or +1) to signify -45 or +45 degree orientation, respectively, in BL-2 gimbal 
;                          Default = -45.
;   mapstep [float]:       Set to override automatic calculation of distance (in degrees) between successive alpha/beta points
;   
; KEYWORDS:
;   NOPLOT:         Set to suppress plot (see outmap keyword, below)
;   MULTIPLIER:     Set to return a map of multiplicative factors instead of the DEFAULT difference map.
;   DESPIKE:        Set to attempt spike removal in SURF beam current (MAY exclude good data by accident)
;   CORRECTBC:      Set to modify SURF beam current using empirical correction for potential nonlinearity (MAY NOT BE ACCURATE)
;   INCLUDEDARK:    Set this to prevent automatic exclusion of dark data
;	  DEBUG:          Option to print DEBUG messages
;	  VERBOSE:        Set this to print additional processing messages
;
; OUTPUTS:  
;	  Plot showing FOV map data as Alpha and Beta scans
;	  
;	OPTIONAL OUTPUTS:
;	  sci [arr of str]:      Returns the processed science data
;	  surferData [arr of str]: SURFER PC log data
;	  outmap [?]:            FOV map data
;
; COMMON BLOCKS:
;	  None
;
; PROCEDURE:
;	  1. Check input parameters
;	  2. Read/Plot the data using exis_process_surfdata.pro
;	  3. Re-plot as Alpha and Beta Scans
;
; MODIFICATION HISTORY:
;   2018-03-29: James Paul Mason: Initial script based on Amir Caspi's minxss_fovmap.pro.
;                                 Significant cleaning of this header. Modified MinXSS specifics to rocket specifics.
;   2018-04-02: James Paul Mason: Many edits to this code to get it running for rocket X123.
;+
pro rocket_x123_fovmap, datafile, surffile, $
                        mapstep=mapstep, $
                        ORIENTATION=ORIENTATION, NOPLOT=NOPLOT, MULTIPLIER=MULTIPLIER, DESPIKE=DESPIKE, CORRECTBC=CORRECTBC, INCLUDEDARK = INCLUDEDARK, DEBUG=DEBUG, VERBOSE=VERBOSE, $
                        sci=sci, surferData=surferData, outmap = outmap

; Defaults
IF orientation EQ !NULL THEN BEGIN
  orientation = -45.0d * !DtoR
  IF keyword_set(VERBOSE) THEN BEGIN
    message, /INFO, "WARNING: Gimbal orientation not specified, setting to -45º"
  ENDIF
ENDIF

; Read rocket telemetry and SURFER file
read_hydra_rxrs, datafile, hk=hk, sci=sci, sps=sps, VERBOSE=VERBOSE
surferData = read_surfer_data(surffile)

; Consolidate relevant hydra and SURFER data into a single structure
fovdata = rocket_x123_surfer_consolidate(sci, surferData)

; Set labels for analysis and plotting
choice_labels = ['Fast Counter', 'Slow Counter']
sig_labels = ['X123_FAST_CPS', 'X123_SLOW_CPS']

; Exclude dark data
; Do this by checking the SURF valve positions (all open = good, any closed = bad)
; If ENTIRE file shows dark (0) or missing (-1) valves, skip this step
if not keyword_set(includedark) then begin
  if median(fovdata.surf_valves) NE -1 then begin
    ; REMOVE TWO additional data points on either side, to account for valve motion latency
    wgood = where((fovdata.surf_valves eq 7) and (shift(fovdata.surf_valves, 1) eq 7) and (shift(fovdata.surf_valves, -1) eq 7) and (shift(fovdata.surf_valves, 2) eq 7) and (shift(fovdata.surf_valves, -2) eq 7), ngood)
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
  diff[2] = max(surferData.yaw_deg) - min(surferData.yaw_deg)
  diff[3] = max(surferData.pitch_deg) - min(surferData.pitch_deg)
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
;       sdata1_fine = surferData[isurfu,*]
       end
    3: begin
       type='Pitch (V)'
;       sdata1 = fovdata.surfv
;       sdata1_fine = surferData[isurfv,*]
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
;       sdata2_fine = surferData[isurfu,*]
       end
    3: begin
       type+= ' & Pitch (V)'
;       sdata2 = fovdata.surfv
;       sdata2_fine = surferData[isurfv,*]
      end
  endcase
tdata = fovdata.sec_since_start
tdata_fine = surferData.sec_since_start

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
sdata_x_fine = surferData.x_pos_inches
sdata_y_fine = surferData.y_pos_inches
sdata_yaw = surferData.yaw_deg ;fovdata.yaw_deg ; FIXME: 
sdata_u_fine = surferData.yaw_deg
sdata_pitch = surferData.pitch_deg ;fovdata.pitch_deg ; FIXME: 
sdata_v_fine = surferData.pitch_deg

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
integtime = mean(fovdata.x123_real_time) / 1000 ; convert ms to s

title = 'FOV Uniformity: ' + 'X123' + ', '+string(round(orientation*180./!pi), format='(I+0)')+string(176b)+')'
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
  ;cdata = fovdata.signal
endelse ; cdata now contains the correct signal(s) to use

; Find all the science data during stable periods, and mark it
for k = 1, n_elements(runstarts)-1 do begin
  tmax = (tdata_fine[wgood[runstarts[k]-1]])[0]
  tmin = (tdata_fine[wgood[runstarts[k-1]]])[0]
  tgood = where( (tdata ge (tmin + integtime/2.)) and (tdata le (tmax - integtime/2.)), ngood )
  ; If sufficient good data exists during this stable period, average it and accumulate
  if (ngood ge 3) then begin
    ctemp = dblarr(n_elements(cdata))   &   ectemp = ctemp
    cmax = max(cdata[tgood])
    tgood2 = where(abs(cdata[tgood]) ge abs(cmax * 0.75), ngood2)  ; Eliminate dropouts
    ctemp = mean(cdata[tgood[tgood2]])  ; Average all points
    ectemp = stddev(cdata[tgood[tgood2]])/sqrt(ngood2)  ; Estimated error
    ; Error estimate is lower limit, does NOT properly propagate errors from dark subtraction or other summing
    stemp_u = sdata_yaw[tgood[0]] ; Save SURF value (no need to average since it's the same for all points in this run)
    stemp_v = sdata_pitch[tgood[0]]
    cdata_avg = (n_elements(cdata_avg) eq 0) ? ctemp : [[cdata_avg], [ctemp]]
    ecdata_avg = (n_elements(ecdata_avg) eq 0) ? ectemp : [[ecdata_avg], [ectemp]]
    sdata_u_avg = (n_elements(sdata_u_avg) eq 0) ? stemp_u : [sdata_u_avg, stemp_u]
    sdata_v_avg = (n_elements(sdata_v_avg) eq 0) ? stemp_v : [sdata_v_avg, stemp_v]
  endif else if keyword_set(debug) then print, "No good data for time interval: ", strtrim(tmin, 2), + ' : ' + strtrim(tmax, 2)
endfor

;
;	save only the non-moving data for the plots
;
cmap = transpose(cdata_avg)
ecmap = transpose(ecdata_avg)
yaws = sdata_u_avg
pitches = sdata_v_avg

;	Calculate instrument ALPHA and BETA angles based on BL-2 gimbal PITCH and YAW
;	Yaws are NEGATIVE compared to the usual (sane) direction...
;alphas = -sqrt(1/2.) * yaws - sqrt(1/2.) * pitches
;betas = -sqrt(1/2.) * yaws + sqrt(1/2.) * pitches
alphas = cos(orientation) * (-yaws) + sin(orientation) * pitches
betas = -sin(orientation) * (-yaws) + cos(orientation) * pitches
; If mapstep not given, find most common step size of alpha and beta (ASSUMES row/col scanning) and ROUND to nearest 0.1 degree
if not keyword_set(mapstep) then begin
  alphaUnique = alphas[uniq(alphas, sort(alphas))]
  betaUnique = betas[uniq(betas, sort(betas))]
  mapstep = median(abs((alphaUnique+betaUnique)-shift(alphaUnique+betaUnique,1)))
  mapstep = round(mapstep/.1d)*.1d
endif

; Re-grid cmap to 2D array based on alpha, beta positions (average points with identical position)
alpha_rnd = round(alphas/mapstep)*mapstep  &  alphas = alpha_rnd[uniq(alpha_rnd,sort(alpha_rnd))]
n_alpha = n_elements(alphas)
beta_rnd = round(betas/mapstep)*mapstep  &  betas = beta_rnd[uniq(beta_rnd,sort(beta_rnd))]
n_beta = n_elements(betas)
cmap_regrid = fltarr(n_alpha, n_beta, n_elements(cmap))   &   ecmap_regrid = cmap_regrid

for i=0,n_alpha-1 do begin
  for j=0,n_beta-1 do begin
    wgood = where((alpha_rnd eq alphas[i]) and (beta_rnd eq betas[j]), ngood)
    if (ngood ne 0) then begin
      ; Ignore first and last center-point measurements...
;      if ((i eq n_alpha/2) and (j eq n_beta/2)) then wgood = wgood[where((wgood ge 2) and (wgood le n_elements(cmap_regrid)))]
      cmap_regrid[i,j,*] = mean(cmap[wgood],dim=1)
      ecmap_regrid[i,j,*] = sqrt(total(ecmap[wgood]^2,1))/sqrt(ngood)
    endif else begin
      cmap_regrid[i,j,*] = !values.f_nan
      ecmap_regrid[i,j,*] = !values.f_nan
      if keyword_set(debug) then print,"DEBUG: No good data for (alpha,beta) = ("+string(alphas[i],format='(F4.1)')+','+string(betas[j],format='(F4.1)')+')'
    endelse
  endfor
endfor

; Normalize map to center-point average
a0 = where(alphas eq 0)
b0 = where(betas eq 0)
pct_factor = keyword_set(multiplier) ? 1. : 100.
add_factor = keyword_set(multiplier) ? 0. : 1.
for k=0,n_elements(cmap)-1 do begin
  ecmap_regrid[*,*,k] *= pct_factor/(cmap_regrid[a0,b0,k])[0] ; Must do errors first because of reassignment below...
  cmap_regrid[*,*,k] = ((cmap_regrid[*,*,k]/(cmap_regrid[a0,b0,k])[0]) - add_factor) * pct_factor
endfor

if not keyword_set(noplot) then begin
  ; Bilinearly interpolate on 5x finer grid
  alphas = interpol(alphas, findgen(n_alpha), findgen((n_alpha-1)*5+1)/5.)
  betas = interpol(betas, findgen(n_beta), findgen((n_beta-1)*5+1)/5.)
  cmap_regrid_bilinear = fltarr(n_elements(alphas), n_elements(betas), n_elements(cmap_regrid[0, 0, *]))
  FOR timeIndex = 0, n_elements(cmap_regrid[0, 0, *]) - 1 DO BEGIN
    cmap_regrid_bilinear[*, *, timeIndex] = bilinear(cmap_regrid[*, *, timeIndex], findgen((n_alpha-1)*5+1)/5., findgen((n_beta-1)*5+1)/5.)
  ENDFOR
  cmap_regrid = cmap_regrid_bilinear
  
  neg_thresh = keyword_set(multiplier) ? 1. : 0.
  format_str = keyword_set(multiplier) ? '(F5.3)' : '(F+4.1)'
  pct_str = keyword_set(multiplier) ? '' : '%'
  
  contour, cmap_regrid[*, *, 0], alphas, betas, /iso, /nodata, /xs, /ys, xtitle = 'Alpha [deg]', ytitle = 'Beta [deg]', title = title, xr=plotrange(alphas), yr=plotrange(betas)
  device,decomp=0
  loadct, 1, /silent ; Blue/White
  wgood = where(cmap_regrid lt neg_thresh, ngood) ; Plot negative deviations in blue...
  percentstep = (('X123' eq 'XP') ? 0.5 : (('X123' eq 'SPS') ? 0.5 : 0.5)) / (keyword_set(multiplier) ? 100. : 1.)
  
  FOR timeIndex = 0, n_elements(cmap_regrid[0, 0, *]) - 1 DO BEGIN
    if (ngood ne 0) then begin
      minval = floor(min(cmap_regrid[wgood])/percentstep)*percentstep ; minimum contour level needed in tenths of a percent (NEGATIVE)
      levels = findgen(abs(minval-neg_thresh)/percentstep+1)*percentstep + minval ; contours from minval up to 0, in tenths of a percent
      colors = indgen(n_elements(levels))*100/(n_elements(levels)-1)+155 ; darker blue = more negative
      contour, cmap_regrid[*, *, timeIndex], alphas, betas, levels=levels, c_colors=colors, /iso, /cell_fill, /over
      contour, cmap_regrid[*, *, timeIndex], alphas, betas, levels=levels, /iso, /over, c_charsize=2, c_annotation=string(levels[0:n_elements(levels)-2],format=format_str)+pct_str
    endif
    loadct, 3, /silent ; Red Temperature
    wgood = where(cmap_regrid gt neg_thresh, ngood) ; Plot positive deviations in red...
    if (ngood ne 0) then begin
      minval = ceil(max(cmap_regrid[wgood])/percentstep)*percentstep ; maximum contour level needed in tenths of a percent (POSITIVE)
      levels = findgen(round(abs(minval-neg_thresh)/percentstep+1))*percentstep + neg_thresh; contours from 0 up to minval, in tenths of a percent
      colors = reverse(indgen(n_elements(levels))*100/(n_elements(levels)-1)+135) ; reversed so darker red = more positive
      contour,cmap_regrid[*, *, timeIndex],alphas,betas,levels=levels,c_colors=colors,/iso,/cell_fill,/over,/noerase
      contour,cmap_regrid[*, *, timeIndex],alphas,betas,levels=levels,/iso,/over,c_charsize=2,c_annotation=string(levels,format=format_str)+pct_str
    endif
  ENDFOR
  
  ; Overplot circle at +/- 20 arcmin to show PORD requirements
  circle_points = transpose([[(20./60.) * cos((2 * !PI / 99.0) * FINDGEN(100))], [(20./60.) * sin((2 * !PI / 99.0) * FINDGEN(100))]])
  ;plots, 0., 0., psym=7, thick=4,symsize=2
  plots, 0., 0., psym=1, thick=4,symsize=2.5
  oplot, circle_points[0,*], circle_points[1,*], thick=4
  circle_points = transpose([[(27./60.) * cos((2 * !PI / 99.0) * FINDGEN(100))], [(27./60.) * sin((2 * !PI / 99.0) * FINDGEN(100))]])
  oplot, circle_points[0,*], circle_points[1,*], thick=4, color=125
  STOP
endif ; if not noplot

return
end
