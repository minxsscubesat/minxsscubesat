;+
; NAME:
;   minxss_average_packets.pro
;
; PURPOSE:
;   Average the packets data into single data structure
;
;	  This is used for MinXSS Level 3 processing
;
; CATEGORY:
;    MinXSS Level 3
;
; CALLING SEQUENCE:
;   avg_packet = minxss_average_packets( packet_array )
;
; INPUTS:
;   packet_array	Packet array (data structure)
;
; OPTIONAL INPUTS:
;	  None
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   avg_packet: The average of each packet variable is returned as:
;						    avg_packet.mean.XXXX
;						    avg_packet.median.XXXX
;						    avg_packet.stddev.XXXX
;						    avg_packet.min.XXXX
;						    avg_packet.max.XXXX
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;	  Uses standard IDL mean(), median(), stddev(), min() & max() on all packet variables.
;	  Only numbers are averaged.  Strings just use the first packet value.
;
; PROCEDURE:
;   1. Make the avg_packet definition
;	  2. Loop through all packet variables to make mean, median, and stddev
;	  3. Return avg_packet
;
; MODIFICATION HISTORY:
;	  2015/11/29: Tom Woods: Original code
;+
FUNCTION minxss_average_packets, packets, verbose=verbose

;
;	check inputs
;
; default return value
avg = -1L
if n_params() lt 1 then begin
	print, 'USAGE: avg_packet = minxss_average_packets( packet_array, /verbose )'
	return, avg
endif
num_tags = n_tags( packets[0] )
if (num_tags lt 1) then begin
	print, 'ERROR: minxss_average_packets() needs a data structure array as input.'
	return, avg
endif
if n_elements(packets) lt 2 then begin
	avg = packets	; just a single element
	print, 'WARNING: there are not enough packets to average.'
	return, avg
endif

;
; 1. Make the avg_packet definition as "avg"
;
avg = { mean: packets[0], median: packets[0], stddev: packets[0], $
		min: packets[0], max: packets[0] }

;
;	2. Loop through all packet variables to make mean, median, and stddev
;		If variable is array then do average of each element.
;		If variable is string then do not do average (it will just the first packet value)
;
if keyword_set(verbose) then $
	print, 'minxss_average_packets: Averaging ', strtrim(num_tags,2), ' variables ...'

for i=0L,num_tags-1 do begin
	vtype = size( packets[0].(i), /type )
	if ((vtype gt 0) and (vtype lt 6)) or ((vtype gt 11) and (vtype lt 16)) then begin
		num_array = size( packets[0].(i), /n_elements )
		if (num_array gt 1) then begin
			for k=0L,num_array-1 do begin
				avg.mean.(i)[k] = mean( packets.(i)[k] )
				avg.median.(i)[k] = median( packets.(i)[k] )
				avg.stddev.(i)[k] = stddev( packets.(i)[k] )
				avg.min.(i)[k] = min( packets.(i)[k] )
				avg.max.(i)[k] = max( packets.(i)[k] )
			endfor
		endif else begin
			avg.mean.(i) = mean( packets.(i) )
			avg.median.(i) = median( packets.(i) )
			avg.stddev.(i) = stddev( packets.(i) )
			avg.min.(i) = min( packets.(i) )
			avg.max.(i) = max( packets.(i) )
		endelse
	endif
endfor

;
;	3. Return "avg"
;
RETURN, avg
END