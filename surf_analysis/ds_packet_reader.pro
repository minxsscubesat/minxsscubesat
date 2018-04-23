;+
; NAME:
;   ds_packet_reader
;
; PURPOSE:
;   DeweSoft's on ALTAIR-0167 sends out "channel" data using TCP/IP and this procedure
;	  sets up TCP/IP socket to read the incoming data.  Follow the NSROC DeweSoft user manual
;	  on how to telnet into ALTAIR to stream the channel data.
;
; INPUTS:
;   None required
;
; KEYWORD PARAMETERS:
;	  PORT:		     A port number to use for communicating between the DeweSoft Altair box
;					       Default port is 8002
;   RESTART:	   Set to restart (re-open) TCP/IP socket
;   DEBUG: 		   Set to print debugging information, such as the sizes of the packets.
;	  LOG:		     Set to log the incoming data to a file
;	  PLAYBACK:	   Set to log file name to playback data previously logged
;	  SAMPLE_SIZE: The sample size of the channel data (in bytes): default is 2
;	  ONCE_READ:	 Set to read the socket only once and then return (default is to read forever)
;
; OUTPUTS:
;   None: The main objective is to get ds_pr_buffer filled with DeweSoft packets and then
;			to send completed packets to ds_packet_processor() [USER Specify Processing Module]
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires byte2ulong.pro to convert 4-bytes to unsigned long.
;	  Requires USER to develop their own ds_packet_processor() module.
;		Expected call is:  ds_packet_process, dataPacket, debug=debug, sample_size=sample_size
;
; PROCEDURE:
;   Open TCP/IP socket and wait for USER to configure ALTAIR via Telnet commands
;   Read socket data and buffer until have DeweSoft Packet
;		Send Packet to ds_packet_processor() module
;
; EXAMPLE:
;   IDL>  ds_packet_reader, /debug, /log
;
; MODIFICATION HISTORY:
;   2015-04-23: James Paul Mason: Wrote reader script called test_dewesoft_packet_processing_speed.pro
;	  2015-04-24: Tom Woods wrote ds_packet_reader.pro to add reader options
;-
PRO ds_packet_reader, port=port, DEBUG=DEBUG, RESTART=RESTART, LOG=LOG, playback=playback, $
		sample_size=sample_size,  once_read=once_read

;   check inputs and set defaults
IF ~keyword_set(port) THEN port = 8002
IF ~keyword_set(DEBUG) THEN debug = 0
IF ~keyword_set(RESTART) then restart = 0
IF ~keyword_set(LOG) then log = 0
IF ~keyword_set(sample_size) then sample_size = 2L
IF ~keyword_set(ONCE_READ) then once_read = 0

;  setup common block if /once_read option is used
common ds_packet_reader_common, ds_pr_initOK, ds_pr_connect_lun, ds_pr_socket_lun, ds_pr_buffer, ds_pr_log_lun

IF ((ds_pr_connect_lun EQ !NULL) OR keyword_set(RESTART)) AND ~keyword_set(PLAYBACK) THEN BEGIN
  ; first setup TCP/IP socket connection and wait until ATLAIR is sending out data
  socket, ds_pr_connect_lun, port, /LISTEN, /GET_LUN, READ_TIMEOUT = 60., WRITE_TIMEOUT = 60., /RAWIO
  STOP, 'Waiting until DeweSoft is sending data via its startacq command. Then GO with .continue'

  ; next setup Socket to read the data using IDL's file readu procedure
  if ds_pr_socket_lun NE !NULL then begin
    close, ds_pr_socket_lun
  	free_lun, ds_pr_socket_lun
  endif
  get_lun, ds_pr_socket_lun

  ; This only grabs the very first packet, after this read, all data is read on the ds_pr_socket_lun.
  noDatayet = 1
  if keyword_set(DEBUG) then message, /INFO, 'Waiting for data from DeweSoft...'
  WHILE noDataYet EQ 1 DO BEGIN
    IF file_poll_input(ds_pr_connect_lun, timeout = 1.0) THEN BEGIN
	  socket, ds_pr_socket_lun, accept=ds_pr_connect_lun, /RAWIO, CONNECT_TIMEOUT=30., $
	  		READ_TIMEOUT=30., WRITE_TIMEOUT=30., /SWAP_IF_BIG_ENDIAN
	  noDataYet = 0
	ENDIF
  ENDWHILE
  if keyword_set(DEBUG) then message, /INFO, 'Connection established for DeweSoft data!'

  ds_pr_buffer = !NULL   ; configure as empty when restarting TCP/IP connection

  if keyword_set(LOG) then begin
    if ds_pr_log_lun NE !NULL then begin
    	close, ds_pr_log_lun
    	free_lun, ds_pr_log_lun
    endif
    ds_pr_log_file = 'ds_pr_log_'+datestr+'.bin'
    print, 'DS_PACKET_READER log file = ', ds_pr_log_file
    openw,ds_pr_log_lun, /get_lun, ds_pr_log_file
  endif
