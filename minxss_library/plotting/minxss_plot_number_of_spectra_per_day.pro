;+
; NAME:
;   minxss_plot_number_of_spectra_per_day
;
; PURPOSE:
;   Create a plot of the number of level 1 spectra per day over the length of the mission
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   LEVEL0C: Set this keyword to use the level 0c spectra (10 second spectra). The default is to use level 1 (1 minute averages).
;
; OUTPUTS:
;   Plot of number of spectra per day over the length of the mission
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 1 data and MinXSS code package
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016-12-29: James Paul Mason: Wrote script.
;-
PRO minxss_plot_number_of_spectra_per_day, LEVEL0C = LEVEL0C

; Defaults
IF keyword_set(LEVEL0C) THEN BEGIN
  levelTitle = 'Level 0C'
ENDIF ELSE BEGIN
  levelTitle = 'Level 1'
ENDELSE

; Get the number of spectra per day for the length of the mission
numberOfSpectra = minxss_number_of_spectra_for_date('all', ouptutJd = dateJd, LEVEL0C = LEVEL0C)

; Generate cumulative spectra array
FOR i = 0, n_elements(dateJd) - 1 DO BEGIN
  cumulativeSpectra = (cumulativeSpectra NE !NULL) ? [cumulativeSpectra, cumulativeSpectra[i - 1] + numberOfSpectra[i]] : numberOfSpectra[i]
ENDFOR

; Create per day plot
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(dateJd, numberOfSpectra, COLOR = 'dodger blue', FILL_COLOR = 'dodger blue', /FILL_BACKGROUND, $ 
         TITLE = 'MinXSS-1 ' + levelTitle + ' Science Coverage', $ 
         XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
         YTITLE = '# of Spectra Per Day')

; Create cumulative plot
p2 = plot(dateJd, cumulativeSpectra, COLOR = 'dodger blue', FILL_COLOR = 'dodger blue', /FILL_BACKGROUND, $
          TITLE = 'MinXSS-1 ' + levelTitle + ' Solar Spectra Downlinked', $
          XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
          YTITLE = 'Cumulative Spectra [#]', YTICKFORMAT = '(f10.0)')

END