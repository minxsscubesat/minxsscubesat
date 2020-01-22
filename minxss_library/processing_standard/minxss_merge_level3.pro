;+
; NAME:
;   minxss_merge_level3.pro
;
; PURPOSE:
;   Read MinXSS Level 1 irradiance data product and make a merged daily average Level 3 irradiance product
;
; CATEGORY:
;    MinXSS Level 3
;
; CALLING SEQUENCE:
;   minxss_merge_level3, fm
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;	  fm [integer]: Flight Model number 1 or 2 (default is 1)
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages
;
; OUTPUTS:
;   None
;   
; OPTIONAL OUTPUTS:
;   result: Provides the daily averaged result
;
;
; RESTRICTIONS:
;	  Requires GOES XRS merged files per year (copy that over before running this procedure)
;
; PROCEDURE:
;   1. Read the MinXSS Level 1 merged file
;	  2. Make MinXSS Level 3 data structure
;	  3. Read the GOES XRS merged files
;   4. Select the Median X123 Slow Counts and select 2-sigma from this for averaging over day
;   5. Save the L1 averaged data into the L3 structure
;	  6. Save the daily averaged Level 3 product
;+
PRO minxss_merge_level3, fm = fm, result=result, verbose=verbose, debug=debug

; Default return value
result = -1L

;
;	check for valid input parameters
;
IF fm EQ !NULL THEN fm = 1
if (fm gt 2) or (fm lt 1) then begin
  print, "ERROR: minxss_merge_level3 needs a valid 'fm' value.  FM can be 1 or 2."
  return
endif
fm_str = strtrim(fm,2)

if keyword_set(debug) then verbose=1

;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
    file_copy = 'copy '
    file_delete = 'del /F '
endif else begin
    slash = '/'
    file_copy = 'cp '
    file_delete = 'rm -f '
endelse

;
;   1. Read the MinXSS Level 1 merged file
;
dir_fm = getenv('minxss_data')+slash+'fm'+fm_str+slash
dir_merged = getenv('minxss_data') + path_sep() + 'ancillary' + path_sep() + 'goes' + path_sep()
file1 = 'minxss'+fm_str+'_l1_mission_length.sav'
if keyword_set(verbose) then print, 'Reading ',file1,' ...'
restore, dir_fm + 'level1' + slash + file1   ; restores minxsslevel1 and minxsslevel1_meta

;
;	2. Make MinXSS Level 3 data structure
;
year1 = long(min(minxsslevel1.x123.time.yyyydoy)/1000.)
year2 = long(max(minxsslevel1.x123.time.yyyydoy)/1000.)
jd1 = long(min(minxsslevel1.x123.time.jd))-0.5
jd2 = long(max(minxsslevel1.x123.time.jd))-0.5
;  this will skip processing last day because GOES XRS data might not be available yet
num_days = long(jd2 - jd1)

; make minxsslevel3 data structure
time3 = { $
   ISO             :    ' ', $
   HUMAN           :    ' ', $
   YYYYMMDD        : 0L, $
   YYYYDOY         : 0L, $
   JD              : 0.0D0, $
   TAI             : 0.0D0 $
		}
level3 = { $
   TIME            : time3, $
   FLIGHT_MODEL    :  fm, $
   IRRADIANCE      :  fltarr(1024), $
   ENERGY          :  fltarr(1024), $
   ACCURACY        :  fltarr(1024), $
   PRECISION       :  fltarr(1024), $
   STDDEV          :  fltarr(1024), $
   INTEGRATION_TIME : 0.0, $
   NUMBER_SPECTRA  : 0L, $
   X123_FAST_COUNT : 0.0, $
   X123_SLOW_COUNT : 0.0, $
   X123_XRSB	   : 0.0, $
   X123_XRSA	   : 0.0, $
   GOES_XRSB	   : 0.0, $
   GOES_XRSA	   : 0.0, $
   SPS_ON          : 0, $
   SPS_SUM         : 0.0, $
   SPS_X           : 0.0, $
   SPS_Y           : 0.0, $
   EARTH_SUN_DISTANCE : 0.0 $
	}
