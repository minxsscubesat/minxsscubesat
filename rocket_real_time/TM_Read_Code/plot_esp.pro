;
;   plot_esp.pro
;
;   Plot ESP channel time series from read_tm1_cd.pro
;
;   INPUT
;     filename file name (*esp.dat or '' to ask user to select file)
;     xrange=xrange    time range for plot
;     channel=channel  number of channel to plot (single plot versus all 9 channels)
;                channel = 1-9
;	  tzero=tzero  time (sec of day) for zero time (launch time)
;
;   OUTPUT
;     data     all data from file
;
;   Tom Woods
;   10/15/06
;
pro plot_esp, filename, edata, xrange=xrange, yrange=yrange, channel=channel, $
				tzero=tzero, notime=notime, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick ESP Data File', filter='*esp.dat')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

numesp = 9L
; numesp = 12L   ; fixed record length for Intel based Mac

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
;   data structure needs to be same as what is defined in read_tm1_cd.pro
;
esp1 = { time: 0.0D0, fpga_time: 0.0, rec_count: 0, rec_error: 0, cnt: uintarr(numesp) }
nbytes = n_tags(esp1,/length)

openr,lun,filename, /get_lun
a = assoc(lun, esp1)

finfo = fstat(lun)
fsize = finfo.size
dcnt = fsize/nbytes

if (dcnt le 0) then begin
  print, 'ERROR: only partial data set found, so nothing to plot"
  close, lun
  free_lun, lun
  return
endif

;
;   read the binary data file
;
edata = replicate( esp1, dcnt )
for k=0L,dcnt-1L do begin
  etemp = a[k]
  ;  swap_endian_inplace, etemp, /swap_if_little_endian
  edata[k] = etemp
endfor

close, lun
free_lun, lun

;
;  clean the data based on bad fpga_time shifts (only for the *.DAT file)
;
diff = edata.fpga_time - shift(edata.fpga_time,1)
diff[0] = diff[1]
wgood = where( abs(diff) lt 0.6 )
wbad = where( abs(diff) ge 0.6, numbad )
edata = edata[wgood]
if (numbad gt 0) then print, 'WARNING: ', strtrim(numbad,2), ' packets thrown out for bad time values.'

endif else if (extfile eq 'SAV') then begin
  ;
  ;	READ IF block for *.SAV files
  ;
  restore, filename	; expect to have "edata" in this save set

endif else begin
  print, 'Expected file to have an extension, either .dat or .sav'
  return
endelse

;
;   now plot the data
;
ans = ' '
if (!d.name eq 'X') and ((!d.x_size ne 1200) or (!d.y_size ne 800)) then window,0,xsize=1200,ysize=800
setplot
!p.multi=[0,3,3]
kstart = 0L
kend = 8L
xmargin=[6,1]
ymargin=[3,2]

if keyword_set(channel) then begin
  !p.multi=0
  if (channel lt 1) then channel = 1L
  if (channel gt 9) then channel = 9L
  kstart=channel-1
  kend = kstart
  xmargin=[8,2]
  ymargin=[4,2]
endif

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.286
  if (rocket ne 36.258) and (rocket ne 36.275) and (rocket ne 36.286) $
  		and (rocket ne 36.290) and (rocket ne 36.300) and (rocket ne 36.318) $
  		and (rocket ne 36.336) then rocket = 36.336
endif else rocket = 36.336

print, 'Processing ESP data for rocket = ', rocket

if (rocket eq 36.258) then begin
    rkt_tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 15.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=5.
    twindow = 305.
    dtwindow=5.
endif else if (rocket eq 36.275) then begin
    rkt_tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = 387.
    dtwindow=2.
    tpitch5 = 420.
    tyaw5 = 445.
    dtmove=2.
endif else if (rocket eq 36.286) then begin
    rkt_tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = -1.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.290) then begin
    rkt_tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = -1.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.300) then begin
    rkt_tzero = 19*3600L+15*60L+0.000D0  ; launch time in UT
    ;  launch failure - BB cut down
    tapogee = 180
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 300.
    dtdark=5.
    twindow = -1.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.318) then begin
    rkt_tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = 315.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.336) then begin
    rkt_tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = 332.
    dtwindow=3.
    dtmove=2.
endif else begin
    ; force plot to not look for dark and visible light
    rocket = 0.0
endelse

tz = edata[0].time
if keyword_set(rocket) then tz = rkt_tzero
if keyword_set(tzero) then tz = tzero 		; keyword tzero has higher priority

ptime = (edata.time - tz)
xtitle='Time (sec)'
if keyword_set(notime) then begin
  ptime = findgen(n_elements(edata))
  xtitle='Sample'
endif

;
;   get time ranges for rocket flight data
;
if (rocket ne 0.0) then begin
  wgd = where( (ptime gt (tapogee-dtlight)) and (ptime lt (tapogee+dtlight)) )
  wgd1 = where( (ptime gt (tdark1-dtdark)) and (ptime lt (tdark1+dtdark)) )
  wgd2 = where( (ptime gt (tdark2-dtdark)) and (ptime lt (tdark2+dtdark)) )
  wgd3 = where( (ptime gt (twindow-dtwindow)) and (ptime lt (twindow+dtwindow)), numvis )
  temp = mean( ptime )  ; dummy so header strings printed after MEAN compile messages
  signal = fltarr(9)
  print, ' '
  print, 'Channel    Dark-1    Dark-2      Apogee   Visible   Signal (Light-Dark)'
