;+
; NAME:
;	write_netCDF.pro
;
; PURPOSE:
;	Write netCDF file given a structure variable
;
; CATEGORY:
;	All levels of processing
;
; CALLING SEQUENCE:  
;	write_netCDF, data, filename, status, path=dir_path, $
;	  att_file=att_filename, ver=dp_ver, dp_rev=dp_rev, $
;     calver=calver, softver=softver, /clobber
;
; INPUTS:
;	data = structure variable of input data
;	filename = filename for new netCDF file
;	path = optional directory path for the attributes definition file
;	att_file = optional filename for the attributes definition file
;	clobber = optional option for creating netCDF file
;			clobber means any old file will be destroyed
;
;	An external *.att file is used to define attributes (where * =
;	"data" structure name)
;
; OUTPUTS:  
;	status = result status: 0 = OK_STATUS, -1 = BAD_PARAMS, -2 = BAD_FILE,
;			-3 = BAD_FILE_DATA, -4 = FILE_ALREADY_OPENED
;
;	A netCDF file is created and written.
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	Check for valid input parameters
;	Open the netCDF file
;	Use the structure's tag names for defining the variable names in the netCDF.
;	Use the structure name and optional 'path' variable for the Attributes filename
;		OR use the optional 'att_file' parameter for this filename
;	If this Attributes definition file exists, then transfer those attributes into the netCDF file
;		OR else don't write any attributes to the netCDF file.
;	Once netCDF variables and attributes are defined, then write the structure's data to netCDF file
;	Close the netCDF file
;
;	NetCDF IDL Procedures / Process:
;	1. NCDF_CREATE: Call this procedure to begin creating a new file. The new file is put into define mode.
;	2. NCDF_DIMDEF: Create dimensions for the file.
; 	3. NCDF_VARDEF: Define the variables to be used in the file.
;	4. NCDF_ATTPUT: Optionally, use attributes to describe the data.  Global attributes also allowed.
;	4. NCDF_CONTROL, /ENDEF: Leave define mode and enter data mode.
;	5. NCDF_VARPUT: Write the appropriate data to the netCDF file.
;	6. NCDF_CLOSE: Close the file.
;
; MODIFICATION HISTORY:
;	9/20/99		Tom Woods		Original release code, Version 1.00
;	7/09/01		Don Woodraska	Added ver,softver,calver keywords.
;	11/19/01	Don Woodraska	Changed ver to dp_ver(001). Added dp_rev (01).
;	10/08/02	Don Woodraska	Added form_ver (001).
;       05/19/16        Don Woodraska   Allow full colons in variables for attributes (like timestamps)
;       05/20/16        Don Woodraska   Bug fix to allow 1-element arrays
;       06/12/17        Don Woodraska   Removing 1-element arrays (still experimental)
;
; $Log: write_netcdf.pro,v $
; Revision 10.3  2016/05/20 16:47:08  see_sw
; bug fix to allow 1-element arrays
;
; Revision 10.2  2016/05/19 16:36:36  see_sw
; one-line change to allow timestamps in variables
;
; Revision 10.1  2013/11/11 16:59:58  see_sw
; update
;
; Revision 10.0  2007/05/08 19:04:01  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:26:37  see_sw
; commit of version 9.0
;
; Revision 8.0  2004/07/20 20:18:35  turkk
; commit of version 8.0
;
; Revision 7.0  2004/07/08 23:03:01  turkk
; commit of version 7.0
;
; Revision 6.0  2003/03/05 19:32:41  dlwoodra
; version 6 commit
;
; Revision 6.1  2002/11/04 16:49:39  dlwoodra
; added form_ver keyword
;
; Revision 6.0  2002/09/12 15:32:29  dlwoodra
; update to 6.0
;
; Revision 5.1  2002/09/12 15:02:44  dlwoodra
; update from main
;
; Revision 5.20  2002/09/06 23:21:36  see_sw
; commit of version 5.0
;
; Revision 4.0  2002/05/29 18:10:02  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:29  see_sw
; version_3.0_commit
;
; Revision 1.3  2001/11/30 20:19:12  dlwoodra
; added dp_rev keyword
;
; Revision 1.2  2001/07/09 23:22:02  dlwoodra
; added 3 variables that can be used in attributes files, REV, SOFTVER, CALVER.
;
; Revision 1.1.1.1  2000/11/21 21:49:17  dlwoodra
; SEE Code Library Import
;
;
;idver='$Id: write_netcdf.pro,v 10.3 2016/05/20 16:47:08 see_sw Exp $'
;
;-

