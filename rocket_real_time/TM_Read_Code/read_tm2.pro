;
;	read_tm2.pro
;
;	Read NASA 36.318, 36.300, 36.290, 36.275, 36.258, 36.240, or 36.233 TM2 CD data files
;		CCD Data at 10 Mbps
;
;	Extract out data from TM2, keep all data once find fiducial after finding first fiducial
;
;	This "ALL" version just keeps MEGS-A and MEGS-B raw data
;
;	INPUT
;		filename		filename of 36240*.bin or not given or '' to ask user to select file
;
;		launchtime=launchtime		time (SOD) for T-0   (or first time in file if not given)
;
;	10/12/06
;	Tom Woods
;
;	Updated 10/13 for 36.290,   T. Woods
;
;	Usage:
;		!path = '/Users/Shared/Projects/Rocket_Folder/Data_36290/WSMR/code:' + !path
;		read_tm2_all_cd, file2, rocket=36.290, /amegs, /bmegs
;
;	Updated May 2016 to merge read_tm2_all_cd.pro and read_tm2_rt.pro
;		Just use the /CD option to read the CD log files, default is DataView Dump file (RT)
;
;	Updated June 2018 to process Compact SOLSTICE (CSOL) images (uses CLASSIC items)
;
pro  read_tm2, filename, cd=cd, launchtime=launchtime, time=time, $
					amegs=amegs, bmegs=bmegs, classic=classic, csol=csol, $
					rocket=rocket, debug=debug

;  new code to check for CD or RT file type
if keyword_set(cd) then begin
	fileRT = 0
	fileType = 'CD Raw Log File'
	fileFilter = 'LOGFILE*.*'
	ncol = 85L	; CD has 6 extra header bytes (3 words) for Time
	nrow = 3L
endif else begin
	fileRT = 1
	fileType = 'DataView Raw Dump File'
	fileFilter = 'Raw*TM2_*.*'
	ncol = 82L
	nrow = 3L
endelse

if (n_params() lt 1) then filename=''
if (strlen(filename) lt 1) then begin
  filename = dialog_pickfile(title='Pick TM#2 '+fileType, filter=fileFilter)
endif

if (strlen(filename) lt 1) then begin
  print, 'No filename was given...'
  return
endif

