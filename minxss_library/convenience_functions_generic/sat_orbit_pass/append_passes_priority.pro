;+
; H+
;	TITLE	: append_passes_priority
;
; 	Author	: Gabe Bershenyi
; 	Date	: 10/28/21
;
;	$Date: 2019/11/12 16:43:16 $
;	$Source: /lasp/software/src/devel_tools/src/rcs_templates/template.pro.in,v $
;  @(#)	$Revision: 1.3 $
;	$Name:  $
;	$Locker:  $
;
;	PURPOSE:
;	Append UHF and S-Band priority schedules to passes data structure
;
;	CATEGORY:
;	Utility
;
;	CALLING SEQUENCE:
;	append_passes_priority
;
;	INPUT PARAMETERS:
;	passes        - IDL structure from the .sav file containing pass
;                       schedule data
;
;	OPTIONAL KEYWORD PARAMETERS:
;
;	OUTPUT PARAMETERS:
;	priority_passes - Same as input data structure, but with two
;                         added tags for UHF and S-Band schedule priority
;
;	COMMON BLOCKS:
;	None
;
;	PROCEDURE:
;	Loop on every index in "passes" to add two priority tags
;
;	LIMITATIONS/ASSUMPTIONS:
;	
;
;-
;	MODIFICATIONS/REVISION LEVEL:
;	MM/DD/YY WHO	WHAT (most recent change first)
;       10/28/21 GLB    Created
;
; H-
;------------------------------------------------------------------------------

FUNCTION append_passes_priority,passes,uhf_priority,sband_priority

;       1. check parameters
if n_params() ne 3 then begin
    print,'Usage: priority_passes = append_passes_prioirity(passes,uhf_priority,sband_priority)'
    print,'passes          = IDL structure with pass times'
    print,'uhf_priority    = Vector of UHF pass priority'
    print,'sband_priority  = Vector of S-Band pass priority'
    print,'                  Format: 0/Delete 1/Keep_no_conflict 2/Keep_w_conflict'
    print,''
    print,'Returning'
    return,!values.f_nan
endif

; Check that inputs match
n_passes = n_elements(passes)
n_uhf = n_elements(uhf_priority)
n_sband = n_elements(sband_priority)
if (n_passes ne n_uhf) or (n_passes ne n_sband) then begin
    print,"Input variable length mismatch"
    print,"Passes: ",n_passes," elements"
    print,"UHF:    ",n_uhf," elements"
    print,"S-Band: ",n_sband," elements"
    return,!values.f_nan
endif

; 2. Loop to append
;    passes is an array of structures
for i = 0l, n_passes - 1 do begin
    ; For the first element, create the new structure outright
    new_pass = { start_jd: passes[i].start_jd, $
                 start_date: passes[i].start_date, $
                 start_time: passes[i].start_time, $
                 end_jd: passes[i].end_jd, $
                 end_date: passes[i].end_date, $
                 end_time: passes[i].end_time, $
                 duration_minutes: passes[i].duration_minutes, $
                 max_jd: passes[i].max_jd, $
                 max_date: passes[i].max_date, $
                 max_time: passes[i].max_time, $
                 max_elevation: passes[i].max_elevation, $
                 sunlight: passes[i].sunlight, $
                 dir_EW: passes[i].dir_EW, $
                 dir_NS: passes[i].dir_NS, $
                 satellite_name: passes[i].satellite_name, $
                 station_name: passes[i].station_name, $
                 uhf_priority: uhf_priority[i], $ ;    New
                 sband_priority: sband_priority[i] } ; New

    ; Add new_pass to the array of passes
    if i eq 0 then begin
        priority_passes = new_pass
    endif else begin ; For subsequent elements, append
        priority_passes = [priority_passes, new_pass]
    endelse

endfor

return,priority_passes

END
