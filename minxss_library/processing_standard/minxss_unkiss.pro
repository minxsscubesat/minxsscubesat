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
;   input [string]: Name of file to read (string) or a bytarr containing packet(s)
;
; OPTIONAL INPUTS:
;   FM [int]: Flight model designation; defaults to 2.
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
FUNCTION minxss_unkiss, input, fm=fm, verbose=verbose, _extra=_extra

  IF (n_params() LT 1) THEN BEGIN
    print, 'USAGE: output = minxss_unkiss, input_file, /verbose'
    input=' '
  ENDIF
  IF size(input[0], /TYPE) EQ 7 THEN IF (strlen(input) LT 2) THEN BEGIN
    ; find file to read
    input = dialog_pickfile(/read, title='Select MinXSS KISS file to read', filter='*.kss')
    IF (strlen(input) LT 2) THEN return, -1   ; user did not select file
  ENDIF
  IF n_elements(fm) EQ 0 THEN fm = 2

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

  JPM_bare_C0 = 0 ; KLUDGE: some JPM python-decoded files already have KISS sequences decoded, this is to track that

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
  MINXSS_AX25_BYTE8 = byte('9A'x)  ; M bit shifted forward 1
  MINXSS_AX25_BYTE9 = byte('92'x)  ; I bit shifted forward 1
  MINXSS_AX25_BYTE10 = byte('9C'x) ; N bit shifted forward 1
  MINXSS_AX25_BYTE11 = byte('B0'x) ; X bit shifted forward 1
  MINXSS_AX25_BYTE12 = byte('A6'x) ; S bit shifted forward 1
  MINXSS_AX25_BYTE13 = byte('A6'x) ; S bit shifted forward 1
  MINXSS_AX25_BYTE14 = byte('E1'x)
  MINXSS_AX25_BYTE15 = byte('03'x)
  MINXSS_AX25_BYTE16 = byte('F0'x)
 
  SYNC_BYTE1 = byte('A5'X)
  SYNC_BYTE2 = byte('A5'X)
 
;  IF fm EQ 1 THEN BEGIN
;    sourceCallsignIndex = 7
;  ENDIF ELSE IF fm EQ 2 THEN BEGIN
;    sourceCallsignIndex = 0
;  ENDIF

  ; KLUDGE: make sure there is always a C0 at the end of the file so we don't drop potential packets
  IF (data[-1] NE KISS_FEND) THEN data = [data, KISS_FEND]
  
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
        ; MinXSS-1 had source and destination reversed, so have to look in different payload indices
        IF (((payload[0] EQ MINXSS_AX25_BYTE8) AND (payload[1] EQ MINXSS_AX25_BYTE9) AND (payload[2] EQ MINXSS_AX25_BYTE10))  $ ; FM2
         OR ((payload[7] EQ MINXSS_AX25_BYTE8) AND (payload[8] EQ MINXSS_AX25_BYTE9) AND (payload[9] EQ MINXSS_AX25_BYTE10))) $ ; FM1
         THEN BEGIN
          ; 6 Dec 2018 -- KLUDGE: Some JPM python-decoded packets may include bare C0 bytes.
          ; Need to delineate packets by finding the next C0 that is prefaced by A5 A5 sync bytes
          i2 = i ; scan through subsequent C0 bytes to find the next one prefaced by syncs
          REPEAT i2 += 1 UNTIL ((data[kissFENDIndices[i2]-2] EQ SYNC_BYTE1) AND (data[kissFENDIndices[i2]-1] EQ SYNC_BYTE2))
          ; Now we have a valid MinXSS packet, so extract the payload from scratch and store it
          payload = data[kissFENDIndices[i]+2:kissFENDIndices[i2]-1]
          IF (i2 GT (i+1)) THEN JPM_bare_C0 = 1 ; set a flag
          i = i2 ; Advance the main pointer to the C0 we just found, we've already scanned through the others
          extractedData = (n_elements(extractedData) GT 0) ? [extractedData, temporary(payload)] : temporary(payload)
        ENDIF
      ENDIF
    ENDIF
  ENDFOR
  ; The payload is now (probably) the entire MinXSS packet, including AX.25 header...
  ; TODO: Include option to strip AX.25 header, too??

  IF (i GT 0) THEN data = temporary(extractedData)

  ; Remove KISS escape characters (DB)
  ; TODO: When JPM_bare_C0 EQ 1, these are already decoded ... so DBDC or DBDD is real if present. SKIP THIS???
  KISSescapeIndices = where(data eq KISS_FESC, nfesc)
  FOR i = 0, nfesc - 1 DO BEGIN
    ; The following is safe because all VALID payloads should end with A5A5, so we won't fall off the end of the array
    IF (data[KISSescapeIndices[i]+1] EQ KISS_TFEND) THEN $
      ; DBDC is escaped C0
      data = [data[0:KISSescapeIndices[i]-1], KISS_FEND, data[KISSescapeIndices[i]+2:*]] $
    ELSE IF (data[KISSescapeIndices[i]+1] EQ KISS_TFESC) THEN $
      ; DBDD is escaped DB
      data = [data[0:KISSescapeIndices[i]-1], KISS_FESC, data[KISSescapeIndices[i]+2:*]]
    ; ELSE just ignore it, but DB should never appear alone (** It does for some JPM python-decoded files **)
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
