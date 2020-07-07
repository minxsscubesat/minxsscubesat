;+
; NAME:
;   minxss_make_flare_catalog
;
; PURPOSE:
;   Grab MinXSS data during (nearly?) all of the flares that ocurred during the MinXSS-1 mission
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
;   CSV file for each flare
;   CSV file report of flare timestamp, flare class, and how many MinXSS-1 data points available during the surrounding times
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   Requires access to the MinXSS-1 level 1 data
;
; EXAMPLE:
;   Just run it!
;-
PRO minxss_make_flare_catalog

; Constants
minutes_per_day = 1440.
seconds_per_minute = 60.

; Defaults
preflare_baseline_minutes = 300.
postflare_baseline_minutes = 30.
minimum_number_points = 30.
saveloc = './MinXSS Flare Catalog/'

; Load the MinXSS and GOES flare event data
restore, getenv('minxss_data') + '/fm1/level1/minxss1_l1_mission_length_v2.sav'
restore, '/Users/jmason86/Dropbox/Research/Data/GOES/events/GOES_events_MinXSS1_era.sav' ; Available here: https://www.dropbox.com/s/n4gd0t7l7kqklwa/GOES_events_MinXSS1_era.sav?dl=0

; Extract the GOES flare start times and move back 300 minutes to capture pre-flare baseline time
; Extract the GOES flare peak times, add GOES duration [seconds], and add post-flare baseline time
flare_start_jd = goesEvents.eventStartTimeJd - preflare_baseline_minutes / minutes_per_day
flare_end_jd = goesEvents.eventPeakTimeJd + ((goesEvents.duration / seconds_per_minute) + postflare_baseline_minutes) / minutes_per_day

; Extract MinXSS X123 time in JD
time_jd = minxsslevel1.x123.time.jd

; Extract MinXSS X123 energy array and find the indices for positive-only energies
energy = minxsslevel1.x123[0].energy
good_energy_indices = where(energy GT 0.009) ; First energy bin at 0.008 keV is bad

counter=0
; Loop through each GOES flare and see how many MinXSS data points are available
FOR flareIndex = 0, n_elements(flare_start_jd) - 1 DO BEGIN
  time_indices = where(time_jd GE flare_start_jd[flareIndex] AND time_jd LE flare_end_jd[flareIndex], npoints)
  IF npoints LT minimum_number_points THEN CONTINUE
  
  irradiance = minxsslevel1.x123[time_indices].irradiance[good_energy_indices]
  ;summed_irradiance = total(irradiance, 1, /NAN)
  
  ; Write to CSV
  write_array = strarr(n_elements(irradiance[0, *]), n_elements(irradiance[*, 0]) + 1)
  write_array[*, 0] = jpmjd2iso(time_jd[time_indices])
  write_array[*, 1:-1] = irradiance
  write_array = transpose(write_array)
  write_csv, saveloc + jpmjd2iso(goesEvents[flareIndex].eventPeakTimeJd) + ' ' + strtrim(goesEvents[flareIndex].st$class, 2) + '.csv', write_array, header = ['timestamp', strtrim(energy[good_energy_indices], 2)]
  
  
  ;p = plot(time_jd[time_indices], summed_irradiance, xtickunits = ['Hours'])
  ;IF flareIndex EQ 242 then STOP ; The biggest flare
  counter++
ENDFOR ; flareIndex loop

STOP

END