minxsslevel3 = replicate(level3, num_days)

; make minxsslevel3_meta structure
minxsslevel3_meta = { $
   TITLE           :    'MinXSS Level 3 Data Product, daily averaged irradiances corrected to 1-AU', $
   SOURCE          :    'MinXSS SOC at LASP / CU', $
   MISSION         :    'MinXSS-'+fm_str, $
   DATA_PRODUCT_TYPE :    'MinXSS Level 3', $
   DATA_PRODUCT_VERSION :    '1.0', $
   DATA_PRODUCT_REVISION :    '1.0.1', $
   PRODUCT_FORMAT_VERSION :    'IDL Save Set', $
   SOFTWARE_VERSION :    '1.0.1', $
   SOFTWARE_NAME   :    'IDL save.pro called from minxss_merge_level3.pro', $
   CALIBRATION_VERSION :    minxsslevel1_meta.CALIBRATION_VERSION, $
   DESCRIPTION     :    'Calibrated MinXSS X123 science data averaged over a day and corrected to 1-AU', $
   HISTORY         :    '2017/02/03: Tom Woods: Original Level 3 code', $
   FILENAME        :    'minxss1_l3_mission_length.sav', $
   DATE_GENERATED  :    systime(), $
   TIME            :    'Time structure for different date/time formats', $
   TIME_STRUCT_ISO :    'Time in ISO text format', $
   TIME_STRUCT_HUMAN   :    'Time in Human-readable text format', $
   TIME_STRUCT_YYYYMMDD   :    'Time in Year-Month-Day long integer format', $
   TIME_STRUCT_YYYYDOY   :    'Time in Year Day-Of-Year (DOY) long integer format', $
   TIME_STRUCT_JD  :    'Time in Julian Date double format', $
   TIME_STRUCT_TAI :    'Time in International Atomic Time (TAI) format', $
   FLIGHT_MODEL    :    'MinXSS Flight Model integer (1 or 2)', $
   IRRADIANCE      :    'X123 Irradiance in units of photons/sec/cm^2/keV, float array[1024]', $
   ENERGY          :    'X123 Energy bins in units of keV, float array[1024]', $
   ACCURACY        :    'X123 Irradiance Relative Accuracy (in percent), float array[1024]', $
   PRECISION       :    'X123 Measurement Precision (in percent), float array[1024]', $
   STDDEV          :    'X123 Standard Deviation of daily average (irradiance units), float array[1024]', $
   INTEGRATION_TIME :    'X123 Integration Time accumulated for daily average', $
   NUMBER_SPECTRA  :    'X123 Number of Spectra in daily average', $
   X123_FAST_COUNT :    'X123 Fast Counter value, larger than Slow Count could mean missed photons', $
   X123_SLOW_COUNT :    'X123 Slow Counter value: integration of signal over 1024 bins', $
   X123_XRSB	   : 	'X123 integrated irradiance for XRS-B band of 1-8 Angstrom', $
   X123_XRSA	   : 	'X123 integrated irradiance for XRS-A band of 0.5-4 Angstrom', $
   GOES_XRSB	   : 	'GOES XRS-B (1-8 Angstrom) Irradiance (W/m^2) - median for day', $
   GOES_XRSA	   : 	'GOES XRS-A (0.5-4 Angstrom) Irradiance (W/m^2) - median for day', $
   SPS_ON          :    'SPS power flag (1=ON, 0=OFF)', $
   SPS_SUM         :    'SPS signal in units of fC, normally about 2E6 fC when in sunlight', $
   SPS_X           :    'SPS X-axis offset from the sun center (NaN if SPS is not in the sun)', $
   SPS_Y           :    'SPS Y-axis offset from the sun center (NaN if SPS is not in the sun)', $
   EARTH_SUN_DISTANCE :    'Earth-Sun Distance in units of AU (irradiance is corrected to 1AU)' $
	}

