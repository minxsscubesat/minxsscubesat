;+
; NAME:
;   minxss_temperature_overplot.pro
;
; PURPOSE:
;   Create a single plot showing all temperature data for a time range. Optionally include thermal couple data from thermal balance. 
;
; CATEGORY:
;   Level 0B (at time of writing) or 0C
;
; CALLING SEQUENCE:
;   minxss_temperature_overplot, timeRange
;
; INPUTS:
;   timeRange [dblarr]: Date/time range for plot in format yyyydoy.fod (fraction of day) e.g. 2015083.43482d. 
;
; OPTIONAL INPUTS:
;   tcFilename [string]: The path/filename of thermal couple data to be included.
;   level [string]:      Specify 'B' or 'C' for Level 0B or Level 0C (default) data. 
;   plotTitle [string]:  Pass in a plot title if you wish. Useful for thermal balance special plots
;   
; KEYWORD PARAMETERS:
;   VERBOSE:         Set to print out more information as processing goes on
;   THERMAL_BALANCE: Set to use the thermal balance saveset instead of using timeRange[0] to load the saveset. 
;   MANUAL_PLOT:     Set this to stop the code before producing the massive plot and instead plot from the command line. 
;   
; OUTPUTS:
;   A single plot with all temperature data within specified timeRange
;
; OPTIONAL OUTPUTS:
;   None
;
; COMMON BLOCKS:
;   None
;
; RESTRICTIONS:
;   Requires JPMColors
;
; EXAMPLE: 
;   minxss_plots_temperature, [2015084.00d, 2015084.167d], tcFilename = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/TVAC and TBAL TC LabView Data/20150324 Cold Thermal Balance.csv', plotTitle = 'All Temperatures for Thermal Balance - Cold', /THERMAL_BALANCE
;   minxss_plots_temperature, [2015084.75d, 2015084.967d], tcFilename = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/TVAC and TBAL TC LabView Data/20150325 Hot Thermal Balance.csv', plotTitle = 'All Temperatures for Thermal Balance - Hot', /THERMAL_BALANCE
;   
; PROCEDURE:
;   1. Restore relevant data and crop to timeRange
;   2. Create plot
;
; MODIFICATION HISTORY:
;   2015/04/13: James Paul Mason: Wrote script. 
;   2015/06/09: James Paul Mason: Added THERMAL_BALANCE and MANUAL_PLOT keywords and fixed some bugs to do with time
;   2015/10/23: James Paul Mason: Refactored minxss_processing -> minxss_data and changed affected code to be consistent
;   2016/03/18: James Paul Mason: For thermal balance, now exports everything to a .sav and fixes a daylight savings time issue in minxss
;+
PRO minxss_plots_temperature, fm=fm, timeRange, tcFilename = tcFilename, level = level, plotTitle = plotTitle, $
                              VERBOSE = VERBOSE, THERMAL_BALANCE = THERMAL_BALANCE, MANUAL_PLOT = MANUAL_PLOT

; Input checks
IF n_params() lt 1 THEN BEGIN
  print, 'USAGE: minxss_temperature_overplot, timeRange, tcFilename = tcFilename, level = level, /VERBOSE'
  return
ENDIF
IF fm EQ !NULL THEN fm = 1

; Time setup
time1 = timeRange[0]
time2 = timeRange[1]
time_date = long(time1)
time_year = long(time_date / 1000.)
time_doy = time_date MOD 1000L
date_str = strtrim(time_year,2) + '_'
doy_str = strtrim(time_doy,2)
WHILE strlen(doy_str) LT 3 DO doy_str = '0' + doy_str
date_str += doy_str

; Level setup
; FIXME:  default choice is L0B for now but will want to change it to be L0C for flight
IF keyword_set(level) THEN BEGIN
  level_str = strlowcase(strmid(level,0,1))
ENDIF ELSE level_str = 'b'
IF level_str NE 'b' OR level_str NE 'c' THEN level_str = 'b'

