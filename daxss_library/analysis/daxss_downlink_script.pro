;+
; NAME:
;   daxss_downlink_script.pro
;
; PURPOSE:
;   Calculate SD-card offsets for DAXSS packets based on time input
;
; INPUTS:
;   yyyydoy		Long or Double for Year and Day of Year
;	  HH, MM, SS	Optional input for Hours, Minutes, Seconds
;
;	OPTIONAL INPUTS:
;	  time_iso [string]: Timestamp in ISO8601 UTC format, e.g., 2022-03-23T14:19:20Z.
;	                     Can also be "human" format, leaving out the T and Z;
;						 e.g., 2022-03-23 14:19:20
;	                     Can specify instead of yyyydoy, hh, mm, ss.
;	  saveloc [string]:  The path to save the output script to. Defaults to './'
;	  class [string]:    The flare class (or really any string you want) to be included
;						 in the filename, if any.
;	  minutes_before_flare [float]: The number of minutes before the flare that you
;						want downlinked. Default is 5.
;	  minutes_after_flare [float]:  The number of minutes after the flare that you
;						want downlinked. Default is 10.
;	  plot_sd			Plot SD-card write offsets for validation of script
;
; KEYWORD PARAMETERS:
;   /uhf		Calculate Downlink length appropriate for UHF (default)
;	/sband		Calculate Downlink length appropriate for S-Band
;	/verbose	Print debug messages
;
; OUTPUTS:
;   scid_range	Range of SD-card write offsets for SCID (Science DAXSS)
;
; COMMON BLOCKS:
;   None.
;
; RESTRICTIONS:
;   Requires DAXSS Level 0C merged data product
;
; PROCEDURE:
;   1. Task 1A: Find / read latest DAXSS Level 0C merged data product
;	   Task 1B: Read INSPIRESat-1 SD-Card list for time history when SD cards were active
;   2. Task 2A: Check that time period has valid SD card option (only SD-1 and SD-2 can be downlinked)
;	   Task 2B: Calculate and output the range for the data downlink
;	3. Task 3: Write Hydra Script for downlink
;
; HISTORY
;	2022-03-08	T. Woods, identify SD_WRITE_SCID offsets for given time
;	2022-03-23  James Paul Mason: Added time_iso optional input.
;	2022-03-24  James Paul Mason: Updated extrapolation method to use linfit of last 100 points. Also added Hydra script generation.
;	2022-10-02	T. Woods: Updated to extrapolate only for maximum of 2 days
;	2023-02-08	T. Woods: Updated to interpolate only and scripts identified for SD-1 or SD-2 being active
;					This requires running is1_make_sd_card_list.pro first
;					and then editing the is1_sd_card_list_v2.0.0.dat file
;	2023-10-31	T. Woods:  Updated to use SBAND script template file for the /SBAND option
;
;+
PRO daxss_downlink_script, yyyydoy_in, hh_in, mm_in, ss_in, $
                           time_iso=time_iso, saveloc=saveloc, class=class, $
                           minutes_before_flare=minutes_before_flare, $
                           minutes_after_flare=minutes_after_flare, $
                           UHF=UHF, SBAND=SBAND, plot_sd=plot_sd, $
                           scid_range=scid_range, verbose=verbose, debug=debug

; Defaults
if keyword_set(debug) then verbose=1
if not keyword_set(SBAND) OR keyword_set(UHF) then useUHF = 1 else useUHF = 0

if n_params() lt 1 then begin
  IF time_iso EQ !NULL THEN BEGIN
	 print, 'USAGE: daxss_downlink_script, yyyydoy, hh, mm, ss, time_iso=time_iso, /uhf, /sband, /verbose'
   return
  ENDIF
endif ELSE BEGIN
  ; Convert DOY input (if provided) to ISO
  yyyydoy = strtrim(long(yyyydoy_in), 2)
  if hh_in EQ !NULL then hh_in = 12
  IF hh_in LT 10 THEN hh = '0' + strmid(strtrim(hh_in, 2), 0, 1) ELSE hh = strmid(strtrim(hh_in, 2), 0, 2)
  IF mm_in EQ !NULL THEN mm_in = 0
  IF mm_in LT 10 THEN mm = '0' + strmid(strtrim(mm_in, 2), 0, 1) ELSE mm = strmid(strtrim(mm_in, 2), 0, 2)
  IF ss_in EQ !NULL THEN ss_in = 0
  IF ss_in LT 10 THEN ss = '0' + strmid(strtrim(ss_in, 2), 0, 1) ELSE ss = strmid(strtrim(ss_in, 2), 0, 2)
  time_iso = jpmjd2iso(JPMyyyyDoy2JD(yyyydoy + hh + mm + ss))
