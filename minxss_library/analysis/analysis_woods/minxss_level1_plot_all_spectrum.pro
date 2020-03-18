;
;	minxss_level1_plot_all_spectra.pro
;
;	;	$ minxss_idl
;	$ idl
;   IDL> .run minxss_level1_plot_all_spectra.pro
;
;	T. Woods,  3/11/2020
;

;  Read MinXSS-1 Level 1 merged data File
if (size(m1,/type) ne 8) then begin
	file1netcdf = '/Users/twoods/Dropbox/minxss_dropbox/data/fm1/level1/minxss1_solarSXR_level1_2016-05-16-mission_V002.ncdf'
	print, 'Reading '+file1netcdf+'... (please wait about a minute)'
	read_netcdf, file1netcdf, m1, m1attr, m1status

	print, 'NetCDF Read Status (should be 0) = ', m1status
	if (m1status ne 0) then stop, 'STOPPED TO DEBUG:  NetCDF Read Error'
endif

setplot
cc=rainbow(256)

;  87-sec plot sequence over MinXSS-1 mission
plot,m1.x123.energy[*,0],m1.x123.irradiance[*,0],xr=[0.5,10],xs=1,yr=[1E4,1E10],ys=1,/ylog
for k=0,numx123-1 do begin & oplot, m1.x123.energy[*,k],m1.x123.irradiance[*,k],color=cc[k mod 255] & wait, 0.01 & endfor

end
