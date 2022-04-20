; docformat = 'rst'

;+
; :Author: Paulo Penteado (`http://www.ppenteado.net <http://www.ppenteado.net>`), Feb/2013
; This file contains write_csv_pp, and a copy of IDL's write_csv routines (renamed write_csv_pp_original
; and write_csv_convert_pp_original), since write_csv_pp requires an edit on the original write_csv.
;-



; $Id: //depot/Release/ENVI51_IDL83/idl/idldir/lib/write_csv.pro#1 $
;
; Copyright (c) 2008-2013, Exelis Visual Information Solutions, Inc. All
;       rights reserved. Unauthorized reproduction is prohibited.

;----------------------------------------------------------------------------
function write_csv_convert_pp_original, data,noquote=noquote

  compile_opt idl2, hidden

  switch (SIZE(data, /TYPE)) of

    7: begin   ; string type
      ; Always surround all strings with quotes, to avoid problems with
      ; commas and whitespace.
      if noquote then begin
        data1=data
        nq=where((strpos(data,'"') ge 0) or (strpos(data,',') ge 0),nnq)
        if (nnq gt 0) then begin
          data1[nq]='"'+data[nq]+'"'
        endif
      endif else begin
        data1 = '"'+data+'"'
      endelse
      ; Now look for double-quote chars, which need to be escaped.
      hasQuote = WHERE(STRPOS(data, '"') ge 0, nQuote)
      if (nQuote gt 0) then begin
        d = data[hasQuote]
        for i=0,nQuote-1 do d[i] = STRJOIN(STRTOK(d[i],'"',/EXTRACT,/PRESERVE_NULL),'""')
        data1[hasQuote] = '"' + d + '"'
      endif
      return, data1
    end

    ; Be sure to convert bytes to numbers
    1: return, STRTRIM(FIX(data), 1)

    ; Use a format code for double-precision numbers.
    5: return, STRTRIM(STRING(data, FORMAT='(g)'), 1)

    6: ; complex and dcomplex (fall thru)
    9: return, '"' + STRCOMPRESS(data, /REMOVE_ALL) + '"'

    else: begin
      ; regular numeric types
      return, STRTRIM(data, 2)
    end

  endswitch

end

