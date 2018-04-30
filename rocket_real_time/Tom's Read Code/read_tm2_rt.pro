;
;   read_tm2_rt.pro
;
;   Read NSROC 36.205 TM2 Real-Time (RT) data files (packets saved from DataView)
;     CCD Data at 10 Mbps
;
;   Extract out data from TM2
;
;   INPUT
;     filename     filename of 36233*.bin or not given or '' to ask user to select file
;
;     launchtime=launchtime       time (SOD) for T-0   (or first time in file if not given)
;
;   SAME output format as read_tm2_cd.pro so that other supporting (plot) procedures will also work
;   DIFFERENCE between CD and RealTime is the time format and X_rt = X_cd - 2
;
;   10/20/06
;   Tom Woods
;
pro  read_tm2_rt, filename, launchtime=launchtime, time=time, $
              classic=classic, amegs=amegs, bmegs=bmegs, rocket=rocket

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick TM#2 DataView Raw Dump File', filter='Raw*TM2_*')
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

;
;  open the TM#2 Data file
;   Record is 82 words (164 bytes) x 3 rows
;
;   NOTE:  words have bytes flipped for MAC but code written for any computer
;
openr,lun, filename, /get_lun

fb1 = rstrpos( filename, '/' )
if (fb1 lt 0) then fb1 = -1L
fb2 = rstrpos( filename, '.' )
if (fb2 lt 0) then fb2 = strlen(filename)
fbase = strmid( filename, fb1+1, fb2-fb1-1 ) + '_'

if keyword_set(rocket) then rnum = rocket else rnum = 36.240
if (rnum ne 36.240) and (rnum ne 36.233) then begin
  print, 'ERROR: rocket number is not valid, resetting to 36.240'
  rnum = 36.240
endif
print, 'Processing for rocket # ', string(rnum,format='(F7.3)')

if not keyword_set(launchtime) then launchtime=0
fpos = strpos( filename, 'flight' )
if (not keyword_set(launchtime)) and (fpos gt 0) then begin
  if (rnum eq 36.217) then launchtime = 12*3600L + 23*60L + 30   ;  MDT instead of UT for RT data
  if (rnum eq 36.240) then launchtime = 10*3600L + 58*60L + 0 
  print, 'NOTE:  set launch time for ', strtrim(launchtime,2), ' sec of day'
endif

ncol = 82L
nrow = 3L
nbytes = ncol*2L * nrow     ; sync_1 + sync_2 + sfid + mid + 78 words of data

ntotal = ncol * nrow

ntime = 2L                 ; DataView time is 4-bytes of milliseconds of time
packetrate = ntotal * 16L / 10.D6   ; number_words * 16_bits / bit_rate ==> sec per packet

;
;   define constants / arrays for finding sync values
;
wordmask = 'FFFF'X   ; don't need to mask
sync1value = 'FE6B'X
sync1offset = 0L

sync2value = '2840'X
sync2offset = 1L

;
;   DataView can have 4-byte (long) time word at end of each packet
;   so have to determine which type format by examining for Sync words
;
atest = assoc( lun, uintarr(ntotal+ntime*2L+(sync1offset+1L)*2L) )
dtest = atest[0]
swap_endian_inplace, dtest, /swap_if_big_endian     ; only MACs will flip bytes
if ((dtest[sync1offset] and wordmask) eq sync1value) and $
    ((dtest[sync1offset+ntotal] and wordmask) eq sync1value) then begin
  print, 'WARNING: assuming constant TIME rate for these packets'
  hasTime = 0L
  a = assoc( lun, uintarr(ncol,nrow) )
endif else if ((dtest[sync1offset] and wordmask) eq sync1value) and $
    ((dtest[sync1offset+ntotal+ntime] and wordmask) eq sync1value) then begin
  hasTime = 1L
  a = assoc( lun, uintarr(ntotal+ntime) )
  nbytes = nbytes + ntime*2L  ; make file record longer
