;
;	read_events.pro
;
;	Read events from a Text file
;
;	File Format:
;	1)  2 columns with column 1 = date and column 2 = event string
;	2)  3 columns with column 1 = date, column 2 = time, and column 3 = event string
;
;	Date is number like YYYYDOY, YYYYMMDD, or JulianDay
;	Time is number in hours
;	Event is text string
;
;	10/1/2022  T. Woods
;
function read_events, filename, debug=debug

if n_params() lt 1 then begin
	print, 'USAGE:  event_structure = read_events( filename )'
	return, -1
endif

num_lines = 0L
num_columns = 0L
index = 0L

on_ioerror, BAD_FILE
openr, lun, filename, /get_lun
str = ' '
while not eof(lun) do begin
	readf,lun,str
	str = strtrim(str,2)
	tokens = strsplit(str, /extract, count=num_tokens)
	num1 = strmid(str,0,1)
	if (num1 ge '0') and (num1 le '9') then begin
		if (num_lines gt 0) and (num_columns gt 0) then begin
			; have event line to process
			if (num_tokens ge num_columns) then begin
				if (num_columns ge 3) then begin
					events[index].date = double(tokens[0])
					events[index].time = double(tokens[1])
					events[index].event_text = strjoin( tokens[2:-1], ' ' )
					index += 1L
				endif else if (num_columns eq 2) then begin
					events[index].date = double(tokens[0])
					events[index].event_text = strjoin( tokens[1:-1], ' ' )
					index += 1L
				endif
			endif
		endif else begin
			; need to find a LINE or COLUMN string
			strup = strupcase(str)
			if (num_lines le 0) then begin
				posLine = strpos(strup,'LIN')
				if (posLine gt 0) then num_lines = long(tokens[0])
			endif
			if (num_columns le 0) then begin
				posCol = strpos(strup,'COL')
				if (posCol gt 0) then num_columns = long(tokens[0])
			endif
			if (num_lines gt 0) and (num_columns gt 0) then begin
				; make the events structure
				if (num_columns ge 3) then begin
					event1 = { date: 0.0D0, hour: 0.0D0, event_text: ' ' }
				endif else if (num_columns eq 2) then begin
					event1 = { date: 0.0D0, event_text: ' '}
				endif else begin
					if keyword_set(debug) then stop, 'STOPPED with ERROR of Columns being less than 2 ...'
					return, -1
				endelse
				events = replicate(event1,num_lines)
			endif
		endelse
	endif
	; else ignore comment lines
	if (num_lines gt 0) AND (index ge num_lines) then goto, CLOSE_FILE
endwhile

CLOSE_FILE:
	close, lun
	goto, DONE

; Exception label. Print the error message.
BAD_FILE:
	print, "ERROR read_events: " + !ERR_STRING

; Close and free the input/output unit.
DONE:
	FREE_LUN, lun
	on_ioerror, NULL

if keyword_set(debug) then stop, 'DEBUG at end of read_events()...'

return, events
end
