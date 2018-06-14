;
;	process_sam.pro
;
;	process SAM data from rocket flight
;
;	1.  Read each image using movie_raw_megs.pro
;	2.  Get photon events using sam_photons.pro
;	3.  Merge results from each image into single spectrum and single image
;
;	Tom Woods
;	4/15/08
;
pro process_sam, rocket=rocket

;
;	get parameters for specific rocket flight
;
if keyword_set(rocket) then rnum = rocket else rnum = 36.258
valid_rnum = [36.233, 36.240, 36.258]
wvalid = where( rnum eq valid_rnum, nvalid )
if (nvalid lt 1) then begin
  print, 'ERROR: rocket number is not valid, resetting to 36.258'
  rnum = 36.258
endif
print, 'Processing for rocket # ', string(rnum,format='(F7.3)')

if (rnum eq 36.240) then begin
  rnumstr = '36240'
  afile = '36240Flt-10m_150_450_raw_amegs.dat'
  tzero = 16*3600L + 58*60L + 0.72  ; UT time of launch
  im_start = 2
  im_end = 22
  samlimit = 10.
  low = 0.3   ; in nm
  high = 5. ; in nm
endif else if (rnum eq 36.258) then begin
  rnumstr = '36258'
  afile = '36258Flt-10m_-200_580_raw_amegs.dat'
  tzero = 18*3600L + 32*60L + 2.00  ; UT time of launch
  im_start = 41
  im_end = 52
  samlimit = 10.
  low = 0.3   ; in nm
  high = 5. ; in nm
endif


; assumes one has already picked im_start and im_end by doing the following command
doview = 0
if (doview ne 0) then begin
  movie_raw_megs, afile, 'A', 1.0, tzero=tzero, info=info
  stop, 'STOP: you might want to reset im_start & im_end ...'
endif

dostop = 0
kcnt = 0L
for k=im_start,im_end do begin
  aimage = k
  movie_raw_megs, afile, 'A', tzero=tzero, image=aimage
  photons1 = sam_photons( aimage, isam=isam1, iphoton=iphoton1, $
  					spectrum=spectrum1, limit=samlimit, low=low, high=high, /debug )
  if (dostop ne 0) then begin
    stop, 'STOP: enter .c to continue ...'
  endif else begin
    wait, 1
  endelse
  kcnt = kcnt + 1L
  if (k eq im_start) then begin
    ; aphotons = photons1
    aisam = isam1
    aiphoton = iphoton1
    aspectrum = spectrum1
  endif else begin
    ; aphotons = [aphotons, photons1]
    aisam = aisam + isam1
    aiphoton = aiphoton + iphoton1
    aspectrum = aspectrum + spectrum1  
  endelse
endfor

print, 'Number of images combined = ', kcnt
if (kcnt gt 1) then begin
  aisam = aisam/float(kcnt)
  ; no division for aiphoton
  aspectrum = aspectrum / float(kcnt)
endif

;  display the results
window,1,xsize=400,ysize=400
wset, 1
cc = rainbow(256,/image)
tv, (aisam*50. > 0)

window,2,xsize=400,ysize=400
wset, 2
cc = rainbow(256,/image)
tv, smooth(aiphoton,3)   ; smooth to SAM real resolution

wset, 0
cc = rainbow(7)
sptemp = aspectrum
;  smooth out photon event noise for longer wavelengths
ww1 = where( sptemp[0,*] lt 4 )
sptemp[1,ww1] = (smooth(sptemp[1,*],5))[ww1]
ww2 = where( sptemp[0,*] gt 4 )
sptemp[1,ww2] = (smooth(sptemp[1,*],11))[ww2]
plot, sptemp[0,*], sptemp[1,*], xrange=[0,10], xs=1, $
    xtitle='Wavelength (nm)', ytitle='Counts / 10-sec', $
    title='SAM '+rnumstr+' : '+strtrim(kcnt,2)+' images'
    
dosave = 1
if (dosave ne 0) then begin
  savefile = 'sam_'+rnumstr+'.sav'
  print, 'Saving results in ', savefile
  save, aisam, aiphoton, aspectrum, file=savefile
endif

; stop, 'STOP: debug aisam, aiphoton, aspectrum results...'

return
end
