;+
; H+
;	TITLE	: csv2sav_passes
;
; 	Author	: Gabe Bershenyi
; 	Date	: 10/21/21
;
;	$Date: 2022/10/19 16:46:30 $
;	$Source: /home/bershenyi/cubesats/scheduling/RCS/csv2sav_passes.pro,v $
;  @(#)	$Revision: 1.4 $
;	$Name:  $
;	$Locker: bershenyi $
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
;       10/18/22 Bershenyi Added checks to ensure that the two
;                          schedule file inputs match per SMOPS-304
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

; Ensure that the .sav schedule matches the .csv schedule
; Compare the satellite_name field in passes to the satellite column
; of the csv
csv_satellites = passes_csv.field1
match_fails = 0
for pass_num = 0, n_passes - 1 do begin
   if csv_satellites[pass_num] ne passes[pass_num].satellite_name then begin
      if keyword_set(debug) then begin
         print,strtrim(pass_num,2),' ',csv_satellites[pass_num],' ne ',$
               passes[pass_num].satellite_name
      endif
      match_fails = match_fails + 1
   endif
endfor
; Warn and quit if there are match failures
if match_fails ne 0 then begin
   print,"CSV and SAV file inputs do not match"
   print,match_fails," discrepancies between satellite names."
   print,"Check date of ",csv_filename
   print,"Find corresponding file in archive"
   print,"Input filename as 'archive/passes_YYYY-MM-DD_YYYY-MM-DD_BOULDER.sav'"
   if keyword_set(debug) then stop
   return
endif

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

; Save the output to fixed-name files used by other automation
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