;----------------------------------------------------------------------------
;+
; :Description:
;    The WRITE_CSV procedure writes data to a "comma-separated value"
;    (comma-delimited) text file.
;
;    This routine writes CSV files consisting of an optional line of column
;    headers, followed by columnar data, with commas separating each field.
;    Each row is a new record.
;
;    This routine is written in the IDL language. Its source code can be
;    found in the file write_csv.pro in the lib subdirectory of the IDL
;    distribution.
;
; :Syntax:
;    WRITE_CSV, Filename, Data1 [, Data2,..., Data8]
;      [, HEADER=value]
;
; :Params:
;    Filename
;      A string containing the name of the CSV file to write.
;
;    Data1...Data8
;      The data values to be written out to the CSV file. The data arguments
;      can have the following forms:
;      * Data1 can be an IDL structure, where each field contains a
;        one-dimensional array (a vector) of data that corresponds
;        to a separate column. The vectors must all have the same
;        number of elements, but can have different data types. If Data1
;        is an IDL structure, then all other data arguments are ignored.
;      * Data1 can be a two-dimensional array, where each column in the array
;        corresponds to a separate column in the output file. If Data1 is
;        a two-dimensional array, then all other data arguments are ignored.
;      * Data1...Data8 are one-dimensional arrays (vectors), where each vector
;        corresponds to a separate column in the output file. Each vector
;        can have a different data type.
;
; :Keywords:
;    HEADER
;      Set this keyword equal to a string array containing the column header
;      names. The number of elements in HEADER must match the number of
;      columns provided in Data1...Data8. If HEADER is not present,
;      then no header row is written.
;
;      TABLE_HEADER
;      Set this keyword to a scalar string or string array containing extra table lines
;      to be written at the beginning of the file.
;
; :History:
;   Written, CT, VIS, Nov 2008
;   MP, VIS, Oct 2009:  Added keyword SKIP_HEADER
;   Dec 2010:  Better handling for byte and double precision data.
;
;-
pro write_csv_pp_original, Filename, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, $
  HEADER=header, TABLE_HEADER=tableHeader,append=append,noquote=noquote

  compile_opt idl2

  ON_ERROR, 2         ;Return on error

  ON_IOERROR, ioerr

  if (N_PARAMS() lt 2) then $
    MESSAGE, 'Incorrect number of arguments.'

  isStruct = SIZE(Data1, /TYPE) eq 8
  isArray = SIZE(Data1, /N_DIM) eq 2

  if (SIZE(Filename,/TYPE) ne 7) then $
    MESSAGE, 'Filename must be a string.'

  if (N_ELEMENTS(Data1) eq 0) then $
    MESSAGE, 'Data1 must contain data.'

  ; Verify that all columns have the same number of elements.

  msg = 'Data fields must all have the same number of elements.'

  if (isStruct) then begin

    nfields = N_TAGS(Data1)
    nrows = N_ELEMENTS(Data1.(0))
    for i=1,nfields-1 do begin
      if (N_ELEMENTS(Data1.(i)) ne nrows) then $
        MESSAGE, msg
    endfor

  endif else if (isArray) then begin

    d = SIZE(Data1, /DIM)
    nfields = d[0]
    nrows = d[1]

  endif else begin  ; Individual data arguments

    nfields = N_PARAMS() - 1
    nrows = N_ELEMENTS(Data1)

    switch (nfields) of
      8: if (N_ELEMENTS(Data8) ne nrows) then MESSAGE, msg
      7: if (N_ELEMENTS(Data7) ne nrows) then MESSAGE, msg
      6: if (N_ELEMENTS(Data6) ne nrows) then MESSAGE, msg
      5: if (N_ELEMENTS(Data5) ne nrows) then MESSAGE, msg
      4: if (N_ELEMENTS(Data4) ne nrows) then MESSAGE, msg
      3: if (N_ELEMENTS(Data3) ne nrows) then MESSAGE, msg
      2: if (N_ELEMENTS(Data2) ne nrows) then MESSAGE, msg
      else:
    endswitch

  endelse


  ; Verify that the header (if provided) has the correct number of elements.

  nheader = N_Elements(header)
  if (nheader gt 0) then begin
    ; Quietly ignore null strings.
    if (ARRAY_EQUAL(header,'')) then begin
      nheader = 0
    endif else begin
      if (nheader ne nfields || SIZE(header,/type) ne 7) then begin
        MESSAGE, 'HEADER must be a string array of length equal to the number of columns.'
      endif
    endelse
  endif


  ; Start writing the file.

  OPENW, lun, filename, /GET_LUN,append=append
  ; What about handling COMMAS or QUOTES?!

  format = (nfields ge 2) ? '(' + STRTRIM(nfields-1,2)+'(A,","),A)' : '(A)'

  ; Printing out extra headers to csv file
  if n_elements(tableHeader) gt 0 then begin
    for i=0, n_elements(tableHeader)-1 do begin
      ;check if there is comma in the string
      posComma = stregex(tableHeader[i], ',')
      posQuote = stregex(tableHeader[i], '"')
      if (posComma eq -1) && (posQuote eq -1) then printf, lun, tableHeader[i], FORMAT=format else printf, lun, '"' + tableHeader[i] + '"', FORMAT=format
    endfor
  endif

  if (nheader gt 0) then begin
    PRINTF, lun, header, FORMAT=format
  endif


  if (isStruct) then begin  ; Structure fields

    strCopy = STRARR(nfields, nrows)

    for i=0,nfields-1 do begin
      strCopy[i,*] = WRITE_CSV_CONVERT_pp_original(Data1.(i),noquote=noquote)
    endfor

    PRINTF, lun, strCopy, FORMAT=format

  endif else if (isArray) then begin  ; Two-dimensional array

    PRINTF, lun, WRITE_CSV_CONVERT_pp_original(Data1,noquote=noquote), FORMAT=format

  endif else begin  ; Individual data arguments

    strCopy = STRARR(nfields, nrows)

    switch (nfields) of
      8: strCopy[7,*] = WRITE_CSV_CONVERT_pp_original(Data8,noquote=noquote)
      7: strCopy[6,*] = WRITE_CSV_CONVERT_pp_original(Data7,noquote=noquote)
      6: strCopy[5,*] = WRITE_CSV_CONVERT_pp_original(Data6,noquote=noquote)
      5: strCopy[4,*] = WRITE_CSV_CONVERT_pp_original(Data5,noquote=noquote)
      4: strCopy[3,*] = WRITE_CSV_CONVERT_pp_original(Data4,noquote=noquote)
      3: strCopy[2,*] = WRITE_CSV_CONVERT_pp_original(Data3,noquote=noquote)
      2: strCopy[1,*] = WRITE_CSV_CONVERT_pp_original(Data2,noquote=noquote)
      1: strCopy[0,*] = WRITE_CSV_CONVERT_pp_original(Data1,noquote=noquote)
    endswitch

    PRINTF, lun, strCopy, FORMAT=format

  endelse

  FREE_LUN, lun

  return

  ioerr:
  ON_IOERROR, null
  if (N_ELEMENTS(lun) gt 0) then $
    FREE_LUN, lun
  MESSAGE, !ERROR_STATE.msg

end


