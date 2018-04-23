;+
; NAME:
;   minxss_plot_xact_power_vs_temperature
;
; PURPOSE:
;   Matt West at JPL asked how the XACT power consumption changes as a function of temperature. 
;   We don't have a trivial answer since MinXSS doesn't monitor XACT power consumption
;   independently. It runs off the battery voltage so it's a part of the battery voltage 
;   and battery charge/dishcharge current. 
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
;   Plot showing XACT wheel 2 temperature vs total system power consumption
;   Plot showing XACT wheel 2 temperature vs estimated XACT power consumption
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Reuiqres that the MinXSS TVAC data is processed: minxss1_l0c_all_tvac and minxss2_l0c_all_tvac
;
; EXAMPLE:
;   Just run it!
;
; MODIFICATION HISTORY:
;   2016-10-19: James Paul Mason: Wrote script.
;-
PRO minxss_plot_xact_power_vs_temperature

; Load data
restore, '/Users/' + getenv('username') + '/Dropbox/minxss_dropbox/data/fm2/level0c/minxss2_l0c_all_tvac.sav'

; Find out when the battery heater was on and mask out those data from everything
; Also filter for the other enable flags I have access to 
noHeaterIndices = where(hk.enable_batt_heater NE 1 AND hk.enable_inst_heater NE 1 $ 
                        AND hk.enable_adcs EQ 1 $ 
                        AND hk.enable_ant_deploy NE 1 AND hk.enable_sa_deploy NE 1)
hk = hk[noHeaterIndices]

; Grab relevant parameters
wheelT = hk.xact_wheel2temp ; [ºC]
battV = hk.eps_fg_volt ; [V]
battCharge = hk.eps_batt_charge / 1e3 ; [A]
battDischarge = hk.eps_batt_discharge / 1e3 ; [A]
time = minxss_packet_time_to_utc(hk.time) ; [UTC Hour]
time = time - time[0] ; [Hours since start]
timeAdcs4 = minxss_packet_time_to_utc(adcs4.time)
timeAdcs4 = timeAdcs4 - timeAdcs4[0] ; [Hours since start]

; Compute power input from solar panels
sa1Power = hk.eps_sa1_volt * hk.eps_sa1_cur / 1e3
sa2Power = hk.eps_sa2_volt * hk.eps_sa2_cur / 1e3
sa3Power = hk.eps_sa3_volt * hk.eps_sa3_cur / 1e3
saPower = sa1Power + sa2Power + sa3Power

; Compute power
powerTotal = (battDischarge * battV) > saPower ; Can only either be charging or discharging the battery at any particular time

; Compute 5V and 3V voltage line power
power5V = hk.eps_5V_volt * hk.eps_5V_cur / 1e3
power3V = hk.eps_3V_volt * hk.eps_3V_cur / 1e3

; Estimate XACT power by subtracting the 5V and 3V line powers from the total 
powerXact = powerTotal - power5V - power3V

p1 = plot(timeAdcs4, adcs4.rw2_temp, '2', MARGIN = 0.15, AXIS_STYLE = 4, $
          TITLE = 'XACT Power and Temperature', $
          XRANGE = [0, 150], $
          YRANGE = [-60, 60])
p2 = plot(time, powerXact, 'r2', MARGIN = 0.15, AXIS_STYLE = 4, /CURRENT, $ 
          XRANGE = [0, 150], $
          YRANGE = [0, 30])
p3 = plot(time, smooth(powerXact, 1000), COLOR = 'firebrick', '3', /OVERPLOT)
a1 = axis('Y', LOCATION = 'left', TITLE = 'Reaction Wheel 2 Temperature [ºC]', TARGET = p1)
a2 = axis('Y', LOCATION = 'right', TITLE = 'Estimated XACT Power [W]', TARGET = p2, COLOR = 'red')
a3 = axis('X', LOCATION = 'top', TARGET = p1, SHOWTEXT = 0)
a4 = axis('X', LOCATION = 'bottom', TITLE = 'Time [Hours]', TARGET = p1)

p4 = scatterplot(wheelT, powerXact, $
                 TITLE = 'XACT Power and Temparture', $
                 XTITLE = 'Wheel 2 Temperature [ºC]', $
                 YTITLE = 'Estimated XACT Power')

END