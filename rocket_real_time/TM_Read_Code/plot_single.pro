;
;	plot_single.pro
;
;	Plot single analog data time series from read_tm1_cd.pro
;
;	Tom Woods
;	10/15/06
;
pro plot_single, filename, data, xrange=xrange

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick Single Analog Data File', filter='*sa*.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

;
;	get size of data line from filename
;
rnum = rstrpos( filename, '_' )
rdot = rstrpos( filename, '.' )
numstr = strmid( filename, rnum+1, rdot-rnum-1 )
num = long(numstr)

openr,lun,filename, /get_lun
a = assoc(lun, dblarr(num+1L))

finfo = fstat(lun)
fsize = finfo.size
nbytes = (num+1L)*8L
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: only partial data set found, so nothing to plot"
  close, lun
  free_lun, lun
  return
endif

;
;	read the data
;
data = dblarr(num+1L,dcnt)
time = dblarr(dcnt)
single = dblarr(dcnt)
for k=0L,dcnt-1L do begin
  data[*,k] = a[k]
  time[k] = data[0,k]
  single[k] = mean(data[1:*,k])
endfor

close, lun
free_lun, lun

;
;	now plot the data
;
setplot
if keyword_set(xrange) then begin
  plot, (time-time[0]), single, ys=1, xtitle='Time (sec)', ytitle='Signal (V)', xrange=xrange
endif else begin
  plot, (time-time[0]), single, ys=1, xtitle='Time (sec)', ytitle='Signal (V)'
endelse

return
end
