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
;     hk_data      HK packets from file
;     sci_data     SCI packets from file
;     sps_ps_data  SPS_PS packets from file
;     log_data     LOG packets from file
;
;   Tom Woods
;   6/2/2016
;
pro plot_rxrs, filename, hk_data, sci_data, log_data, sps_ps_data, $
				xrange=xrange, yrange=yrange, channel=channel, $
				tzero=tzero, rocket=rocket, debug=debug

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick XRS Save File', filter='*xrs.sav')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

if keyword_set(rocket) then begin
  ;  force default to be last flight = 36.336
  if (rocket ne 36.258) and (rocket ne 36.275) and (rocket ne 36.286) $
  		and (rocket ne 36.290) and (rocket ne 36.300) and (rocket ne 36.318) $
  		and (rocket ne 36.336) then rocket = 36.336
endif else rocket = 36.336
print, 'Processing XRS data for rocket #', strtrim(rocket,2)

if keyword_set(tzero) then tzero_org = tzero else tzero_org = 0L

; gain for Rocket XRS to convert DN to fC:  #1 is for B1, A2, Dark-1; #2 is for A1, B2, Dark-2
xrs_gain = 7.00  ;  fC/DN
xrs_dark =  40.  ;  DN/sec

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
  if (extfile eq 'DAT') then begin
     if (rocket lt 36.336) then begin
		 ; read the file using read_isis_xrs.pro
		 read_isis_xrs, filename, hk=hk, sci=sci, log=log, /verbose
		 filename_org = filename
		 filename = strmid(filename,0,rpos) + '.sav'
		 print, 'DAT file is being rewritten as SAV file'
		 save, hk, sci, log, file=filename
	endif else begin
		 ; read the file using read_rxrs_2018.pro
		 read_rxrs_2018, filename, hk=hk, sci=sci, log=log, sps_ps=sps_ps, /verbose
		 filename_org = filename
		 filename = strmid(filename,0,rpos) + '.sav'
		 print, 'DAT file is being rewritten as SAV file'
		 save, hk, sci, log, sps_ps, file=filename
		 ; stop, 'DEBUG sps_ps...'
	endelse
  endif else begin
	print, 'File has wrong extension, expected .sav'
  	return
  endelse
endif

;
;   read the save set
;		Assumes read_isis_xrs() has been used to store HK and LOG packets into IDL save set
;
restore, filename

;  save the data as returned output
hk_data = hk
sci_data = sci
log_data = log
if (rocket ge 36.336) then sps_ps_data = sps_ps

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
xmargin=[7.2,1.2]
ymargin=[3,2]

if keyword_set(channel) then begin
  !p.multi=0
  if (channel lt 1) then channel = 1L
  if (channel gt numxrs) then channel = numxrs
  kstart=channel-1
  kend = kstart
  xmargin=[8.5,2]
  ymargin=[4,2]
endif

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
    dtdark=6.
    twindow = 315.
    dtwindow=4.
    dtmove=3.
endif else if (rocket eq 36.336) then begin
    rkt_tzero = 19*3600L+0*60L+0.000D0  ; launch time in UT
    tapogee = 275.
    dtlight = 15.
    tdark1 = 70.
    tdark2 = 490.
    dtdark=9.
    twindow = 338.
    dtwindow=3.
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
if keyword_set(rocket) then tz = rkt_tzero
if tzero_org ne 0 then tz = tzero_org	; force tzero to be the one in the keyword "tzero"

ptime = (thk - tz)
xtitle='Time (sec)'

; also generate time for SCI packet
ydsci= jd2yd(gps2jd(sci.time))
tsci = (ydsci - long(ydsci[0]))* 24.D0*3600.  ; convert to seconds of day
;  ERROR in ISIS Setting time is off by 2 hours
tsci += 7200.
tz2 = tsci[0]
if keyword_set(tzero) or keyword_set(rocket) then tz2 = tzero
ptime2 = (tsci - tz2)

; also generate time for SPS_PS packet
if (rocket ge 36.336) then begin
	ydsps= jd2yd(gps2jd(sps_ps.time))
	tsps = (ydsps - long(ydsps[0]))* 24.D0*3600.  ; convert to seconds of day
	;  ERROR in ISIS Setting time is off by 2 hours
	tsps += 7200.
	tz3 = tsps[0]
	if keyword_set(tzero) or keyword_set(rocket) then tz3 = tzero
	ptime3 = (tsps - tz3)
endif

