;
;  minxss_fresh_orbit_number.pro
;  
;  Update minxss_orbit_number.dat with all new orbit number entries.
;  This is useful if this file gets corrupted
;  
;  .run minxss_fresh_orbit_number
;
;   Tom Woods   1/4/2017
;
;
;  Spacecraft defines for MinXSS-1
satid = 41474L   ; MinXSS-1
gs_long_lat = [ -105.2705D0, 40.0150D0 ]  ; Boulder Longitude (West=negative), Latitude in degrees
path_name = getenv('TLE_dir') + '\'

date1 = ymd2jd(2016,5,16)
date2 = long(systime(/julian)) + 0.5D0
date_step = 20.
kmax = long(((date2 - date1) / date_step) + 0.99)
print, ' '
print, 'Processing orbit number for MinXSS-1 in ', strtrim(kmax,2), ' loops ...'
for k=0L,kmax do begin
  date_range = [ date1 + k*date_step - 1., date1 + (k+1)*date_step ]
  if (date_range[1] gt date2) then date_range[1] = date2
  if (date_range[0] lt date2) then begin
    print, '    ', k+1, jd2yd(date_range[0]), ' - ', jd2yd(date_range[1])
    spacecraft_pass, date_range, passes, number_passes, id_satellite=satid, $
            ground_station=gs_long_lat, tle_path=path_name, /verbose, sc_location=location
    spacecraft_orbit_number,  location, 'minxss', data=orbit_num, /verbose
  endif
endfor
print, ' '
print, 'Completed - review the new minxss_orbit_number.dat file.'

on = read_dat( path_name + '\orbit_number\' + 'minxss_orbit_number.dat' )
yron = yd_to_yfrac( reform( on[1,*] + on[2,*] / (24.D0*3600.) ) )

end