;
;	3. Read the GOES XRS merged files
;
xrs_dir = dir_merged
for k=year1,year2 do begin
  xrs_file = 'goes_1mdata_widx_'+strtrim(k,2)+'.sav'
  restore, xrs_dir + xrs_file   ; goes data structure
  if (k eq year1) then begin
    goes_jd = gps2jd(goes.time)  ; convert GPS to Julian Day (JD)
    goes_xrsb = goes.long
    goes_xrsa = goes.short
  endif else begin
    goes_jd = [ goes_jd, gps2jd(goes.time) ]
    goes_xrsb = [goes_xrsb, goes.long ]
    goes_xrsa = [goes_xrsa, goes.short ]
  endelse
  goes=0L
endfor

if (max(goes_jd) lt (long(max(minxsslevel1.time.jd))-0.5)) then begin
   stop, "STOP: GOES XRS file is not latest version! You can .continue or retall to exit"
endif

if keyword_set(debug) then stop, 'DEBUG: check minxsslevel1, minxsslevel3, goes variables ...'

;
;	get counts for each spectrum that is good
;
counts = total(minxsslevel1.signal_cps,1)
wgood = where( minxsslevel1.SPACECRAFT_IN_SAA eq 0, num_good )
if (num_good lt 2) then begin
	stop, 'STOP: there are not enough data outside SAA for processing!'
endif
minxsslevel1 = minxsslevel1[wgood]
counts = counts[wgood]
MIN_COUNTS = 5
index = -1L
; constants for converting X123 photon flux to energy flux for XRS band integrations
hc = 6.626D-34 * 2.998D8
EFang = 12.398
aband = EFang / [ 0.5, 4 ]	; convert Angstrom to keV for XRS bands
bband = EFang / [ 1., 8 ]	; convert Angstrom to keV for XRS bands

if keyword_set(verbose) then print, 'Processing ', strtrim(num_days,2), ' days ...'

