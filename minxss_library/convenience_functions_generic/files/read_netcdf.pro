;+
; NAME:
;	read_netCDF.pro
;
; PURPOSE:
;	Read netCDF file into structure variable
;
; CATEGORY:
;	All levels of processing
;
; CALLING SEQUENCE:  
;	read_netCDF, filename, data, attributes, status
;
; INPUTS:
;	filename = filename for existing netCDF file
;
; OUTPUTS:  
;	data = structure variable for data read from netCDF file
;	attributes = array of strings of the attributes from the netCDF file
;	status = result status: 0 = OK_STATUS, -1 = BAD_PARAMS, -2 = BAD_FILE,
;			-3 = BAD_FILE_DATA, -4 = FILE_ALREADY_OPENED
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	Check for valid input parameters
;	Open the netCDF file
;	Create structures based on the netCDF definitions
;	Once structures are defined, then read the netCDF variables into the structure's data
;	Read the attributes into a string array
;	Close the netCDF file
;
;	NetCDF IDL Procedures / Process:
;	1.	NCDF_OPEN: Open an existing netCDF file.
;	2.	NCDF_INQUIRE: Call this function to find the format of the netCDF file.
;	3.	NCDF_DIMINQ: Retrieve the names and sizes of dimensions in the file.
;	4.	NCDF_VARINQ: Retrieve the names, types, and sizes of variables in the file.
;	5.	NCDF_ATTINQ: Optionally, retrieve the types and lengths of attributes.
;	6.	NCDF_ATTNAME: Optionally, retrieve attribute names.
;	7.	NCDF_ATTGET: Optionally, retrieve the attributes.
;	8.	NCDF_VARGET: Read the data from the variables.
;	9.	NCDF_CLOSE: Close the file.
;
; MODIFICATION HISTORY:
;	9/20/1999		Tom Woods		Original release of code, Version 1.00
;	12/3/1999		Tom Woods		Removed BYTE array conversion to STRING
;   05/23/2004  Don Woodraska  Prevents IDL reserved words by appending an
;                              underscore to tag names if necessary.
;
; $Log: read_netcdf.pro,v $
; Revision 10.1  2013/11/11 16:59:57  see_sw
; update
;
; Revision 10.0  2007/05/08 19:04:00  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:26:36  see_sw
; commit of version 9.0
;
; Revision 8.0  2004/07/20 20:18:32  turkk
; commit of version 8.0
;
; Revision 7.0  2004/07/08 23:02:58  turkk
; commit of version 7.0
;
; Revision 6.1  2004/07/07 22:34:39  turkk
; commit for version 7 release
;
; Revision 7.0  2003/03/18 20:33:04  dlwoodra
; commit for version 7.0
;
; Revision 6.0  2002/09/12 15:32:17  dlwoodra
; update to 6.0
;
; Revision 5.1  2002/09/12 15:02:42  dlwoodra
; update from main
;
; Revision 5.20  2002/09/06 23:21:35  see_sw
; commit of version 5.0
;
; Revision 4.0  2002/05/29 18:10:02  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:28  see_sw
; version_3.0_commit
;
; Revision 1.1.1.1  2000/11/21 21:49:17  dlwoodra
; SEE Code Library Import
;
;
;idver='$Id: read_netcdf.pro,v 10.1 2013/11/11 16:59:57 see_sw Exp $'
;
;+

pro	read_netCDF, filename, data, attributes, status

;
;	Generic "status" values
;
OK_STATUS = 0
BAD_PARAMS = -1
BAD_FILE = -2
BAD_FILE_DATA = -3
FILE_ALREADY_OPENED = -4

debug_mode = 0			; set to 1 if want to debug this procedure

;
;	check for valid parameters
;
status = BAD_PARAMS
if (n_params(0) lt 1) then begin
	print, 'USAGE: read_netCDF, filename, data, attributes, status'
	return
