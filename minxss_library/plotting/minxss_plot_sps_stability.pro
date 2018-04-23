;+
; NAME:
;   minxss_plot_sps_stability
;
; PURPOSE:
;   Rick Kohnert asked for a plot to show the stability in the SPS diodes in FM-2 when dark. 
;   This was to support instrument proposal to a Goddard SMEX. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   ON_ORBIT: Set this to plot a 10 minute period of high cadence data of sps_x and sps_y
;
; OUTPUTS:
;   Plot of SPS diodes and standard deviation versus time. 
;   Same plot but with temperature trend removed. 
;
; OPTIONAL OUTPUTS:
;   None. 
;
; RESTRICTIONS:
;   Requires MinXSS IDL package. 
;
; EXAMPLE:
;   Just run it! 
;
; MODIFICATION HISTORY:
;   2016-02-26: James Paul Mason: Wrote script.
;   2016-11-27: James Paul Mason: Added ON_ORBIT keyword
;-
PRO minxss_plot_sps_stability, ON_ORBIT = ON_ORBIT

IF ~keyword_set(ON_ORBIT) THEN BEGIN 
  ; Read raw telemetry for a predetermined file
  ; This file was the largest one available for FM-2 that contained science data
  ; It corresponded to a CPT
  minxss_read_packets, getenv('minxss_data') + '/../ISIS/Rundirs/2016_042_13_03_28/tlm_packets_2016_042_13_05_52', hk = hk, sci = sci
  
  ; Data manipulation
  timeUtcHours = minxss_packet_time_to_utc(sci.time)
  timeUtcHoursHk = minxss_packet_time_to_utc(hk.time)
  diode0 = sci.sps_data[0] / sci.sps_xps_count ; this is the integration period and varies between 9 and 10 usually
  diode1 = sci.sps_data[1] / sci.sps_xps_count 
  diode2 = sci.sps_data[2] / sci.sps_xps_count
  diode3 = sci.sps_data[3] / sci.sps_xps_count
  smooth0 = smooth(diode0, 2)
  smooth1 = smooth(diode1, 2)
  smooth2 = smooth(diode2, 2)
  smooth3 = smooth(diode3, 2)
  normalized0 = diode0 / smooth0 * mean(diode0)
  normalized1 = diode1 / smooth1 * mean(diode1)
  normalized2 = diode2 / smooth2 * mean(diode2)
  normalized3 = diode3 / smooth3 * mean(diode3)
  
  ; Plot of diodes and standard deviation versus time
  w = window(DIMENSIONS = [800, 1600])
  p0 = plot(timeUtcHours, diode0, 'r2', TITLE = 'SPS Diode 0 Data With Aperture Cover On During CPT', LAYOUT = [1, 4, 1], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '0')
  p0f = plot(timeUtcHours, smooth0, '--', /OVERPLOT)
  t0 = text(20.22, p0.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(diode0)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p0)
  
  p1 = plot(timeUtcHours, diode1, 'b2', TITLE = 'Diode 1', LAYOUT = [1, 4, 2], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '1')
  p1f = plot(timeUtcHours, smooth1, '--', /OVERPLOT)
  t1 = text(20.22, p1.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(diode1)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p1)
  
  p2 = plot(timeUtcHours, diode2, 'g2', TITLE = 'Diode 2', LAYOUT = [1, 4, 3], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '2')
  p2f = plot(timeUtcHours, smooth2, '--', /OVERPLOT)
  t2 = text(20.22, p2.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(diode2)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p2)
  
  p3 = plot(timeUtcHours, diode3, COLOR = 'orange', '2', TITLE = 'Diode 3', LAYOUT = [1, 4, 4], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '3')
  p3f = plot(timeUtcHours, smooth3, '--', /OVERPLOT)
  t3 = text(20.22, p0.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(diode3)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p3)
  
  ; Plot of normalized diodes
  w = window(DIMENSIONS = [800, 1600])
  p0 = plot(timeUtcHours, normalized0, 'r2', TITLE = 'Diode0 / smooth(2pt) * mean(diode0)', LAYOUT = [1, 4, 1], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '0')
  t0 = text(20.22, p0.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(normalized0)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p0)
  
  p1 = plot(timeUtcHours, normalized1, 'b2', TITLE = 'Diode1 / smooth(2pt) * mean(diode1)', LAYOUT = [1, 4, 2], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '1')
  t1 = text(20.22, p1.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(normalized1)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p1)
  
  p2 = plot(timeUtcHours, normalized2, 'g2', TITLE = 'Diode2 / smooth(2pt) * mean(diode2)', LAYOUT = [1, 4, 3], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '2')
  t2 = text(20.22, p2.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(normalized2)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p2)
  
  p3 = plot(timeUtcHours, normalized3, COLOR = 'orange', '2', TITLE = 'Diode3 / smooth(2pt) * mean(diode3)', LAYOUT = [1, 4, 4], /CURRENT, $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Signal [counts/s]', $
            NAME = '3')
  t3 = text(20.22, p3.yrange[1], '$\sigma = $' + JPMPrintNumber(stddev(normalized3)), /DATA, VERTICAL_ALIGNMENT = 1, TARGET = p3)
  
  ; Plot temperature
  p4 = plot(timeUtcHoursHk, hk.sps_xps_temp, '2', TITLE = 'Temperatures During CPT', $
            XTITLE = 'UTC Time [Hour]', XRANGE = [20.2, 21.0], $
            YTITLE = 'Temperature [ºC]', $
            NAME = 'SPS Detector')
  p5 = plot(timeUtcHoursHk, hk.mb_temp1, COLOR = 'purple', '2', /OVERPLOT, $
            NAME = 'Motherboard')
  l = legend(TARGET = [p4, p5], POSITION = [0.92, 0.86])
ENDIF ELSE BEGIN; ON_ORBIT keyword not set else it is

  ; Restore the MinXSS-1 on orbit data
  restore, getenv('minxss_data') + '/fm1/level0c/minxss1_l0c_all_mission_length.sav'
  
  ; Grab the day with the most hk points as determined by minxss_determine_highest_density_data_coverage
  ; Corresponds to date 2016-09-22
  mostDataIndices = where(floor(hk.time_jd - 0.5) EQ 2457653.0 AND hk.sps_x NE 0)
  hk = hk[mostDataIndices]
  
  ; Convert sun angle to degrees
  sps_x = hk.sps_x / 10000. * 3.0
  sps_y = hk.sps_y / 10000. * 3.0
  
  p1 = plot(hk.time_jd, sps_x, 'g2*-', $ 
           TITLE = 'MinXSS-1 Orbit Sun Position Sensor Data', $
           XTITLE = 'Hour on 2016-09-22', XTICKUNITS = 'Hours', XMAJOR = 9, $
           YTITLE = 'Sun Position [º]', $ 
           NAME = 'Horizontal')
  p2 = plot(hk.time_jd, sps_y, 'b2*-', /OVERPLOT, $
            NAME = 'Vertical')
  l1 = legend(TARGET = [p1, p2], POSITION = [0.36, 0.83])
           

STOP

ENDELSE
END