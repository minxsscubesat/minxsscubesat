;+
; NAME:
;	qlxrs
;
; PURPOSE:
;	Do quick time series plot of all XRS data
;
; CATEGORY:
;	SURF procedure for quick look purpose only
;
; CALLING SEQUENCE:  
;	qlxrs, filename=filename, surffile=surffile, itime=itime, debug=debug
;
; INPUTS:
;	filename	Optional input for DataView Dump file of Rocket XRS MCU data
;	surffile	Optional input to read SURFER log file
;	itime		Optional input to specify the integration time: default is 1.0 sec
;	debug		Optional input that will do STOP at end of procedure
;
; OUTPUTS:  
;	PLOT		Plot to screen the time series of all 4 XRS channels
;				Plot is normalized to SURF beam current if given surffile
;
; COMMON BLOCKS:
;	None
;
; PROCEDURE:
;	1.  Check input parameters
;	2.	Call plotxrs.pro for XRS channels A1, B1, A2, and B2
;	3.  Stop at end if /DEBUG is used
;
; MODIFICATION HISTORY:
;	1/19/10		Tom Woods	Original file creation
;
;+

pro qlxrs, filename=filename, surffile=surffile, itime=itime, debug=debug

;
;	1.  Check input parameters
;
if keyword_set(filename) then infile = filename else infile = ' '

if keyword_set(surffile) then insurf = surffile else insurf = ' '

if keyword_set(itime) then integtime = float(itime) else integtime = 1.0
if (integtime lt 1.0) then integtime = 1.0

;
;	2.	Call plotxrs.pro for XRS channels A1, B1, A2, and B2
;
ans = ' '
if keyword_set(surffile) then begin
  plotxrs, 'A1', infile, insurf, itime=integtime, data=a1
  read, 'Next plot ? ', ans
  plotxrs, 'B1', infile, insurf, itime=integtime, data=b1
  read, 'Next plot ? ', ans
  plotxrs, 'A2', infile, insurf, itime=integtime, data=a2
  read, 'Next plot ? ', ans
  plotxrs, 'B2', infile, insurf, itime=integtime, data=b2
endif else begin
  plotxrs, 'A1', infile, itime=integtime, data=a1
  read, 'Next plot ? ', ans
  plotxrs, 'B1', infile, itime=integtime, data=b1
  read, 'Next plot ? ', ans
  plotxrs, 'A2', infile, itime=integtime, data=a2
  read, 'Next plot ? ', ans
  plotxrs, 'B2', infile, itime=integtime, data=b2
endelse

;
;	3.  Stop at end if /DEBUG is used
;
if keyword_set(debug) then begin
  stop, 'DEBUG qlxrs: check out a1, b1, a2, b2 data structures...'
endif

return
end