endif
if (n_params(0) lt 2) then begin
	filename = ''
	read, 'Enter filename for the existing netCDF file : ', filename
	if (strlen(filename) lt 1) then return
endif

status = OK_STATUS

if (debug_mode gt 2) and ( !d.name eq 'MAC' ) then begin
	SEE_MAC_CODE = !dir + ':SEE DPS Ä:'
	full_file = SEE_MAC_CODE + 'see_data:' + filename
endif else begin
	full_file = filename
endelse

reserved_words=['AND','BEGIN','BREAK','CASE','COMMON','COMPILE_OPT', $
                'CONTINUE','DO','ELSE','END','ENDCASE','ENDELSE','ENDFOR', $
                'ENDIF','ENDREP','ENDSWITCH','ENDWHILE','EQ','FOR', $
                'FORWARD_FUNCTION','FUNCTION','GE','GOTO','GT','IF', $
                'INHERITS','LE','LT','MOD','NE','NOT','OF','ON_IOERROR', $
                'OR','PRO','REPEAT','SWITCH','THEN','UNTIL','WHILE','XOR']

;
;	Open the netCDF file
;	1.	NCDF_OPEN: Open an existing netCDF file.
;
if (debug_mode gt 0) then print, 'Opening ', filename, ' ...'
fid = NCDF_OPEN( full_file, /NOWRITE )

;
;	Create structures based on the netCDF definitions
;	2.	NCDF_INQUIRE: Call this function to find the format of the netCDF file.
;	3.	NCDF_DIMINQ: Retrieve the names and sizes of dimensions in the file.
;	4.	NCDF_VARINQ: Retrieve the names, types, and sizes of variables in the file.
;
finq = NCDF_INQUIRE( fid )		; finq /str = ndims, nvars, ngatts, recdim

;
;	get dimension definitions first
;	get unlimited dimension (finq.recdim)
;	
dim_unlimited = finq.recdim		; = -1 if undefined, otherwise index into dim array
if ( finq.ndims gt 0 ) then begin
	dimstr = ' '
	dimsize = 0L
	dim_name = strarr( finq.ndims )
	dim_size = lonarr( finq.ndims )
	for k=0,finq.ndims-1 do begin
		NCDF_DIMINQ, fid, k, dimstr, dimsize
		dim_name[k] = dimstr
		dim_size[k] = dimsize
	endfor
endif

;
;	get variable definitions next
;	also determine nested structure levels, max. dimension, and command dimension value
;
;	LIMITATION: 6 dimensions allowed per variable
;	netCDF does not really define unsigned variable types
;
;	Have internal structure definition for tracking variables / structures
;		name = name from netCDF file
;		var_name = name from structure definition (last word after last '.')
;		type = data type value (same values as used by size())
;		natts = number of attributes for this variable
;		ndims = number of dimensions in "dim"
;		dim = dimension index into dim_size[]
;		nest_level = nest level of structures (number of '.' in name)
;		nest_name = structure name (nested)
;		nest_id = index to first case of structure name (nested)
;		nest_cnt = index of variable within a single structure (nested)
;		ptr = data variable pointer
;		str_ptr = structure pointer (if first case of new structure)
;		
var_inq1 = { name : " ", var_name : " ", type : 0, natts : 0L, ndims : 0L, dim: lonarr(8), nest_level : 0, $
	nest_name: strarr(6), nest_id : lonarr(6), nest_cnt : lonarr(6), ptr : PTR_NEW(), str_ptr : PTRARR(6) }
var_inq = replicate( var_inq1, finq.nvars )
max_level = 0			; track max structure nest level while getting variable definitions
max_dim = 1			; track max base structure dimension required
has_common_dim = 1		; assume TRUE to start out, any conflict makes it FALSE