pro write_netCDF, data, filename, status, path=path, att_file=att_file, $
                  clobber=clobber, ver=dp_ver, dp_rev=dp_rev, $
                  softver=softver, calver=calver, formver=formver

;
;	Generic "status" values
;
OK_STATUS = 0
BAD_PARAMS = -1
BAD_FILE = -2
BAD_FILE_DATA = -3
FILE_ALREADY_OPENED = -4

debug_mode = 0		; set to >= 1 if want to debug this procedure
					; set to 2 if want to debug and force directory to special Woods Mac directory

;
;	check for valid parameters
;
status = BAD_PARAMS
if (n_params(0) lt 1) then begin
	print, 'USAGE: write_netCDF, data, filename, status, path=dir_path, att_file=att_filename, ver=dp_ver, dp_rev=dp_rev, softver=softver, calver=calver, /clobber'
	return
endif
dsize = size(data)
if (dsize[0] ne 1) or (dsize[2] ne 8) then begin
	print, 'ERROR: write_netCDF requires the data to be a structure array'
	return
endif
if (n_params(0) lt 2) then begin
	filename = ''
	read, 'Enter filename for the new netCDF file : ', filename
	if (strlen(filename) lt 1) then return
endif
dir_path = ''
att_filename = tag_names( data, /structure_name ) + '.att'
if keyword_set(path) then dir_path = path
if keyword_set(att_file) then att_filename = att_file
att_filename = dir_path + att_filename
if keyword_set(dp_ver) then dp_version=dp_ver else dp_version='001'
if keyword_set(dp_rev) then dp_revision=dp_rev else dp_revision='01'
if keyword_set(softver) then soft_ver=softver else soft_ver='01.01'
if keyword_set(calver) then cal_ver=calver else cal_ver='01.01'
if keyword_set(formver) then form_ver=formver else form_ver='001'

;
;	Do initial survery of variables and nested structures
;	to verify limitation on dimensions of arrays and nested structures
;	
;	LIMITATIONS:  4 dimensions on arrays and 4 nested structures
;
;	Use internal name structure for tracking any nested structures
;
temp_def = { name : ' ', isVar : 0B, tag_index : 0L, var_size : lonarr(10), nest_level : 0, $
	struct_index : lonarr(4), dim_index : lonarr(16), var_ptr : ptr_new() }
var_def = temp_def

;
;	define first structure entry into "var_def" for the "data" structure
;
var_def[0].name = tag_names( data, /structure_name )
var_def[0].isVar = 0
var_def[0].tag_index = 0
var_def[0].var_size = size( data )
var_def[0].nest_level = 0
temp_index = lonarr(4)
var_def[0].struct_index = temp_index
temp_dim = lonarr(16) - 1
var_def[0].dim_index = temp_dim
var_def[0].var_ptr = ptr_new(data[0])

next_var = 1
level_index = lonarr(5)
level_index[0] = 1
extra_var = n_tags( data )
nest_level = 0

while (extra_var gt 0) and (nest_level le 4) do begin
	;
	; each level of nested structures are appended to var_def
	;
	var_def = [ var_def, replicate( temp_def, extra_var ) ]
	if (nest_level gt 0) then j_start = level_index[nest_level-1] else j_start = 0
	j_end = level_index[nest_level] - 1
	extra_var = 0	
	for j=j_start, j_end do begin
		;
		; only process structure definitions
		;
		if ( var_def[j].isVar eq 0 ) then begin
			theData = *(var_def[j].var_ptr)
			tnames = tag_names( theData ) 
			temp_index = var_def[j].struct_index
			k_total = n_tags( theData ) - 1
			for k= 0, k_total do begin
				theVar = theData[0].(k)
				theName = ''
				nn = var_def[j].nest_level
				if ( nn gt 0 ) then begin
					theName = var_def[ var_def[j].struct_index[nn-1] ].name + '.'
				endif
				theName = theName + tnames[k]
				var_def[next_var].name = theName
				var_def[next_var].isVar = 1
				var_def[next_var].tag_index = k
				var_def[next_var].nest_level = nest_level
				var_def[next_var].struct_index = temp_index
				var_def[next_var].dim_index = temp_dim
				tempsize = size( theVar ) ; number of dims, dimension lengths,... datatype, numberofelements
                                ; scalars have 0 dimensions
                                ; arrays have 1 or more dimensions
				if (tempsize[0] gt 4) then begin
					print, 'ERROR:  write_netCDF  has a limitation of 4 dimensions for its variables'
					print, 'ABORTING....'
					; NCDF_CONTROL, fid, /ABORT
					return
				endif
				var_def[next_var].var_size = tempsize
				var_def[next_var].var_ptr = ptr_new( theVar )
				;
				;	if structure, then need to set it up special
				;
				if (tempsize[tempsize[0]+1] eq 8) then begin
					var_def[next_var].isVar = 0
					var_def[next_var].nest_level = nest_level + 1
					var_def[next_var].struct_index[nest_level] = next_var
					extra_var = extra_var + n_tags( theVar[0] )
				endif
				next_var = next_var + 1
			endfor
		endif
	endfor
	;
	;	get ready for next level of nested structures
	;
	nest_level = nest_level + 1
	level_index[nest_level] = next_var