;
;	extract out file base name
;
dirslash = path_sep()  ; is it Mac ('/') or Windows ('\')
fb1 = rstrpos( filename, dirslash )
if (fb1 lt 0) then fb1 = -1L
fb2 = rstrpos( filename, '.' )
if (fb2 lt 0) then fb2 = strlen(filename)
fbase = strmid( filename, fb1+1, fb2-fb1-1 ) + '_'
;  just use the full input file name
fbase = filename + '_'

if keyword_set(rocket) then rnum = rocket else rnum = 36.336
if (rnum ne 36.336) and (rnum ne 36.318) and (rnum ne 36.300) and (rnum ne 36.290) and $
		(rnum ne 36.286) and (rnum ne 36.240) and (rnum ne 36.233) then begin
  print, 'ERROR: rocket number is not valid, resetting to 36.318'
  rnum = 36.336
endif
print, 'Processing for rocket # ', string(rnum,format='(F7.3)')

if not keyword_set(launchtime) then launchtime=0L
fpos = strpos( filename, 'flight' )
if (not keyword_set(launchtime)) and (fpos ge 0) then begin
  if (rnum eq 36.217) then launchtime = 12*3600L + 23*60L + 30  ; MDT instead of UT
  if (rnum eq 36.240) then launchtime = 10*3600L + 58*60L + 0
  if (rnum eq 36.258) then launchtime = 12*3600L + 32*60L + 2.00D0
  if (rnum eq 36.275) then launchtime = 11*3600L + 50*60L + 0.354D0
  if (rnum eq 36.286) then launchtime = 13*3600L + 30*60L + 1.000D0
  if (rnum eq 36.290) then launchtime = 12*3600L + 0*60L + 0.4D0
  if (rnum eq 36.300) then launchtime = 13*3600L + 14*60L + 25.1D0
  if (rnum eq 36.318) then launchtime = 19*3600L + 0*60L + 0.0D0
  if (rnum eq 36.336) then launchtime = 19*3600L + 0*60L + 0.0D0  ; TBD !!!
  print, 'NOTE:  set launch time for ', strtrim(launchtime,2), ' sec of day'
endif

nbytes = ncol*2L * nrow		; sync_1 + 3 words of time + sfid + mid + 78 words of data + sync_2
nint = nbytes/2L
ntotal = ncol * nrow

ntime = 2L                 ; DataView time is 4-bytes of milliseconds of time
packetrate = ntotal * 10L / 1.D6    ; number_words * 10_bits / bit_rate ==> sec per packet

RToffset = -2L		; offset between CD data and RT data for the "X" value

;
;	Define SYNC words
;
if keyword_set(CD) then begin
	wordmask = 'FFFF'X		; don't need to mask
	sync1value = '2840'X
	sync1offset = 0L

	sync2value = 'FE6B'X
	sync2offset = nint-1L
endif else begin
	wordmask = 'FFFF'X   ; don't need to mask
	sync1value = 'FE6B'X
	sync1offset = 0L

	sync2value = '2840'X
	sync2offset = 1L
endelse

;
;  open the TM CD Data file
;	Record is 85 words (170 bytes) x 3 rows
;
;	NOTE:  words have bytes flipped for MAC but code written for any computer
;
openr,lun, filename, /get_lun

if keyword_set(CD) then begin
	; Record for CD file
	a = assoc( lun, uintarr(ncol,nrow) )
endif else begin
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

endelse

finfo = fstat(lun)
fsize = finfo.size
pcnt = fsize/nbytes
print, ' '
print, 'READ_TM2:  ',strtrim(pcnt,2), ' records in ', filename
if not keyword_set(CD) then $
	print, ' WARNING:  DataView dumps are incomplete - use READ_TM2, /CD for complete data set.'

acnt = 0L
aindex=ulong(lonarr(pcnt))
atime = dblarr(pcnt)

pcnt10 = pcnt/10L

;
;	find first valid time
;
for k=0L,pcnt-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) then begin
  	if keyword_set(CD) then begin
      time1 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	  time1 = time1 / 1000.D0   ; convert msec to sec
  	endif else begin
  	  if (hasTime ne 0) then begin
        time1 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
        time1 = time1 / 1000.D0   ; convert millisec to sec
      endif else begin
        time1 = k * packetrate
      endelse
  	endelse
  	goto, gottime1
  endif
endfor

gottime1:
data1 = data
print, ' '
timetemp = time1
if (launchtime eq 0) then launchtime = time1   ;  set T+0 as start of file if launch time not given
hr = fix(timetemp/3600.)
min = fix((timetemp-hr*3600.)/60.)
sec = fix(timetemp-hr*3600.-min*60.)
print, 'Start Time = ', strtrim(hr,2), ':', strtrim(min,2), ':', strtrim(sec,2), ' at T ',strtrim(timetemp-launchtime,2)

;
;	find last valid time
;
for k=pcnt-1L,0L,-1L do begin
  data = a[k]
  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes
  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) then begin
  	if keyword_set(CD) then begin
      time2 = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	  time2 = time2 / 1000.D0   ; convert msec to sec
  	endif else begin
  	  if (hasTime ne 0) then begin
        time2 = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
        time2 = time2 / 1000.D0   ; convert millisec to sec
      endif else begin
        time2 = k * packetrate
      endelse
  	endelse
  	goto, gottime2
  endif
endfor

gottime2:
data2 = data
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
ktotal = kend - kstart + 1L

if keyword_set(debug) then stop, 'DEBUG first packet = data1 and last packet = data2 ...'

;
;	set up files / variables
;
fbase = fbase + timestr
fend = '.dat'

