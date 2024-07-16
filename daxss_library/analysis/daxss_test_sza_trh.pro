;
;	daxss_test_sza_trh.pro
;
;	Test the DAXSS Level 0D code for Solar Zenith Angle and Tangent Ray Height
;	There seems to be different answers from different computers.  T. Woods  1/20/2023
;	Are different codes being used ???
;
;	USAGE:
;		IDL>  .run  daxss_test_sza_trh.pro
;

;  read DAXSS Level 0D data
if n_elements(dxdata) lt 2 then begin
	daxss_dir = getenv('minxss_data') + '/fm3/level0d/'
	daxss0d_file = 'daxss_l0d_mission_length_v2.0.0.sav'
	print, '*****  READING ' + daxss_dir + daxss0d_file
	restore, daxss_dir + daxss0d_file

	;  Isolate Day 2022/114
	wkeep = where(long(daxss_level0d.time_yd) eq 2022114L, num_keep )
	print, '*****  KEEPING data on 2022/114: ' + strtrim(num_keep,2) + ' data points.'
	dxdata = daxss_level0d[wkeep]
	daxss_level0d = 0L
endif

;   Configure HOUR of day variable
hour = (dxdata.time_yd - 2022114.D0)*24.

;	Call Level 0D code for SZA and TRH

; Get sun angle and distance
sunVector = sunvec(jd = dxdata.time_jd, r = earth_sun_distance, alpha = right_ascension, delta = declination)
; daxss_level0d.earth_sun_distance = earth_sun_distance ; [AU]
; daxss_level0d.sun_right_ascension = right_ascension   ; [º]
; daxss_level0d.sun_declination = declination           ; [º]

; Added  solar_zenith_angle  and  tangent_ray_height  for Version 2.1
solar_zenith_altitude, dxdata.time_yd, dxdata.longitude, $
				dxdata.latitude, dxdata.altitude, sza, trh, $
				trh_longitude, trh_latitude
; daxss_level0d.solar_zenith_angle = sza
; daxss_level0d.tangent_ray_height = trh

; Added sun angles and tangent ray height location information for Version 2.2
; daxss_level0d.trh_longitude = trh_longitude
; daxss_level0d.trh_latitude = trh_latitude

;;;  COMPARE these results to daxss_level0d results
print, ' '
print, '***** COMPARE dxdata values and these results for right_ascension, declination, sza, trh'
print, ' '

!p.multi=[0,1,2]
setplot & cc=rainbow(7) & ans=' '
xmargin=[7,1] & xrange=[0,24]
ymargin1=[2,0.5] & ymargin2=[3,0.5]

plot, hour, dxdata.sun_right_ascension, psym=-4, xrange=xrange, xs=1, ytitle='sun_right_ascension',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, right_ascension, psym=-5, color=cc[3]
plot, hour, dxdata.sun_right_ascension - right_ascension, psym=-4, ytitle='DIFF (L0D-New)', $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
read, 'Next Plot ? ', ans

plot, hour, dxdata.sun_declination, psym=-4, xrange=xrange, xs=1, ytitle='sun_declination',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, declination, psym=-5, color=cc[3]
plot, hour, dxdata.sun_declination - declination, psym=-4, ytitle='DIFF (L0D-New)', $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
read, 'Next Plot ? ', ans

plot, hour, dxdata.solar_zenith_angle, psym=-4, xrange=xrange, xs=1, ytitle='solar_zenith_angle',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, sza, psym=-5, color=cc[3]
plot, hour, dxdata.solar_zenith_angle - sza, psym=-4, ytitle='DIFF (L0D-New)', $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
read, 'Next Plot ? ', ans

plot, hour, dxdata.tangent_ray_height, psym=-4, xrange=xrange, xs=1, ytitle='tangent_ray_height',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, trh, psym=-5, color=cc[3]
diff = dxdata.tangent_ray_height - trh
yrange2=[min(diff), max(diff)]
if (yrange2[0] eq 0.0) then yrange2[0] = -0.01
if (yrange2[1] eq 0.0) then yrange2[1] =  0.01
plot, hour, diff, psym=-4, ytitle='DIFF (L0D-New)', yrange=yrange2, $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
read, 'Next Plot ? ', ans

plot, hour, dxdata.trh_longitude, psym=-4, xrange=xrange, xs=1, ytitle='trh_longitude',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, trh_longitude, psym=-5, color=cc[3]
diff = dxdata.trh_longitude - trh_longitude
yrange2=[min(diff), max(diff)]
if (yrange2[0] eq 0.0) then yrange2[0] = -0.01
if (yrange2[1] eq 0.0) then yrange2[1] =  0.01
plot, hour, diff, psym=-4, ytitle='DIFF (L0D-New)', yrange=yrange2, $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
read, 'Next Plot ? ', ans

plot, hour, dxdata.trh_latitude, psym=-4, xrange=xrange, xs=1, ytitle='trh_latitude',  $
		xtitle=' ', ys=1, title=' ', xmargin=xmargin, ymargin=ymargin1
oplot, hour, trh_latitude, psym=-5, color=cc[3]
diff2 = dxdata.trh_latitude - trh_latitude
yrange2=[min(diff2), max(diff2)]
if (yrange2[0] eq 0.0) then yrange2[0] = -0.01
if (yrange2[1] eq 0.0) then yrange2[1] =  0.01
plot, hour, diff2, psym=-4, ytitle='DIFF (L0D-New)', yrange=yrange2, $
	xrange=xrange, xs=1, xtitle='Hour of 2022/114', ys=1, xmargin=xmargin, ymargin=ymargin2
; read, 'Next Plot ? ', ans

!p.multi=0

end