endwhile

num_var = next_var		; the maximum number of variables for netCDF file (size of var_def)
if (num_var ne n_elements(var_def)) then begin
	print, 'WARNING: write_netCDF has error in pre-parsing for variable definitions'
endif

if (extra_var gt 0) then begin
	print, 'ERROR:  write_netCDF  has a limitation of 4 nested structures for its variables'
	print, 'ABORTING....'
	; NCDF_CONTROL, fid, /ABORT
	return
endif

if (debug_mode gt 0) then stop, 'Check out "var_def" structure results...'

;
;	Open the netCDF file - option to CLOBBER any existing file
;
status = BAD_FILE
if keyword_set(clobber) then fid = NCDF_CREATE( filename, /CLOBBER ) $
else fid = NCDF_CREATE( filename, /NOCLOBBER )
status = OK_STATUS

;
;	Define the netCDF dimensions
;	Use the size() function to make dimensions
;	Define the dimension of the structure itself as UNLIMITED (in case want to append to this file)
;
str_did = NCDF_DIMDEF( fid, 'string', 256 )		; fix string length to 256 characters
num_dim = 0

if (debug_mode gt 0) then begin
	print, ' '
	print, 'Number of structures / variables = ', num_var
	print, ' '
	print, 'Defining dimensions and variables...'
	print, '    Index   Dimensions   Data-Type   Name'
	print, '    -----   ----------   ---------   ----'
endif

for k=0,num_var-1 do begin
	var_size = var_def[k].var_size
	if (var_size[0] gt 0) then begin
                ; for 1d array of length 1, this is true
		for j=1,var_size[0] do begin
			if (var_size[j] gt 1) or (k eq 0) then begin
				if (k eq 0) and (j eq 1) then begin
					var_dim = NCDF_DIMDEF( fid, 'structure_elements', /UNLIMITED )
				endif else begin
					var_dim = NCDF_DIMDEF( fid, 'dim' + strtrim(j,2) + '_' + var_def[k].name, var_size[j] )
				endelse
				if (num_dim eq 0) then dim_id = replicate( var_dim, num_var * 16 )		; assume 4*4 max
				dim_id[num_dim] = var_dim
				var_def[k].dim_index[j-1] = num_dim
				num_dim = num_dim + 1
                        endif ;else begin
;                                ; this is the 1-element array case
;				var_dim = NCDF_DIMDEF( fid, 'dim' + strtrim(j,2) + '_' + var_def[k].name, var_size[j] )
;				if (num_dim eq 0) then dim_id = replicate( var_dim, num_var * 16 )		; assume 4*4 max
;				dim_id[num_dim] = var_dim
;				var_def[k].dim_index[j-1] = num_dim
;				num_dim = num_dim + 1
;                         endelse
		endfor
	endif
	;
	;	append dimension index for any structure dimensions
	;
	jnext = var_size[0]
	if (var_def[k].nest_level gt 0) and (var_def[k].isVar) then begin
		for j=1,var_def[k].nest_level do begin
			ii = 0
			jj = var_def[k].struct_index[j-1]
			while (ii lt 4) and (var_def[jj].dim_index[ii] ge 0) do begin
				var_def[k].dim_index[jnext] = var_def[jj].dim_index[ii]
				jnext = jnext + 1
				ii = ii + 1
			endwhile
		endfor
	endif
	;
	;	append the dimension for "data" structure array for each variable
	;	IF has common dimension
	;
	if (var_def[k].isVar) then var_def[k].dim_index[jnext] = var_def[0].dim_index[0]
endfor

; if (debug_mode gt 0) then stop, 'Check out the var_def.dim_index[]...'

