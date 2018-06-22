;
;	movie_csol.pro
;
;	Show movie of CSOL images
;
;	INPUT
;		filename   output file from read_tm2_cd (/csol)
;		waittime   time to wait between images (sec)
;		image	   number of image to view (and return data for)
;		/scale	   option to display images as tvscl instead of tv
;		tzero      time (sec of day) for zero time (launch time)
;
;	OUTPUT
;		image		if set as input, then "image" is also output of that image record
;		data		full data of records in the binary file
;
;	Tom Woods
;	10/16/06
;
pro movie_csol, filename, waittime, scale=scale, data=data, image=image, tzero=tzero

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick CSOL Image Data File', filter='*csol.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if n_params() lt 2 then waittime = 0.1
if (waittime lt 0.05) then waittime = 0.05
if (waittime gt 10) then waittime = 10.

;
;	same definition as in read_tm2.pro
;
cnumx = 2000L
cnumy = 440L
csol_meta = { time_counter: 0L, temp_det0: 0.0, temp_det1: 0.0, temp_fpga: 0.0, mon_5v: 0.0, $
  				mon_current: 0.0, tec_enable: 0, led_enable: 0, integ_period: 0.0, $
  				sdcard_start: 0U, sdcard_address: 0U, error_code: 0U }
csol1 = { time: 0.0D0, pixelerror: 0L, frameid: 0U, image: uintarr(cnumx,cnumy), $
  				metadata: csol_meta }
nbytes = n_tags(csol1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, csol1)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: incomplete csol image found'
  close,lun
  free_lun, lun
  return
endif

;
;	read / display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 1180) or (!d.y_size ne 600)) then window,0,xsize=1180,ysize=600
setplot
cc=rainbow(7)
; loadct,4
sp = dblarr(cnumx,5)
sp_cols = long(cnumy/5)
cc_sp = [ cc[0], cc[3], cc[1], cc[4], cc[0] ]

num_gap = 10L
cnumy_gap = cnumy+4*num_gap
image_gap = uintarr(cnumx,cnumy_gap)

kstart = 0L
kend = dcnt-1L

if keyword_set(image) then begin
  kstart = long(image[0])
  if (kstart lt 0) then kstart = 0L
  if (kstart ge dcnt) then kstart = dcnt-1L
  kend = kstart
endif

data = replicate( csol1, kend-kstart+1 )

for k=kstart,kend do begin
  csol1 = a[k]
  data[k-kstart] = csol1
  if (k eq kstart) then begin
    tz = csol1.time
    if keyword_set(tzero) then tz = tzero
  endif
  ;
  ;	plot spectrum above image
  ;
  for i=0L,cnumx-1 do begin
  	for j=0,4 do sp[i,j] = total(csol1.image[i,j*sp_cols:(j+1)*sp_cols-1])
  endfor
  mtitle='CSOL Img'+strtrim(k,2)+': Time @ '+strtrim(long(csol1.time-tz),2)
  plot, sp[*,0], /nodata, xtitle='X',ytitle='Integrated Signal', title=mtitle, $
  		yr=[min(sp)*0.9,max(sp)*1.1],ys=1,xr=[0,cnumx],xs=1, xmargin=[10,2],ymargin=[13.5,2]
  for j=0,4 do oplot, sp[*,j], color=cc_sp[j]
  if (csol1.pixelerror gt 2) or (csol1.pixelerror lt 0) then begin
    xx = !x.crange[0] + (!x.crange[1]-!x.crange[0])*0.1
    yy = !y.crange[1] - (!y.crange[1]-!y.crange[0])*0.1
  	xyouts, xx, yy, 'Pixel Errors = '+strtrim(csol1.pixelerror,2), color=cc[0]
  endif
  ;
  ;	make image with gaps
  ;
  for j=0,4 do begin
  	image_gap[*,j*num_gap+j*sp_cols:j*num_gap+(j+1)*sp_cols-1]  = csol1.image[*,j*sp_cols:(j+1)*sp_cols-1]
  endfor
  im = rebin(image_gap,cnumx/2L,cnumy_gap/2L)
  if keyword_set(scale) then tvscl, im, 150, num_gap else tv, im, 150, num_gap
  xyouts, 130, num_gap*1.5+sp_cols*1.4/2., 'FUV', color=cc_sp[1], align=1, /device
  xyouts, 130, num_gap*2.5+sp_cols*3.4/2., 'MUV', color=cc_sp[3], align=1, /device

  wait, waittime
endfor

close, lun
free_lun, lun

;
;	return "image" data if asked for single image
;
if keyword_set(image) then image = csol1

return
end