;
;	sort out first the dimensions and attribute numbers
;	check for max. dim needed for base structure
;	and if should have base structure array (if all the same last dim)
;
for k=0, finq.nvars-1 do begin
	var_def = NCDF_VARINQ( fid, k )
	var_inq[k].ndims = var_def.ndims
	var_inq[k].natts = var_def.natts
	if (var_def.ndims gt 0) then begin
		for j=0, var_def.ndims-1 do var_inq[k].dim[j] = var_def.dim[j]
	endif
	if (var_def.ndims gt 0) then begin
		lastdim = dim_size[ var_def.dim[var_def.ndims-1] ]
		if (lastdim gt max_dim) then max_dim = lastdim
		if (var_inq[k].dim[var_inq[k].ndims-1] ne var_inq[0].dim[var_inq[0].ndims-1]) then has_common_dim = 0
	endif else has_common_dim = 0
endfor

if (debug_mode gt 0) then begin
	print, ' '
	if (has_common_dim) then print, 'Array dimension for base structure = ', strtrim(max_dim, 2) $
	else print, 'Single structure element will be defined - max dim. seen though is ', strtrim(max_dim, 2)
endif

if (has_common_dim eq 0) then max_dim = 1		;  make single-element structure only

str_dim_limit = 1								; define limit for converting BYTE array into STRING
if (has_common_dim) then str_dim_limit = 2

