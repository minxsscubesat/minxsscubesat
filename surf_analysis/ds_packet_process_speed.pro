;+
; NAME:
;   ds_packet_process_speed
;
; PURPOSE:
;   Print the Sample-1 data rate speed
;
; INPUTS:
;   None required
;
; KEYWORD PARAMETERS:
;   DEBUG: 		    Set to print debugging information, such as the sizes of the packets.
;	  SAMPLE_SIZE:  The sample size of the channel data (in bytes): default is 2
;
; OUTPUTS:
;   None: The main objective is to print the data rate speed for Sample-1 (channel 1) data
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires byte2ulong.pro to convert 4-bytes to unsigned long.
;
; PROCEDURE:
;   Write message on data rate
;
; EXAMPLE:
;   ds_packet_process_speed, dataPacket
;
; MODIFICATION HISTORY:
;	  2015/04/24: Tom Woods original code
;-
PRO ds_packet_process_speed, dataPacket, DEBUG=DEBUG, sample_size=sample_size

;   check inputs and set defaults
IF ~keyword_set(DEBUG) THEN debug = 0
IF ~keyword_set(sample_size) then sample_size = 2L

;  setup common block to track time from last call
common ds_packet_process_speed_common, ds_pps_tic_id

if (ds_pps_tic_id NE !NULL) then begin
  numSamples = byte2ulong(dataPacket[36:39])
  time_diff = toc( ds_pps_tic_id )
  rate = float(numSamples) / (time_diff > 1E-6)
  print, '    Sample-1 Speed (samples/sec) = ', rate
endif

;  get time for next call here
ds_pps_tic_id = tic( 'ds_pss' )

RETURN
END
