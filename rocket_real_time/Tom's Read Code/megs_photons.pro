;+
; NAME:
;	megs_photons
;
; PURPOSE:
;	Extract photon / particle events from MEGS images
;
; CATEGORY:
;	procedure for quick look purpose only
;
; CALLING SEQUENCE:  
;	array_photon_events = megs_photons( image [,/sam, limit=limit ] )
;
; INPUTS:
;	image		2048 x 1024 MEGS CCD image
;	/sam		Option to select SAM image area of 512 x 512 for MEGS-A only
;	limit		Option to specify lower limit for finding photons (Default = 10 DN)
;	/debug		Option to print messages and display SAM image
;   region      Option to specify the region to search for photon / particle events
;					region = [xmin, ymin, xmax, ymax]
;
; OUTPUTS:  
;	photons		array of photon events is returned
;				photons.x = X centroid of photon event
;				photons.y = Y centroid of photon event
;				photons.xwidth = number of X pixels for photon event width
;				photons.ywidth = number of y pixels for photon event width
;				photons.energy = energy of photon event (eV)
;				photons.wavelength= wavelength of photon event (nm)
;
;		or		-1 if error in parameters
;
;	iphoton		Option to return photon image (each pixel represents energy in that pixel)
;
;	spectrum	Option to return spectrum in 0.1-nm intervals
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Extract out photon events in image region
;			Look for peaks within 3x3 pixels
;			Calculate centroid (center of mass)
;			Convert total in event (DN) to energy (1 electron = 3.65 eV)
;	3.	Return "photons"
;
; MODIFICATION HISTORY:
;	9/8/06		Tom Woods	Original file creation
;   11/4/06     Tom Woods   Updated for full MEGS image to help with particle detection
;
;+
function megs_photons, image, sam=sam, iphoton=iphoton, spectrum=spectrum, $
					     limit=limit, debug=debug, region=region

;
;	1.  Check input parameters
;
if n_params() lt 1 then begin
  print, 'USAGE:  photons = megs_photons( image [,/sam, iphoton=iphoton, spectrum=spectrum, $ '
  print, '                               limit=limit, /debug ] )'
  return, -1
endif

isize = size(image)
if (isize[0] ne 2) or (isize[1] ne 2048) or (isize[2] ne 1024) then begin
  print, 'ERROR megs_photons: IMAGE size is not 2048 x 1024'
  return, -1
endif

;
;	set lower limit for extracting photons (default is 10 DN)
;
if not keyword_set(limit) then limit = 10.
if (limit lt 2) then limit = 2.
if (limit gt 100) then limit = 100.		; FYI: 5 nm ==> 68 electrons ==> 34 DN

;
;	conversion constant for energy - wavelength
;		wavelength = eV_nm / energy
;		
ev_nm = 1239.84

;
;	conversion from DN to energy
;		energy = DN * Gain * si_energy
;
Gain = 2.0			; electrons/DN:  ASSUMPTION for quick-look  +++++ update with real value
si_energy = 3.63	; eV/electron for each electron released

;
;	2.	Extract out photon events in image region
;			Look for peaks and extract out to below lower limit
;			Calculate centroid (center of mass)
;			Convert total in event (DN) to energy (1 electron = 3.65 eV)
;
if keyword_set(region) and (n_elements(region) ge 4) then begin
  xradius = long(abs(region[2]-region[0]+1)/2.)
  yradius = long(abs(region[3]-region[1]+1)/2.)
  xc = long((region[2]+region[0]+1)/2.)
  yc = long((region[3]+region[1]+1)/2.)
  isam = float(image[xc-xradius:xc+xradius-1, yc-yradius:yc+yradius-1])
endif else if keyword_set(sam) then begin
  xc = 1624L  ; ideal X center for SAM image
  yc = 256L   ; ideal Y center
  xradius = 256L
  yradius = 256L
  isam = float(image[xc-xradius:xc+xradius-1, yc-yradius:yc+yradius-1])
endif else begin
  xradius = 1024L
  yradius = 512L
  isam = float(image)
endelse
xdia = xradius*2
ydia = yradius*2

; assumes dark is already removed, but also subtract median in case dark needs slight adjustment
if keyword_set(region) and (n_elements(region) ge 4) then begin
  isam = isam - median(isam)  
endif else if keyword_set(sam) then begin
  isam = isam - median(isam)
endif else begin
  ; subtract median for top and bottom differently
  isam[*,0:511] = isam[*,0:511] - median(isam[*,0:511])
  isam[*,512:*] = isam[*,512:*] - median(isam[*,512:*])
endelse

;  display SAM image
if keyword_set(debug) then begin
  if keyword_set(sam) then xx = 512 else xx = 1024
  window,1,xsize=xx,ysize=512
  wset, 1
  if keyword_set(sam) then tv, (isam > 0) $
  else tv, rebin(isam,1024,512) > 0
  wset, 0
endif

;  define structure for photons
ptemp = { x: 0.0, y: 0.0, xwidth: 0, ywidth: 0, energy: 0.0, wavelength: 0.0 }
photons = -1
pnum = 0L

