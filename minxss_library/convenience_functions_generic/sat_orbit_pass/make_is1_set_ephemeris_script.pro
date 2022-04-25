;
; make_is1_set_ephemeris.pro
;
; Purpose:  generate the InspireSat-1 (IS1) Ephemeris script (needed once per week)
;
; INPUTS
;   yr, mo, day, hr, mn, sec     UTC Date/Time for ephemeris calculation (usually middle of pass)
;   script_path                 Optional input (default is it uses $TLE_dir/India/scripts/)
;	/latest						Option to make latest ephemeris script
;   /verbose
;
; OUTPUT
;   File is generated in HYDRA Scripts directory called is1_set_ephemeris_yymmdd_hhmm.prc
;
; Ephemeris can be validated with conversion of ECEF values to LLH at
;     http://www.oc.nps.edu/oc2902w/coord/llhxyz.htm
;     Those values should be near IIST Ground Station (8.6 Lat, 77.0 Long)
;
; History
;   6/17/16 Amir Caspi    Original Code
;   6/25/16 Tom Woods   Updated with comments
;   11/2/16 Tom Woods   Updated with /latest option so filename is set_ephemeris_latest.prc
;   12/6/18 Tom Woods   Updated for MinXSS-2 file saveset
;	02/26/22 Tom Woods	Created for IS1 using make_set_ephemeris.pro used by MinXSS
;
PRO make_is1_set_ephemeris_script, yr, mo, day, hr, mn, sec, $
			script_path = script_path, verbose = verbose, latest=latest

  ;
  ; Set script path
  ;
  ;  slash for Mac = '/', PC = '\'
  ;  File Copy for Mac = 'cp', PC = 'copy'
  if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
  endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
  endelse

  IF keyword_set(script_path) THEN BEGIN
    path_name = script_path
  ENDIF ELSE BEGIN
    ;  default is to use directory $TLE_dir/India/scripts/
    ;  ***** changed for IS-1 *****
    path_name = getenv('TLE_dir') + slash + 'India' + slash + 'scripts'
    ; else path_name is empty string
  ENDELSE
  IF strlen(path_name) GT 0 THEN BEGIN
    ; check if need to remove end of string back slash
    spos = strpos(path_name, slash, /reverse_search )
    slen = strlen(path_name)
    IF (spos EQ (slen-1)) THEN path_name = strmid( path_name, 0, slen-1 )
  ENDIF
  IF keyword_set(debug) THEN print, '*** Script path = ', path_name

if keyword_set(latest) then begin
  ; Load latest Pass times and find next good pass to setup the input variables for "latest" ephemeris
  path2_name = getenv('TLE_dir')
  if strlen(path2_name) gt 0 then begin
    if ((strpos(path2_name,slash,/reverse_search)+1) lt strlen(path2_name)) then path2_name += slash
  endif
  path_dropbox = path2_name + 'India' + slash  ; ***** changed for IS-1 *****
  file_passes = 'passes_latest_INDIA.sav'
  ;  restore "passes" data structure
  restore, path_dropbox + file_passes
  jd_now = systime( /julian ) - 5.5/24.D0  ; also convert IST to UT ***** changed for IS-1 *****
  jd_now = jd_now + 1./24.D0   ; look 1 hour from now for next good pass
  ; ***** changed 30 deg elevation to 40 deg elevation for IS-1 *****
  ELEVATION_MIN = 40.  ; same value used by minxss_satellite_pass, /auto_pass
  wgood = where( (passes.start_jd gt jd_now) and (passes.max_elevation gt ELEVATION_MIN), num_good )
  if (num_good lt 1) then begin
    print, 'ERROR finding a future good pass for is1_set_ephemeris_latest.  Exiting...'
    ; stop, 'DEBUG...'
    return
  endif
  best_jd = passes[wgood[0]].start_jd
  best_jd = best_jd + 5./(24.D0*60.)  ; add 5 minutes so ephemeris is in middle of pass
  ;  configure the input variables with this best_jd
  caldat, best_jd, mo, day, yr, hr, mn, sec
  if keyword_set(verbose) then print, 'Ephemeris Latest is for ', yr, mo, day, hr, mn, sec
