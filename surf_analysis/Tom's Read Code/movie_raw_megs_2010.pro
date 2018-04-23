;
;	movie_raw_megs.pro
;
;	Show movie of MEGS CCD images - starts with raw data buffer
;
;	INPUT
;		filename   output file from read_tm2_cd (/classic)
;		channel    'A' or 'B'
;		waittime   time to wait between images (sec)
;		image	   number of image to view (and return data for)
;		/scale	   option to display images as tvscl instead of tv
;		tzero      time for zero time (launch time)
;
;	OUTPUT
;		info		array of time, pixelerror, integbits, buffer, total_counts_in_image
;		image		if set as input, then "image" is also output of that image record
;
;	Tom Woods
;	10/16/06
;
;	Code is written to only to return single image at a time by specifying the image index
;		EXAMPLE for reading single image (to read image #3 in the file)
;		IDL>  image = 3
;		IDL>  movie_raw_megs, FILENAME, 'A', image=image
;		IDL>  help, image
;		  image
;
pro movie_raw_megs, filename, channel, waittime, data=data, info=info, scale=scale, image=image, tzero=tzero, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick MEGS CCD Image Data File', filter='*raw*megs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if n_params() lt 2 then begin
  rp = rstrpos(filename,'megs.dat')
  if (rp gt 0) then channel = strupcase(strmid(filename,rp-1,1)) else channel='?'
endif
ch = strupcase(strmid(channel,0,1))

if n_params() lt 3 then waittime = 0.5
if (waittime lt 0.05) then waittime = 0.05
if (waittime gt 10) then waittime = 10.

mnumx = 2048L
mnumy = 1024L
atotal = mnumx * mnumy

;
;	read binary file if file given is *.dat or read (restore) IDL save set if file is *.sav
;
rpos = strpos( filename, '.', /reverse_search )
if (rpos lt 0) then begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endif
extfile = strupcase(strmid(filename,rpos+1,3))

;
;	READ IF block for *.DAT files
;
if (extfile eq 'DAT') then begin
;
;	data structure needs to be same definition as in read_tm2_all_cd.pro
;
awmin = long((10.D6/16.)*(33./82.)*10.)
megs1 = { time: 0.0D0, numbuffer: 0L, buffer: uintarr(awmin) }
megsim1 = { time: 0.0D0, pixel_error: 0L, fid_index: 0L, total_counts: 0.0D0, image: uintarr(mnumx,mnumy) }

nbytes = n_tags(megs1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, megs1)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: incomplete MEGS image in file'
  close,lun
  free_lun,lun
  return
endif

;
;	read the data
;
data = replicate( megs1, dcnt )
for k=0L,dcnt-1L do begin
  mtemp = a[k]
  ; swap_endian_inplace, mtemp, /swap_if_little_endian
  data[k] = mtemp
endfor

close, lun
free_lun, lun


endif else if (extfile eq 'SAV') then begin
  ;
  ;	READ IF block for *.SAV files
  ;
  restore, filename	; expect to have "data" in this save set
  dcnt = n_elements(data)
  
endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.275
  if (rocket ne 36.258) or (rocket ne 36.275) then rocket = 36.275
endif else rocket = 36.275

if (rocket eq 36.258) then begin
    tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 30.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=10.
endif
if (rocket eq 36.275) then begin
    tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=10.
endif

;
;	display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=800,ysize=600
setplot
cc=rainbow(7)
; loadct,4
sp1 = dblarr(mnumx)
sp2 = dblarr(mnumx)
info = dblarr(4,dcnt)		; time, pixelerror, total_counts_in_image, fidicual_index
kstart = 0L
kend = dcnt-1L

if keyword_set(image) then begin
  kstart = long(image[0])
  if (kstart lt 0) then kstart = 0L
  if (kstart ge dcnt) then kstart = dcnt-1L
  kend = kstart
endif

for k=kstart,kend do begin
  megs1 = data[k]
  ;
  ;	convert buffer to image (if possible)
  ;
  image1 = 0L
  aerr = mnumx * mnumy * (-1L)
  fidindex = -1
  wfid1 = where( megs1.buffer[0:megs1.numbuffer-1] eq 'FFFF'X, nfid1 )
  wfid2 = where( megs1.buffer[0:megs1.numbuffer-1] eq 'AAAA'X, nfid2 )
  if (nfid1 gt 0) and (nfid2 gt 0) then begin
    if (wfid2[0] eq (wfid1[0] + 1)) then begin
      fidindex = wfid1[0]
      image1 = megs_raw2image( megs1.buffer[fidindex:megs1.numbuffer-1], megs1.numbuffer-fidindex, megs1.time, pixelerror=aerr )
    endif
  endif
  if n_elements(image1) lt 2 then begin
    wnotzero = where( (megs1.buffer[0:megs1.numbuffer-1] ne '7E7E'X) and (megs1.buffer[0:megs1.numbuffer-1] ne 0) , numnotzero )
    if (numnotzero gt 0) then begin
       image1 = megs_raw2image( megs1.buffer[0:megs1.numbuffer-1], megs1.numbuffer, megs1.time, pixelerror=aerr )   
    endif
  endif
  info[0,k] = megs1.time
  info[1,k] = aerr
  info[2,k] = total(image1)
  info[3,k] = fidindex
  
  if (k eq kstart) then begin
    tz = megs1.time
    if keyword_set(tzero) or (rocket ne 0) then tz = tzero
  endif
  
  if (n_elements(image1) gt 1) then begin
    ;
    ;	plot spectrum above image
    ;
    if (ch eq 'A') then begin
      for j=0L,mnumx-1 do sp1[j] = total(image1[j,0:mnumy/2-1])
      for j=0L,mnumx-1 do sp2[j] = total(image1[j,mnumy/2:mnumy-1])
      sp1d = sp1 - min(sp1) + 1000.
      sp2d = sp2 - min(sp2) + 1000.
      yrange = [min([min(sp1d),min(sp2d)]),max([max(sp1d),max(sp2d)])*1.1]
    endif else begin
    	;  For ch = 'B' or unknown
      for j=0L,mnumx-1 do sp1[j] = total(image1[j,*])
      sp1d = sp1 - min(sp1) + 1000.
      yrange = [min(sp1d),max(sp1d)*1.1]
    endelse
    if (yrange[1] lt 1E5) then yrange[1] = 1E5
    mtitle = 'Img'+strtrim(k,2)+': Time @ '+strtrim(long(megs1.time-tz),2)
    plot_io, sp1d, xtitle='X',ytitle='Integrated Signal', title=mtitle, $
  		yr=yrange,ys=1,xr=[0,2050],xs=1, xmargin=[10,2],ymargin=[13.5,2]
    oplot, sp1d, color=cc[5]
    if (ch eq 'A') then oplot, sp2d, color=cc[3]
    if (info[1,k] gt 0) or (info[1,k] lt (-2)) then begin
      xx = !x.crange[0] + (!x.crange[1]-!x.crange[0])*0.1
      yy = !y.crange[1] - (!y.crange[1]-!y.crange[0])*0.1
    	xyouts, xx, yy, 'Pixel Errors = '+strtrim(info[1,k],2), color=cc[0]
    endif
    im = rebin(image1,512,256)
    im[0,*] = 0		; put dark border around image
    im[511,*] = 0
    im[*,0] = 0
    im[*,255] = 0
    ;stop, 'STOP: Check out "im" ...'
    ; +++++  ERROR with IDL v6.3 on MAC to do tv or tvscl (Bus error at OS-X system level) +++++
    if keyword_set(scale) then tvscl, im, 200, 0 else tv, im, 200, 0
    wait, waittime
  endif
endfor

;
;	do extra plot at end if /info is given
;
doExtra = 0
if keyword_set(info) and not keyword_set(image) and (doExtra ne 0) then begin
  setplot
  !p.multi=[0,1,3]
  plot, info[0,*]-tz, info[1,*], psym=-4, xtitle='', ytitle='Pixel Errors', xmargin=[10,2], ymargin=[2,1]
  plot, info[0,*]-tz, info[2,*], psym=-4, xtitle='', ytitle='Image Total', ys=1, xmargin=[10,2], ymargin=[2,1]
  plot, info[0,*]-tz, info[3,*], psym=-4, xtitle='Time (sec)', ytitle='Fid. Index', ys=1, xmargin=[10,2], ymargin=[3,0]
  !p.multi=0
endif

;
;	return "image" data if asked for single image
;
if keyword_set(image) then image = image1

return
end
