;+
; NAME:
;   minxss_determine_lowest_density_data_coverage
;
; PURPOSE:
;   Determine what day we presently have the least science data
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   excludeDates [long or string array]: If there are dates you don't want returned, specify them here. 
;                                        Format can be either long as yyyydoy or string as 'yyy-mm-dd'
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   yyyyDoy [long]: Function returns the date (yyyydoy) with the lowest density of science coverage, 
;                   as well as prints it to console with other related information. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS code package and level1 and level0c mission length files
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2016-11-26: James Paul Mason: Wrote script.
;-
FUNCTION minxss_determine_lowest_density_data_coverage, excludeDates = excludeDates

; Convert excludeDates (if any) to JD
IF excludeDates NE !NULL THEN BEGIN
  IF isA(excludeDates, 'long') THEN excludeDatesJd = JPMyyyyDoy2JD(excludeDates) -0.5 ELSE $
  IF isA(excludeDates, 'string') THEN excludeDatesJd = JPMiso2jd(excludeDates) - 0.5 $
  ELSE excludeDatesJd = !NULL
ENDIF

; Restore the level 1 data
restore, getenv('minxss_data') + '/fm1/level1/minxss1_l1_mission_length.sav'

; Loop through each day and determine how many points of science data there are
dateIndex = 0
todayDateJd = minxsslevel1[0].time.jd
WHILE floor(todayDateJd) LT floor(minxsslevel1[-1].time.jd) AND dateIndex LT n_elements(minxsslevel1) DO BEGIN
  
  ; Grab today's date in JD and human format, but starting at midnight rather than noon
  todayDateJd = minxsslevel1[dateIndex].time.jd - 0.5
  todayDate = minxsslevel1[dateIndex].time.human
  
  ; Skip this day if it's contained in excludeDates
  IF excludeDatesJd NE !NULL THEN BEGIN
    IF excludeDatesJd.HasValue(floor(todayDateJd)) THEN BEGIN
      dateIndex++
      CONTINUE
    ENDIF
  ENDIF
  
  ; Find how many spectra there are for today and add that number to a running array
  todaySpectraIndices = where(floor(minxsslevel1.time.jd - 0.5) EQ floor(todayDateJd), todaySpectraCount)
  dailySpectraCount = (dailySpectraCount NE !NULL) ? [dailySpectraCount, todaySpectraCount] : todaySpectraCount
  dateForSpectraCount = (dateForSpectraCount NE !NULL) ? [dateForSpectraCount, todayDate] : todayDate
  dateForSpectraCountJd = (dateForSpectraCountJd NE !NULL) ? [dateForSpectraCountJd, todayDateJd] : todayDateJd
  dateIndex += todaySpectraCount
ENDWHILE

; Determine the date with the lowest density of coverage and print to console
minimumDensity = min(dailySpectraCount, minIndex)
print, 'Date with least science coverage: ' + strmid(dateForSpectraCount[minIndex], 0, 10)
print, 'Which has only ' + JPMPrintNumber(minimumDensity, /NO_DECIMALS) + ' spectra'

; Restore level 0c data to get the corresponding SD card offsets
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Find the sd card offsets for that date 
dateOfInterestIndices = where(floor(hk.time_jd - 0.5) EQ floor(dateForSpectraCountJd[minIndex]))
dateTimesOfInterest = hk[dateOfInterestIndices].time_human
dateOfInterestSciSdOffset = hk[dateOfInterestIndices].SD_SCI_WRITE_OFFSET
print, 'Science SD offset range for that date: ' + strtrim(min(dateOfInterestSciSdOffset), 2) + ' - ' + strtrim(max(dateOfInterestSciSdOffset), 2)
print, 'Corresponding to times ' + dateTimesOfInterest[0] + ' - ' + dateTimesOfInterest[-1]

; See if X123 was even enabled during that time
enable_x123 = hk[dateOfInterestIndices].ENABLE_X123
print, 'X123 was powered on ' + JPMPrintNumber(total(enable_x123) / n_elements(enable_x123) * 100.) + '% of this time'

return, JPMjd2yyyydoy(JPMyyyymmddhhmmss2jd(dateForSpectraCount[minIndex]))

END