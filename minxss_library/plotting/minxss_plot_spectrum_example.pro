;+
; NAME:
;   minxss_plot_spectrum_example
;
; PURPOSE:
;   Plot a single arbitrary MinXSS spectrum as an example of how to do so
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
;   plot: MinXSS Level 1 spectrum at index 100 
;
; OPTIONAL OUTPUTS:
;   If savePath optional input was specified, then the plot will be saved to disk as a .png
;
; RESTRICTIONS:
;   Requires IDL 8.2.2 or higher
;
; EXAMPLE:
;   minxss_plot_spectrum, savePath = '/users/jmason86/Dropbox/very_important_analysis/minxss_is_awesome/'
;
; MODIFICATION HISTORY:
;   2016-08-31: James Paul Mason: Wrote script.
;   2017-04-13: James Paul Mason: Restricted xrange to good values, made y on a log scale
;-
PRO minxss_plot_spectrum_example, savePath = savePath, $
                                  VERBOSE = VERBOSE

; Start a timer
TIC

; Which spectrum index to plot
spectrumIndex = 2060 ; Corresponds to an M5.0 flare on 2016-07-23T01:36:05

; Load data
IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Resotring MinXSS level 1 data'
restore, getenv('minxss_data') + 'fm1/level1/minxss1_l1_mission_length.sav'

; Plot a single arbitrary spectrum at index 100
IF keyword_set(VERBOSE) THEN message, /INFO, systime() + ' Plotting MinXSS level 1 arbitrary spectrum at index 100'
p1 = plot(minxsslevel1[spectrumIndex].energy, minxsslevel1[spectrumIndex].irradiance, THICK = 2, $
             TITLE = 'MinXSS Solar SXR Spectrum on ' + minxsslevel1[spectrumIndex].time.human, $
             XTITLE = 'Energy [keV]', XRANGE = [0.8, 2.5], $
             YTITLE = 'Irradiance [photons / sec / cm$^2$ / keV]', YRANGE = [1e4, 1e9], /YLOG)
IF savePath NE !NULL THEN p1.save, savePath + path_sep() + 'minxss level 1 spectrum ' + minxsslevel1[spectrumIndex].time.human + '.png'

message, /INFO, systime() + ' Completed in ' + strtrim(toc(), 2) + ' seconds'
END