for jd=jd1,jd2-1.,1.0 do begin
  index += 1L
  ;
  ;   4. Select the Median X123 Slow Counts and select 2-sigma from this for averaging over day
  ;		exclude SPACECRAFT_IN_SAA != 0 and VALID_FLAG[0:1023] = TRUE
  ;
  wgood = where( (minxsslevel1.time.jd ge jd) and (minxsslevel1.time.jd lt (jd+1.0)), num_good )
  if (num_good ge MIN_COUNTS) then begin
  	mcounts = median(counts[wgood])
  	scounts = stddev(counts[wgood])
  	wclean = where( (counts[wgood] ge (mcounts-scounts*2)) and (counts[wgood] le (mcounts+scounts*2)), num_clean)
  	if (num_clean ge MIN_COUNTS) then begin
  		wgood = wgood[wclean]
  		num_good = num_clean
  	endif else begin
  		wgood = -1
  		num_good = 0
  	endelse
  endif

  ;
  ;   5. Save the L1 averaged data into the L3 structure
  ;
  minxsslevel3[index].time.jd = jd
  if (num_good ge MIN_COUNTS) then begin
    icenter = wgood[long(num_good/2)]
    flt_good = float(num_good)
  	minxsslevel3[index].time.iso = minxsslevel1[icenter].time.iso
  	minxsslevel3[index].time.human = minxsslevel1[icenter].time.human
  	minxsslevel3[index].time.YYYYMMDD = minxsslevel1[icenter].time.YYYYMMDD
  	minxsslevel3[index].time.YYYYDOY = minxsslevel1[icenter].time.YYYYDOY
  	minxsslevel3[index].time.tai = minxsslevel1[icenter].time.tai
	minxsslevel3[index].ENERGY = minxsslevel1[icenter].ENERGY
  	minxsslevel3[index].EARTH_SUN_DISTANCE = minxsslevel1[icenter].EARTH_SUN_DISTANCE

	minxsslevel3[index].IRRADIANCE = total(minxsslevel1[wgood].IRRADIANCE,2)/flt_good
	minxsslevel3[index].ACCURACY = total(minxsslevel1[wgood].ACCURACY,2)/flt_good
	minxsslevel3[index].PRECISION = total(minxsslevel1[wgood].PRECISION,2)/flt_good/sqrt(flt_good)
	minxsslevel3[index].STDDEV = stddev(minxsslevel1[wgood].IRRADIANCE,dim=2)
	minxsslevel3[index].INTEGRATION_TIME = total(minxsslevel1[wgood].INTEGRATION_TIME)
	minxsslevel3[index].NUMBER_SPECTRA  = total(minxsslevel1[wgood].NUMBER_SPECTRA)
	minxsslevel3[index].X123_FAST_COUNT = total(minxsslevel1[wgood].X123_FAST_COUNT)/flt_good
	minxsslevel3[index].X123_SLOW_COUNT = total(minxsslevel1[wgood].X123_SLOW_COUNT)/flt_good
	wsps = where( minxsslevel1.SPS_ON gt 0, num_sps )
	if (num_sps ge 1) then begin
		flt_sps = float(num_sps)
   		minxsslevel3[index].SPS_ON = 1
   		minxsslevel3[index].SPS_SUM = total(minxsslevel1[wgood[wsps]].SPS_SUM)/flt_sps
   		minxsslevel3[index].SPS_X  = total(minxsslevel1[wgood[wsps]].SPS_X)/flt_sps
   		minxsslevel3[index].SPS_Y  = total(minxsslevel1[wgood[wsps]].SPS_Y)/flt_sps
	endif else begin
   		minxsslevel3[index].SPS_ON = 0
   		minxsslevel3[index].SPS_SUM = 0
   		minxsslevel3[index].SPS_X  = !VALUES.F_NAN
   		minxsslevel3[index].SPS_Y  = !VALUES.F_NAN
	endelse
	;  integrate X123 spectrum for XRS A & B bands
	x123_band = minxsslevel3[index].ENERGY[20] - minxsslevel3[index].ENERGY[19]  ; ~ 0.03 keV/bin
	wgxa = where( (minxsslevel3[index].ENERGY ge aband[1]) and (minxsslevel3[index].ENERGY lt aband[0]) )
	aphoton2energy = (hc*minxsslevel3[index].ENERGY[wgxa]) * 1.D4 / (1.D-10*EFang)
	minxsslevel3[index].X123_XRSA = total(minxsslevel3[index].IRRADIANCE[wgxa]*x123_band*aphoton2energy)
	wgxb = where( (minxsslevel3[index].ENERGY ge bband[1]) and (minxsslevel3[index].ENERGY lt bband[0]) )
	bphoton2energy = (hc*minxsslevel3[index].ENERGY[wgxb]) * 1.D4 / (1.D-10*EFang)
	minxsslevel3[index].X123_XRSB = total(minxsslevel3[index].IRRADIANCE[wgxb]*x123_band*bphoton2energy)
	;  get median of GOES XRS flux for the day
	wgoes = where( (goes_jd ge jd) and (goes_jd lt (jd+1.0)), num_goes )
	if (num_goes gt 1) then begin
	 	minxsslevel3[index].GOES_XRSB = median(goes_xrsb[wgoes])
		minxsslevel3[index].GOES_XRSA = median(goes_xrsa[wgoes])
	endif
  endif else begin
	; values will be zero if a daily average is not possible
	minxsslevel3[index].time.YYYYDOY = -1L
  endelse
endfor

;  only keep the days that have valid daily average
wkeep = where( minxsslevel3.time.YYYYDOY gt 2016000L, num_keep )
if (num_keep gt 1) then minxsslevel3 = minxsslevel3[wkeep]

;
;	6. Save the daily averaged Level 3 product
;
file3 = 'minxss'+fm_str+'_l3_mission_length.sav'
if keyword_set(verbose) then print, 'Saving ',file3,' ...'
full_file3 = dir_fm + 'level3' + slash + file3
save, minxsslevel3, minxsslevel3_meta, file=full_file3   ; restores minxsslevel1 and minxsslevel1_meta

result = minxsslevel3

if keyword_set(debug) then stop, "DEBUG at end of minxss_merge_level3.pro ..."

RETURN
END