;
; 1. Restore relevant data
;
data_dir = getenv('minxss_data') + '/fm' + strtrim(fm, 2) + '/level0' + level_str + '/'
IF keyword_set(THERMAL_BALANCE) THEN data_file = 'TBAL March 2015.sav' ELSE $
                                     data_file = 'minxss_l0' + level_str + '_' + date_str + '.sav'

; See if file exists before continuing
full_filename = file_search(data_dir + data_file, count=fcount)
IF (fcount GT 0) THEN BEGIN
  IF keyword_set(verbose) THEN print, 'Restoring data from ', data_file
  restore, data_dir + data_file
  hk = temporary(hk)
ENDIF ELSE BEGIN
  message, /INFO, 'Can not find file = ' + data_file
  return
ENDELSE

; Convert GPS to yd
packetTimeYyyyDoy = jd2yd(gps2jd(hk.time)) ;yyyydoy.fod

; Thermal balance data doesn't account for daylight savings time. It's an hour behind so must correct
IF keyword_set(THERMAL_BALANCE) THEN packetTimeYyyyDoy+= 1./24.

; Crop data down to timeRange, and convert to relative hours for plotting
wgood = where(packetTimeYyyyDoy GE time1 AND packetTimeYyyyDoy LE time2, numgood)
IF (numgood LT 2) THEN BEGIN
  message, /INFO, 'Need valid data in the time range of ' + strtrim(time1, 2) + ' - ' + strtrim(time2, 2)
  IF keyword_set(verbose) THEN STOP, 'DEBUG ...'
  return
ENDIF
yd_base = long(time_year * 1000L + time_doy)
hk = hk[wgood]
packetTimeYyyyDoy = packetTimeYyyyDoy[wgood]
hkFods = packetTimeYyyyDoy - long(packetTimeYyyyDoy)
relativeTimeHours = (hkFods - (time1 - long(time1))) * 24.

; Make a date string
time_date = long(packetTimeYyyyDoy[0])
time_year = long(time_date / 1000.)
time_doy = time_date MOD 1000L
date_str = strtrim(time_year, 2) + '_'
doy_str = strtrim(time_doy, 2)
WHILE strlen(doy_str) LT 3 DO doy_str = '0' + doy_str
date_str += doy_str

