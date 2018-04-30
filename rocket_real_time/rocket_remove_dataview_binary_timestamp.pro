;+
; NAME:
;   rocket_remove_dataview_binary_timestamp
;
; PURPOSE:
;   Tom's DataView program adds a timestamp to each received packet in it's dump binary files. 
;   This code removes that 4-byte timestamp to restore the binary to the way DataView received it.
;   Particularly used for the EVE rocket where data is streamed to us from White Sands Missile Range. 
;   Originally created to support development of the new TM-1 IDL socket read and real-time display
;   software. For debugging and testing, needed to feed the new IDL code exactly what WSMR will stream. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataViewDumpFilename [string]: The path and filename of the DataView dump bianry file. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   No variable return, but creates a new binary file in the same path as the input with 
;   _DataViewTimeStampRemoved appended to to the filename. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires remove.pro
;
; EXAMPLE:
;   rocket_remove_dataview_binary_timestamp, '/Users/jmason86/Dropbox/Research/Postdoc_LASP/Rocket/TM1_Raw_Data_05_06_16_16-57_SequenceAllFire-2'
;
; MODIFICATION HISTORY:
;   2017-08-04: James Paul Mason: Wrote script.
;-
PRO rocket_remove_dataview_binary_timestamp, dataViewDumpFilename = dataViewDumpFilename

; Defaults
IF dataViewDumpFilename EQ !NULL THEN BEGIN
  dataViewDumpFilename = '/Users/jmason86/Dropbox/Research/Postdoc_LASP/Rocket/TM1_Raw_Data_05_06_16_16-57_SequenceAllFire-2'
ENDIF

; Setup
syncByte = 1003

; Read in the binary file
dataViewBinary = read_binary(dataViewDumpFilename, DATA_TYPE = 12) ; data_type 12 = uint

; Find the sync bytes and remove the last two bytes (a uint = 2 bytes) of the timestamp that comes just before the sync byte
syncIndices = where(dataViewBinary EQ syncByte)
syncIndices8th = syncIndices[0 : -1 : 8] ; Want the sync at the end of a full packet, not just a single row. 8 rows per packet. 
syncIndices = syncIndices[1 : -1]
remove, syncIndices - 1, dataViewBinary

; Repeat to remove the first two bytes of the timestamp
syncIndices = where(dataViewBinary EQ syncByte)
syncIndices8th = syncIndices[0 : -1 : 8] ; Want the sync at the end of a full packet, not just a single row. 8 rows per packet. 
syncIndices = syncIndices[1 : -1]
remove, syncIndices - 1, dataViewBinary

; Write the new binary with no DataView timestamps
openw, lun, dataViewDumpFilename + '_DataViewTimeStampRemoved.dat', /GET_LUN
writeu, lun, dataViewBinary
free_lun, lun

END