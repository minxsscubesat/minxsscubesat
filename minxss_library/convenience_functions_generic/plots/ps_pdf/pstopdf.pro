PRO PSTOPDF, psfile, $
	PDFFILE    = pdffile,  $
	WAIT       = wait,   $
	DELETEPS   = deleteps, $
	STATUS     = status,   $
	VERBOSE    = verbose

;+
; NAME:
;		PSTOPDF
; PURPOSE:
;		This procedure converts a PostScript file to a PDF file by using the 
;		pstopdf command.
; CALLING SEQUENCE:
;		PSTOPDF, psfile
; ARGUMENTS:
;		psfile   : A string or string array of PostScript file names to convert to PDF.
; KEYWORDS:
;		PDFFILE  : Optional PDF output file name or array of file names to match psfile.
;					  The default is to name the outpuf file(s) the same as the input,
;					  but with the suffix .pdf rather than .ps.
;		WAIT     : By default, the pstopdf command is run in the background while IDL
;					  continues to execute.  If the WAIT keyword is set, the SPAWN command
;					  will wait until the pstopdf process exits before and continuing
;					  IDL execution.
;		DELETEPS : Set this keyword to delete the PS file after converting to PDF.
;		STATUS   : Set this keyword to a named variable to retrieve the operation
;					  status.  It returns 1 if successful and 0 if not.
;		VERBOSE  : Set this keyword to print verbose informational messages.
; REQUIREMENTS
;		The routine spawns the command 'pstopdf' - this is built into Mac OSX and 
;		possibly other platforms.  FILE_DELETE is used to delete the file.
; MODIFICATION HISTORY
;	Original by Ben Tupper.  Heavily modified by K. Bowman.
;-

COMPILE_OPT IDL2																					;Set compile options

status = 0																							;Status flag

n = N_ELEMENTS(psfile)																			;Number of files to convert
IF (n EQ 0) THEN RETURN																			;No files found

FOR i = 0, n-1 DO BEGIN
	IF KEYWORD_SET(verbose) THEN PRINT, 'Converting ', psfile[i] , ' to PDF.'	;Print info message

	cmd = 'pstopdf ' + psfile[i] 																;Create command

	IF (N_ELEMENTS(pdffile) GT 0) THEN cmd = cmd + ' -o ' + pdffile[i]			;Optionally add output file name
	
	IF ~KEYWORD_SET(wait) THEN cmd = cmd + ' &'											;Default is run as a background process
	
	SPAWN, cmd																						;Run command

	IF KEYWORD_SET(deleteps) THEN FILE_DELETE, psfile[i]								;Delete PS file
ENDFOR

status = 1																							;Set status flag

END
