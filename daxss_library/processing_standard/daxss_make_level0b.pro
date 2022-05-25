;+
; NAME:
;   daxss_make_level0b.pro
;
; PURPOSE:
;   Reads InspireSat-1 Processed Level 0 files (csv format) and make Hydra-like binary file.
;   This reads Ground Station DAXSS and Beacon files and also SatNOGS beacon file.
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print out processing messages while running.
;
; OUTPUTS:
;   None.
;
; OPTIONAL OUTPUTS:
;   None.
;
; COMMON BLOCKS:
;   None.
;
; RESTRICTIONS:
;   Requires DAXSS processing suite and to be run on MinXSS Data Processing Computer (MacD3750)
;
; PROCEDURE:
;   1. Task 1: Find DAXSS and Beacon CSV Level 0 merged file on GoogleDrive
;   2. Task 2: Convert those data into binary data (byte array)
;   3. Write DAXSS Level 0b binary file (to be read by is1_daxss_beacon_read_packets.pro)
;
;
; EXAMPLE USAGE
; IDL> daxss_make_level0b, /verbose
;
; This is called by daxss_make_level0b using the use_csv_files option.
;
; HISTORY
; 2022-03-15  T. Woods, updated for IS-1 paths
; 2022-05-11  T. Woods, updated to also read the daxss_memdump CSV files
;
;+
PRO daxss_make_level0b, VERBOSE = VERBOSE, DEBUG=DEBUG

;  Defines
ARRAY_CHUNKS_BYTES = 100000L
MIN_BYTES = 12L  ; minimum number of bytes for CCSDS packet

;
;   1. Task 1: Find DAXSS and Beacon CSV Level 0 merged file on GoogleDrive
;
csv_path='/Users/minxss/My Drive (inspire.lasp@gmail.com)/IS1 On-Orbit Data/Processed data/Decoded_Packets_*/'
daxssFiles=file_search(csv_path, 'daxss_sci_level_0.csv', count=daxss_count)
daxssDumpFiles = file_search(csv_path, 'daxss_memdump_level_0.csv', count=daxss_dump_count)
beaconFiles=file_search(csv_path, 'beacon_level_0.csv', count=beacon_count)
; DsatNogsFiles=file_search(csv_path, 'inspire_satnogs*daxss_sci_level_0.csv', count=satnogs1_count)
BsatNogsFiles=file_search(csv_path, 'inspire_satnogs*beacon_level_0.csv', count=satnogs2_count)
if (daxss_count lt 1) or (beacon_count lt 1) then begin
  message, /info, 'ERROR finding InspireSat-1 CSV Processed Files !!!'
  return
endif
; get the most recent files
daxssFilesTime = dblarr(daxss_count)
for ii=0L,daxss_count-1 do daxssFilesTime[ii] = file_modtime( daxssFiles[ii] )
temp = max(daxssFilesTime,wmax)
theDaxssFile = daxssFiles[wmax]
if keyword_set(verbose) then message, /INFO, "Reading CSV file-1: " + theDaxssFile

daxssDumpFilesTime = dblarr(daxss_dump_count)
for ii=0L,daxss_dump_count-1 do daxssDumpFilesTime[ii] = file_modtime( daxssDumpFiles[ii] )
temp = max(daxssDumpFilesTime,wmax)
theDaxssDumpFile = daxssDumpFiles[wmax]
if keyword_set(verbose) then message, /INFO, "Reading CSV file-2: " + theDaxssDumpFile

beaconFilesTime = dblarr(beacon_count)
for ii=0L,beacon_count-1 do beaconFilesTime[ii] = file_modtime( beaconFiles[ii] )
temp = max(beaconFilesTime,wmax)
theBeaconFile = beaconFiles[wmax]
if keyword_set(verbose) then message, /INFO, "Reading CSV file-3: " + theBeaconFile

if (satnogs2_count ge 1) then begin
	; get the most recent file for Beacon packets
	satFileTime = dblarr(satnogs2_count)
	for ii=0L,satnogs2_count-1 do satFileTime[ii] = FILE_MODTIME(BsatNogsFiles[ii])
	temp = max(satFileTime, wmax)
	theSatNogsFile = BsatNogsFiles[wmax]
	if keyword_set(verbose) then message, /INFO, "Reading CSV file-4: " + theSatNogsFile
endif

;
;   2. Task 2: Convert those data into binary data (byte array)
;
bdata = bytarr(ARRAY_CHUNKS_BYTES)
bdata_total = ARRAY_CHUNKS_BYTES
bdata_length = 0L
str = ' '
if (satnogs2_count ge 1) then begin
	allFiles = [ theDaxssFile, theDaxssDumpFile, theBeaconFile, theSatNogsFile ]
endif else begin
	allFiles = [ theDaxssFile, theDaxssDumpFile, theBeaconFile ]
endelse
num_files = n_elements(allFiles)
bytes_files = lonarr(num_files)

for k=0,num_files-1 do begin
  ;  process lines of CSV data from CSV file
  bytes_files[k] = bdata_length
  openr, lun, allFiles[k], /get_lun
  while not eof(lun) do begin
    readf,lun,str
    ; parse string into bytes
    str_numbers = STRSPLIT( str, " ,", /extract, count=num_bytes )
    if (num_bytes ge MIN_BYTES) then begin
      if (bdata_length + num_bytes) gt bdata_total then begin
        ; expand bdata for more bytes
        bdata = [ bdata, bytarr(ARRAY_CHUNKS_BYTES) ]
        bdata_total += ARRAY_CHUNKS_BYTES
      endif
      bdata[bdata_length:bdata_length+num_bytes-1] = byte(uint(str_numbers))
      bdata_length += num_bytes
    endif
  endwhile
  close, lun
  free_lun, lun
  bytes_files[k] = bdata_length - bytes_files[k]
  if keyword_set(verbose) then message, /INFO, 'Processed '+strtrim(bytes_files[k],2)+$
      ' bytes for file '+allFiles[k]
endfor

;
;   3. Write DAXSS Level 0b binary file
;
if (bdata_length gt 0) then begin
  flightModelString = 'fm3'   ; changed from FM4 to FM3 on 5/24/2022, TW
  out_path = getenv('minxss_data')+path_sep()+flightModelString+path_sep()+'level0b'+path_sep()
  out_file = 'daxss_l0b_csv_merged.bin'
  fullFilename = out_path + out_file

  IF keyword_set(verbose) THEN message, /INFO, 'Saving ' + strtrim(bdata_length,2) + $
      ' bytes of data for DAXSS Level 0b packets into ' + fullFilename

  openw, lun, fullFilename, /get_lun
  adata = assoc(lun, bytarr(bdata_length))
  adata[0] = bdata[0:bdata_length-1]
  close, lun
  free_lun, lun
endif else begin
  if keyword_set(verbose) then message, /INFO, 'ERROR finding any IS-1 / DAXSS data to save for Level 0b.'
endelse

if keyword_set(debdaug) then stop, 'DEBUG at end of daxss_make_level0b...'
;  clear memory
bdata = 0L

return
end

