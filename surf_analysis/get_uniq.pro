;+
; Project     : HESSI
;
; Name        : get_uniq
;
; Purpose     : return unique elements of an array
;
; Category    : utility
;;
; Syntax      : IDL> out=get_uniq(in)
;
; Inputs      : IN = array to search
;
; Outputs     : OUT = unique elements
;
; Optional Out: SORDER = sorting index
;
; Keywords    : NO_CASE: case insensitive ordering on strings
;               COUNT: # of uniq values
;				EPSILON:  positive number ge 0, for gt 0 the difference between
;				two consecutive numbers must be gt epsilon for them to be unique.
;
; History     : Written 20 Sept 1999, D. Zarro, SM&A/GSFC
;				25-Aug-2006, richard.schwartz@gsfc.nasa.gov;  added an epsilon tolerance
;				for determining floats to be the same value
;
; Contact     : dzarro@solar.stanford.edu
;-

function get_uniq,array,sorder,no_case=no_case,count=count, epsilon=epsilon

count=0
sorder=-1
if not exist(array) then return,-1
sorder=0
if n_elements(array) eq 1 then begin
 count=1
 return,array[0]
endif

sorted=0b
if keyword_set(no_case) then begin
 if (datatype(array) eq 'STR') then begin
  sorder=uniq([strlowcase(array)],sort([strlowcase(array)]))
  sorted=1b
 endif
endif

if not sorted then sorder=uniq([array],sort([array]))

count=n_elements(sorder)
if count eq 1 then sorder=sorder[0]

return,array[sorder]
end
