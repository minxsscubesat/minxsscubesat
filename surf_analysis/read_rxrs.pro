;+
; NAME:
;	read_rxrs
;
; PURPOSE:
;	read rocket XRS data saved by DataView and using rocket XRS MCU
;
; CATEGORY:
;	SURF / lab procedure for quick look purpose
;
; CALLING SEQUENCE:  
;	data_packets = read_rxrs( filename )
;
; INPUTS:
;	filename		Filename (can include directory path too)
;					If not given, then ask user to select file
;
; OUTPUTS:  
;	data_packets	Structure array with format of:
;					{ time: 0.D0, type: 0, raw: lonarr(MAX_NUM), value: fltarr(MAX_NUM) }
;					where MAX_NUM = 6
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.  Open file
;	3.  Read and process one line of text from data file
;
;	Expect four types of packets:
;		TIME    >T #    #=(F10) for Time (GPS seconds)
;		ASIC	>Dn= # # # # # # <CR><LF>  #=(F8) for Detector Signal (DN), n=1 or 2
;	   ANALOG  >B= # # # # # # <CR><LF>  #=(F5) for 5V, ADC-Temp, A-1 Temp, A-2 Temp, B Temp
;	   CAL DAC >DAC1 #   #=(F6): 0-1023 possible
;	   OFFSET  >Offsets#n: # # # # # #    #=(F6) and n=1 or 2
;
;	Packet Types:
;			1	D1
;			2	D2
;			3	B
;			4	DAC1
;			5	Offsets#1
;			6	Offsets#2
;
;	4.  Close file and exit
;
; MODIFICATION HISTORY:
;	12/22/09		Tom Woods	Original file creation
;
;+

function read_rxrs, filename, debug=debug

;
;	1.  Check input parameters
;		If none given, then ask user to select file
;
if (n_params() lt 1) then begin
  filename = dialog_pickfile( filter='XRS*' )  
endif

fsize = size(filename)
if (total(fsize) eq 0) then begin
  filename=' '
  filename = dialog_pickfile( filter='XRS*' )  
endif

if (strlen(filename) lt 2) then begin
  filename = dialog_pickfile( filter='XRS*' )  
endif

;
;	2.  Open file
;
openr, lun, filename, /get_lun

;
;	3.  Read and process one line of text from data file
;		Define packet types and then do while loop until EOF
;
MAX_NUM = 6
fstr = ' '
ftime = 0UL
tempdata = { time: 0.D0, type: 0, raw: lonarr(MAX_NUM), value: fltarr(MAX_NUM) }
data = -1

scnt = 0L
badcnt = 0L

;  TIME packet 
theader = ">T"
tlength = 12
thdrlen = strlen(theader)

;  data packets:  ASIC (detector), Analog monitors, DAC levels
;  aheader = string to identify header
aheader = [ ">D1=", ">D2=", ">B", ">DAC1 ", ">>Offsets#1:", ">>Offsets#2:" ]
;  alength = length of packet
alength =  [ 52, 52, 32, 16, 48, 48 ]
;  anum = number of values in packet
anum = [ 6, 6, 6, 2, 6, 6 ] < MAX_NUM
;  aword = string length of number
aword = [ 8, 8, 5, 5, 6, 6 ]
num_type = n_elements(anum)
;  ahdrlen = string length of header
ahdrlen = intarr(num_type)
for i=0,num_type-1 do ahdrlen[i] = strlen(aheader[i])

TEMPCOEFF = [130.55, -0.666922, 0.00215634, -4.1242D-6, 3.93294D-9, -1.47967D-12]

lasttime = dblarr(num_type)
lastdeltatime = dblarr(num_type)

