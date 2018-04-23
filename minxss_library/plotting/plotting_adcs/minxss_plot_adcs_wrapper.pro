;+
; NAME:
;   minxss_plot_adcs_wrapper
;
; PURPOSE:
;   Run all of the other programs in the plotting_adcs folder
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plots. Default is a directory on James's computer. 
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Bunch of ADCS related plots
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2017-01-10: James Paul Mason: Wrote script.
;-
PRO minxss_plot_adcs_wrapper, saveloc = saveloc

; Defaults
IF saveloc EQ !NULL THEN BEGIN
  saveloc = '/Users/' + getenv('username') + '/Dropbox/Research/Postdoc_LASP/Papers/20170701 CubeSat Pointing and Power On Orbit/Figures/'
ENDIF

; Get all ADCS plotting scripts
scriptNames = file_search(getenv('minxss_code') + '/src/plotting/plotting_adcs/*.pro')

; Remove this one so as to avoid an infinite loop
goodScriptIndices = where(strmatch(scriptNames, '*minxss_plot_adcs_wrapper.pro', /FOLD_CASE) NE 1)
scriptNames = scriptNames[goodScriptIndices]

; Loop through each script name
FOR i = 0, n_elements(scriptNames) - 1 DO BEGIN 

  ; Parse out the paths, only care about the filenames
  scriptNameParsed = ParsePathAndFilename(scriptNames[i])
  functionName = strmid(scriptNameParsed.filename, 0, strlen(scriptNameParsed.filename) - 4)
  
  ; Execute the script with passed in saveloc
  message, /INFO, JPMsystime() + ': Calling function ' + functionName
  void = execute(functionName + ', saveloc = saveloc')
  
ENDFOR 

END