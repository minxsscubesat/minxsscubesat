;
;
;	tle_find_in_file.pro
;
;	Replace the following unix grep function for finding TLE in a file:
;		grep_cmd = 'grep "' + mission + '" -A 2 ' + catalog
;		spawn, grep_cmd, result
;
;	INPUT
;		mission		mission name, default is MinXSS (ISS for now)
;		catalog		catalog file
;
;	OUTPUT
;		result		strarr(3) of TLE found (or null string if not found)
;
;	PROCEDURE
;	1.  Open catalog file
;	2.	Search line by line for mission name
;	3.	Close catalog file
;	4. 	Return result
;
;	CALLING EXAMPLE
;	IDL>  result = tle_find_in_file( mission, catalog )
;
;	This is called from tle_download_latest.pro so it will work on PC Windows (without grep)
;
;	HISTORY
;	2016-Jan-24		T. Woods	Original version
;
function tle_find_in_file, mission, catalog, debug=debug

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

;
;	2.	Search catalog file for specific mission and obtain its TLE (three lines per mission)
;
;	This replaces Unix:  grep_cmd = 'grep "' + mission + '" -A 2 ' + catalog
;					  spawn, grep_cmd, result
;
if keyword_set(debug) then print, 'Searching TLEs for '+mission+'...'
missioncap = strupcase(mission)
on_ioerror, exit_close
while not eof(flun) do begin
	readf, flun, strin
	linecnt += 1
	linecap = strupcase(strin)
	if (strpos(linecap, missioncap) ge 0) then begin
		; read the next 2 TLE lines and add to result
		s3[0] = strin
		readf, flun, strin
		s3[1] = strin
		readf, flun, strin
		s3[2] = strin
		; add 3 lines to result
		if (cnt eq 0) then result = s3 else result = [ result, s3 ]
		linecnt += 2
		cnt += 1L
	endif
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
