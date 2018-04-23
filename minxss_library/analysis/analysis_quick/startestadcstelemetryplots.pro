;+
; NAME:
;   StarTestAdcsTelemetryPlots
;
; PURPOSE:
;   Create plots of various ADCS telemetry points for the outdoor fine point star test. 
;
; INPUTS:
;   None
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   Plots of various telemetry points
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2015/08/27: James Paul Mason: Wrote script.
;-
PRO StarTestAdcsTelemetryPlots

; Setup
;saveloc = '/Users/jama6159/Drive/CubeSat/MinXSS Server/0000 Images/Outdoor Star Field Test/Attempt 4 - Fine Point - Mostly Success/'
saveloc = '/Users/jama6159/Drive/CubeSat/MinXSS Server/0000 Images/Outdoor Star Field Test/Attempt 5 - Fine Point - Mostly Success/'

; Restore the star test data from the test performed on 2015/07/17
;restore, '/Users/jama6159/Drive/CubeSat/MinXSS Server/9000 Processing/data/level0b/minxss_l0b_2015_199.sav' ; First Star Test - 5 second real time data
restore, '/Users/jama6159/Drive/CubeSat/MinXSS Server/9000 Processing/data/level0b/minxss_l0b_2015_244_StarTest.sav' ; Second Star Test - 5 second real time data

; Hard code timerange
XRANGE = [6.40, 6.46]
xrange = [2.4, 2.9]

; Conversions
rad2rpm = 9.54929659643
rad2deg = 57.2957795

; Make the wheels plot
timeUtcHours = minxss_packet_time_to_utc(adcs2.time)
STOP
p1 = plot(timeUtcHours, adcs2.WHEEL_MEAS_SPEED1 * rad2rpm, 'r2', TITLE = 'Reaction Wheels During Fine-Point Star Test', $
          XTITLE = 'UTC Time [Hour]', XRANGE = xrange, $
          YTITLE = 'Wheel Speed [RPM]', $
          NAME = 'Wheel1')
p2 = plot(timeUtcHours, adcs2.WHEEL_MEAS_SPEED2 * rad2rpm, 'g2', /OVERPLOT, $
          NAME = 'Wheel2')
p3 = plot(timeUtcHours, adcs2.WHEEL_MEAS_SPEED3 * rad2rpm, 'b2', /OVERPLOT, $
          NAME = 'Wheel3')
l1 = legend(TARGET = [p1, p2, p3], POSITION = [0.31, 0.88])
p1.save, saveloc + 'Wheel Speeds.png'

; Make star tracker plot
timeUtcHours = minxss_packet_time_to_utc(adcs3.time)
p4 = plot(timeUtcHours, adcs3.NUM_STARS_USED_IN_ATTITUDE, '10', TITLE = 'Tracked Star Statistics During Fine-Point Star Test', $
          XTITLE = 'UTC Time [Hour]', XRANGE = xrange, $
          YTITLE = 'Number Count', $
          NAME = 'Stars Used in Attitude')
p5 = plot(timeUtcHours, adcs3.NUM_STARS_ON_FOV, 'r2', /OVERPLOT, $
          NAME = 'Stars on FOV')
p6 = plot(timeUtcHours, adcs3.NUM_TRACKED_STARS, 'g2', /OVERPLOT, $
          NAME = 'Tracked Stars')
p7 = plot(timeUtcHours, adcs3.NUM_ID_STARS, 'b2', /OVERPLOT, $
          NAME = 'ID Stars')
p8 = plot(timeUtcHours, adcs3.NUM_BRIGHT_STARS, '2', COLOR = 'orange', /OVERPLOT, $
          NAME = 'Bright Stars')
l2 = legend(TARGET = [p4, p5, p6, p7, p8], POSITION = [0.92, 0.88])
p4.save, saveloc + 'Star Statistics Full.png'
p4.yrange = [0, 25]
p4.save, saveloc + 'Star Statistics Zoomed.png'


; Make mode plot
timeUtcHours = minxss_packet_time_to_utc(adcs2.time)
p9 = plot(timeUtcHours, adcs2.adcs_mode, 'r10', TITLE = 'ADCS Mode During Fine-Point Star Test', $
          XTITLE = 'UTC Time [Hour]', $
          YTITLE = 'ADCS Mode', YTICKNAME = ['Sun Point', 'Fine Point']) ; ; 0=sun_point, 1 = fine_point
