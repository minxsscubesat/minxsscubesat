  function y2toy4, y2
;
; Convert dates of the form yyddd[.ddd] to 4-digit years, assuming that
; years 30 to 99 are 1930 to 1999, respectively, and years 00 to 29 are
; 2000 to 2029, respectively.  Note that this is a "disparaged"
; expedient to extend support for old 2-digit years, and that 2-digit
; years should no longer be used.  If !warn.obs_routines is true,
; this function will print a warning if it detects a 2-digit year.
;
; B. Knapp, 2000-01-26
;
; Print usage?
  if n_params() eq 0 then begin
     print,' '
     print,' Y2TOY4 is a function which converts date arguments of the'
     print,' form yyddd[.ddd] to 4-digit years of the form yyyyddd[.ddd].'
     print,' It assumes that 2-digit years in the range 30 to 99 are'
     print,' 1930 to 1999, respectively, and 00 to 29 are 2000 to 2029,'
     print,' respectively.  The argument may be a scalar or array of any'
     print,' numeric type.  4-digit years are not changed.  Note that'
     print,' 2-digit years are disparaged and if !warn.obs_routines is'
     print,' true, this function will print a warning if it detects a'
     print,' 2-digit year.  Usage:'
     print,' '
     print,'     y4 = y2toy4( y2 )'
     return,' '
  endif
;
  y = long( y2/1000.d0 )
  d = y2 mod 1000.d0
;
  c20 = where( 30 le y and y le 99, nc20 )
  if nc20 gt 0 then y[c20] = y[c20]+1900L
;
  c21 = where(  0 le y and y le 29, nc21 )
  if nc21 gt 0 then y[c21] = y[c21]+2000L
;
; Print warning?
  if !warn.obs_routines and (nc20 gt 0 or nc21 gt 0) then begin
     help, /traceback, output=h
     t = where( strpos( h, '%' ) ge 0, nt )
     tokens = strsplit( h[t[1]], /extract )
     msg = '% Warning! Obsolete 2-digit year detected in '+tokens[1]
     if n_elements( tokens ) gt 2 then msg = msg + ' at line '+tokens[2]
     print,msg
  endif
;
; Return result (same type as input, but promote short int to long, since
; short int cannot hold 7-digit date)
  info = size( y2 )
  y4 = make_array( n_elements( y2 ), type=(info[n_elements( info )-2] > 3) )
  y4[0] = y*1000.d0 + d
  return, y4
  end


