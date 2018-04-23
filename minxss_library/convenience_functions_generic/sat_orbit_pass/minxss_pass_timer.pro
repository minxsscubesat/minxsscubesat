;
;	minxss_pass_timer
;
;	This procedure will display the MinXSS Pass timer and future pass times
;
;	********************************
;	***                          ***
;	***   Run this continuously  ***
;	***                          ***
;	********************************
;
;	INPUT
;		fm			Option to specify FM 1 or 2, default is 1
;		add_pass	Option to add manual pass with start_JD and end_JD
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
;	1.  Read IDL save set of passes in minxss_passes_latest.sav
;	2.  Determine time to next Pass AOS or if in pass, the time to Pass LOS
;	3.  Repeat Step 2 until Pass is complete, then goto Step 1
;
;	HISTORY
;		2016-Nov-18  T. Woods	Original Code
;
function rgb2long, rgb
   return, ishft(long(rgb[0]),16) + ishft(long(rgb[1]),8) + rgb[2]
end

pro minxss_pass_timer, fm=fm, add_pass=add_pass, debug=debug, verbose=verbose

if keyword_set(debug) then verbose = 1
if not keyword_set(fm) then fm=1
if fm lt 1 then fm = 1
if fm gt 2 then fm = 2


;
;	setup path for reading MinXSS Pass info that was stored by minxss_satellite_pass.pro
;
;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then slash = '\' else slash = '/'
path_name = getenv('TLE_dir')
if strlen(path_name) gt 0 then path_name += slash
; else path_name is empty string
save_path = path_name + 'pass_saveset' + slash
if keyword_set(verbose) then print, '*** Pass Saveset path = ', save_path

;
;	read MinXSS Logo
;		logo_img = bytarr(4, 374, 400)
;		resize down to bytarr(4,187,200)
;			tv, logo_img[1:3,*,*] will display yellow back and blue text
;
logo_file = save_path + 'MinXSS_' + strtrim(long(fm),2)+'_Logo.png'
logo_ok = query_png( logo_file, logo_status )
if (logo_ok) then begin
	logo_pulse = 0
	logo_img = read_png( logo_file )
	logo_img1 = rebin(logo_img[0:2,*,*],3,187,200)
	logo_img2 = rebin(logo_img[1:3,*,*],3,187,200)
endif

;
;	Configure standard window (user can resize if they want)
;	Use old style IDL plots so objects don't have to be destroyed continously
;
wxmin = 1350L
wymin = 400L
wtitle = 'MinXSS-'+strtrim(long(fm),2)+' Pass Information'
window, 0, XSIZE=wxmin+50, YSIZE=wymin+50, TITLE=wtitle
device, SET_FONT='Helvetica', /TT_FONT
cc = rainbow(7)

;
;	1.  Read IDL save set of passes in minxss_passes_latest.sav
;			save set variables = passes, location
;
;		passes.start_JD,  .start_date,  .start_time
;		passes.end_JD,    .end_date,    .end_time
;		passes.sunlight (0 = eclipse, 1=sunlight)
;
RESTART_NEW_PASS:
waiting_for_pass = 1
pass_completed = 0
ipass = 0L		; start search at first pass in file
ipassLast = -1L
save_name1 = 'minxss_passes_latest.sav'
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
xaos = 0.15
xlos = 0.35
xsun = 0.52
xtime = 0.62
yy = [ 0.94, 0.75, 0.45, 0.35, 0.25, 0.15, 0.05 ]
csize = [ 3, 3, 1.8, 1.8, 1.8, 1.8, 1.8 ]
cthick = [ 1, 2, 1, 1, 1, 1, 1 ]
ccolor = [ rgb2long(!color.white), cc[4], rgb2long(!color.white), $
		rgb2long(!color.white),  rgb2long(!color.white), rgb2long(!color.white),  rgb2long(!color.white) ]
color_wait = cc[3]
color_pass = cc[0]
pextra = 5
xerase = [ 0.60, 1, 1, 0.6, 0.6]
yerase = [0.5, 0.5, 1, 1, 0.5]

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
	print, 'ERROR: There are no more future passes found.  Run minxss_spacecraft_pass.pro ASAP !!!!!'
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
	if (!d.x_size ne wxsize) or (!d.y_size ne wysize) then begin
		;   Write Static Stuff
		
		wxsize = !d.x_size & wysize = !d.y_size
		if (!d.x_size lt wxmin) then wxsize = wxmin
		if (!d.y_size lt wymin) then wysize = wymin
		window, 0, xsize=1904, ysize=480, xpos = -1920, ypos = (1050 - wysize - 40), title=wtitle
		erase
		plot, [0,1], [0,1], /nodata, yr=[0,1], ys=1+4, xr=[0,1], xs=1+4, xmargin=[0,0], ymargin=[0,0], $
			font=1, background=rgb2long(!color.black), color=rgb2long(!color.white)
		if keyword_set(debug) then begin
			print, 'Pass Index = ', ipass
			print, 'New Window Size = ', wxsize, ' x ', wysize
		endif
		xyouts, xaos, yy[0], 'AOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xlos, yy[0], 'LOS Time', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
		xyouts, xsun, yy[0], 'Orbit Phase', charsize=csize[0], charthick=cthick[0], color=ccolor[0], align=0.5
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
				yyout -= 0.1
				xyouts, xlos, yy[ii]+0.1, 'Next Pass', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[ii], align=0.5
				xyouts, xlos, yyout-0.1, 'Future Passes', charsize=csize[ii], charthick=cthick[ii], $
						color=ccolor[0], align=0.5
			endif
			xyouts, xlos, yyout, los_time, charsize=csize[ii], charthick=cthick[ii], $
					color=ccolor[ii], align=0.5
			if (passes[j].sunlight eq 0) then phase = 'Eclipse' $
			else if (passes[j].sunlight eq 1) then phase = 'Sunlight' else phase = 'Extra Pass'
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
		xyouts, xtime, yy[1]-0.18, '  to LOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_pass, align=0
	endif else begin
		xyouts, xtime, yy[1], hhmmss, charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
		xyouts, xtime, yy[1]-0.18, '  to AOS', charsize=csize[1]*cfactor, charthick=cthick[1]*tfactor, $
				color=color_wait, align=0
	endelse
	;  also print system time in UTC
	caldat, stime, year, month, day, hour, minutes, seconds
	hhmmss = string(hour,format='(I02)')+':'+string(minutes,format='(I02)')+$
			':'+string(seconds,format='(I02)')
	xyouts, xtime, yy[0], 'Current UTC '+hhmmss, charsize=csize[0], charthick=cthick[0], $
			color=ccolor[0], align=0
	; pulse MinXSS Logo if in pass
	if (logo_ok ne 0) then begin
		if (waiting_for_pass ne 0) then begin
			tv,logo_img1,0.7,0.07,/data,true=1
		endif else begin
			if logo_pulse then tv,logo_img2,0.7,0.07,/data,true=1 $
			else tv,logo_img1,0.7,0.07,/data,true=1
			logo_pulse = not logo_pulse
		endelse
	endif

endif else begin
	; index moved forward to last pass has finished
	pass_completed = 1
endelse

;
;	3.  Repeat Step 2 until Pass is complete, then goto Step 1
;		Wait one second before doing next step
;
wait, 1
if pass_completed ne 0 then begin
	if keyword_set(verbose) then print, 'PASS Completed. Looking for next pass...'
	goto, RESTART_NEW_PASS
endif
goto, KEEP_PLOTTING

if keyword_set(debug) then stop, 'DEBUG at end of minxss_pass_timer...'
return
end
