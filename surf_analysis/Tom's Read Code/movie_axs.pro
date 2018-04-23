;
;   movie_axs.pro
;
;   Show movie of AXS spectra
;
;   INPUT
;     filename   output file from read_tm2_cd (/classic)
;     waittime   time to wait between images (sec)
;     spectrum   number of spectrum to view (and return data for)
;	  tzero      time (sec of day) for zero time (launch time)
;
;   OUTPUT
;     spectrum if set as input, then "spectrum" is also output of that spectrum record
;
;   Tom Woods
;   10/16/06
;
pro movie_axs, filename, waittime, spectrum=spectrum, tzero=tzero

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick AXS Spectra Data File', filter='*axs.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if n_params() lt 2 then waittime = 0.1
if (waittime lt 0.05) then waittime = 0.05
if (waittime gt 10) then waittime = 10.

;
;   same definition as in read_tm1_cd.pro
;
numaxs = 2048L
axs1 = { time: 0.0D0, rec_error: 0, cnt: uintarr(numaxs) }
nbytes = n_tags(axs1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, axs1)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: incomplete AXS spectrum in file'
  close,lun
  free_lun,lun
  return
endif

;
;   read / display the data
;
if (!d.name eq 'X') and ((!d.x_size ne 800) or (!d.y_size ne 600)) then window,0,xsize=800,ysize=600
setplot
cc=rainbow(7)
; loadct,4
kstart = 0L
kend = dcnt-1L

if keyword_set(spectrum) then begin
  kstart = long(spectrum[0])
  if (kstart lt 0) then kstart = 0L
  if (kstart ge dcnt) then kstart = dcnt-1L
  kend = kstart
endif

for k=kstart,kend do begin
  axs1 = a[k]
  if (k eq kstart) then begin
    tz = axs1.time
    if keyword_set(tzero) then tz = tzero
  endif
  ;
  ; plot spectrum
  ;
  sp1 = axs1.cnt
  yrange = [min(sp1)*0.9,max(sp1)*1.1]
  yrange = [0,1000]
  mtitle = 'Sp'+strtrim(k,2)+': Time @ '+strtrim(long(axs1.time-tz),2)
  plot, sp1, xtitle='X',ytitle='Counts', title=mtitle, $
     yr=yrange,ys=1,xr=[0,2050],xs=1, xmargin=[7,2],ymargin=[3.5,2]
  if (axs1.rec_error gt 0) then begin
    xx = !x.crange[0] + (!x.crange[1]-!x.crange[0])*0.1
    yy = !y.crange[1] - (!y.crange[1]-!y.crange[0])*0.1
    xyouts, xx, yy, 'Record Errors = '+strtrim(axs1.rec_error,2), color=cc[0]
  endif
  wait, waittime
endfor

close, lun
free_lun, lun

;
;   return "spectrum" data if asked for single image
;
if keyword_set(spectrum) then spectrum = axs1

return
end
