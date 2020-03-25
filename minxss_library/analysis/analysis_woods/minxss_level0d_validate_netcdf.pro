;
;	minxss_level0d_validate_netcdf.pro
;
;	Validate the MinXSS-1 Level 0D NetCDF file
;	Tom Woods
;	March 2020
;
;	$ minxss_idl
;	$ idl
;   IDL> .run minxss_level0D_validate_netcdf.pro
;
;	Displays MetaData and Min-Max of each variable
;


minxss_data_dir = getenv('minxss_data')
if strlen(minxss_data_dir) lt 20 then begin
	minxss_data_dir = '/Users/twoods/Dropbox/minxss_dropbox/data'
endif
level_num = 'D'
filenetcdf = minxss_data_dir + '/fm1/level0d/minxss1_solarSXR_level0D_2016-05-16-mission_V002.ncdf'
print, ' '
print, 'Displaying Data for Level 0D'
print, ' '

;  Read File if needs fresh read
if (size(m0d,/type) ne 8) then begin
	last_level = level_num
	print, 'Reading '+filenetcdf+'... (please wait about a minute)'
	read_netcdf, filenetcdf, m0d, m0d_attr, m0status

	print, 'NetCDF Read Status (should be 0) = ', m0status
	if (m0status ne 0) then stop, 'STOPPED TO DEBUG:  NetCDF Read Error'
endif

ans = ' '
read, 'Size your terminal window to be at least 262 characters wide then hit RETURN key: ', ans

print, ' '
help, m0d,/str
print, ' '

;	Examine the Min-Median-Max values of each variable in m0d
ntags = n_tags(m0d)
name_tags = tag_names(m0d)
print, ' '
print, '***************************   Level 0D Structure Variables    ***************************'
print, '***** Number of Spectra = ',n_elements(m0d.flight_model)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do begin
  if (name_tags[k] ne 'TIME') then begin
    print,k,strmid(name_tags[k],0,40),min(m0d.(k)),median(m0d.(k)),max(m0d.(k)), $
    	format='(I5,A42,3E14.3)'
  endif
endfor

stop, 'STOPPED TO VERIFY Level 0D Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in m0d.time
ntags = n_tags(m0d.time)
name_tags = tag_names(m0d.time)
print, ' '
print, '***************************   Level 0D TIME Structure Variables    ***************************'
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do begin
    print,k,strmid(name_tags[k],0,40),min(m0d.time.(k)),median(m0d.time.(k)),max(m0d.time.(k)), $
    	format='(I5,A42,3E14.3)'
endfor

stop, 'STOPPED TO VERIFY Level 0D TIME Structure Variables (enter .C to continue)'

;  View the Meta Data / NetCDF Attributes
n_attr = n_elements( m0d_attr )
print, ' '
print, '***************************   META DATA (ATTRIBUTES)    ***************************'
for k=0,n_attr-1 do begin
	print,k,' ',m0d_attr[k],format='(I4,A2,A)'
	if (k gt 0) and ((k mod 50) eq 0) then stop, 'STOPPED to VERIFY 50 MetaData lines, Enter .C to continue.'
endfor

stop, 'STOPPED TO VERIFY META DATA (Attributes in NetCDF file). Enter .C to continue.'

print, ' '
print, 'DONE WITH SIMPLE VALIDATION CHECKS OF MINXSS-1 LEVEL 0D DATA'

;  Do PLOTS to check data quality    +++++ TO DO

end
