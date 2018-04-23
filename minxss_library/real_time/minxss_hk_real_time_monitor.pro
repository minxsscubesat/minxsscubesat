;+
; NAME:
;   minxss_hk_real_time_monitor
;
; PURPOSE:
;   Monitor critical housekeeping data and send an email to the chosen recipient if anything falls out of range. 
;   It's ideal to setup a text message alert on emails from here e.g., http://techawakening.org/free-sms-alerts-new-email-on-gmail-with-google-docs/1130/
;   They will always have the subject line: 'MinXSS CubeSat HK Alert'. 
;
; INPUTS:
;   hk [structure]: Housekeeping data from minxss_read_packets in the standard structure format. 
;
; OPTIONAL INPUTS:
;   emailAddress [string]: Optionally input your email address. Defaults to James Paul Mason -- jmason86@gmail.com
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Email message if housekeeping telemetry falls out of range
;
; OPTIONAL OUTPUTS:
;   None
;   
; RESTRICTIONS:
;   Requires JPMPrintNumber
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2015/01/20: James Paul Mason: Wrote script.
;-
PRO minxss_hk_real_time_monitor, hk, emailAddress = emailAddress

; Defaults
IF ~keyword_set(emailAddress) THEN emailAddress = 'jmason86@gmail.com'

IF hk.CDH_TEMP LE -25.0 OR hk.CDH_TEMP GE 75.0 THEN emailBody = 'CDH temperature at ' + JPMPrintNumber(hk.CDH_TEMP) + ' ºC'
IF hk.COMM_TEMP LE -25.0 OR hk.COMM_TEMP GE 75.0 THEN emailBody = 'COMM temperature at' + JPMPrintNumber(hk.COMM_TEMP) + ' ºC'
IF hk.RADIO_TEMP LE -25.0 OR hk.RADIO_TEMP GE 60.0 THEN emailBody = 'COMM temperature at' + JPMPrintNumber(hk.COMM_TEMP) + ' ºC'
IF hk.EPS_3V_CUR LE 115.0 OR hk.EPS_3V_CUR GE 235.0 THEN emailBody = 'EPS 3V current at' + JPMPrintNumber(hk.EPS_3V_CUR) + ' mA'
IF hk.EPS_5V_CUR LE -5.0 OR hk.EPS_5V_CUR GE 950.0 THEN emailBody = 'EPS 5V current at' + JPMPrintNumber(hk.EPS_5V_CUR) + ' mA'
IF hk.EPS_BATT_CHARGE LE -50.0 OR hk.EPS_BATT_CHARGE GE 3200.0 THEN emailBody = 'EPS battery charge at ' + JPMPrintNumber(hk.EPS_BATT_CHARGE) + ' mA'
IF hk.EPS_BATT_DISCHARGE LE -25.0 OR hk.EPS_BATT_DISCHARGE GE 3300.0 THEN emailBody = 'EPS battery discharge at ' + JPMPrintNumber(hk.EPS_BATT_DISCHARGE) + ' mA'
;IF hk.EPS_BATT_TEMP1 LE 2.0 OR hk.EPS_BATT_TEMP1 GE 38.0 THEN emailBody = 'Battery temperature at ' + JPMPrintNumber(hk.EPS_BATT_TEMP1) + ' ºC'
;IF hk.EPS_BATT_TEMP2 LE 2.0 OR hk.EPS_BATT_TEMP2 GE 38.0 THEN emailBody = 'Battery temperature at ' + JPMPrintNumber(hk.EPS_BATT_TEMP2) + ' ºC'
IF hk.EPS_FG_VOLT LE 6.85 OR hk.EPS_FG_VOLT GE 8.38 THEN emailBody = 'EPS battery voltage at ' + JPMPrintNumber(hk.EPS_FG_VOLT) + ' V'
IF hk.EPS_TEMP1 LE -25.0 OR hk.EPS_TEMP1 GE 75.0 THEN emailBody = 'EPS temperature at ' + JPMPrintNumber(hk.EPS_TEMP1) + ' ºC'
IF hk.EPS_TEMP2 LE -25.0 OR hk.EPS_TEMP2 GE 75.0 THEN emailBody = 'EPS temperature at ' + JPMPrintNumber(hk.EPS_TEMP2) + ' ºC'
IF hk.MB_TEMP1 LE -25.0 OR hk.MB_TEMP1 GE 75.0 THEN emailBody = 'Motherboard temperature at ' + JPMPrintNumber(hk.MB_TEMP1) + ' ºC'
IF hk.MB_TEMP2 LE -25.0 OR hk.MB_TEMP2 GE 75.0 THEN emailBody = 'Motherboard temperature at ' + JPMPrintNumber(hk.MB_TEMP2) + ' ºC'
IF hk.X123_BRD_TEMP LE -25.0 OR hk.X123_BRD_TEMP GE 75.0 THEN emailBody = 'X123 board temperature at ' + JPMPrintNumber(hk.X123_BRD_TEMP) + ' ºC'
IF hk.X123_DET_TEMP NE 0.0 AND hk.X123_DET_TEMP LE 220.0 OR hk.X123_DET_TEMP GE 240.0 THEN emailBody = 'X123 detector temperature at ' + JPMPrintNumber(hk.X123_DET_TEMP) + ' ºC'
;IF hk.XACT_WHEEL2TEMP LE -18.0 OR hk.XACT_WHEEL2TEMP GE 58.0 THEN emailBody = 'XACT wheel temperature at ' + JPMPrintNumber(hk.XACT_WHEEL2TEMP) + ' ºC'

IF emailBody NE !NULL THEN BEGIN
  spawn, 'echo ' + emailBody + ' | mailx -s "MinXSS CubeSat HK Alert" ' + emailAddress
  print, 'MinXSS CubeSat HK Alert: ' + emailBody
ENDIF

END