endif

if not keyword_set(xrange) then xrange = [min(ptime), max(ptime)]

for k=kstart,kend do begin
    mtitle='ESP #' + strtrim(k+1,2)

	wgdx = where(ptime ge xrange[0] and ptime le xrange[1])
    if keyword_set(yrange) then yr = yrange else $
    	yr = [min(edata[wgdx].cnt[k])*0.9, max(edata[wgdx].cnt[k])*1.1]
    plot, ptime, edata.cnt[k], ys=1, xrange=xrange, yrange=yr, $
        xtitle=xtitle, ytitle='Counts', title=mtitle, xmargin=xmargin, ymargin=ymargin

    if (rocket ne 0.0) then begin
      oplot, (tapogee-dtlight)*[1,1], !y.crange, line=2
      oplot, (tapogee+dtlight)*[1,1], !y.crange, line=2
      oplot, (tdark1-dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark1+dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark2-dtdark)*[1,1], !y.crange, line=1
      oplot, (tdark2+dtdark)*[1,1], !y.crange, line=1
      ; oplot, (twindow-dtwindow)*[1,1], !y.crange, line=3
      ; oplot, (twindow+dtwindow)*[1,1], !y.crange, line=3
      oplot, (twindow)*[1,1], !y.crange, line=3
      light = mean( edata[wgd].cnt[k] )
      dark1 = mean( edata[wgd1].cnt[k] )
      dark2 = mean( edata[wgd2].cnt[k] )
      if (twindow gt 0) and (numvis gt 2) then begin
        visible = mean( edata[wgd3].cnt[k] )
        visible = visible - (dark1+dark2)/2.
      endif else visible = 0.0
      signal[k] = light-(dark1+dark2)/2.
      print, 'ESP #',k+1,dark1,dark2,light,visible,signal[k],format='(A5,I2,2F10.2,F12.2,F10.2,F12.2)'
    endif
endfor
!p.multi=0

if (rocket ne 0.0) then begin
  ESP_X_FACTOR = 29.70 * 0.744  ; calibrate to SPARCS 36.275
  ESP_Y_FACTOR = 63.83 * 1.139  ; calibrate to SPARCS 36.275
  print, ' '
  if (kstart le 3) and (kend ge 6) then begin
    ; QUAD diode calculation -  quad pattern (x,y view):
    ;      5   6
    ;      4   7
    ; note that index is diode number - 1
    sum = total(signal[3:6])
    quad_x = (((signal[5]+signal[6])-(signal[4]+signal[3])) / sum) * ESP_X_FACTOR  ; in arc-minutes
    quad_y = (((signal[4]+signal[5])-(signal[3]+signal[6])) / sum) * ESP_Y_FACTOR  ; in arc-minutes
    print, 'QUAD X = ', string(quad_x,format='(F6.2)'), ' arc-minutes'
    print, 'QUAD Y = ', string(quad_y,format='(F6.2)'), ' arc-minutes'
    ;
    ;	Did Pitch +5 and Yaw +5 near end of 36.275 flight to check out SPARCS pointing
    ;
    if (rocket eq 36.275) then begin
      wgdp = where( (ptime gt (tpitch5-dtmove)) and (ptime lt (tpitch5+dtmove)) )
      wgdy = where( (ptime gt (tyaw5-dtmove)) and (ptime lt (tyaw5+dtmove)) )
      pquad = fltarr(4)
      yquad = fltarr(4)
      for k=0,3 do begin
        plight = mean( edata[wgdp].cnt[k+3] )
        ylight = mean( edata[wgdy].cnt[k+3] )
        dark1 = mean( edata[wgd1].cnt[k+3] )
        dark2 = mean( edata[wgd2].cnt[k+3] )
        pquad[k] = plight - (dark1+dark2)/2.
        yquad[k] = ylight - (dark1+dark2)/2.
      endfor
      ;  PITCH +5
      psum = total(pquad)
      pquad_x = (((pquad[2]+pquad[3])-(pquad[1]+pquad[0])) / psum) * ESP_X_FACTOR  ; in arc-minutes
      pquad_y = (((pquad[1]+pquad[2])-(pquad[0]+pquad[3])) / psum) * ESP_Y_FACTOR  ; in arc-minutes
      print, ' '
      print, 'PITCH+5 QUAD X = ', string(pquad_x,format='(F6.2)'), ' arc-minutes'
      print, 'PITCH+5 QUAD Y = ', string(pquad_y,format='(F6.2)'), ' arc-minutes'
      ;  Yaw +5
      ysum = total(yquad)
      yquad_x = (((yquad[2]+yquad[3])-(yquad[1]+yquad[0])) / ysum) * ESP_X_FACTOR  ; in arc-minutes
      yquad_y = (((yquad[1]+yquad[2])-(yquad[0]+yquad[3])) / ysum) * ESP_Y_FACTOR  ; in arc-minutes
      print, ' '
      print, ' YAW+5  QUAD X = ', string(yquad_x,format='(F6.2)'), ' arc-minutes'
      print, ' YAW+5  QUAD Y = ', string(yquad_y,format='(F6.2)'), ' arc-minutes'
    endif
  endif
endif

return
end