while not eof(lun) do begin
  ; read string
  readf,lun,fstr	
  ; look for time packet
  tpos = strpos( fstr, theader )
  if (tpos ge 0) then begin
    pos2 = strpos( fstr, ">", tpos+2 )
    pos3 = strlen( fstr )
    if ( ((pos2-tpos) ge tlength) or ((pos3-tpos) ge tlength) ) then begin
    	ftime = ulong( strmid(fstr, tpos+2, tlength-thdrlen) )
    endif
  endif
  ;  look for data packets (check for each header string)
  gotOne = 0
  for i=0,num_type-1 do begin
   apos = strpos( fstr, aheader[i] )
   if (apos ge 0) then begin
     pos2 = strlen( fstr )
     if ((pos2-apos) ge alength[i]) then begin
        gotOne = 1
        tempdata.time = ftime
        tempdata.type = i + 1
        ;  track delta time for each type packet
        if (lasttime[i] ne 0) then deltatime = ftime - lasttime[i] else deltatime = 0.0
        lasttime[i] = ftime
    	for k=0,anum[i]-1 do begin
    	  tempdata.raw[k] = long( strmid(fstr, apos+ahdrlen[i]+k*aword[i], aword[i]) )
    	endfor
    	if (anum[i] le 5) then begin
    	  for k=anum[i],5 do begin
    	    tempdata.raw[k] = 0
    	    tempdata.value[k] = 0
    	  endfor
    	endif
    	if (i ge 0) and (i le 1) then begin
    	  ; convert to DN per second (assuming it is really integer seconds for integration)
    	  if (deltatime gt 40) or (deltatime lt 0) then begin
    	    ; error in time so reset counters
    	    deltatime = 0
    	    lasttime[i] = 0
    	    lastdeltatime[i] = 0
    	  endif
    	  ; force delatime to be 1, 3 9, or 30 sec
    	  if (deltatime le 2) then deltatime = 1.0 $
    	  else if (deltatime le 7) then deltatime = 3.0 $
    	  else if (deltatime le 21) then deltatime = 9.0 $
    	  else deltatime = 30.0
    	  ; use last deltatime has been disabled (so some 3 sec spikes get through)
    	  if (lastdeltatime[i] ne 0) then begin
    	  	; integration time (deltatime) is not more accurate than 1.0 sec
    	    ;if (abs(deltatime-lastdeltatime[i]) le 1.0) then deltatime = lastdeltatime[i]
    	  endif
    	  if (deltatime gt 0) then begin
    	    for k=0,anum[i]-1 do tempdata.value[k] = tempdata.raw[k] / deltatime
    	    lastdeltatime[i] = deltatime
    	  endif else begin
    	  	for k=0,anum[i]-1 do tempdata.value[k] = tempdata.raw[k] ; assume 1-sec deltatime
    	  endelse
    	endif else if (i eq 2) then begin
    	  ;  Analog packet convert
    	  tempdata.value[0] = tempdata.raw[0] * 0.00683		; 5V monitor
    	  tempdata.value[1] = tempdata.raw[1] * 0.25		; ADC temperature
    	  tempdata.value[5] = tempdata.raw[5] * 5.0/1023. ; Reference 2.5V temperature
    	  for k=2,4 do begin
    	    x = double(tempdata.raw[k])  ; convert to Temperature
    	    tempdata.value[k] = TEMPCOEFF[0]
    	    for j=1,5 do tempdata.value[k] = tempdata.value[k] + TEMPCOEFF[j] * (x^j)
    	  endfor
    	endif else if (i eq 3) then begin
    	  ;  DAC1 convert (DN to Volts)
    	  ; tempdata.value[0] = tempdata.raw[0] * 0.004881592 + 0.0034  ; CAL on 12/22/09
    	  tempdata.value[0] = tempdata.raw[0] * 0.004722  ; CAL on 1/10/10 for R-XRS MCU
     	  tempdata.value[1] = tempdata.raw[1] / 1000.  ; msec to sec
    	endif else begin
    	  ;  Offset-1 or 2 convert
    	  for k=0,anum[i]-1 do tempdata.value[k] = tempdata.raw[k]
    	endelse
    	if (scnt eq 0) then data = tempdata else data = [ data, tempdata ]
    	scnt = scnt + 1L
      endif
      break		; only allow one data packet per line
    endif
  endfor
  if (gotOne eq 0) then badcnt = badcnt + 1L
endwhile

;
;	4.  Close file and exit
;
close, lun
free_lun, lun

if keyword_set(debug) then print_stats = 1 else print_stats = 0
if (print_stats ne 0) then begin
  print, 'read_rxrs: ', strtrim(scnt,2), ' data records read'
  if (badcnt gt 0) then print, '    and ', strtrim(badcnt,2), ' bad (skipped) data lines'
endif

return, data
end
