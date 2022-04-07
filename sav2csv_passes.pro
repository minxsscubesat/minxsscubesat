;+
; H+
;	TITLE	: sav2csv_passes
;
; 	Author	: Gabe Bershenyi
; 	Date	: 10/21/21
;
;	$Date: 2022/03/22 19:54:40 $
;	$Source: /home/bershenyi/cubesats/scheduling/RCS/sav2csv_passes.pro,v $
;  @(#)	$Revision: 1.2 $
;	$Name:  $
;	$Locker: bershenyi $
;
;	PURPOSE:
;	Convert from .sav to .csv pass schedule file
;
;	CATEGORY:
;	Utility
;
;	CALLING SEQUENCE:
;	sav2csv_passes.pro,'passes_latest_BOULDER.sav','passes_latest_BOULDER.csv'
;
;	INPUT PARAMETERS:
;	passes        - IDL structure from the .sav file containing pass
;                       schedule data
;       csv_filename  - Filename of the CSV file containing pass
;                       schedule data
;
;	OPTIONAL KEYWORD PARAMETERS:
;
;	OUTPUT PARAMETERS:
;	None
;
;	COMMON BLOCKS:
;	None
;
;	PROCEDURE:
;	Restore .sav file
;       Output data to .csv file
;
;	LIMITATIONS/ASSUMPTIONS:
;	<List any known cases in which code will fail or future work is needed>
;	<List any assumptions made about dates, input code, user interaction, etc.>
;
;-
;	MODIFICATIONS/REVISION LEVEL:
;	MM/DD/YY WHO	WHAT (most recent change first)
;       10/21/21 GLB    Created
;
; H-
;------------------------------------------------------------------------------

;+
; NAME:        
;       TAG_EXIST()
; PURPOSE:              
;       To test whether a tag name exists in a structure.
; EXPLANATION:               
;       Routine obtains a list of tagnames and tests whether the requested one
;       exists or not. The search is recursive so if any tag names in the 
;       structure are themselves structures the search drops down to that level.
;       (However, see the keyword TOP_LEVEL).
;               
; CALLING SEQUENCE: 
;       status = TAG_EXIST(str, tag, [ INDEX =, /TOP_LEVEL, /QUIET ] )
;    
; INPUT PARAMETERS:     
;       str  -  structure variable to search
;       tag  -  tag name to search for, scalar string
;
; OUTPUTS:
;       Function returns 1b if tag name exists or 0b if it does not.
;                              
; OPTIONAL INPUT KEYWORD:
;       /TOP_LEVEL = If set, then only the top level of the structure is
;                           searched.
;       /QUIET - if set, then do not print messages if invalid parameters given
;       /RECURSE - does nothing but kept for compatibility with the
;                  Solarsoft version for which recursion is not the default 
;        http://sohowww.nascom.nasa.gov/solarsoft/gen/idl/struct/tag_exist.pro
; OPTIONAL OUTPUT KEYWORD:
;       INDEX = index of matching tag, scalar longward, -1 if tag name does
;               not exist
;
; EXAMPLE:
;       Determine if the tag 'THICK' is in the !P system variable
;       
;       IDL> print,tag_exist(!P,'THICK')
;
; PROCEDURE CALLS:
;       None.
;
; MODIFICATION HISTORY:     : 
;       Written,       C D Pike, RAL, 18-May-94               
;       Passed out index of matching tag,  D Zarro, ARC/GSFC, 27-Jan-95     
;       William Thompson, GSFC, 6 March 1996    Added keyword TOP_LEVEL
;       Zarro, GSFC, 1 August 1996    Added call to help 
;       Use SIZE(/TNAME) rather than DATATYPE()  W. Landsman  October 2001
;       Added /RECURSE and /QUIET for compatibility with Solarsoft version
;                W. Landsman  March 2009
;       Slightly faster algorithm   W. Landsman    July 2009
;       July 2009 update was not setting Index keyword  W. L   Sep 2009.
;       Use V6.0 notation W.L. Jan 2012 
;        Not setting index again, sigh  W.L./ K. Allers  Jan 2012
;-            

function tag_exist, str, tag,index=index, top_level=top_level,recurse=recurse, $
         quiet=quiet

;
;  check quantity of input
;
compile_opt idl2
if N_params() lt 2 then begin
   print,'Use:  status = tag_exist(structure, tag_name)'
   return,0b
endif

;
;  check quality of input
;

if size(str,/TNAME) ne 'STRUCT' or size(tag,/TNAME) ne 'STRING' then begin
 if ~keyword_set(quiet) then begin 
   if size(str,/TNAME) ne 'STRUCT' then help,str
   if size(tag,/TNAME) ne 'STRING' then help,tag
   print,'Use: status = tag_exist(str, tag)'
   print,'str = structure variable'
   print,'tag = string variable'
  endif 
   return,0b
endif

  tn = tag_names(str)

  index = where(tn eq strupcase(tag), nmatch)

 if ~nmatch && ~keyword_set(top_level) then begin
       status= 0b
       for i=0,n_elements(tn)-1 do begin
        if size(str.(i),/TNAME) eq 'STRUCT' then $
                status=tag_exist(str.(i),tag,index=index)
        if status then return,1b
      endfor
    return,0b

endif else begin
    index = index[0] 
    return,logical_true(nmatch)
 endelse
end


PRO sav2csv_passes,passes,csv_filename

number_passes_total = n_elements(passes)

if keyword_set(verbose) then print, 'Saving "passes" CSV file to ', csv_filename
openw, lun, csv_filename, /get_lun
csv_header = ' Satellite, Start Time, End Time, Duration Minutes, Peak Elevation, In Sunlight'

; Optionally apply priority
if tag_exist(passes,'uhf_priority') and $
  tag_exist(passes,'sband_priority') then begin
    pass_priority = 1
    csv_header = csv_header +', UHF Priority, S-Band Priority'
endif else pass_priority = 0

printf, lun, csv_header
for k=0L, number_passes_total-1 do begin
	; pass_num_str = string( pass_orbit_number[k], format='(I6)')
	sat_name = passes[k].satellite_name
	caldat, passes[k].start_jd, month, day, year, hh, mm, ss
	start_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	caldat, passes[k].end_jd, month, day, year, hh, mm, ss
	end_str = strmid( timestamp( year=year, month=month, day=day, hour=hh, min=mm, sec=ss ), 0, 19)+'UT'
	duration_str = string(passes[k].duration_minutes, format='(F8.2)')
	elevation_str = string( passes[k].max_elevation, format='(F8.2)')
	if (passes[k].sunlight ne 0) then sun_str = 'YES' else sun_str='eclipse'
        if pass_priority then begin
            case passes[k].uhf_priority of
                0: uhf_prio_str = 'Delete'
                1: uhf_prio_str = 'Keep'
                2: uhf_prio_str = 'Keep_Conflict'
            endcase
            case passes[k].sband_priority of
                0: sband_prio_str = 'Delete'
                1: sband_prio_str = 'Keep'
                2: sband_prio_str = 'Keep_Conflict'
            endcase
        endif
	; MinXSS-1 option used pass_num_str  instead of pass_name
	pass_str = ' ' + $
          sat_name + ', ' + $
          start_str + ', ' + $
          end_str + ', ' + $
          duration_str + ', ' + $
          elevation_str + ', ' + $
          sun_str
        ; Optionally append priority
        if pass_priority then begin
            pass_str = pass_str + ', ' + $
              uhf_prio_str + ', ' + $
              sband_prio_str
        endif
        ; Print line to file
	printf, lun, pass_str
endfor
printf, lun, ' '
close, lun
free_lun, lun


END
