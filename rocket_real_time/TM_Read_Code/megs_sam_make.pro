;
;	megs_sam_make.pro
;
;	Combine all SAM images into single image
;
;	INPUT
;		filename   output file from read_tm2_cd (/classic)
;		range	   range of image indices to add together
;		/rocket	   option to specify rocket number
;
;	OUTPUT
;		image		output of summed image record
;
;	Tom Woods
;	11/19/2014
;
pro megs_sam_make, filename, range, sam_image, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick MEGS CCD Image Data File', filter='*raw*megs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if n_params() lt 2 then begin
  range = [0,100]
endif

ch = 'A'   ; only MEGS-A data can be used for SAM

waittime = 0.5

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

;  create SAM image
sam_image = dblarr(mnumx/2L, mnumy/2L)
sam_image_count = 0L

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

endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.290
  if (rocket ne 36.258) or (rocket ne 36.275) or (rocket ne 36.286) $
  		or (rocket ne 36.290) or (rocket ne 36.353) then rocket = 36.353
endif else rocket = 36.353
print, 'MEGS_SAM_MAKE: using rocket # ', rocket

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
if (rocket eq 36.286) then begin
    tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
endif
if (rocket eq 36.290) then begin
    tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
endif
if (rocket eq 36.353) then begin
    tzero = 17*3600L+25*60L+0.000D0  ; launch time in UT
    tapogee = 278.
    dtlight = 30.
    tdark1 = 65.
    tdark2 = 490.
    dtdark=10.
    data = adata
    adata = 0.
endif
;
;	no need to set T-zero (launch) time as that is already in the raw data file
;
;tz = data[0].time
;if keyword_set(tzero) or (rocket ne 0) then tz = tzero

;
;	display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=1100,ysize=600
setplot
cc=rainbow(7)
; loadct,4
sp1 = dblarr(mnumx)
sp2 = dblarr(mnumx)
kstart = 0L
kend = dcnt-1L

if (n_elements(range) ge 1) then begin
  if (range[0] gt 0) then kstart = range[0]
  if (range[0] gt (dcnt-1L)) then kstart = dcnt-1L
endif
if (n_elements(range) ge 2) then begin
  if (range[1] lt dcnt) then kend = range[1]
  if (range[1] lt 0) then kend=0
endif

for k=kstart,kend do begin
  megsim1 = data[k]
  image1 = megsim1.image

  ;  add to SAM image
  sam_image += image1[1024:*,0:511]
  sam_image_count += 1L

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
;	Display SAM image
;
if (sam_image_count gt 0) then sam_image /= sam_image_count
tv, sam_image

;
;	return SAM "image" data as 3rd parameter (no extra code needed for this)
;

return
end
