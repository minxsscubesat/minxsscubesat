;+
; NAME:
;   minxss_plot_tbal_convert_model_txt_to_sav
;
; PURPOSE:
;   For some stupid reason, thermal desktop always outputs an xls with a time column every other spot. Generate a sensible csv. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   dataPathModel [string]:        The path to the model data. Default is '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/'
;                                  since James is the only one likely to use this code.
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
;   2016/04/01: James Paul Mason: Wrote script.
;-
PRO minxss_plot_tbal_convert_model_txt_to_sav, dataPathModel = dataPathModel

; Defaults
IF ~keyword_set(dataPathModel) THEN datalocModel = '/Users/jmason86/Dropbox/CubeSat/Thermal Analysis/MinXSS Thermal Desktop Model/Thermal Balance Rev 2 (Based on MinXSS Rev7)/' ELSE dataloc = temporary(dataPath)

; Read the hot balance file from Thermal Desktop
readcol, datalocModel + 'Hot Transient Measures.txt', timeSeconds, tcMinusXTopModel, t, tcMinusXMiddleModel, t, tcMinusXBottomModel, $
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
save, FILENAME = datalocModel + 'Hot Transient Measures.sav', /COMPRESS, $
      timeModelHours, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
      tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
      tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
      tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
      tcMinusZModel, tcPlusZModel, $
      tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
      tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
      tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel

; Read the cold balance file from Thermal Desktop
readcol, datalocModel + 'Cold Steady State Measures.txt', timeSeconds, tcMinusXTopModel, t, tcMinusXMiddleModel, t, tcMinusXBottomModel, $
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
save, FILENAME = datalocModel + 'Cold Steady State Measures.sav', /COMPRESS, $
      timeModelHours, tcMinusXTopModel, tcMinusXMiddleModel, tcMinusXBottomModel, $
      tcPlusYTopModel, tcPlusYMiddleModel, tcPlusYBottomModel, $
      tcPlusXOnSaModel, tcPlusXUnderSaModel, tcPlusXBottomModel, tcPlusXTopModel, $
      tcMinusYTopModel, tcMinusYMiddleModel, tcMinusYBottomModel, $
      tcMinusZModel, tcPlusZModel, $
      tlmSaPlusYModel, tlmSaMinusYModel, tlmSaPlusXModel, $
      tlmEpsModel, tlmBatteryModel, tlmCdhModel, tlmCommModel, $
      tlmX123DetectorModel, tlmX123BoardModel, tlmMotherboardModel

END