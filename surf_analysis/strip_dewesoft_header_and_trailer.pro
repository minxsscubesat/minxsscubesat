;+
; NAME:
;   strip_dewesoft_header_and_trailer
;
; PURPOSE:
;   Extract instrument data from a complete DEWESoft packet i.e. discard DEWESoft headers and trailers and convert from bytes to uints. Originally written for 
;   the SDO/EVE sounding rocket program. 
;
; INPUTS:
;   socketData [bytarr]:          A complete DEWESoftPacket that still has the headers/trailers intact. 
;   offset [long]:                How far into the DEWESoftPacket to get to the "Data Samples" bytes of the DEWESoft channel definitions according to the binary
;                                 data format documentation. Note that another 4 bytes need to be skipped to get to the actual data.
;                                 The bytes of instrument samples range from [offset + 4, (offset + 4) + (numberOfDataSamples * sampleSizeDeweSoft)]
;   numberOfDataSamples [ulong]:  The number of instrument samples contained in the complete DEWESoft packet for whichever channel this corresponds to (make sure
;                                 to pass in all of these input parameters that correspond to the same channel).
;   sampleSizeDeweSoft [integer]: This is =2 if using synchronous data in DEWESoft for instrument channels, or =10 if using asynchronous. The additional bytes
;                                 are from timestamps on every sample. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   instrumentPacketDataWithFiller [uint]: An array of words corresponding to instrument data, but still may have WSMR telemetry filler data, which is
;                                          0x7E7E bytes in random places to fill up the full bandwidth of the telemetry link. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2015-04-23: James Paul Mason: Wrote script.
;-
FUNCTION strip_dewesoft_header_and_trailer, socketData, offset, numberOfDataSamples, sampleSizeDeweSoft

return, byte2uint(socketData[offset + 4:(offset + 4) + (numberOfDataSamples * 2UL)])

END