; Get thermal couple data
IF tcFilename NE !NULL THEN BEGIN
  readcol, tcFilename, tcDate, tcSSM, tcHour, $
           tcPlusZ, tcPlusYTop, tcPlusYMiddle, tcPlusYBottom, tcMinusZ, $
           tcPlusXTop, tcPlusXOnSA, tcPlusXUnderSA, tcPlusXBottom, $
           tcMinusYTop, tcMinusYMiddle, tcMinusYBottom, $
           tcMinusXTop, tcMinusXMiddle, tcMinusXBottom, $
           tcShroudInput, tcShroudOutput, tcShroudLeftFront, tcShroudLeftRear, tcShroudBack, tcShroudTopRear, tcShroudRightFront, $
           tcGetter, tcPlatenBackLeft, tcPlatenInput, $
           tcChiller1, tcGasHeater, tcPressure, /SILENT
           
  ; Deal with time: convert to UTC including handling of day roll over
  tcHour = tcHour + 6. ; Convert to UTC
  FOR i = 0, n_elements(tcHour) - 1 DO IF tcHour[i] GT 24. THEN tcHour[i] = tcHour[i] - 24.
  tcFod = tcHour/24.
  timeOnly1 = time1 - long(time1)
  timeOnly2 = time2 - long(time2)
  tcInTimeRangeIndices = where(tcFod GE timeOnly1 AND tcFod LE timeOnly2) ; Assumes the correct matching day for the MinXSS data

  IF tcInTimeRangeIndices NE [-1] THEN BEGIN
        
    ; Spacecraft 
    tcPlusZ = tcPlusZ[tcInTimeRangeIndices]
    tcPlusYTop = tcPlusYTop[tcInTimeRangeIndices]
    tcPlusYMiddle = tcPlusYMiddle[tcInTimeRangeIndices]
    tcPlusYBottom = tcPlusYBottom[tcInTimeRangeIndices]
    tcMinusZ = tcMinusZ[tcInTimeRangeIndices]
    tcPlusXTop = tcPlusXTop[tcInTimeRangeIndices]
    tcPlusXOnSA = tcPlusXOnSA[tcInTimeRangeIndices]
    tcPlusXUnderSA = tcPlusXUnderSA[tcInTimeRangeIndices]
    tcPlusXBottom = tcPlusXBottom[tcInTimeRangeIndices]
    tcMinusYTop = tcMinusYTop[tcInTimeRangeIndices]
    tcMinusYMiddle = tcMinusYMiddle[tcInTimeRangeIndices]
    tcMinusYBottom = tcMinusYBottom[tcInTimeRangeIndices]
    tcMinusXTop = tcMinusXTop[tcInTimeRangeIndices]
    tcMinusXMiddle = tcMinusXMiddle[tcInTimeRangeIndices]
    tcMinusXBottom = tcMinusXBottom[tcInTimeRangeIndices]
    
    ; Tank
    tcShroudInput = tcShroudInput[tcInTimeRangeIndices]
    tcShroudOutput = tcShroudOutput[tcInTimeRangeIndices]
    tcShroudLeftFront = tcShroudLeftFront[tcInTimeRangeIndices]
    tcShroudLeftRear = tcShroudLeftRear[tcInTimeRangeIndices]
    tcShroudBack = tcShroudBack[tcInTimeRangeIndices]
    tcShroudTopRear = tcShroudTopRear[tcInTimeRangeIndices]
    tcShroudRightFront = tcShroudRightFront[tcInTimeRangeIndices]
    tcGetter = tcGetter[tcInTimeRangeIndices]
    tcPlatenBackLeft = tcPlatenBackLeft[tcInTimeRangeIndices]
    tcPlatenInput = tcPlatenInput[tcInTimeRangeIndices]
    tcChiller1 = tcChiller1[tcInTimeRangeIndices]
    tcGasHeater = tcGasHeater[tcInTimeRangeIndices]
    tcPressure = tcPressure[tcInTimeRangeIndices]
    
    ; Time
    tcDate = tcDate[tcInTimeRangeIndices]
    tcSSM = tcSSM[tcInTimeRangeIndices]       ; SSM = seconds since midnight in local (mountain) time
    tcHour = tcHour[tcInTimeRangeIndices]
    tcFod = tcFod[tcInTimeRangeIndices]
    tcRelativeTimeHours = tcHour - (timeOnly1 * 24.)
  ENDIF ELSE message, /INFO, 'No thermal couple data found in time range'
ENDIF

; If thermal balance analysis, then just save everything to disk so this code doesn't need to be called again
IF keyword_set(THERMAL_BALANCE) THEN BEGIN
  parser = ParsePathAndFilename(tcFilename)
  IF strmatch(parser.fileName, '*Cold*') THEN save, FILENAME = parser.path + '../FM-1 Cold Thermal Balance Data.sav' ELSE $
    save, FILENAME = parser.path + '../FM-1 Hot Thermal Balance Data.sav'

STOP
;
; 2. Create plot
;
IF keyword_set(MANUAL_PLOT) THEN STOP
IF plotTitle EQ !NULL THEN plotTitle = 'All Temperatures for ' + date_str

p1 = plot(relativeTimeHours, hk.CDH_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), TITLE = plotTitle, MARGIN = [0.1, 0.1, 0.15, 0.1], DIMENSIONS = [1500, 1200], $
          XTITLE = 'Time Since Start [hours]', $
          YTITLE = 'Temperature [ºC]', $
          NAME = 'CDH')