;
;	Now define the netCDF variables
;	Use the structure's tag names for defining the variable names in the netCDF
;
first_var=0
for k=0,num_var-1 do begin
	;
	;  only process real variables (not structure definitions)
	;
	if (var_def[k].isVar ne 0) then begin
		var_size = var_def[k].var_size
		data_type = var_size[ var_size[0] + 1 ]
		if (debug_mode gt 0) then print, k, var_size[0], data_type, '   ', var_def[k].name
		;
		;	now make dimension array
		;
		ii = 0
		while (ii lt 16) and (var_def[k].dim_index[ii] ge 0) do begin
			if (ii eq 0) then the_dim = [ dim_id[ var_def[k].dim_index[ii] ] ] $
			else the_dim = [ the_dim, dim_id[ var_def[k].dim_index[ii] ] ]
			ii = ii + 1
		endwhile
		;
		;	now make variable in a big case statement now for different data type
		;
		case data_type of 
			1:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /BYTE )
			2:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /SHORT )
			3:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /LONG )
			4:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /FLOAT )
			5:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /DOUBLE )
			7:	var_defid = NCDF_VARDEF( fid, var_def[k].name, [str_did, the_dim], /CHAR )
			12:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /SHORT )
			13:	var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim, /LONG )
			else: begin
				print, 'WARNING: write_netCDF error in variable type, assuming float'
				var_defid = NCDF_VARDEF( fid, var_def[k].name, the_dim )		; assume it is /FLOAT ???
				end
		endcase
		if (first_var eq 0) then var_id = replicate( var_defid, num_var )
		first_var = 1
		var_id[k] = var_defid
	endif
endfor

if (debug_mode gt 0) then stop, 'Check out the "var_id"...'

;
;	Use the structure name and optional 'path' variable for the Attributes filename
;		OR use the optional 'att_file' parameter for this filename
;	If this Attributes definition file exists, then transfer those attributes into the netCDF file
;		OR else don't write any attributes to the netCDF file.
;
on_ioerror, bad_att_file
openr,alun, att_filename, /get_lun
cur_varid = -1		; GLOBAL default start
astr = ''
letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'

