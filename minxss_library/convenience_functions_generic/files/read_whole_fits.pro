function read_whole_fits,file_in,verbose=verbose,status

; 7/10/06 changed d.data.rec to d.data.img

;constants
mrdfits_eof = -2

; assume we can just read it first
file = file_in

; if it's a level 0b file, then just read it
skip_decompress=0
;if stregex(file,'L0B') gt -1 then skip_decompress=1

do_del=0
if skip_decompress eq 0 and $
   strlowcase((reverse(strsplit(file_in,'.',/extract)))[0]) eq 'gz' then begin
   CD, CURRENT=curDir
   spawn,'echo $$',pid
   pid=strtrim(pid[0],2)
   file = curDir+'/'+pid+'_tmp'
   spawn,'gzip -dc '+file_in+' >! '+file,result
   do_del=1
endif

theFile = file_search(file, count = nfiles)
IF nFiles EQ 0 THEN BEGIN
  PRINT, "Error generating temp file: read_whole_fits: " + file
END

fits_info, file, /silent, n_ext = number_of_hdus
;  number_of_hdus = the max HDU #
; i.e. shk 0b has null #0 and table in #1, so number_of_hdus=1

;estimate output structure size from file size
;read in HDU until we get one that's valid
tmp = mrdfits( file, 0, h, status=status, /unsigned,/silent)
hdr = mrdfits( file, 1, h, status=status, /unsigned,/silent)
;stop
if size(tmp,/type) eq 2 and (size(tmp))[0] eq 0 then begin
    ;stop
   if do_del eq 1 then file_delete,file
    return,hdr ;bailout

;    tmp=hdr
;    help,tmp,/str,output=outtext
;    strbytes=long((strsplit((strsplit(outtext[0],/ext,'='))[1],/ext,','))[0]) * $
;      n_elements(tmp)
;    info=file_info(file)
;    n_rec=floor(info.size*1.0d0/strbytes) ;make n_rec big enough

endif else begin
    case size(tmp,/type) of
        1: strbytes=1
        2: strbytes=2
        3: strbytes=4
        4: strbytes=4
        5: strbytes=8
        6: strbytes=8
        7: strbytes=1
        9: strbytes=16
        12: strbytes=2
        13: strbytes=4
        14: strbytes=8
        15: strbytes=8
    endcase
    strbytes=strbytes*n_elements(tmp)
    info=file_info(file)
    n_rec=ceil(info.size*1.0d0/strbytes) ;make n_rec big enough
endelse


;initial values
status = 0L
i = 0L
count=0L

datarec=replicate({img:tmp<0},n_rec)
struct={data:datarec,hdr:hdr}

;while status ne mrdfits_eof and count lt n_rec do begin
while i le number_of_hdus and status ne mrdfits_eof and count lt n_rec do begin
    tmp = mrdfits( file, i, h, status=status, /unsigned, /silent)
    if status ne mrdfits_eof then begin
        ;help,tmp,/str
        if i eq 0 then struct.data[i].img=tmp else begin
            flag=0
            if size(struct[0].data[0],/type) eq 8 then flag=1
            thetags=n_tags(struct[0].data[0])
            if flag eq 1 then begin
                thetype=size(struct[0].data[0].(0),/type) 
            endif else begin
                thetype=size(struct[0].data[0],/type)
            endelse
            if thetype eq size(tmp,/type) then begin
                ; structure is same as first data read
                ;count=count+1L
                struct.data[count].img=tmp
                ;print,count
                ;stop,'look'
            endif else begin
                ;structure is not the same as the first data read
                ;treat it like a bintable
                hdr=tmp
;                struct={data:temporary(struct.data),hdr:tmp}
                ;stop
            endelse
        endelse

        i = i + 1L
    endif ;else begin
        ;stop
    ;endelse
endwhile

;stop,'.con to trim'
;print,'trimming structure down to loaded values only'
struct={data:temporary(struct.data[0:count]),hdr:hdr}
;print,'finished trimming'

;stop
if status eq mrdfits_eof then status = 0

if do_del eq 1 then file_delete,file

return,struct ;tmp
end
