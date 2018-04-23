;
;
;	tle_download_latest.pro
;
;	Search for latest TLE for specified satellite
;	This uses Mac OS-X curl command line call to space-track.org
;
;	INPUT
;		mission		Option for mission name, default is MinXSS (ISS for now)
;		satid		Option for mission satellite ID number instead of mission name
;		catalog		Option for catalog file
;		url			Option for URL search / query at space-track.org
;		user		Option for user (login)
;		password	Option for password (login)
;		verbose		Option for verbose call to curl
;		debug		Option to debug this procedure
;		nodownload	Option to not do a new download and just search the previous downloaded TLE file
;		path		Option for path storing TLE data,default is $TLE_dir
;		output		Option to append TLE to its SATELLITE_ID.tle file
;		SatPC    Option to write TLE values of MinXSS, CADRE, and ISS to file for SatPC32 tracking
;
;	OUTPUT
;		tle			strarr(2) of TLE
;		output		Option to write (append) TLE string to mission TLE file
;
;	PROCEDURE
;	1.  Option: Download latest TLE from space-track.org and save into catalog file
;	2.	Search catalog file for specific mission and obtain its TLE
;	3.	Option: Output this TLE to its TLE history file
;
;	CALLING EXAMPLE
;	IDL>  tle_download_latest, tle, /dowunload, /output
;
;	HISTORY
;	2015-Nov-21		T. Woods	Original version
; 2016-Feb-09   T. Woods  Added the option /SatPC so TLEs for MinXSS, CADRE, ISS are saved for SatPC32 tracking
;
pro tle_download_latest, tle, satid=satid, mission=mission, $
		catalog=catalog, url=url, user=user, password=password, $
		nodownload=nodownload, output=output, verbose=verbose, path=path, SatPC=SatPC, debug=debug

; define slash and quote depending if Mac or Windows
if !version.os_family eq 'Windows' then begin
  slash = '\'
  quote1 = '"'
  quote2 = '"'
  andsign = '^&'
endif else begin
  slash = '/'
  quote1 = "'"
  quote2 = '"'
  andsign = '&'
endelse

;
;	default path is $TLE_dir
;
if not keyword_set(path) then begin
	path = getenv('TLE_dir')
	if strlen(path) gt 0 then path += slash
endif

;
;	default Mission is ISS (will change to MinXSS once it is launched)
;		ISS name = 'ISS (ZARYA)'
;	OR use satid if it was set
if not keyword_set(mission) then begin
	if not keyword_set(satid) then mission = 'ISS (ZARYA)'
endif

do_Minxss2 = 0   ; set to 0 for minxss-1 or 1 for minxss-2
if keyword_set(SatPC) then begin
  if (strupcase(SatPC) eq 'MINXSS2') then do_Minxss2 = 1
  mission1 = 'MINXSS'  ;  'MINXSS' name in TLE catalog
  mission1_id = 41474L
  mission1pc = 'MINXSS-1'     ;  Name to save as mission header in SatPC file
  mission2 = 'CADRE'  ;  'CADRE' name in TLE catalog
  mission2_id = 41475L
  mission2pc = 'CADRE'
  mission3 = 'ISS (ZARYA)'  ;  'ISS' name in TLE catalog
  mission3_id = 25544L
  mission3pc = 'ISS'
  if (do_Minxss2 ne 0) then begin
  	; re-define for MinXSS-1, QB50, MinXSS-2
    mission1 = 'MINXSS'  ;  'MINXSS' name in TLE catalog
    mission1_id = 41474L
    mission1pc = 'MINXSS-1'     ;  Name to save as mission header in SatPC file
    mission2 = 'IRIS (ESRO 2B)'  ;  'IRIS' name in TLE catalog (SSO orbit like MinXSS-2)
    mission2_id = 39197L
    mission2pc = 'IRIS-MINXSS-2'
    mission3 = 'ISS (ZARYA)'  ;  'ISS' name in TLE catalog
    mission3_id = 25544L
    mission3pc = 'ISS-QB50'
  endif
endif

;
;	default catalog is $TLE_dir/space_track_LEO_latest_catalog.txt
;
if not keyword_set(catalog) then begin
	catalog = path + 'space_track_LEO_latest_catalog.txt'
endif

;
;	default URL is all satellites with apogee < 450 km
;
if not keyword_set(url) then begin
  if !version.os_family eq 'Windows' then begin
    url = 'https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/APOGEE/%3C700/orderby/ORDINAL%20asc/format/3le/metadata/false'
  endif else begin
    url = 'https://www.space-track.org/basicspacedata/query/class/tle_latest/ORDINAL/1/APOGEE/%3C700/orderby/ORDINAL%20asc/format/3le/metadata/false'
  endelse
