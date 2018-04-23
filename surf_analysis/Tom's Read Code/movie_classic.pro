;
;	movie_classic.pro
;
;	Show movie of CLASSIC images
;
;	INPUT
;		filename   output file from read_tm2_cd (/classic)
;		waittime   time to wait between images (sec)
;		image	   number of image to view (and return data for)
;		/scale	   option to display images as tvscl instead of tv
;		tzero      time (sec of day) for zero time (launch time)
;
;	OUTPUT
;		info		array of time, pixelerror, integbits, buffer, total_counts_in_image
;		image		if set as input, then "image" is also output of that image record
;
;	Tom Woods
;	10/16/06
;
pro movie_classic, filename, waittime, info=info, scale=scale, image=image, tzero=tzero

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick CLASSIC Image Data File', filter='*classic.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if n_params() lt 2 then waittime = 0.1
if (waittime lt 0.05) then waittime = 0.05
if (waittime gt 10) then waittime = 10.

;
;	same definition as in read_tm2_cd.pro
;
cnumx = 1066L
cnumy = 1064L
classic1 = { time: 0.0D0, pixelerror: 0L, integbits: 0, buffer: 0, image: uintarr(cnumx,cnumy) }
nbytes = n_tags(classic1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, classic1)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: incomplete CLASSIC image found'
  close,lun
  free_lun, lun
  return
endif

;
;	read / display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=800,ysize=600
setplot
cc=rainbow(7)
; loadct,4
sp = dblarr(cnumx)
info = dblarr(5,dcnt)		; time, pixelerror, integbits, buffer, total_counts_in_image
kstart = 0L
kend = dcnt-1L

if keyword_set(image) then begin
  kstart = long(image[0])
  if (kstart lt 0) then kstart = 0L
  if (kstart ge dcnt) then kstart = dcnt-1L
  kend = kstart
endif

for k=kstart,kend do begin
  classic1 = a[k]
  info[0,k] = classic1.time
  info[1,k] = classic1.pixelerror
  info[2,k] = classic1.integbits
  info[3,k] = classic1.buffer
  info[4,k] = total(classic1.image)
  if (k eq kstart) then begin
    tz = classic1.time
    if keyword_set(tzero) then tz = tzero
  endif
  ;
  ;	plot spectrum above image
  ;
  for j=0L,cnumx-1 do sp[j] = total(classic1.image[j,*])
  mtitle='Img'+strtrim(k,2)+': Time @ '+strtrim(long(classic1.time-tz),2)
  plot, sp, xtitle='X',ytitle='Integrated Signal', title=mtitle, $
  		yr=[min(sp)*0.9,max(sp)*1.1],ys=1,xr=[0,1070],xs=1, xmargin=[10,2],ymargin=[13.5,2]
  oplot, sp, color=cc[5]
  if (classic1.pixelerror gt 2) or (classic1.pixelerror lt 0) then begin
    xx = !x.crange[0] + (!x.crange[1]-!x.crange[0])*0.1
    yy = !y.crange[1] - (!y.crange[1]-!y.crange[0])*0.1
  	xyouts, xx, yy, 'Pixel Errors = '+strtrim(classic1.pixelerror,2), color=cc[0]
  endif
  im = rebin(classic1.image[0:1063,*],266,266)
  im[0,*] = 0		; put dark border around image
  im[265,*] = 0
  im[*,0] = 0
  im[*,265] = 0
  if keyword_set(scale) then tvscl, im, 300, 0 else tv, im, 300, 0
  wait, waittime
endfor

close, lun
free_lun, lun

;
;	do extra plot at end if /info is given
;
if keyword_set(info) and not keyword_set(image) then begin
  setplot
  !p.multi=[0,1,3]
  plot, info[0,*]-tz, info[1,*], psym=-4, xtitle='', ytitle='Pixel Errors', xmargin=[10,2], ymargin=[2,1]
  plot, info[0,*]-tz, info[2,*], psym=-4, xtitle='', ytitle='Integ. Bits', $
  		yrange=[-1,4],ys=1, xmargin=[10,2], ymargin=[2,1]
  oplot, info[0,*]-tz, info[3,*], psym=-5, color=cc[3]
  plot, info[0,*]-tz, info[4,*], psym=-4, xtitle='Time (sec)', ytitle='Image Total', ys=1, xmargin=[10,2], ymargin=[3,0]
  !p.multi=0
endif

;
;	return "image" data if asked for single image
;
if keyword_set(image) then image = classic1

return
end
