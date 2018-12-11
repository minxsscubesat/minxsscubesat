;
;	satellite_pass_timer
;
;	This procedure will display the Satellite Pass timer and future pass times
;
;	********************************
;	***                          ***
;	***   Run this continuously  ***
;	***                          ***
;	********************************
;
;	INPUT
;		station		Option to specify ground station by name; default is 'Boulder'
;		dual_station Option to specify second ground station: /dual defaults to 'Fairbanks'
;		add_pass	Option to add manual pass with start_JD and end_JD
;		smaller   Option to make display smaller
;		larger    Option to make display larger
;
;	OUTPUT
;		Plot is updated every second with Pass time information
;
;	ASSUMPTIONS
;		Environment needs to be set for 'TLE_dir' directory path
;		The minxss_passes_latest.sav file is copied regularly to $TLE_dir/pass_saveset/
;		You may need to change the "slash" definition in Line 42 if using Mac or PC Windows
;
;	PROCEDURE
;	1.  Read IDL save set of passes in passes_latest_STATION.sav
;	2.  Determine time to next Pass AOS or if in pass, the time to Pass LOS
;	3.  Repeat Step 2 until Pass is complete, then goto Step 1
;
;	HISTORY
;		2016-Nov-18  T. Woods	Original Code
;
function rgb2long, rgb
   return, ishft(long(rgb[0]),16) + ishft(long(rgb[1]),8) + rgb[2]
end

pro satellite_pass_timer, station, dual_station=dual_station, add_pass=add_pass, debug=debug, verbose=verbose, $
        smaller=smaller, larger=larger

;  check inputs
if n_params() lt 1 then station ='Boulder'
station_caps = strupcase(station)
if strlen(station) lt 1 then begin
  print, 'ERROR: station needs to be defined (either "Boulder" or "Fairbanks") !'
  return
endif
doDual = 0
if keyword_set(dual_station) then begin
	doDual = 1
	if strlen(strtrim(dual_station,2)) lt 2 then dual_station='Fairbanks'
	dual_station_caps = strupcase(dual_station)
endif
if keyword_set(debug) then verbose = 1

if not keyword_set(smaller) then begin
  if keyword_set(larger) then smaller=0 else smaller=1
endif
if (smaller eq 0) then larger=1

;
;	setup path for reading Satellite Pass info that was stored by plan_satellite_pass.pro
;
;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then slash = '\' else slash = '/'
path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then path_name += slash
; else path_name is empty string
save_path = path_name + station_caps + slash
if keyword_set(verbose) then print, '*** Pass Saveset path = ', save_path
save_name1 = 'passes_latest_'+station_caps+'.sav'
if (doDual ne 0) then begin
	save_path2 = path_name + dual_station_caps + slash
	save_name2 = 'passes_latest_'+dual_station_caps+'.sav'
endif

;
;	read MinXSS Logo
;		logo_img = bytarr(4, 374, 400)
;		resize down to bytarr(4,187,200)
;			tv, logo_img[1:3,*,*] will display yellow back and blue text
;
logo_file = path_name + 'pass_saveset' + slash + 'MinXSS_1_Logo.png'
logo_ok = query_png( logo_file, logo_status )
if (logo_ok) then begin
	logo_pulse = 0
	logo_img = read_png( logo_file )
	if keyword_set(smaller) then begin
    logo_img1 = rebin(logo_img[0:2,0:371,*],3,93,100)
    logo_img2 = rebin(logo_img[1:3,0:371,*],3,93,100)
	endif else begin
	  logo_img1 = rebin(logo_img[0:2,*,*],3,187,200)
	  logo_img2 = rebin(logo_img[1:3,*,*],3,187,200)
	endelse
endif
logo2_file = path_name + 'pass_saveset' + slash + 'MinXSS_2_Logo.png'
logo2_ok = query_png( logo2_file, logo2_status )
if (logo2_ok) then begin
	logo2_pulse = 0
	logo2_img = read_png( logo2_file )
	if keyword_set(smaller) then begin
    logo2_img1 = rebin(logo2_img[0:2,0:371,*],3,93,100)
    logo2_img2 = rebin(logo2_img[1:3,0:371,*],3,93,100)
  endif else begin
    logo2_img1 = rebin(logo2_img[0:2,*,*],3,187,200)
    logo2_img2 = rebin(logo2_img[1:3,*,*],3,187,200)
  endelse
endif

