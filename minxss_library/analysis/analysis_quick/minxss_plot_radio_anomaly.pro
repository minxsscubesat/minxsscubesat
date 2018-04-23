;+
; NAME:
;   minxss_plot_radio_anomaly
;
; PURPOSE:
;   Create plots and output to analyze the radio anomaly observed in MinXSS-2 post vibe-2 
;   when antenna failed to deploy and soon after the radio ceased communicating with CDH.
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   saveloc [string]: The path to save the plot. Default is current directory.
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Various plots
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires file minxss2_l0c_2018_073_radio_anomaly.sav or the telmetry files to generate it
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2018-03-14: James Paul Mason: Wrote script.
;-
PRO minxss_plot_radio_anomaly, saveloc = saveloc, REPROCESS = REPROCESS

IF saveloc EQ !NULL THEN BEGIN
  saveloc = '/Users/jmason86/Google Drive/CubeSat/MinXSS Server/4000 Testing/4310 FM2 Anomalies Before_After Vibe 2/4310-006 Li-1 Hang Up/'
ENDIF

fontSize = 12

IF keyword_set(REPROCESS) THEN BEGIN
  FOR yyyydoy = 2018070L, 2018074L DO BEGIN
    yyyydoy_long_forced = long(yyyydoy)
    minxss_make_level0b, YYYYDOY = yyyydoy_long_forced, FM = 2, /VERBOSE ; this code changes yyyydoy to string
  ENDFOR
  
  FOR yyyydoy = 2018070L, 2018074L DO BEGIN
    minxss_make_level0c, YYYYDOY = long(yyyydoy), FM = 2, /VERBOSE
  ENDFOR

; Restore and concatenate the level 0c data
hkTemp = !NULl
logTemp = !NULL
adcs1Temp = !NULL
adcs2Temp = !NULL
adcs3Temp = !NULL
adcs4Temp = !NULL
FOR doy = 70, 73 DO BEGIN
  restore, '/Users/jmason86/Dropbox/minxss_dropbox/data/fm2/level0c/minxss2_l0c_2018_0' + strtrim(doy, 2) + '.sav'
  hkTemp = [hkTemp, hk]
  logTemp = [logTemp, log]
  adcs1Temp = [adcs1Temp, adcs1]
  adcs2Temp = [adcs2Temp, adcs2]
  adcs3Temp = [adcs3Temp, adcs3]
  adcs4Temp = [adcs4Temp, adcs4]
ENDFOR
hk = hkTemp
log = logTemp
adcs1 = adcs1Temp
adcs2 = adcs2Temp
adcs3 = adcs3Temp
adcs4 = adcs4Temp

save, hk, log, adcs1, adcs2, adcs3, adcs4, filename = '/Users/jmason86/Dropbox/minxss_dropbox/data/fm2/level0c/minxss2_l0c_2018_070-073_radio_anomaly.sav'
ENDIF ELSE BEGIN
  restore, '/Users/jmason86/Dropbox/minxss_dropbox/data/fm2/level0c/minxss2_l0c_2018_070-073_radio_anomaly.sav'
ENDELSE

;;
; Create plots
;;

labelDate = label_date(DATE_FORMAT = ['%H', '%D'])

p1 = plot(hk.time_jd - 5./24., hk.EPS_BATT_DISCHARGE, LINESTYLE = 'none', SYMBOL = '*', FONT_SIZE = fontsize, $
          TITLE = 'MinXSS-2 Radio Anomaly Analysis', $
          XTITLE = 'Hour [MT, top], Day [bottom]', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XTICKINTERVAL = 8, $
          YTITLE = 'Battery Current [mA]')
p1.save, saveloc + 'Battery Discharge.png'
          
p2 = plot(hk.time_jd - 5./24., hk.XACT_WHEEL1MEASSPEED, LINESTYLE = 'none', SYMBOL = '*', FONT_SIZE = fontsize, $
          TITLE = 'MinXSS-2 Radio Anomaly Analysis', $
          XTITLE = 'Hour [MT, top], Day [bottom]', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XTICKINTERVAL = 8, $
          YTITLE = 'Wheel Speed')
p2.save, saveloc + 'XACT Wheel 1.png'

p3 = plot(hk.time_jd - 5./24., hk.RADIO_RSSI, LINESTYLE = 'none', SYMBOL = '*', FONT_SIZE = fontsize, $
          TITLE = 'MinXSS-2 Radio Anomaly Analysis', $
          XTITLE = 'Hour [MT, top], Day [bottom]', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XTICKINTERVAL = 8, $
          YTITLE = 'Radio RSSI [dB]')
p3.save, saveloc + 'RSSI.png'

p4 = plot(hk.time_jd - 5./24., hk.COMM_TEMP, LINESTYLE = 'none', SYMBOL = '*', FONT_SIZE = fontsize, $
          TITLE = 'MinXSS-2 Radio Anomaly Analysis', $
          XTITLE = 'Hour [MT, top], Day [bottom]', XTICKFORMAT = ['LABEL_DATE', 'LABEL_DATE'], XTICKUNITS = ['Hour', 'Day'], XTICKINTERVAL = 8, $
          YTITLE = 'Comm Board Temperature [ºC]')
p4.save, saveloc + 'Comm Board Temperature.png'

p5 = plot(hk.time_jd, hk.COMM_LAST_STATUS, LINESTYLE = 'none', SYMBOL = '*', FONT_SIZE = fontsize, $
          TITLE = 'MinXSS-2 COMM Telemetry Read Status', $
          XTICKFORMAT = ['label_date', 'label_date'], XTICKUNITS = ['Hour', 'Day'], $ 
          YRANGE = [-10,60], YTICKNAME = ['', 'Error', 'Read', '', 'Reading', '', 'Error', ''])
p5.save, saveloc + 'Comm Read Status.png'
STOP
END