;+
; :Description:
;    A simple wrapper for write_csv, to write csv files using a structure's field names as column
;    titles (setting `titlesfromfields`), ccepting nested structures, and with the option of writing the
;    file by pieces.
;
; :Params:
;    file: in, required, type=string
;      Passed to write_csv, specifies the name of the file to write.
;    data1: in, required
;      Passed to write_csv, after the variable has its structures flattened by a call to
;      `pp_struct_unravel`.
;    data2: in, optional
;      Passed unaltered to write_csv.
;    data3: in, optional
;      Passed unaltered to write_csv.
;    data4: in, optional
;      Passed unaltered to write_csv.
;    data5: in, optional
;      Passed unaltered to write_csv.
;    data6: in, optional
;      Passed unaltered to write_csv.
;    data7: in, optional
;      Passed unaltered to write_csv.
;    data8: in, optional
;      Passed unaltered to write_csv.
;
; :Keywords:
;    titlesfromfields: in, optional
;      If set, the column titles in the csv file are made by the field names in data1.
;    verbose: in, optional, default=0
;      If set, write_csv_pp will inform which piece of the file it is currently writing
;    divide: in, optional, default=1
;      Used to split the file writing into ``divide`` pieces. This is useful to save memory, since
;      IDL's ``write_csv`` creates a temporary string array with the whole file contents, before writing it
;      to the file, and that array can be several times larger than the input array.
;    noquote: in, optional, default=0
;      If set, string fields that do not contain commas or double-quotes will not
;      be quoted. If not set (default), all string fields are quoted.
;    _ref_extra: in, out, optional
;      Any other parameters are passed, unaltered, to / from write_csv.
;
; :Examples:
;    Make a simple structure array and write it to a csv file::
;
;      s={a:1,b:{c:2.5,d:-9,e:0},f:1.8,g:'h'}
;      s2=replicate(s,2)
;      s2[1].a=-1
;      s2[1].f=-1.8
;      s2[1].g='h,i'
;      write_csv_pp,'write_csv_pp_test.csv',s2,/titlesfromfields
;
;    Which result in a file with:
;
;    A,B_C,B_D,B_E,F,G
;
;    1,2.50000,-9,0,1.80000,"h"
;
;    -1,2.50000,-9,0,-1.80000,"h,i"
;
;    Compare with using the `noquote` keyword:
;
;      write_csv_pp,'write_csv_pp_test.csv',s2,/titlesfromfields,/noquote
;
;    Which produces
;
;    A,B_C,B_D,B_E,F,G
;
;    1,2.50000,-9,0,1.80000,h
;
;    -1,2.50000,-9,0,-1.80000,"h,i"
;
;    On the first row, the string (the last column) is unquoted. On the second,
;    it is still quoted because it contains a comma; without this quote, it
;    would look like the row has an extra column.
;
; :Requires: `pp_struct_unravel`
;
; :Author: Paulo Penteado (`http://www.ppenteado.net <http://www.ppenteado.net>`), Feb/2013
;-
pro write_csv_pp,file,data1,data2,data3,data4,data5,data6,data7,data8,titlesfromfields=tf,$
  divide=divide,_ref_extra=ex,verbose=verbose,noquote=noquote
  compile_opt idl2,logical_predicate

  noquote=keyword_set(noquote)
  divide=n_elements(divide) ? divide : 1LL
  nrows=n_elements(data1)
  blocksize=ceil(nrows*1d0/divide)
  nd=ceil(nrows*1d0/blocksize)

  u=pp_struct_unravel(data1,/testonly)
  if u then data0=pp_struct_unravel(data1)
  for i=0LL,nd-1 do begin
    fr=i*blocksize
    lr=((i+1LL)*blocksize-1)<(nrows-1LL)
    if keyword_set(verbose) then print,'write_csv_pp: writing file section ',strtrim(i+1,2),' of ',strtrim(nd,2)
    if keyword_set(tf) then begin
      header=tag_names(u ? data0 : data1)
      write_csv_pp_original,file,(u ? data0[fr:lr] : data1[fr:lr]),$
        n_elements(data2) ? data2[fr:lr] : !null ,$
        n_elements(data3) ? data3[fr:lr] : !null ,$
        n_elements(data4) ? data4[fr:lr] : !null ,$
        n_elements(data5) ? data5[fr:lr] : !null ,$
        n_elements(data6) ? data6[fr:lr] : !null ,$
        n_elements(data7) ? data7[fr:lr] : !null ,$
        n_elements(data8) ? data8[fr:lr] : !null ,$
        _strict_extra=ex,header=(i eq 0 ? header : !null),append=i,noquote=noquote
    endif else begin
      write_csv_pp_original,file,(u ? data0[fr:lr] : data1[fr:lr]),$
        n_elements(data2) ? data2[fr:lr] : !null ,$
        n_elements(data3) ? data3[fr:lr] : !null ,$
        n_elements(data4) ? data4[fr:lr] : !null ,$
        n_elements(data5) ? data5[fr:lr] : !null ,$
        n_elements(data6) ? data6[fr:lr] : !null ,$
        n_elements(data7) ? data7[fr:lr] : !null ,$
        n_elements(data8) ? data8[fr:lr] : !null ,$
        _strict_extra=ex,append=i,noquote=noquote
    endelse
  endfor
end