p9.save, saveloc + 'ADCS Mode.png'

; Make attitude error (integral error) plot
timeUtcHours = minxss_packet_time_to_utc(adcs3.time)
p10 = plot(timeUtcHours, adcs3.INTEGRAL_ERROR1 * rad2deg, 'r2', TITLE = 'Attitude Integral Error During Fine-Point Star Test', $
           XTITLE = 'UTC Time [Hour]', XRANGE = xrange, $
           YTITLE = 'Attitude Integral Error [º]', $
           NAME = '1')
p11 = plot(timeUtcHours, adcs3.INTEGRAL_ERROR2 * rad2deg, 'g2', /OVERPLOT, $
           NAME = '2')
p12 = plot(timeUtcHours, adcs3.INTEGRAL_ERROR3 * rad2deg, 'b2', /OVERPLOT, $
           NAME = '3')
l3 = legend(TARGET = [p10, p11, p12], POSITION = [0.24, 0.88])
p10.save, saveloc + 'Attitude Integral Error.png'

; Make system momentum plot
timeUtcHours = minxss_packet_time_to_utc(adcs3.time)
totalMomentum = sqrt(adcs3.SYSTEM_MOMENTUM1^2 + adcs3.SYSTEM_MOMENTUM2^2 + adcs3.SYSTEM_MOMENTUM3^2)
p13 = plot(timeUtcHours, adcs3.SYSTEM_MOMENTUM1, 'r2', TITLE = 'System Momentum During Fine-Point Star Test', MARGIN = 0.1, DIMENSIONS = [800, 600], AXIS_STYLE = 4, $
           XRANGE = xrange, $
           NAME = '1')
p14 = plot(timeUtcHours, adcs3.SYSTEM_MOMENTUM2, 'g2', /OVERPLOT, $
           NAME = '2')
p15 = plot(timeUtcHours, adcs3.SYSTEM_MOMENTUM3, 'b2', /OVERPLOT, $
           NAME = '3')
p16 = plot(timeUtcHours, totalMomentum, '2', COLOR = 'orange', /CURRENT, MARGIN = 0.1, AXIS_STYLE = 4, $
           XRANGE = p13.XRANGE, $
           YRANGE = [-0.2, 0.06], $
           NAME = 'Total')
ax13y = axis('Y', LOCATION = 'left', TARGET = [p13], TITLE = 'System Momentum [Nms]')
ax13xb = axis('X', LOCATION = 'bottom', TARGET = [p13], TITLE = 'UTC Time [Hour]')
ax13xt = axis('X', LOCATION = 'top', TARGET = [p13], TEXT_COLOR = 'white')
p17 = plot(p16.XRANGE, [0.011, 0.011], '2--', COLOR = 'orange', /OVERPLOT, $
           NAME = 'Wheel Cutoff')
ax16 = axis('Y', LOCATION = 'right', TARGET = [p16], TITLE = 'Total Momentum [Nms]', COLOR = 'orange')
l4 = legend(TARGET = [p13, p14, p15, p16, p17], POSITION = [0.3, 0.29])
p13.save, saveloc + 'System Momentum.png'

; Make wheel control mode plot
timeUtcHours = minxss_packet_time_to_utc(adcs2.time)
p18 = plot(timeUtcHours, adcs2.WHEEL_CONTROL_MODE1, 'r10', TITLE = 'Wheel Control Mode During Fine-Point Star Test', $
           XTITLE = 'UTC Time [Hour]', XRANGE = xrange, $
           YTITLE = 'Wheel Control Mode', YTICKNAME = ['TRQ', 'SPD', 'PWM'], $ ; 0=TRQ,1=SPD,2=PWM
           NAME = 'Wheel1')
p19 = plot(timeUtcHours, adcs2.WHEEL_CONTROL_MODE2, 'g6', /OVERPLOT, $
           NAME = 'Wheel2')
p20 = plot(timeUtcHours, adcs2.WHEEL_CONTROL_MODE3, 'b2', /OVERPLOT, $
           NAME = 'Wheel3')
l5 = legend(TARGET = [p18, p19, p20], POSITION = [0.3, 0.29])
p18.save, saveloc + 'Wheel Control Modes.png'

END