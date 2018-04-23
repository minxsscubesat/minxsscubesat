;+
; NAME:
;   minxss_last_beacon
;
; PURPOSE:
;   Grab data from the last MinXSS-1 beacon
;
; INPUTS:
;   None -- hard-coded hex from HAM operator VK2FAK in Australia
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   hk [structure]: Returns the standard MinXSS housekeeping anonymous structure
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code base
;
; EXAMPLE:
;   hk = minxss_last_beacon()
;
; MODIFICATION HISTORY:
;   2017-05-08: James Paul Mason: Wrote script.
;-
FUNCTION minxss_last_beacon

; The packet in hex format (stores into an intarr)

lastBeacon = $
  ['86'x, 'A2'x, '40'x, '40'x, '40'x, '40'x, '60'x, '9A'x, '92'x, '9C'x, $
   'B0'x, 'A6'x, 'A6'x, 'E1'x, '03'x, 'F0'x, '08'x, '19'x, 'C6'x, '16'x, $
   '00'x, 'F7'x, '86'x, 'F9'x, '37'x, '46'x, '60'x, '01'x, '01'x, '00'x, $
   '4B'x, '00'x, 'BA'x, '00'x, 'C9'x, '00'x, '74'x, 'FC'x, '00'x, '05'x, $
   'A2'x, '94'x, '00'x, '03'x, '12'x, '8F'x, '00'x, '01'x, '64'x, '93'x, $
   '03'x, '01'x, 'D1'x, '67'x, '00'x, '01'x, 'FE'x, '6A'x, '0F'x, '01'x, $
   '66'x, '9B'x, '00'x, '90'x, '80'x, '94'x, '00'x, '18'x, '00'x, '00'x, $
   '00'x, '01'x, 'D2'x, '06'x, '04'x, '08'x, '00'x, '00'x, '00'x, '01'x, $
   '6F'x, 'D4'x, '0E'x, '00'x, '00'x, '00'x, '00'x, '00'x, '55'x, '13'x, $
   '00'x, '00'x, '05'x, '80'x, 'C7'x, '01'x, '85'x, '03'x, 'D5'x, '0B'x, $
   '02'x, '08'x, '30'x, '45'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, $
   '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, $
   '12'x, '4C'x, '25'x, '00'x, '09'x, '7E'x, '01'x, '72'x, '23'x, '3C'x, $
   '00'x, '00'x, 'E2'x, '9F'x, 'DA'x, '01'x, '07'x, '0B'x, 'E0'x, '3C'x, $
   'B0'x, '46'x, '00'x, '41'x, 'F0'x, '3C'x, '30'x, '3C'x, '30'x, 'BB'x, $
   '78'x, '10'x, '08'x, '00'x, '68'x, '05'x, '68'x, '00'x, 'A8'x, '21'x, $
   'A0'x, '01'x, '80'x, '22'x, 'B8'x, '09'x, '58'x, '1D'x, '08'x, '01'x, $
   'A8'x, '0D'x, '28'x, '00'x, '80'x, '13'x, 'A0'x, '0B'x, 'A6'x, '07'x, $
   '00'x, '08'x, '85'x, '07'x, '35'x, '00'x, '91'x, '05'x, '15'x, '00'x, $
   '91'x, '05'x, 'F6'x, '01'x, 'B7'x, '00'x, '7C'x, '01'x, '00'x, '00'x, $
   '67'x, '01'x, '68'x, '01'x, '33'x, '01'x, '00'x, '00'x, '00'x, '00'x, $
   '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, $
   '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, $
   'C7'x, '2F'x, '0C'x, '0D'x, 'D8'x, '00'x, '00'x, '00'x, '03'x, '09'x, $
   '01'x, '00'x, '00'x, '00'x, 'A8'x, '07'x, 'BC'x, '0B'x, 'D0'x, '08'x, $
   '00'x, '00'x, '00'x, '00'x, '00'x, '00'x, 'A4'x, '02'x, '1E'x, 'FE'x, $
   'B2'x, 'FD'x, '07'x, '24'x, '00'x, '00'x, 'AC'x, 'C3'x, 'A5'x, 'A5'x]
lastBeacon = byte(lastBeacon)   
   
; Read the data
minxss_read_packets, lastBeacon, hk = hk

return, hk

END