;
;	Configure standard window (user can resize if they want)
;	Use old style IDL plots so objects don't have to be destroyed continously
;
; Option for larger window
wxmin = 1850L
wymin = 450L
if keyword_set(smaller) then begin
  wxmin = 1200L
  wymin = 300L
endif
ydual = wymin
fdual = 0.5
if (doDual ne 0) then wymin *= 2
wtitle = station_caps + ' Pass Information'
; device,get_window_pos=wpos
window, 0, XSIZE=wxmin, YSIZE=wymin, XPOS=0, YPOS=40, TITLE=wtitle
device, SET_FONT='Helvetica', /TT_FONT
; cc = rainbow(255,/image)

;
;	1.  Read IDL save set of passes in minxss_passes_latest.sav
;			save set variables = passes, location
;
;		passes.start_JD,  .start_date,  .start_time
;		passes.end_JD,    .end_date,    .end_time
;		passes.sunlight (0 = eclipse, 1=sunlight)
;
RESTART_NEW_PASS:

if (doDual ne 0) then begin
	restore, save_path2 + save_name2
	passes2 = passes	; rename restored variable "passes" for the dual station
	num_passes2 = n_elements(passes2)
	waiting_for_pass2 = 1
	ipass2 = 0L		; start search at first pass in file
	ipassLast2 = -1L
endif
pass_completed2 = 0

waiting_for_pass = 1
pass_completed = 0
ipass = 0L		; start search at first pass in file
ipassLast = -1L
restore, save_path + save_name1
num_passes = n_elements(passes)

if keyword_set(add_pass) and (n_elements(add_pass) ge 2) then begin
	; insert manual pass into existing pass list
	if keyword_set(verbose) then print, 'Adding Extra Pass Manually'
	apasses = passes
	num_passes += 1L
	add_done = 0
	passes = replicate(apasses[0],num_passes)
	j = 0L
	for k=0L,num_passes-2 do begin
		if (add_pass[0] lt apasses[k].start_jd) and (add_done eq 0) then begin
		  passes[j].start_jd = add_pass[0]
		  passes[j].end_jd = add_pass[1]
		  passes[j].sunlight = 2
		  j += 1
		  passes[j] = apasses[k]
		  add_done = 1
		endif else begin
		  passes[j] = apasses[k]
		endelse
		j += 1
	endfor
	if (j eq k) and (add_done eq 0) then begin
		passes[j].start_jd = add_pass[0]
		passes[j].end_jd = add_pass[1]
		passes[j].sunlight = 2
	endif
endif
print, '*** Saveset ', save_name1, ' has ', num_passes, ' pass times.'
print, '*** Use Control-C to exit this loop of displaying time...'

wxsize = 0L
wysize = 0L
xaos = 0.10   ; originally was 0.15
xlos = 0.30   ; originally was 0.35
xsun = 0.52   ; originally was 0.52
xtime = 0.65  ; originally was 0.62
yy = [ 0.94, 0.75, 0.45, 0.35, 0.25, 0.15, 0.05 ]
dyy = 0.1
dyy2 = 0.18
csize = [ 3, 3, 1.8, 1.8, 1.8, 1.8, 1.8 ]
if keyword_set(smaller) then csize=csize/1.5
cthick = [ 1, 2, 1, 1, 1, 1, 1 ]
if !version.os_family eq 'Windows' then begin
  ccolor = [ rgb2long(reverse(!color.white)), rgb2long(reverse(!color.yellow)), rgb2long(reverse(!color.white)), $
    rgb2long(reverse(!color.white)),  rgb2long(reverse(!color.white)), rgb2long(reverse(!color.white)),  rgb2long(reverse(!color.white)) ]
  color_wait = rgb2long(reverse(!color.lime_green))
  color_pass = rgb2long(reverse(!color.tomato))
endif else begin
  ; Mac or Linux
  ccolor = [ rgb2long(!color.white), rgb2long(!color.yellow), rgb2long(!color.white), $
		rgb2long(!color.white),  rgb2long(!color.white), rgb2long(!color.white),  rgb2long(!color.white) ]
  color_wait = rgb2long(!color.lime_green)
  color_pass = rgb2long(!color.tomato)
endelse
pextra = 5
xerase = [ xtime, 1, 1, xtime, xtime]
yerase = [0.5, 0.5, 0.995, 0.995, 0.5]
xtv = 0.7
ytv = 0.07
if (doDual ne 0) then begin
	yy /= 2.
	dyy /= 2.
	dyy2 /= 2.
	yerase /= 2.
	ytv /= 2.
endif

