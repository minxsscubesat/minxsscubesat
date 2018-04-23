;+
; NAME:
;   minxss_plot_thermal_orbit_predicts_wrapper
;
; PURPOSE:
;   Dissertation plot.
;   Create plot showing the model predictions for all 3 orbit scenarios: ISS cold, ISS hot, and sun sync. 
;   Calls minxss_plot_thermal_orbit_predicts_grouped. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPathModel [string]:        The path to the model data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/'
;                                  since James is the only one likely to use this code.
;   plotPath [string]:             The path you want the plots saved to. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Rev8/'
;                                  since James is the only one likely to use this code.                           
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot as described in purpose in the plotPath as well as dissertation directory for James
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires minxss code package
;
; EXAMPLE:
;   None
;
; MODIFICATION HISTORY:
;   2016/04/05: James Paul Mason: Wrote script.
;-
PRO minxss_plot_thermal_orbit_predicts_wrapper, dataPathModel = dataPathModel, plotPath = plotPath

; Defaults
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/' ELSE dataloc = temporary(dataPath)
IF ~keyword_set(plotPath) THEN saveloc = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Results/Rev8/' ELSE saveloc = temporary(plotPath)
savelocDissertation = '/Users/jmason86/Dropbox/Research/Woods_LASP/Papers/20160501 Dissertation/PhD_Dissertation/LaTeX/Images/'

; Update the model files -- convert the TD output txt to IDL saveset
minxss_plot_thermal_orbit_convert_model_txt_to_sav

; Call the minxss_plot_thermal_orbit_predicts_grouped 2 times, once per orbit type (Iss or SunSync)
minxss_plot_thermal_orbit_predicts_grouped, 'Iss'
minxss_plot_thermal_orbit_predicts_grouped, 'SunSync'


END