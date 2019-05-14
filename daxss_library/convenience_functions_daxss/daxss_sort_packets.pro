;+
; NAME:
;   daxss_sort_packets.pro
;
; PURPOSE:
;   Sort DAXSS data packets by time. Note that this function directly manipulates the input rather than returning a copy. 
;
; INPUTS:
;   packet_array [array of structures] Array of packets that has to have at least *.time for time Sorting
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set to print debug messages while processing
;
; OUTPUTS:
;   packet_array [array of structures] The input array, directly modified to be sorted by time
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   packet_array has to have *.time tag
;
; PROCEDURE:
;   1. Sort the selected packets by time
;   2. Return the sorted result
;
;+

pro daxss_sort_packets, packets, $
                        VERBOSE=VERBOSE

  if n_params() lt 1 then begin
    message, /INFO, 'USAGE: daxss_sort_packets, packet_array'
    return
  endif

  ; return if there are no packets
  if packets EQ !NULL then return

  ;
  ; 1. Sort the selected packets by time
  ;
  tsort = uniq(packets.time, sort(packets.time))

  ;
  ; 4. Return the sorted result
  ;
  packets = packets[tsort]

  num_out = n_elements(packets)
  if keyword_set(verbose) then begin
    message, /INFO, 'Number of Packets selected is ', strtrim(num_out,2), ' out of ', strtrim(num_in,2)
  endif

  return
end
