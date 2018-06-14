;+
; NAME:
;	sam_photons
;
; PURPOSE:
;	Extract photon events from SAM images
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:  
;	array_photon_events = sam_photons( image [,isam=isam, iphoton=iphoton, $
;								spectrum=spectrum, /surf, limit=limit , /debug ] )
;
; INPUTS:
;	image		2048 x 1024 MEGS-A CCD image
;	/surf		Option to reduce SAM image size for SURF calibrations (128 x 128 versus 400 x 400)
;	limit		Option to specify lower limit for finding photons (Default = 10 DN)
;	/debug		Option to print messages and display SAM image
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
;	isam		Option to return SAM image used for photon extraction
;
;	iphoton		Option to return photon image (each pixel represents energy in that pixel)
;
;	spectrum	Option to return spectrum in 0.1-nm intervals
;
; COMMON BLOCKS:
;	None
;
; Example usage for SURF Data
;	samfiles = file_search()
;	plotmegs, 'SAM', samfiles[0], data=dsam
;   photons = sam_photons( dsam.image, spectrum=spsam, /debug )
;
; PROCEDURE:
;
;	1.  Check input parameters
;	2.	Extract out photon events in SAM image region
;			Look for peaks within 3x3 pixels
;			Calculate centroid (center of mass)
;			Convert total in event (DN) to energy (1 electron = 3.65 eV)
;	3.	Return "photons"
;
; MODIFICATION HISTORY:
;	9/8/06		Tom Woods	Original file creation
;
;	4/15/08		Tom Woods	Added low & high filters (for keeping results in iphoton & spectrum)
;							Both are given in nm. Defaults are 0.1 for low and 10. for high.
;							The photons & isam are not affected by this filtering.
;
;+
function sam_photons, image, isam=isam, iphoton=iphoton, spectrum=spectrum, $
					surf=surf, limit=limit, debug=debug, low=low, high=high

;
;	1.  Check input parameters
;
if n_params() lt 1 then begin
  print, 'USAGE:  photons = sam_photons( image [,isam=isam, iphoton=iphoton, spectrum=spectrum, $ '
  print, '                               /surf, limit=limit, low=low, high=high, /debug ] )'
  return, -1
endif

isize = size(image)
if (isize[0] ne 2) or (isize[1] ne 2048) or (isize[2] ne 1024) then begin
  print, 'ERROR sam_photons: IMAGE size is not 2048 x 1024'
  return, -1
endif

;
;	set lower limit for extracting photons (default is 10 DN)
;
if not keyword_set(limit) then limit = 10.
if (limit lt 2) then limit = 2.
if (limit gt 100) then limit = 100.		; FYI: 5 nm ==> 68 electrons ==> 34 DN

if keyword_set(low) then wvlow = low else wvlow = 0.1
if (wvlow lt 0.) then wvlow = 0.
if keyword_set(high) then wvhigh = high else wvhigh = 10.
if (wvhigh gt 30.) then wvhigh = 30.

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
;	2.	Extract out photon events in SAM image region
;			Look for peaks and extract out to below lower limit
;			Calculate centroid (center of mass)
;			Convert total in event (DN) to energy (1 electron = 3.65 eV)
;
xc = 1608L  ; ideal X center
yc = 278L   ; ideal Y center
radius = 200L
if keyword_set(surf) then radius = 64L   ; 0.25 degree radius
dia = radius*2
isam = image[xc-radius:xc+radius-1, yc-radius:yc+radius-1]

; assumes dark is already removed, but also subtract median in case dark needs slight adjustment
isam = isam - median(isam)

;  display SAM image
if keyword_set(debug) then begin
  window,1,xsize=512,ysize=512
  wset, 1
  if keyword_set(surf) then tv, (rebin(isam,512,512) * 10) > 0 $
  else tv, (isam * 10 > 0)
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
while (peak ge limit) do begin
  ; get peak X, Y location
  yc = long(wpk / dia)
  xc = long(wpk - yc*dia)
  
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
    if (x2 lt (dia-1)) then begin
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
    if (y2 lt (dia-1)) then begin
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
    if (x2 ge dia) then x2 = dia - 1

    yextra = (y2-y1)*0.2
    if (yextra lt 1) then yextra = 1
    y1 = y1-yextra
    if (y1 lt 0) then y1=0
    y2 = y2+yextra
    if (y2 ge dia) then y2 = dia - 1

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

;
;	3.	Return "photons"
;
if keyword_set(debug) then print, 'sam_photons: ', strtrim(pnum,2), ' photons events found.'

;
;		Make "iphoton" - photon based image
;		Only process the events that pass the low & high wavelength filters
;
iphoton = fltarr( dia, dia )
wgd = where( (photons.wavelength ge wvlow) and (photons.wavelength le wvhigh), ngd )
if keyword_set(debug) then print, 'sam_photons: ', strtrim(ngd,2), ' photons passed the low-high filter.'
for k=0,ngd-1 do begin
  xc = long(photons[wgd[k]].x + 0.5)
  if (xc lt 0) then xc = 0
  if (xc ge dia) then xc = dia-1
  yc = long(photons[wgd[k]].y + 0.5)
  if (yc lt 0) then yc = 0
  if (yc ge dia) then yc = dia-1
  iphoton[xc,yc] = iphoton[xc,yc] + photons[wgd[k]].energy
endfor

;
;		Make spectrum - spectrum in 0.1-nm intervals (up to 10 nm)
;
wvstep = 0.1
wvstep2 = wvstep / 2.
wvmax = 10.
nwv = wvmax / wvstep
spectrum = fltarr(2,nwv)
spectrum[0,*] = findgen(nwv) * wvstep + wvstep2
if (n_elements(photons) gt 1) then begin
  for k=0,nwv-1 do begin
    wgd = where( (photons.wavelength ge (spectrum[0,k]-wvstep2)) and (photons.wavelength lt (spectrum[0,k]+wvstep2)), numgd )
    spectrum[1,k] = numgd
  endfor
  ;  clean spectrum based on low & high filters
  wlow = where( spectrum[0,*] lt wvlow, nlow )
  if (nlow ge 1) then spectrum[1,wlow] = 0.
  whi = where( spectrum[0,*] gt wvhigh, nhi )
  if (nhi ge 1) then spectrum[1,whi] = 0.
endif

return, photons
end