while not( eof(alun) ) do begin
	readf, alun, astr
	astr = strtrim(strcompress(astr),2)
	pos_let = strpos( letters, strmid(astr,0,1) )
	alen = strlen(astr)
	if ( alen gt 0 ) and (pos_let ge 0) then begin
		pos_colon = strpos( astr, ':' )
                ; 5/18/16 DLW allow full colons as long as they are not at the end of the line
                ; this is true only if the colon is the last char
                ; you still cannot have colons in attribute names
		if ( (pos_colon eq (strlen(astr)-1)) ) then begin
			;
			;	got a variable name (could be GLOBAL)
			;		find out which variable index if it exists
			;
			vname = strtrim(strmid(astr,0,pos_colon),2)
			if (strupcase(vname) eq 'GLOBAL') then begin
				cur_varid = -1
			endif else begin
				cur_varid = -1
				jj = 0
				test_vname = strupcase(vname)
				while ( jj lt num_var ) and (cur_varid lt 0) do begin
					if (test_vname eq strupcase(var_def[jj].name) ) then cur_varid = jj
					jj = jj + 1
				endwhile
				if (cur_varid lt 0) then begin
					message, /INFO, 'WARNING: variable NOT found for attribute ' +  test_vname
					if (debug_mode gt 0) then stop, 'Check out warning...'
				endif
			endelse
		endif else begin
			;
			;	check for attribute definition (name = text)
			;
			adef = str_sep( astr, "=" )
			n_adef = n_elements(adef)
			if (n_adef ge 2) then begin
				aname = strtrim( adef[0], 2 )
				atext = adef[1]
				jj = 2   ;  merge any other text together
				while (jj lt n_adef) do begin
					atext = atext + '=' + adef[jj]
					jj = jj + 1
				endwhile
				atext = strtrim( atext, 2 )
				;
				;	check for special substitutions:  $FILE, $DATE, $TIME
				;	also check for "$" at end of atext which means it needs to read another line
				;
				pos_dollar = strpos( atext, "$" )
				if ( pos_dollar ge 0 ) then begin
					alen = strlen(atext)
					while ( pos_dollar eq (alen-1) ) and not( eof(alun) ) do begin
						readf, alun, astr
						atext = atext + ' ' + strtrim( strcompress( astr ), 2 )
						alen = strlen(atext)
						pos_dollar = strpos( atext, "$" )
					endwhile
					up_atext = strupcase( atext )
					pos1 = strpos( up_atext, "$FILE" )
					if (pos1 ge 0) then begin
						newtext = strmid( atext, 0, pos1 ) + filename
						if ( pos1 lt (alen-5) ) then newtext = newtext + strmid( atext, pos1+5, alen-pos1-5 )
						atext = newtext
						alen = strlen(atext)
					endif
					pos1 = strpos( up_atext, "$DATE" )
					if (pos1 ge 0) then begin
						newtext = strmid( atext, 0, pos1 ) + systime()
						if ( pos1 lt (alen-5) ) then newtext = newtext + strmid( atext, pos1+5, alen-pos1-5 )
						atext = newtext
						alen = strlen(atext)
					endif
					pos1 = strpos( up_atext, "$TIME" )
					if (pos1 ge 0) then begin
						newtext = strmid( atext, 0, pos1 ) + systime()
						if ( pos1 lt (alen-5) ) then newtext = newtext + strmid( atext, pos1+5, alen-pos1-5 )
						atext = newtext
						alen = strlen(atext)
					endif
                    ;pos1 = strpos( up_atext, "$DP_VERSION" )
                    pos1 = strpos( up_atext, "$VERSION" )
                    if (pos1 ge 0) then begin
                        newtext = strmid( atext, 0, pos1 ) + DP_VERSION
                        atext = newtext
                        alen = strlen(atext)
                    endif
                    ;pos1 = strpos( up_atext, "$DP_REVISION" )
                    pos1 = strpos( up_atext, "$REVISION" )
                    if (pos1 ge 0) then begin
                        newtext = strmid( atext, 0, pos1 ) + DP_REVISION
                        atext = newtext
                        alen = strlen(atext)
                    endif
                    pos1 = strpos( up_atext, "$SOFT_VER" )
                    if (pos1 ge 0) then begin
                        newtext = strmid( atext, 0, pos1 ) + SOFT_VER
                        atext = newtext
                        alen = strlen(atext)
                    endif
                    pos1 = strpos( up_atext, "$CAL_VER" )
                    if (pos1 ge 0) then begin
                        newtext = strmid( atext, 0, pos1 ) + CAL_VER
                        atext = newtext
                        alen = strlen(atext)
                    endif
                    pos1 = strpos( up_atext, "$FORM_VER" )
                    if (pos1 ge 0) then begin
                        newtext = strmid( atext, 0, pos1 ) + FORM_VER
                        atext = newtext
                        alen = strlen(atext)
                    endif

				endif
				
				;
				;	now define attribute (either GLOBAL or as part of variable)
				;
				if ( cur_varid lt 0 ) then begin
					NCDF_ATTPUT, fid, /GLOBAL, aname, atext
				endif else begin
					NCDF_ATTPUT, fid, var_id[cur_varid], aname, atext
				endelse
			endif
		endelse
	endif
endwhile

close, alun
free_lun, alun
goto, end_att_file

bad_att_file:
	print, 'WARNING: write_netCDF could not find attributes file = ', att_filename

end_att_file:
	on_ioerror, NULL

;
;	Once netCDF variables and attributes are defined, then write the structure's data to netCDF file
;
NCDF_CONTROL, fid, /ENDEF
for k=0,num_var-1 do begin
	;
	;  only process real variables (not structure definitions)
	;
	if (var_def[k].isVar ne 0) then begin
		ti = var_def[k].struct_index
		k_ti = var_def[k].tag_index
		ti_0 = var_def[ti[0]].tag_index
		ti_1 = var_def[ti[1]].tag_index
		ti_2 = var_def[ti[2]].tag_index
		ti_3 = var_def[ti[3]].tag_index
		case  var_def[k].nest_level of
			0 :	theData = data.(k_ti)
			1 : theData = data.(ti_0).(k_ti)
			2 : theData = data.(ti_0).(ti_1).(k_ti)
			3 : theData = data.(ti_0).(ti_1).(ti_2).(k_ti)
			4 : theData = data.(ti_0).(ti_1).(ti_2).(ti_3).(k_ti)
		else : begin
			print, 'WARNING: write_netCDF has error in parsing data for writing'
			theData = 0.0
			end
		endcase
		NCDF_VARPUT, fid, var_id[k], theData
	endif
endfor

;
;	Close the netCDF file
;
NCDF_CLOSE, fid

;
;	clean up pointer heap before leaving
;
num_var_def = n_elements( var_def )
for k=0,num_var_def-1 do begin
	if ( ptr_valid( var_def[k].var_ptr ) ) then ptr_free, var_def[k].var_ptr
endfor

return
end