;
;	2.  Determine time to next Pass AOS or if in pass, the time to Pass LOS
;
KEEP_PLOTTING:
; get system time in Julian date
stime = systime(/julian, /utc)

; search "passes" array for which pass is next
for k=ipass,num_passes-1 do begin
	if stime le passes[k].start_jd or stime le passes[k].end_jd then break
endfor
if (k ge num_passes) then begin
	print, 'ERROR: There are no more future passes found.  Run plan_spacecraft_pass.pro ASAP !!!!!'
	return
endif

if (k eq ipass) or (ipassLast lt 0) then begin
	ipass = k & ipassLast = k
	if stime lt passes[k].start_jd then begin
		waiting_for_pass = 1
		sec_diff = (passes[k].start_jd - stime)*24.*3600.D0
	endif else if stime le passes[k].end_jd then begin
		waiting_for_pass = 0
		sec_diff = (passes[k].end_jd - stime)*24.*3600.D0
	endif
	;
	;	Make plot that displays time until pass AOS if waiting for pass or LOS if in a pass
	;		PLOT top half with AOS, Time to AOS / Time to LOS, LOS, Sunlight Flag
	;		PLOT bottom half with next 5 pass times (AOS, LOS, sunlight flag)
	;
	;	Use old style IDL plots so objects don't have to be destroyed continously
	;
	need_static = 0
	if (!d.x_size ne wxsize) or (!d.y_size ne wysize) then begin
		;   Write Static Stuff
		need_static = 1
		if keyword_set(debug) then begin
			print, 'X & Y Size = ', !d.x_size, !d.y_size, wxsize, wysize
			stop, 'Check out window size ...'
		endif
		; check is system doesn't allow for desired size
		if (wxsize eq 0) and (!d.x_size lt wxmin) then wxmin = !d.x_size
		if (wysize eq 0) and (!d.y_size lt wymin) then wymin = !d.y_size
		wxsize = !d.x_size & wysize = !d.y_size
		if (!d.x_size lt wxmin) then wxsize = wxmin
		if (!d.y_size lt wymin) then wysize = wymin
		;  force window to be same Min. size
		device,get_window_pos=wpos
		wpos[1] -= wysize  ; move bottom point to top of window
		window, 0, XSIZE=wxsize, YSIZE=wysize, XPOS=wpos[0], YPOS=wpos[1], title=wtitle
		erase
		plot, [0,1], [0,1], /nodata, yr=[0,1], ys=1+4, xr=[0,1], xs=1+4, xmargin=[0,0], ymargin=[0,0], $
			font=1, background=rgb2long(!color.black), color=rgb2long(!color.white)
		if keyword_set(debug) then begin
			print, 'Pass Index = ', ipass
			print, 'New Window Size = ', wxsize, ' x ', wysize
		endif
		xyouts, xaos, yy[0], 'AOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xlos, yy[0], 'LOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xsun, yy[0], 'Satellite-Phase-MaxEL', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		jmax = ipass + pextra
		if (jmax ge num_passes) then jmax=num_passes-1
		for j=ipass,jmax do begin
			ii = j-ipass+1
			caldat, passes[j].start_jd, month,day,year,hour,minute,second
			yymmdd = string(year,format='(I04)')+'/'+string(month,format='(I02)')+ $
					'/'+string(day,format='(I02)')
			hhmmss = string(hour,format='(I02)')+':'+string(minute,format='(I02)')+ $
					':'+string(second,format='(I02)')
			aos_time = yymmdd + '-' + hhmmss
			xyouts, xaos, yy[ii], aos_time, charsize=csize[ii], charthick=cthick[ii], color=ccolor[ii], align=0.5
			caldat, passes[j].end_jd, month,day,year,hour,minute,second
			yymmdd = string(year,format='(I04)')+'/'+string(month,format='(I02)')+ $
					'/'+string(day,format='(I02)')
			hhmmss = string(hour,format='(I02)')+':'+string(minute,format='(I02)')+ $
					':'+string(second,format='(I02)')
			los_time = yymmdd + '-' + hhmmss
			yyout = yy[ii]
			if (ii eq 1) then begin
				yyout -= dyy
				xyouts, xlos, yy[ii]+dyy, 'Next Pass', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[ii], align=0.5
				xyouts, xlos, yyout-dyy, 'Future Passes', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[0], align=0.5
			endif
			xyouts, xlos, yyout, los_time, charsize=csize[ii], charthick=cthick[ii], $
					color=ccolor[ii], align=0.5
			if (passes[j].sunlight eq 0) then phase = 'Eclipse' $
			else if (passes[j].sunlight eq 1) then phase = 'Sun' else phase = 'Extra Pass'
			elev_str = string(long(passes[j].max_elevation+0.5), format='(I2)')
			phase = strtrim(passes[j].satellite_name,2) + '-' + phase + '-' + elev_str
			xyouts, xsun, yy[ii], phase, charsize=csize[ii], charthick=cthick[ii], $
					color=ccolor[ii], align=0.5
		endfor
	endif

	;	Write Dynamic Stuff
	polyfill, xerase, yerase, color=rgb2long(!color.black)
	hour = long(sec_diff/3600.) & minutes = long((sec_diff-hour*3600.)/60.)
	seconds = long(sec_diff-hour*3600.-minutes*60.)
	hhmmss = string(hour,format='(I02)')+':'+string(minutes,format='(I02)')+':'+string(seconds,format='(I02)')
	cfactor=3.0
	tfactor=2.0
	if (waiting_for_pass eq 0) then begin
		xyouts, xtime, yy[1], hhmmss, charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_pass, align=0
		xyouts, xtime, yy[1]-dyy2, '  to LOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_pass, align=0
	endif else begin
		xyouts, xtime, yy[1], hhmmss, charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
		xyouts, xtime, yy[1]-dyy2, '  to AOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
	endelse
	;  also print system time in UTC
	caldat, stime, year, month, day, hour, minutes, seconds
	hhmmss = string(hour,format='(I02)')+':'+string(minutes,format='(I02)')+$
			':'+string(seconds,format='(I02)')
	xyouts, xtime, yy[0], 'Current UTC '+hhmmss+' @ '+station_caps+' GS', charsize=csize[0], charthick=cthick[0], $
			color=ccolor[0], align=0
	; pulse MinXSS Logo if in pass
	if (logo_ok ne 0) then begin
		if (waiting_for_pass ne 0) then begin
			tv,logo_img1,xtv,ytv,/data,true=1
		endif else begin
			if logo_pulse then tv,logo_img2,xtv,ytv,/data,true=1 $
			else tv,logo_img1,xtv,ytv,/data,true=1
			logo_pulse = not logo_pulse
		endelse
	endif

