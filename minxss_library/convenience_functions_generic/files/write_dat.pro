;
;	generic file writing routine for general data files
;	Use read_dat.pro to read these files
;
;	Tom Woods
;
;	Version 1.0	1994	Initial procedure
;		2.0	1996	Updated to handle array of structures
;
;	INPUT:  data			array or structure of data
;		filename keyword	name of output file
;		lintext keyword		string for "lines" comment
;		coltext keyword		string for "columns" comment
;		comments keyword	string or array of strings for header
;		format keyword		specific format for writing file
;
;	OUTPUT:  status			0 if OK, -1 if failed to write file
;
; $Log: write_dat.pro,v $
; Revision 4.0  2013/03/28 19:18:09  dlwoodra
; version_4.0_commit
;
; Revision 3.0  2011/03/22 15:24:44  dlwoodra
; version_3.0_commit
;
; Revision 2.0  2010/06/23 18:10:40  dlwoodra
; version_2.0_commit
;
; Revision 1.1.1.1  2009/05/28 21:58:01  evesdp
; Imported Sources
;
; Revision 7.0  2004/07/08 23:03:01  turkk
; commit of version 7.0
;
; Revision 6.0  2003/03/05 19:32:26  dlwoodra
; version 6 commit
;
; Revision 5.20  2002/09/06 23:21:36  see_sw
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
;idver='$Id: write_dat.pro,v 4.0 2013/03/28 19:18:09 dlwoodra Exp $'
;
pro write_dat, data, filename=filename, lintext=lintext, coltext=coltext, $
	comments=comments,format=format, status=status

status = -1
if n_params(0) lt 1 then begin
	print, 'USAGE: write_dat, data, filename=filename, lintext=lintext, $'
	print, '               coltext=coltext, comments=comments, $'
	print, '               format=format, status=status'
	return
endif

isStructure = 0
ns = size( data )
;
;	set up format, structure string for data structure
;
if ns(ns(0)+1) eq 8 then begin
  isStructure = 1
  structStr = 'STRUCTURE = { '
  tnames = tag_names(data)
  nt = n_tags(data)
  altform = '$('
  for i=0,nt-1 do begin
	structStr = structStr + tnames(i) + ': '
	asize = size(data.(i))
	atype = asize(asize(0)+1)
	case atype of
		1:  begin
			structStr = structStr + '0B'
			altform = altform + 'I'
		    end
		2:  begin
			structStr = structStr + '0'
			altform = altform + 'I'
		    end
		3:  begin
			structStr = structStr + '0L'
			altform = altform + 'I'
		    end
		4:  begin
			structStr = structStr + '0.0'
			altform = altform + 'G'
		    end
		5:  begin
			structStr = structStr + '0.0D0'
			altform = altform + 'G'
		    end
		6:  begin
			structStr = structStr + 'complex(0,0)'
			altform = altform + 'G,G'
		    end
		7:  begin
			structStr = structStr + "' '"
			altform = altform + 'A'
			smax = 1
			for j = 0,ns(1)-1 do begin
				slen = strlen(data(j).(i))
				if slen gt smax then smax = slen
			endfor
			smax = smax + 2
			altform = altform + strtrim( string(smax), 2 )
		    end
		else: begin
			structStr = structStr + '0.0D0'
			altform = altform + 'G'
		    end
	endcase
	if i ne nt-1 then begin
		structStr = structStr + ', '
		altform = altform + ','
	endif
  endfor
  structStr = structStr + ' }'
  altform = altform + ')'
  if (ns(0) ne 1) then begin
	print, 'write_dat: A structure must be 1-D data.'
	return
  endif
  ncolumns = nt
  nlines = ns(1)
  if not(keyword_set(format)) then format = altform
endif else begin
;
;	check array of data for correct types and size
;
  if (ns(ns(0)+1) lt 1) or (ns(ns(0)+1) gt 7) then begin
	print, 'write_dat: Data array is an undefined type !!!???'
	return
  endif
  if (ns(0) gt 2) or (ns(0) lt 1) then begin
	print, 'write_dat: The data array must be 1-D or 2-D data.'
	return
  endif
  if ns(0) eq 1 then begin
	ncolumns = 1
	nlines = ns(1)
  endif else begin
	ncolumns = ns(1)
	nlines = ns(2)
  endelse
endelse

if NOT( keyword_set( filename) ) then begin
	filename = ' '
	read, 'write_dat: Enter output filename ? ', filename
endif

if keyword_set( lintext ) then lintext = 'lines : ' + lintext else $
	lintext = 'lines'

if keyword_set( coltext ) then coltext = 'columns : ' + coltext else $
	coltext = 'columns'

get_lun, lun
openit = 0
on_ioerror, openerror
openw,lun, filename

on_ioerror, writeerror
openit = 1
if keyword_set( comments ) then begin
	nc = n_elements(comments)
	for k=0,nc-1 do printf,lun, '; ', comments(k)
endif
if isStructure ne 0 then printf,lun, structStr
if keyword_set(format) then printf,lun,'FORMAT = ' + format
printf,lun, ' ' + strtrim(nlines,2) + ' ' + lintext
printf,lun, ' ' + strtrim(ncolumns,2) + ' ' + coltext
if keyword_set(format) then printf,lun, data, form=format else printf,lun, data
status = 0
goto, cleanup

openerror:
print, 'write_dat: Could not open ' + filename
goto,cleanup

writeerror:
print, 'write_dat: there was a write error for ' + filename

cleanup:
on_ioerror, NULL
if openit then close,lun
free_lun, lun
return
end