ENDELSE
IF saveloc EQ !NULL THEN BEGIN
  ; saveloc = '.' + path_sep()
  saveloc = getenv('minxss_data') + path_sep() + 'flares' + path_sep() + 'daxss' $
  			+ path_sep() + 'scripts' + path_sep()
ENDIF
IF minutes_before_flare EQ !NULL THEN minutes_before_flare = 5.
IF minutes_after_flare EQ !NULL THEN minutes_after_flare = 10.

;
;   1. Task 1A: Find / read latest DAXSS Level 0C merged data product
;		Changed from fm4 to fm3 on 5/24/2022, TW
;
dpath = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'level0c' + path_sep()
dfile0c = 'daxss_l0c_all_mission_length_*.sav'
theFiles = file_search( dpath + dfile0c, count=fileCount )
if (fileCount lt 1) then begin
	print, 'ERROR: DAXSS Level 0C file not found.'
	return
endif

common daxss_plot_flare2_common, daxss_level1_data, hk, hk_jd, sci, sci_jd, picosim2,  $
						goes, goes_year, goes_jd
if (hk eq !NULL) then begin
	if keyword_set(VERBOSE) then print, 'Reading file ', theFiles[fileCount-1], ' ...'
	;  PACKETS in Level 0C: hk, sci, log, dump
	restore, theFiles[fileCount-1]
	hk_jd = hk.time_jd
	sci_jd = sci.time_jd
	; make picosim2 time series too
	picosim2 = reform(sci.picosim_data[2]) / (sci.picosim_integ_time/1000.)
endif

;
;   1. Task 1B: Read INSPIRESat-1 SD-Card list for time history when SD cards were active
;
sd_dir = getenv('minxss_data') + path_sep() + 'fm3' + path_sep() + 'sd_card' + path_sep()
sd_file = 'is1_sd_card_list_v*.dat'
theFiles2 = file_search( sd_dir + sd_file, count=fileCount2 )
if (fileCount2 lt 1) then begin
	print, 'ERROR: INSPIRESat-1 SD-Card List file not found.'
	return
endif
if keyword_set(VERBOSE) then print, 'Reading file ', theFiles2[fileCount2-1], ' ...'
;  read array of time (YYYYDOY) and active SD card number
sd_list = read_dat( theFiles2[fileCount2-1] )
sd_jd = yd2jd( reform(sd_list[0,*]) )
sd_number = long(reform(sd_list[1,*]))

;
;	2. Task 2A: Check that time period has valid SD card option (only SD-1 and SD-2 can be downlinked)
;
time_iso_temp = time_iso[0] ; So time_iso will not go to !NULL when calling JPMiso2jd
jd_center = JPMiso2jd(time_iso_temp)
if jd_center lt min(hk.time_jd) then begin
	print, 'ERROR: Input Time is before the INSPIRESat-1 mission !'
	return
endif
if jd_center gt max(hk.time_jd) then begin
	hk_yd_max = long(jd2yd(max(hk.time_jd)))
	print, 'ERROR: Input Time is after the HK maximum date of '+strtrim(hk_yd_max,2)
	ans = 'Y'
	; read, 'Do you want to extrapolate SD-card offsets (else quits) ? (Y/N) ', ans
	if (strmid(strupcase(ans),0,1) ne 'Y') then return
endif

; make clean array of HK
wgood = where( (hk.SD_WRITE_SCID gt 0) and (hk.SD_WRITE_BEACON gt 0), num_good )
if (num_good lt 2) then begin
	print, 'ERROR: There are not enough HK packets !'
	return
endif
hk_time_jd = hk[wgood].time_jd
hk_sd_write_scid = hk[wgood].SD_WRITE_SCID
hk_sd_write_beacon = hk[wgood].SD_WRITE_BEACON
hk_x123_on = (hk[wgood].DAXSS_CDH_ENABLES AND '0002'X)

