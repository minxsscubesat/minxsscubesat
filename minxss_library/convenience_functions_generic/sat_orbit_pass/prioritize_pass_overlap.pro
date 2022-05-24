;+
; H+
;	TITLE	: prioritize_pass_overlap
;
; 	Author	: Karen Bryant
; 	Date	: 10/01/21
;
;	$Date: 2022/03/30 20:18:22 $
;	$Source: /home/bershenyi/cubesats/scheduling/RCS/prioritize_pass_overlap.pro,v $
;  @(#)	$Revision: 1.4 $
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
; Outputs: winners - absolute index vector of winners w/in overlapping pairs
;          losers  - absolute index vector of losers w/in overlapping
;                    pairs
; Assumptions: 
PRO judge_victors, passes, score, overlap_inds, winners, losers, priority_list

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
    
; Create a pass priority list
; 0 - Delete (b/c conflict)
; 1 - Keep (no conflict)
; 2 - Keep (prioritize)
priority_list = intarr(n_elements(passes)) + 1 ; Default to 1/keep 
priority_list[losers] = 0
priority_list[winners] = 2

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

; Find sunsets
sunlight_deltas = passes.sunlight - shift(passes.sunlight,1)
sunset_inds = where(sunlight_deltas eq -1, n_sunsets)
; Eliminate the fake sunset at the beginning
if sunset_inds[0] eq 0 and n_sunsets ge 1 then begin
   n_sunsets = n_sunsets - 1
   sunset_inds = sunset_inds[1:-1]
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

; Print baseline counts
n_passes = n_elements(passes)
print,"------ Unfiltered Pass Counts ------"
count_pass_spacecraft,passes


;     3. TBD input spacecraft priority
; -1; Delete all (of that spacecraft)
;  0; Delete when conflict
;  1; Normal priority (judge based on score)






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
aos = aos_minus_3min
los = los_plus_2min

; Calculate gaps between passes
;      aos[i+1] - los[i]
gaps = shift(aos,-1) - los
; Check for overlapping passes
overlap_inds = where(gaps le 0,n_overlaps)
; This method always makes an overlap at the end
n_overlaps = n_overlaps - 1
; Only work hard if overlaps exist
if n_overlaps ge 1 then begin
    ; Get rid of the fake overlap
    overlap_inds = overlap_inds[0:-2]
    ; For every overlap, we have two passes
    overlap_inds_plus1 = overlap_inds+1

    ; Track the last overlap
    last_overlap_pass = passes[overlap_inds_plus1[-1]]
    
    ; Print overlapping counts
    print,"------ Overlapping Pass Counts ------"
    all_overlap_inds = [overlap_inds,overlap_inds_plus1]
    overlap_passes = passes[all_overlap_inds]
    count_pass_spacecraft,overlap_passes
    
    ; V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V_V
    ; Prioritize passes by score
    ; One mission gets days, the other gets nights, then 
    ; ping pong day by day
    ; In effect: One mission gets priority from sunset to sunset
    ;            Flip once per day
    ; Inputs: passes, mission_hash
    ; Outputs: score
    rotate_priority,passes,mission_hash,score,debug


    ; Use deprioritize_mission to deprioritize all passes of a given mission 
    ; Use in conjunction with delete_mission to ensure that the deleted
    ; mission gives priority to other missions
    deprioritize_mission,passes,mission_hash,score,new_score
    score = new_score

    ;

    ;; Use MaxEl as a tie breaker
    ; (rotate_priority uses 100 to force a victor)
    ; score = score + passes.max_elevation

    ; Synchronize Sband and UHF for now
    uhf_score = score
    sband_score = score

    ; ^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^_^

    ; Judge passes
    print,"*_*_*_*_*_*_*_*_*_*_* UHF *_*_*_*_*_*_*_*_*_*_*"
    judge_victors, $
      passes, uhf_score, overlap_inds, $ ; Input Params
      uhf_winners, uhf_losers, uhf_priority ; Output params
    print,"*_*_*_*_*_*_*_*_*_*_* S-Band *_*_*_*_*_*_*_*_*_*_*"
    judge_victors, $
      passes, sband_score, overlap_inds, $ ; Input Params
      sband_winners, sband_losers, sband_priority ; Output params
    
endif else begin
    uhf_priority = intarr(n_passes) + 1 ; 1/Keep
    sband_priority = intarr(n_passes) + 1 ; 1/Keep
    print,'No overlapping passes found'
endelse

; Delete all passes for specific missions (if applicable)
delete_mission, passes, mission_hash, sband_priority, new_sband_priority
sband_priority = new_sband_priority
delete_mission, passes, mission_hash, uhf_priority, new_uhf_priority
uhf_priority = new_uhf_priority

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
