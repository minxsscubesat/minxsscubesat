;
; plot_satellite_track.pro
;
; Purpose:  Plot satellite track for specified Satellite ID and over limited time range
;
; INPUTS
;   sat_id		Satellite ID
;	time		Julian Date time values
;				jd_time = JULDAY(Month, Day, Year, Hour, Minute, Second)
;	/label_time	Label time every 10 minutes along orbit track
;   /verbose
;
; OUTPUT
;   Plot is made of Earth with ground track over-plotted
;
; History
;   1/12/2019 Tom Woods   Original for MinXSS-2 orbit analysis
;
PRO plot_satellite_track, sat_id, time, label_time=label_time, verbose = verbose

if n_params() lt 2 then begin
	print, 'USAGE: plot_satellite_track, sat_id, time_jd, /verbose
	return
endif

; always make verbose
; verbose = 1

;
;	Get S/C location based on satellite ID and time in Julian Date
;		location[0,*] = longtitude in degrees (-180 to 180 range)
;		location[1,*] = latitude in degrees (-90 to 90 range)
;		location[2,*] = altitude in km (from center of Earth)
;
spacecraft_location, id_satellite=sat_id, time, location, sunlight, /J2000, verbose=verbose

earth_radius = 6371.  ; km
altitude = reform(location[2,*]) - earth_radius
if keyword_set(verbose) then begin
	print, 'Orbit Altitude range is ', min(altitude), ' to ', max(altitude), ' km'
endif

;
;	Plot continents
;
setplot
cc=rainbow(7)
cs=1.5

;  MAP_SET, /PROJECTION_TYPE, Latitude, Longitude, Rotation_angle
MAP_SET, /MERCATOR, 0, 0, 0, $
	/CONTINENTS, E_CONTINENTS={FILL:1, COLOR:cc[3]}, $
   /GRID, E_GRID={LABEL:1, COLOR:cc[1]} ;  COLOR=cc[0]

;
;	Over-plot satellite Location
;		MAP_SET sets !X and !Y CRANGE as 0 to 1
;		OPLOT needs to be Longitude and Latitude values
;
oplot, reform(location[0,*]), reform(location[1,*]), color=cc[0]

if keyword_set(label_time) then begin
	; label every 10 minutes
	tstep = 10. /24./60.  ; convert 10 minutes to fraction of day
	tstart = time[0]
	;  round tstart to next minute
	caldat, tstart, month, day, year, hour, minute, second
	tstart = julday( month, day, year, hour, minute+1, 0 )
	tend = time[-1]
	;  round tend to previous minute
	caldat, tend, month, day, year, hour, minute, second
	tend = julday( month, day, year, hour, minute, 0 )
	tnum = long((tend-tstart)/tstep)+1
	if (tnum ge 2) then begin
		tarray = tstart + findgen(tnum)*tstep
		xx = interpol( reform(location[0,*]), time, tarray )
		yy = interpol( reform(location[1,*]), time, tarray )
		for ii=0L,tnum-1 do begin
			caldat, tarray[ii], month, day, year, hour, minute, second
			tname = string(hour,format='(I02)') + ':' + string(minute,format='(I02)')
			if (abs(yy[ii]) lt 80) then xyouts, xx[ii], yy[ii], tname, charsize=cs, align=0.5
		endfor
	endif
endif

if keyword_set(verbose) then stop, 'DEBUG plot_satellite_track...'

END
