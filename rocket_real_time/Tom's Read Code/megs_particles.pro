;
;	megs_particles.pro
;
;	Analyze the particle hits for MEGS as function of altitude
;
;	INPUT:
;		channel		'A' or 'B'
;
;	OUTPUT:
;		spectra		data structure of results
;		
;	Tom Woods
;	11/6/06
;
pro megs_particles, channel, spectra

if (n_params() lt 1) then begin
  channel = 'X'
  read, 'Enter Channel (A or B) ', channel
endif
ch = strupcase(strmid(channel,0,1))

;
;	get the dark reference images
;
restore, '36233_megs_preflight_dark.sav'	; adark, bdark  [2048,1024] images at T-49 sec
file=''
tzero = 17.*3600.D0 + 58*60.

if (ch eq 'A') then begin
  ;  A channel options
  imlist = [ 21, 22, 23, 24, 25, 26, 33, 34, 35 ]  ; index into movie_megs()
  alt = [26.6, 44.9, 64.8, 83.6, 101.6, 118.5, 101.9, 84.0, 65.1 ]  ; altitude (km) at 5 sec before
  region = [50, 0, 2047, 1023]
endif else begin
  ;  B channel options
  imlist = [ 21, 22, 23, 24, 26 ]   ; FF images at index of 25, 43, 44, 45
  alt = [ 26.6, 44.9, 64.8, 83.6, 118.5 ]
  region = 0
endelse

numsp = n_elements(imlist)
numwave = 500L
outsp1 = { time: 0.0, altitude: 0.0, darkscale: 0.0, total: 0.0, wave: fltarr(numwave), count: fltarr(numwave) }
spectra = replicate(outsp1,numsp)

for k=0,numsp-1 do begin
  im1 = imlist[k]
  movie_megs, file, ch, image=im1, tzero=tzero
  spectra[k].time = im1.time - tzero
  spectra[k].altitude = alt[k]
  if (ch eq 'A') then begin
    dscale = median(im1.image) / median(adark)
    imdiff = im1.image - adark * dscale
  endif else begin
    dscale = median(im1.image) / median(bdark)
    imdiff = im1.image - bdark * dscale
  endelse
  spectra[k].darkscale = dscale
  ph = megs_photons( imdiff, iphoton=iphoton, spectrum=sp, limit=30, region=region )
  spectra[k].wave = reform(sp[0,*])
  spectra[k].count = reform(sp[1,*])
  spectra[k].total = total(spectra[k].count)
endfor


return
end
