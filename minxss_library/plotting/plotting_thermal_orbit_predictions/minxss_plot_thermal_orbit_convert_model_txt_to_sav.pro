;+
; NAME:
;   minxss_plot_thermal_orbit_convert_model_txt_to_sav
;
; PURPOSE:
;   For some stupid reason, thermal desktop always outputs an xls with a time column every other spot. Generate a restorable sav file instead. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPathModel [string]: The path to the model data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/'
;                           since James is the only one likely to use this code.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plot as described in purpose
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
PRO minxss_plot_thermal_orbit_convert_model_txt_to_sav, dataPathModel = dataPathModel

; Defaults
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/Research/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Rev8/' ELSE dataloc = temporary(dataPath)

; Read the hot case file from Thermal Desktop
readcol, datalocModel + 'ISS Hot Worst Case Model Predicts.txt', timeSeconds, tcMinusXTopModel, t, tcMinusXMiddleModel, t, tcMinusXBottomModel, $
                                                                 t, tcPlusYTopModel, t, tcPlusYMiddleModel, t, tcPlusYBottomModel, $
                                                                 t, tcPlusXOnSaModel, t, tcPlusXUnderSaModel, t, tcPlusXBottomModel, t, tcPlusXTopModel, $
                                                                 t, tcMinusYTopModel, t, tcMinusYMiddleModel, t, tcMinusYBottomModel, $
                                                                 t, tcMinusZModel, t, tcPlusZModel, $
                                                                 t, tlmSaPlusYModel, t, tlmSaMinusYModel, t, tlmSaPlusXModel, $
                                                                 t, tlmEpsModel, t, tlmBatteryModel, t, tlmCdhModel, t, tlmCommModel, $
                                                                 t, tlmX123DetectorModel, t, tlmX123BoardModel, t, tlmMotherboardModel, DELIMITER = ' ', SKIPLINE = 1, /SILENT

; Convert time to hours
timeModelHours = timeSeconds / 3600. 

; Make IDL saveset
save, FILENAME = datalocModel + 'ISS Hot Worst Case Model Predicts.sav', /COMPRESS, $
      timeModelHours, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
      tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
      tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
      tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
      tcMinusZModel, tcPlusZModel, $
      tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
      tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
      tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel


; Read the hot case BOL file from Thermal Desktop
readcol, datalocModel + 'ISS Hot Model Predicts.txt', timeSeconds, tcMinusXTopModel, t, tcMinusXMiddleModel, t, tcMinusXBottomModel, $
                                                      t, tcPlusYTopModel, t, tcPlusYMiddleModel, t, tcPlusYBottomModel, $
                                                      t, tcPlusXOnSaModel, t, tcPlusXUnderSaModel, t, tcPlusXBottomModel, t, tcPlusXTopModel, $
                                                      t, tcMinusYTopModel, t, tcMinusYMiddleModel, t, tcMinusYBottomModel, $
                                                      t, tcMinusZModel, t, tcPlusZModel, $
                                                      t, tlmSaPlusYModel, t, tlmSaMinusYModel, t, tlmSaPlusXModel, $
                                                      t, tlmEpsModel, t, tlmBatteryModel, t, tlmCdhModel, t, tlmCommModel, $
                                                      t, tlmX123DetectorModel, t, tlmX123BoardModel, t, tlmMotherboardModel, DELIMITER = ' ', SKIPLINE = 1, /SILENT

; Convert time to hours
timeModelHours = timeSeconds / 3600.

; Make IDL saveset
save, FILENAME = datalocModel + 'ISS Hot Model Predicts.sav', /COMPRESS, $
  timeModelHours, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
  tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
  tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
  tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
  tcMinusZModel, tcPlusZModel, $
  tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
  tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
  tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel

; Read the cold case file from Thermal Desktop
readcol, datalocModel + 'ISS Cold Model Predicts.txt', timeSeconds2, tcMinusXTopModel, t, tcMinusXMiddleModel, t, tcMinusXBottomModel, $
                                                       t, tcPlusYTopModel, t, tcPlusYMiddleModel, t, tcPlusYBottomModel, $
                                                       t, tcPlusXOnSaModel, t, tcPlusXUnderSaModel, t, tcPlusXBottomModel, t, tcPlusXTopModel, $
                                                       t, tcMinusYTopModel, t, tcMinusYMiddleModel, t, tcMinusYBottomModel, $
                                                       t, tcMinusZModel, t, tcPlusZModel, $
                                                       t, tlmSaPlusYModel, t, tlmSaMinusYModel, t, tlmSaPlusXModel, $
                                                       t, tlmEpsModel, t, tlmBatteryModel, t, tlmCdhModel, t, tlmCommModel, $
                                                       t, tlmX123DetectorModel, t, tlmX123BoardModel, t, tlmMotherboardModel, DELIMITER = ' ', SKIPLINE = 1, /SILENT

; Convert time to hours
timeModelHours = timeSeconds / 3600.

; Make IDL saveset
save, FILENAME = datalocModel + 'ISS Cold Model Predicts.sav', /COMPRESS, $
      timeModelHours, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
      tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
      tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
      tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
      tcMinusZModel, tcPlusZModel, $
      tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
      tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
      tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel

END