; docformat = 'rst'

;+
; :Author: Paulo Penteado (`http://www.ppenteado.net <http://www.ppenteado.net>`), Feb/2013
;-
;+
; :Description:
;    This function is used to obtain a flat structure from a nested structure.
;    Its output is useful as an input to write_csv (and `write_csv_pp`).
;
; :Returns:
;    Produces a flat structure from a nested structure. If the input variable `str` does
;    not have nested structures, an identical copy is returned.
;
; :Params:
;    str: in, required
;      The structure to be flattened. See example below.
;
; :Keywords:
;    testonly: in, optional, default=0
;      If set, instead of returning a copy of the structure, only a test is performed, to determine
;      whether the given variable is a nested structure. This is useful when the structure is large: upon
;      determining that the structure is not nested, the user might decide to use the original structure,
;      instead of the output of pp_struct_unravel (which would just be a copy of the original structure).
;
; :Examples:
;
;   Define a nested structure and then flatten it::
;
;     str={a:1,b:[2,3],c:{d:'e',f:2.6},g:-1}
;     help,str
;     ;** Structure <eda88578>, 4 tags, length=40, data length=28, refs=1:
;     ;A               INT              1
;     ;B               INT       Array[2]
;     ;C               STRUCT    -> <Anonymous> Array[1]
;     ;G               INT             -1
;     help,pp_struct_unravel(str)
;     ;** Structure <ec63eeb8>, 5 tags, length=32, data length=28, refs=1:
;     ;A               INT              1
;     ;B               INT       Array[2]
;     ;C_D             STRING    'e'
;     ;C_F             FLOAT           2.60000
;     ;G               INT             -1
;
;
;
; :Author: Paulo Penteado (`http://www.ppenteado.net <http://www.ppenteado.net>`), Feb/2013
;-
function pp_struct_unravel,str,testonly=testonly
  compile_opt idl2,logical_predicate
  testonly=keyword_set(testonly)
  if size(str,/tname) ne 'STRUCT' then return,testonly ? 0 : str
  tn=tag_names(str)
  nt=n_elements(tn)
  tnames=strarr(nt)
  for i=0,nt-1 do tnames[i]=size(str.(i),/tname)
  w=where(tnames eq 'STRUCT',count)
  if ~count then return,(testonly ? 0 : str)

  ret=testonly ? 0 : {}
  for i=0,nt-1 do if tnames[i] ne 'STRUCT' then begin
    if ~testonly then ret=create_struct(ret,tn[i],str.(i))
  endif else begin
    if testonly then return,1
    s=pp_struct_unravel(str.(i))
    tnf=tag_names(s)
    for j=0,n_elements(tnf)-1 do begin
      ret=create_struct(ret,tn[i]+'_'+tnf[j],s.(j))
    endfor
  endelse
  if n_elements(str) gt 1 then ret=pp_structtransp(ret)
  return,ret


end