endif

;
;	default User is tom.woods@lasp for space-track.org
;
if not keyword_set(user) then user='tom.woods@lasp.colorado.edu'
if not keyword_set(password) then password = 'Go_cubesat-Pass'

;
;	1.  Option: Download latest TLE from space-track.org and save into catalog file
;
;	execute curl command
;		curl -c cookies.txt -b cookies.txt -k
;			https://www.space-track.org/ajaxauth/login -d "identify=USER&password=PASSWORD&query=URL"
;

cookies = path + 'space-track_cookies.txt'
curl_cmd = 'curl -c ' + cookies + ' -b ' + cookies
curl_cmd += ' --output ' + quote2 + catalog + quote2
if keyword_set(verbose) then curl_cmd += ' --verbose'
curl_cmd += ' -k https://www.space-track.org/ajaxauth/login -d '
curl_cmd += quote1 + "identity=" + strtrim(user,2) + '&password=' + strtrim(password,2)
curl_cmd += '&query=' + strtrim(url,2) + quote1

if not keyword_set(nodownload) then begin
	print, '*****  Starting TLE download. This will take several seconds. *****'
	if keyword_set(debug) or keyword_set(verbose) then $
	   print, 'CURL CMD('+strtrim(strlen(curl_cmd),2)+'): '+curl_cmd
	spawn, curl_cmd, curl_messages
	n_str = n_elements(curl_messages)
	if keyword_set(debug) or keyword_set(verbose) then for k=0L,n_str-1 do print, curl_messages[k]
endif

; if keyword_set(debug) then stop, 'DEBUG curl download file ...'

;
;	2.	Search catalog file for specific mission and obtain its TLE
;
;	now search catalog file for the Mission Name and extract the TLE
;		grep returns lines of csh output and then
;			Mission Name line and two TLE data lines
;		If more than one mission is found with same name then there is a line of "--"
;		before the next set of Mission Name line and two TLE data lines
;
;		OLD WAY for Unix (Mac)
;  grep_cmd = 'grep "' + mission + '" -A 2 ' + catalog
;  spawn, grep_cmd, result
;
; 		NEW WAY for any platform
if keyword_set(satid) then result = tle_satid_find_in_file( satid, catalog ) $
else result = tle_find_in_file( mission, catalog )  ; find using mission name

num = n_elements(result)
if (num lt 3) then begin
	; mission not found
	tle = -1L
	print, 'ERROR: mission TLE not found'
	if keyword_set(debug) then stop, 'DEBUG error-1 ...'
	return
endif

;	search for first line with "0 "
istart = 0L
for k=0L,num-1 do begin
	 if strmid(result[k],0,2) eq '0 ' then break
endfor
istart = k

if (istart ge num) then begin
	; mission not found
	tle = -1L
	print, 'ERROR: mission TLE not found'
	if keyword_set(debug) then stop, 'DEBUG error-2 ...'
	return
endif

num_options = (num + 1 - istart) / 4L

if (num_options lt 1) then begin
	; no mission found
	tle = -1L
	print, 'ERROR: mission TLE not found'
	if keyword_set(debug) then stop, 'DEBUG error-3 ...'
	return
endif else if (num_options eq 1) then begin
	;  only one mission found
	tle = result[istart:istart+2]
endif else begin
	; multiple missions found so ask user to select which one
	print, ' '
	print, '***  Select Spacecraft  ***'
	for k=0,num_options-1 do $
	  print, string(k+1,format='(I4)'), ' = ', strmid(result[istart+k*4L],2,strlen(result[istart+k*4L])-2)
    choice=0L
    read, '>>>>> Enter spacecraft choice: ', choice
    print, ' '
    if (choice lt 1) then choice=1
    if (choice gt num_options) then choice=num_options
    iselect = istart + (choice-1)*4L
    tle = result[iselect:iselect+2]
endelse

;
;	3.	Option: Output this TLE to its TLE history file
;
;	option to append latest TLE to spacecraft TLE file in $TLE_dir
;
if keyword_set(output) then begin
	spacecraft_id = long(strmid(tle[1],2,5))
	out_file = path + string(spacecraft_id,format='(I08)') + '.tle'
	filename = file_search( out_file, count=fcount )
	if (fcount ge 1) then begin
		openu, lun, out_file, /get_lun
		doWrite = 0
		tle0 = ' ' & tle1 = ' ' & tle2 = ' '
		while not(eof(lun)) do begin
			if not(eof(lun)) then readf, lun, tle0
			if not(eof(lun)) then readf, lun, tle1
			if not(eof(lun)) then readf, lun, tle2
		endwhile
		last_tle_time = float( strmid(tle1, 19, 14) )
		now_tle_time = float( strmid(tle[1], 19, 14) )
		if (now_tle_time gt last_tle_time) then doWrite = 1
	endif else begin
		openw, lun, out_file, /get_lun
		doWrite = 1
	endelse
	if (doWrite ne 0) then begin
		; write the TLE now
		printf, lun, tle[0]  ; , ' ; updated ', systime()  ; extra characters corrupt for spacecraft_pv reading TLE
		printf, lun, tle[1]
		printf, lun, tle[2]
		; if keyword_set(verbose) then
		print, 'Appending new TLE to ', out_file
	endif else print, 'TLE update is not needed in ', out_file
	close, lun
	free_lun, lun