;
;   get time ranges for rocket flight data
;
if (rocket ne 0.0) then begin
  wgda = where( (ptime gt (tapogee-dtlight)) and (ptime lt (tapogee+dtlight)) )
  wgd1 = where( (ptime gt (tdark1-dtdark)) and (ptime lt (tdark1+dtdark)) )
  wgd2 = where( (ptime gt (tdark2-dtdark)) and (ptime lt (tdark2+dtdark)) )
  wgd3 = where( (ptime gt (twindow-dtwindow)) and (ptime lt (twindow+dtwindow)), numvis )
  wdark = where( ((ptime gt (tdark1-dtdark)) and (ptime lt (tdark1+dtdark))) or $
  			((ptime gt (tdark2-dtdark)) and (ptime lt (tdark2+dtdark))) or $
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
    0: begin
    	xrs_data = hk.xps_data2 * xrs_gain
    	xrs_data2 = sci.xps_data2 * xrs_gain / float(sci.sps_xps_count)
       end
    1: begin
    	xrs_data = hk.xps_data * xrs_gain
    	xrs_data2 = sci.xps_data * xrs_gain / float(sci.sps_xps_count)
       end
    2: begin
    	xrs_data = hk.sps_sum
    	xrs_data2 = ((total(sci.sps_data,1)/ float(sci.sps_xps_count)) - 4.*xrs_dark) * xrs_gain
       end
    3: begin
    	xrs_data = hk.sps_sum2
    	xrs_data2 = ((total(sci.sps_data2,1)/ float(sci.sps_xps_count)) - 4.*xrs_dark) * xrs_gain
       end
    endcase

	wxr = where(ptime ge xrange[0] and ptime le xrange[1])
    if keyword_set(yrange) then yr = yrange else $
    	yr = [min(xrs_data[wxr])*0.9, max(xrs_data[wxr])*1.1]

    plot, ptime, xrs_data, ys=1, xrange=xrange, yrange=yr, $
        xtitle=xtitle, ytitle='Signal (fC)', title=mtitle, xmargin=xmargin, ymargin=ymargin
	; over plot the SCI data
	oplot, ptime2, xrs_data2, color=cc[3]

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
      light = mean( xrs_data[wgda] )
      dark1 = mean( xrs_data[wgd1] )
      dark2 = mean( xrs_data[wgd2] )
      mdark = (dark1+dark2)/2.
      dfit = poly_fit( ptime[wdark], xrs_data[wdark], 2 )
      fitdark = dfit[0] + dfit[1] * ptime + dfit[2] * ptime^2.
      fdark = mean( fitdark[wgda] )
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


;
;	now plot X123 data
;
fast = hk.x123_fast_count
slow = hk.x123_slow_count
fast2 = sci.x123_fast_count / (sci.x123_accum_time/1000.)
slow2 = sci.x123_slow_count / (sci.x123_accum_time/1000.)

wgdx123 = where((ptime2 ge (tapogee-dtlight)) and (ptime2 le (tapogee+dtlight)),num_gdx123)
if (num_gdx123 gt 1) then begin
	x123_sp = sci[wgdx123[0]].x123_spectrum / (sci[wgdx123[0]].x123_accum_time/1000.)
	for ii=1,num_gdx123-1 do x123_sp += sci[wgdx123[ii]].x123_spectrum / (sci[wgdx123[ii]].x123_accum_time/1000.)
	x123_sp /= float(num_gdx123)
	x123_energy = 0.03 * findgen(1024) - 0.05
endif

ans = ' '
read, 'Next Plot for X123 ? ', ans

; for X123 spectrum
xmargin2=[8,3]

setplot
cc=rainbow(7)
!p.multi=[0,1,2]

;  FIRST X123 plot is time series of Fast and Slow counts
plot, ptime2, fast2, xrange=xrange, $
	xtitle=xtitle, ytitle='X123 Total Signal (cps)', title='X123 Fast (black) & Slow (green)', $
	xmargin=xmargin, ymargin=ymargin
oplot, ptime-1.5, fast, line=2
oplot, ptime2, slow2, color=cc[3]
oplot, ptime-1.5, slow, color=cc[3], line=2

;  SECOND X123 plot is spectrum at Apogee
plot, x123_energy, x123_sp, psym=10, /ylog, xrange=[0,5], yrange=[3E-1,max(x123_sp)*1.5], ys=1, $
	xtitle='Energy (keV)', ytitle='X123 Signal (cps)', title='Apogee', xmargin=xmargin2, ymargin=ymargin

!p.multi = 0

;  only plot SPS and PicoSIM for rocket GE 36.336
if rocket lt 36.336 then goto, rxrs_end

;
;	now plot SPS data
;
read, 'Next Plot for SPS ? ', ans

wa3 = where((ptime3 ge (tapogee-dtlight)) and (ptime3 le (tapogee+dtlight)))
print, 'X123-SPS Apogee Sum = ', mean(sps_ps[wa3].sps_sum)
print, '           Apogee X = ', mean(sps_ps[wa3].sps_x)
print, '           Apogee Y = ', mean(sps_ps[wa3].sps_y)

setplot
cc=rainbow(7)
!p.multi=[0,1,2]

;  first plot is the SPS Sum
;  FIRST X123 plot is time series of Fast and Slow counts
plot, ptime3, sps_ps.sps_sum, xrange=xrange, $
	xtitle=xtitle, ytitle='SPS Sum', title='X123 SPS', xmargin=xmargin, ymargin=ymargin

;  second plot is the SPS X & Y
plot, ptime3, sps_ps.sps_x, /nodata, xrange=xrange, yrange=[-2,2], ys=1, $
	xtitle=xtitle, ytitle='SPS X & Y (degrees)', title='Offsets: X (red), Y (green)', $
	xmargin=xmargin, ymargin=ymargin
oplot, ptime3, sps_ps.sps_x, color=cc[0]
oplot, ptime3, sps_ps.sps_y, color=cc[3]
!p.multi = 0

;
;	now plot PicoSIM NIR data
;
read, 'Next Plot for PicoSIM ? ', ans

setplot
cc=rainbow(7)
cs = 1.8

ps_rate = sps_ps.ps_signal
for ii=0,5 do ps_rate[ii,*] /= ((sps_ps.ps_integ_time > 22.4)/1000.)

plot, ptime3, ps_rate[0,*], /nodata, xrange=xrange, yrange=[0,max(ps_rate)*1.1], ys=1, $
	xtitle=xtitle, ytitle='Signal (DN/sec)', title='X123-PicoSIM NIR', $
	xmargin=xmargin2, ymargin=ymargin
xx = !x.crange[0]*0.9 + !x.crange[1]*0.1
dy = (!y.crange[1] - !y.crange[0])/18.
yy = !y.crange[1] - dy*2
for ii=0,5 do begin
	oplot, ptime3, ps_rate[ii,*], color=cc[ii]
	xyouts, xx, yy-dy*ii, strtrim(ii+1,2), color=cc[ii], charsize=cs
endfor

rxrs_end:
if keyword_set(debug) then stop, 'DEBUG at end ...'

return
end
