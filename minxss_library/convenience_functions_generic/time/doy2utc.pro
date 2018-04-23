;+
; Project     : SOHO - CDS     
;                   
; Name        : DOY2UTC()
;               
; Purpose     : Converts day of year to internal CDS time format.
;               
; Explanation : Takes day-of-year value and year (default=current) and
;               converts to the internal CDS UTC time structure.
;               
; Use         : IDL> utc = doy2utc(doy [,year])
;    
; Inputs      : doy - integer day-of-year value (can be an array)
;               
; Opt. Inputs : year - the applicable year (default is current year)
;                      If this is an array it must have the same dimensions
;                      as doy.
;               
; Outputs     : Function returns a CDS UTC structure.
;               
; Opt. Outputs: None
;               
; Keywords    :	EXACT	= If set, then the year is considered to be passed
;			  exactly, even if it's only 2 or 3 digits.
;
;		ERRMSG  = If defined and passed, then any error messages will
;			  be returned to the user in this parameter rather than
;			  being handled by the IDL MESSAGE utility.  If no
;			  errors are encountered, then a null string is
;			  returned.  In order to use this feature, the string
;			  ERRMSG must be defined first, e.g.,
;
;				ERRMSG = ''
;				RESULT = DOY2UTC( DOY, ERRMSG=ERRMSG )
;				IF ERRMSG NE '' THEN ...
;
; Calls       :	None
;
; Common      : None
;               
; Restrictions: None
;               
; Side effects: If an error is encountered and the ERRMSG keyword has been 
;		set, the result returned is an integer -1.  If ERRMSG has
;		not been set and an error occurs, DOY2UTC returns with a
;		null result.
;               
; Category    : Util, time
;               
; Prev. Hist. : None
;
; Written     : C D Pike, RAL, 5-Jan-95
;               
; Modified    :	Version 1, C.D. Pike, RAL, 5 January 1995
;		Version 2, C.D. Pike, RAL, 9 January 1995
;			Fix bug if input is single value array.
;		Version 3, Donald G. Luttermoser, GSFC/ARC, 1 February 1995
;			Added the keyword ERRMSG.  Set ONERROR flag to 2.
;			Corrected bug in YEAR calculation.  Note that this
;			routine can handle both scalar and vector input.
;               Version 4, Changed handling of input year array, as 
;                          suggested by S Paswaters.  CDP, 10-Mar-95
;		Version 5, 5-Jan-2000, William Thompson, GSFC
;			Changed way that two-digit years are interpreted for
;			better Y2K compliance.
;   	    	Version 6,16-Sep-2010, N.Rich, NRL
;   	    	    	Fix ambiguous array subscript for doy
;
; Version     : Version 5, 5-Jan-2000
;-            

function doy2utc, doy, year, exact=exact, errmsg=errmsg

onerror = 2  ;  Return to caller if error is detected.
message = '' ;  Error message string.

;
;  Any parameters?
;
if n_params() eq 0 then begin
   message='Syntax:  Result = DOY2UTC( DOY [,YEAR])'
   goto, handle_error
endif

;
;  How many values?
;
num = n_elements(doy)

if num eq 1 then doy = doy[0]

;
;  Was year supplied?
;
if n_params() eq 1 then begin
   get_utc,u
   year = fix(strmid(utc2str(u),0,4))
endif else if (not keyword_set(exact)) and (year(0) lt  100) then	$
	year = ((year + 50) mod 100) + 1950

;
;  Make year match in dimension
;
if n_elements(year) ne n_elements(doy) then begin
   if n_elements(year) gt 1 then begin
      message='Array sizes for doy and year parameters do not match.'
      goto, handle_error
   endif else begin
      ty = year(0)
      year = intarr(n_elements(doy))
      year(*) = ty
   endelse
endif

;
;  UTC for Jan 1 year in question.
;
day1 = str2utc('1-Jan-'+strtrim(year,2),/dmy)

;
;  Add day of year number.
;
out = replicate({cds_int_time},n_elements(doy))

out.mjd = doy + day1.mjd - 1

;
;  So result is ...
;
return, out

;
; Error handling section.
;
handle_error:
if n_elements(errmsg) eq 0 then message, message
errmsg = message
return, -1
;
end   
