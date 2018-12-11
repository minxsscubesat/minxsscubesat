;+
; NAME:
;   minxss_read_sdr_log
;
; PURPOSE:
;   Wengang's software defined radio outputs decoded hex values. 
;   This code takes that and converts it into a format consistent with binary HYDRA output. 
;
; INPUTS:
;   input [.log file]: SDR output log -- Just a copy/paste of the log output into a .log (ASCII text) file
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   binaryData [bytes]: The binary representation of the ASCII output corresponding to MinXSS packets.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   minxss_read_sdr_log, path + 'sdr_output.log'
;
; MODIFICATION HISTORY:
;   2018-12-03: James Paul Mason: Wrote script.
;   2018-12-07: Amir Caspi: converted for use with MinXSS processing pipeline
;-
FUNCTION minxss_read_sdr_log, input, verbose=verbose

; Check inputs and get filename
if (n_params() lt 1) then begin
  print, 'USAGE: minxss_read_sdr_log, input_file, /verbose'
  input=' '
endif
IF size(input[0], /TYPE) EQ 7 THEN if (strlen(input) lt 2) then begin
  ; find file to read
  input = dialog_pickfile(/read, title='Select SDR log file to read', filter='sdr_log*')
  if (strlen(input) lt 2) then return, -1  ; user did not select file
endif

; Prep the array that will hold the full packet (as bytes)
binaryData = !NULL

; Store MinXSS AX.25 header used to determine MinXSS packet start
MinXSS_FM2_AX25_HEADER = '9a 92 9c b0 a6 64 60 86 a2 40 40 40 40 e1 03 f0'

; Open the file
openr, lun, input, /GET_LUN
IF keyword_set(verbose) THEN message, /info, "Opening file " + input

; Read the file, one line at a line, looking for MinXSS packet bytes...
line = ''
inPacket = 0
packetCounter = 0
WHILE NOT eof(lun) DO BEGIN

  ; Read a line
  readf, lun, line
  
  ; If the line matches the start of a MinXSS packet (based on AX.25 header), set a flag and increase packet counter
  IF stregex(line, '0000: ' + MinXSS_FM2_AX25_HEADER, /fold_case, /boolean) THEN BEGIN
    inPacket = 1
    packetCounter += 1
  ; Else, if the line doesn't match something in the middle of the packet, then UNSET the flag
  ; PACKET LINE EXAMPLE -- 0000: 84 86 a8 40 40 40 60 86 a6 92 9a 40 40 e1 03 f0
  ; Note: if we're in the middle of a non-MinXSS packet, this will be skipped, but that's fine!
  ENDIF ELSE IF NOT stregex(line, '[0-9a-f]{4}: ([0-9a-f]{2}[ ]?)+', /fold_case, /boolean) THEN inPacket = 0
  
  ; If we're in a MinXSS packet, then split the line into individual bytes, throw away the line number prefix (item 0)...
  ; Convert to actual bytes, and store in the full array
  ; (We do the conversion here, by line, rather than all at once later, because IDL is REALLY slow at concatenating string arrays...)
  IF inPacket THEN BEGIN
    individualBytes = (strsplit(line, ' ', /extract))[1:*]
    lineBytes = bytarr(n_elements(individualBytes))
    FOR i = 0, n_elements(lineBytes) - 1 DO BEGIN
      reads, individualBytes[i], theByte, format='(z)'
      lineBytes[i] = theByte
    ENDFOR
    binaryData = [temporary(binaryData), lineBytes]
  ENDIF
  ; Continue on to next line...

ENDWHILE ; reached EOF
free_lun, lun

IF keyword_set(verbose) THEN BEGIN
  message, /info, "Found " + strtrim(packetCounter,2) + " packets with " + strtrim(n_elements(binaryData),2) + " total bytes..."
ENDIF

; Now binaryData is a bytarr containing all MinXSS bytes from the SDR log. Return it!
return, binaryData

END