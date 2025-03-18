;+
; H+
;	TITLE	: prioritize_pass_overlap
;
; 	Author	: Karen Bryant
; 	Date	: 10/01/21
;
;	$Date: 2022/11/30 22:06:06 $
;	$Source: /home/bershenyi/cubesats/scheduling/RCS/prioritize_pass_overlap.pro,v $
;  @(#)	$Revision: 1.7 $
;	$Name:  $
;	$Locker: bershenyi $
;
;	PURPOSE:
;	Check for pass overlaps for multiple Cubesat missions
;
;	CATEGORY:
;	Utility
;
;	CALLING SEQUENCE:
;	
;
;	INPUT PARAMETERS:
;	
;
;	OPTIONAL KEYWORD PARAMETERS:
;
;	OUTPUT PARAMETERS:
;	
;
;	COMMON BLOCKS:
;	
;
;	PROCEDURE:
;	
;
;	LIMITATIONS/ASSUMPTIONS:
;	
;
;-
;	MODIFICATIONS/REVISION LEVEL:
;	MM/DD/YY WHO	WHAT (most recent change first)
;
; H-
;------------------------------------------------------------------------------

PRO count_pass_spacecraft,passes
n_passes = n_elements(passes)
for i = 0l, n_passes-1 do begin
    ; On the first index, initialize variables
    if i eq 0 then begin
        counts = 1
        names = passes[i].satellite_name
    endif else begin
    ; On subsequent indices, search and possibly append
        n_names = n_elements(names)
        new_name = 1; True
        for j = 0, n_names-1 do begin
            if names[j] eq passes[i].satellite_name then begin
                new_name = 0; False
                counts[j] = counts[j] + 1
            endif
        endfor
        ; If the satellite_name doesn't match, then it must be new, 
        ; so append it to the list of names
        if new_name then begin
            counts = [counts, 1]
            names = [names, passes[i].satellite_name]
        endif
    endelse 
endfor
print,'      Total: ',n_passes
n_names = n_elements(names)
for j = 0, n_names-1 do begin
    print,'      ',names[j],': ',counts[j]
endfor
print,''

END

; Program: Judge_Victors
; Inputs:  passes - IDL structure for pass schedule
;          score - vector of all pass scores
;          overlap_inds - index vector of the first pass of 
;                         each overlapping pair
;          priority_in - Input of priority vector
; Outputs: winners - absolute index vector of winners w/in overlapping pairs
;          losers  - absolute index vector of losers w/in overlapping
;                    pairs
;          priority_out - Output of priority vector
; Assumptions: 
PRO judge_victors, passes, score, overlap_inds, priority_in,  $
                   winners, losers, priority_out, $
                   debug=debug

; Copy priority input to output
priority_out = priority_in

; score_gap
overlap_inds_plus1 = overlap_inds + 1
score_gap = score[overlap_inds] - score[overlap_inds_plus1]
; Declare winners and losers
first_is_best_inds = where(score_gap ge 0, n_first_is_best)
if n_first_is_best gt 0 then begin
    ; Winners is a vector of the absolute indices of winning passes
    ; where overlap exists
    winners = overlap_inds_plus1
    winners[first_is_best_inds] = overlap_inds[first_is_best_inds]
    ; Losers is a vector of abs indices of passes we probably
    ; want to skip
    losers = overlap_inds
    losers[first_is_best_inds] = overlap_inds_plus1[first_is_best_inds]
endif else begin           ; Otherwise, the second pass won every time
    losers = overlap_inds       ; First is the worst
    winners = overlap_inds_plus1 ; Second is the best
endelse


if keyword_set(debug) then begin
; Print priority among overlapping counts
   print,"------ Winners among Overlapping Pass Counts ------"
   winner_passes = passes[winners]
   count_pass_spacecraft,winner_passes

; Print filtered counts
   print,"------ Filtered Pass Counts ------"
   full_inds = intarr(n_elements(passes))
   full_inds[losers] = 1
   keep_inds = where(full_inds ne 1)
   filtered_passes = passes[keep_inds]
   count_pass_spacecraft,filtered_passes
endif
    
; Modify pass priority list
; 0 - Delete (b/c conflict)
; 1 - Keep (no conflict)
; 2 - Keep (prioritize)
; Initialize list if it doesn't already exist
priority_out[losers] = 0
priority_out[winners] = 2

END


; Program: Rotate Priority
; Inputs:  passes - IDL structure for pass schedule
;          mission_hash - Hash of mission names and priority scores
; Outputs: score - vector of all pass scores
; Assumptions: 
; Description: Rotate which mission gets priority starting at sunset
; each day. Ignore some missions according to mission_hash.
PRO rotate_priority, passes, mission_hash, score, debug

; Find the number of missions that get rotating priority (prio value = 1)
top_missions = mission_hash.where(1)
n_top_missions = n_elements(top_missions)
n_passes = n_elements(passes)
mission_assignments = intarr(n_passes)
n_days = floor(passes[-1].start_jd - passes[0].start_jd)

; Find sunsets
sunlight_deltas = passes.sunlight - shift(passes.sunlight,1)
sunset_inds = where(sunlight_deltas eq -1, n_sunsets)
; Eliminate the fake sunset at the beginning
if sunset_inds[0] eq 0 and n_sunsets ge 1 then begin
   n_sunsets = n_sunsets - 1
   sunset_inds = sunset_inds[1:-1]
endif
; There are no passes in eclipse for about two months in the summer!
; AND they are spotty before and after this absence
if n_sunsets lt n_days then begin
   
   if keyword_set(debug) then begin
      print,"Days:",n_days,"  Sunsets:",n_sunsets
      print,sunset_inds
      print,passes[0].start_jd,passes[-1].start_jd
      ;print,time_since_sunset/3600
      print,passes[sunset_inds].start_time/3600
   endif
   
   ; If we suspect spotty sunsets, just set sunset time at 05:00:00 UTC
   sunset_time_s = 5*3600       ; 05:00:00
   one_day_s = 24*3600l
   time_since_sunset = passes.start_time - sunset_time_s
   temp_time_since_sunset = time_since_sunset
   ; Fix negative times since sunset
   negative_inds = where(time_since_sunset lt 0, n_negative_inds)
   if n_negative_inds gt 0 then begin
      time_since_sunset[negative_inds] = time_since_sunset[negative_inds] + $
                                        one_day_s
   endif       ; Else IDK! That will probably never happen with a full schedule
   ; Use shift method to find when time_since_sunset crosses 0
   sunlight_deltas = time_since_sunset - shift(time_since_sunset,1)
   sunset_inds = where(sunlight_deltas lt 0, n_sunsets)
   ; Eliminate the fake sunset at the beginning
   if sunset_inds[0] eq 0 and n_sunsets ge 1 then begin
      n_sunsets = n_sunsets - 1
      sunset_inds = sunset_inds[1:-1]
   endif
   
   if keyword_set(debug) then begin
      print,"Days:",n_days,"  Sunsets:",n_sunsets
      print,sunset_inds
      print,passes[0].start_jd,passes[-1].start_jd
      ;for j = 0, n_passes - 1 do begin
      ;   print,j,passes[j].start_time/3600,$
      ;         temp_time_since_sunset[j]/3600,$
      ;          time_since_sunset[j]/3600,$
      ;          sunlight_deltas[j]/3600,format='(F,F,F,F,F)'
      ;endfor
      ;stop
   endif
endif

; Only work hard if sunsets exist
if n_sunsets gt 0 then begin
   ; Assign days based on modulo of JD
   sunset_ind_assignments = floor(passes[sunset_inds].start_jd mod $
                                  n_top_missions)
   ; Now spread those assignments to the other indices
   for sunset = 0, n_sunsets - 1 do begin
      ; For the first one, use the first sunset day -1
      if sunset eq 0 then begin
         first_assignment = floor((passes[sunset_inds[0]].start_jd - 1) mod $
                                  n_top_missions)
         mission_assignments[0:sunset_inds[sunset]-1] = first_assignment
      endif
      ; For middle sunsets, spread up to the next sunset
      if sunset lt n_sunsets - 1 then begin ; Middle
         mission_assignments[sunset_inds[sunset]:sunset_inds[sunset+1]-1] = $
            sunset_ind_assignments[sunset]
      ; For the last sunset, spread to the end
      endif else begin          ; Last sunset
         mission_assignments[sunset_inds[sunset]:-1] = $
            sunset_ind_assignments[sunset]
      endelse
      
   endfor
endif else begin     ; In this case, there are 1 or 0 sunsets
   ; Otherwise, just take the modulo of the first pass JD
   mission_assignments = floor(passes[0].start_jd mod $
                               n_top_missions)
endelse

; Now turn the assignments into scores. Add 100 points to the
; assignee, and 10 points just for being in the top mission club
score = fltarr(n_passes)
for mission = 0, n_top_missions - 1 do begin
   ; Compare the satellite name in passes to the mission name AND
   ; the assigned mission for each day
   this_mission_assignments = where((passes.satellite_name eq $
                                    top_missions[mission]) AND $
                                    (mission_assignments eq mission),$
                             n_this_mission_assignments)
   if n_this_mission_assignments gt 0 then begin
      score[this_mission_assignments] = 100
   endif
   this_mission_off_days = where((passes.satellite_name eq $
                                    top_missions[mission]) AND $
                                    (mission_assignments ne mission),$
                             n_this_mission_off_days)
   if n_this_mission_off_days gt 0 then begin
      score[this_mission_off_days] = 10
   endif
endfor

; if keyword_set(debug) then stop

END



; Program: Coronate_Mission
; Inputs:  passes - IDL structure for pass schedule
;          mission_hash - Hash of mission names and priority scores
;          score_in - Input of score vector
; Outputs: score_out - Output of modified score vector
; Assumptions: Only one can wear the crown
; Description: Use mission_hash to oronate the highest priority
;          mission with a "crown" of 1000 points in the score
PRO coronate_mission, passes, mission_hash, score_in, score_out, debug=debug

; Copy score in to out
score_out = score_in

; Find royal mission (prio value = 2)
royal_missions = mission_hash.where(2)

n_royal_missions = n_elements(royal_missions)
if n_royal_missions gt 1 then begin
   print,"/!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\"
   print,"WARNING: More than 1 mission marked priority level 2 (highest)"
   print,"         Only prioritizing ",royal_missions[0]
   print,"/!\ /!\ /!\ /!\ /!\ /!\ /!\ /!\"
   ; score_out = ; How can we break this in an obvious way?
   return
endif
if n_royal_missions eq 1 then begin
   royal_mission = royal_missions[0]
   royal_inds = where(passes.satellite_name eq royal_mission,n_royal_inds)
      if n_royal_inds gt 0 then begin
      ; 1000 should be 10x any other score
      score_out[royal_inds] = score_in[royal_inds] + 1000
   endif
endif

END

; Program: Delete_Mission
; Inputs:  passes - IDL structure for pass schedule
;          mission_hash - Hash of mission names and priority scores
;          priority_in - Input of priority vector
; Outputs: priority_out - Output of modified priority vector
; Assumptions: 
; Description: Use mission_hash to determine whether all passes for a 
; specific spacecraft should be marked 'Delete'
PRO delete_mission, passes, mission_hash, priority_in, priority_out
; Copy priority in to out
priority_out = priority_in
; Pass priority list codes
; 0 - Delete (b/c conflict)
; 1 - Keep (no conflict)
; 2 - Keep (prioritize)

; Determine which (if any) missions to delete
delete_missions = mission_hash.where(-1)
n_delete_missions = n_elements(delete_missions)
if n_delete_missions gt 0 then begin
   ; Delete where satellite name matches the delete mission
   for mission = 0, n_delete_missions - 1 do begin
      delete_inds = where(passes.satellite_name eq $
                          delete_missions[mission],$
                          n_delete_inds)
      if n_delete_inds gt 0 then begin
         priority_out[delete_inds] = 0
      endif
   endfor
endif


END

; Program: Deprioritize_Mission
; Inputs:  passes - IDL structure for pass schedule
;          mission_hash - Hash of mission names and priority scores
;          score_in - Input of score vector
; Outputs: score_out - Output of modified score vector
; Assumptions: 
; Description: Use this program to deprioritize all passes of a given mission 
; Use in conjunction with delete_mission to ensure that the deleted
; mission gives priority to other missions
PRO deprioritize_mission, passes, mission_hash, score_in, score_out
; Copy priority in to out
score_out = score_in
; Pass priority list codes
; 0 - Delete (b/c conflict)
; 1 - Keep (no conflict)
; 2 - Keep (prioritize)

; Determine which (if any) missions to delete
delete_missions = mission_hash.where(-1)
n_delete_missions = n_elements(delete_missions)
if n_delete_missions gt 0 then begin
   ; Delete where satellite name matches the delete mission
   for mission = 0, n_delete_missions - 1 do begin
      delete_inds = where(passes.satellite_name eq $
                          delete_missions[mission],$
                          n_delete_inds)
      if n_delete_inds gt 0 then begin
         score_out[delete_inds] = -100 ; Something big enough to defeat any
                                ; addition of MaxEl to the score
      endif
   endfor
endif
END

; Program: delete_overlap
; Inputs:  AOS_JD - Vector of AOS times in JD format
;          LOS_JD - Vector of LOS times in JD format
;          score - Pass score vector
;          passes - IDL structure for pass schedule
;          priority_in - Input of modified priority vector
;          
; Outputs: priority_out - Output of modified priority vector
;          overlap_exists - Bool of whether (1) or not (0) overlap exists
; Assumptions: Use program recursively for N concurrent passes
; Description: Use this program to check for overlap and delete the
;              lower scoring pass where overlap exists

PRO delete_overlap, aos_jd, los_jd, $
                    score, passes, $
                    priority_in, priority_out, $
                    overlap_exists, debug=debug
  
; Assume overlap exists until proven otherwise
  overlap_exists = 1b

; Copy input to output
priority_out = priority_in

; Only check overlap on passes for keeping
keep_inds = where(priority_in gt 0, n_keep_inds)
; Bail if there are no passes to keep
if n_keep_inds eq 0 then begin
   overlap_exists = 0b ; Can't have overlap without passes!
   return
endif

; Build new vectors from keep_inds
aos_jd_keep = aos_jd[keep_inds]
los_jd_keep = los_jd[keep_inds]
priority_keep = priority_in[keep_inds]
score_keep = score[keep_inds]
passes_keep = passes[keep_inds]

; Calculate gaps between passes
;      aos_jd_keep[i+1] - los_jd_keep[i]
gaps = shift(aos_jd_keep,-1) - los_jd_keep
; Check for overlapping passes
overlap_inds = where(gaps le 0,n_overlaps)
; This method always makes an overlap at the end
n_overlaps = n_overlaps - 1
; Only work hard if overlaps exist
if n_overlaps ge 1 then begin
    ; Get rid of the fake overlap
    overlap_inds = overlap_inds[0:-2]

    ; Judge passes to keep winners and delete lower priority passes
    judge_victors, $
      passes_keep, score_keep, overlap_inds, priority_keep, $ ; Input Params
       winners_of_keep, losers_of_keep, priority_keep_new, $ ; Output params
       debug=debug
    
    ; Build output variables
    ; De-reference vectors from the subset keep_inds
    losers_inds = keep_inds[losers_of_keep]
    winners_inds = keep_inds[winners_of_keep]
    ; (above) out = in
    ; Pass priority list codes
    ; 0 - Delete (b/c conflict)
    ; 1 - Keep (no conflict)
    ; 2 - Keep (prioritize)
    priority_out[losers_inds] = 0
    priority_out[winners_inds] = 2
    ;if keyword_set(debug) then begin
    ;   priority_delta = priority_in - priority_out
    ;   print,priority_delta
    ;   stop
    ;endif
 endif else begin
    overlap_exists = 0b
 endelse


    ;; ; Print overlapping counts
    ;; if keyword_set(debug) then begin
    ;;    print,"------ Overlapping Pass Counts ------"
    ;;    all_overlap_inds = [overlap_inds,overlap_inds_plus1]
    ;;    overlap_passes = passes[all_overlap_inds]
    ;;    count_pass_spacecraft,overlap_passes
    ;; endif


    
END

; Program: parse_config
; Inputs:  filepath
; Outputs: mission_hash,config_sav,config_dir
; Assumptions: 
; Description: Parse the scheduling_config.ini file and return key variables

PRO parse_config, filepath,mission_hash,config_sav,config_dir,debug=debug

; Read in the whole file to a vector called file_lines
; Open the config file
openr, lun, filepath, /get_lun
file_lines = ''
this_line = ''
while not EOF(lun) do begin
   readf,lun,this_line
   file_lines = [file_lines, this_line]
endwhile
; CLose the file
close,lun
free_lun,lun

; Search for config variables
hash_keys = ''
hash_values = ''
n_lines = n_elements(file_lines)
for line_num = 0, n_lines - 1 do begin
   ; idl_sav_file
   test_string = strmid(file_lines[line_num],0,13)
   if test_string eq 'idl_save_file' then begin
      ; Extract the components, trim whitespace on both sides
      tmp_result = strtrim(strsplit(file_lines[line_num],['='],/extract),2)
      config_sav = tmp_result[1]
      if keyword_set(debug) then print,tmp_result
   endif
   ; schedule_directory
   test_string = strmid(file_lines[line_num],0,18)
   if test_string eq 'schedule_directory' then begin
      ; Extract the components, trim whitespace on both sides
      tmp_result = strtrim(strsplit(file_lines[line_num],['='],/extract),2)
      config_dir = tmp_result[1]
      if keyword_set(debug) then print,tmp_result
   endif
   ; mission_hash of priorities
   ; Look for [mission]_priority = [value]
   test_result = stregex(file_lines[line_num],'_priority',/boolean)
   if test_result then begin    ; Test pass
      ; Look for the value on the right side of the equals sign
      tmp_result = strtrim(strsplit(file_lines[line_num],['='],/extract),2)
      value_string = tmp_result[1]
      value_num = 0l
      reads,value_string,value_num,format='(Z)'
      if keyword_set(debug) then print,'Value: ',value_string,'->',value_num
      
      ; Look for the [mission] in [mission]_priority
      tmp_result = strtrim(strsplit(test_string,['_priority'],/extract),2)
      mission = tmp_result[0]
      if keyword_set(debug) then print,mission

      ; Store mission and value
      hash_values = [hash_values,value_num]
      hash_keys = [hash_keys,mission]
   endif
endfor

; Combine hash values and keys into a real hash
; First, trim initialization values
hash_keys = hash_keys[1:-1]
hash_values = hash_values[1:-1]
mission_hash = orderedhash(hash_keys,hash_values)
;if keyword_set(debug) then stop


END

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
;
;
;                    Main Program: PRIORITIZE_PASS_OVERLAP
;
;
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------


PRO prioritize_pass_overlap, pass_idl_save_file=pass_idl_save_file,$
                             directory=directory,$
                             out_dir=out_dir,$
                             debug=debug,$
                             asynchronous=asynchronous,$
                             config=config,$
                             help=help

;       1. check parameters
if ((n_params() eq 0) OR keyword_set(help)) then begin
    print,'Usage: prioritize_pass_overlap [,pass_idl_save_file=pass_idl_save_file,$'
    print,'                                directory=directory,config=config]'
    print,'Optional Parameters:'
    print,'pass_idl_save_file = name of the IDL saveset file with pass times'
    print,'                 default is "passes_latest_BOULDER.sav"'
    print,'directory = name of the directory where files reside'
    print,'                 default is "~/Dropbox/minxss_dropbox/tle/Boulder/"'
    print,'config = filepath of config file'
    print,'         default is "/home/gs-ops/Dropbox/Automation/Automation_Boulder/scheduling_config.ini"'
    print,''
endif

if keyword_set(help) then return

; Read in config file
if not keyword_set(config) then config = '/home/gs-ops/Dropbox/Automation/Automation_Boulder/scheduling_config.ini'
parse_config,config,mission_hash,config_sav,config_dir,debug=debug

; Check for parameters or 
;                    defer to config file or 
;                                     assign defaults
; in that order.
if not keyword_set(pass_idl_save_file) then begin
   if keyword_set(config_sav) then begin
      pass_idl_save_file = config_sav
   endif else begin
      pass_idl_save_file = "passes_latest_BOULDER.sav"
   endelse
endif
if not keyword_set(directory) then begin
   if keyword_set(config_dir) then begin
      directory = config_dir
   endif else begin
      directory = "~/Dropbox/minxss_dropbox/tle/Boulder/"
   endelse
endif
if not keyword_set(out_dir) then out_dir = directory

if not keyword_set(mission_hash) then begin
   print,"Warning: No mission priority information found. "
   print,"Reverting to default."
   mission_hash = orderedhash('CSIM',-1,'CUTE',1,'IS-1',-1,/fold_case)
endif
print,'Mission         Priority'
print,mission_hash
print,""
print,'Review above mission priority information.'
stop,'Enter .c to continue if correct'


;       2. restore the IDL saveset
restore,directory+pass_idl_save_file
n_passes = n_elements(passes)

if keyword_set(debug) then begin
; Print baseline counts
   print,"------ Unfiltered Pass Counts ------"
   count_pass_spacecraft,passes
endif

; V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V
; Prioritize passes by score
; V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V

; Create a default priority of all 1 - Keep (no conflict)
priority = intarr(n_passes) + 1; 1/Keep

; One mission gets days, the other gets nights, then 
; ping pong day by day
; In effect: One mission gets priority from sunset to sunset
;            Flip once per day
; Inputs: passes, mission_hash
; Outputs: score
rotate_priority,passes,mission_hash,score,debug

; If the mission hash contains a royal mission, give it a crown
; The Queen must think the whole world smells like fresh paint
; 1000 additional points should beat any other score
coronate_mission,passes,mission_hash,score,new_score,debug=debug
score = new_score

; Use deprioritize_mission to deprioritize all passes of a given mission 
; Use in conjunction with delete_mission to ensure that the deleted
; mission gives priority to other missions
deprioritize_mission,passes,mission_hash,score,new_score
score = new_score
; Delete all passes for specific missions (if applicable)
delete_mission, passes, mission_hash, priority, new_priority
priority = new_priority

; ^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^
; Prioritize passes by score
; ^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^


; V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V
; Check overlap and delete as needed
; V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V
; Assume overlap exists until proven otherwise
overlap_exists = 1b

; Pad AOS and LOS times with re-configuration durations
; Constants
sec_per_day = 86400d
two_min_jd = 2*60.0 /sec_per_day
three_min_jd = 3*60.0 /sec_per_day
; Config @ AOS - 3min
aos_minus_3min = passes.start_jd - three_min_jd
; Run to LOS + 2min
los_plus_2min = passes.end_jd + two_min_jd

; Use the padded times as the effective AOS and LOS
aos_jd = aos_minus_3min
los_jd = los_plus_2min

; Iterate to delete overlapping passes until overlap does not exist
while overlap_exists do begin
   delete_overlap, aos_jd, los_jd, $
                   score, passes, $
                   priority, priority_new,$
                   overlap_exists, debug=debug
   priority = priority_new
endwhile
; ^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^
; Check overlap and delete as needed
; ^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^

; Clone proirity to UHF and S-Band copies as schedules are synced...
;        ... for now!
uhf_priority = priority
sband_priority = priority
;        To un-sync, create new scores for each type, and
;                    iterate with delete_overlap on each priority_*
;                    vector


; Append priority to the structure (even if they're all Keep/No conflict)
priority_passes = append_passes_priority(passes,uhf_priority,sband_priority)

; Output CSV files for history
;baseline_csv_filename = 'original_passes.csv'
prioritized_csv_filename = 'passes_manual_BOULDER.csv'
;sav2csv_passes,passes,directory+baseline_csv_filename
sav2csv_passes,priority_passes,out_dir+prioritized_csv_filename

print,"------------------------------------------------------"
print,"Manually modify "+prioritized_csv_filename+" if needed."
stop,"Enter .c to continue once modifications saved"

; Output New .sav files
csv2sav_passes,prioritized_csv_filename,pass_idl_save_file,out_dir

END
