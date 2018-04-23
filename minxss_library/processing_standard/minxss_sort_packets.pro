;+
; NAME:
;	  minxss_sort_packets.pro
;
; PURPOSE:
;	  Sort MinXSS data packets by time and optionally also by flight model and specific date (YYYYDOY)
;
; CATEGORY:
;	  MinXSS Level 0C
;
; CALLING SEQUENCE:
;	  minxss_sort_packets, packet_array, date_yyyydoy, flight_model
;
; INPUTS:
;	  packet_array		Array of packets that has to have at least *.time for Time Sorting
;						It also needs *.flight_model to select for "flight_model"
;						It assumes GPS seconds for *.time to select by YYYYDOY
;
;	OPTIONAL INPUTS:
;	  flight_model		Flight Model number of 1 or 2
;	  date_yyyydoy		Date for selecting packets
;
;	KEYWORD PARAMETERS:
;	  verbose			Print debug messages while processing
;
; OUTPUTS:
;	  packet_array		Input 'packet_array' is modified and is new output
;
;	OPTIONAL OUTPUTS:
;	  NONE
;
; COMMON BLOCKS:
;	  None
;
;	RESTRICTIONS:
;	  packet_array has to have *.time and *.flight_model parameters for this procedure to work right.
;
; PROCEDURE:
;   1. Select packets with correct flight model number (option based on input)
;	2. Select packets with same date (YYYYDOY) (option based on input)
;	3. Sort the selected packets by time
;	4. Return the sorted result
;
; MODIFICATION HISTORY:
;   2015/09/08: Tom Woods: Original code.
;   2016/05/30: Amir Caspi: Isolated unique timestamps to remove duplicate packets
;
;
;+

pro minxss_sort_packets, packets, yyyydoy, fm, verbose=verbose

if n_params() lt 1 then begin
  print, 'USAGE: minxss_sort_packets, packet_array, date_yyyydoy, flight_model'
  return
endif

; return if there are no packets
if packets EQ !NULL then return

;
;   1. Select packets with correct flight model number (option based on input)
;
num_in = n_elements(packets)
if n_params() ge 3 then begin
	wgood = where( packets.flight_model eq fm, numgood )
	if (numgood le 0) then begin
	  packets = !NULL
	  if keyword_set(verbose) then print, 'No Packets for FM = ', strtrim(fm,2)
	  return
	endif
	packets = packets[wgood]
endif

;
;	2. Select packets with same date (YYYYDOY) (option based on input)
;		This assumes *.time is in GPS seconds.
;
if n_params() ge 2 then begin
    packets_yd = long( jd2yd( gps2jd( packets.time ) ) )
	wgood = where( packets_yd eq long(yyyydoy), numgood )
	if (numgood le 0) then begin
	  packets = !NULL
	  if keyword_set(verbose) then print, 'No Packets for date = ', strtrim(yyyydoy,2)
	  return
	endif
	packets = packets[wgood]
endif

;
;	3. Sort the selected packets by time
;
;tsort = sort( packets.time )
tsort = uniq( packets.time, sort(packets.time))

;
;	4. Return the sorted result
;
packets = packets[tsort]

num_out = n_elements(packets)
if keyword_set(verbose) then begin
	print, 'Number of Packets selected is ', strtrim(num_out,2), ' out of ', strtrim(num_in,2)
endif

return
end
