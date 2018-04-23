;+
; NAME:
;   minxss_plot_cadre_ground_station_conflict
;
; PURPOSE:
;
;
; INPUTS:
;
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;
;
; OPTIONAL OUTPUTS:
;
;
; RESTRICTIONS:
;
;
; EXAMPLE:
;
;
; MODIFICATION HISTORY:
;   2017/02/04: James Paul Mason: Wrote script.
;-
PRO minxss_plot_cadre_ground_station_conflict

; Setup
dataloc = getenv('minxss_data') + '/../pass_attributes/'

;accessData = read_ascii(dataloc + 'stk_boulder_to_satellites_access.txt', DATA_START = 10, HEADER = headerData, DELIMETER = ' ') 
readcol, dataloc + 'stk_boulder_to_satellites_access.txt', accessNumber, startDay, startMonth, startYear, startTime, endDay, endMonth, endYear, endTime, durationSeconds, $
                                                           format = 'i, i, a, i, a, i, a, i, a, f', SKIPLINE = 8, /SILENT

; Convert times to fraction of day
startTimeFod = JPMhhmmss2Fod(startTime)
startDayFod = startDay + startTimeFod
endTimeFod = JPMhhmmss2Fod(endTime)
endDayFod = endDay + endTimeFod

; Differentiate CADRE
accessNumberCadre = accessNumber[0:497]
startDateJdCadre = ymd2jd(startYear[0:497], JPMmon2mm(startMonth[0:497]), startDayFod[0:497])
endDateJdCadre = ymd2jd(endYear[0:497], JPMmon2mm(endMonth[0:497]), endDayFod[0:497])
durationSecondsCadre = durationSeconds[0:497]

; Differentiate MinXSS
accessNumberMinxss = accessNumber[995:1490]
startDateJdMinxss = ymd2jd(startYear[995:1490], JPMmon2mm(startMonth[995:1490]), startDayFod[995:1490])
endDateJdMinxss = ymd2jd(endYear[995:1490], JPMmon2mm(endMonth[995:1490]), endDayFod[995:1490])
durationSecondsMinxss = durationSeconds[995:1490]

; Loop through 7 day intervals 
percentConflict = !NULL
minxssWeeklyContactTotalTime = !NULL
FOR i = 0, n_elements(accessNumberMinxss) - 1 DO BEGIN
  ; Identify indices for current 7 day group
  minxssWeekJdIndices = where(startDateJdMinxss GE startDateJdMinxss[i] AND startDateJdMinxss LT startDateJdMinxss[i] + 7)
  cadreWeekJdIndices = where(startDateJdCadre GE startDateJdMinxss[i] AND startDateJdCadre LT startDateJdMinxss[i] + 7)
  
  ; Isolate a week of data - MinXSS
  startDateJdMinxssWeek = startDateJdMinxss[minxssWeekJdIndices]
  endDateJdMinxssWeek = endDateJdMinxss[minxssWeekJdIndices]
  durationSecondsMinxssWeek = durationSecondsMinxss[minxssWeekJdIndices]
  
  ; Isolate a week of data - CADRE
  startDateJdCadreWeek = startDateJdCadre[cadreWeekJdIndices]
  endDateJdCadreWeek = endDateJdCadre[cadreWeekJdIndices]
  durationSecondsCadreWeek = durationSecondsCadre[cadreWeekJdIndices]
  
  ; Identify and sum overlap for the week
  overlapSeconds = 0
  FOR accessIndexMinXSS = 0, n_elements(startDateJdMinxssWeek) - 1 DO BEGIN
    ; where are cadre end times greater than the minxss start time but less than the minxss end time
    accessIndexCadre = where(endDateJdCadreWeek GE startDateJdMinxssWeek[accessIndexMinXSS] AND endDateJdCadreWeek LE endDateJdMinxssWeek[accessIndexMinXSS])
    
    IF accessIndexCadre EQ [-1] THEN CONTINUE
    
    ; overlap is greater of the start times to the lesser of the end times
    greaterStartTime = startDateJdMinxssWeek[accessIndexMinXSS] > startDateJdCadreWeek[accessIndexCadre]
    lesserEndTime = endDateJdMinxssWeek[accessIndexMinXSS] < endDateJdCadreWeek[accessIndexCadre]
    IF lesserendtime - greaterstarttime LT 0 THEN STOP
    overlapSeconds += (lesserEndTime - greaterStartTime) * 86400. ; converts fraction of day to total seconds of overlap   
  ENDFOR
  
  ; Sum total contact time for MinXSS (durationSeconds)
  totalContactTimeMinXSS = total(durationSecondsMinxssWeek)
  minxssWeeklyContactTotalTime = [minxssWeeklyContactTotalTime, totalContactTimeMinXSS]
  
  ; Compute percentage of conflict for this week
  percentConflictThisWeek = overlapSeconds / totalContactTimeMinXSS * 100
  
  ; percentConflict = [percentConflict, percentConflictThisWeek]
  percentConflict = [percentConflict, percentConflictThisWeek]
  
  ; Increment by all the indices in the current 7 day group
  i+= n_elements(minxssWeekJdIndices)
ENDFOR

; Plot percentConflict per week
p1 = plot(percentConflict, '2', /HISTOGRAM, MARGIN = 0.1, AXIS_STYLE = 1, $
          TITLE = 'MinXSS-CADRE to Boulder Ground Station Contact Conflict', $
          XTITLE = 'Weeks from 2015/12/21', $
          YTITLE = 'Spacecraft Conflict Per Week [%]')
p2 = plot(minxssWeeklyContactTotalTime/3600., 'r2', /HISTOGRAM, /CURRENT, AXIS_STYLE = 4, MARGIN = 0.1, $
          YRANGE = [0, 8])
ax1 = axis('X', LOCATION = 'top', TARGET = [p1], TEXT_COLOR = 'white', MINOR = 3)
ax2 = axis('Y', LOCATION = 'right', TARGET = [p2], TITLE = 'MinXSS Weekly Contact Time Total [Hours]', COLOR = 'red')

STOP
END