endif else begin
  print, 'ERROR: could not find SYNC with or without TIME in these packets'
  close,lun
  free_lun,lun
  return
endelse

;
;   set up arrays to help with finding sync / time
;
nint = nbytes/2L

finfo = fstat(lun)
fsize = finfo.size
pcnt = fsize/nbytes
print, ' '
print, 'READ_TM2_RT:  ',strtrim(pcnt,2), ' records in ', filename
print, ' '
print, 'WARNING:  TM data from DataView is incomplete - use READ_TM2_CD for full data set.'
print, ' '

acnt = 0L
aindex=ulong(lonarr(pcnt))
atime = dblarr(pcnt)

pcnt10 = pcnt/10L

;
;   find first valid time
;
for k=0L,pcnt-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) then begin
    if (hasTime ne 0) then begin
      time1 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
      time1 = time1 / 1000.D0   ; convert millisec to sec
    endif else begin
      time1 = k * packetrate
    endelse
    goto, gottime1
  endif
endfor

gottime1:
print, ' '
timetemp = time1
hr = fix(timetemp/3600.)
min = fix((timetemp-hr*3600.)/60.)
sec = fix(timetemp-hr*3600.-min*60.)
print, 'Start Time = ', strtrim(hr,2), ':', strtrim(min,2), ':', strtrim(sec,2), ' at T ',strtrim(timetemp-launchtime,2)

;
;   find last valid time
;
for k=pcnt-1L,0L,-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) then begin
    if (hasTime ne 0) then begin
      time2 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
      time2 = time2 / 1000.D0   ; convert millisec to sec
    endif else begin
      time2 = k * packetrate
    endelse
    goto, gottime2
  endif
endfor

gottime2:
print, ' '
timetemp = time2
hr = fix(timetemp/3600.)
min = fix((timetemp-hr*3600.)/60.)
sec = fix(timetemp-hr*3600.-min*60.)
print, 'Stop  Time = ', strtrim(hr,2), ':', strtrim(min,2), ':', strtrim(sec,2), ' at T ',strtrim(timetemp-launchtime,2)
print, ' '

if keyword_set(time) then begin
  dtime = (time2-time1)/pcnt
  kstart = long( (time[0] - (time1 - launchtime)) / dtime )
  if (kstart lt 0) then kstart = 0L
  if (kstart ge pcnt) then kstart = pcnt-1
  if n_elements(time) lt 2 then kend = pcnt-1L else begin
    kend = long( (time[1] - (time1 - launchtime)) / dtime )
    if (kend lt 0) then kend = 0L
    if (kend ge pcnt) then kend = pcnt-1
  endelse
  if (kstart gt kend) then begin
    ktemp = kend
    kend = kstart
    kstart = ktemp
  endif
  timestr = strtrim(long(time[0]),2) + '_' + strtrim(long(time[1]),2) + '_'
endif else begin
  kstart = 0L
  kend = pcnt-1L
  timestr = ''
endelse

;
;   set up files / variables
;
fbase = fbase + timestr
fend = '.dat'

if keyword_set(classic) then begin
  fclassic = fbase + 'classic' + fend
  print, 'Saving CLASSIC images in ', fclassic
  cnumx = 1066L
  cnumy = 1064L
  classic1 = { time: 0.0D0, pixelerror: 0L, integbits: 0, buffer: 0, image: uintarr(cnumx,cnumy) }
  openw,clun,fclassic,/get_lun
  ca = assoc(clun,classic1)
  cacnt = 0L
  cfidmask = '03F8'X
  cfidvalue = '01B8'X
  cwcnt = 0L
  cwtotal = cnumx*cnumy*4L
  cwords = uintarr(cwtotal)
  coferr = 0L
  cxy = [6,0,1,1,12,0]   ; for CD
  cxy = [4,0,1,1,12,0]   ; for RT (DataView)
  ;ctcnt = 0L
  ;ctemp = cwords
  ;ctmax = n_elements(ctemp)
