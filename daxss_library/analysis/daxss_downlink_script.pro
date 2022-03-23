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
;	                     Can also be "human" format, leaving out the T and Z; e.g., 2022-03-23 14:19:20
;	                     Can specify instead of yyyydoy, hh, mm, ss. 
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
;   Requires DAXSS Level 0B merged data product
;
; PROCEDURE:
;   1. Task 1: Find / read latest DAXSS Level 0B merged data product
;   2. Task 2: Interpolate SD_WRITE_SCID for input time
;   3. Task 3: Calculate and output the range for the data downlink
;	  4. Task 4: Write Hydra Script for downlink  (TBD)
;
; HISTORY
;	2022-03-08	T. Woods, identify SD_WRITE_SCID offsets for given time
;	2022-03-23  James Paul Mason: Added time_iso optional input. 
;
;+
PRO daxss_downlink_script, yyyydoy, hh, mm, ss, $
                           time_iso=time_iso, $
                           UHF=UHF, SBAND=SBAND, $
                           scid_range=scid_range, verbose=verbose

if n_params() lt 1 then begin
  IF time_iso EQ !NULL THEN BEGIN
	 print, 'USAGE: daxss_downlink_script, yyyydoy, hh, mm, ss, /uhf, /sband, /verbose'
   return
  ENDIF
endif

;
;   1. Task 1: Find / read latest DAXSS Level 0B merged data product
;
dpath = getenv('minxss_data') + '/fm4/level0b/'
dfile0b = 'daxss_l0b_merged_20*.sav'
theFiles = file_search( dpath + dfile0b, count=fileCount )
if (fileCount lt 1) then begin
	print, 'ERROR: DAXSS Level 0B file not found.'
	return
endif
if keyword_set(VERBOSE) then print, 'Reading file ', theFiles[fileCount-1], ' ...'
;  PACKETS in Level 0B: hk, sci, log, dump
restore, theFiles[fileCount-1]

;
;   2. Task 2: Interpolate SD_WRITE_SCID for input time
;		convert hk.daxss_time from GPS time to JD
;		and convert input time to JD
;
hkjd = gps2jd( hk.daxss_time )

IF time_iso EQ !NULL THEN BEGIN
  if n_params() lt 2 then begin
  	theYD = yyyydoy
  endif else begin
  	if (n_params() lt 4) then ss = 0.
  	if (n_params() lt 3) then mm = 0.
  	theYD = yyyydoy + (hh + mm/60. + ss/3600.)/24.D0
  endelse
ENDIF

;
;   3. Task 3: Calculate and output the range for the data downlink
;		Add time centered on the input time
;			UHF: 5 minutes = 300 sec * 2 packets/sec = 600 total packets
;			S-BAND: 5 minutes = 300 sec * 100 packets/sec = 30000L total packets
;
if keyword_set(SBAND) then total_packets = 300L * 100L $
else total_packets = 300L * 2L
half_total = total_packets/2L
half_time = (300./3600./24.D0) / 2.
IF time_iso EQ !NULL THEN BEGIN
  centerJD = yd2jd( theYD )
ENDIF ELSE BEGIN
  time_iso_temp = time_iso ; So time_iso will not go to !NULL when calling JPMiso2jd
  centerJD = JPMiso2jd(time_iso_temp)
ENDELSE
if (centerJD lt min(hkjd)) OR (centerJD gt max(hkjd)) then begin
	print, 'ERROR: Input Time is not in time range for InspireSat-1 mission !'
	return
endif
theJD = centerJD + [-1.*half_time, half_time]
scid_range = interpol( hk.sd_write_scid, hkjd, theJD )
print, ' '
IF theYD NE !NULL THEN BEGIN
  print, 'SD-card SCID range is ', long(scid_range), ' for ', theYD, format="(A,I10,' to',I10,A,F14.5)"
ENDIF ELSE BEGIN
  print, 'SD-card SCID range is ', jpmprintnumber(scid_range[0], /NO_DECIMALS), ' to ', JPMPrintNumber(scid_range[1], /NO_DECIMALS), ' for ', time_iso
ENDELSE
print, ' '

;
;	4. Task 4: Write Hydra Script for downlink  (TBD)
;

if keyword_set(VERBOSE) then begin
	stop, 'DEBUG daxss_downlink_script ...'
endif

return
end
