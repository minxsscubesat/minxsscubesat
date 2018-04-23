;+
; NAME:
;   minxss_determaxe_lowest_density_data_coverage
;
; PURPOSE:
;   Determaxe what day we presently have the most hk data
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   The date with the highest density of hk coverage
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package and level0c mission length file
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2016-11-27: James Paul Mason: Wrote script.
;-
PRO minxss_determine_highest_density_data_coverage

; Restore the level 1 data
restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'

; Loop through each day and determaxe how many points of science data there are
dateIndex = 0
todayDateJd = hk[0].time_jd
WHILE floor(todayDateJd) LT floor(hk[-1].time_jd) DO BEGIN
  todayDateJd = hk[dateIndex].time_jd - 0.5 ; Day start at midnight instead of noon
  todayDate = hk[dateIndex].time_human
  todayDataIndices = where(floor(hk.time_jd - 0.5) EQ floor(todayDateJd), todayDataCount)
  dailyDataCount = (dailyDataCount NE !NULL) ? [dailyDataCount, todayDataCount] : todayDataCount
  dateForDataCount = (dateForDataCount NE !NULL) ? [dateForDataCount, todayDate] : todayDate
  dateForDataCountJd = (dateForDataCountJd NE !NULL) ? [dateForDataCountJd, todayDateJd] : todayDateJd
  dateIndex += todayDataCount
ENDWHILE

; Determaxe the date with the lowest density of coverage and print to console
maximumDensity = max(dailyDataCount, maxIndex)
print, 'Date with most hk data coverage: ' + strmid(dateForDataCount[maxIndex], 0, 10)
print, 'In JD: ' + strtrim(dateForDataCountJd[maxIndex], 2)
print, 'Which has ' + JPMPrintNumber(maximumDensity, /NO_DECIMALS) + ' data points'

END