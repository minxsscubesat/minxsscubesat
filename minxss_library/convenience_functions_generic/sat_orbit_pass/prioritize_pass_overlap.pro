;+
; H+
;	TITLE	: prioritize_pass_overlap
;
; 	Author	: Karen Bryant
; 	Date	: 10/01/21
;
;	$Date: 2019/11/12 16:43:16 $
;	$Source: /lasp/software/src/devel_tools/src/rcs_templates/template.pro.in,v $
;  @(#)	$Revision: 1.3 $
;	$Name:  $
;	$Locker:  $
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

function boolean_not,number
bool_number = boolean(number)
if bool_number eq 0 then begin
    not_number = 1
endif else begin
    not_number = 0
endelse
return,not_number
end

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
first_is_best_inds = where(score_gap gt 0, n_first_is_best)
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


PRO prioritize_pass_overlap, pass_idl_save_file,$
                             directory,$
                             debug=debug,$
                             asynchronous=asynchronous

;       1. check parameters
if n_params() ne 2 then begin
    print,'Usage: prioritize_pass_overlap, pass_idl_save_file,$'
    print,'                                directory'
    print,'pass_idl_save_file = name of the IDL saveset file with pass times'
    print,'directory = name of the directory where files reside'
    print,''
    print,'Returning'
    return
endif

;       2. restore the IDL saveset

restore,directory+pass_idl_save_file

; Print baseline counts
n_passes = n_elements(passes)
print,"------ Unfiltered Pass Counts ------"
count_pass_spacecraft,passes


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
    odds_or_evens = boolarr(n_passes)
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
        ; Mark sunsets as odd or even by JD
        sunsets_odds_or_evens = floor(passes[sunset_inds].start_jd mod 2)
        sunsets_odds_or_evens = boolean(sunsets_odds_or_evens)
        ; Now spread those odds/evens to the other indices
        for sunset = 0, n_sunsets - 1 do begin
            ; For the first one, reverse it and spread backward
            if sunset eq 0 then begin
                first_odd_even = sunsets_odds_or_evens[sunset]
                odds_or_evens[0:sunset_inds[sunset]-1] = $
                  boolean_not(first_odd_even)
            endif
            ; For middle sunsets, spread up to the next sunset
            if sunset lt n_sunsets - 1 then begin ; Middle
                odds_or_evens[sunset_inds[sunset]:sunset_inds[sunset+1]-1] = $
                  sunsets_odds_or_evens[sunset]
            ; For the last sunset, spread to the end
            endif else begin ; Last sunset
                odds_or_evens[sunset_inds[sunset]:-1] = $
                  sunsets_odds_or_evens[sunset]
            endelse
            
        endfor
    endif else begin ; In this case, there are 1 or 0 sunsets
        ; Otherwise, just take the odd/even-ness of the first pass
        odds_or_evens = floor(passes[0].start_jd mod 2)
    endelse

    if keyword_set(debug) then stop
    ; CSIM gets evens
    CSIM_day_inds = where((odds_or_evens eq 0) and $
                          (passes.satellite_name eq 'CSIM'),n_csim_days)
    ; CUTE gets odds
    CUTE_day_inds = where((odds_or_evens eq 1) and $
                          (passes.satellite_name eq 'CUTE'),n_cute_days)
    score = fltarr(n_passes)
    if n_cute_days gt 0 then score[cute_day_inds] = 100
    if n_csim_days gt 0 then score[csim_day_inds] = 100
    ; Synchronize Sband and UHF for now
    uhf_score = score
    sband_score = score
    
    ;

    ;; Start with  elevation
    ; uhf_score = passes.max_elevation
    ; sband_score = passes.max_elevation
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

; Append priority to the structure (even if they're all Keep/No conflict)
priority_passes = append_passes_priority(passes,uhf_priority,sband_priority)

; Output CSV files for history
;baseline_csv_filename = 'original_passes.csv'
prioritized_csv_filename = 'passes_manual_BOULDER.csv'
;sav2csv_passes,passes,directory+baseline_csv_filename
sav2csv_passes,priority_passes,directory+prioritized_csv_filename

print,"------------------------------------------------------"
print,"Manually modify "+prioritized_csv_filename+" if needed."
stop,"Enter .c to continue once modifications saved"

; Output New .sav files
csv2sav_passes,prioritized_csv_filename,pass_idl_save_file,directory

END