;
;	now define variables
;
for k=0, finq.nvars-1 do begin
	var_def = NCDF_VARINQ( fid, k )
	var_inq[k].name = var_def.name
	case strupcase(var_def.datatype) of
		'BYTE': begin
			theType = 1		; use size() definitions for data type numbers
			; if (var_def.ndims ge str_dim_limit) then begin
			;	if (debug_mode gt 0) then print, 'Forcing STRING type for ', var_def.name
			;	theType = 7
			; endif
			end
		'CHAR': begin
			theType = 7		; expect STRING type
			if (debug_mode gt 0) then print, 'STRING type for ', var_def.name
			end
		'SHORT': theType = 2
		'LONG': theType = 3
		'DOUBLE': theType = 5
		else: theType = 4		; default is FLOAT
	endcase
	;
	;	set up structure variable definitions, assume nest level 0 before looking for '.'
	;  increase nest_level for each '.' found and fill in nest_name, nest_id[], nest_cnt[]
	;
	var_inq[k].type = theType
	var_inq[k].nest_level = 0
	for ii=0,5 do begin
		var_inq[k].nest_name[ii] = ''
		var_inq[k].nest_id[ii] = 0
		var_inq[k].nest_cnt[ii] = 0
	endfor
	var_inq[k].nest_id[0] = 0
	if (k eq 0) then var_inq[k].nest_cnt[0] = 0 $
	else var_inq[k].nest_cnt[0] =  var_inq[k-1].nest_cnt[0] + 1
	dotpos = 0
	while (dotpos ge 0) do begin
		lastpos = dotpos
		dotpos = strpos( var_def.name, '.', lastpos )
		if (dotpos ge 0) then begin
			var_inq[k].nest_level = var_inq[k].nest_level + 1
			nn = var_inq[k].nest_level
			if (nn gt max_level) then max_level = nn
			if (nn gt 5) then begin
				print, 'ERROR: write_netCDF can not handle more than 4 nested structures !'
				print, 'Aborting...'
				NCDF_CONTROL, fid, /ABORT
				status = BAD_FILE_DATA
				return
			endif
			newname = strmid(var_def.name, lastpos, dotpos-lastpos)
			var_inq[k].nest_name[nn] = newname
			if (k eq 0) then k1=0 else k1 = k - 1
			if (k ne 0) and ( var_inq[k1].nest_level ge nn ) and (var_inq[k1].nest_name[nn] eq newname) then begin
				var_inq[k].nest_cnt[nn-1] = var_inq[k].nest_cnt[nn-1] - 1
				var_inq[k].nest_id[nn] = var_inq[k1].nest_id[nn]
				var_inq[k].nest_cnt[nn] = var_inq[k1].nest_cnt[nn] + 1				
			endif else begin
				var_inq[k].nest_id[nn] = k
				var_inq[k].nest_cnt[nn] = 0
			endelse
			dotpos = dotpos + 1
		endif
	endwhile
    ; avoid IDL reserved work conflict
    tmp_name = strmid( var_def.name, lastpos, strlen(var_def.name) - lastpos )
    test_reserved = where(tmp_name eq reserved_words, test_result)
    if test_result ne 0 then tmp_name = tmp_name+'_' ;append underscore
	var_inq[k].var_name = tmp_name
	;
	;	now define variable and save as PTR
	;	uses dumb dimension rules : 
	;		ndim_var = ndim_total - 1					for base structure being an array
	;		if (CHAR) then ndim_var = ndim_var - 1		for string definitions
	;
	ndim_array = var_inq[k].ndims
	if (has_common_dim) then ndim_array = ndim_array - 1
	if (var_inq[k].type eq 7) then ndim_array = ndim_array - 1
	if (ndim_array lt 0) then ndim_array = 0
	case ndim_array of
		0:	begin
			case var_inq[k].type of 
				1: theData = 0B
				2: theData = 0
				3: theData = 0L
				5: theData = 0.0D0
				7: theData = ''
				else: theData = 0.0
			endcase
			end
		1:  begin
			case var_inq[k].type of 
				1: theData = bytarr( dim_size[ var_inq[k].dim[0] ] )
				2: theData = intarr( dim_size[ var_inq[k].dim[0] ] )
				3: theData = lonarr( dim_size[ var_inq[k].dim[0] ] )
				5: theData = dblarr( dim_size[ var_inq[k].dim[0] ] )
				7: theData = strarr( dim_size[ var_inq[k].dim[1] ] )	; offset 1 Dim for char array
				else: theData = fltarr( dim_size[ var_inq[k].dim[0] ] )
			endcase
			end
		2:  begin
			case var_inq[k].type of 
				1: theData = bytarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ] )
				2: theData = intarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ] )
				3: theData = lonarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ] )
				5: theData = dblarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ] )
				7: theData = strarr( dim_size[ var_inq[k].dim[1] ], dim_size[ var_inq[k].dim[2] ] )
				else: theData = fltarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ] )
			endcase
			end
		3: 	begin
			case var_inq[k].type of 
				1: theData = bytarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ] )
				2: theData = intarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ]  )
				3: theData = lonarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ]  )
				5: theData = dblarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ]  )
				7: theData = strarr( dim_size[ var_inq[k].dim[1] ], dim_size[ var_inq[k].dim[2] ], $
								dim_size[ var_inq[k].dim[3] ]  )		; offset 1 Dim for char array
				else: theData = fltarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ]  )
			endcase
			end
		4:	begin
			case var_inq[k].type of 
				1: theData = bytarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ], dim_size[ var_inq[k].dim[3] ] )
				2: theData = intarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ], dim_size[ var_inq[k].dim[3] ]  )
				3: theData = lonarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ], dim_size[ var_inq[k].dim[3] ]  )
				5: theData = dblarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ], dim_size[ var_inq[k].dim[3] ]  )
				7: theData = strarr( dim_size[ var_inq[k].dim[1] ], dim_size[ var_inq[k].dim[2] ], $
								dim_size[ var_inq[k].dim[3] ], dim_size[ var_inq[k].dim[4] ]  )	
				else: theData = fltarr( dim_size[ var_inq[k].dim[0] ], dim_size[ var_inq[k].dim[1] ], $
								dim_size[ var_inq[k].dim[2] ], dim_size[ var_inq[k].dim[3] ]  )
			endcase
			end
		else: begin
			print, 'ERROR: read_netCDF can only handle 4 dimensions for arrays'
			print, 'Aborting...'
			NCDF_CONTROL, fid, /ABORT
			status = BAD_FILE_DATA
			return
			end
	endcase
	var_inq[k].ptr = PTR_NEW( theData )
endfor