endif else begin
  ; Calculate fractional day if needed
  if (n_params() lt 6) then sec = 0.
  if (n_params() lt 5) then mn = 0.
  if (n_params() lt 4) then hr = 12.0
  if (n_params() lt 3) then begin
     print, 'USAGE:  make_is1_set_ephemeris_script, yr, mo, day, hr, mn, sec, script_path=script_path, /verbose'
     print, 'ERROR:  invalid parameters (need at least 3), so no Script file created.'
     return
  endif
  if keyword_set(verbose) then print, 'Ephemeris User Date is for ', yr, mo, day, hr, mn, sec
endelse

fracday = hr/24. + mn/60./24. + sec/60./60./24.

; fix year to be greater than 2022
if (yr lt 2022) or (yr gt 2040) then begin
  if (yr ge 22) and (yr le 40) then begin
      yr = 2000 + yr
      print, 'WARNING:  changing YEAR to be ', yr
  endif else begin
      print, 'ERROR with YEAR value, exiting...'
      return
  endelse
endif

; always make verbose
verbose = 1

  ;
  ;  read set_ephemeris_template file
  ;
  filename = path_name+slash+'is1_set_ephemeris_template.prc'
  finfo = file_info(filename)

  openr, lun, filename, /get_lun
  scriptbytes = bytarr(finfo.size)
  readu, lun, scriptbytes
  close, lun
  free_lun, lun

  jd_start = ymd2jd(yr, mo, day + fracday)
  IS1_SAT_ID = 51657L  ; 2/16/22 solution (might change!)
  spacecraft_location, id_satellite=IS1_SAT_ID, jd_start, location, sunlight, eci_pv = pv, /J2000, verbose=verbose
;  pv = [123.456, 456.789, -789.000, 321.123, -654.456, 987.789] ; TESTING PURPOSES

  filledscript = string(scriptbytes)
  filledscript = strreplace(filledscript, ['<TephYear>', '<TephMonth>', '<TephDay>', '<TephHour>', '<TephMinute>', '<TephSecond>'], strtrim(fix([yr - 2000, mo, day, hr, mn, sec]),2))
  filledscript = strreplace(filledscript, ['<TephPosX>', '<TephPosY>', '<TephPosZ>', '<TephVelX>', '<TephVelY>', '<TephVelZ>'], strtrim(pv,2))

  date_str = string(long(yr),format='(I04)') + string(long(mo),format='(I02)') + string(long(day),format='(I02)') + $
        '_' + string(long(hr),format='(I02)') + string(long(mn),format='(I02)') + 'UT'
  new_file = 'is1_set_ephemeris_' + date_str + '.prc'
  filename = path_name+slash+new_file
  print, 'Saving New Ephemeris script in ', filename
  openw, lun, filename, /get_lun
  printf, lun, filledscript
  close, lun
  free_lun, lun
  ;
  ;	also save "latest" file if so requested
  if keyword_set(latest) then begin
    new_file2 = 'is1_set_ephemeris_latest.prc'
	filename2 = path_name+slash+new_file2
	print, 'Saving "Latest" Ephemeris script in ', filename2
	openw, lun, filename2, /get_lun
	printf, lun, filledscript
	close, lun
	free_lun, lun
  endif

  ; do not copy to Boulder Hydra as IS1 operations are not at LASP
  ; scripts_dir = getenv('Dropbox_root_dir')+slash+'Hydra'+slash+'MinXSS'+slash
  ; scripts_Boulder = scripts_dir + 'HYDRA_FM-2_Boulder' + slash + 'Scripts' + slash
  ; print, '*** Also saving this into ', scripts_Boulder
  ; copy_cmd = file_copy + '"' + filename + '" "' + scripts_Boulder+new_file + '"'
  ; spawn, copy_cmd, exit_status=status

END