; verify DAXSS is on before proceeding
is_X123_on = interpol( hk_x123_on, hk_time_jd, jd_center*[1,1.] )
if (is_X123_on[0] lt 1.99) then begin
	print, 'ERROR: DAXSS X123 is not ON for this time !'
	return
endif

; identify which SD card is active for the input time
ww=where(jd_center gt sd_jd, wnum)
if (wnum eq 0) then begin
	print, 'ERROR: Input Time is before the INSPIRESat-1 mission !'
	return
endif
if (useUHF ne 0) then begin
	sd_active = sd_number[ww[-1]]
	if (sd_active eq 0) then begin
		print, 'ERROR: DAXSS Downlink is not done for FLASH memory !'
		return
	endif
	if (sd_active ne 1) AND (sd_active ne 2) then begin
		print, 'ERROR: DAXSS Downlink is not possible for this time !'
		return
	endif
endif else begin
	; SBAND is always SD card #1
	sd_active = sd_number[ww[-1]]
	if (sd_active ne 1) then begin
		print, 'ERROR: DAXSS Downlink is not possible for this time !'
		return
	endif
endelse
sd_active_str = 'SD' + strtrim(long(sd_active),2)

;
;   2. Task 2B: Calculate and output the range for the data downlink
;
jd_range = jd_center + [-1. * minutes_before_flare/1440., minutes_after_flare/1440.]
hk_jd = hk_time_jd  ; daxss_extrapolate_sd_offset() modifies the hk_jd variable
scid_range = daxss_extrapolate_sd_offset(hk_jd, hk_sd_write_scid, jd_range)
hk_jd = hk_time_jd  ; daxss_extrapolate_sd_offset() modifies the hk_jd variable
hk_range = daxss_extrapolate_sd_offset(hk_jd, hk_sd_write_beacon, jd_range)

;	check for error conditions of finding SD offsets
IF (finite(scid_range) EQ [0]) OR (finite(hk_range) EQ [0]) THEN begin
	message, /INFO, 'ERROR finding valid SD offsets. No script being made.'
	return
endif
IF (scid_range[1] le scid_range[0]) OR (hk_range[1] le hk_range[0]) THEN begin
	message, /INFO, 'ERROR finding increasing SD offsets. No script being made.'
	return
endif

print, ' '
print, 'SD-card SCID range is ', jpmprintnumber(scid_range[0], /NO_DECIMALS), ' to ', JPMPrintNumber(scid_range[1], /NO_DECIMALS), ' for ', time_iso
print, 'SD-card HK (Beacon) range is ', jpmprintnumber(hk_range[0], /NO_DECIMALS), ' to ', JPMPrintNumber(hk_range[1], /NO_DECIMALS), ' for ', time_iso
print, ' '

