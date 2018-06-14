;
;	movie_raw_megs.pro
;
;	Show movie of MEGS CCD images - starts with raw data buffer
;
;	INPUT
;		filename   output file from read_tm2_cd (/classic)
;		channel    'A' or 'B'
;		waittime   time to wait between images (sec) : prompt user for each image if < 0
;		image	   number of image to view (and return data for)
;		/scale	   option to display images as tvscl instead of tv
;		tzero      time for zero time (launch time)
;
;	OUTPUT
;		info		array of time, pixelerror, integbits, buffer, total_counts_in_image
;		image		if set as input, then "image" is also output of that image record
;		data		full set of data from file
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
pro movie_raw_megs, filename, channel, waittime, data=data, scale=scale, image=image, rocket=rocket

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
if (waittime ge 0) and (waittime lt 0.1) then waittime = 0.1
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
data = replicate( megsim1, dcnt )
kcnt = 0L
for k=0L,dcnt-1L do begin
  megs1 = a[k]
  ; swap_endian_inplace, mtemp, /swap_if_little_endian

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
  if (n_elements(image1) gt 1) then begin
    megsim1.time = megs1.time
    megsim1.pixel_error = aerr
    megsim1.total_counts = total(image1)
    megsim1.fid_index = fidindex
    megsim1.image = image1
    data[kcnt] = megsim1
    kcnt += 1L
  endif else print, 'ERROR: no image for k = ', k

endfor
if (kcnt ne dcnt) then data=data[0:kcnt-1]

close, lun
free_lun, lun


endif else if (extfile eq 'SAV') then begin
  ;
  ;	READ IF block for *.SAV files
  ;
  restore, filename	; expect to have "data" in this save set
  dcnt = n_elements(data)
  if (dcnt eq 0) then begin
    if ch eq "A" then data=amegs else data=bmegs
    dcnt = n_elements(data)
  endif
  if (dcnt eq 0) then begin
    stop, 'ERROR in finding data for ', filename
  endif
endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

common rocket_common, rocket_number, launch_time, rocket_data_dir
if not keyword_set(rocket) then rocket=36.300
rocket_set_number, rocket
tzero = launch_time

if (rocket eq 36.258) then begin
    ; tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 30.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=10.
endif else if (rocket eq 36.275) then begin
    ; tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=10.
endif else if (rocket eq 36.286) then begin
    ; tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
endif else if (rocket eq 36.290) then begin
    ; tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
endif else if (rocket eq 36.300) then begin
    ; tzero = 19*3600L+15*60L+0.000D0  ; launch time in UT
    tapogee = 200.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
endif

;
;	no need to set T-zero (launch) time as that is already in the raw data file
;
;tz = data[0].time
;if keyword_set(tzero) or (rocket ne 0) then tz = tzero

;
;	display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=800,ysize=600
setplot
cc=rainbow(7)
; loadct,4
sp1 = dblarr(mnumx)
sp2 = dblarr(mnumx)
kstart = 0L
kend = dcnt-1L

if keyword_set(image) then begin
  kstart = long(image[0])
  if (kstart lt 0) then kstart = 0L
  if (kstart ge dcnt) then kstart = dcnt-1L
  kend = kstart
endif

for k=kstart,kend do begin
  megsim1 = data[k]
  image1 = megsim1.image
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
    mtitle = 'Img'+strtrim(k,2)+': Time @ '+strtrim(long(megsim1.time),2)
    plot_io, sp1d, xtitle='X',ytitle='Integrated Signal', title=mtitle, $
  		yr=yrange,ys=1,xr=[0,2050],xs=1, xmargin=[10,2],ymargin=[13.5,2]
    oplot, sp1d, color=cc[5]
    if (ch eq 'A') then oplot, sp2d, color=cc[3]
    if (megsim1.pixel_error gt 0) or (megsim1.pixel_error lt (-2)) then begin
      xx = !x.crange[0] + (!x.crange[1]-!x.crange[0])*0.1
      yy = !y.crange[1] - (!y.crange[1]-!y.crange[0])*0.1
    	xyouts, xx, yy, 'Pixel Errors = '+strtrim(megsim1.pixel_error,2), color=cc[0]
    endif
    im = rebin(image1,512,256)
    im[0,*] = 0		; put dark border around image
    im[511,*] = 0
    im[*,0] = 0
    im[*,255] = 0
    ;stop, 'STOP: Check out "im" ...'
    ; +++++  ERROR with IDL v6.3 on MAC to do tv or tvscl (Bus error at OS-X system level) +++++
    if keyword_set(scale) then tvscl, im, 200, 0 else tv, im, 200, 0

    if (waittime lt 0) then begin
      ans = ' '
      read, 'Next ? ', ans
    endif else  wait, waittime

endfor

;
;	do extra plot at end if /info is given
;
doExtra = 1
if (not keyword_set(image)) and (doExtra ne 0) then begin
  ans = 'Y'
  read, 'Show Summary Plot ? (Y/N) ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then begin
    setplot
    !p.multi=[0,1,3]
    plot, data.time, data.pixel_error, psym=-4, xtitle='', ytitle='Pixel Errors', xmargin=[10,2], ymargin=[2,1]
    plot, data.time, data.total_counts, psym=-4, xtitle='', ytitle='Image Total', ys=1, xmargin=[10,2], ymargin=[2,1]
    plot, data.time, data.fid_index, psym=-4, xtitle='Time (sec)', ytitle='Fid. Index', ys=1, xmargin=[10,2], ymargin=[3,0]
    !p.multi=0
  endif
endif

;
;	return "image" data if asked for single image
;
if keyword_set(image) then image = image1

return
end
