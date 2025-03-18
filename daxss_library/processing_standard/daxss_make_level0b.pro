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
;   merged_raw:    		Option to use 2024 merged Level 0 packet file instead of daily-produced files
;								This is used with the use_csv_file option.
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
; 2022-09-28  T. Woods, CSV_PATH name changed
; 2022-10-05  T. Woods, Added ADCS_CSS packets for DAXSS Level 0B-0C processing
; 2023-02-18  T. Woods, Added SD_HK packets for DAXSS Level 0B-0C processing
; 2023-10-06	T. Woods, updated to use Aug-28-2023 IS-1 Level 0 CSV file to recover the missing data
;					(issue is that daxss_sci_level_0.csv dropped from 307MB to 114MB on Aug-29-2023)
; 2023-10-06	T. Woods, archive GoogleDrive CSV files as "latest" onto dropbox_minxss
; 2024-02-02	T. Woods, added /merged_raw option to use the Indian new merged Level 0 packet file
;
;+
PRO daxss_make_level0b, merged_raw=merged_raw, VERBOSE = VERBOSE, DEBUG=DEBUG

;  Defines
ARRAY_CHUNKS_BYTES = 100000L
MIN_BYTES = 12L  ; minimum number of bytes for CCSDS packet

;
;   1. Task 1: Find DAXSS and Beacon CSV Level 0 merged file on GoogleDrive
;
; csv_path='/Users/minxss/My Drive (inspire.lasp@gmail.com)/IS1 On-Orbit Data/Processed data/Decoded_Packets_*/'
;  GoogleDrive Path Name changed on 9/28/2022
csv_root='/Volumes/GoogleDrive-102509592257659234307/My Drive/IS1 On-Orbit Data/Processed data/'
if (NOT file_test(csv_root,/directory)) then begin
	stop, '*** STOP: ERROR for IS1 CSV Directory in daxss_make_level0b...'
	return
endif

; new Feb 2, 2024 to use new data processing files that India generates
if keyword_set(MERGED_RAW) then begin
	csv_path = csv_root + 'Overall_data/Level 0 Packets/'
endif else begin
	csv_path = csv_root + 'Decoded_Packets_*/'
endelse

daxssFiles=file_search(csv_path, 'daxss_sci_level_0.csv', count=daxss_count)
daxssDumpFiles = file_search(csv_path, 'daxss_memdump_level_0.csv', count=daxss_dump_count)
beaconFiles=file_search(csv_path, 'beacon_level_0.csv', count=beacon_count)
cssFiles=file_search(csv_path, 'adcs_css_level_0.csv', count=css_count)
sdFiles=file_search(csv_path, 'sd_hk_level_0.csv', count=sd_count)

; DsatNogsFiles=file_search(csv_path, 'inspire_satnogs*daxss_sci_level_0.csv', count=satnogs1_count)
BsatNogsFiles=file_search(csv_path, 'inspire_satnogs*beacon_level_0.csv', count=satnogs2_count)
if (daxss_count lt 1) or (beacon_count lt 1) then begin
  message, /info, 'ERROR finding InspireSat-1 CSV Processed Files !!!'
  stop, '*** STOP: DEBUG daxss_make_level0b ....'
  return
endif
; get the most recent files
daxssFilesTime = dblarr(daxss_count)
for ii=0L,daxss_count-1 do daxssFilesTime[ii] = file_modtime( daxssFiles[ii] )
temp = max(daxssFilesTime,wmax)
theDaxssFile = daxssFiles[wmax]
if keyword_set(verbose) then message, /INFO, "Reading CSV file-1: " + theDaxssFile

if (daxss_dump_count gt 0) then begin
  daxssDumpFilesTime = dblarr(daxss_dump_count)
  for ii=0L,daxss_dump_count-1 do daxssDumpFilesTime[ii] = file_modtime( daxssDumpFiles[ii] )
  temp = max(daxssDumpFilesTime,wmax)
  theDaxssDumpFile = daxssDumpFiles[wmax]
  if keyword_set(verbose) then message, /INFO, "Reading CSV file-2: " + theDaxssDumpFile
endif else theDaxssDumpFile = ''

beaconFilesTime = dblarr(beacon_count)
for ii=0L,beacon_count-1 do beaconFilesTime[ii] = file_modtime( beaconFiles[ii] )
temp = max(beaconFilesTime,wmax)
theBeaconFile = beaconFiles[wmax]
if keyword_set(verbose) then message, /INFO, "Reading CSV file-3: " + theBeaconFile

;  new 10/5/2022:  add ADCS_CSS packets for DAXSS data processing
if (css_count gt 0) then begin
  cssFilesTime = dblarr(css_count)
  for ii=0L,css_count-1 do cssFilesTime[ii] = file_modtime( cssFiles[ii] )
  temp = max(cssFilesTime,wmax)
  theCssFile = cssFiles[wmax]
  if keyword_set(verbose) then message, /INFO, "Reading CSV file-4: " + theCssFile