if arg_present(amegs) or keyword_set(amegs) then begin
  famegs = fbase + 'raw_amegs' + fend
  print, 'Saving MEGS-A images in ', famegs
  mnumx = 2048L
  mnumy = 1024L
  afirst = 0L
  atotal = mnumx * mnumy
  awmin = long((10.D6/16.)*(33./82.)*10.)
  amegs1 = { time: 0.0D0, numbuffer: 0L, buffer: uintarr(awmin) }
  openw,alun,famegs,/get_lun
  aa = assoc(alun,amegs1)
  aacnt = 0L
  mfidvalue1 = 'FFFF'X
  mfidvalue2 = 'AAAA'X
  awcnt = 0L
  axy = [18,0,2,1,33,0]
  if not keyword_set(CD) then begin
  	axy[0] = axy[0] + RToffset	; convert from CD to RT "X"
  endif
endif
if arg_present(bmegs) or keyword_set(bmegs) then begin
  fbmegs = fbase + 'raw_bmegs' + fend
  print, 'Saving MEGS-B images in ', fbmegs
  mnumx = 2048L
  mnumy = 1024L
  bfirst = 0L
  btotal = mnumx * mnumy
  bwmin = long((10.D6/16.)*(33./82.)*10.)
  bmegs1 = { time: 0.0D0, numbuffer: 0L, buffer: uintarr(bwmin) }
  openw,blun,fbmegs,/get_lun
  ba = assoc(blun,bmegs1)
  bacnt = 0L
  mfidvalue1 = 'FFFF'X
  mfidvalue2 = 'AAAA'X
  bwcnt = 0L
  bxy = [19,0,2,1,33,0]
  if not keyword_set(CD) then begin
  	bxy[0] = bxy[0] + RToffset	; convert from CD to RT "X"
  endif
endif
if (arg_present(classic) or keyword_set(classic)) and (rnum le 36.217) then begin
  cnumx = 1066L
  cnumy = 1064L
  classic1 = { time: 0.0D0, pixelerror: 0L, integbits: 0, buffer: 0, image: uintarr(cnumx,cnumy) }
  fclassic = fbase + 'classic' + fend
  print, 'Saving CLASSIC images in ', fclassic
  openw,clun,fclassic,/get_lun
  ca = assoc(clun,classic1)
  cacnt = 0L
  cfidmask = '03F8'X
  cfidvalue = '01B8'X
  cwcnt = 0L
  cwtotal = cnumx*cnumy*4L
  cwords = uintarr(cwtotal)
  coferr = 0L
  cxy = [6,0,1,1,12,0]
  ;ctcnt = 0L
  ;ctemp = cwords
  ;ctmax = n_elements(ctemp)
  if not keyword_set(CD) then begin
  	cxy[0] = cxy[0] + RToffset	; convert from CD to RT "X"
  endif
endif
if (arg_present(csol) or keyword_set(csol)) and (rnum eq 36.336) then begin
  csnumx = 2000L
  csnumy = 440L
  csnumy5 = long(csnumy/5L)
  csol_meta1 = { time_counter: 0L, temp_det0: 0.0, temp_det1: 0.0, temp_fpga: 0.0, mon_5v: 0.0, $
  				mon_current: 0.0, tec_enable: 0, led_enable: 0, integ_period: 0.0, $
  				sdcard_start: 0U, sdcard_address: 0U, error_code: 0U }
  csol1 = { time: 0.0D0, pixelerror: 0L, frameid: 0U, image: uintarr(csnumx,csnumy), $
  				metadata: csol_meta1 }
  fcsol = fbase + 'csol' + fend
  print, 'Saving CSOL images in ', fcsol
  openw,cslun,fcsol,/get_lun
  csa = assoc(cslun,csol1)
  csacnt = 0L
  csfidmask = 'FFFF'X
  csfidvalue1 = '5555'X
  csfidoffset1 = 0
  csfidvalue2 = 'A5A5'X
  csfidoffset2 = 1
  csfidvalue3 = '0000'X
  csfidoffset3 = 2
  cstemp_last = uintarr(6)
  csframeid = 0U
  cswcnt = 0L
  cswtotal = csnumx*csnumy*4L
  cswords = uintarr(cswtotal)
  csoferr = 0L
  csxy = [6,0,1,1,12,0]
  if not keyword_set(CD) then begin
  	cxy[0] = cxy[0] + RToffset	; convert from CD to RT "X"
  endif
