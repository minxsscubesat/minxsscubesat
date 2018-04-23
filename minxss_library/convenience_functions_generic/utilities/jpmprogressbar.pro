;+
; NAME:
;   JPMProgressBar
;
; PURPOSE:
;   Provide a graphical display of a programs progress. 
;
; INPUTS:
;   percentComplete [float]:      The percentage complete of the program
;   progressBar [barplot object]: Always pass this in and have the return value have the same name so that the plot can simply be updated rather than a new one generated. 
;   ticObject   [TIC object]:     Always pass this in so that the timer is accessible
;   runTimeText [text object]:    Always pass this in so that a display of run time can be updated
;   etaText [text object]:        Always pass this in so that a display of the estimated time remaining can be updated
;   
; OPTIONAL INPUTS:
;    NAME [string]: Name for the window title
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Progress bar plot
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   progressBar = JPMProgressBar(100. * i/n_elements(array), progressBar = progressBar)
;
; MODIFICATION HISTORY:
;   2015-02-18: James Paul Mason: Wrote script.
;   2015-06-01: James Paul Mason: Fixed the IDLGRMODEL::DRAW error message by using CLIP = 0, which screwed up clipping in first iteration. Used SetData after first iteration
;                                 to get ultimate desired behavior.
;   2016-06-11: James Paul Mason: Added the ticObject, runTimeText, and etaText inputs to show these text values. They are now required. 
;   2016-10-08: James Paul Mason: Switched from jpmsod2hhmmss to JPMseconds2hhmmss to allow for times > 1 day
;-
FUNCTION JPMProgressBar, percentComplete, progressBar = progressBar, name = name, ticObject = ticObject, runTimeText = runTimeText, etaText = etaText

IF ~keyword_set(NAME) THEN name = 'Program Progress'

; Format run time string
runTime = TOC(ticObject) ; [s]
runTimeString = JPMseconds2hhmmss(runTime, /RETURN_STRING)

; Compute estimated time remaining and format string
averageProgressRate = percentComplete / runTime
estimatedRemainingTime = (100 - percentComplete) / averageProgressRate
estimatedRemainingTimeString = JPMseconds2hhmmss(estimatedRemainingTime, /RETURN_STRING)

IF progressBar EQ !NULL THEN BEGIN
  progressBar = barplot([percentComplete], WIDTH = 1, DIMENSIONS = [500, 100], MARGIN = [0.01, 0.2, 0.03, 0], /NO_TOOLBAR, CLIP = 0, $
                        WINDOW_TITLE = name, NAME = name, $
                        XRANGE = [0, 100], /HORIZONTAL, $
                        YRANGE = [0, 0.5])
  runTimeText = text(0.7, 0.65, 'Run Time: ' + runTimeString, ALIGNMENT = 1)
  etaText = text(0.7, 0.50, 'Estimated Remaining Time: ' + estimatedRemainingTimeString, ALIGNMENT = 1)
ENDIF

progressBar.SetData, percentComplete ; This fixes the clipping for the first iteration and updates it as normal thereafter
runTimeText.string = 'Run Time: ' + runTimeString
etaText.string = 'Estimated Remaining Time: ' + estimatedRemainingTimeString

return, progressBar
END