if (debug_mode gt 0) then begin
	print, ' '
	nvar = n_elements( var_inq )
	print, 'Indx Lvl -- 0  1 ID 2  3--< 0  1 CT 2  3 >  NAME'
	for jj=0,nvar-1 do print, jj, var_inq[jj].nest_level, var_inq[jj].nest_id[0:3], var_inq[jj].nest_cnt[0:3], $
		var_inq[jj].name, form="(10I4,'   ',A)"
	stop, 'Check out var_inq and dim_name, dim_size...'
endif

;
;	define structures based on var and dim definitions from netCDF file
;	using anonymous structure name with CREATE_STRUCT()
;
;	start with largest nest level and work down to zero level
;	store higher level structures as PTR (in var_inq[XX].str_ptr)
;
;	search backwards in variables for structure definitions
;   assume structure variables are grouped together
;
for nn=max_level,0,-1 do begin
	for k=0, finq.nvars-1 do begin
		;
		;	check if new structure found (same nest level as "nn" and cnt = 0)
		;	if new, then ss = CREATE_STRUCT( tag, value ) for first parameter and
		;	then ss = CREATE_STRUCT( ss, tag, value ) for other parameters
		;
		if (k eq 0) then firstzero = var_inq[k].nest_cnt[nn] eq 0 $
		else firstzero = (var_inq[k].nest_cnt[nn] eq 0) and $
				( (var_inq[k-1].nest_cnt[nn] ne 0) or (var_inq[k-1].nest_id[nn] ne var_inq[k].nest_id[nn]) )
		if (var_inq[k].nest_level ge nn) and (firstzero) then begin
			if (nn lt var_inq[k].nest_level) then begin
				ss = CREATE_STRUCT( var_inq[k].nest_name[nn+1], *(var_inq[k].str_ptr[nn+1]) )
			endif else begin
				ss = CREATE_STRUCT( var_inq[k].var_name, *(var_inq[k].ptr) )
			endelse
			k1 = k
			for kk=k+1, finq.nvars-1 do begin
				k2 = kk
				if ( var_inq[k2].nest_level ge nn ) and ( var_inq[k2].nest_id[nn] eq var_inq[k].nest_id[nn] ) and $
						( var_inq[k2].nest_cnt[nn] eq (var_inq[k1].nest_cnt[nn] + 1) ) then begin
					if (nn lt var_inq[kk].nest_level) then begin
						ss = CREATE_STRUCT( ss, var_inq[kk].nest_name[nn+1], *(var_inq[kk].str_ptr[nn+1]) )
					endif else begin
						ss = CREATE_STRUCT( ss, var_inq[kk].var_name, *(var_inq[kk].ptr) )
					endelse
					k1 = k2
				endif
			endfor
			;
			;	store new structure as PTR
			;	if BASE structure, then replicate for all data reading later
			var_inq[k].str_ptr[nn] = PTR_NEW( ss )
			if (nn eq 0) then begin
				data = replicate( ss, max_dim )
			endif
			if (debug_mode gt 0) then begin
				if (nn gt 0) then print, k, nn, '  Structure defined for ', var_inq[k].nest_name[nn] $
				else print, k, nn, '  Base Structure defined as '
				help, ss, /struct
			endif
		endif
	endfor
endfor

if (debug_mode gt 0) then begin
	print, ' '
	print, '"data" array size is ', strtrim(max_dim,2)
	stop, 'Check out structure definitions in data...'
endif

