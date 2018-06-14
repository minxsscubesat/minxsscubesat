;
;   plot_rxrs.pro
;
;   Plot Rocket XRS channel time series from read_tm1.pro and read_isis_xrs.pro
;
;   INPUT
;     filename 	file name (*.sav or '' to ask user to select file)
;     xrange=xrange    time range for plot
;     channel=channel  number of channel to plot (single plot versus all 6 channels)
;                channel = 1-6
;	  tzero=tzero  time (sec of day) for zero time (launch time)
;
;   OUTPUT
;     data     all data from file
;
;   Tom Woods
;   6/2/2016
;
pro plot_rxrs, filename, xrsdata, xrange=xrange, yrange=yrange, channel=channel, $
				tzero=tzero, rocket=rocket, debug=debug

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick XRS Save File', filter='*xrs.sav')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

numxrs = 4L
;
;	read binary file if file given is *.dat or read (restore) IDL save set if file is *.sav
;
rpos = strpos( filename, '.', /reverse_search )
if (rpos lt 0) then begin
  print, 'Expected file to have an extension of .sav'
  return
endif
extfile = strupcase(strmid(filename,rpos+1,3))
if (extfile ne 'SAV') then begin
  print, 'File has wrong extension, expected .sav'
  return
endif

;
;   read the save set
;		Assumes read_isis_xrs() has been used to store HK and LOG packets into IDL save set
;
restore, filename


;
;   now plot the data
;
ans = ' '
if (!d.name eq 'X') and ((!d.x_size ne 1200) or (!d.y_size ne 800)) then window,0,xsize=1200,ysize=800
setplot
cc=rainbow(7)
!p.multi=[0,2,2]
kstart = 0L
kend = numxrs - 1L
xmargin=[6,1]
ymargin=[3,2]

if keyword_set(channel) then begin
  !p.multi=0
  if (channel lt 1) then channel = 1L
  if (channel gt numxrs) then channel = numxrs
  kstart=channel-1
  kend = kstart
  xmargin=[8,2]
  ymargin=[4,2]
endif

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.286
  if (rocket ne 36.258) or (rocket ne 36.275) or (rocket ne 36.286) $
  		or (rocket ne 36.290) or (rocket ne 36.300) or (rocket ne 36.318) then rocket = 36.318
endif else rocket = 36.318

if (rocket eq 36.258) then begin
    tzero = 18*3600L+32*60L+2.00D0  ; launch time in UT
    tapogee = 274.
    dtlight = 15.
    tdark1 = 50.
    tdark2 = 550.
    dtdark=5.
    twindow = 305.
    dtwindow=5.
endif else if (rocket eq 36.275) then begin
    tzero = 17*3600L+50*60L+0.354D0  ; launch time in UT
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
    tzero = 19*3600L+30*60L+1.000D0  ; launch time in UT
    tapogee = 276.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = -1.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.290) then begin
    tzero = 18*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=5.
    twindow = -1.
    dtwindow=2.
    dtmove=2.
endif else if (rocket eq 36.300) then begin
    tzero = 19*3600L+15*60L+0.000D0  ; launch time in UT
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
    tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 60.
    tdark2 = 490.
    dtdark=6.
    twindow = 315.
    dtwindow=4.
    dtmove=3.
endif else begin
    ; force plot to not look for dark and visible light
    rocket = 0.0
endelse

ydhk= jd2yd(gps2jd(hk.time))
thk = (ydhk - long(ydhk[0]))* 24.D0*3600.  ; convert to seconds of day
;  ERROR in ISIS Setting time is off by 2 hours
thk += 7200.

tz = thk[0]
if keyword_set(tzero) or keyword_set(rocket) then tz = tzero
ptime = (thk - tz)
xtitle='Time (sec)'

;
;   get time ranges for rocket flight data
;
if (rocket ne 0.0) then begin
  wgd = where( (ptime gt (tapogee-dtlight)) and (ptime lt (tapogee+dtlight)) )
  wgd1 = where( (ptime gt (tdark1-dtdark)) and (ptime lt (tdark1+dtdark)) )
  wgd2 = where( (ptime gt (tdark2-dtdark)) and (ptime lt (tdark2+dtdark)) )
  wgd3 = where( (ptime gt (twindow-dtwindow)) and (ptime lt (twindow+dtwindow)), numvis )
  wdark = where( (ptime lt tdark1) or (ptime gt tdark2) or $
  			((ptime gt (twindow-dtwindow)) and (ptime lt (twindow+dtwindow))), numdark )
  temp = mean( ptime )  ; dummy so header strings printed after MEAN compile messages
  signal = fltarr(numxrs)
  signal2 = signal
  print, ' '
  print, 'Channel    Dark-1    Dark-2      Apogee   Visible   Signal  f-Visible  f-Signal'
endif

if not keyword_set(xrange) then xrange = [min(ptime), max(ptime)]

xrs_name = ['XRS-A1', 'XRS-B1', 'XRS-A2', 'XRS-B2']

for k=kstart,kend do begin
    mtitle=xrs_name[k]

    case k of
    0: xrs_data = hk.xps_data2
    1: xrs_data = hk.xps_data
    2: xrs_data = hk.sps_sum
    3: xrs_data = hk.sps_sum2
    endcase

    if keyword_set(yrange) then yr = yrange else $
    	yr = [min(xrs_data)*0.9, max(xrs_data)*1.1]

    plot, ptime, xrs_data, ys=1, xrange=xrange, yrange=yr, $
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
      light = mean( xrs_data[wgd] )
      dark1 = mean( xrs_data[wgd1] )
      dark2 = mean( xrs_data[wgd2] )
      mdark = (dark1+dark2)/2.
      dfit = poly_fit( ptime[wdark], xrs_data[wdark], 2 )
      fitdark = dfit[0] + dfit[1] * ptime + dfit[2] * ptime^2.
      fdark = mean( fitdark[wgd] )
      oplot, ptime, fitdark, line=2, color=cc[0]
      if (twindow gt 0) and (numvis ge 2) then begin
        visible = mean( xrs_data[wgd3] )
        mvisible = visible - mdark
        fvisible = visible - fdark
      endif else begin
        mvisible = 0.0
        fvisible = 0.0
      endelse
      signal[k] = light-mdark
      signal2[k] = light-fdark
      print, xrs_name[k], dark1,dark2,light,mvisible,signal[k], fvisible,signal2[k], $
      				format='(A7,2F10.2,F12.2,4F10.2)'
    endif
endfor
!p.multi=0

xrsdata = hk

if keyword_set(debug) then stop, 'DEBUG at end ...'

return
end
