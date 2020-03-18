;
;	minxss_level1_validate_netcdf.pro
;
;	Validate the MinXSS-1 Level 1 NetCDF file
;	Tom Woods
;	Aug 2019
;
;	$ minxss_idl
;	$ idl
;   IDL> .run minxss_level1_validate_netcdf.pro
;
;	Displays MetaData and Min-Max of each variable
;

;  Read File
if (size(m1,/type) ne 8) then begin
	file1netcdf = '/Users/twoods/Dropbox/minxss_dropbox/data/fm1/level1/minxss1_solarSXR_level1_2016-05-16-mission_V002.ncdf'
	print, 'Reading '+file1netcdf+'... (please wait about a minute)'
	read_netcdf, file1netcdf, m1, m1attr, m1status

	print, 'NetCDF Read Status (should be 0) = ', m1status
	if (m1status ne 0) then stop, 'STOPPED TO DEBUG:  NetCDF Read Error'
endif

ans = ' '
read, 'Size your terminal window to be at least 262 characters wide then hit RETURN key: ', ans

;  View the Meta Data / NetCDF Attributes
n_attr = n_elements( m1attr )
print, ' '
print, '***************************   META DATA (ATTRIBUTES)    ***************************'
for k=0,n_attr-1 do begin
	print,k,' ',m1attr[k],format='(I4,A2,A)'
	if (k gt 0) and ((k mod 100) eq 0) then stop, 'STOPPED to VERIFY 100 MetaData lines, Enter .C to continue.'
endfor

stop, 'STOPPED TO VERIFY META DATA (Attributes in NetCDF file). Enter .C to continue.'

print, ' '
help, m1,/str
print, ' '

;	Examine the Min-Median-Max values of each variable in X123
ntags = n_tags(m1.x123)
name_tags = tag_names(m1.x123)
print, ' '
print, '***************************   X123 Structure Variables    ***************************'
print, '***** Number of Spectra = ',n_elements(m1.x123.flight_model)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.x123.(k)),median(m1.x123.(k)),max(m1.x123.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY X123 Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in X123_TIME
ntags = n_tags(m1.x123_time)
name_tags = tag_names(m1.x123_time)
print, ' '
print, '***************************   X123_TIME Structure Variables    ***************************'
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.x123_time.(k)),median(m1.x123_time.(k)),max(m1.x123_time.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY X123_TIME Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in X123_DARK
ntags = n_tags(m1.x123_dark)
name_tags = tag_names(m1.x123_dark)
print, ' '
print, '***************************   X123_DARK Structure Variables    ***************************'
print, '***** Number of Spectra = ',n_elements(m1.x123_dark.flight_model)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.x123_dark.(k)),median(m1.x123_dark.(k)),max(m1.x123_dark.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY X123_DARK Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in X123_DARK_TIME
ntags = n_tags(m1.x123_dark_time)
name_tags = tag_names(m1.x123_dark_time)
print, ' '
print, '***************************   X123_DARK_TIME Structure Variables    ***************************'
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.x123_dark_time.(k)),median(m1.x123_dark_time.(k)),max(m1.x123_dark_time.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY X123_DARK_TIME Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in XP
ntags = n_tags(m1.xp)
name_tags = tag_names(m1.xp)
print, ' '
print, '***************************   XP Structure Variables    ***************************'
print, '***** Number of Measurements = ',n_elements(m1.xp.flight_model)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.xp.(k)),median(m1.xp.(k)),max(m1.xp.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY XP Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in XP_TIME
ntags = n_tags(m1.xp_time)
name_tags = tag_names(m1.xp_time)
print, ' '
print, '***************************   XP_TIME Structure Variables    ***************************'
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.xp_time.(k)),median(m1.xp_time.(k)),max(m1.xp_time.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY XP_TIME Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in XP_DARK
ntags = n_tags(m1.xp_dark)
name_tags = tag_names(m1.xp_dark)
print, ' '
print, '***************************   XP_DARK Structure Variables    ***************************'
print, '***** Number of Measurements = ',n_elements(m1.xp_dark.flight_model)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.xp_dark.(k)),median(m1.xp_dark.(k)),max(m1.xp_dark.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY XP_DARK Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in XP_DARK_TIME
ntags = n_tags(m1.xp_dark_time)
name_tags = tag_names(m1.xp_dark_time)
print, ' '
print, '***************************   XP_DARK_TIME Structure Variables    ***************************'
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m1.xp_dark_time.(k)),median(m1.xp_dark_time.(k)),max(m1.xp_dark_time.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY XP_DARK_TIME Structure Variables (enter .C to continue)'

print, ' '
print, 'DONE WITH SIMPLE VALIDATION CHECKS OF MINXSS-1 LEVEL 1 DATA'

;  Do PLOTS to check data quality    +++++ TO DO

end