ENDIF  ; end of TCP/IP socket setup and optional opening of Log file

IF keyword_set(PLAYBACK) then begin
	; configure for playback file instead of Socket
	if ds_pr_socket_lun NE !NULL then begin
      close, ds_pr_socket_lun
  	  free_lun, ds_pr_socket_lun
  	endif
  	get_lun, ds_pr_socket_lun
  	openr, ds_pr_socket_lun, playback
  	;  set once_read to be 0 as only one pass is required to read playback file
  	once_read = 0
  	ds_pr_buffer = !NULL
endif

loopFlag = 1

WHILE loopFlag DO BEGIN

 ;  determine if reading socket is forever or just once
 if ONCE_READ eq 0 then loopFlag = 0 else loopFlag = 1

 ; Read data on the socket
  socketDataSize = (fstat(ds_pr_socket_lun)).size

  IF socketDataSize GT 0 THEN BEGIN
    ; read the data and merge with previous buffer (if it exists)
    IF (ds_pr_buffer EQ !NULL) THEN BEGIN
      ds_pr_buffer = bytarr(socketDataSize)
      readu, ds_pr_socket_lun, ds_pr_buffer
    ENDIF ELSE BEGIN
      socketData = bytarr(socketDataSize)
      readu, ds_pr_socket_lun, socketData
	  ds_pr_buffer = [ temporary(ds_pr_buffer), socketData ]
	ENDELSE

	;
	;	look for DeweSoft Packet Sync headers (0 1 2 3 4 5 6 7) and process for each packet found
	;
	sync_last = -1L
	wSync7 = where( ds_pr_buffer eq 7, numSync7 )
	FOR i=0L,numSync7-1 DO BEGIN
	  ; first verify if wSync7[i] is real sync or not
	  isSync = 0
	  IF (wSync7[i] ge 7) THEN BEGIN
	  	;  ii is index of new sync if sequence of 8-bytes is 0 1 2 3 4 5 6 7
	    ii = wSync7[i]-7
	    if (ds_pr_buffer[ii] eq 0) and (ds_pr_buffer[ii+1] eq 1) and (ds_pr_buffer[ii+2] eq 2) $
	    	and (ds_pr_buffer[ii+3] eq 3) and (ds_pr_buffer[ii+4] eq 4) and (ds_pr_buffer[ii+5] eq 5) $
	    	and (ds_pr_buffer[ii+6] eq 6) then isSync = 1
	  ENDIF
	  IF (isSync ne 0) THEN BEGIN
	    IF (sync_last ge 0) THEN BEGIN
			;
			;	Process full packet using previous Sync location and new Sync location
			;	USER needs to write Processing module for this data
			;
			dataPacket = ds_pr_buffer[sync_last:ii-1]
			if keyword_set(DEBUG) then begin
			  message, /INFO, 'packet size = ' + strtrim(byte2ulong(dataPacket[8:11]),2) $
			  		+ ', 1st sample count = ' + strtrim(byte2ulong(dataPacket[36:39]),2)
			endif

			;  *****  USER processing module (one could replace the procedure name)  *****
			; ds_packet_process, dataPacket, debug=debug, sample_size=sample_size
			ds_packet_process_speed, dataPacket, debug=debug, sample_size=sample_size

	    ENDIF
	    ;  remember Sync index "ii" for next search of full packet
	    sync_last = ii
	  ENDIF
	ENDFOR

    ;
    ;	Delete all processed packets from the buffer before exiting (or looping for more Socket data)
    ;
    IF (sync_last gt 0) and ~keyword_set(playback) then ds_pr_buffer = temporary(ds_pr_buffer[sync_last:-1])

  ENDIF ELSE BEGIN
    ; no socket data has been found
  	if keyword_set(DEBUG) then message, /INFO, 'DS_PACKET_READER: No data found.'
  ENDELSE
ENDWHILE

;
;	close playback file if necessary
;
if keyword_set(playback) then begin
	close, ds_pr_socket_lun
  	free_lun, ds_pr_socket_lun
  	ds_pr_socket_lun = !NULL
endif

END