endif

;  ********************************   READ DATA  ****************************
;
;	read all of the data and get the TIME
;		TIME_millisec:  [(((byte 5) & 0xF0) << 9) + (byte 3) << 8 + (byte 2) ] * 1000. +
;				[ ((byte 5) & 0x03) << 8 + (byte 4) ] +
;				[ ((byte 7) & 0x03) << 8 + (byte 6) ] / 1000.
;
;	2018:  Updated so Row 0 doesn't have to be first row in file
;
sfidxy = [4,0,0,1]
sfid_mask = '000F'X
if not keyword_set(CD) then sfidxy[0] = sfidxy[0] + RToffset	; convert from CD to RT "X"
data_last = a[kstart > 0? kstart-1 : kstart]
sfid_last = extract_item(data_last, sfidxy)

for k=kstart,kend do begin
  datanew = a[k]
  ;  2018: new make sure SFID is in right order
  sfid = extract_item(datanew, sfidxy)
  data = datanew
  if (sfid[0] and sfid_mask) ne 0 then begin
  	; file alignment is NOT OK for Row 0
  	; use data from data_last to start new data packet
  	for ii=0,nrow-1 do begin
  		if (sfid_last[ii] and sfid_mask) eq 0 then begin
  			; found Row 0
  			ii_last = nrow-ii-1
  			data[*,0:ii_last] = data_last[*,ii:nrow-1]
  			if (ii gt 0) then data[*,ii_last+1:nrow-1] = datanew[*,0:ii-1]
  			break
  		endif
  	endfor
  	if keyword_set(debug) then stop, 'DEBUG two data packet merging ...'
  endif
  ;  remember data for next packet read merging option
  data_last = datanew
  sfid_last = sfid

  swap_endian_inplace, data, /swap_if_big_endian		; only MACs will flip bytes

  if ((data[sync1offset] and wordmask) eq sync1value) and $
  			((data[sync2offset] and wordmask) eq sync2value) then begin
  	if keyword_set(CD) then begin
     atime[acnt] = (data[1,0] + ISHFT(ulong(data[2,0] and '8000'X),1)) * 1000.D0 $
  		+ (data[2,0] and '03FF'X) + (data[3,0] and '03FF'X) / 1000.D0
  	 atime[acnt] = atime[acnt] / 1000.	; convert msec to sec
  	 ; stop, 'STOP: DEBUG time ...'
  	 atime[acnt] = atime[acnt] - launchtime  ; convert to relative time
  	endif else begin
  	 if (hasTime ne 0) then begin
      atime[acnt] = (data[ntotal] + ISHFT(ulong(data[ntotal+1]),16))
      atime[acnt] = atime[acnt] / 1000.D0   ; convert millisec to sec
      ;  restructure data into ncol x nrow (without time)
      data = reform( data[0:ntotal-1], ncol, nrow )
     endif else begin
      atime[acnt] = k * packetrate
     endelse
  	endelse
  	aindex[acnt] = k

    if arg_present(amegs) or keyword_set(amegs) then begin
      if (afirst eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, axy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, agotfid
        goto, anotyet
agotfid:
		afirst = 1L
		nw = jend-jj
        amegs1.buffer[awcnt:awcnt+nw-1] = temp[jj:jend-1]
        awcnt = awcnt + nw
        amegs1.time = atime[acnt]	; save time of the fiducial (in sec)
anotyet:
		; read some more data
      endif else begin
        ; store data until fill buffer or find fiducial
        temp = extract_item( data, axy )
        jend = n_elements(temp)
        if (awcnt gt atotal) then begin
          ; check for fiducial
          gotfid = -1L
          for jj=0L,jend-1L do if (temp[jj] eq mfidvalue1) then gotfid = jj
          if (gotfid ge 0) then begin
            ; terminate buffer if found fiducial
            jmax = gotfid
            jmax2 = awmin - awcnt
            if (jmax2 lt jmax) then jmax = jmax2   ; buffer is full
            if (jmax gt 0) then begin
              amegs1.buffer[awcnt:awcnt+jmax-1] = temp[0:jmax-1]
              awcnt = awcnt + jmax
            endif
            ;  save the record
            amegs1.numbuffer = awcnt
            if keyword_set(debug) and (aacnt lt 2) then stop, 'Check out MEGS-A image...'
            aa[aacnt] = amegs1
            aacnt = aacnt + 1L
            ;  start new image stream
            awcnt = 0L
	        nw = jend - jmax
	        if (nw gt 0) then begin
              amegs1.buffer[awcnt:awcnt+nw-1] = temp[jmax:jend-1]
              awcnt = awcnt + nw
            endif
            amegs1.time = atime[acnt]	; save time of the record start (in sec)
          endif else if ((awcnt+jend) gt awmin) then begin
            ; terminate buffer if full
            jmax = awmin - awcnt
            if (jmax gt 0) then begin
              amegs1.buffer[awcnt:awcnt+jmax-1] = temp[0:jmax-1]
              awcnt = awcnt + jmax
            endif
            ;  save the record
            amegs1.numbuffer = awcnt
            if keyword_set(debug) and (aacnt lt 2) then stop, 'Check out MEGS-A image...'
            aa[aacnt] = amegs1
            aacnt = aacnt + 1L
            ;  start new image stream
            awcnt = 0L
	        nw = jend - jmax
	        if (nw gt 0) then begin
              amegs1.buffer[awcnt:awcnt+nw-1] = temp[jmax:jend-1]
              awcnt = awcnt + nw
            endif
            amegs1.time = atime[acnt]	; save time of the record start (in sec)
          endif else begin
            ; just stuff data into buffer
            amegs1.buffer[awcnt:awcnt+jend-1] = temp
            awcnt = awcnt + jend
          endelse
        endif else begin
          ; just stuff data into buffer
          amegs1.buffer[awcnt:awcnt+jend-1] = temp
          awcnt = awcnt + jend
        endelse
      endelse
  	endif

    if arg_present(bmegs) or keyword_set(bmegs) then begin
      if (bfirst eq 0L) then begin
        ; wait until see fiducial before storing data
        temp = extract_item( data, bxy )
        jend = n_elements(temp)
        for jj=0,jend-1 do if (temp[jj] eq mfidvalue1) then goto, bgotfid
        goto, bnotyet
bgotfid:
		bfirst = 1L
		nw = jend-jj
        bmegs1.buffer[bwcnt:bwcnt+nw-1] = temp[jj:jend-1]
        bwcnt = bwcnt + nw
        bmegs1.time = atime[acnt]	; save time of the fiducial (in sec)
bnotyet:
		; read some more data
      endif else begin
        ; store data until fill buffer or find fiducial
        temp = extract_item( data, bxy )
        jend = n_elements(temp)
        if (bwcnt gt btotal) then begin
          ; check for fiducial
          gotfid = -1L
          for jj=0L,jend-1L do if (temp[jj] eq mfidvalue1) then gotfid = jj
          if (gotfid ge 0) then begin
            ; terminate buffer if found fiducial
            jmax = gotfid
            jmax2 = bwmin - bwcnt
            if (jmax2 lt jmax) then jmax = jmax2   ; buffer is full
            if (jmax gt 0) then begin
              bmegs1.buffer[bwcnt:bwcnt+jmax-1] = temp[0:jmax-1]
              bwcnt = bwcnt + jmax
            endif
            ;  save the record
            bmegs1.numbuffer = bwcnt
            if keyword_set(debug) and (bacnt lt 2) then stop, 'Check out MEGS-B image...'
            ba[bacnt] = bmegs1
            bacnt = bacnt + 1L
            ;  start new image stream
            bwcnt = 0L
	        nw = jend - jmax
	        if (nw gt 0) then begin
              bmegs1.buffer[bwcnt:bwcnt+nw-1] = temp[jmax:jend-1]
              bwcnt = bwcnt + nw
            endif
            bmegs1.time = atime[acnt]	; save time of the record start (in sec)
          endif else if ((bwcnt+jend) gt bwmin) then begin
            ; terminate buffer if full
            jmax = bwmin - bwcnt
            if (jmax gt 0) then begin
              bmegs1.buffer[bwcnt:bwcnt+jmax-1] = temp[0:jmax-1]
              bwcnt = bwcnt + jmax
            endif
            ;  save the record
            bmegs1.numbuffer = bwcnt
            if keyword_set(debug) and (bacnt lt 2) then stop, 'Check out MEGS-B image...'
            ba[bacnt] = bmegs1
            bacnt = bacnt + 1L
            ;  start new image stream
            bwcnt = 0L
	        nw = jend - jmax
	        if (nw gt 0) then begin
              bmegs1.buffer[bwcnt:bwcnt+nw-1] = temp[jmax:jend-1]
              bwcnt = bwcnt + nw
            endif
            bmegs1.time = atime[acnt]	; save time of the record start (in sec)
          endif else begin
            ; just stuff data into buffer
            bmegs1.buffer[bwcnt:bwcnt+jend-1] = temp
            bwcnt = bwcnt + jend
          endelse
        endif else begin
          ; just stuff data into buffer
          bmegs1.buffer[bwcnt:bwcnt+jend-1] = temp
          bwcnt = bwcnt + jend
        endelse
      endelse
  	endif

     if (arg_present(classic) or keyword_set(classic)) and (rnum le 36.217) then begin
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
        classic1.time = atime[acnt]	; save time of the fiducial (in sec)
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
        classic1.time = atime[acnt]	; save time of the fiducial (in sec)
        classic1.integbits = temp[jj] and '0003'X
        classic1.buffer = (temp[jj] and '0004'X) / 4L
cnotyet2:
		; read some more data
      endelse
  	endif

     if (arg_present(csol) or keyword_set(csol)) and (rnum eq 36.336) then begin
      if (cswcnt eq 0L) then begin
        ; wait until see fiducial before storing data
        cstemp = extract_item( data, csxy )
        temp = [cstemp_last, cstemp]
        cstemp_last = cstemp
        jend = n_elements(temp)
        for jj=0,jend-3 do begin
        	if (temp[jj+csfidoffset1] eq csfidvalue1) and $
        		(temp[jj+csfidoffset2] eq csfidvalue2) and $
        		(temp[jj+csfidoffset3] eq csfidvalue3) then goto, csgotfid
        endfor
        ; stop, 'Debug CSOL temp search array ...'
        goto, csnotyet
csgotfid:
		; Found Row 0 of CSOL image
		; print, 'CSOL found SYNC for Row 0'
		nw = jend-jj
        cswords[cswcnt:cswcnt+nw-1] = temp[jj:jend-1]
        cswcnt = cswcnt + nw
        csol1.time = atime[acnt]	; save time of the fiducial (in sec)
		if (nw ge 4) then csol1.frameid = temp[jj+3]
		cstemp_last = uintarr(6)
csnotyet:
		; read some more data
      endif else begin
        ; store data until see next image fiducial
        cstemp = extract_item( data, csxy )
        if (cswcnt lt 4) and (n_elements(cstemp) gt 4) then csol1.frameid = cstemp[3-cswcnt]
        temp = [cstemp_last, cstemp]
        cstemp_last = cstemp
        jend = n_elements(temp)
        for jj=0,jend-3 do begin
        	if (temp[jj+csfidoffset1] eq csfidvalue1) and $
        		(temp[jj+csfidoffset2] eq csfidvalue2) and $
        		(temp[jj+csfidoffset3] eq csfidvalue3) then goto, csgotfid2
        endfor
        jend = n_elements(cstemp)
        if ((cswcnt+jend) lt cswtotal) then begin
          cswords[cswcnt:cswcnt+jend-1] = cstemp
          cswcnt = cswcnt + jend
        endif else begin
          jmax = cswtotal - cswcnt - 1L
          if (jmax ge 0) then begin
            cswords[cswcnt:cswcnt+jmax] = cstemp[0:jmax]
            cswcnt = cswcnt + jmax
          endif
          csoferr = csoferr + jend - jmax + 1L
        endelse
        goto, csnotyet2
csgotfid2:
		nw = jj
		if (jj gt 0) and ((cswcnt+jj) le cswtotal) then begin
          cswords[cswcnt:cswcnt+jj-1] = temp[0:jj-1]
          cswcnt = cswcnt + nw
        endif else csoferr = csoferr + nw
        if (csoferr ne 0) then begin
          print, 'WARNING: ', strtrim(csoferr,2), ' words thrown away for CSOL @ ',strtrim(csol1.time,2)
          csoferr = 0L     ;  reset overflow flag
        endif
        ;  process the data stream into CSOL image and meta data structure
        csol_raw2image, cswords, cswcnt, csol1
        ;  save the record
        ; if (csacnt eq 0) then stop, 'Check out first CSOL image in "csol1" ...'
        csa[csacnt] = csol1
        csacnt = csacnt + 1L
        ;  start new image stream
        cswcnt = 0L
		nw = jend-jj
        cswords[cswcnt:cswcnt+nw-1] = temp[jj:jend-1]
        cswcnt = cswcnt + nw
        csol1.time = atime[acnt]	; save time of the fiducial (in sec)
		if (nw ge 4) then csol1.frameid = temp[jj+3]
		cstemp_last = uintarr(6)
csnotyet2:
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

print, ' '
print, 'READ_TM2: processed ',strtrim(acnt,2), ' records'
print, '                 expected to process ', strtrim(ktotal,2)
if (acnt ne pcnt) then begin
  atime=atime[0:acnt-1]
  aindex=aindex[0:acnt-1]
endif

;
;	close original file now
;   and all of the open output files
;
close, lun
free_lun, lun

ans = 'Y'
if arg_present(amegs) or keyword_set(amegs) then begin
  close, alun
  free_lun, alun
  print, ' '
  print, strtrim(aacnt,2), ' MEGS-A images saved.'
  read, 'Show MEGS-A image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then begin
  	movie_raw_megs, famegs, 'A', 2, data=amegs
  	aSaveFile = fbase + 'image_amegs.sav'
  	print, 'Saving processed MEGS-A data (amegs) in ', aSaveFile
  	save, amegs, file=aSaveFile
  endif
endif
if arg_present(bmegs) or keyword_set(bmegs) then begin
  close, blun
  free_lun, blun
  print, ' '
  print, strtrim(bacnt,2), ' MEGS-B images saved.'
  read, 'Show MEGS-B image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then begin
  	movie_raw_megs, fbmegs, 'B', 2, data=bmegs
  	bSaveFile = fbase + 'image_bmegs.sav'
  	print, 'Saving processed MEGS-B data (bmegs) in ', bSaveFile
  	save, bmegs, file=bSaveFile
  endif
endif
if (arg_present(classic) or keyword_set(classic)) and (rnum le 36.217) then begin
  close, clun
  free_lun, clun
  print, ' '
  print, strtrim(cacnt,2), ' CLASSIC images saved.'
  read, 'Show CLASSIC image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_classic, fclassic
endif
if (arg_present(csol) or keyword_set(csol)) and (rnum eq 36.336) then begin
  close, cslun
  free_lun, cslun
  print, ' '
  print, strtrim(csacnt,2), ' CSOL images saved.'
  read, 'Show CSOL image movie (Y/N) ? ', ans
  ans = strupcase(strmid(ans,0,1))
  if (ans eq 'Y') then movie_csol, fcsol
endif

if keyword_set(debug) then stop, 'STOP: Check out results, atime, aindex, acnt ...'

return
end
