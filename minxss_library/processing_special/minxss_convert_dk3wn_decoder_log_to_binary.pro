;+
; NAME:
;   minxss_convert_dk3wn_decoder_log_to_binary
;
; PURPOSE:
;   Convert the .log file provided by PEOSAT's database of stored beacons from DK3WN's beacon decoder into a binary file. 
;   Those are the name's of two HAM radio operators in The Netherlands and Germany. Many HAM operators use their software.
;   We want it back in binary because our IDL routines are designed to read the binary from Hydra or James Paul Mason's 
;   beacon decoder software (an alternative to DK3WN's). 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   logFilename: The local path and filename for the .log file generated from PE0SAT's database. 
;                Default is getenv('minxss_data') + '/../ham_data_temp/DK3WN-PE0SAT_decoded.log'
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   No variables but saves a binary file to disk per day of data in the file in the same folder as input
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   minxss_convert_dk3wn_decoder_log_to_binary, logFilename = getenv('minxss_data') + '/data/ham_data/DK3WN-PE0SAT_20171201_decoded.log'
;
; MODIFICATION HISTORY:
;   2017-07-13: James Paul Mason: Wrote script.
;-
PRO minxss_convert_dk3wn_decoder_log_to_binary, logFilename = logFilename

; Defaults
IF logFilename EQ !NULL THEN BEGIN
  logFilename = getenv('minxss_data') + '/../ham_data_temp/DK3WN-PE0SAT_decoded.log'
ENDIF

; Read the file that was stored by DK3WN's decoder into PE0SAT's sql database
restore, getenv('minxss_data') + '/../ham_data_temp/DK3WN-PE0SAT_decoded_ascii_template.sav'
logFileString = read_ascii(logFilename, TEMPLATE = logFileAsciiTemplate)
receivedDate = strmid(logFileString.datetime, 0, 10) ; Discard the time and just keep the date
allDataString = logFileString.packetHex

; Loop through each day's recorded data
moreDaysToProcess = 1
dateIndex = 0
WHILE moreDaysToProcess DO BEGIN
  todayIndices = where(receivedDate EQ receivedDate[dateIndex], numTodayPackets)
  todayDataString = allDataString[todayIndices]
  
  ; Loop through each packet
  FOREACH packetString, todayDataString DO BEGIN
    ; Loop through each hex value and store as byte
    FOR byteIndex = 0, strlen(packetString) - 1, 2 DO BEGIN
      outputInteger = 0B
      reads, strmid(packetString, byteIndex, 2), outputInteger, FORMAT = '(Z)' 
      packetByte = packetByte EQ !NULL ? outputInteger : [packetByte, outputInteger] 
    ENDFOR
  ENDFOREACH
  
  ; Save day's data to a file and clear packetByte buffer
  inputPathAndFilename = ParsePathAndFilename(logFilename)
  path = inputPathAndFilename.path
  openw, lun, path + receivedDate[dateindex] + '_DK3WN-PE0SAT_decoded.dat', /GET_LUN
  writeu, lun, packetByte
  close, lun
  free_lun, lun
  packetByte = !NULL

  dateIndex += numTodayPackets
  IF dateIndex GT n_elements(allDataString) - 1 THEN BEGIN
    moreDaysToProcess = 0
  ENDIF
  
ENDWHILE

END