endif
if keyword_set(amegs) then begin
  famegs = fbase + 'amegs' + fend
  print, 'Saving MEGS-A images in ', famegs
  mnumx = 2048L
  mnumy = 1024L
  amegs1 = { time: 0.0D0, pixelerror: 0L, image: uintarr(mnumx,mnumy) }
  openw,alun,famegs,/get_lun
  aa = assoc(alun,amegs1)
  aacnt = 0L
  mfidvalue1 = 'FFFF'X
  mfidvalue2 = 'AAAA'X
  awcnt = 0L
  awtotal = mnumx*mnumy*2L
  awords = uintarr(awtotal)
  aoferr = 0L
  axy = [18,0,2,1,33,0]     ; for CD
  axy = [16,0,2,1,33,0]     ; for RT (DataView)
endif
if keyword_set(bmegs) then begin
  fbmegs = fbase + 'bmegs' + fend
  print, 'Saving MEGS-B images in ', fbmegs
  mnumx = 2048L
  mnumy = 1024L
  bmegs1 = { time: 0.0D0, pixelerror: 0L, image: uintarr(mnumx,mnumy) }
  openw,blun,fbmegs,/get_lun
  ba = assoc(blun,bmegs1)
  bacnt = 0L
  mfidvalue1 = 'FFFF'X
  mfidvalue2 = 'AAAA'X
  bwcnt = 0L
  bwtotal = mnumx*mnumy*2L
  bwords = uintarr(bwtotal)
  boferr = 0L
  bxy = [19,0,2,1,33,0]     ; for CD
  bxy = [17,0,2,1,33,0]     ; for RT (DataView)
endif

kfullcnt = kend - kstart;
print, 'Reading ', strtrim(kfullcnt,2), ' records...'

