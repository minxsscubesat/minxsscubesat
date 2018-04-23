;
;	generic file reading routine for general data files
;	that were written by write_dat.pro
;
;	Tom Woods
;
;	Version 1.0	1994	Initial procedure
;		2.0	1996	Updated to handle array of structures
;
;       3.0 2006 DLW Updated to remove empty dimensions for 1d arrays
;            Updated to return integer types for 1d arrays based on data ranges
;            (byte, uint, fix, long, ulong, long64, & ulong64)
;
;	INPUT:  filename
;	
;	OUTPUT:	data from the file (array of data or array of structure)
;
; $Log: read_dat.pro,v $
; Revision 4.0  2013/03/28 19:18:27  dlwoodra
; version_4.0_commit
;
; Revision 3.0  2011/03/22 15:24:52  dlwoodra
; version_3.0_commit
;
; Revision 2.0  2010/06/23 18:10:49  dlwoodra
; version_2.0_commit
;
; Revision 1.1.1.1  2009/05/28 21:58:01  evesdp
; Imported Sources
;
; Revision 9.1  2006/07/19 16:03:56  dlwoodra
; remove empty dimensions
; return integral types for 1d arrays
;
; Revision 9.0  2005/06/16 15:26:36  see_sw
; commit of version 9.0
;
; Revision 8.0  2004/07/20 20:18:31  turkk
; commit of version 8.0
;
; Revision 7.0  2004/07/08 23:02:58  turkk
; commit of version 7.0
;
; Revision 6.0  2003/03/05 19:32:30  dlwoodra
; version 6 commit
;
; Revision 5.20  2002/09/06 23:21:35  see_sw
; commit of version 5.0
;
; Revision 4.0  2002/05/29 18:10:01  see_sw
; Release of version 4.0
;
; Revision 3.0  2002/02/01 18:55:28  see_sw
; version_3.0_commit
;
; Revision 1.1.1.1  2000/11/21 21:49:17  dlwoodra
; SEE Code Library Import
;
;
;idver='$Id: read_dat.pro,v 4.0 2013/03/28 19:18:27 dlwoodra Exp $'
;
function read_dat, filename, status=status, silent=silent

status = -1
data = -1

if n_params(0) lt 1 then begin
	filename = ' '
	read, 'Enter filename to read ? ', filename
	if filename eq '' then return, data
endif

get_lun, lun
openit = 0
on_ioerror, openerror
openr,lun, filename

numbers = '0123456789'

;
;	read header comment lines first
;	also check for STRUCTURE and FORMAT keywords too
;
on_ioerror, readerror
openit = 1
incomments = 1
sinput = ''
form = ''
struct = ''
while incomments do begin
	readf,lun,sinput
	sinput = strtrim(sinput,1)
	sinputcaps = strupcase(sinput)
	if strpos( sinputcaps, 'STRUCT' ) eq 0 then begin
		startpos = strpos( sinputcaps, '{' )
		endpos = strpos( sinputcaps, '}' )
		if (startpos lt 0) or (endpos lt 0) or $
		   (endpos lt startpos) then begin
			if (not(keyword_set(silent))) then print, 'read_dat: Error in STRUCT keyword definition !'
		endif else begin
			struct = strmid( sinput, startpos, endpos-startpos+1 )
		endelse
	endif
	if strpos( sinputcaps, 'FORMAT' ) eq 0 then begin
		startpos = strpos( sinputcaps, '(' )
		endpos = strpos( sinputcaps, ')' )
		if (startpos lt 0) or (endpos lt 0) or $
		   (endpos lt startpos) then begin
			if (not(keyword_set(silent))) then print, 'read_dat: Error in FORMAT keyword definition !'
		endif else begin
			form = strmid( sinput, startpos, endpos-startpos+1 )
		endelse
	endif
	if strpos( numbers, strmid(sinput,0,1) ) ge 0 then $
		incomments = 0
endwhile
;
;	read number of lines
;
nlines = long( sinput )
n = strlen(sinput)
k = 1
innumber = 1
numberstr = '0123456789 /.,<>?;:\|=+-_)(*&^%$#@!~'
while innumber do begin
    if strpos( numberstr, strmid(sinput,k,1) ) lt 0 then begin
	if (k lt n-1) and (not(keyword_set(silent))) then begin
		print, '    ', filename, ' : ', strmid(sinput,k,n-k)
	endif
	innumber = 0
    endif else begin
	k = k + 1
	if k ge n-2 then innumber = 0
    endelse
endwhile
;
;	read number of columns
;
readf,lun,sinput
sinput = strtrim(sinput,1)
ncolumns = long( sinput )
n = strlen(sinput)
k = 1
innumber = 1
while innumber do begin
    if strpos( numberstr, strmid(sinput,k,1) ) lt 0 then begin
	if (k lt n-1) and (not(keyword_set(silent))) then begin
		print, '    ', filename, ' : ', strmid(sinput,k,n-k)
	endif
	innumber = 0
    endif else begin
	k = k + 1
	if k ge n-2 then innumber = 0
    endelse
endwhile

form = '$' + form

;
;	read array of numbers if structure is not defined
;
if strlen(struct) le 2 then begin
	data = dblarr(ncolumns, nlines)
	;
	; read data (using format if it exists)
	;
	if strlen(form) le 2 then readf,lun,data else $
		readf,lun,form,data	
	status = 0

    ; 7/19/06 DLW - remove empty dim, assign appropriate type
    data=reform(data) ;remove empty dimension if only 1d array
    ;check for integer type
    tmp=where(data mod 1ULL gt 0,n_float)
    if n_float eq 0 then begin
        datamax=max(data,min=datamin)
        if datamin ge 0 then begin
            ;unsigned types
            if datamax gt 2UL^32-1 then data=ulong64(data) else $ ;64-bit
              if datamax gt 2UL^16-1 then data=ulong(data) else $ ;32-bit
                if datamax gt 255 then data=uint(data) else $ ;16-bit
                  data=byte(data) ;8-bit
        endif else begin
            ;signed types
            if datamax gt 2UL^32-1 then data=long64(data) else $ ;64-bit
              if datamax gt 2UL^16-1 then data=long(data) else $ ;32-bit
                data=fix(data) ;16-bit
        endelse
    endif ;else leave data as a double

	goto, cleanup
endif else begin
;
;	read array of structure
;
	acmd = execute( 'temp = ' + struct )
	data = replicate( temp, nlines )
	;
	; read data (using format if it exists)
	;
	if strlen(form) le 2 then readf,lun,data else $
		readf,lun,form,data
	;
	; clean up any string data
	;
	ntags = n_tags(data)
	tnames = tag_names(data)
	for i=0,ntags-1 do begin
	  asize = size( data.(i) )
	  if (asize(asize(0)+1) eq 7) then begin
		if (not(keyword_set(silent))) then print, 'read_dat: Compressing strings for DATA.' + tnames(i)
		data.(i) = strtrim( data.(i), 2 )
	  endif
	endfor
	status = 0
	goto, cleanup	
endelse

openerror:
print, 'ERROR: READ_DAT() could not open ' + filename
goto,cleanup

readerror:
print, 'ERROR: READ_DAT() had a read error for ' + filename

cleanup:
if (not(keyword_set(silent))) then print, ' '
on_ioerror, NULL
if openit then close,lun
free_lun, lun
return, data
end
