;+
; NAME:
;   minxss_plot_timeseries_example
;
; PURPOSE:
;   Plot a single arbitrary MinXSS spectral bin through time as an example of how to do so
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   savePath [string]: Set this to the path you want to save the plot to
;
; KEYWORD PARAMETERS:
;   VERBOSE: Set this to print processing messages to console
;
; OUTPUTS:
;   plot: MinXSS Level 1 arbitrary spectral bin at index 73 as a function of time
;
; OPTIONAL OUTPUTS:
;   If savePath optional input was specified, then the plot will be saved to disk as a .png
;
; RESTRICTIONS:
;   Requires IDL 8.2.2 or higher
;
; EXAMPLE:
;   minxss_plot_timeseries_example, savePath = '/users/jmason86/Dropbox/very_important_analysis/minxss_is_awesome/'
;
; MODIFICATION HISTORY:
;   2016-08-31: James Paul Mason: Wrote script.
;-
PRO minxss_plot_timeseries_example, savePath = savePath, $
                                    VERBOSE = VERBOSE

; Start a timer
tic

; Load data
IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Resotring MinXSS level 1 data'
restore, '/Users/jmason86/Dropbox/minxss_dropbox/data/fm1/level1/minxss1_l1_mission_length.sav'

; Plot a single arbitrary bin at index 30 as a function of time
IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Plotting MinXSS level 1 arbitrary bin at 2.0 keV vs time'
labelDate = label_date(DATE_FORMAT = ['%M', '%Y'])
p1 = plot(minxsslevel1.time.jd, minxsslevel1.irradiance[73], SYMBOL = 'dot', SYM_THICK = 3, COLOR = 'dodger blue', $
             TITLE = 'MinXSS Solar SXR ' + strtrim(minxsslevel1[0].energy[73], 2) + ' keV Over Time', $
             XTITLE = 'Time [UTC]', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Month', 'Year'], XTICKINTERVAL = 1, $
             YTITLE = 'Irradiance [photons / sec / cm$^2$ / keV]')
IF savePath NE !NULL THEN p1.save, savePath + path_sep() + 'minxss level 1 0.75 keV.png'

message, /INFO, systime() + ' Completed in ' + strtrim(toc(), 2) + ' seconds'

END