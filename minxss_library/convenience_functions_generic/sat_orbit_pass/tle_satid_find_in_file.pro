;
;
;	tle_satid_find_in_file.pro
;
;	Replace the following unix grep function for finding TLE in a file:
;		grep_cmd = 'grep "' + mission + '" -A 2 ' + catalog
;		spawn, grep_cmd, result
;
;	New procedure so searches for satellite ID instead of MISSION name
;
;	INPUT
;		satid		satellite ID (default is ISS = 25544)
;		catalog		catalog file
;
;	OUTPUT
;		result		strarr(3) of TLE found (or null string if not found)
;
;	PROCEDURE
;	1.  Open catalog file
;	2.	Search line by line for satellite id
;	3.	Close catalog file
;	4. 	Return result
;
;	CALLING EXAMPLE
;	IDL>  result = tle_satid_find_in_file( satid, catalog )
;
;	This is called from tle_download_latest.pro so it will work on PC Windows (without grep)
;
;	HISTORY
;	2016-Jan-24		T. Woods	Original version for tle_find_in_file.pro
;	2016-Mar-17		T. Woods	Revised to use satid instead of mission name
;
function tle_satid_find_in_file, satid, catalog, debug=debug

;	temporary debug
; debug = 1

result = ''
cnt = 0L
linecnt = 0L
if n_params() lt 2 then return, result

;
;	1.  Open catalog file
;
on_ioerror, bad_exit
finfo = file_info( catalog )
if not finfo.exists then begin
	print, 'ERROR: '+catalog+ ' file does not exist!'
	goto, exit_now
endif
openr, flun, catalog, /get_lun
s3 = strarr(3)
strin = ' '
strin2 = ' '
lastLine = ' '

;
;	2.	Search catalog file for specific mission and obtain its TLE (three lines per mission)
;
;	This replaces Unix:  grep_cmd = 'grep "' + mission + '" -A 2 ' + catalog
;					  spawn, grep_cmd, result
;
tempstr = string(satid)
missionID = strtrim(tempstr,2)
;  add '0' if ID is short number
while (strlen(missionID) lt 5) do missionID = '0' + missionID
if keyword_set(debug) then print, 'Searching TLEs for satid = '+missionID+' ...'

on_ioerror, exit_close
while not eof(flun) do begin
	readf, flun, strin
	linecnt += 1
	linecap = strupcase(strin)
	if (strpos(linecap, missionID) eq 2) then begin
		; read the next TLE line and add to result
		s3[1] = strin
		readf, flun, strin2
		s3[2] = strin2
		s3[0] = lastLine  ; this should be line 0 of 3-line-element
		; add 3 lines to result
		if (cnt eq 0) then result = s3 else result = [ result, s3 ]
		linecnt += 1L
		cnt += 1L
	endif
	lastLine = strin
endwhile

;
;	3.	Close catalog file
;
exit_close:
close, flun
free_lun, flun

;
;	4. 	Return result
;
goto, exit_now
bad_exit:
	print, 'ERROR reading TLEs from '+catalog+': ', !err_string

exit_now:
on_ioerror, NULL
if keyword_set(debug) then begin
	help, result
	stop, 'DEBUG TLE results ...'
endif

return, result
end
