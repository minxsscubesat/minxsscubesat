;+
; H+
;	TITLE	: csv2sav_passes
;
; 	Author	: Gabe Bershenyi
; 	Date	: 10/21/21
;
;	$Date: 2019/11/12 16:43:16 $
;	$Source: /lasp/software/src/devel_tools/src/rcs_templates/template.pro.in,v $
;  @(#)	$Revision: 1.3 $
;	$Name:  $
;	$Locker:  $
;
;	PURPOSE:
;	Convert from .csv to .sav pass schedule file
;
;	CATEGORY:
;	Utility
;
;	CALLING SEQUENCE:
;	csv2sav_passes.pro,'passes_latest_BOULDER.csv','passes_latest_BOULDER.sav'
;
;	INPUT PARAMETERS:
;	
;
;	OPTIONAL KEYWORD PARAMETERS:
;
;	OUTPUT PARAMETERS:
;	<describe outputs produced by routine>
;
;	COMMON BLOCKS:
;	<Describe any common blocks used>
;
;	PROCEDURE:
;	Ingest CSV
;       
;
;	LIMITATIONS/ASSUMPTIONS:
;	<List any known cases in which code will fail or future work is needed>
;	<List any assumptions made about dates, input code, user interaction, etc.>
;
;-
;	MODIFICATIONS/REVISION LEVEL:
;	MM/DD/YY WHO	WHAT (most recent change first)
;
; H-
;------------------------------------------------------------------------------

function prio_string2numeric,prio_strings
n_strings = n_elements(prio_strings)
prio_numeric = intarr(n_strings) + 1; Default to "Keep"

; 0: uhf_prio_str = 'Delete'
; 1: uhf_prio_str = 'Keep'
; 2: uhf_prio_str = 'Keep_Conflict'
for i = 0, n_strings - 1 do begin
    if prio_strings[i] eq 'Delete' then begin
        prio_numeric[i] = 0
    endif else if prio_strings[i] eq 'Keep' then begin
        prio_numeric[i] = 1
    endif else if prio_strings[i] eq 'Keep_Conflict' then begin
        prio_numeric[i] = 2
    endif else begin
        print,'Error: priority string does not match:',prio_strings[i]
        prio_numeric[i] = 1
    endelse
endfor

return,prio_numeric
end

PRO csv2sav_passes,csv_filename,sav_filename,directory,$
                   debug=debug
if n_params() ne 3 then begin
    print,'Invalid input:'
    print,'csv2sav_passes,csv_filename,sav_filename,directory,$'
    print,'               debug=debug'
    print,''
    return
endif

; Ingest CSV
passes_csv = read_csv(directory+csv_filename,$
                      header=passes_csv_header,n_table_header=1)
uhf_priority_str = passes_csv.field7
sband_priority_str = passes_csv.field8
; Trim footer
n_passes = n_elements(uhf_priority_str)
if n_passes gt 1 then begin
    uhf_priority_str = uhf_priority_str[0:n_passes-2]
    sband_priority_str = sband_priority_str[0:n_passes-2]
endif




; Convert priority strings to numeric
uhf_priority_numeric = prio_string2numeric(uhf_priority_str)
sband_priority_numeric = prio_string2numeric(sband_priority_str)


; Ingest .sav file
restore,directory+sav_filename

; Filter .sav file(s)
; UHF
uhf_keep_inds = where(uhf_priority_numeric ne 0, n_keep_uhf)
if n_keep_uhf gt 0 then begin
    uhf_keep_passes = passes[uhf_keep_inds]
endif else begin
    print,"Error: No UHF passes marked for use."
    uhf_keep_passes = -1
endelse
;S-Band
sband_keep_inds = where(sband_priority_numeric ne 0, n_keep_sband)
if n_keep_sband gt 0 then begin
    sband_keep_passes = passes[sband_keep_inds]
endif else begin
    print,"Error: No S-Band passes marked for use."
    sband_keep_passes = -1
endelse


; Replace .sav file(s)
; Chop up input filename
;split_sav_filename = strsplit(sav_filename,'.',/extract)
;base_sav_filename = split_sav_filename[0]
;extension_sav_filename = split_sav_filename[1] 
;uhf_sav_filename = $
;  base_sav_filename+'_filtered_UHF.'+extension_sav_filename
;sband_sav_filename = $
;  base_sav_filename+'_filtered_SBand.'+extension_sav_filename


sband_sav_filename = 'passes_manual_SBAND_BOULDER.sav'
uhf_sav_filename = 'passes_manual_UHF_BOULDER.sav'
; Variable for saving must be called 'passes'
passes = uhf_keep_passes
save,passes,file=directory+uhf_sav_filename
; Variable for saving must be called 'passes'
passes = sband_keep_passes
save,passes,file=directory+sband_sav_filename



if keyword_set(debug) then stop



END
