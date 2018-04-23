;+
; NAME:
;   read_netCDF_header.pro
;
; PURPOSE:
;   Read netCDF header into string array variable
;
; CATEGORY:
;   All levels of processing
;
; CALLING SEQUENCE:  
;   read_netCDF_header, filename, attributes, status
;
; INPUTS:
;   filename = filename for existing netCDF file
;
; OUTPUTS:  
;   attributes = array of strings of the attributes from the netCDF file
;   status = result status: 0 = OK_STATUS, -1 = BAD_PARAMS, -2 = BAD_FILE,
;           -3 = BAD_FILE_DATA, -4 = FILE_ALREADY_OPENED
;
; COMMON BLOCKS:
;   None
;
; PROCEDURE:
;   Check for valid input parameters
;   Open the netCDF file
;   Create structures based on the netCDF definitions
;   Once structures are defined, then read the netCDF variables into
;   the structure's data 
;   Read the attributes into a string array
;   Close the netCDF file
;
;   NetCDF IDL Procedures / Process:
;   1.  NCDF_OPEN: Open an existing netCDF file.
;   2.  NCDF_INQUIRE: Call this function to find the format of the
;        netCDF file.
;   3.  NCDF_DIMINQ: Retrieve the names and sizes of dimensions in the file.
;   4.  NCDF_VARINQ: Retrieve the names, types, and sizes of variables
;        in the file.
;   5.  NCDF_ATTINQ: Optionally, retrieve the types and lengths of
;        attributes.
;   6.  NCDF_ATTNAME: Optionally, retrieve attribute names.
;   7.  NCDF_ATTGET: Optionally, retrieve the attributes.
;;;;;   8.  No longer exists! NCDF_VARGET: Read the data from the variables.
;   9.  NCDF_CLOSE: Close the file.
;
; MODIFICATION HISTORY:
;   9/20/1999       Tom Woods       Original release of code, Version 1.00
;   12/3/1999       Tom Woods       Removed BYTE array conversion to STRING
;   11/19/2001  Don Woodraska  Modified read_netcdf v 1.1.1.1 to read
;   only the header information from the netcdf file. No data is
;   actually read which makes this fast. Separated wrapped lines,
;   untabbified.
;
; $Log: read_netcdf_header.pro,v $
; Revision 10.1  2013/11/11 16:59:57  see_sw
; update
;
; Revision 10.0  2007/05/08 19:04:00  see_sw
; commit of version 10.0
;
; Revision 9.0  2005/06/16 15:26:37  see_sw
; commit of version 9.0
;
; Revision 8.0  2004/07/20 20:18:32  turkk
; commit of version 8.0
;
; Revision 7.0  2004/07/08 23:02:58  turkk
; commit of version 7.0
;
; Revision 6.0  2003/03/05 19:32:46  dlwoodra
; version 6 commit
;
; Revision 5.20  2002/09/06 23:21:35  see_sw
; commit of version 5.0
;
; Revision 4.1  2002/05/30 16:09:20  dlwoodra
; initial 4.0 commit
;
;
;idver='$Id: read_netcdf_header.pro,v 10.1 2013/11/11 16:59:57 see_sw Exp $'
;
;-

pro read_netCDF_header, filename, attributes, status

;
;   Generic "status" values
;
OK_STATUS = 0
BAD_PARAMS = -1
BAD_FILE = -2
BAD_FILE_DATA = -3
FILE_ALREADY_OPENED = -4

debug_mode = 0          ; set to 1 if want to debug this procedure

;
;   check for valid parameters
;
status = BAD_PARAMS
if (n_params(0) lt 1) then begin
    print, 'USAGE: read_netCDF, filename, attributes, status'
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

;
;   Open the netCDF file
;   1.  NCDF_OPEN: Open an existing netCDF file.
;
if (debug_mode gt 0) then print, 'Opening ', filename, ' ...'
fid = NCDF_OPEN( full_file, /NOWRITE )

;
;   Create structures based on the netCDF definitions
;   2.  NCDF_INQUIRE: Call this function to find the format of the
;        netCDF file. 
;   3.  NCDF_DIMINQ: Retrieve the names and sizes of dimensions in the file.
;   4.  NCDF_VARINQ: Retrieve the names, types, and sizes of variables
;        in the file.
;
finq = NCDF_INQUIRE( fid )      ; finq /str = ndims, nvars, ngatts, recdim