;
;   read all of the data and get the TIME
;     TIME_millisec:  [(((byte 5) & 0xF0) << 9) + (byte 3) << 8 + (byte 2) ] * 1000. +
;          [ ((byte 5) & 0x03) << 8 + (byte 4) ] +
;          [ ((byte 7) & 0x03) << 8 + (byte 6) ] / 1000.
;
for k=kstart,kend do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian       ; only MACs will flip bytes

  if ((data[sync1offset] and wordmask) eq sync1value) and $
         ((data[sync2offset] and wordmask) eq sync2value) then begin

    if (hasTime ne 0) then begin
      atime[acnt] = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
      atime[acnt] = atime[acnt] / 1000.D0   ; convert millisec to sec
      ;  restructure data into ncol x nrow (without time)
      data = reform( data[0:ntotal-1], ncol, nrow )
    endif else begin
      atime[acnt] = k * packetrate
    endelse
    aindex[acnt] = k

    if keyword_set(amegs) then begin
      if (awcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, axy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, agotfid
        goto, anotyet
agotfid:
       nw = jend-jj
        awords[awcnt:awcnt+nw-1] = temp[jj:jend-1]
        awcnt = awcnt + nw
        amegs1.time = atime[acnt]   ; save time of the fiducial (in sec)
anotyet:
       ; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, axy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, agotfid2
        if ((awcnt+jend) lt awtotal) then begin
          awords[awcnt:awcnt+jend-1] = temp
          awcnt = awcnt + jend
        endif else begin
          jmax = awtotal - awcnt - 1L
          if (jmax ge 0) then begin
            awords[awcnt:awcnt+jmax] = temp[0:jmax]
            awcnt = awcnt + jmax
          endif
          aoferr = aoferr + jend - jmax + 1L
        endelse
        goto, anotyet2
agotfid2:
        if (aoferr ne 0) then begin
          print, 'WARNING: ', strtrim(aoferr,2), ' words thrown away for MEGS-A @ ',strtrim(amegs1.time,2)
          aoferr = 0L     ;  reset overflow flag
        endif
       nw = jj
       if (jj gt 0) and ((awcnt+jj) le awtotal) then begin
          awords[awcnt:awcnt+jj-1] = temp[0:jj-1]
          awcnt = awcnt + nw
        endif
        ; check for valid image (and not just series of 'FFFF'X data)
        if (awords[1] ne mfidvalue2) then begin
          ; print, 'ERROR finding valid image, skipping it...'
          awcnt = 0L
          goto, anotyet2
        endif
        ;  process the data stream into MEGS image
        amegs1.image = megs_raw2image( awords, awcnt, amegs1.time, pixelerror=aerr )
        amegs1.pixelerror = aerr
        ;  save the record
        ; if (aacnt eq 0) then stop, 'Check out first MEGS-A image...'
        aa[aacnt] = amegs1
        aacnt = aacnt + 1L
        ;  start new image stream
        awcnt = 0L
       nw = jend-jj
        awords[awcnt:awcnt+nw-1] = temp[jj:jend-1]
        awcnt = awcnt + nw
        amegs1.time = atime[acnt]   ; save time of the fiducial (in sec)
anotyet2:
       ; read some more data
      endelse
    endif

     if keyword_set(bmegs) then begin
      if (bwcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, bxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, bgotfid
        goto, bnotyet
bgotfid:
       nw = jend-jj
        bwords[bwcnt:bwcnt+nw-1] = temp[jj:jend-1]
        bwcnt = bwcnt + nw
        bmegs1.time = atime[acnt]   ; save time of the fiducial (in sec)
bnotyet:
       ; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, bxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, bgotfid2
        if ((bwcnt+jend) lt bwtotal) then begin
          bwords[bwcnt:bwcnt+jend-1] = temp
          bwcnt = bwcnt + jend
        endif else begin
          jmax = bwtotal - bwcnt - 1L
          if (jmax ge 0) then begin
            bwords[bwcnt:bwcnt+jmax] = temp[0:jmax]
            bwcnt = bwcnt + jmax
          endif
          boferr = boferr + jend - jmax + 1L
        endelse
        goto, bnotyet2
bgotfid2:
        if (boferr ne 0) then begin
          print, 'WARNING: ', strtrim(boferr,2), ' words thrown away for MEGS-B @ ',strtrim(bmegs1.time,2)
          boferr = 0L     ;  reset overflow flag
        endif
       nw = jj
       if (jj gt 0) and ((bwcnt+jj) le bwtotal) then begin
          bwords[bwcnt:bwcnt+jj-1] = temp[0:jj-1]
          bwcnt = bwcnt + nw
        endif
        ; check for valid image (and not just series of 'FFFF'X data)
        if (bwords[1] ne mfidvalue2) then begin
          ; print, 'ERROR finding valid image, skipping it...'
          bwcnt = 0L
          goto, bnotyet2
        endif
        ;  process the data stream into MEGS image
        bmegs1.image = megs_raw2image( bwords, bwcnt, bmegs1.time, pixelerror=berr )
        bmegs1.pixelerror = berr
        ;  save the record
        ; if (bacnt eq 0) then stop, 'Check out first MEGS-B image...'
        ba[bacnt] = bmegs1
        bacnt = bacnt + 1L
        ;  start new image stream
        bwcnt = 0L
       nw = jend-jj
        bwords[bwcnt:bwcnt+nw-1] = temp[jj:jend-1]
        bwcnt = bwcnt + nw
        bmegs1.time = atime[acnt]   ; save time of the fiducial (in sec)
bnotyet2:
       ; read some more data
      endelse
    endif

     if keyword_set(classic) then begin
      if (cwcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, cxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if ((temp[jj] and cfidmask) eq cfidvalue) then goto, cgotfid
        ;ctemp[ctcnt:ctcnt+jend-1]=temp
        ;ctcnt=ctcnt+jend
        ;if (ctcnt ge (ctmax-jend*2)) then begin
        ;  stop, 'ERROR:  can not find CLASSIC sync - debug "ctemp"...'
        ;  ctcnt = 0L
        ;endif
        goto, cnotyet
cgotfid:
       nw = jend-jj
        cwords[cwcnt:cwcnt+nw-1] = temp[jj:jend-1]
        cwcnt = cwcnt + nw
        classic1.time = atime[acnt] ; save time of the fiducial (in sec)
        classic1.integbits = temp[jj] and '0003'X
        classic1.buffer = (temp[jj] and '0004'X) / 4L
cnotyet:
       ; read some more data
      endif else begin
        ; store data until see next fiducial
        temp = extract_item( data, cxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if ((temp[jj] and cfidmask) eq cfidvalue) then goto, cgotfid2
        if ((cwcnt+jend) lt cwtotal) then begin
          cwords[cwcnt:cwcnt+jend-1] = temp
          cwcnt = cwcnt + jend
        endif else begin
          jmax = cwtotal - cwcnt - 1L
          if (jmax ge 0) then begin
            cwords[cwcnt:cwcnt+jmax] = temp[0:jmax]
            cwcnt = cwcnt + jmax
          endif
          coferr = coferr + jend - jmax + 1L
        endelse
        goto, cnotyet2
cgotfid2:
        if (coferr ne 0) then begin
          print, 'WARNING: ', strtrim(coferr,2), ' words thrown away for CLASSIC @ ',strtrim(classic1.time,2)
          coferr = 0L     ;  reset overflow flag
        endif
       nw = jj
       if (jj gt 0) and ((cwcnt+jj) le cwtotal) then begin
          cwords[cwcnt:cwcnt+jj-1] = temp[0:jj-1]
          cwcnt = cwcnt + nw
        endif
        ;  process the data stream into CLASSIC image
        classic1.image = classic_raw2image( cwords, cwcnt, classic1.time, pixelerror=cerr )
        classic1.pixelerror = cerr
        ;  save the record
        ; if (cacnt eq 0) then stop, 'Check out first CLASSIC image in "classic1" ...'
        ca[cacnt] = classic1
        cacnt = cacnt + 1L
        ;  start new image stream
        cwcnt = 0L
       nw = jend-jj
        cwords[cwcnt:cwcnt+nw-1] = temp[jj:jend-1]
        cwcnt = cwcnt + nw
        classic1.time = atime[acnt] ; save time of the fiducial (in sec)
        classic1.integbits = temp[jj] and '0003'X
        classic1.buffer = (temp[jj] and '0004'X) / 4L
cnotyet2:
       ; read some more data
      endelse
    endif

    acnt = acnt + 1L
  endif

  if (k mod pcnt10) eq 0 then begin
    ; stop, 'Stopped  @ ' + strtrim(long(k/pcnt10)*10,2) + ' %...'
    print, '  @ ' + strtrim(long(k/pcnt10)*10,2) + ' %...'
  endif
endfor

if (acnt lt kfullcnt) then begin
  print, ' '
  print, 'READ_TM2_RT FILE ERROR: only ',strtrim(acnt,2), ' good records found'
  print, '    Expected ', strtrim(kfullcnt,2), ' records.'
endif

if (acnt ne pcnt) then begin
  atime=atime[0:acnt-1]
  aindex=aindex[0:acnt-1]
endif

;
;   close original file now
;   and all of the open output files
;
close, lun
free_lun, lun

ans = 'Y'
if keyword_set(classic) then begin
  close, clun
  free_lun, clun
  print, ' '
  print, strtrim(cacnt,2), ' CLASSIC images saved.'
  read, 'Show CLASSIC image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_classic, fclassic
endif
if keyword_set(amegs) then begin
  close, alun
  free_lun, alun
  print, ' '
  print, strtrim(aacnt,2), ' MEGS-A images saved.'
  read, 'Show MEGS-A image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_megs, famegs, 'A', info=ainfo
endif
if keyword_set(bmegs) then begin
  close, blun
  free_lun, blun
  print, ' '
  print, strtrim(bacnt,2), ' MEGS-B images saved.'
  read, 'Show MEGS-B image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_megs, fbmegs, 'B', info=binfo
endif

; stop, 'Check out results ...'

return
end