endif

;
; Write the TLEs for MinXSS, CADRE, and ISS to file for SatPC use
;
; File-1 = $SATPC_TLE_dir/minxss.tle
; File-2 = $Dropbox_dir/tle/minxss.tle
;
; Each file has the mission name followed by the Two-Line-Element values
;
if keyword_set(SatPC) then begin
  tle_strings = strarr(3*3L)
  cnt = 0L
  for k=0,2 do begin
    switch k of
      0: begin
           mname = mission1
           mid = mission1_id
           mname_save = mission1pc
         break
         end
      1: begin
           mname = mission2
           mid = mission2_id
           mname_save = mission2pc
         break
         end
      2: begin
           mname = mission3
           mid = mission3_id
           mname_save = mission3pc
         break
         end
     endswitch

      ; get TLE list from catalog
      ; result = tle_find_in_file( mname, catalog )
      result = tle_satid_find_in_file( mid, catalog )

      num = n_elements(result)
      if (num lt 3) then begin
        ; mission not found
        tle = -1L
        print, 'SATPC ERROR: mission ', mname, ' not found'
      endif

      ; search for first line with "0 "
      istart = 0L
      for j=0L,num-1 do begin
         if strmid(result[j],0,2) eq '0 ' then break
      endfor
      istart = j

      if (istart ge num) then begin
        ; mission not found
        tle = -1L
        print, 'SATPC ERROR: mission ', mname, ' not found'
      endif

      num_options = (num + 1 - istart) / 4L

      if (num_options lt 1) then begin
        ; no mission found
        tle = -1L
        print, 'SATPC ERROR: mission ', mname, ' not found'
      endif else if (num_options eq 1) then begin
        ;  only one mission found
        tle = result[istart:istart+2]
      endif else begin
        ; multiple missions found so ask user to select which one
        print, ' '
        print, '***  Select Spacecraft  ***'
        for j=0,num_options-1 do $
          print, string(j+1,format='(I4)'), ' = ', $
          		strmid(result[istart+j*4L],2,strlen(result[istart+j*4L])-2)
        choice=0L
        read, '>>>>> Enter spacecraft choice: ', choice
        print, ' '
        if (choice lt 1) then choice=1
        if (choice gt num_options) then choice=num_options
        iselect = istart + (choice-1)*4L
        tle = result[iselect:iselect+2]
      endelse
      ;  save TLE result
      if (n_elements(tle) ge 2) then begin
        tle_strings[cnt*3] = mname_save
        tle_strings[cnt*3+1] = tle[1]
        tle_strings[cnt*3+2] = tle[2]
        cnt += 1L
      endif
    endfor

    ;
    ;  Write File 1
    ;
    file1 = getenv('SATPC_TLE_dir')
    if strlen(file1) ne 0 then file1 += slash
    if (do_Minxss2 ne 0) then satpc_file = 'minxss2.tle' else satpc_file = 'minxss.tle'
    file1 += satpc_file
    if keyword_set(verbose) then print, 'SATPC file written to ', file1
    openw, lun, file1, /get_lun
    for k=0,cnt-1 do begin
      for j=0,2 do printf,lun,tle_strings[k*3+j]
      if (k eq 0) then begin
      		printf,lun,'MINXSS_LO'
      		printf,lun,tle_strings[1]
      		printf,lun,tle_strings[2]
      		printf,lun,'MINXSS_HI'
      		printf,lun,tle_strings[1]
      		printf,lun,tle_strings[2]
      endif
    endfor
    close, lun
    ;
    ;  Write File 2
    ;
    file2 = getenv('Dropbox_dir')
    if strlen(file2) ne 0 then file2 += slash + 'tle' + slash
    file2 += satpc_file
    if keyword_set(verbose) then print, 'SATPC file written to ', file2
    openw, lun, file2, /get_lun
    for k=0,cnt-1 do begin
      for j=0,2 do printf,lun,tle_strings[k*3+j]
    endfor
    close, lun
    free_lun, lun
endif

if keyword_set(debug) then begin
	stop, 'DEBUG tle_download_latest results ...'
endif

return
end