endif else begin
	; index moved forward to last pass has finished
	pass_completed = 1
endelse

;
;	do dual station display too (below the primary station section)
;
if (doDual ne 0) then begin
  ; search "passes2" array for which pass is next
  for k2=ipass2,num_passes2-1 do begin
	if stime le passes2[k2].start_jd or stime le passes2[k2].end_jd then break
  endfor
  if (k2 ge num_passes2) then begin
	print, 'ERROR: There are no more future passes found for station-2.  Run plan_spacecraft_pass.pro ASAP !!!!!'
	return
  endif

  if (k2 eq ipass2) or (ipassLast2 lt 0) then begin
	ipass2 = k2 & ipassLast2 = k2
	if stime lt passes2[k2].start_jd then begin
		waiting_for_pass2 = 1
		sec_diff = (passes2[k2].start_jd - stime)*24.*3600.D0
	endif else if stime le passes2[k2].end_jd then begin
		waiting_for_pass2 = 0
		sec_diff = (passes2[k2].end_jd - stime)*24.*3600.D0
	endif
	;
	;	Make plot that displays time until pass AOS if waiting for pass or LOS if in a pass
	;		PLOT top half with AOS, Time to AOS / Time to LOS, LOS, Sunlight Flag
	;		PLOT bottom half with next 5 pass times (AOS, LOS, sunlight flag)
	;
	;	Use old style IDL plots so objects don't have to be destroyed continously
	;
	if (need_static ne 0) then begin
		;   Write Static Stuff
		if keyword_set(debug) then begin
			print, 'Pass2 Index = ', ipass2
		endif
		oplot, [0,1],[0.5,0.5],thick=3,color=ccolor[0]
		xyouts, xaos, fdual+yy[0], 'AOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xlos, fdual+yy[0], 'LOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xsun, fdual+yy[0], 'Satellite-Phase-MaxEL', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		jmax = ipass2 + pextra
		if (jmax ge num_passes2) then jmax=num_passes2-1
		for j=ipass2,jmax do begin
			ii = j-ipass2+1
			caldat, passes2[j].start_jd, month,day,year,hour,minute,second
			yymmdd = string(year,format='(I04)')+'/'+string(month,format='(I02)')+ $
					'/'+string(day,format='(I02)')
			hhmmss = string(hour,format='(I02)')+':'+string(minute,format='(I02)')+ $
					':'+string(second,format='(I02)')
			aos_time = yymmdd + '-' + hhmmss
			xyouts, xaos, fdual+yy[ii], aos_time, charsize=csize[ii], charthick=cthick[ii], color=ccolor[ii], align=0.5
			caldat, passes2[j].end_jd, month,day,year,hour,minute,second
			yymmdd = string(year,format='(I04)')+'/'+string(month,format='(I02)')+ $
					'/'+string(day,format='(I02)')
			hhmmss = string(hour,format='(I02)')+':'+string(minute,format='(I02)')+ $
					':'+string(second,format='(I02)')
			los_time = yymmdd + '-' + hhmmss
			yyout = yy[ii]
			if (ii eq 1) then begin
				yyout -= dyy
				xyouts, xlos, fdual+yy[ii]+dyy, 'Next Pass', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[ii], align=0.5
				xyouts, xlos, fdual+yyout-dyy, 'Future passes2', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[0], align=0.5
			endif
			xyouts, xlos, fdual+yyout, los_time, charsize=csize[ii], charthick=cthick[ii], $
					color=ccolor[ii], align=0.5
			if (passes2[j].sunlight eq 0) then phase = 'Eclipse' $
			else if (passes2[j].sunlight eq 1) then phase = 'Sun' else phase = 'Extra Pass'
			elev_str = string(long(passes2[j].max_elevation+0.5), format='(I2)')
			phase = strtrim(passes2[j].satellite_name,2) + '-' + phase + '-' + elev_str
			xyouts, xsun, fdual+yy[ii], phase, charsize=csize[ii], charthick=cthick[ii], $
					color=ccolor[ii], align=0.5
		endfor
	endif

	;	Write Dynamic Stuff
	polyfill, xerase, fdual+yerase, color=rgb2long(!color.black)
	hour = long(sec_diff/3600.) & minutes = long((sec_diff-hour*3600.)/60.)
	seconds = long(sec_diff-hour*3600.-minutes*60.)
	hhmmss = string(hour,format='(I02)')+':'+string(minutes,format='(I02)')+':'+string(seconds,format='(I02)')
	cfactor=3.0
	tfactor=2.0
	if (waiting_for_pass2 eq 0) then begin
		xyouts, xtime, fdual+yy[1], hhmmss, charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_pass, align=0
		xyouts, xtime, fdual+yy[1]-dyy2, '  to LOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_pass, align=0
	endif else begin
		xyouts, xtime, fdual+yy[1], hhmmss, charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
		xyouts, xtime, fdual+yy[1]-dyy2, '  to AOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
	endelse
	;  also print system time in UTC
	caldat, stime, year, month, day, hour, minutes, seconds
	hhmmss = string(hour,format='(I02)')+':'+string(minutes,format='(I02)')+$
			':'+string(seconds,format='(I02)')
	xyouts, xtime, fdual+yy[0], 'Current UTC '+hhmmss+' @ '+dual_station_caps+' GS', charsize=csize[0], charthick=cthick[0], $
			color=ccolor[0], align=0
	; pulse MinXSS Logo if in pass
	if (logo2_ok ne 0) then begin
		if (waiting_for_pass2 ne 0) then begin
			tv,logo2_img1,xtv,fdual+ytv,/data,true=1
		endif else begin
			if logo2_pulse then tv,logo2_img2,xtv,fdual+ytv,/data,true=1 $
			else tv,logo2_img1,xtv,fdual+ytv,/data,true=1
			logo2_pulse = not logo2_pulse
		endelse
	endif

  endif else begin
	; index moved forward to last pass has finished
	pass_completed2 = 1
  endelse

endif

;
;	3.  Repeat Step 2 until Pass is complete, then goto Step 1
;		Wait one second before doing next step
;
wait, 1
if (pass_completed ne 0) or (pass_completed2 ne 0) then begin
	if keyword_set(debug) and (pass_completed ne 0) then print, 'Station #1 completed pass.'
	if keyword_set(debug) and (pass_completed2 ne 0) then print, 'Station #2 completed pass.'
	if keyword_set(verbose) then print, 'PASS Completed. Looking for next pass...'
	goto, RESTART_NEW_PASS
endif
goto, KEEP_PLOTTING

if keyword_set(debug) then stop, 'DEBUG at end of satellite_pass_timer...'
return
end
