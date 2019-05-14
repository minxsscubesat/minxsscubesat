;+
; NAME:
;   daxss_filename_parts.pro
;
; PURPOSE:
;   Extract out the level number and date in YYYYDOY format for a filename for a DAXSS data product.
;
; INPUTS:
;   filename [string]: File name string
;
; OPTIONAL INPUTS:
;   None
;
; KEYWORD PARAMETERS:
;   None
;
; OUTPUTS:
;   filename_parts_structure:
;                 .level       is string of 'L0C', 'L1', 'L2', 'L3', or 'L4'
;                 .yyyydoy     is date in YYYYDOY format
;
; OPTIONAL OUTPUTS:
;   None
;
; RESTRICTIONS:
;   None
;
; PROCEDURE:
;   1. Find the last period of file extension and extract date in YYYYDOY format
;   2. Find the previous underscore and extract out level string
;   3. Return the results
;
;+

function daxss_filename_parts, filename

  fn_parts = {level: '   ', yyyydoy: 0L}

  if n_params() lt 1 then begin
    message, /INFO, 'USAGE: filename_parts_structure = minxss_filename_parts( fileName )'
    return, fn_parts
  endif

  ;
  ;   1. Find the last period of file extension and extract date in YYYYDOY format
  ;
  pdot = strpos( filename, '.', /reverse_search )
  if (pdot lt 8) then return, fn_parts
  fn_parts.yyyydoy = long(strmid( filename, pdot-8, 4 ))*1000L + long(strmid( filename, pdot-3, 3))

  ;
  ; 2. Find the previous underscore and extract out level string
  ;
  pdash = strpos(filename, '_', pdot-10, /reverse_search)
  if (pdash lt 0) then return, fn_parts
  fn_parts.level = strupcase( strmid( filename, pdash+1, pdot-pdash-10 ) )

  ;
  ; 3. Return the results
  ;
  return, fn_parts
end