;
;   get dimension definitions first
;   get unlimited dimension (finq.recdim)
;   
dim_unlimited = finq.recdim 
; dim_unlimited = -1 if undefined, otherwise index into dim array
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
;   get variable definitions next
;   also determine nested structure levels, max. dimension, and
;   command dimension value 
;
;   LIMITATION: 6 dimensions allowed per variable
;   netCDF does not really define unsigned variable types
;
;   Have internal structure definition for tracking variables / structures
;       name = name from netCDF file
;       var_name = name from structure definition (last word after last '.')
;       type = data type value (same values as used by size())
;       natts = number of attributes for this variable
;       ndims = number of dimensions in "dim"
;       dim = dimension index into dim_size[]
;       nest_level = nest level of structures (number of '.' in name)
;       nest_name = structure name (nested)
;       nest_id = index to first case of structure name (nested)
;       nest_cnt = index of variable within a single structure (nested)
;       ptr = data variable pointer
;       str_ptr = structure pointer (if first case of new structure)
;       
var_inq1 = { name       : " ",       $
             var_name   : " ",       $
             type       : 0,         $
             natts      : 0L,        $
             ndims      : 0L,        $
             dim        : lonarr(8), $
             nest_level : 0,         $
             nest_name  : strarr(6), $
             nest_id    : lonarr(6), $
             nest_cnt   : lonarr(6), $
             ptr        : PTR_NEW(), $
             str_ptr    : PTRARR(6)  $
           }
var_inq = replicate( var_inq1, finq.nvars )
max_level = 0
; track max structure nest level while getting variable definitions
max_dim = 1         ; track max base structure dimension required
has_common_dim = 1  ; assume TRUE to start out, any conflict makes it FALSE

;
;   sort out first the dimensions and attribute numbers
;   check for max. dim needed for base structure
;   and if should have base structure array (if all the same last dim)
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
        if (var_inq[k].dim[var_inq[k].ndims-1] ne $
            var_inq[0].dim[var_inq[0].ndims-1]) then has_common_dim = 0
    endif else has_common_dim = 0
endfor

if (debug_mode gt 0) then begin
    print, ' '
    if (has_common_dim) then $
      print, 'Array dimension for base structure = ', strtrim(max_dim, 2) $
    else print, 'Single structure element will be defined' + $
      '- max dim. seen though is ', strtrim(max_dim, 2)
endif

if (has_common_dim eq 0) then max_dim = 1 ; make one-element structure only

str_dim_limit = 1   ; define limit for converting BYTE array into STRING
if (has_common_dim) then str_dim_limit = 2


;
;   now define "attributes" as string array and read attributes from
;   the netCDF file 
;   5.  NCDF_ATTINQ: Optionally, retrieve the types and lengths of
;        attributes. 
;   6.  NCDF_ATTNAME: Optionally, retrieve attribute names.
;   7.  NCDF_ATTGET: Optionally, retrieve the attributes.
;
;   LIMITATION: limit attributes with more than 1 parameter are
;   compressed into single string
;

CR = string( [ 13B ] )
num_att = 0L
;   finq.ngatts = number of GLOBAL attributes from NCDF_INQUIRE earlier
if (finq.ngatts gt 0) then num_att = finq.ngatts + 1
for k=0, finq.nvars-1 do $
  if (var_inq[k].natts gt 0) then num_att = num_att + var_inq[k].natts + 1

if ( num_att gt 0 ) then begin
    attributes = strarr( num_att )
    acnt = 0L
    ;
    ;   do global variables first
    ;
    if ( finq.ngatts gt 0) then begin
        attributes[acnt] = 'GLOBAL:' ;  + CR
        acnt = acnt + 1
        for jj=0,finq.ngatts-1 do begin
            att_name = NCDF_ATTNAME( fid, /GLOBAL, jj )
            NCDF_ATTGET, fid, /GLOBAL, att_name, att_value
            att_str = string( att_value )
            n_str = n_elements(att_str)
            if (n_str gt 1) then begin
                new_str = ''
                for ii=0,n_str-1 do $
                  new_str = new_str + ' ' + strtrim(att_str[ii],2)
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
                    for ii=0,n_str-1 do $
                      new_str = new_str + ' ' + strtrim(att_str[ii],2)
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
;   Close the netCDF file
;   9.  NCDF_CLOSE: Close the file.
;
NCDF_CLOSE, fid

;
;   Free up Pointers before exiting
;
for k=0, finq.nvars-1 do begin
    if PTR_VALID( var_inq[k].ptr ) then PTR_FREE, var_inq[k].ptr
    for jj=0,5 do if PTR_VALID( var_inq[k].str_ptr[jj] ) then $
      PTR_FREE, var_inq[k].str_ptr[jj]
endfor

return
end
