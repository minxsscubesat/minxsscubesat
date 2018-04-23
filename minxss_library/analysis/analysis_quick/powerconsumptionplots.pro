;+
; NAME:
;   PowerConsumptionPlots
;
; PURPOSE:
;   Quick analysis for determining power consumption in eclipse for MinXSS based on 100-hour mission simulation testing 
;   done in 2015/08/19-23. We discovered we were power negative when only 5 solar cells are illuminated (not derated
;   for high temperature), while in safe mode with all 3 reaction wheels running at ~300 rad/s, and the maximum eclipse
;   being used in the solar array simulator (36 min eclipse, 56 min insolation). 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   DO_PLOTS: Set this to produce plots of current, voltage, and power
;
; OUTPUTS:
;   Average current, voltage, and power, and optionally plots. 
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires JPMPrintNumber
;
; EXAMPLE:
;   Just run it, hard code to play around
;
; MODIFICATION HISTORY:
;   2015/08/21: James Paul Mason: Wrote script.
;-
PRO PowerConsumptionPlots, DO_PLOTS = DO_PLOTS

; Restore the data taken overnight with the configuration described in the purpose above
restore, '/Users/jmason86/Drive/CubeSat/MinXSS Server/9000 Processing/data/level0b/minxss_l0b_2015_233.sav'

; Convert to UTC time
packet = hk
packet_time_yd = jd2yd(gps2jd(packet.time))
time1 = min(packet_time_yd)
time2 = max(packet_time_yd)
time_date = long(time1)
time_year = long(time_date / 1000.)
time_doy = time_date mod 1000L
time_date_str = strtrim(time_year,2) + '_'
doy_str = strtrim(time_doy,2)
yd_base = time_year * 1000L + time_doy
ptime = (packet_time_yd - yd_base)*24.  

; Determine which indices to zoom in on for eclipse - HARD CODE THIS GROUP OF CODE
p = plot(hk.EPS_FG_VOLT)
STOP
eclipseRange = [202:251] ; results in average power consumption of 5.86 W, 7.74 V, 0.75 A
eclipseRange = [374:424] ; results in average power consumption of 5.76 W, 7.50 V, 0.76 A
eclipseRange = [561:620] ; results in average power consumption of 5.75 W, 7.33 V, 0.78 A
eclipseRange = [734:793] ; results in average power consumption of 5.82 W, 7.14 V, 0.81 A
eclipseRange = [911:930] ; results in average power consumption of 5.82 W, 6.93 V, 0.84 A

; From the comments above, know that power consumption is mostly independent of battery voltage
; So plot it to prove it
IF keyword_set(DO_PLOTS) THEN BEGIN
  averagePowers = [5.86, 5.76, 5.75, 5.82, 5.82]
  averageVoltages = [7.74, 7.5, 7.33, 7.14, 6.93]
  averageCurrents = [0.75, 0.76, 0.78, 0.81, 0.84]
  p0 = plot(averageVoltages, averagePowers, 'b2', TITLE = 'Power Consumption Over Multiple Eclipses - Safe Mode, 5-cell full power, RWs to ~300 rad/s, max eclipse time', $
            MARGIN = 0.1, $
            XTITLE = 'Battery Voltage [V]', $
            YTITLE = 'Power Consumption [W]', YRANGE = [5.6, 6])
  ax0 = p0.axes
  ax0[0].COLOR = 'blue'
  p01 = plot(averageCurrents, averagePowers, 'r2', /CURRENT, MARGIN = 0.1, AXIS_STYLE = 4, $
             YRANGE = [5.6, 6])
  ax1 = axis('X', LOCATION = 'top', TARGET = [p01], TITLE = 'Discharge Current [A]', COLOR = 'red')
ENDIF

; Define subarrays on eclipse period - Time
timeEclipse = ptime[eclipserange]

; Define subarrays on eclipse period and take average of the power data - Current
dischargeCurrentEclipse = hk[eclipseRange].EPS_BATT_DISCHARGE * 1E-3 ; Converted to SI [A]
averageDischargeCurrentEclipse = mean(dischargecurrenteclipse)
print, 'Average Discharge Current: ' + JPMPrintNumber(averageDischargeCurrentEclipse) + ' A'

; Define subarrays on eclipse period and take average of the power data - Voltage
batteryVoltageEclipse = hk[eclipseRange].EPS_FG_VOLT
averageBatteryVoltageEclipse = mean(batteryvoltageeclipse)
print, 'Average Battery Voltage: ' + JPMPrintNumber(averageBatteryVoltageEclipse) + ' V'

; Compute power in eclipse
powerEclipse = dischargecurrenteclipse * batteryvoltageeclipse
averagePowerEclipse = averagebatteryvoltageeclipse * averagedischargecurrenteclipse
print, 'Average Power: ' + JPMPrintNumber(averagePowerEclipse) + ' W'

IF keyword_set(DO_PLOTS) THEN BEGIN
  ; Create plots
  p = plot(timeEclipse, powerEclipse, '2', TITLE = 'Power Data in Eclipse - Safe Mode, 5-cell full power, RWs to ~300 rad/s, max eclipse time', $
           xtitle = 'UTC Time [Hour]', $
           ytitle = 'Power [W]', $
           NAME = 'Power')
  p2 = plot(timeEclipse, batteryvoltageeclipse, 'b2', TITLE = 'Battery Voltage Data in Eclipse - Safe Mode, 5-cell full power, RWs to ~300 rad/s, max eclipse time', $
            xtitle = 'UTC Time [Hour]', $
            ytitle = 'Battery Voltage [V]', $
            NAME = 'Battery Voltage')
  p3 = plot(timeEclipse, dischargecurrenteclipse, 'r2', TITLE = 'Discharge Current Data in Eclipse - Safe Mode, 5-cell full power, RWs to ~300 rad/s, max eclipse time', $
            xtitle = 'UTC Time [Hour]', $
            ytitle = 'Discharge Current [A]', $
            NAME = 'Discharge Current')
  t = text(0.2, 0.2, 'Average Value = ' + JPMPrintNumber(averagepowereclipse) + ' W', TARGET=[p], FONT_SIZE = 16)
  t.position = [0.22,0.18]
  t2 = text(0.1, 0.15, 'Average Value = ' + JPMPrintNumber(averagebatteryvoltageeclipse) + ' V', TARGET = [p2], font_size = 16)
  t2.position = [0.24, 0.18]
  t2.color = 'b'
  t3 = text(0.15, 0.15, 'Average Value = ' + JPMPrintNumber(averagedischargecurrenteclipse) + ' A', TARGET = [p3], font_size = 16)
  t3.position = [0.25, 0.16]
  t3.color = 'r'
ENDIF

STOP
save, filename = 'Power Data in Eclipse Safe Mode 5 Cell Full Power RWs to 300 radps max eclipse time.sav'

END
