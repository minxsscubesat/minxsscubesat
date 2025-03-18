;+
; NAME:
;   minxss_plot_wheel_speed_histogram
;
; PURPOSE:
;   Plot the reaction wheel speeds as a stacked histogram
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
;   Plot of the reaction wheel speed histograms
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires MinXSS level 0c data
;
; EXAMPLE:
;   Just run it!

PRO minxss_plot_wheel_speed_histogram 

restore, '/Users/masonjp2/Dropbox/minxss_dropbox/data/fm1/level0c/minxss1_l0c_all_mission_length_v4.0.0.sav'

rad2rpm = 9.54929659643
speed1 = hk.XACT_WHEEL1MEASSPEED * rad2rpm
speed2 = hk.XACT_WHEEL2MEASSPEED * rad2rpm
speed3 = hk.XACT_WHEEL3MEASSPEED * rad2rpm


hist_speed1 = histogram(speed1, binsize=50, locations=bins1)
hist_speed2 = histogram(speed2, binsize=100, locations=bins2)
hist_speed3 = histogram(speed3, binsize=200, locations=bins3)

p1 = plot(bins1, hist_speed1, color='tomato', /HISTOGRAM, thick=2, position=[0.15, 0.70, 0.95, 0.99], $
          xshowtext=0, xrange=[-6000, 6000], $
          ytitle='#', $
          name='X')
p2 = plot(bins2, hist_speed2, color='lime green', /HISTOGRAM, thick=2, position=[0.15, 0.40, 0.95, 0.68], /CURRENT, $
          xshowtext=0, xrange=[-6000, 6000], $
          ytitle='#', $
          name='Y')
p3 = plot(bins3, hist_speed3, color='dodger blue', /HISTOGRAM, thick=2, position=[0.15, 0.1, 0.95, 0.38], /CURRENT, $
          xtitle='wheel speed [RPM]', xrange=[-6000, 6000], $
          ytitle='#', $
          name='Z')


dates = ['day', 'month']
margin = 0.15
p4 = plot(hk.time_jd, hk.XACT_WHEEL1MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'tomato', title = 'Wheel speeds [RPM]', font_size = 14, name = '1',  xtickunits = dates, margin = margin)
p5 = plot(hk.time_jd, hk.XACT_WHEEL2MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'lime green', /overplot, name = '2')
p6 = plot(hk.time_jd, hk.XACT_WHEEL3MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'dodger blue', /overplot, name = '3')
p4.yrange = [-6000, 6000]
p = plot(p4.xrange, [0, 0], '--', /OVERPLOT)



altitudes = minxss_get_altitude(timejd=hk.time_jd)
p7 = plot(altitudes, hk.XACT_WHEEL1MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'tomato', title = 'Wheel speeds [RPM]', font_size = 14, name = '1', xtitle='altitude [km]', margin = margin)
p8 = plot(altitudes, hk.XACT_WHEEL2MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'lime green', /overplot, name = '2')
p9 = plot(altitudes, hk.XACT_WHEEL3MEASSPEED * rad2rpm, symbol = '*', linestyle = 'none', 'dodger blue', /overplot, name = '3')
p7.yrange = [-6000, 6000]
p = plot(p7.xrange, [0, 0], '--', /OVERPLOT)



STOP


END