p2 = plot(relativeTimeHours, hk.RADIO_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'Radio')
p3 = plot(relativeTimeHours, hk.COMM_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'COMM')
p4 = plot(relativeTimeHours, hk.MB_TEMP1, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'MB1')
p5 = plot(relativeTimeHours, hk.MB_TEMP2, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'MB2')
p6 = plot(relativeTimeHours, hk.EPS_TEMP1, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'EPS1')
p7 = plot(relativeTimeHours, hk.EPS_TEMP2, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = 'EPS2')          
p8 = plot(relativeTimeHours, hk.EPS_SA1_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = '+Y SA')
p9 = plot(relativeTimeHours, hk.EPS_SA2_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
          NAME = '+X SA')
p10 = plot(relativeTimeHours, hk.EPS_SA3_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = '-Y SA')
p11 = plot(relativeTimeHours, hk.EPS_BATT_TEMP1, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'Battery1')
p12 = plot(relativeTimeHours, hk.EPS_BATT_TEMP2, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'Battery2')
p13 = plot(relativeTimeHours, hk.SPS_XPS_PWR_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'SPS Power Board')
p14 = plot(relativeTimeHours, hk.SPS_XPS_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'SPS')
p15 = plot(relativeTimeHours, hk.XPS_XPS_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'XS')
p16 = plot(relativeTimeHours, hk.X123_BRD_TEMP, '2', COLOR = JPMColors(/SIMPLE, 0), /OVERPLOT, $
           NAME = 'X123 Board')
;p17 = plot(relativeTimeHours, hk.X123_DET_TEMP - 273.15, '2', COLOR = JPMColors(16), /OVERPLOT, $
;           NAME = 'X123 Detector')
;p18 = plot(relativeTimeHours, hk.XACT_TRACKERDETECTORTEMP, '2', COLOR = JPMColors(17), /OVERPLOT, $
;           NAME = 'Star Tracker')
;p19 = plot(relativeTimeHours, hk.XACT_WHEEL2TEMP, '2', COLOR = JPMColors(18), /OVERPLOT, $
;           NAME = 'Reaction Wheel 2')
legendTarget = [p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16]

IF tcInTimeRangeIndices NE !NULL AND tcInTimeRangeIndices NE [-1] THEN BEGIN  
  p20 = plot(tcRelativeTimeHours, tcPlusZ, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+Z Plate')
  p21 = plot(tcRelativeTimeHours, tcPlusYTop, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+Y Plate Top')
  p22 = plot(tcRelativeTimeHours, tcPlusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+Y Plate Middle')
  p23 = plot(tcRelativeTimeHours, tcPlusYBottom, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+Y Plate Bottom')
  p24 = plot(tcRelativeTimeHours, tcMinusZ, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-Z Plate')
  p25 = plot(tcRelativeTimeHours, tcPlusXTop, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+X Plate Top')
  p26 = plot(tcRelativeTimeHours, tcPlusXOnSA, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+X Plate On SA')
  p27 = plot(tcRelativeTimeHours, tcPlusXUnderSA, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+X Plate Under SA')
  p28 = plot(tcRelativeTimeHours, tcPlusXBottom, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '+X Plate Bottom')
  p29 = plot(tcRelativeTimeHours, tcMinusYTop, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-Y Plate Top')
  p30 = plot(tcRelativeTimeHours, tcMinusYMiddle, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-Y Plate Middle')
  p31 = plot(tcRelativeTimeHours, tcMinusYBottom, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-Y Plate Bottom')
  p32 = plot(tcRelativeTimeHours, tcMinusXTop, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-X Plate Top')
  p33 = plot(tcRelativeTimeHours, tcMinusXMiddle, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-X Plate Middle')
  p34 = plot(tcRelativeTimeHours, tcMinusXBottom, '2', COLOR = JPMColors(/SIMPLE, 1), /OVERPLOT, $
             NAME = '-X Plate Bottom')
  legendTarget = [legendTarget, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34]
ENDIF
           
l = legend(POSITION = [1.02, 0.9], TARGET = legendTarget, FONT_SIZE = 8)
                              
ENDIF

END