;
;	Look for max (peak) and then extract out to below lower limit or rise again (adjacent photon)
;
im = isam
peak = max( im, wpk )
phlimit = 2000L
while (peak ge limit) and (pnum lt phlimit) do begin
  ; get peak X, Y location
  yc = long(wpk / xdia)
  xc = long(wpk - yc*xdia)
  
  ;  get x1 (left edge)
  dlast = peak
  x1 = xc
  repeat begin
    drop = 0
    if (x1 gt 0) then begin
      x1 = x1 - 1
      d = im[x1,yc]
      if (d lt dlast) and (d ge limit) then drop = 1
      dlast = d
      if (drop eq 0) then x1 = x1 + 1
    endif
  endrep until (drop eq 0)
  
  ;  get x2 (right edge)
  dlast = peak
  x2 = xc
  repeat begin
    drop = 0
    if (x2 lt (xdia-1)) then begin
      x2 = x2 + 1
      d = im[x2,yc]
      if (d lt dlast) and (d ge limit) then drop = 1
      dlast = d
      if (drop eq 0) then x2 = x2 - 1
    endif
  endrep until (drop eq 0)
  
  ;  get y1 (bottom edge)
  dlast = peak
  y1 = yc
  repeat begin
    drop = 0
    if (y1 gt 0) then begin
      y1 = y1 - 1
      d = im[xc,y1]
      if (d lt dlast) and (d ge limit) then drop = 1
      dlast = d
      if (drop eq 0) then y1 = y1 + 1
    endif
  endrep until (drop eq 0)
  
  ;  get y2 (top edge)
  dlast = peak
  y2 = yc
  repeat begin
    drop = 0
    if (y2 lt (ydia-1)) then begin
      y2 = y2 + 1
      d = im[xc,y2]
      if (d lt dlast) and (d ge limit) then drop = 1
      dlast = d
      if (drop eq 0) then y2 = y2 - 1
    endif
  endrep until (drop eq 0)
  
  ;  sum up DN in the photon box
  imtotal = total( im[x1:x2,y1:y2] )

  ;  special check if large event (image not photon)
  ;	 if so, then expand image size by 20%
  if (imtotal gt 2000) and ((x2-x1) gt 3) and ((y2-y1) gt 3) then begin
    xextra = (x2-x1)*0.2
    if (xextra lt 1) then xextra = 1
    x1 = x1-xextra
    if (x1 lt 0) then x1=0
    x2 = x2+xextra
    if (x2 ge xdia) then x2 = xdia - 1

    yextra = (y2-y1)*0.2
    if (yextra lt 1) then yextra = 1
    y1 = y1-yextra
    if (y1 lt 0) then y1=0
    y2 = y2+yextra
    if (y2 ge ydia) then y2 = ydia - 1

    imtotal = total( im[x1:x2, y1:y2] )
  endif
  
  ptemp.energy = imtotal * Gain * si_energy
  ptemp.wavelength = ev_nm / ptemp.energy
  
  ;  get X, Y centroid value
  ptemp.xwidth = x2-x1+1
  xbin = findgen(x2-x1+1) + x1
  xsum = 0.0
  for y=y1,y2 do xsum = xsum + total(xbin * im[x1:x2,y])
  ptemp.x = xsum / imtotal
  ptemp.ywidth = y2-y1+1
  ybin = findgen(y2-y1+1) + y1
  ysum = 0.0
  for x=x1,x2 do ysum = ysum + total(ybin * im[x,y1:y2])
  ptemp.y = ysum / imtotal
  
  ;  save photon event
  if (pnum eq 0) then photons = ptemp else photons = [ photons, ptemp ]
  pnum = pnum + 1L
  
  ;  clear "im" where photon was detected
  im[x1:x2, y1:y2] = 0.0
  
  ;  get next peak
  peak = max( im, wpk )
endwhile

if (pnum ge phlimit) then print, 'WARNING: stopping with peak level at ', peak

;
;	3.	Return "photons"
;
if keyword_set(debug) then print, 'megs_photons: ', strtrim(pnum,2), ' photons events found.'

;
;		Make "iphoton" - photon based image
;
iphoton = fltarr( xdia, ydia )
for k=0,pnum-1 do begin
  xc = long(photons[k].x + 0.5)
  yc = long(photons[k].y + 0.5)
  iphoton[xc,yc] = iphoton[xc,yc] + photons[k].energy
endfor

;
;		Make spectrum - spectrum in 0.1-nm intervals (up to 10 nm)
;
wvstep = 0.02
wvstep2 = wvstep / 2.
wvmax = 10.
nwv = wvmax / wvstep
spectrum = fltarr(2,nwv)
spectrum[0,*] = findgen(nwv) * wvstep + wvstep2
for k=0,nwv-1 do begin
  wgd = where( (photons.wavelength ge (spectrum[0,k]-wvstep2)) and (photons.wavelength lt (spectrum[0,k]+wvstep2)), numgd )
  spectrum[1,k] = numgd
endfor

return, photons
end
