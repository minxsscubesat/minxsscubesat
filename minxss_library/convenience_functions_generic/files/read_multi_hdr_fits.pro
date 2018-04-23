function read_multi_hdr_fits, file, status, keywords=keywords

; 7/10/06 changed d.data.rec to d.data.img
; 02/02/08 DLW added optional keywords parameter to return headers
;              using fits_info to prevent reading past the EOF

;
; Assumptions: 
;  1) the first HDU (#0) is an image or null
;  2) the second HDU(#1) is a binary table
;  3) any subsequent HDUs are like the first image or like the second
;  binary table. All other HDUs are appended to 0 or 1.
;

;constants
mrdfits_eof = -2
status=0

fits_info,file,n_ext=n_ext,/silent ;n_ext is the number of HDUs

;estimate output structure size from file size
;read in HDU until we get one that's valid
tmp = mrdfits( file, 0, h, status=status, /unsigned,/silent)
keywords = h
if n_ext eq 0 then begin
    ; only 1 HDU is in the file and it has been read
    return,tmp
endif

; there are other HDUs to read

hdr = mrdfits( file, 1, h, status=status, /unsigned,/silent)
if size(hdr,/type) eq 8 then keywords = {h0:keywords, h1:h}

if n_ext eq 1 then begin
    ; only 2 HDUs are in the file, create a structure to return
    if (size(tmp))[0] eq 0 then return,hdr 
    ; otherwise merge the  two structures together
    data={img:tmp}
    return,{data:data, hdr:hdr}
endif
; most of the time, EVE processing will already have returned



; there are more than 2 HDUs, we have to merge some of them

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



;initial values
status = 0L
;i = 0L
;count=0L

i=2L
count=2L ;try skipping to the next HDU after #1

datarec=replicate({img:tmp<0},n_rec)
struct={data:datarec,hdr:hdr}

; trying multi-HDU concatenation
while status ne mrdfits_eof and count lt n_ext-1 do begin
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
                count=count+1L
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
struct={data:temporary(struct.data[0:N_ELEMENTS(struct.data) - 1]),hdr:hdr}
;print,'finished trimming'
TVSCL, REBIN(struct.data.img, 1024, 512)
stop
if status eq mrdfits_eof then status = 0

return,struct ;tmp
end