;
;	Once structures are defined, then read the netCDF variables into "data"
;	8.	NCDF_VARGET: Read the data from the variables.
;
for k=0, finq.nvars-1 do begin
	case var_inq[k].nest_level of
		0:  begin
			NCDF_VARGET, fid, k, value
			if ( var_inq[k].type eq 7 ) then $
			data.(var_inq[k].nest_cnt[0]) = string( value ) $
			else data.(var_inq[k].nest_cnt[0]) = value
			end
		1:  begin
			NCDF_VARGET, fid, k, value
			if ( var_inq[k].type eq 7 ) then $
			data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]) = string( value ) $
			else data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]) = value
			end
		2:  begin
			NCDF_VARGET, fid, k, value
			if ( var_inq[k].type eq 7 ) then $
			data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]).(var_inq[k].nest_cnt[2]) = string( value ) $
			else data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]).(var_inq[k].nest_cnt[2]) = value
			end
		3:  begin
			NCDF_VARGET, fid, k, value
			if ( var_inq[k].type eq 7 ) then $
			data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]).(var_inq[k].nest_cnt[2]).(var_inq[k].nest_cnt[3]) = string( value ) $
			else data.(var_inq[k].nest_cnt[0]).(var_inq[k].nest_cnt[1]).(var_inq[k].nest_cnt[2]).(var_inq[k].nest_cnt[3]) = value
			end
		else: begin
			print, 'ERROR: read_netCDF can only process 4 nested structures'
			print, '       data is lost for ', var_inq[k].name
			end
	endcase
endfor

;
;	now define "attributes" as string array and read attributes from the netCDF file
;	5.	NCDF_ATTINQ: Optionally, retrieve the types and lengths of attributes.
;	6.	NCDF_ATTNAME: Optionally, retrieve attribute names.
;	7.	NCDF_ATTGET: Optionally, retrieve the attributes.
;
;	LIMITATION: limit attributes with more than 1 parameter are compressed into single string
;
CR = string( [ 13B ] )
num_att = 0L
;	finq.ngatts	= number of GLOBAL attributes from NCDF_INQUIRE earlier
if (finq.ngatts gt 0) then num_att = finq.ngatts + 1
for k=0, finq.nvars-1 do if (var_inq[k].natts gt 0) then num_att = num_att + var_inq[k].natts + 1

if ( num_att gt 0 ) then begin
	attributes = strarr( num_att )
	acnt = 0L
	;
	;	do global variables first
	;
	if ( finq.ngatts gt 0) then begin
		attributes[acnt] = 'GLOBAL:' ;	+ CR
		acnt = acnt + 1
		for jj=0,finq.ngatts-1 do begin
			att_name = NCDF_ATTNAME( fid, /GLOBAL, jj )
			NCDF_ATTGET, fid, /GLOBAL, att_name, att_value
			att_str = string( att_value )
			n_str = n_elements(att_str)
			if (n_str gt 1) then begin
				new_str = ''
				for ii=0,n_str-1 do new_str = new_str + ' ' + strtrim(att_str[ii],2)
				att_str = new_str
			endif
			attributes[acnt] = '    ' + att_name + ' = ' + att_str ; + CR
			acnt = acnt + 1
		endfor
	endif
	for k=0, finq.nvars-1 do begin
		if (var_inq[k].natts gt 0) then begin
			attributes[acnt] = var_inq[k].name + ':' ;  + CR
			acnt = acnt + 1
			for jj=0,var_inq[k].natts-1 do begin
				att_name = NCDF_ATTNAME( fid, k, jj )
				NCDF_ATTGET, fid, k, att_name, att_value
				att_str = string( att_value )
				n_str = n_elements(att_str)
				if (n_str gt 1) then begin
					new_str = ''
					for ii=0,n_str-1 do new_str = new_str + ' ' + strtrim(att_str[ii],2)
					att_str = new_str
				endif
				attributes[acnt] = '    ' + att_name + ' = ' + att_str ; + CR
				acnt = acnt + 1
			endfor
		endif
	endfor
endif else begin
	attributes = "NONE"
endelse

;
;	Close the netCDF file
;	9.	NCDF_CLOSE: Close the file.
;
NCDF_CLOSE, fid

;
;	Free up Pointers before exiting
;
for k=0, finq.nvars-1 do begin
	if PTR_VALID( var_inq[k].ptr ) then PTR_FREE, var_inq[k].ptr
	for jj=0,5 do if PTR_VALID( var_inq[k].str_ptr[jj] ) then PTR_FREE, var_inq[k].str_ptr[jj]
endfor

return
end
