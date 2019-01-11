;+
; NAME:
;   JPMyyyymmdd2yyyydoy
;
; PURPOSE:
;   Convert a standard format date to year and day of year. 
;   Adapted from Date2DOY http://www.astro.washington.edu/docs/idl/cgi-bin/getpro/library32.html?DATE2DOY
;
; INPUTS:
;   idate [string or long]: Input date in standard format yyyymmdd (e.g., 20150626)
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   RETURN_STRING: Set this to return a single string in yyyydoy format instead of a structure with yyyy and doy tags. 
;
; OUTPUTS:
;   Returns [long]: year and doy fields, with corresponding values. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   yearDoy = JPMyyyymmdd2yyyydoy(20150626)
;-

FUNCTION JPMyyyymmdd2yyyydoy, idate, RETURN_STRING = RETURN_STRING

; Check data type of input set ascII flag and convert to yyyy,mm,dd:
  info = SIZE(idate)
  IF (info(0) eq 0) THEN BEGIN
    scalar = 1        ;scalar flag set
  ENDIF ELSE BEGIN
    scalar = 0        ;vector input
  ENDELSE

  IF (info(info(0) + 1) eq 7) THEN BEGIN
    ascII = 1       ;ascII input flag set
    yyyy = FIX(STRMID(idate,0,4))   ;extract year
    mm = FIX(STRMID(idate,4,2))   ;extract month
    dd = FIX(STRMID(idate,6,2))   ;extract day
  ENDIF ELSE BEGIN      ;should be a longWord
    ascII = 0       ;non-ascII input
    sdate = STRTRIM(STRING(idate),2)  ;convert to string 
    yyyy = FIX(STRMID(sdate,0,4))   ;extract year
    mm = FIX(STRMID(sdate,4,2))   ;extract month
    dd = FIX(STRMID(sdate,6,2))   ;extract day
  ENDELSE

; Check for leap year and compute DOY:
;               J   F   M   A   M   J   J   A   S   O   N   D
  imonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  IF (scalar) THEN BEGIN      ;scalar input
    IF ((yyyy MOD 4) eq 0) THEN BEGIN ;leap year
      imonth(2) = 29      ;set feb
    ENDIF
    myDOY = FIX( TOTAL(imonth(0:mm-1)) ) + dd
  ENDIF ELSE BEGIN
    myDOY = dd        ;set correct len on vector
    leapYrs = WHERE( (yyyy MOD 4) eq 0) ;index of leap years
    nonLeap = WHERE( (yyyy MOD 4) ne 0) ;index of non-leap years
    IF (nonLeap(0) ne -1) THEN BEGIN
      FOR i=0, N_elements(nonLeap)-1 DO BEGIN
        myDOY(nonLeap(i)) = FIX( TOTAL(imonth(0:mm(nonLeap(i))-1)) ) + $
        dd(nonLeap(i))
      ENDFOR
    ENDIF
    IF (leapYrs(0) ne -1) THEN BEGIN
      imonth(2) = 29      ;set feb
      FOR i =0, N_elements(leapYrs)-1 DO BEGIN
        myDOY(leapYrs(i)) = FIX( TOTAL(imonth(0:mm(leapYrs(i))-1)) ) + dd(leapYrs(i))
      ENDFOR
    ENDIF
  ENDELSE
  
  IF (ascII) THEN BEGIN
    yearOutput = STRTRIM(STRING(yyyy), 2)  ;convert to string   
    myDOY = STRTRIM(STRING(myDOY), 2) ;convert to string   
 ENDIF ELSE BEGIN
   yearOutput = yyyy
 ENDELSE      

; Create yyyydoy string
IF myDoy LT 10 THEN BEGIN
  doyString = '00' + strtrim(myDoy, 2) 
ENDIF ELSE IF myDoy LT 100 THEN BEGIN
  doyString = '0' + strtrim(myDoy, 2) 
ENDIF ELSE BEGIN
  doyString = strtrim(myDoy, 2)
ENDELSE
yyyydoyString = strtrim(yearOutput, 2) + doyString

IF keyword_set(RETURN_STRING) THEN BEGIN
  return, yyyydoyString
ENDIF ELSE return, long(yyyydoyString)

END
