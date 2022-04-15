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
;	  time_iso [string]:            Timestamp in ISO8601 UTC format, e.g., 2022-03-23T14:19:20Z.
;	                                Can also be "human" format, leaving out the T and Z; e.g., 2022-03-23 14:19:20
;	                                Can specify instead of yyyydoy, hh, mm, ss.
;	  saveloc [string]:             The path to save the output script to. Defaults to './'
;	  class [string]:               The flare class (or really any string you want) to be included in the filename, if any.
;	  minutes_before_flare [float]: The number of minutes before the flare that you want downlinked. Default is 5.
;	  minutes_after_flare [float]:  The number of minutes after the flare that you want downlinked. Default is 10.
;
; KEYWORD PARAMETERS:
;   /uhf		Calculate Downlink length appropriate for UHF (default)
;	  /sband		Calculate Downlink length appropriate for S-Band
;	  /verbose	Print debug messages
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
;   1. Task 1: Find / read latest DAXSS Level 0C merged data product
;   2. Task 2: Interpolate SD_WRITE_SCID for input time
;   3. Task 3: Calculate and output the range for the data downlink
;	  4. Task 4: Write Hydra Script for downlink  (TBD)
;
; HISTORY
;	2022-03-08	T. Woods, identify SD_WRITE_SCID offsets for given time
;	2022-03-23  James Paul Mason: Added time_iso optional input.
;	2022-03-24  James Paul Mason: Updated extrapolation method to use linfit of last 100 points. Also added Hydra script generation. 
;
;+
PRO daxss_downlink_script, yyyydoy, hh, mm, ss, $
                           time_iso=time_iso, saveloc=saveloc, class=class, minutes_before_flare=minutes_before_flare, minutes_after_flare=minutes_after_flare, $
                           UHF=UHF, SBAND=SBAND, $
                           scid_range=scid_range, verbose=verbose

; Defaults
if n_params() lt 1 then begin
  IF time_iso EQ !NULL THEN BEGIN
	 print, 'USAGE: daxss_downlink_script, yyyydoy, hh, mm, ss, time_iso=time_iso, /uhf, /sband, /verbose'
   return
  ENDIF
endif ELSE BEGIN
  ; Convert DOY input (if provided) to ISO
  yyyydoy = strtrim(yyyydoy, 2)
  hh = strtrim(hh, 2)
  IF mm EQ !NULL THEN mm = '00'
  IF ss EQ !NULL THEN ss = '00'
  time_iso = jpmjd2iso(JPMyyyyDoy2JD(yyyydoy + hh + mm + ss))
ENDELSE
IF saveloc EQ !NULL THEN BEGIN
  saveloc = './'
ENDIF
IF minutes_before_flare EQ !NULL THEN minutes_before_flare = 5.
IF minutes_after_flare EQ !NULL THEN minutes_after_flare = 10.

;
;   1. Task 1: Find / read latest DAXSS Level 0C merged data product
;
dpath = getenv('minxss_data') + '/fm4/level0c/'
dfile0c = 'daxss_l0c_all_mission_length_*.sav'
theFiles = file_search( dpath + dfile0c, count=fileCount )
if (fileCount lt 1) then begin
	print, 'ERROR: DAXSS Level 0C file not found.'
	return
endif
if keyword_set(VERBOSE) then print, 'Reading file ', theFiles[fileCount-1], ' ...'
;  PACKETS in Level 0C: hk, sci, log, dump
restore, theFiles[-1]

;
;   2. Task 2: Interpolate SD_WRITE_SCID for input time
;		convert hk.daxss_time from GPS time to JD
;		and convert input time to JD
;
hkjd = gps2jd( hk.daxss_time )

;
;   3. Task 3: Calculate and output the range for the data downlink
;
time_iso_temp = time_iso ; So time_iso will not go to !NULL when calling JPMiso2jd
centerJD = JPMiso2jd(time_iso_temp)
if centerJD lt min(hkjd) then begin
	print, 'ERROR: Input Time is not in time range for InspireSat-1 mission !'
	return
endif
jd_range = centerJD + [-1. * minutes_before_flare/1440., minutes_after_flare/1440.]
scid_range = daxss_extrapolate_sd_offset(hkjd, hk.sd_write_scid, jd_range)
hk_range = daxss_extrapolate_sd_offset(hkjd, hk.sd_write_beacon, jd_range)
print, ' '
print, 'SD-card SCID range is ', jpmprintnumber(scid_range[0], /NO_DECIMALS), ' to ', JPMPrintNumber(scid_range[1], /NO_DECIMALS), ' for ', time_iso
print, 'SD-card HK (Beacon) range is ', jpmprintnumber(hk_range[0], /NO_DECIMALS), ' to ', JPMPrintNumber(hk_range[1], /NO_DECIMALS), ' for ', time_iso
print, ' '

;
;	4. Task 4: Write Hydra Script for downlink
;

; Read in the playback flare template
filename = getenv('minxss_code') + path_sep() + 'daxss_library' + path_sep() + 'analysis' + path_sep() + 'playback_flare_template.prc'
finfo = file_info(filename)
openr, lun, filename, /GET_LUN
scriptbytes = bytarr(finfo.size)
readu, lun, scriptbytes
close, lun
free_lun, lun

; Populate the values in the script
filledscript = string(scriptbytes)
filledscript = strreplace(filledscript, ['<THKstartSector>', '<THKstopSectorOffsetFromStart>', '<TSCIstartSector>', '<TSCIstopSectorOffsetFromStart>'], $
                          strtrim(long([hk_range[0], (hk_range[1] - hk_range[0]), scid_range[0], (scid_range[1] - scid_range[0])]),2))

; Write the file to disk
new_file = 'playback_flare_' + time_iso
IF class NE !NULL THEN new_file = new_file + '_' + class + '.prc' ELSE new_file+='.prc'
filename = saveloc+new_file
print, 'Saving new flare playback script in ', filename
openw, lun, filename, /get_lun
printf, lun, filledscript
close, lun
free_lun, lun


if keyword_set(VERBOSE) then begin
	stop, 'DEBUG daxss_downlink_script ...'
endif

return
end