;
;	Plot SD-card write offset values for validation
;		Variables of hk[wgood] are hk_time_jd, hk_sd_write_scid, and hk_sd_write_beacon
;
;	Option to extrapolate fit for solution too
;
if keyword_set(plot_sd) then begin
 ; limited range is +/- 10 days
 wplot = where( (hk_time_jd ge (jd_center-10L)) and (hk_time_jd le (jd_center+10L)), numplot)
 if (numplot gt 2) then begin
 	setplot & cc=rainbow(7)
	cc_scid = poly_fit( hk_time_jd[wplot], hk_sd_write_scid[wplot], 1)
	fit_jd = findgen(21L) + jd_center-10.D0
	fit_scid = cc_scid[0] + cc_scid[1]*fit_jd
 	yrange = [min(fit_scid), max(fit_scid)] & xrange = [fit_jd[0]-1., fit_jd[-1]+1.]
 	plot, hk_time_jd[wplot], hk_sd_write_scid[wplot], psym=4, yr=yrange, ys=1, xr=xrange, xs=1, $
 			ytitle='SD_WRITE_SCID', XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
	oplot, fit_jd, fit_scid, color=cc[3]
	oplot, jd_range, scid_range, color=cc[0], psym=5
	better_scid = cc_scid[0] + cc_scid[1]*jd_range
	diff_ok = 100L
	ans = ' '
	if abs(better_scid[0] - scid_range[0]) gt diff_ok then begin
		print, 'WARNING:  Fitted  SCID Range is ', better_scid[0], better_scid[1]
		print, '    BUT:  Current SCID Range is ', scid_range[0], scid_range[1]
		read, 'Do you want to use the Fitted SCID range instead ? (Y/N) ',ans
		if (strmid(strupcase(ans),0,1) eq 'Y') then scid_range = better_scid
		print, ' '
	endif
	read, 'Ready for Beacon offset plot ? ', ans
	cc_beacon = poly_fit( hk_time_jd[wplot], hk_sd_write_beacon[wplot], 1)
	fit_beacon = cc_beacon[0] + cc_beacon[1]*fit_jd
 	yrange2 = [min(fit_beacon), max(fit_beacon)]
 	plot, hk_time_jd[wplot], hk_sd_write_beacon[wplot], psym=4, yr=yrange2, ys=1, $
 			xr=xrange, xs=1, $
 			ytitle='SD_WRITE_BEACON', XTICKFORMAT='LABEL_DATE', XTICKUNITS=['Time','Time']
	oplot, fit_jd, fit_beacon, color=cc[3]
	oplot, jd_range, hk_range, color=cc[0], psym=5
	better_beacon = cc_beacon[0] + cc_beacon[1]*jd_range
	diff_ok2 = 10L
	ans = ' '
	if abs(better_beacon[0] - hk_range[0]) gt diff_ok2 then begin
		print, 'WARNING:  Fitted  BEACON Range is ', better_beacon[0], better_beacon[1]
		print, '    BUT:  Current BEACON Range is ', hk_range[0], hk_range[1]
		read, 'Do you want to use the Fitted BEACON range instead ? (Y/N) ',ans
		if (strmid(strupcase(ans),0,1) eq 'Y') then hk_range = better_beacon
		print, ' '
	endif
	read, 'Ready to continue ? ', ans
 endif else BEGIN
 	stop, 'ERROR: there are no SD WRITE offset values in range...'
 endelse
ENDIF
;
;	3. Task 3: Write Hydra Script for downlink
;

; Read in the playback flare template
if (useUHF ne 0) then begin
  filename = getenv('minxss_code') + path_sep() + 'daxss_library' + path_sep() + 'analysis' $
		+ path_sep() + 'playback_flare_template.prc'
endif else begin
	; SBAND template file
  filename = getenv('minxss_code') + path_sep() + 'daxss_library' + path_sep() + 'analysis' $
		+ path_sep() + 'playback_flare_card1_sband.prc'
endelse
finfo = file_info(filename)
openr, lun, filename, /GET_LUN
scriptbytes = bytarr(finfo.size)
readu, lun, scriptbytes
close, lun
free_lun, lun

; Populate the values in the script
filledscript = string(scriptbytes)
filledscript = strreplace(filledscript, ['<THKstartSector>', '<THKstopSectorOffsetFromStart>', '<TSCIstartSector>'], $
                          strtrim(long([hk_range[0], (hk_range[1] - hk_range[0]), scid_range[0]]),2))

; Write the file to disk
time_iso_name = time_iso[0]
; remove colons in time stamp
while (strpos(time_iso_name,':') ge 0) do begin
	pc = strpos(time_iso_name,':')
	slen = strlen(time_iso_name)
	if (pc eq 0) then time_new = strmid(time_iso_name,1,slen-1) $
	else if (pc eq (slen-1)) then time_new = strmid(time_iso_name,0,slen-1) $
	else time_new = strmid(time_iso_name,0,pc) + strmid(time_iso_name,pc+1,slen-pc-1)
	time_iso_name = time_new
endwhile
new_file = sd_active_str + '_playback_flare_' + time_iso_name
if (useUHF eq 0) then new_file = 'SBAND_' + new_file + '.prc' else begin
	; only add the CLASS for UHF playbacks
	IF class NE !NULL THEN new_file = new_file + '_' + class + '.prc' ELSE new_file+='.prc'
endelse
filename = saveloc+new_file
print, 'Saving new flare playback script in ', filename
openw, lun, filename, /get_lun
printf, lun, filledscript
close, lun
free_lun, lun


if keyword_set(DEBUG) then begin
	stop, 'DEBUG daxss_downlink_script ...'
endif

return
end
