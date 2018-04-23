;+
; NAME:
;   minxss_unkiss
;
; PURPOSE:
;   Convert KISS files to MinXSS CCSDS format (strips out KISS/AX25 headers)
;
; USAGE
;   output = minxss_unkiss(input, /verbose)
;
; INPUTS:
;   input [string]:       Name of file to read (string) or a bytarr containing packet(s)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   verbose:             Option to print number of packets found
;
; RETURNS:
;   output:           bytarr of extracted MinXSS CCSDS packets
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;
; MODIFICATION HISTORY:
;   05/26/2016: Amir Caspi: Created file
;   06/04/2016: Amir Caspi: Added check to isolate only MinXSS packets
;+
FUNCTION minxss_unkiss, input, verbose=verbose, _extra=_extra

  IF (n_params() LT 1) THEN BEGIN
    print, 'USAGE: output = minxss_unkiss, input_file, /verbose'
    input=' '
  ENDIF
  IF size(input[0], /TYPE) EQ 7 THEN IF (strlen(input) LT 2) THEN BEGIN
    ; find file to read
    input = dialog_pickfile(/read, title='Select MinXSS KISS file to read', filter='*.kss')
    IF (strlen(input) LT 2) THEN return, -1   ; user did not select file
  ENDIF

  inputType = ''
  IF size(input, /TYPE) EQ 7 THEN BEGIN
    inputType = 'file'
    fileOpened = 0
    ON_IOERROR, exit_read
    finfo = file_info( input )
    IF (finfo.exists NE 0) AND (finfo.read NE 0) AND (finfo.size GT 6) THEN BEGIN
      IF keyword_set(verbose) THEN print, 'READING ', strtrim(finfo.size,2), ' bytes from ', input
      openr, lun, input, /get_lun
      fileOpened = 1
      adata = assoc(lun, bytarr(finfo.size))
      data = adata[0]
      close, lun
      free_lun, lun
      fileOpened = 0
      ON_IOERROR, NULL
    ENDIF ELSE GOTO, exit_read
  ENDIF ELSE BEGIN
    inputType = 'bytarr'
    data = input ; input provided was a file name else input was already bytarr
  ENDELSE

  KISS_FEND = byte('C0'x)
  KISS_FESC = byte('DB'x)
  KISS_TFEND = byte('DC'x)
  KISS_TFESC = byte('DD'x)
  
  MINXSS_AX25_BYTE1 = byte('86'x)
  MINXSS_AX25_BYTE2 = byte('A2'x)
  MINXSS_AX25_BYTE3 = byte('40'x)
  MINXSS_AX25_BYTE4 = byte('40'x)
  MINXSS_AX25_BYTE5 = byte('40'x)
  MINXSS_AX25_BYTE6 = byte('40'x)
  MINXSS_AX25_BYTE7 = byte('60'x)
  MINXSS_AX25_BYTE8 = byte('9A'x)
  MINXSS_AX25_BYTE9 = byte('92'x)
  MINXSS_AX25_BYTE10 = byte('9C'x)
  MINXSS_AX25_BYTE11 = byte('B0'x)
  MINXSS_AX25_BYTE12 = byte('A6'x)
  MINXSS_AX25_BYTE13 = byte('A6'x)
  MINXSS_AX25_BYTE14 = byte('E1'x)
  MINXSS_AX25_BYTE15 = byte('03'x)
  MINXSS_AX25_BYTE16 = byte('F0'x)
  
  ; There should NOT be any bare C0 bytes in the payload due to KISS escaping (see below)
  ; So, look for the KISS TNC-to-computer data frame bounded by C0 00 <payload> C0
  kissFENDIndices = where(data eq KISS_FEND, nfend)
  ; If the payload has already been extracted for some reason, the below simply is skipped...
  FOR i = 0, nfend - 2 DO BEGIN
    ; The below should be safe because there should always be a final C0, so we won't overrun the array
    IF (data[kissFENDIndices[i]+1] EQ '00'x) THEN BEGIN
      ; We extract only the payload
      payload = data[kissFENDIndices[i]+2:kissFENDIndices[i+1]-1]
      ; If the payload is long enough (minimum 14 bytes for a CCSDS header and sync word), then save it
      IF (n_elements(payload) GE 14) THEN BEGIN
        ; Check AX.25 header for MinXSS compliance... only save if match
        IF ((payload[7] EQ MINXSS_AX25_BYTE8) AND (payload[8] EQ MINXSS_AX25_BYTE9) AND (payload[9] EQ MINXSS_AX25_BYTE10)) THEN $
          extractedData = (n_elements(extractedData) GT 0) ? [extractedData, temporary(payload)] : temporary(payload)
      ENDIF
    ENDIF
  ENDFOR
  ; The payload is now (probably) the entire MinXSS packet, including AX.25 header... though possibly the AX.25 header was stripped
  ; TODO: Include option to strip AX.25 header, too??

  IF (i GT 0) THEN data = temporary(extractedData)

  ; Remove KISS escape characters (DB)
  KISSescapeIndices = where(data eq KISS_FESC, nfesc)
  FOR i = 0, nfesc - 1 DO BEGIN
    ; The following is safe because all VALID payloads should end with A5A5, so we won't fall off the end of the array
    IF (data[KISSescapeIndices[i]+1] EQ KISS_TFEND) THEN $
      ; DBDC is escaped C0
      data = [data[0:KISSescapeIndices[i]-1], KISS_FEND, data[KISSescapeIndices[i]+2:*]] $
    ELSE IF (data[KISSescapeIndices[i]+1] EQ KISS_TFESC) THEN $
      ; DBDD is escaped DB
      data = [data[0:KISSescapeIndices[i]-1], KISS_FESC, data[KISSescapeIndices[i]+2:*]]
    ; ELSE just ignore it, but DB should never appear alone
    ; Now we've shortened the array by one, so subtract from the indices...
    KISSescapeIndices -= 1
  ENDFOR
  
  return, data

  exit_read:
  ; Exit Point on File Open or Read Error
  IF keyword_set(verbose) THEN print, 'ERROR reading file: ', input
  IF (fileOpened NE 0) THEN BEGIN
    close, lun
    free_lun, lun
  ENDIF
  ON_IOERROR, NULL

  return, -1

END