endif else theCssFile = ''

;  new 2/18/2023:  add SD_HK packets for DAXSS data processing
if (sd_count gt 0) then begin 
  sdFilesTime = dblarr(sd_count)
  for ii=0L,sd_count-1 do sdFilesTime[ii] = file_modtime( sdFiles[ii] )
  temp = max(sdFilesTime,wmax)
  theSdFile = sdFiles[wmax]
  if keyword_set(verbose) then message, /INFO, "Reading CSV file-5: " + theSdFile
endif else theSdFile = ''

if (satnogs2_count ge 1) then begin
	; get the most recent file for SatNogs Beacon packets
	satFileTime = dblarr(satnogs2_count)
	for ii=0L,satnogs2_count-1 do satFileTime[ii] = FILE_MODTIME(BsatNogsFiles[ii])
	temp = max(satFileTime, wmax)
	theSatNogsFile = BsatNogsFiles[wmax]
	if keyword_set(verbose) then message, /INFO, "Reading CSV file-6: " + theSatNogsFile
endif else theSatNogsFile = ''

; if not keyword_set(MERGED_RAW) then begin  ; add these data for all cases (2/8/2024 T. Woods)
	;  new 10/6/2023:  add August-28-2023 CSV files that have the "missing" data
	dropbox_folder = getenv('minxss_data') + '/fm3/csv_files/Level0Packets_2023-08-28/'
	extraCSVfile1 = dropbox_folder+'beacon_level_0.csv'
	extraCSVfile2 = dropbox_folder+'daxss_sci_level_0.csv'
; endif

;
;   2. Task 2: Convert those data into binary data (byte array)
;
bdata = bytarr(ARRAY_CHUNKS_BYTES)
bdata_total = ARRAY_CHUNKS_BYTES
bdata_length = 0L
str = ' '

; changed on 02/02/2024 for the new MERGED_RAW option
if keyword_set(MERGED_RAW) then begin
	allFiles = [ theDaxssFile, theBeaconFile ] 
	if (strlen(theDaxssDumpFile) gt 1) then  allFiles = [ allFiles, theDaxssDumpFile ]
	if (strlen(theCssFile) gt 1) then        allFiles = [ allFiles, theCssFile ]
	if (strlen(theSdFile) gt 1) then         allFiles = [ allFiles, theSdFile ]
	if (strlen(theSatNogsFile) gt 1) then    allFiles = [ allFiles, theSatNogsFile ]
	if (strlen(extraCSVfile1) gt 1) then    allFiles = [ allFiles, extraCSVfile1 ]
	if (strlen(extraCSVfile2) gt 1) then    allFiles = [ allFiles, extraCSVfile2 ]
endif else begin
  allFiles = [ theDaxssFile, theBeaconFile ] 
  if (strlen(theDaxssDumpFile) gt 1) then  allFiles = [ allFiles, theDaxssDumpFile ]
  if (strlen(theCssFile) gt 1) then        allFiles = [ allFiles, theCssFile ]
  if (strlen(theSdFile) gt 1) then         allFiles = [ allFiles, theSdFile ]
  if (strlen(theSatNogsFile) gt 1) then    allFiles = [ allFiles, theSatNogsFile ]
  if (strlen(extraCSVfile1) gt 1) then    allFiles = [ allFiles, extraCSVfile1 ]
  if (strlen(extraCSVfile2) gt 1) then    allFiles = [ allFiles, extraCSVfile2 ]
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
  ; if keyword_set(verbose) then
  message, /INFO, 'Processed '+strtrim(bytes_files[k],2)+$
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

; new 10-06-2023:  archive the GoogleDrive files as "latest" onto minxss_dropbox
;  			slash for Mac = '/', PC = '\'
;  			File Copy for Mac = 'cp', PC = 'copy'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse
archive_path = getenv('minxss_data') + '/fm3/csv_files/archive_latest/'
append_name = ".latest"
if keyword_set(verbose) then print, 'Archiving recent IS-1 Level 0 CSV files to ', archive_path
;  don't copy over the two extra CSV files already on minxss_dropbox
for i=0L,n_elements(allFiles)-3L do begin
	pslash = strpos( allFiles[i], slash, /reverse_search)
	if (pslash ge 0) then archiveFile = strmid( allFiles[i], pslash+1, strlen(allFiles[i]) - pslash - 1) $
	else archiveFile = allFiles[i]
	archiveFile = archive_path + archiveFile + append_name
	copy_cmd = file_copy + '"' + allFiles[i] + '" "' +archiveFile + '"'
	spawn, copy_cmd, exit_status=status
endfor

if keyword_set(debdaug) then stop, 'DEBUG at end of daxss_make_level0b...'
;  clear memory
bdata = 0L

return
end

