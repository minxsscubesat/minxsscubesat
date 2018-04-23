;
;	goes_xrs_temp_em.pro
;
;	Extend the GOES data structure to include JD, temperature, and Emission Measure (EM)
;		Temperature is based on XRS-A / XRS-B ratio  (Garcia technique with Mewe spectra)
;		Emission Measure is based on X123 modeling result: EM = EM_constant * Temp^N
;
;	INPUT:
;		year		1974 to present year, can be an array of years or range of years
;		/save		Option to save the result back into an IDL save set
;		/directory  Option to specify the GOES data directory
;
;	OUTPUT:
;		goes		revised GOES data structure
;
;	ENVIRONMENT VARIABLE:
;		$see_analysis	GOES data files are expected to be in $see_analysis/goes/ directory
;
;	PROCEDURE:
;		1.  Load GOES data and XRS temperature function
;		2.	Calculate Temperature based on XRS-A / XRS-B ratio
;		3.	Calculate Emission Measure based on X123 result (function of Temperature)
;
;	HISTORY:
;		10/4/2017	T. Woods, Original code
;
pro goes_xrs_temp_em, year, goes, save=save, directory=directory

if n_params() lt 1 then begin
	print, 'USAGE: goes_xrs_temp_em, year, [ goes_data, /save, directory=directory ]'
	return
endif

;  slash for Mac = '/', PC = '\'
if !version.os_family eq 'Windows' then begin
    slash = '\'
endif else begin
    slash = '/'
endelse

if keyword_set(directory) then begin
	goes_dir = directory
endif else begin
	goes_dir = getenv('see_analysis')
	if (strlen(goes_dir) gt 1) then begin
		goes_dir += slash+'goes'+slash
	endif else begin
		; print warning - it will likely fail
		print, 'WARNING: GOES data directory is not defined, looking in current directory !'
	endelse
endelse

;
;	1.  Load GOES data and XRS temperature function
;	load GOES XRS data from $see_analysis/goes/ IDL save set (file per year)
;
  num_years = n_elements(year)
  if (num_years eq 1) then begin
    ; process single year
  	years = [ year ]
  endif else if (num_years eq 2) then begin
  	; process range of years
  	num_years = long(year[1] - year[0] + 1)
  	years = indgen(num_years)+long(year[0])
  endif else if (num_years gt 2) then begin
  	; process list of years
  	years = year
  endif else begin
  	;  error
  	print, 'ERROR: goes_xrs_temp_em needs at least one year between 1974 and present time !'
  	return
  endelse
  goes_num = num_years * 366L * (24L*60L)   ; one-minute cadence
  goes_len = 0L
  goes1 = { time: 0UL, short: 0.0, long: 0.0, sat: 0, flare_idx_short: 0.0, flare_idx_long: 0.0, $
  				jd: 0.0D0, logTemp: 0.0, logEM: 0.0 }
  goes_data = replicate( goes1, goes_num )
  for k=0L,num_years-1 do begin
    xrs_file = 'goes_1mdata_widx_'+strtrim(years[k],2)+'.sav'
    restore, goes_dir + xrs_file   ; goes data structure
    num_new = n_elements(goes)
	goes_data[goes_len:goes_len+num_new-1].time = goes.time
	goes_data[goes_len:goes_len+num_new-1].short = goes.short
	goes_data[goes_len:goes_len+num_new-1].long = goes.long
	goes_data[goes_len:goes_len+num_new-1].sat = goes.sat
	goes_data[goes_len:goes_len+num_new-1].flare_idx_short = goes.flare_idx_short
	goes_data[goes_len:goes_len+num_new-1].flare_idx_long = goes.flare_idx_long
    goes_len += num_new
    goes=0L
  endfor
  goes = goes_data[0:goes_len-1]  ; truncate to what is actually used
  goes_data=0L

  ;  calculate Julian Date (JD)
  goes.jd = gps2jd(goes.time)

  ; apply "calibration" to GOES XRS (just done once)
  acal = 1. / 0.85	; XRS-A / 0.85 for "true" irradiance level
  xrsa = goes.short * acal
  bcal = 1. / 0.70   ; XRS-B / 0.70  for "true" irradiance level
  xrsb = goes.long * bcal

  ;
  ;	load temperature model for GOES ratio of XRS-A / XRS-B
  ;
  dtfile = 'xrs_temp_current.dat'
  xrsratio = read_dat(goes_dir + dtfile)
  xrsratio[0,*] = alog10(xrsratio[0,*] * 1E6)		; convert T_MK to alog10(T_K)
  ;  place A/B ratio into Current_C column
  xrsratio[3,*] = 0.0
  wgd1 = where((xrsratio[2,*] gt 0) and (xrsratio[1,*] gt 0))
  xrsratio[3,wgd1] = xrsratio[1,wgd1] / xrsratio[2,wgd1]
  xrs_temp_valid = [5.3, 7.9]
  wgd = where( (xrsratio[0,*] ge xrs_temp_valid[0]) and (xrsratio[0,*] le xrs_temp_valid[1]) $
  		and (xrsratio[2,*] gt 0) and (xrsratio[1,*] gt 0) )
  ;  truncate to valid ratio range
  xrsratio_temp = xrsratio[*,wgd]

;
;	2.	Calculate Temperature based on XRS-A / XRS-B ratio  (Garcia method)
;
  ratio_xrs = xrsa / (xrsb > 1E-10)
  goes.logTemp = interpol( reform(xrsratio_temp[0,*]), reform(xrsratio_temp[3,*]), ratio_xrs )
  wlow = where( ratio_xrs lt min(xrsratio_temp[3,*], ilow), numlow )
  if (numlow gt 0) then goes[wlow].logTemp = xrsratio_temp[0,ilow]
  whigh = where( ratio_xrs gt max(xrsratio_temp[3,*], ihigh), numhigh )
  if (numhigh gt 0) then goes[whigh].logTemp = xrsratio_temp[0,ihigh]

;
;	3.	Calculate Emission Measure based on X123 result (function of Temperature)
;		Derived from fitting CHIANTI isothermal models to MinXSS X123 data
;		EM = EM_constant * Temp^N
;       Bennet Scwhab 10/24/2017  long(EM) = Yint + YintSlope * log(Temp) + WeightedMean_C1 * log(XRS_B_Flux)
;	         Yint = 66.5112
;     	     YintSlope = -4.81847
;    	     WeightedMean_C1 = 1.34503
  EM_constant = 66.5112		; Bennet Scwhab X123 result 10/4/2017
  T_power = -4.81847 		; Bennet Scwhab X123 result 10/4/2017
  B_power = 1.34503			; Bennet Scwhab X123 result 10/4/2017
  goes.logEM = EM_constant + T_power * goes.logTemp + B_power * alog10(goes.long)

if keyword_set(save) then begin
  new_file = 'goes_1mdata_extend_'+strtrim(years[0],2)
  if (num_years gt 1) then new_file += '-' + strtrim(years[num_years-1],2)
  new_file += '.sav'
  print, 'Saving GOES data extended with Temp and EM to ', new_file
  save, goes, file=goes_dir + new_file
endif

return
end
