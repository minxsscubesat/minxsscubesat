;+
; NAME:
;   minxss_number_of_spectra_for_date
;
; PURPOSE:
;   Determine how many spectra we have on the ground for a particular date
;
; INPUTS:
;   date [long or string]: Date to check the number of spectra for. Can be formatted as either yyyydoy (long) or 'yyyymmdd' (string). 
;                          Can also specify date as 'all' to return an array with the number of spectra for every date in the mission. 
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   LEVEL0C: Set this keyword to use the level 0c spectra (10 second spectra). The default is to use level 1 (1 minute averages). 
;
; OUTPUTS:
;   numberOfSpectra [integer]: Returns the number of spectra found for the input date
;
; OPTIONAL OUTPUTS:
;   outputJd [dblarr]: Return the date(s) in Julian date format
;
; RESTRICTIONS:
;   Requires access to the MinXSS level 1 data
;
; EXAMPLE:
;   print, minxss_number_of_spectra_for_date('20161228')
;
; MODIFICATION HISTORY:
;   2016-12-28: James Paul Mason: Wrote script.
;-
FUNCTION minxss_number_of_spectra_for_date, date, ouptutJd = outputJd, $
                                            LEVEL0C = LEVEL0C

; Input validty check and conversion
IF isA(date, 'string') AND date NE 'all' THEN BEGIN
  inputDateYyyyDoy = JPMyyyymmdd2yyyydoy(date)
ENDIF ELSE $
IF isa(date, 'long') THEN BEGIN
  inputDateYyyyDoy = date
ENDIF

; Restore the data
IF keyword_set(LEVEL0C) THEN BEGIN
  restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav
  packetTimeYYYYDOY_FOD = jd2yd(sci.time_jd)
  yyyydoy = long(packetTimeYYYYDOY_FOD)
  ;yyyydoy = JPMjd2yyyydoy(sci.time_jd)
  jd = sci.time_jd
ENDIF ELSE BEGIN
  restore, getenv('minxss_data') + '/fm1/level1/minxss1_l1_mission_length.sav'
  yyyydoy = minxsslevel1.time.yyyydoy
  jd = minxsslevel1.time.jd
ENDELSE 

; If returning for all dates then loop through each date and add up number of spectra
IF date EQ 'all' THEN BEGIN
  FOR inputDateYyyyDoy = 2016137, JPMjd2yyyydoy(JPMiso2jd(JPMsystime(/ISO, /UTC))) DO BEGIN
    matchedDateIndices = where(yyyydoy EQ inputDateYyyyDoy, numberOfSpectraTemp)
    numberOfSpectra = (numberOfSpectra NE !NULL) ? [numberOfSpectra, numberOfSpectraTemp] : numberOfSpectraTemp
    
    IF numberOfSpectraTemp NE 0 THEN BEGIN
      outputJd = (outputJd NE !NULL) ? [outputJd, floor(jd[matchedDateIndices[0]])] : floor(jd[matchedDateIndices[0]])
    ENDIF ELSE BEGIN
      outputJd = (outputJd NE !NULL) ? [outputJd, !VALUES.D_NAN] : !VALUES.D_NAN
    ENDELSE
    
  ENDFOR
  
  return, numberOfSpectra
  
ENDIF

; Determine how many spectra for given day
matchedDateIndices = where(yyyydoy EQ inputDateYyyyDoy, numberOfSpectra)
outputJd = floor(jd[matchedDateIndices[0]]) ; TODO: Do I need to add 0.5 to get back to normal JD definition of starting at noon?

return, numberOfSpectra

END