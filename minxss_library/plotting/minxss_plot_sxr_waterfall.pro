;+
; NAME:
;   minxss_plot_sxr_waterfall
;
; PURPOSE:
;   Create a plot of energy/wavelength vs time with intensity indicated by color for the soft x-rays (SXRs) observed by MinXSS/X123
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   energyRange [float, float]:                Restrict the energy range in the plot to just these lower and upper bounds. Default is no restriction. 
;   binRange [integer, integer]:               Same idea as energyRange but in terms of the 1024 available bins instead. Results in error if energyRange is also specified. 
;                                              Default is no restriction. 
;   timeRange [string, string]:                Time range to plot in ISO format: yyyy-mm-ddThh:mm:ssZ, e.g., ['2016-05-16T00:00:00Z', '2016-11-07T18:46:05Z']. 
;                                              Default is entire available data set in minxss_l1_mission_length.sav. 
;   rgb_table [integer or string, or bytearr]: Straight passthrough to the IDL colorbar function's rgb_table optional input. Default is 'rainbow'. 
;   colorScale []:                             TODO: How to input this so I can do e.g., log(intensity) or sqrt(intensity) etc. 
;   savePlotPathAndFilename [string]:          If specified, the waterfall plot will be saved with the path/filename specified in this variable. 
;   
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   waterfall plot displayed
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code package and level 1 data
;
; EXAMPLE:
;   Just run it to use the defaults! 
;
; MODIFICATION HISTORY:
;   2016-11-07: James Paul Mason: Wrote script.
;-
PRO minxss_plot_sxr_waterfall, fm=fm, energyRange = energyRange, binRange = binRange, timeRange = timeRange, rgb_table = rgb_table, colorScale = colorScale, $
                               savePlotPathAndFilename = savePlotPathAndFilename

IF fm EQ !NULL THEN fm = 1

; Check for input specification errors
IF energyRange NE !NULL AND binRange NE !NULL THEN BEGIN
  message, /INFO, JPMsystime() + ' Cannot specify both energyRange and binRange -- they are entirely redundant. Pick one or the other to specify.'
  return
ENDIF

; Convert timeRange if input
IF timeRange NE !NULL THEN BEGIN
  timeRangeTemp = timeRange ; For some reason JPMiso2jd NULLs out the input
  timeRangeJd = JPMiso2jd(timeRangeTemp)
ENDIF

; Restore Level 1 data
restore, getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level1/minxss' + strtrim(fm, 2) + '_l1_mission_length.sav'

; Defaults
IF energyRange EQ !NULL AND binRange NE !NULL THEN energyRange = [minxsslevel1[0].energy[binRange[0]], minxsslevel1[0].energy[binRange[1]]]
IF energyRange EQ !NULL THEN energyRange = [0., minxsslevel1[0].energy[-1]]
IF timeRange EQ !NULL THEN timeRangeJd = [minxsslevel1[0].time.jd, minxsslevel1[-1].time.jd]
IF rgb_table EQ !NULL THEN rgb_table = 3
IF colorScale EQ !NULL THEN colorScale = 'none'

;;
; Restrict data as indicated by input
;;

; Restrict time range
timeIndices = where(minxsslevel1.time.jd GT timeRangeJd[0] AND minxsslevel1.time.jd LT timeRangeJd[1])
IF timeIndices EQ [-1] THEN BEGIN
  message, /INFO, JPMsystime() + ' Did not find any data within time range.'
  return
ENDIF
minxsslevel1 = minxsslevel1[timeIndices]

; Restrict energy range
energyIndices = where(minxsslevel1[0].energy GT energyRange[0] AND minxsslevel1[0].energy LT energyRange[1])
energies = minxsslevel1[0].energy[energyIndices]

; Convert to wavelength
wavelengthsAngstrom = kev2angstrom(energies)

;; 
; Scale irradiance
;; 

; Grab the irradiance confined to the specified energy range
irradiance = minxsslevel1.irradiance[energyIndices]

;;
; Background subtraction
;; 

; Make sure the background to be subtracted isn't 0 
nonzeroIndices = where(irradiance[10, *] GT 0)
backgroundIndex = nonzeroIndices[0]

irradianceRelative = irradiance
FOR i = 0, n_elements(energies) - 1 DO BEGIN
  irradianceRelative[i, *] = (irradiance[i, *] - irradiance[i, backgroundIndex]) / irradiance[i, backgroundIndex] * 100. ; [%]
ENDFOR

; Apply the scaling of choice
IF colorScale EQ 'none' OR colorScale EQ '' THEN irradianceScaled = irradiance
IF colorScale EQ 'log' THEN irradianceScaled = alog(irradiance)
IF colorScale EQ 'sqrt' THEN irradianceScaled = sqrt(irradiance)

;; 
; Create plot
;; 

; Make intelligent time axis
timeRangeDifferenceDays = timeRangeJd[1] - timeRangeJd[0]
IF timeRangeDifferenceDays GT 60 THEN BEGIN
  labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
  xtickunits = ['Month', 'Year']
  xtickformat = ['LABEL_DATE', 'LABEL_DATE']
  xtitle = ''
ENDIF
IF timeRangeDifferenceDays GT 1 AND timeRangeDifferenceDays LT 60 THEN BEGIN
  labelDate = label_date(DATE_FORMAT = ['%D', '%M', '%Y'])
  xtickunits = ['Day', 'Month', 'Year']
  xtickformat = ['LABEL_DATE', 'LABEL_DATE', 'LABEL_DATE']
  xtitle = ''
ENDIF
IF timeRangeDifferenceDays * 24. GT 1 AND timeRangeDifferenceDays * 24. LT 24 THEN BEGIN
  labelDate = label_date(DATE_FORMAT = ['%I', '%H'])
  xtickunits = ['Minute', 'Hour']
  xtickformat = ['LABEL_DATE', 'LABEL_DATE']
  xtitle = strmid(timeRange[0], 0, 10)
ENDIF
IF timeRangeDifferenceDays * 24. LT 1 THEN BEGIN
  labelDate = label_date(DATE_FORMAT = ['%s', '%I'])
  xtickunits = ['Second', 'Minute']
  xtickformat = ['LABEL_DATE', 'LABEL_DATE']
  xtitle = strmid(timeRange[0], 0, 13)
ENDIF

w1 = window(DIMENSIONS = [600, 600])
p1 = plot(minxsslevel1.time.jd, JPMrange(energies[0], energies[0], npts = n_elements(minxsslevel1)), /CURRENT, $
          RGB_TABLE = 3, VERT_COLORS = irradianceRelative[0, *], $
          TITLE = 'MinXSS-1 Soft X-ray Waterfall', $
          XTITLE = xtitle, XTICKFORMAT = xtickformat, XTICKUNITS = xtickunits, XMAJOR = 8, $
          YTITLE = 'Energy [keV]')
FOR energyIndex = 1, n_elements(energies) - 1 DO BEGIN
  p2 = plot(minxsslevel1.time.jd, JPMrange(energies[energyIndex], energies[energyIndex], npts = n_elements(minxsslevel1)), $
            RGB_TABLE = 3, VERT_COLORS = irradianceRelative[energyIndex, *], /OVERPLOT)
  IF c2 EQ !NULL AND finite(max(irradianceRelative[energyIndex, *])) THEN BEGIN 
  c2 = colorbar(MAJOR = 2, TICKNAME = ['50', '100'])
  STOP
  c2.POSITION = [0.13, 0.905, 0.92, 0.94]
  c2.TITLE = 'Relative Irradiance [%]'
  c2.TEXTPOS = 1
  ENDIF
ENDFOR

STOP
END