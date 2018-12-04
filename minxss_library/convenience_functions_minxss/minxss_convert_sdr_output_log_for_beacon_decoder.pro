;+
; NAME:
;   minxss_convert_sdr_output_log_for_beacon_decoder
;
; PURPOSE:
;   Wengang's software defined radio outputs decoded hex values. 
;   This code takes that and converts it into a format consistent with the python MinXSS beacon decoder example_data.py. 
;
; INPUTS:
;   sdrOutput [.txt file]: Just a copy/paste of the log output into a .txt file
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   hexFormatted [string]: The hex reformatted for compatbility wth the python MinXSS beacon decoder. Copy/paste this into example_data.py.
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   minxss_convert_sdr_output_log_for_beacon_decoder, path + 'sdr_output.txt'
;
; MODIFICATION HISTORY:
;   2018-12-03: James Paul Mason: Wrote script.
;-
PRO minxss_convert_sdr_output_log_for_beacon_decoder, sdrOutput

; Default
IF NOT keyword_set(sdrOutput) THEN BEGIN
  sdrOutput = '/Users/jmason86/Desktop/beacons/tom_all.txt'
ENDIF

; Open the file
openr, lun, sdrOutput, /GET_LUN

; Read one line at a time, adding to the full hex packet string
hexFormatted = ''
line = ''
WHILE NOT eof(lun) DO BEGIN
  readf, lun, line
  
  ; Ignore comment lines
  IF strmatch(line, '*PDU*', /FOLD_CASE) OR strmatch(line, '*contents*') OR strmatch(line, '*()*') OR strmatch(line, '*\**') THEN BEGIN
    CONTINUE
  ENDIF
  
  ; Remove line numbers 
  line = strmid(line, 6)
  
  ; Add in the 0x for hex
  line = '0x' + STRJOIN(STRSPLIT(line, /EXTRACT), ', 0x') + ', '
  
  ; Concatenate
  hexFormatted = hexFormatted + line
  
  ; Detect end of packet and print
  IF strmatch(hexFormatted, '*0xa5, 0xa5*') THEN BEGIN
    
    ; Add the KISS 0xC0 header/trailer back in
    hexFormatted = '0xc0, ' + hexFormatted + '0xc0'
    
    ; Print the formatted hex 
    print, ''
    print, 'Here is a packet:' 
    print, hexFormatted
    
    ; Reset in case there are more packets in this file
    hexFormatted = ''
  ENDIF
  
ENDWHILE

free_lun, lun

END