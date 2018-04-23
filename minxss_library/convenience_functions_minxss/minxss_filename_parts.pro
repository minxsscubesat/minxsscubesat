;+
; NAME:
;	  minxss_filename_parts.pro
;
; PURPOSE:
;	  Extract out the flight model, level number, and date in YYYYDOY format for a filename
;	  for a MinXSS data product.   This does return flight model value for Level 0B files.
;
; CATEGORY:
;	  MinXSS Level 0-4
;
; CALLING SEQUENCE:
;	  filename_parts_structure = minxss_filename_parts( filename )
;
; INPUTS:
;	  filename		File name string
;
;	OPTIONAL INPUTS:
;	  NONE
;
;	KEYWORD PARAMETERS:
;	  L0B			Option to not look for flight model number if level L0B files are used
;
; OUTPUTS:
;	  filename_parts_structure		.flight_model    is 1 or 2
;									.level			 is string of 'L0C', 'L1', 'L2', 'L3', or 'L4'
;									.yyyydoy		 is date in YYYYDOY format
;
;	OPTIONAL OUTPUTS:
;	  NONE
;
; COMMON BLOCKS:
;	  None
;
;	RESTRICTIONS:
;	  None
;
; PROCEDURE:
;   1. Find the last period of file extension and extract date in YYYYDOY format
;	  2. Find the previous 2 underscores and extract out level string and flight model number
;	  3. Return the results
;
; MODIFICATION HISTORY:
;   2015/09/08: Tom Woods:  Original code
;
;
;+

function minxss_filename_parts, filename, L0B=L0B

fn_parts = { flight_model: 0, level: '   ', yyyydoy: 0L }

if n_params() lt 1 then begin
  print, 'USAGE: filename_parts_structure = minxss_filename_parts( fileName )'
  return, fn_parts
endif

;
;   1. Find the last period of file extension and extract date in YYYYDOY format
;
pdot = strpos( filename, '.', /reverse_search )
if (pdot lt 8) then return, fn_parts
fn_parts.yyyydoy = long(strmid( filename, pdot-8, 4 ))*1000L + long(strmid( filename, pdot-3, 3))

;
;	2. Find the previous 2 underscores and extract out level string and flight model number
;
pdash = strpos( filename, '_', pdot-10, /reverse_search )
if (pdash lt 0) then return, fn_parts
fn_parts.level = strupcase( strmid( filename, pdash+1, pdot-pdash-10 ) )
if not keyword_set(L0B) then fn_parts.flight_model = long( strmid( filename, pdash-1, 1 ) )

;
;	3. Return the results
;
return, fn_parts
end
