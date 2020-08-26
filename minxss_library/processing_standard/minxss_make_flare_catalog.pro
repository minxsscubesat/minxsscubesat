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
saveloc = getenv('minxss_data') + 'fm1/minxss_flare_catalog/'

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

; Prepare structure to hold statistics/listing of all flares
catalog_struct = {time_goes_start:'', time_goes_peak:'', time_goes_end:'', time_minxss_start:'', time_minxss_end:'', flare_class:'', number_data_points_within_goes_start_end:0L, number_data_points_all:0L}

counter=0
; Loop through each GOES flare and see how many MinXSS data points are available
FOR flare_index = 0, n_elements(flare_start_jd) - 1 DO BEGIN
  time_indices = where(time_jd GE flare_start_jd[flare_index] AND time_jd LE flare_end_jd[flare_index], npoints)
  IF npoints LT minimum_number_points THEN CONTINUE
  
  irradiance = minxsslevel1.x123[time_indices].irradiance[good_energy_indices]
  
  ; Count how many MinXSS data points just within the GOES start/end times, for reference
  tmp = where(time_jd GE goesEvents[flare_index].eventStartTimeJd AND time_jd LE (goesEvents[flare_index].eventPeakTimeJd + (goesEvents[flare_index].duration / seconds_per_minute) / minutes_per_day), npoints_within_goes)
  
  ; Write to disk
  minxss_flare = strarr(n_elements(irradiance[*, 0]) + 1, n_elements(irradiance[0, *]))
  minxss_flare[0, *] = jpmjd2iso(time_jd[time_indices])
  minxss_flare[1:-1, *] = irradiance
  write_csv, saveloc + 'CSV/' + jpmjd2iso(goesEvents[flare_index].eventPeakTimeJd) + ' ' + strtrim(goesEvents[flare_index].st$class, 2) + '.csv', minxss_flare, header = ['timestamp', strtrim(energy[good_energy_indices], 2)]
  save, minxss_flare, filename = saveloc + 'IDL Savesets/' + jpmjd2iso(goesEvents[flare_index].eventPeakTimeJd) + ' ' + strtrim(goesEvents[flare_index].st$class, 2) + '.sav'
  
  ; Add to catalog listing
  catalog_struct.time_goes_start = jpmjd2iso(goesEvents[flare_index].eventStartTimeJd)
  catalog_struct.time_goes_peak = jpmjd2iso(goesEvents[flare_index].eventPeakTimeJd)
  catalog_struct.time_goes_end = jpmjd2iso(goesEvents[flare_index].eventPeakTimeJd + (goesEvents[flare_index].duration / seconds_per_minute) / minutes_per_day)
  catalog_struct.time_minxss_start = jpmjd2iso(time_jd[time_indices[0]])
  catalog_struct.time_minxss_end = jpmjd2iso(time_jd[time_indices[-1]])
  catalog_struct.flare_class = strtrim(goesEvents[flare_index].st$class, 2)
  catalog_struct.number_data_points_all = npoints
  catalog_struct.number_data_points_within_goes_start_end = npoints_within_goes
  IF counter GT 0 THEN BEGIN
    catalog = [catalog, catalog_struct]
    catalog[counter] = catalog_struct  
  ENDIF ELSE catalog = catalog_struct
  
  ;p = plot(time_jd[time_indices], summed_irradiance, xtickunits = ['Hours'])
  ;IF flare_index EQ 242 then STOP ; The biggest flare
  counter++
ENDFOR ; flare_index loop

write_csv, saveloc + 'CSV/MinXSS Flare Catalog.csv', catalog, header = ['Time GOES Start', 'Time GOES Peak', 'Time GOES End', 'Time MinXSS Start', 'Time MinXSS End', 'Flare Class', 'Number MinXSS Datapoints Within GOES Start-End Time', 'Number MinXSS Datapoints All']
save, catalog, filename = saveloc + 'IDL Savesets/MinXSS Flare Catalog.sav'

END