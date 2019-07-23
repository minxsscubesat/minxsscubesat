function since_version, release
;+
; NAME:
;	SINCE_VERSION
;
; PURPOSE:
;	Determine if the current release of IDL (as given in the 
;	!VERSION.RELEASE system variable) comes after the user specified 
;	release.   
;
; CALLING SEQUENCE:
;	test = SINCE_VERSION( release )
;
; INPUT:
;	release - scalar string, must be formatted exactly like the 
;		!VERSION.RELEASE system variable (e.g. '3.0.0') 
;
; OUTPUT:
;	test - 1 if current release is identical or later than the specified 
;              'release' else 0
;
; EXAMPLE:
;	Use the /FTOXDR keyword to the BYTEORDER procedure if the current 
;	release of IDL is 2.2.2 or later
;
;	IDL> if since_version('2.2.2') then byteorder, a, /FTOXDR
;
; REVISION HISTORY:
;	Written   Wayne Landsman         Hughes/STX        January, 1992
;	Corrected algorithm     W. Landsman                April, 1992
;-
 On_error,2

 if N_params() EQ 0 then begin
    print, 'Syntax -  test = SINCE_VERSION( release )
    return, -1
 endif

 release = strtrim( release, 2)
 v1 = strmid( release, 0 ,1)
 v2 = strmid( release, 2, 1)
 v3 = strmid( release, 4, 1)

 c1 = strmid( !VERSION.RELEASE, 0, 1)
 c2 = strmid( !VERSION.RELEASE, 2, 1)
 c3 = strmid( !VERSION.RELEASE, 4, 1)

 if c1 EQ v1 then begin

       if c2 EQ v2 then return, (c3 GE v3) else return, (c2 GT v2)

 endif else return, (c1 GT v1)

 end
