;
;	minxss_level0c_validate_netcdf.pro
;
;	Validate the MinXSS-1 Level 0C NetCDF file
;	Tom Woods
;	March 2020
;
;	$ minxss_idl
;	$ idl
;   IDL> .run minxss_level0C_validate_netcdf.pro
;
;	Displays MetaData and Min-Max of each variable
;

minxss_data_dir = getenv('minxss_data')
if strlen(minxss_data_dir) lt 20 then begin
	minxss_data_dir = '/Users/twoods/Dropbox/minxss_dropbox/data'
endif
level_num = 'C'
filenetcdf = minxss_data_dir + '/fm1/level0c/minxss1_solarSXR_level0C_2016-05-16-mission_V002.ncdf'

print, ' '
print, 'Displaying Data for Level 0C'
print, ' '

;  Read File if needs fresh read
if (size(m0c,/type) ne 8) then begin
	last_level = level_num
	print, 'Reading '+filenetcdf+'... (please wait about a minute)'
	read_netcdf, filenetcdf, m0c, m0c_attr, m0status

	print, 'NetCDF Read Status (should be 0) = ', m0status
	if (m0status ne 0) then stop, 'STOPPED TO DEBUG:  NetCDF Read Error'
endif

ans = ' '
read, 'Size your terminal window to be at least 262 characters wide then hit RETURN key: ', ans

print, ' '
help, m0c,/str
print, ' '

;	Examine the Min-Median-Max values of each variable in HK
ntags = n_tags(m0c.hk)
name_tags = tag_names(m0c.hk)
print, ' '
print, '***************************   HK Structure Variables    ***************************'
print, '***** Number of HK Packets = ',n_elements(m0c.hk.time)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m0c.hk.(k)),median(m0c.hk.(k)),max(m0c.hk.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY HK Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in SCI
ntags = n_tags(m0c.sci)
name_tags = tag_names(m0c.sci)
print, ' '
print, '***************************   SCI Structure Variables    ***************************'
print, '***** Number of SCI Packets = ',n_elements(m0c.sci.time)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do print,k,strmid(name_tags[k],0,40),min(m0c.sci.(k)),median(m0c.sci.(k)),max(m0c.sci.(k)),format='(I5,A42,3E14.3)'

stop, 'STOPPED TO VERIFY SCI Structure Variables (enter .C to continue)'

;	Examine the Min-Median-Max values of each variable in LOG
ntags = n_tags(m0c.log)
name_tags = tag_names(m0c.log)
print, ' '
print, '***************************   LOG Structure Variables    ***************************'
print, '***** Number of LOG Packets = ',n_elements(m0c.log.time)
print, ' Index                        Tag_Name              Min_Value  Median_Value     Max_Value'
for k=0,ntags-1 do begin
  if (name_tags[k] ne 'MESSAGE') then begin
     print,k,strmid(name_tags[k],0,40),min(m0c.log.(k)),median(m0c.log.(k)),max(m0c.log.(k)), $
  			format='(I5,A42,3E14.3)'
  endif else begin
      print,k,strmid(name_tags[k],0,40),0,0,0, $
  			format='(I5,A42,3E14.3)'
  endelse
endfor

stop, 'STOPPED TO VERIFY LOG Structure Variables (enter .C to continue)'

;  View the Meta Data / NetCDF Attributes
n_attr = n_elements( m0c_attr )
print, ' '
print, '***************************   META DATA (ATTRIBUTES)    ***************************'
for k=0,n_attr-1 do begin
	print,k,' ',m0c_attr[k],format='(I4,A2,A)'
	if (k gt 0) and ((k mod 50) eq 0) then stop, 'STOPPED to VERIFY 50 MetaData lines, Enter .C to continue.'
endfor

stop, 'STOPPED TO VERIFY META DATA (Attributes in NetCDF file). Enter .C to continue.'

print, ' '
print, 'DONE WITH SIMPLE VALIDATION CHECKS OF MINXSS-1 LEVEL 0C DATA'

;  Do PLOTS to check data quality    +++++ TO DO

end
